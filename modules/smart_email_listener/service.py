"""
Service for Smart Email Listener & Task Generator (INT-EMAIL-010)
"""

import re
from datetime import datetime, date
from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from .schemas import (
    InboundEmailCreate,
    InboundEmailParsePreviewRequest,
    ArrivalNoticeParseResult,
    InboundEmailLogResponse,
)
from .validators import validate_email_payload
from . import repository


def parse_date_string(date_str: str) -> Optional[date]:
    clean = re.sub(r"[^\d/.-]", "", date_str).strip()
    formats = ["%Y-%m-%d", "%Y/%m/%d", "%d-%m-%Y", "%d/%m/%Y", "%Y.%m.%d", "%d.%m.%Y"]
    for fmt in formats:
        try:
            return datetime.strptime(clean, fmt).date()
        except ValueError:
            continue
    return None


def extract_arrival_notice_data(subject: str, body: str) -> Dict[str, Any]:
    combined_text = f"{subject}\n{body}"

    # 1. Extract B/L Number (Prioritize explicit keyword)
    bl_number = None
    kw_bl_match = re.search(
        r"(?:B/?L\s*(?:No\.?|Number)?|Bill of Lading(?:\s*No\.?|Number)?|بوليصة\s*(?:الشحن)?|رقم البوليصة)[:\s#]*([A-Z0-9]{6,20})\b",
        combined_text,
        re.IGNORECASE,
    )
    if kw_bl_match:
        bl_number = kw_bl_match.group(1).upper()
    else:
        carrier_bl_match = re.search(
            r"\b((?:MSC|MAEU|CMAU|COSU|ONEY|HLCU|EGLV|ZIMU)[A-Z0-9]{6,16})\b",
            combined_text,
            re.IGNORECASE,
        )
        if carrier_bl_match:
            bl_number = carrier_bl_match.group(1).upper()

    # 2. Extract ETA
    extracted_eta = None
    eta_match = re.search(
        r"(?:Estimated\s*Time\s*of\s*Arrival|\(?ETA\)?|Arrival\s*Date|Est\.?\s*Arrival|تاريخ\s*الوصول|الموعد\s*المتوقع|تاريخ\s*متوقع)[\s():-]*(\d{4}[-/.]\d{1,2}[-/.]\d{1,2}|\d{1,2}[-/.]\d{1,2}[-/.]\d{4})",
        combined_text,
        re.IGNORECASE,
    )
    if eta_match:
        extracted_eta = parse_date_string(eta_match.group(1))

    # 3. Extract Vessel Name
    vessel_name = None
    vessel_match = re.search(
        r"(?:Vessel|Ship|Feeder|باخرة|السفينة|الباخرة)[:\s]*([A-Za-z0-9\s.-]{3,35}?)(?=\s*(?:Voyage|Voy|رحلة|ETA|Discharge|\n|$))",
        combined_text,
        re.IGNORECASE,
    )
    if vessel_match:
        vessel_name = vessel_match.group(1).strip()

    # 4. Extract Voyage
    voyage_name = None
    voyage_match = re.search(r"(?:Voyage|Voy|رحلة)[:\s]*([A-Za-z0-9/-]{2,20})", combined_text, re.IGNORECASE)
    if voyage_match:
        voyage_name = voyage_match.group(1).strip()

    # 5. Extract ISO Container Numbers
    containers = list(set(re.findall(r"\b([A-Z]{4}\d{7})\b", combined_text)))

    return {
        "bl_number": bl_number,
        "eta": extracted_eta,
        "vessel": vessel_name,
        "voyage": voyage_name,
        "containers": containers,
    }


def preview_arrival_notice_service(req: InboundEmailParsePreviewRequest) -> ArrivalNoticeParseResult:
    extracted = extract_arrival_notice_data(req.subject, req.body_text)
    return ArrivalNoticeParseResult(
        extracted_bl_number=extracted["bl_number"],
        extracted_eta=extracted["eta"],
        extracted_vessel=extracted["vessel"],
        extracted_voyage=extracted["voyage"],
        extracted_containers=extracted["containers"],
        is_matched_file=False,
        import_file_id=None,
        import_file_code=None,
        payment_task_created=False,
        task_id=None,
        summary_message="تمت المعاينة والاستخراج بنجاح من نص الإيميل.",
    )


def process_inbound_email_service(
    db: Session, req: InboundEmailCreate, user: str = "SmartEmailListener"
) -> ArrivalNoticeParseResult:
    validate_email_payload(req.sender_email, req.subject, req.body_text)
    extracted = extract_arrival_notice_data(req.subject, req.body_text)

    bl_number = extracted["bl_number"]
    eta_date = extracted["eta"]
    vessel = extracted["vessel"]
    voyage = extracted["voyage"]
    containers_str = ", ".join(extracted["containers"]) if extracted["containers"] else None

    # Search for matching import file
    matched_file = repository.find_import_file_by_bl(db, bl_number) if bl_number else None
    task_created = False
    task_id = None
    status_str = "Processed"

    if matched_file:
        status_str = "Matched"
        # Update ETA if different
        if eta_date:
            repository.update_import_file_eta(db, matched_file.import_file_id, eta_date)

        # Generate Payment Task for Delivery Order
        created_task = repository.create_delivery_order_payment_task(db, matched_file, bl_number, eta_date)
        task_id = created_task.task_id
        task_created = True
        status_str = "Task_Created"
        msg = f"تم استخراج بوليصة [{bl_number}] بنجاح ومطابقتها مع الملف [{matched_file.import_file_code}] وتوليد مهمة سداد إذن التسليم (#{created_task.task_code})."
    else:
        if bl_number:
            status_str = "Unmatched_BL"
            msg = f"تم استخراج البوليصة [{bl_number}] ولكن لم يتم العثور على ملف استيراد نشط مسجل به هذا الرقم."
        else:
            status_str = "No_BL_Detected"
            msg = "تم استلام الإيميل ولم يُعثر على رقم بوليصة شحن صريح بداخله."

    # Save Inbound Log
    log_record = repository.create_email_log(
        db,
        {
            "sender_email": req.sender_email,
            "subject": req.subject,
            "body_text": req.body_text,
            "email_type": req.email_type or "Arrival Notice",
            "extracted_bl_number": bl_number,
            "extracted_eta": eta_date,
            "extracted_vessel": vessel,
            "extracted_voyage": voyage,
            "extracted_containers": containers_str,
            "import_file_id": matched_file.import_file_id if matched_file else None,
            "processing_status": status_str,
            "task_id": task_id,
            "notes": msg,
        },
        user=user,
    )

    return ArrivalNoticeParseResult(
        extracted_bl_number=bl_number,
        extracted_eta=eta_date,
        extracted_vessel=vessel,
        extracted_voyage=voyage,
        extracted_containers=extracted["containers"],
        is_matched_file=matched_file is not None,
        import_file_id=matched_file.import_file_id if matched_file else None,
        import_file_code=matched_file.import_file_code if matched_file else None,
        payment_task_created=task_created,
        task_id=task_id,
        summary_message=msg,
    )
