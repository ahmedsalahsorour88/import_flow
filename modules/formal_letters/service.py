"""
Service for AI Formal Letter Drafting (AI-DRAFT-014)
"""

from datetime import datetime, date
from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from .schemas import (
    FormalLetterGenerateRequest,
    FormalLetterResponse,
    FormalLetterTemplateInfo,
    FormalLetterRecordResponse,
)
from .templates import (
    TEMPLATE_METADATA,
    DEMURRAGE_EXTENSION_TEMPLATE,
    BANK_DELEGATION_TEMPLATE,
    BANK_FORM4_APPLICATION_TEMPLATE,
    CUSTOMS_BROKER_MANDATE_TEMPLATE,
)
from .validators import validate_formal_letter_request
from . import repository

from modules.import_files.model import ImportFile
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.external_service_providers.model import ExternalServiceProvider
from modules.freight_booking.model import ShipmentBooking
from modules.import_documentation.model import CustomsDeclarationDraft, DraftBLReviewSession


def get_available_templates_service() -> List[FormalLetterTemplateInfo]:
    return [FormalLetterTemplateInfo(**meta) for meta in TEMPLATE_METADATA]


def generate_formal_letter_service(
    db: Session, req: FormalLetterGenerateRequest, user: str = "System"
) -> FormalLetterResponse:
    validate_formal_letter_request(req.import_file_id, req.template_type, req.extension_days or 21)

    # 1. Fetch Import File
    import_file = (
        db.query(ImportFile)
        .filter(ImportFile.import_file_id == req.import_file_id, ImportFile.is_active == True)
        .first()
    )
    if not import_file:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"ملف الاستيراد رقم [{req.import_file_id}] غير موجود.",
        )

    # 2. Fetch linked Company & Supplier
    company = None
    if import_file.company_id:
        company = (
            db.query(ImportCompany)
            .filter(ImportCompany.company_id == import_file.company_id)
            .first()
        )

    supplier = None
    if import_file.supplier_id:
        supplier = (
            db.query(Supplier)
            .filter(Supplier.supplier_id == import_file.supplier_id)
            .first()
        )

    # 3. Fetch linked Booking
    booking = (
        db.query(ShipmentBooking)
        .filter(ShipmentBooking.import_file_id == import_file.import_file_id)
        .first()
    )

    # 4. Fetch linked Customs Declaration or Draft BL for B/L Number
    bl_number = None
    decl = (
        db.query(CustomsDeclarationDraft)
        .filter(CustomsDeclarationDraft.import_file_id == import_file.import_file_id)
        .first()
    )
    if decl and decl.bl_number:
        bl_number = decl.bl_number
    else:
        bl_review = (
            db.query(DraftBLReviewSession)
            .filter(DraftBLReviewSession.import_file_id == import_file.import_file_id)
            .first()
        )
        if bl_review and bl_review.draft_bl_number:
            bl_number = bl_review.draft_bl_number

    if not bl_number:
        bl_number = "بموجب إذن الشحن"

    # 5. Fetch linked Broker Provider if exists
    broker_provider = None
    if import_file.broker_id:
        broker_provider = (
            db.query(ExternalServiceProvider)
            .filter(ExternalServiceProvider.provider_id == import_file.broker_id)
            .first()
        )

    # Extract clean parameters
    today_str = date.today().strftime("%Y/%m/%d")
    company_name = (company.importer_name if company else None) or import_file.company_name or "الشركة المستوردة"
    commercial_registry = (company.registration_number if company else None) or "سجل تجاري استيرادي"
    tax_id = (company.vat_id if company else None) or (company.importer_id if company else None) or "بطاقة ضريبية معتمدة"
    company_address = (company.address if company else None) or "جمهورية مصر العربية"
    importer_customs_id = (company.importer_id if company else None) or "مسجل بالمنظومة"
    acid_number = import_file.acid_number or (decl.acid_number if decl else None) or "قيد الاستخراج"
    vessel_name = (booking.vessel_name if booking else None) or "السفينة الناقلة"
    voyage_number = (booking.voyage_number if booking else None) or "الرحلة الحالية"
    po_number = import_file.po_number or "أمر الشراء المعتمد"
    supplier_name = (supplier.company_name if supplier else None) or import_file.supplier_name or "المورد الأجنبي"
    total_amount = f"{import_file.estimated_cost:,.2f}" if import_file.estimated_cost else "حسب الفاتورة التجارية"
    currency_code = import_file.estimated_cost_currency or "USD"
    port_of_discharge = import_file.port_of_discharge or "ميناء الإسكندرية / الدخيلة"

    # Default recipient and bank names
    recipient_name = req.recipient_name or (booking.shipping_line_name if booking else None) or "التوكيل الملاحي المختص"
    bank_name = req.bank_name or "البنك التجاري المعتمد"
    bank_branch = req.bank_branch or "الفرع الرئيسي"
    broker_name = (
        req.broker_name
        or (broker_provider.partner_name if broker_provider else None)
        or import_file.broker_name
        or "المكتب المعتمد للتخليص"
    )
    broker_license = (
        req.broker_license
        or (broker_provider.clearance_license_number if broker_provider else None)
        or "ترخيص مصلحة الجمارك"
    )
    broker_office_name = (
        (broker_provider.partner_name if broker_provider else None)
        or import_file.broker_name
        or "مكتب التخليص الجمركي"
    )

    custom_notes_section = ""
    if req.custom_notes and req.custom_notes.strip():
        custom_notes_section = f"ملاحظات وتعهدات إضافية:\n{req.custom_notes.strip()}\n"

    params = {
        "current_date": today_str,
        "company_name": company_name,
        "commercial_registry": commercial_registry,
        "tax_id": tax_id,
        "company_address": company_address,
        "importer_customs_id": importer_customs_id,
        "bl_number": bl_number,
        "acid_number": acid_number,
        "vessel_name": vessel_name,
        "voyage_number": voyage_number,
        "po_number": po_number,
        "supplier_name": supplier_name,
        "total_amount": total_amount,
        "currency_code": currency_code,
        "port_of_discharge": port_of_discharge,
        "recipient_name": recipient_name,
        "bank_name": bank_name,
        "bank_branch": bank_branch,
        "bank_account_no": "حساب الشركة الجاري طرفكم",
        "delegate_name": broker_name,
        "delegate_national_id": "الثابت ببطاقة الرقم القومي ورخصة التخليص",
        "broker_name": broker_name,
        "broker_license": broker_license,
        "broker_office_name": broker_office_name,
        "payment_method": "اعتماد مستندي / تحصيل مستندي (CAD)",
        "documentary_collection_ref": "إشعار التحصيل البنكي للشحنة",
        "extension_days": req.extension_days or 21,
        "custom_notes_section": custom_notes_section,
    }

    # Select template
    if req.template_type == "demurrage_extension":
        letter_title = "خطاب طلب مد فترة سماح غرامات التأخير للتوكيل الملاحي"
        body = DEMURRAGE_EXTENSION_TEMPLATE.format(**params)
    elif req.template_type == "bank_delegation":
        letter_title = "خطاب تفويض بنكي معتمد لاستلام بوالص الشحن والمستندات الأصلية"
        body = BANK_DELEGATION_TEMPLATE.format(**params)
    elif req.template_type == "bank_form4":
        letter_title = "طلب استخراج نموذج (4) جمركي لفتح اعتماد أو سداد مستندي"
        body = BANK_FORM4_APPLICATION_TEMPLATE.format(**params)
    elif req.template_type == "customs_broker_mandate":
        letter_title = "خطاب تفويض وتوكيل مخلص جمركي رسمي مع التعهدات القانونية"
        body = CUSTOMS_BROKER_MANDATE_TEMPLATE.format(**params)
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="نوع القالب غير معروف.",
        )

    # Save to history
    record = repository.create_letter_record(
        db,
        {
            "import_file_id": import_file.import_file_id,
            "template_type": req.template_type,
            "letter_title_ar": letter_title,
            "recipient_name": recipient_name,
            "letter_body": body,
            "notes": req.custom_notes,
        },
        user=user,
    )

    return FormalLetterResponse(
        letter_id=record.letter_id,
        letter_code=record.letter_code,
        template_type=req.template_type,
        letter_title_ar=letter_title,
        letter_body=body,
        import_file_id=import_file.import_file_id,
        import_file_code=import_file.import_file_code,
        generated_at=record.created_at.strftime("%Y-%m-%d %H:%M"),
    )


def get_file_letter_history_service(db: Session, import_file_id: int) -> List[FormalLetterRecordResponse]:
    records = repository.get_letters_by_file(db, import_file_id)
    return [FormalLetterRecordResponse.model_validate(r) for r in records]
