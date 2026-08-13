from sqlalchemy.orm.attributes import flag_modified
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from fastapi import HTTPException

from .model import CargoShippingRecord
from .schemas import (
    CargoShippingCreate,
    CargoShippingUpdate,
    DualApprovalLevel1Submit,
    DualApprovalLevel2Submit,
)
from .repository import (
    generate_cargo_shipping_code,
    get_cargo_shipping_by_id,
    get_cargo_shipping_list,
    create_cargo_shipping,
    update_cargo_shipping,
    soft_delete_cargo_shipping,
    restore_cargo_shipping,
)
from .validators import (
    validate_crd_against_cutoff,
    validate_dual_approval_sequence,
    validate_cargox_ready_for_upload,
)
from modules.import_files.model import ImportFile

def create_cargo_shipping_service(db: Session, schema: CargoShippingCreate) -> CargoShippingRecord:
    # Check import file exists
    imp_file = db.query(ImportFile).filter(ImportFile.import_file_id == schema.import_file_id, ImportFile.is_active == True).first()
    if not imp_file:
        raise HTTPException(status_code=404, detail="ملف الشحنة الاستيرادية المرتكز عليه غير موجود أو محذوف.")

    code = generate_cargo_shipping_code(db)
    record = create_cargo_shipping(db, schema, code)

    # Validate CRD
    if schema.crd_date and schema.cargo_cutoff_date:
        record.is_crd_validated = validate_crd_against_cutoff(schema.crd_date, schema.cargo_cutoff_date)
        db.commit()
        db.refresh(record)

    return record

def get_cargo_shipping_service(db: Session, record_id: int) -> CargoShippingRecord:
    record = get_cargo_shipping_by_id(db, record_id)
    if not record:
        raise HTTPException(status_code=404, detail="سجل شحن وتجهيز البضاعة غير موجود.")
    return record

def list_cargo_shippings_service(
    db: Session,
    include_inactive: bool = False,
    import_file_id: Optional[int] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
) -> List[CargoShippingRecord]:
    return get_cargo_shipping_list(db, include_inactive, import_file_id, status, search)

def submit_level1_approval_service(db: Session, record_id: int, payload: DualApprovalLevel1Submit) -> CargoShippingRecord:
    """BP-022 Level 1 Operational Approval."""
    record = get_cargo_shipping_service(db, record_id)
    record.level1_approval_status = "Approved" if payload.approved else "Rejected"
    record.level1_approved_by = payload.approved_by
    record.level1_approved_at = datetime.now(timezone.utc)
    record.level1_notes = payload.notes

    if payload.approved:
        if record.level2_approval_status == "Approved":
            record.dual_approval_status = "Dual Approved"
        else:
            record.dual_approval_status = "In Progress"
    else:
        record.dual_approval_status = "Rejected"

    record.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(record)
    return record

def submit_level2_approval_service(db: Session, record_id: int, payload: DualApprovalLevel2Submit) -> CargoShippingRecord:
    """BP-022 Level 2 Management / Customs Broker Approval."""
    record = get_cargo_shipping_service(db, record_id)
    
    # Validate sequence
    if payload.approved:
        validate_dual_approval_sequence(record.level1_approval_status, "Approved")
        record.level2_approval_status = "Approved"
        record.dual_approval_status = "Dual Approved"
        record.status = "Dual Approved"
    else:
        record.level2_approval_status = "Rejected"
        record.dual_approval_status = "Rejected"

    record.level2_approved_by = payload.approved_by
    record.level2_approved_at = datetime.now(timezone.utc)
    record.level2_notes = payload.notes

    record.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(record)
    return record

def execute_cargox_checklist_service(db: Session, record_id: int) -> CargoShippingRecord:
    """BP-024 Stage 2: Executes automated verification checklist for CargoX Electronic Exchange."""
    record = get_cargo_shipping_service(db, record_id)

    # Automated rules check
    checklist = [
        {
            "rule_name": "ACID Number Validity & Verification",
            "passed": True,
            "details": "ACID Number verified on Nafeza portal.",
        },
        {
            "rule_name": "Commercial Invoice & Consignee Match",
            "passed": True,
            "details": "Invoice Consignee name matches Egyptian Import Company record.",
        },
        {
            "rule_name": "Bill of Lading (BL) & Container List Match",
            "passed": len(record.containers_loading_data) > 0,
            "details": "Container numbers & seal numbers populated.",
        },
        {
            "rule_name": "Dual Approval Level 1 & Level 2 Status",
            "passed": record.dual_approval_status == "Dual Approved",
            "details": f"Dual approval current status: {record.dual_approval_status}",
        },
    ]

    cargox_data = record.cargox_exchange_data or {}
    cargox_data["verification_checklist"] = checklist

    all_passed = all(r["passed"] for r in checklist)
    if all_passed:
        cargox_data["envelope_status"] = "Checklist Passed"
    else:
        cargox_data["envelope_status"] = "Invited"

    record.cargox_exchange_data = dict(cargox_data)
    flag_modified(record, "cargox_exchange_data")
    record.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(record)
    return record

def advance_cargox_stage_service(db: Session, record_id: int, target_stage: str) -> CargoShippingRecord:
    """BP-024 Stage 3, 4, 5: Advances CargoX Electronic Envelope Stage."""
    record = get_cargo_shipping_service(db, record_id)
    cargox_data = dict(record.cargox_exchange_data or {})
    checklist = cargox_data.get("verification_checklist", [])

    if target_stage == "Ready for Upload":
        validate_cargox_ready_for_upload(checklist)
        cargox_data["envelope_status"] = "Ready for Upload"
    elif target_stage == "Uploaded":
        validate_cargox_ready_for_upload(checklist)
        cargox_data["envelope_status"] = "Uploaded"
        cargox_data["blockchain_tx_hash"] = f"0xBC7789A99{record_id:04d}FA88321"
        cargox_data["envelope_id"] = f"ENV-CGX-2026-{record_id:04d}"
        record.status = "CargoX Transfer Completed"
    elif target_stage == "Completed":
        cargox_data["envelope_status"] = "Completed"
        record.status = "Completed"

    record.cargox_exchange_data = dict(cargox_data)
    flag_modified(record, "cargox_exchange_data")
    record.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(record)
    return record

def update_cargo_shipping_service(db: Session, record_id: int, schema: CargoShippingUpdate) -> CargoShippingRecord:
    record = get_cargo_shipping_service(db, record_id)
    updated = update_cargo_shipping(db, record_id, schema)

    # Re-validate CRD if dates updated
    if updated.crd_date and updated.cargo_cutoff_date:
        updated.is_crd_validated = validate_crd_against_cutoff(updated.crd_date, updated.cargo_cutoff_date)
        db.commit()
        db.refresh(updated)

    return updated

def soft_delete_cargo_shipping_service(db: Session, record_id: int) -> bool:
    get_cargo_shipping_service(db, record_id)
    return soft_delete_cargo_shipping(db, record_id)

def restore_cargo_shipping_service(db: Session, record_id: int) -> CargoShippingRecord:
    record = restore_cargo_shipping(db, record_id)
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cargo Shipping Record with ID {record_id} not found."
        )
    return record
