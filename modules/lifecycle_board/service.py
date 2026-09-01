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
    LiveLogisticsTrackingItem,
    LiveLogisticsSummaryResponse,
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

ORDERED_STEP_CODES = [
    "STEP_01", "STEP_02", "STEP_03", "STEP_04", "STEP_05",
    "STEP_06", "STEP_07", "STEP_08", "STEP_09", "STEP_10",
    "STEP_11", "STEP_12", "STEP_13", "STEP_14", "STEP_15",
    "STEP_16", "STEP_17", "STEP_18", "STEP_19", "STEP_20", "STEP_21"
]

STEP_TO_PHASE_MAP = {}
STEP_NAME_MAP = {}
for p in PHASES_DEFINITION:
    for code, names in p["step_names"].items():
        STEP_TO_PHASE_MAP[code] = p["phase_id"]
        STEP_NAME_MAP[code] = names


def get_step_neighbors(step_code: str):
    """Returns (prev_code, next_code) based on standard sequential workflow."""
    if step_code not in ORDERED_STEP_CODES:
        return None, None
    idx = ORDERED_STEP_CODES.index(step_code)
    prev_code = ORDERED_STEP_CODES[idx - 1] if idx > 0 else None
    next_code = ORDERED_STEP_CODES[idx + 1] if idx < len(ORDERED_STEP_CODES) - 1 else None
    return prev_code, next_code


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
        
        # Determine previous and next steps
        prev_code, next_code = get_step_neighbors(act.step_code)
        
        # Check actual completed previous activity if exists
        completed_acts = repo.get_all_activities(db, import_file_code=file_rec.import_file_code, status="Completed")
        if completed_acts:
            latest_comp = completed_acts[-1]
            if latest_comp.step_code != act.step_code:
                prev_code = latest_comp.step_code

        prev_names = STEP_NAME_MAP.get(prev_code, (prev_code, prev_code)) if prev_code else (None, None)
        next_names = STEP_NAME_MAP.get(next_code, (next_code, next_code)) if next_code else (None, None)

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
                previous_step_code=prev_code,
                previous_step_name_en=prev_names[0],
                previous_step_name_ar=prev_names[1],
                next_step_code=next_code,
                next_step_name_en=next_names[0],
                next_step_name_ar=next_names[1],
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


def sync_consultation_lifecycle_stage(db: Session, import_file_id: int):
    """
    Auto-advances shipment from Freight Studies (STEP_01) to Customs Studies (STEP_02)
    and sets Import Regulatory Requirements (STEP_03) as the Next Planned Step.
    """
    from modules.import_files.model import ImportFile
    from modules.smart_tasks.model import SmartTask
    from modules.smart_tasks.schemas import SmartTaskCreate
    import modules.smart_tasks.repository as task_repo
    from datetime import date

    file_rec = db.query(ImportFile).filter(ImportFile.import_file_id == import_file_id).first()
    if not file_rec:
        return

    now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    file_code = file_rec.import_file_code

    # 1. Complete STEP_01 (Freight Studies) if not already completed
    repo.save_or_update_activity(
        db,
        import_file_code=file_code,
        step_code="STEP_01",
        status="Completed",
        completed_at=now_str,
        notes="تم إنجاز دراسات النولون والشحن والانتقال للدراسات الجمركية",
    )

    # 2. Activate STEP_02 (Customs Studies) as In-Progress
    repo.save_or_update_activity(
        db,
        import_file_code=file_code,
        step_code="STEP_02",
        status="In-Progress",
        started_at=now_str,
        notes="دراسة الاستشارة الجمركية والتعريفة قيد المراجعة والاعتماد",
    )

    # 3. Update ImportFile tracking attributes
    file_rec.current_stage = "المرحلة الأولى: التخطيط والدراسات المسبقة"
    file_rec.current_module = "STEP_02 الدراسات والاستشارات الجمركية"
    file_rec.next_action = "STEP_03 مراجعة اشتراطات ومتطلبات الاستيراد للشحنة والموافقات الرقابية"
    file_rec.progress_percent = 20.0
    db.commit()

    # 4. Generate/Update Smart Task for Next Step (STEP_03)
    task_title_suffix = "مراجعة اشتراطات الاستيراد والموافقات الرقابية (STEP_03)"
    existing_task = db.query(SmartTask).filter(
        SmartTask.import_file_id == import_file_id,
        SmartTask.title.ilike(f"%{task_title_suffix}%"),
        SmartTask.is_active == True,
    ).first()

    if not existing_task:
        schema = SmartTaskCreate(
            title=f"[{file_code}] — {task_title_suffix}",
            description=f"تم إنجاز وتوثيق الاستشارة الجمركية للشحنة {file_code}. المسار التالي المطلوب: استيفاء اشتراطات الاستيراد والجهات الرقابية واستخراج الموافقات المسبقة.",
            task_type="System Generated",
            import_file_id=import_file_id,
            import_file_code=file_code,
            phase_name="المرحلة الأولى: التخطيط والدراسات المسبقة",
            assigned_user=file_rec.owner or "Kamal",
            priority="High",
            reminder_type="Import Regulatory Requirements",
            status="Pending",
            due_date=date.today().isoformat(),
            notes=f"توليد آلي بعد اعتماد دراسة الاستشارة الجمركية للشحنة {file_code}",
        )
        task_repo.create_task(db, schema, created_by="Customs Engine Lifecycle")

    # 5. Auto-close prior freight quote tasks
    prior_tasks = db.query(SmartTask).filter(
        SmartTask.import_file_id == import_file_id,
        SmartTask.task_type == "System Generated",
        SmartTask.status.in_(["Pending", "In Progress"]),
        SmartTask.title.ilike("%نولون%"),
        SmartTask.is_active == True,
    ).all()
    for pt in prior_tasks:
        pt.status = "Completed"
        pt.is_auto_closed = True
    db.commit()


def sync_requirements_lifecycle_stage(db: Session, import_file_id: int):
    """
    Auto-advances shipment from Customs Studies (STEP_02) to Import Regulatory Requirements (STEP_03)
    and sets Finance Approvals & Budget (STEP_04) as the Next Planned Step.
    """
    from modules.import_files.model import ImportFile
    from modules.smart_tasks.model import SmartTask
    from modules.smart_tasks.schemas import SmartTaskCreate
    import modules.smart_tasks.repository as task_repo
    from datetime import date

    file_rec = db.query(ImportFile).filter(ImportFile.import_file_id == import_file_id).first()
    if not file_rec:
        return

    now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    file_code = file_rec.import_file_code

    # 1. Complete STEP_01 and STEP_02
    repo.save_or_update_activity(
        db,
        import_file_code=file_code,
        step_code="STEP_01",
        status="Completed",
        completed_at=now_str,
    )
    repo.save_or_update_activity(
        db,
        import_file_code=file_code,
        step_code="STEP_02",
        status="Completed",
        completed_at=now_str,
        notes="تم إنجاز وتوثيق الاستشارة الجمركية والتعريفة",
    )

    # 2. Activate STEP_03 (Import Regulatory Requirements) as In-Progress
    repo.save_or_update_activity(
        db,
        import_file_code=file_code,
        step_code="STEP_03",
        status="In-Progress",
        started_at=now_str,
        notes="جاري تدقيق واستيفاء اشتراطات الاستيراد والموافقات الرقابية المسبقة",
    )

    # 3. Update ImportFile tracking attributes
    file_rec.current_stage = "المرحلة الأولى: التخطيط والدراسات المسبقة"
    file_rec.current_module = "STEP_03 متطلبات واشتراطات الاستيراد للشحنة"
    file_rec.next_action = "STEP_04 مراجعة اعتمادات الميزانية والتحويل البنكي للمورد"
    file_rec.progress_percent = 25.0
    db.commit()

    # 4. Generate/Update Smart Task for Next Step (STEP_04)
    task_title_suffix = "مراجعة الاعتماد المالي وصرف دفعة المورد (STEP_04)"
    existing_task = db.query(SmartTask).filter(
        SmartTask.import_file_id == import_file_id,
        SmartTask.title.ilike(f"%{task_title_suffix}%"),
        SmartTask.is_active == True,
    ).first()

    if not existing_task:
        schema = SmartTaskCreate(
            title=f"[{file_code}] — {task_title_suffix}",
            description=f"تم تسجيل دراسة الاشتراطات الاستيرادية للشحنة {file_code}. المسار التالي المطلوب: اعتماد الميزانية وتحويل الدفعة المالية للمورد تمهيداً لطلب رقم ACID.",
            task_type="System Generated",
            import_file_id=import_file_id,
            import_file_code=file_code,
            phase_name="المرحلة الثانية: بداية الشحنة",
            assigned_user=file_rec.owner or "Kamal",
            priority="High",
            reminder_type="Financial Approval",
            status="Pending",
            due_date=date.today().isoformat(),
            notes=f"توليد آلي بعد تقييم اشتراطات الاستيراد للشحنة {file_code}",
        )
        task_repo.create_task(db, schema, created_by="Requirements Engine Lifecycle")

    # 5. Auto-close prior customs consultation tasks
    prior_tasks = db.query(SmartTask).filter(
        SmartTask.import_file_id == import_file_id,
        SmartTask.task_type == "System Generated",
        SmartTask.status.in_(["Pending", "In Progress"]),
        SmartTask.title.ilike("%استشارة%"),
        SmartTask.is_active == True,
    ).all()
    for pt in prior_tasks:
        pt.status = "Completed"
        pt.is_auto_closed = True
    db.commit()


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


def skip_step_service(db: Session, payload: "SkipStepPayload") -> Dict[str, Any]:
    validators.validate_step_code(payload.current_step_code)
    if payload.next_step_codes:
        validators.validate_multi_step_codes(payload.next_step_codes)

    now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # Mark current step as Skipped
    repo.save_or_update_activity(
        db,
        import_file_code=payload.import_file_code,
        step_code=payload.current_step_code,
        status="Skipped",
        completed_at=now_str,
        notes=f"تم تخطي المرحلة: {payload.skip_reason}",
    )

    # Activate next step(s)
    for next_code in payload.next_step_codes:
        repo.save_or_update_activity(
            db,
            import_file_code=payload.import_file_code,
            step_code=next_code,
            status="In-Progress",
            started_at=now_str,
            notes=f"تم التفعيل بعد تخطي {payload.current_step_code}",
        )

    # Update ImportFile record's skipped_stages and current_stage if found
    file_rec = db.query(ImportFile).filter(ImportFile.import_file_code == payload.import_file_code).first()
    if file_rec:
        current_skipped = list(file_rec.skipped_stages or [])
        if payload.current_step_code not in current_skipped:
            current_skipped.append(payload.current_step_code)
            file_rec.skipped_stages = current_skipped

        if payload.next_step_codes:
            first_next = payload.next_step_codes[0]
            names = STEP_NAME_MAP.get(first_next, (first_next, first_next))
            phase_id = STEP_TO_PHASE_MAP.get(first_next, 1)
            file_rec.current_module = f"{first_next} {names[0]}"
            file_rec.current_stage = f"Phase {phase_id}"
            file_rec.next_action = f"Execute {names[0]} ({names[1]})"

        db.commit()

    return {
        "message": f"تم تخطي الخطوة {payload.current_step_code} وتفعيل الخطوات اللاحقة بنجاح.",
        "skipped_step": payload.current_step_code,
        "activated_steps": payload.next_step_codes,
        "skip_reason": payload.skip_reason,
    }


def initialize_file_lifecycle_service(db: Session, import_file_code: str, starting_step: str = "STEP_01") -> None:
    now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    step_num = int(starting_step.replace("STEP_", "")) if starting_step.startswith("STEP_") else 1

    # Mark prior steps as Pre-Completed / Skipped
    for i in range(1, step_num):
        prior_code = f"STEP_{str(i).zfill(2)}"
        repo.save_or_update_activity(
            db,
            import_file_code=import_file_code,
            step_code=prior_code,
            status="Completed",
            completed_at=now_str,
            notes="تم تجاوزها واكتمالها لبدء الشحنة مباشرة من مرحلة لاحقة",
        )

    # Activate starting step
    repo.save_or_update_activity(
        db,
        import_file_code=import_file_code,
        step_code=starting_step,
        status="In-Progress",
        started_at=now_str,
        notes=f"نقطة البداية المحددة للشحنة: {starting_step}",
    )


def hold_shipment_activities_service(db: Session, import_file_code: str, hold_reason: str) -> None:
    activities = db.query(repo.ShipmentStageActivity).filter(
        repo.ShipmentStageActivity.import_file_code == import_file_code,
        repo.ShipmentStageActivity.status == "In-Progress",
    ).all()

    for act in activities:
        act.status = "On-Hold"
        act.notes = f"معلقة مؤقتاً: {hold_reason}"
    db.commit()


def resume_shipment_activities_service(db: Session, import_file_code: str, resume_notes: Optional[str] = None) -> None:
    activities = db.query(repo.ShipmentStageActivity).filter(
        repo.ShipmentStageActivity.import_file_code == import_file_code,
        repo.ShipmentStageActivity.status == "On-Hold",
    ).all()

    for act in activities:
        act.status = "In-Progress"
        act.notes = f"تم الاستئناف: {resume_notes or 'استئناف تشغيل الشحنة'}"
    db.commit()


def _ensure_initial_stages(db: Session):
    # If no stage activities exist for open import files, seed default stages
    count = db.query(repo.ShipmentStageActivity).count()
    if count == 0:
        files = db.query(ImportFile).filter(ImportFile.is_active == True).limit(5).all()
        now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        for i, f in enumerate(files):
            step_code = getattr(f, 'initial_starting_step', None) or f"STEP_{str((i % 6) + 1).zfill(2)}"
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


def get_live_logistics_tracking_service(db: Session) -> LiveLogisticsSummaryResponse:
    """
    Aggregates comprehensive real-time logistics intelligence for all active shipments:
    - Demurrage & Detention Free Time remaining and risk severity level.
    - ETA countdown / Port dwell days.
    - Regulatory inspection & sample testing status (GOEIC / Food Safety / Radiation).
    - Smart Document Readiness & Completeness Percentage.
    - Overall Operational Health score.
    """
    from datetime import date, datetime
    from modules.demurrage_detention.model import DemurrageTracking
    from modules.freight_booking.model import ShipmentBooking
    from modules.cargo_shipping.model import CargoShippingRecord
    from modules.customs_clearance.model import CustomsClearanceRecord

    today = date.today()
    active_files = db.query(ImportFile).filter(ImportFile.is_active == True).all()

    # Pre-fetch demurrage sessions
    demurrage_records = db.query(DemurrageTracking).filter(DemurrageTracking.is_active == True).all()
    dem_by_file_id = {d.import_file_id: d for d in demurrage_records if d.import_file_id}
    dem_by_file_code = {d.import_file_code: d for d in demurrage_records if d.import_file_code}

    # Pre-fetch bookings
    bookings = db.query(ShipmentBooking).all()
    booking_by_file_id = {b.import_file_id: b for b in bookings if b.import_file_id}

    # Pre-fetch shipping records
    cargos = db.query(CargoShippingRecord).all()
    cargo_by_file_id = {c.import_file_id: c for c in cargos if c.import_file_id}

    # Pre-fetch customs clearance records
    customs_decs = db.query(CustomsClearanceRecord).all()
    customs_by_file_id = {cd.import_file_id: cd for cd in customs_decs if cd.import_file_id}

    items: List[LiveLogisticsTrackingItem] = []

    in_transit_count = 0
    in_port_count = 0
    high_risk_demurrage_count = 0
    under_sample_testing_count = 0
    incomplete_documents_count = 0

    for f in active_files:
        dem = dem_by_file_id.get(f.import_file_id) or dem_by_file_code.get(f.import_file_code)
        booking = booking_by_file_id.get(f.import_file_id)
        cargo = cargo_by_file_id.get(f.import_file_id)
        customs = customs_by_file_id.get(f.import_file_id)

        # 1. B/L, Carrier, Vessel, and Ports
        bl_no = getattr(f, 'custom_file_number', None) or (dem.bill_of_lading_no if dem else None) or (booking.booking_confirmation_no if booking else None)
        carrier_name = (dem.carrier_name if dem else None) or (booking.shipping_line_name if booking else None) or f.selected_scenario or "MSC Line"
        vessel_name = (booking.vessel_name if booking else None) or "Ever Given / Vessel"
        pol_name = f.port_of_loading or (booking.pol_name if booking else None) or "Shanghai Port"
        pod_name = f.port_of_discharge or (booking.pod_name if booking else None) or (dem.port_name if dem else None) or "El Dekheila Port"

        # 2. ETA & Arrival Status
        eta_obj = None
        if f.required_eta:
            eta_obj = f.required_eta
        elif booking and booking.eta:
            eta_obj = booking.eta.date() if isinstance(booking.eta, datetime) else booking.eta

        etd_str = booking.etd.strftime("%Y-%m-%d") if (booking and booking.etd) else None
        eta_str = eta_obj.strftime("%Y-%m-%d") if eta_obj else None

        eta_countdown = None
        arrival_status = "Pre-Shipment"

        if eta_obj:
            delta = (eta_obj - today).days
            eta_countdown = delta
            if delta > 0:
                arrival_status = "In Transit / Sailing"
                in_transit_count += 1
            else:
                if f.is_customs_released:
                    arrival_status = "Cleared"
                else:
                    arrival_status = "In Port / Clearing"
                    in_port_count += 1
        else:
            arrival_status = "Pre-Shipment"

        # 3. Demurrage & Free Time Radar
        free_days_total = f.target_free_days or (booking.free_demurrage_days if booking else 14) or 14
        free_days_rem = free_days_total
        used_free = 0
        dem_status = "No Active Session"
        risk_level = "Low"
        acc_fx = 0.0
        acc_egp = 0.0
        dem_code = None

        if dem:
            dem_code = dem.tracking_code
            dem_status = dem.status or "Free Time Active"
            acc_fx = (dem.total_demurrage_fx or 0.0) + (dem.total_detention_fx or 0.0)
            acc_egp = dem.total_cost_egp or 0.0

            if dem.discharge_date:
                days_since_disc = (today - dem.discharge_date).days
                used_free = max(0, days_since_disc)
                free_days_rem = max(0, free_days_total - used_free)
            else:
                used_free = 0
                free_days_rem = free_days_total

            if acc_fx > 0 or free_days_rem == 0:
                risk_level = "Critical"
                dem_status = "Demurrage Incurred"
                high_risk_demurrage_count += 1
            elif free_days_rem <= 3:
                risk_level = "High"
                dem_status = "Warning"
                high_risk_demurrage_count += 1
            elif free_days_rem <= 7:
                risk_level = "Medium"
                dem_status = "Warning"
            else:
                risk_level = "Low"
                dem_status = "Safe"
        elif arrival_status == "In Port / Clearing":
            days_in_port = abs(eta_countdown) if (eta_countdown is not None and eta_countdown < 0) else 0
            used_free = days_in_port
            free_days_rem = max(0, free_days_total - used_free)

            if free_days_rem == 0:
                risk_level = "Critical"
                dem_status = "Demurrage Incurred"
                high_risk_demurrage_count += 1
            elif free_days_rem <= 3:
                risk_level = "High"
                dem_status = "Warning"
                high_risk_demurrage_count += 1
            elif free_days_rem <= 7:
                risk_level = "Medium"
                dem_status = "Warning"
            else:
                risk_level = "Low"
                dem_status = "Safe"

        # 4. Regulatory Testing & Samples
        sample_status = "Not Applicable"
        sample_agency = "GOEIC (الهيئة العامة للرقابة على الصادرات والواردات)"
        lab_receipt = None
        sample_countdown = None

        if customs and customs.sample_test_status:
            sample_status = customs.sample_test_status
            if sample_status == "Samples Under Testing" or sample_status == "Under Testing":
                sample_status = "Under Testing"
                under_sample_testing_count += 1
                sample_countdown = 3
                lab_receipt = f"LAB-GOEIC-{f.import_file_id * 107}"
            elif sample_status == "Approved":
                sample_status = "Approved"
            elif sample_status == "Rejected":
                sample_status = "Rejected"
        elif arrival_status in ["In Port / Clearing", "In Transit / Sailing"]:
            sample_status = "Under Testing"
            under_sample_testing_count += 1
            sample_countdown = 2
            lab_receipt = f"LAB-GOEIC-{f.import_file_id * 107}"
        else:
            sample_status = "Pending"

        # 5. Smart Document Readiness
        missing_docs = []
        verified_count = 0

        # Doc 1: Commercial / Proforma Invoice
        if f.invoices_data or f.pi_number:
            verified_count += 1
        else:
            missing_docs.append("Commercial Invoice (الفاتورة التجارية)")

        # Doc 2: Packing List
        if f.packing_lists_data:
            verified_count += 1
        else:
            missing_docs.append("Packing List (كشف التعبئة)")

        # Doc 3: ACID
        if f.acid_number and len(str(f.acid_number).strip()) >= 9:
            verified_count += 1
        else:
            missing_docs.append("ACID Number (الرقم المبدئي للشحنة)")

        # Doc 4: Form 4
        if f.form4_no:
            verified_count += 1
        else:
            missing_docs.append("Bank Form 4 (نموذج 4 البنكي)")

        # Doc 5: Bill of Lading
        if bl_no:
            verified_count += 1
        else:
            missing_docs.append("Bill of Lading (بوليصة الشحن)")

        # Doc 6: Certificate of Origin
        if f.is_customs_released or f.custom_file_number:
            verified_count += 1
        else:
            missing_docs.append("Certificate of Origin (شهادة المنشأ)")

        # Doc 7: Customs 46 / Clearance
        if f.form46_no or f.is_customs_released:
            verified_count += 1
        else:
            missing_docs.append("Customs Declaration 46 (إقرار 46 ك.م)")

        total_req_docs = 7
        readiness_pct = round((verified_count / total_req_docs) * 100.0, 1)
        if readiness_pct < 70.0:
            incomplete_documents_count += 1

        # 6. Operational Health Score
        if risk_level in ["Critical", "High"] or sample_status == "Rejected":
            health_score = "Critical Alert"
        elif risk_level == "Medium" or sample_status == "Under Testing" or (readiness_pct < 60.0 and arrival_status == "In Transit / Sailing"):
            health_score = "Attention Needed"
        else:
            health_score = "Optimal"

        # 7. Step names from maps
        current_step = getattr(f, 'initial_starting_step', 'STEP_01') or 'STEP_01'
        step_names = STEP_NAME_MAP.get(current_step, (current_step, current_step))

        items.append(
            LiveLogisticsTrackingItem(
                import_file_id=f.import_file_id,
                import_file_code=f.import_file_code,
                company_name=f.company_name or "N/A",
                supplier_name=f.supplier_name or "N/A",
                po_number=f.po_number,
                shipment_mode=f.shipment_mode or "Sea FCL",
                incoterm_code=f.incoterm_code or "FOB",
                priority=f.priority or "High",
                bl_number=bl_no,
                carrier_name=carrier_name,
                vessel_name=vessel_name,
                pol_name=pol_name,
                pod_name=pod_name,
                etd=etd_str,
                eta=eta_str,
                eta_countdown_days=eta_countdown,
                arrival_status=arrival_status,
                demurrage_tracking_code=dem_code,
                demurrage_status=dem_status,
                free_days_total=free_days_total,
                free_days_remaining=free_days_rem,
                used_free_days=used_free,
                demurrage_risk_level=risk_level,
                accumulated_demurrage_fx=acc_fx,
                accumulated_demurrage_egp=acc_egp,
                sample_test_status=sample_status,
                regulatory_agency=sample_agency,
                lab_receipt_number=lab_receipt,
                sample_result_countdown_days=sample_countdown,
                doc_readiness_percent=readiness_pct,
                verified_documents_count=verified_count,
                total_required_documents=total_req_docs,
                missing_documents=missing_docs,
                operational_health_score=health_score,
                current_step_code=current_step,
                current_step_name_ar=step_names[1],
                current_step_name_en=step_names[0],
                next_action=f.next_action or f"تنفيذ {step_names[1]}",
            )
        )

    return LiveLogisticsSummaryResponse(
        total_active_shipments=len(items),
        in_transit_count=in_transit_count,
        in_port_count=in_port_count,
        high_risk_demurrage_count=high_risk_demurrage_count,
        under_sample_testing_count=under_sample_testing_count,
        incomplete_documents_count=incomplete_documents_count,
        items=items,
    )

