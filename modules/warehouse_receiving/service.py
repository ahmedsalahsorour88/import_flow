from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException

from .model import WarehouseReceivingRecord
from .schemas import (
    WarehouseReceivingCreate,
    WarehouseReceivingUpdate,
    DiscrepancyReportSubmit,
    WarehouseInspectionSubmit,
    InspectionSummaryResponse,
)
from .repository import (
    generate_grn_code,
    get_warehouse_receiving_by_id,
    get_warehouse_receiving_list,
    create_warehouse_receiving,
    update_warehouse_receiving,
    soft_delete_warehouse_receiving,
    restore_warehouse_receiving,
)
from .validators import validate_seal_integrity, validate_discrepancy_claim
from modules.import_files.model import ImportFile

def create_warehouse_receiving_service(db: Session, schema: WarehouseReceivingCreate) -> WarehouseReceivingRecord:
    # Check import file exists
    imp_file = db.query(ImportFile).filter(ImportFile.import_file_id == schema.import_file_id, ImportFile.is_active == True).first()
    if not imp_file:
        raise HTTPException(status_code=404, detail="ملف الشحنة الاستيرادية المرتكز عليه غير موجود أو محذوف.")

    existing = db.query(WarehouseReceivingRecord).filter(
        WarehouseReceivingRecord.import_file_id == schema.import_file_id,
        WarehouseReceivingRecord.is_active == True,
    ).first()
    if existing:
        raise HTTPException(
            status_code=400,
            detail=f"يوجد بالفعل إذن استلام مخزني مسجل لهذا الملف الاستيرادي (رقم الإذن: {existing.grn_number}). يرجى مراجعة وتحديث الإذن الحالي بدلاً من إنشاء إذن مكرر.",
        )

    validate_seal_integrity(schema.seal_intact, schema.seal_number or "")

    code = generate_grn_code(db)
    record = create_warehouse_receiving(db, schema, code)

    try:
        from modules.audit_logs.service import AuditLogService
        AuditLogService(db).log_activity(
            entity_type="WarehouseReceivingRecord",
            entity_id=record.receiving_id,
            entity_code=record.grn_number,
            action="CREATE",
            new_data=schema.model_dump(exclude_unset=True),
            performed_by="Warehouse Manager",
        )
    except Exception as e:
        import logging
        logging.getLogger(__name__).warning("AuditLog for WarehouseReceivingRecord create failed: %s", e)

    # LOG-BOND-003: Check if shipment is Under-Bond Released (Quarantine Lock Active)
    from modules.customs_clearance.model import CustomsClearanceRecord
    clearance = db.query(CustomsClearanceRecord).filter(
        CustomsClearanceRecord.import_file_id == schema.import_file_id,
        CustomsClearanceRecord.is_active == True,
    ).order_by(CustomsClearanceRecord.customs_clearance_id.desc()).first()

    if clearance and clearance.is_under_bond_release and clearance.quarantine_lock:
        record.is_under_bond_quarantine = True
        record.quarantine_lock_active = True
        record.dispatch_blocked = True
        record.status = "Under Bond Quarantine"
        record.notes = (record.notes or "") + f" | بضاعة تحت التحفظ الجمركي (سحب على عهدة - تعهد #{clearance.bond_guarantee_ref}) - يحظر الصرف والتشغيل."

    # Auto update import file stage and stop transport/demurrage timers
    imp_file.current_module = "Phase 8 - Warehouse Receiving & Quality Control"
    imp_file.inland_transport_status = "ARRIVED"
    arrival_dt = schema.arrival_datetime or datetime.now(timezone.utc)
    if not imp_file.inland_actual_arrival_date:
        imp_file.inland_actual_arrival_date = arrival_dt

    # Sync inland transport bookings if any
    try:
        from modules.inland_transport.model import InlandTransportBooking
        active_bookings = db.query(InlandTransportBooking).filter(
            InlandTransportBooking.import_file_id == schema.import_file_id,
            InlandTransportBooking.is_active == True,
        ).all()
        for b in active_bookings:
            if b.status != "Arrived at Warehouse":
                b.status = "Arrived at Warehouse"
                b.actual_arrival_at = arrival_dt
    except Exception:
        pass

    # Stop port storage timers on demurrage trackings if gate out was not recorded
    try:
        from modules.demurrage_detention.model import DemurrageTracking
        active_trackings = db.query(DemurrageTracking).filter(
            DemurrageTracking.import_file_id == schema.import_file_id,
            DemurrageTracking.is_active == True,
        ).all()
        today_date = (schema.arrival_datetime or datetime.now(timezone.utc)).date()
        for t in active_trackings:
            if not t.gate_out_date:
                t.gate_out_date = today_date
    except Exception:
        pass

    stage_title = (
        f"Under-Bond Quarantine at {schema.warehouse_name} (GRN: {code})"
        if record.quarantine_lock_active
        else f"Goods Received at {schema.warehouse_name} (GRN: {code})"
    )
    next_action_title = (
        "Awaiting Laboratory Test Approval before Production"
        if record.quarantine_lock_active
        else "الفحص الفني ومحضر مطابقة العجز والتالف (TR-04) وتكلفة الوصول (CLO-02)"
    )
    imp_file.current_stage = stage_title
    imp_file.next_action = next_action_title
    if (imp_file.progress_percent or 0.0) < 98.0:
        imp_file.progress_percent = 98.0
    db.commit()

    # Lifecycle advance: STEP_19 → STEP_20 (GRN completed → Landed Cost Settlement)
    try:
        from modules.lifecycle_board.service import advance_lifecycle_step_service
        advance_lifecycle_step_service(
            db=db,
            import_file_id=schema.import_file_id,
            completed_step_code="STEP_19",
            target_step_codes=["STEP_20"],
            notes=f"تم استلام البضاعة في المخزن ({schema.warehouse_name}) وإصدار إذن الإضافة ({code}).",
            assigned_user="Warehouse Manager",
            custom_stage_title=stage_title,
            custom_next_action=next_action_title,
            min_progress_percent=98.0,
        )
    except Exception as e:
        import logging
        logging.getLogger(__name__).warning("Lifecycle advance STEP_19→STEP_20 failed: %s", e)

    # Smart Tasks and System Notifications
    try:
        from modules.smart_tasks.service import create_task_service
        from modules.smart_tasks.schemas import SmartTaskCreate
        create_task_service(
            db=db,
            schema=SmartTaskCreate(
                import_file_id=imp_file.import_file_id,
                title=f"الفحص الفني ومطابقة العجز والتالف (TR-04) - {code}",
                description=f"مطابقة كميات إذن الإضافة المخزني ({code}) مع الفاتورة وحصر أي عجز أو تالف للشحنة {imp_file.import_file_code}.",
                category="Operations",
                priority="Medium",
                assigned_to=schema.inspector_name or "Warehouse QC Inspector",
                task_type="TR-04",
            ),
            user_name="System",
        )
    except Exception:
        pass

    try:
        from modules.notifications.service import create_system_notification
        create_system_notification(
            db=db,
            title=f"تم إصدار إذن استلام بضاعة بالمخزن ({code})",
            message=f"وصلت بضاعة الشحنة {imp_file.import_file_code} لمخزن {schema.warehouse_name} وتم إصدار إذن الإضافة {code}.",
            severity="INFO",
            category="Warehouse Receiving",
            reference_id=record.receiving_id,
        )
    except Exception:
        pass

    return record



def get_warehouse_receiving_service(db: Session, record_id: int) -> WarehouseReceivingRecord:
    record = get_warehouse_receiving_by_id(db, record_id)
    if not record:
        raise HTTPException(status_code=404, detail="سجل استلام الجودة والمخازن غير موجود.")
    return record

def list_warehouse_receivings_service(
    db: Session,
    include_inactive: bool = False,
    import_file_id: Optional[int] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
) -> List[WarehouseReceivingRecord]:
    return get_warehouse_receiving_list(db, include_inactive, import_file_id, status, search)

def report_receiving_discrepancy_service(db: Session, record_id: int, payload: DiscrepancyReportSubmit) -> WarehouseReceivingRecord:
    """BP-035 Report Receiving Discrepancies & Damage Claims."""
    validate_discrepancy_claim(payload.discrepancy_type, payload.discrepancy_notes)

    record = get_warehouse_receiving_service(db, record_id)
    record.discrepancy_type = payload.discrepancy_type
    record.discrepancy_notes = payload.discrepancy_notes
    record.quarantine_zone_assigned = payload.quarantine_zone_assigned
    record.insurance_claim_filed = payload.insurance_claim_filed
    record.insurance_claim_ref = payload.insurance_claim_ref
    record.status = "Discrepancy Reported"
    record.updated_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(record)
    return record

def update_warehouse_receiving_service(db: Session, record_id: int, schema: WarehouseReceivingUpdate) -> WarehouseReceivingRecord:
    existing = get_warehouse_receiving_service(db, record_id)
    update_data = schema.model_dump(exclude_unset=True, exclude_none=True)
    old_data = {k: getattr(existing, k, None) for k in update_data.keys()}

    updated = update_warehouse_receiving(db, record_id, schema)

    try:
        from modules.audit_logs.service import AuditLogService
        AuditLogService(db).log_activity(
            entity_type="WarehouseReceivingRecord",
            entity_id=updated.receiving_id,
            entity_code=updated.grn_number,
            action="UPDATE",
            old_data=old_data,
            new_data=update_data,
            performed_by="Warehouse Manager",
        )
    except Exception as e:
        import logging
        logging.getLogger(__name__).warning("AuditLog for WarehouseReceivingRecord update failed: %s", e)

    return updated

def soft_delete_warehouse_receiving_service(db: Session, record_id: int) -> bool:
    get_warehouse_receiving_service(db, record_id)
    return soft_delete_warehouse_receiving(db, record_id)

def restore_warehouse_receiving_service(db: Session, record_id: int) -> WarehouseReceivingRecord:
    record = restore_warehouse_receiving(db, record_id)
    if not record:
        raise HTTPException(status_code=404, detail=f"سجل استلام المخزن رقم {record_id} غير موجود.")
    return record


def validate_warehouse_dispatch_authorization(db: Session, record_id: int) -> bool:
    """
    LOG-BOND-003: Strict Quarantine Dispatch Lock Validator.
    Raises HTTP 400 if cargo is under laboratory quarantine lock.
    """
    record = get_warehouse_receiving_service(db, record_id)
    if record.quarantine_lock_active or record.dispatch_blocked:
        raise HTTPException(
            status_code=400,
            detail="ممنوع الصرف أو التداول أو التشغيل: هذه الرسالة محتجزة تحت التحفظ الجمركي المؤقت (سحب على عهدة) لحين ورود شهادة المطابقة المعملية وفك الحظر رسمياً.",
        )
    return True


def submit_warehouse_inspection_protocol_service(
    db: Session,
    record_id: int,
    schema: WarehouseInspectionSubmit,
    user_name: str = "Warehouse QC Committee",
) -> WarehouseReceivingRecord:
    """
    TR-04: Formal Warehouse Inspection & Discrepancy Protocol Issuance.
    - Recalculates quantities (invoiced vs accepted vs shortage vs damaged).
    - Computes discrepancy rate percentage.
    - Assigns formal inspection protocol number (e.g. INSP-2026-XXXX).
    - Sets inspection verdict (ACCEPTED_FULL, ACCEPTED_WITH_DISCREPANCY, REJECTED_QUARANTINED).
    - Records root cause of damage / shortage.
    - Captures insurance and foreign supplier claims.
    - Updates ImportFile current_stage and next_action.
    - Auto-resolves active SmartTasks for TR-04.
    - Dispatches system notification to QC, Operations, and Financial Accounting.
    """
    record = get_warehouse_receiving_service(db, record_id)

    # 1. Update line items if provided
    if schema.grn_items is not None:
        items_dict_list = [item.model_dump() for item in schema.grn_items]
        record.grn_items = items_dict_list
        record.total_invoiced_qty = sum(item.invoiced_qty for item in schema.grn_items)
        record.total_accepted_qty = sum(item.accepted_qty for item in schema.grn_items)
        record.total_shortage_qty = sum(item.shortage_qty for item in schema.grn_items)
        record.total_damaged_qty = sum(item.damaged_qty for item in schema.grn_items)

    # 2. Discrepancy calculations
    total_discrepancy = (record.total_shortage_qty or 0) + (record.total_damaged_qty or 0)
    invoiced = record.total_invoiced_qty or 0
    if invoiced > 0:
        record.discrepancy_rate_percent = round((total_discrepancy / invoiced) * 100.0, 2)
    else:
        record.discrepancy_rate_percent = 0.0

    # 3. Protocol Number Generation
    if not record.inspection_protocol_number:
        current_year = datetime.now(timezone.utc).year
        record.inspection_protocol_number = f"INSP-{current_year}-{record.receiving_id:04d}"

    # 4. Set inspection details
    record.inspection_date = schema.inspection_date or datetime.now(timezone.utc)
    record.inspection_committee = schema.inspection_committee or "لجنة الفحص والاستلام الفني والمخزني"
    record.root_cause = schema.root_cause
    record.quarantine_zone_assigned = schema.quarantine_zone_assigned
    record.insurance_claim_filed = schema.insurance_claim_filed
    record.insurance_claim_ref = schema.insurance_claim_ref
    record.supplier_claim_filed = schema.supplier_claim_filed
    record.supplier_claim_ref = schema.supplier_claim_ref
    record.claim_amount_estimated = schema.claim_amount_estimated or 0.0
    record.claim_currency = schema.claim_currency or "EGP"
    if schema.inspector_name:
        record.inspector_name = schema.inspector_name
    if schema.notes:
        record.notes = schema.notes

    # 5. Determine Verdict and Status
    if schema.quarantine_zone_assigned or record.quarantine_lock_active:
        record.inspection_verdict = "REJECTED_QUARANTINED"
        record.status = "Under Quarantine Inspection"
        record.discrepancy_type = schema.discrepancy_type if schema.discrepancy_type != "None" else "Quarantine Rejection"
    elif total_discrepancy > 0:
        record.inspection_verdict = schema.inspection_verdict or "ACCEPTED_WITH_DISCREPANCY"
        record.status = "Discrepancy Reported"
        if schema.discrepancy_type and schema.discrepancy_type != "None":
            record.discrepancy_type = schema.discrepancy_type
        elif (record.total_shortage_qty or 0) > 0 and (record.total_damaged_qty or 0) > 0:
            record.discrepancy_type = "Shortage & Damaged"
        elif (record.total_shortage_qty or 0) > 0:
            record.discrepancy_type = "Shortage"
        elif (record.total_damaged_qty or 0) > 0:
            record.discrepancy_type = "Damage"
    else:
        record.inspection_verdict = "ACCEPTED_FULL"
        record.status = "Inspection Passed / Clean Receipt"
        record.discrepancy_type = "None"

    if schema.discrepancy_notes:
        record.discrepancy_notes = schema.discrepancy_notes

    record.updated_at = datetime.now(timezone.utc)
    record.updated_by = user_name

    # 6. Update Import File
    from modules.import_files.model import ImportFile
    imp_file = db.query(ImportFile).filter(ImportFile.import_file_id == record.import_file_id).first()
    if imp_file:
        if record.inspection_verdict == "ACCEPTED_FULL":
            stage_text = f"QC Passed - Ready for Landed Cost (GRN: {record.grn_code})"
            next_action_text = "احتساب تكلفة الوصول الفعلية والانحراف (CLO-02) والتسوية الختامية (CLO-01)"
        elif record.inspection_verdict == "REJECTED_QUARANTINED":
            stage_text = f"Quarantined under Inspection ({record.inspection_protocol_number})"
            next_action_text = "متابعة نتائج الفحص المعملي ومطالبات الضمان مع المورد"
        else:
            stage_text = f"Discrepancy Protocol Filed: {record.inspection_protocol_number} ({record.total_shortage_qty} Short, {record.total_damaged_qty} Damaged)"
            next_action_text = "متابعة تسوية التعويض مع التأمين/المورد (CLO-01) واحتساب تكلفة الوصول (CLO-02)"

        imp_file.current_stage = stage_text
        imp_file.next_action = next_action_text
        if (imp_file.progress_percent or 0.0) < 99.0:
            imp_file.progress_percent = 99.0

    db.commit()
    db.refresh(record)

    # 7. Auto-resolve TR-04 SmartTasks
    try:
        from modules.smart_tasks.model import SmartTask
        tr04_tasks = db.query(SmartTask).filter(
            SmartTask.import_file_id == record.import_file_id,
            SmartTask.status.in_(["Pending", "In Progress"]),
        ).all()
        for task in tr04_tasks:
            if (task.task_type == "TR-04") or ("TR-04" in (task.title or "")) or ("الفحص الفني" in (task.title or "")):
                task.status = "Completed"
                task.completed_at = datetime.now(timezone.utc)
                task.resolution_notes = f"تم اعتماد محضر الفحص الفني ({record.inspection_protocol_number}) بنتيجة: {record.inspection_verdict} بواسطة {user_name}."
        db.commit()
    except Exception:
        pass

    # 8. Dispatch System Notification
    try:
        from modules.notifications.service import create_system_notification
        claim_info = ""
        if record.insurance_claim_filed:
            claim_info += f" | مطالبة تأمين: {record.insurance_claim_ref or 'قيد التسجيل'}"
        if record.supplier_claim_filed:
            claim_info += f" | إشعار خصم مورد: {record.supplier_claim_ref or 'قيد التسجيل'}"

        create_system_notification(
            db=db,
            title=f"محضر الفحص المخزني والمطابقة ({record.inspection_protocol_number})",
            message=f"اعتمدت {record.inspection_committee} محضر الفحص للشحنة {imp_file.import_file_code if imp_file else ''}. النتيجة: {record.inspection_verdict} (مقبول: {record.total_accepted_qty}, عجز: {record.total_shortage_qty}, تالف: {record.total_damaged_qty}){claim_info}.",
            severity="WARNING" if total_discrepancy > 0 else "INFO",
            category="Quality Control & Inspection",
            reference_id=record.receiving_id,
        )
    except Exception:
        pass

    return record


def get_inspection_summary_service(db: Session, record_id: int) -> InspectionSummaryResponse:
    record = get_warehouse_receiving_service(db, record_id)
    total_discrepancy = (record.total_shortage_qty or 0) + (record.total_damaged_qty or 0)
    return InspectionSummaryResponse(
        receiving_id=record.receiving_id,
        grn_code=record.grn_code,
        import_file_id=record.import_file_id,
        inspection_protocol_number=record.inspection_protocol_number,
        inspection_date=record.inspection_date or record.arrival_datetime,
        inspection_committee=record.inspection_committee,
        inspection_verdict=record.inspection_verdict or ("ACCEPTED_FULL" if total_discrepancy == 0 else "ACCEPTED_WITH_DISCREPANCY"),
        root_cause=record.root_cause,
        total_invoiced_qty=record.total_invoiced_qty or 0,
        total_accepted_qty=record.total_accepted_qty or 0,
        total_shortage_qty=record.total_shortage_qty or 0,
        total_damaged_qty=record.total_damaged_qty or 0,
        discrepancy_rate_percent=record.discrepancy_rate_percent or 0.0,
        quarantine_zone_assigned=record.quarantine_zone_assigned or False,
        insurance_claim_filed=record.insurance_claim_filed or False,
        insurance_claim_ref=record.insurance_claim_ref,
        supplier_claim_filed=record.supplier_claim_filed or False,
        supplier_claim_ref=record.supplier_claim_ref,
        claim_amount_estimated=record.claim_amount_estimated or 0.0,
        claim_currency=record.claim_currency or "EGP",
        status=record.status or "Goods Received",
        is_ready_for_landed_cost=(record.inspection_verdict != "REJECTED_QUARANTINED" and not record.quarantine_lock_active),
    )

