"""
Business Service for Shipment Stage Activity & 6-Phase Lifecycle Board
"""

import json
from datetime import datetime
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session

import modules.lifecycle_board.repository as repo
import modules.lifecycle_board.validators as validators
from modules.lifecycle_board.schemas import (
    StageActivityResponse,
    StepAdvancePayload,
    MultiStageSetPayload,
    LifecycleBoardSummaryResponse,
    PhaseSummary,
    ShipmentStageCard,
)
from modules.import_files.model import ImportFile

PHASES_DEFINITION = [
    {
        "phase_id": 1,
        "title_en": "1. Pre-Planning & Studies",
        "title_ar": "المرحلة الأولى: التخطيط والدراسات المسبقة",
        "color_hex": "#D97706",
        "step_codes": ["STEP_01", "STEP_02", "STEP_03"],
        "step_names": {
            "STEP_01": ("Freight Studies", "دراسات ومفاضلة نولون الشحن"),
            "STEP_02": ("Customs Studies", "الدراسات والاستشارات الجمركية"),
            "STEP_03": ("Import Regulatory Requirements", "متطلبات واشتراطات الاستيراد للشحنة"),
        },
    },
    {
        "phase_id": 2,
        "title_en": "2. Shipment Initiation",
        "title_ar": "المرحلة الثانية: بداية الشحنة",
        "color_hex": "#3498DB",
        "step_codes": ["STEP_04", "STEP_05"],
        "step_names": {
            "STEP_04": ("Finance Approvals & Budget", "اعتمادات الميزانية وسداد الموردين"),
            "STEP_05": ("ACID Operations", "الرقم التعريفي المبدئي للشحنة ACID"),
        },
    },
    {
        "phase_id": 3,
        "title_en": "3. Booking & Doc Prep",
        "title_ar": "المرحلة الثالثة: حجز الشحن والتدقيق المستندي المبدئي",
        "color_hex": "#16A085",
        "step_codes": ["STEP_06", "STEP_07", "STEP_08", "STEP_09"],
        "step_names": {
            "STEP_06": ("Freight Booking", "حجز النولون وتأكيد الخط الملاحي"),
            "STEP_07": ("Freight Allocations", "تخصيص وتوزيع الحاويات والبضائع"),
            "STEP_08": ("Draft Docs Review", "مراجعة وتدقيق مسودات الشحن"),
            "STEP_09": ("Docs Customs Approval", "الاعتماد النهائي للمستندات من الجمارك"),
        },
    },
    {
        "phase_id": 4,
        "title_en": "4. Digital & Banking",
        "title_ar": "المرحلة الرابعة: التوثيق الرقمي والاعتماد البنكي",
        "color_hex": "#C0392B",
        "step_codes": ["STEP_10", "STEP_11", "STEP_12"],
        "step_names": {
            "STEP_10": ("CargoX Follow-up / Upload", "رفع ومتابعة مستندات CargoX"),
            "STEP_11": ("Originals Collection", "تحصيل واستلام أصول المستندات"),
            "STEP_12": ("Bank Form 4", "استخراج واعتماد نموذج 4 البنكي"),
        },
    },
    {
        "phase_id": 5,
        "title_en": "5. Port Operations & Clearance",
        "title_ar": "المرحلة الخامسة: عمليات الميناء والتخليص الجمركي",
        "color_hex": "#8E44AD",
        "step_codes": ["STEP_13", "STEP_14", "STEP_15", "STEP_16", "STEP_17", "STEP_18"],
        "step_names": {
            "STEP_13": ("Customs Declaration 46", "قيد ومطابقة إقرار 46 ك.م"),
            "STEP_14": ("Clearance Follow-up", "متابعة الكشف والتثمين"),
            "STEP_15": ("Drawing Samples / Shortage", "سحب العينات / محاضر العجز"),
            "STEP_16": ("Cargo Discrepancy / Damage", "محاضر المعاينة والأضرار"),
            "STEP_17": ("Final Customs Calculation", "الحساب والسداد الجمركي النهائي"),
            "STEP_18": ("Demurrage & Detention", "إدارة الغرامات وفترات السماح"),
        },
    },
    {
        "phase_id": 6,
        "title_en": "6. Inbound & Final Closure",
        "title_ar": "المرحلة السادسة: الاستلام المخزني والتسوية المالية",
        "color_hex": "#27AE60",
        "step_codes": ["STEP_19", "STEP_20", "STEP_21"],
        "step_names": {
            "STEP_19": ("Warehouse Receiving GRN", "إذن الإضافة والاستلام المخزني"),
            "STEP_20": ("Landed Cost Settlement", "تسوية التكلفة الاستيرادية الشاملة"),
            "STEP_21": ("Import File Final Closure", "الإغلاق النهائي للملف الاستيرادي"),
        },
    },
]

STEP_TO_PHASE_MAP = {}
STEP_NAME_MAP = {}
for p in PHASES_DEFINITION:
    for code, names in p["step_names"].items():
        STEP_TO_PHASE_MAP[code] = p["phase_id"]
        STEP_NAME_MAP[code] = names


def get_board_summary_service(db: Session) -> LifecycleBoardSummaryResponse:
    # 1. Ensure any unseeded active import files have at least 1 stage
    _ensure_initial_stages(db)

    # 2. Get step counts
    counts = repo.get_step_counts(db)

    # 3. Build phase summaries
    phases_res: List[PhaseSummary] = []
    for p in PHASES_DEFINITION:
        total_p = sum(counts.get(c, 0) for c in p["step_codes"])
        phases_res.append(
            PhaseSummary(
                phase_id=p["phase_id"],
                title_en=p["title_en"],
                title_ar=p["title_ar"],
                color_hex=p["color_hex"],
                step_codes=p["step_codes"],
                total_active_shipments=total_p,
                step_counts={c: counts.get(c, 0) for c in p["step_codes"]},
            )
        )

    # 4. Fetch all active shipment stage cards
    records = repo.get_active_shipments_with_details(db)
    all_shipment_cards: List[ShipmentStageCard] = []
    unique_files = set()

    for act, file_rec in records:
        unique_files.add(file_rec.import_file_code)
        names = STEP_NAME_MAP.get(act.step_code, (act.step_code, act.step_code))
        all_shipment_cards.append(
            ShipmentStageCard(
                import_file_code=file_rec.import_file_code,
                company_name=file_rec.company_name or "N/A",
                supplier_name=file_rec.supplier_name or "N/A",
                po_number=file_rec.po_number,
                shipment_mode=file_rec.shipment_mode or "Sea FCL",
                incoterm_code=file_rec.incoterm_code or "FOB",
                priority=file_rec.priority or "High",
                estimated_cost=file_rec.estimated_cost or 0.0,
                estimated_cost_currency=file_rec.estimated_cost_currency or "USD",
                step_code=act.step_code,
                step_name_en=names[0],
                step_name_ar=names[1],
                status=act.status,
                started_at=act.started_at,
                notes=act.notes,
            )
        )

    return LifecycleBoardSummaryResponse(
        phases=phases_res,
        total_active_files=len(unique_files),
        all_shipments=all_shipment_cards,
    )


def advance_step_service(db: Session, payload: StepAdvancePayload) -> Dict[str, Any]:
    validators.validate_step_code(payload.current_step_code)
    validators.validate_multi_step_codes(payload.next_step_codes)

    now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    act_data_json = json.dumps(payload.action_data) if payload.action_data else None

    # Complete current step
    repo.save_or_update_activity(
        db,
        import_file_code=payload.import_file_code,
        step_code=payload.current_step_code,
        status="Completed",
        completed_at=now_str,
        action_data=act_data_json,
        notes=payload.notes,
    )

    # Activate next step(s)
    for next_code in payload.next_step_codes:
        repo.save_or_update_activity(
            db,
            import_file_code=payload.import_file_code,
            step_code=next_code,
            status="In-Progress",
            started_at=now_str,
            notes=f"تم التفعيل بعد إكمال {payload.current_step_code}",
        )

    return {
        "message": f"تم إكمال الخطوة {payload.current_step_code} وتفعيل الخطوات التالية بنجاح.",
        "completed_step": payload.current_step_code,
        "activated_steps": payload.next_step_codes,
    }


def set_multi_active_stages_service(db: Session, payload: MultiStageSetPayload) -> Dict[str, Any]:
    validators.validate_multi_step_codes(payload.active_step_codes)
    now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    for step_code in payload.active_step_codes:
        repo.save_or_update_activity(
            db,
            import_file_code=payload.import_file_code,
            step_code=step_code,
            status="In-Progress",
            started_at=now_str,
            notes=payload.notes or "تفعيل مرحلي متزامن",
        )

    return {
        "message": f"تم تفعيل {len(payload.active_step_codes)} مرحلة بالتوازي للشحنة {payload.import_file_code}.",
        "active_steps": payload.active_step_codes,
    }


def _ensure_initial_stages(db: Session):
    # If no stage activities exist for open import files, seed default stages
    count = db.query(repo.ShipmentStageActivity).count()
    if count == 0:
        files = db.query(ImportFile).filter(ImportFile.is_active == True).limit(5).all()
        now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        for i, f in enumerate(files):
            step_code = f"STEP_{str((i % 6) + 1).zfill(2)}"
            repo.save_or_update_activity(
                db,
                import_file_code=f.import_file_code,
                step_code=step_code,
                status="In-Progress",
                started_at=now_str,
                notes="تهيئة أولية لنشاط الشحنة",
            )

def get_all_activities_service(db: Session, import_file_code: str):
    return repo.get_all_activities(db, import_file_code=import_file_code)
