from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException

from .model import WarehouseReceivingRecord
from .schemas import (
    WarehouseReceivingCreate,
    WarehouseReceivingUpdate,
    DiscrepancyReportSubmit,
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

    validate_seal_integrity(schema.seal_intact, schema.seal_number or "")

    code = generate_grn_code(db)
    record = create_warehouse_receiving(db, schema, code)

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

    # Auto update import file stage
    imp_file.current_module = "Phase 8 - Warehouse Receiving & Quality Control"
    if record.quarantine_lock_active:
        imp_file.current_stage = f"Under-Bond Quarantine at {schema.warehouse_name} (GRN: {code})"
        imp_file.next_action = "Awaiting Laboratory Test Approval before Production"
    else:
        imp_file.current_stage = f"Goods Received at {schema.warehouse_name} (GRN: {code})"
        imp_file.next_action = "Landed Cost Settlement & Invoice Clearance"
    imp_file.progress_percent = 85.0
    db.commit()

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
    get_warehouse_receiving_service(db, record_id)
    return update_warehouse_receiving(db, record_id, schema)

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

