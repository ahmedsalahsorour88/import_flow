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

