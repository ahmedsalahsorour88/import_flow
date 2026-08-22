from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException

from .model import CustomsClearanceRecord
from .schemas import (
    CustomsClearanceCreate,
    CustomsClearanceUpdate,
    DutyPaymentSubmit,
    CompleteReleaseSubmit,
)
from .repository import (
    generate_customs_clearance_code,
    get_customs_clearance_by_id,
    get_customs_clearance_list,
    create_customs_clearance,
    update_customs_clearance,
    soft_delete_customs_clearance,
    restore_customs_clearance,
)
from .validators import validate_bank_receipt_no, validate_release_permit
from modules.import_files.model import ImportFile

def create_customs_clearance_service(db: Session, schema: CustomsClearanceCreate) -> CustomsClearanceRecord:
    # Check import file exists
    imp_file = db.query(ImportFile).filter(ImportFile.import_file_id == schema.import_file_id, ImportFile.is_active == True).first()
    if not imp_file:
        raise HTTPException(status_code=404, detail="ملف الشحنة الاستيرادية المرتكز عليه غير موجود أو محذوف.")

    code = generate_customs_clearance_code(db)
    record = create_customs_clearance(db, schema, code)

    # Auto sync declaration 46 code if provided
    if schema.declaration_46_no:
        imp_file.form46_no = schema.declaration_46_no
        db.commit()

    return record

def get_customs_clearance_service(db: Session, record_id: int) -> CustomsClearanceRecord:
    record = get_customs_clearance_by_id(db, record_id)
    if not record:
        raise HTTPException(status_code=404, detail="سجل التخليص الجمركي والمعاينة غير موجود.")
    return record

def list_customs_clearances_service(
    db: Session,
    include_inactive: bool = False,
    import_file_id: Optional[int] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
) -> List[CustomsClearanceRecord]:
    return get_customs_clearance_list(db, include_inactive, import_file_id, status, search)

def submit_duty_payment_service(db: Session, record_id: int, payload: DutyPaymentSubmit) -> CustomsClearanceRecord:
    """BP-031 Record Customs Duty Payment & Match Final Customs Ledger."""
    validate_bank_receipt_no(payload.bank_receipt_no)
    
    record = get_customs_clearance_service(db, record_id)
    record.bank_receipt_no = payload.bank_receipt_no
    record.paying_bank_name = payload.paying_bank_name
    record.payment_date = payload.payment_date
    record.payment_notes = payload.payment_notes
    
    if payload.actual_duty_total is not None and payload.actual_duty_total > 0:
        record.actual_duty_total = payload.actual_duty_total
    elif record.actual_duty_total == 0.0:
        record.actual_duty_total = record.total_duty_payable
        
    if payload.estimated_duty_total is not None and payload.estimated_duty_total > 0:
        record.estimated_duty_total = payload.estimated_duty_total

    if record.estimated_duty_total > 0:
        record.duty_variance_amount = record.actual_duty_total - record.estimated_duty_total
        record.duty_variance_percentage = round((record.duty_variance_amount / record.estimated_duty_total) * 100, 2)

    if payload.duty_variance_reason:
        record.duty_variance_reason = payload.duty_variance_reason

    if payload.nafeza_assessment_json:
        record.nafeza_assessment_json = payload.nafeza_assessment_json

    record.payment_status = "Paid & Verified"
    record.status = "Duty Paid"
    record.updated_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(record)
    return record

def complete_customs_release_service(db: Session, record_id: int, payload: CompleteReleaseSubmit) -> CustomsClearanceRecord:
    """BP-032 Complete Final Customs Release Order."""
    record = get_customs_clearance_service(db, record_id)
    validate_release_permit(payload.release_permit_no, record.payment_status)

    record.release_permit_no = payload.release_permit_no
    record.release_date = payload.release_date
    if payload.port_gate_out_date:
        record.port_gate_out_date = payload.port_gate_out_date
    record.demurrage_storage_fees = payload.demurrage_storage_fees
    record.dispatch_authorized = payload.dispatch_authorized
    record.dispatch_date = datetime.now(timezone.utc) if payload.dispatch_authorized else None
    record.status = "Final Release Granted"
    if payload.notes:
        record.notes = payload.notes
    record.updated_at = datetime.now(timezone.utc)

    # Update import file operational stage and release state
    imp_file = db.query(ImportFile).filter(ImportFile.import_file_id == record.import_file_id).first()
    if imp_file:
        imp_file.current_module = "Phase 7 - Customs Clearance & Inspection"
        imp_file.current_stage = "Customs Release Permit Issued"
        imp_file.progress_percent = 75.0
        imp_file.next_action = "Warehouse Receiving & Dispatch"
        imp_file.is_customs_released = True
        imp_file.customs_released_at = payload.release_date or datetime.now(timezone.utc)

    db.commit()
    db.refresh(record)
    return record

def update_customs_clearance_service(db: Session, record_id: int, schema: CustomsClearanceUpdate) -> CustomsClearanceRecord:
    get_customs_clearance_service(db, record_id)
    updated = update_customs_clearance(db, record_id, schema)

    if schema.declaration_46_no:
        imp_file = db.query(ImportFile).filter(ImportFile.import_file_id == updated.import_file_id).first()
        if imp_file:
            imp_file.form46_no = schema.declaration_46_no
            db.commit()

    return updated

def delete_customs_clearance_service(db: Session, record_id: int) -> bool:
    get_customs_clearance_service(db, record_id)
    return soft_delete_customs_clearance(db, record_id)

soft_delete_customs_clearance_service = delete_customs_clearance_service

def restore_customs_clearance_service(db: Session, record_id: int) -> CustomsClearanceRecord:
    restored = restore_customs_clearance(db, record_id)
    if not restored:
        raise HTTPException(status_code=404, detail="السجل المطلوب استعادته غير موجود.")
    return restored
