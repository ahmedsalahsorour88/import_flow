from datetime import datetime
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
    """BP-031 Record Customs Duty Payment."""
    validate_bank_receipt_no(payload.bank_receipt_no)
    
    record = get_customs_clearance_service(db, record_id)
    record.bank_receipt_no = payload.bank_receipt_no
    record.paying_bank_name = payload.paying_bank_name
    record.payment_date = payload.payment_date
    record.payment_notes = payload.payment_notes
    record.payment_status = "Paid & Verified"
    record.status = "Duty Paid"
    record.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(record)
    return record

def complete_customs_release_service(db: Session, record_id: int, payload: CompleteReleaseSubmit) -> CustomsClearanceRecord:
    """BP-032 Complete Final Customs Release Order."""
    record = get_customs_clearance_service(db, record_id)
    validate_release_permit(payload.release_permit_no, record.payment_status)

    record.release_permit_no = payload.release_permit_no
    record.release_date = payload.release_date
    record.demurrage_storage_fees = payload.demurrage_storage_fees
    record.dispatch_authorized = payload.dispatch_authorized
    record.dispatch_date = datetime.utcnow() if payload.dispatch_authorized else None
    record.status = "Final Release Granted"
    if payload.notes:
        record.notes = payload.notes
    record.updated_at = datetime.utcnow()

    # Update import file operational stage
    imp_file = db.query(ImportFile).filter(ImportFile.import_file_id == record.import_file_id).first()
    if imp_file:
        imp_file.current_module = "Phase 7 - Customs Clearance & Inspection"
        imp_file.current_stage = "Customs Release Permit Issued"
        imp_file.progress_percent = 75.0
        imp_file.next_action = "Warehouse Receiving & Dispatch"

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

def soft_delete_customs_clearance_service(db: Session, record_id: int) -> bool:
    get_customs_clearance_service(db, record_id)
    return soft_delete_customs_clearance(db, record_id)

def restore_customs_clearance_service(db: Session, record_id: int) -> CustomsClearanceRecord:
    record = restore_customs_clearance(db, record_id)
    if not record:
        raise HTTPException(status_code=404, detail=f"سجل التخليص الجمركي رقم {record_id} غير موجود.")
    return record
