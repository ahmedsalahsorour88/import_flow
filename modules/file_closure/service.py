from datetime import datetime
from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException

from .model import ImportFileClosureRecord
from .schemas import FileClosureCreate, FileClosureUpdate
from .repository import (
    generate_closure_code,
    get_closure_by_id,
    get_closure_by_import_file_id,
    list_closures,
    create_closure,
    update_closure,
    soft_delete_closure,
    restore_closure,
)
from .validators import validate_closure_checklist
from modules.import_files.model import ImportFile

def close_import_file_service(db: Session, schema: FileClosureCreate) -> ImportFileClosureRecord:
    imp_file = db.query(ImportFile).filter(ImportFile.import_file_id == schema.import_file_id, ImportFile.is_active == True).first()
    if not imp_file:
        raise HTTPException(status_code=404, detail="ملف الشحنة الاستيرادية المرتكز عليه غير موجود أو محذوف.")

    checklist_dict = schema.closure_checklist.model_dump()
    completed_count = sum(1 for v in checklist_dict.values() if v)
    total_items = len(checklist_dict) if checklist_dict else 5
    progress_percent = (completed_count / total_items) * 100.0 if total_items > 0 else 0.0

    # ── DB-Enforced Closure Validation (for non-draft final closure) ─────────
    if not schema.is_draft:
        validate_closure_checklist(checklist_dict, getattr(imp_file, 'skipped_stages', None))

        db_errors = []

        # 1. Verify customs clearance has Final Release Granted
        try:
            from modules.customs_clearance.model import CustomsClearanceRecord
            clearance = db.query(CustomsClearanceRecord).filter(
                CustomsClearanceRecord.import_file_id == schema.import_file_id,
                CustomsClearanceRecord.is_active == True,
                CustomsClearanceRecord.status == "Final Release Granted",
            ).first()
            if not clearance and not (imp_file.skipped_stages and "STEP_17" in (imp_file.skipped_stages or [])):
                db_errors.append("لم يتم إتمام التخليص الجمركي النهائي (Final Release Granted) لهذا الملف.")
        except Exception:
            pass

        # 2. Verify at least one GRN exists
        try:
            from modules.warehouse_receiving.model import WarehouseReceivingRecord
            grn = db.query(WarehouseReceivingRecord).filter(
                WarehouseReceivingRecord.import_file_id == schema.import_file_id,
                WarehouseReceivingRecord.is_active == True,
            ).first()
            if not grn and not (imp_file.skipped_stages and "STEP_19" in (imp_file.skipped_stages or [])):
                db_errors.append("لم يتم إصدار إذن إضافة (GRN) لاستلام البضاعة في المخزن.")
        except Exception:
            pass

        # 3. Verify financial settlement exists and is calculated
        try:
            from modules.financial_settlement.model import LandedCostSettlementRecord
            settlement = db.query(LandedCostSettlementRecord).filter(
                LandedCostSettlementRecord.import_file_id == schema.import_file_id,
                LandedCostSettlementRecord.is_active == True,
                LandedCostSettlementRecord.status.in_(["Calculated", "Approved", "Closed"]),
            ).first()
            if not settlement and not (imp_file.skipped_stages and "STEP_20" in (imp_file.skipped_stages or [])):
                db_errors.append("لم يتم إنشاء أو اعتماد تسوية التكلفة الاستيرادية الشاملة (Landed Cost Settlement).")
        except Exception:
            pass

        if db_errors:
            raise HTTPException(
                status_code=400,
                detail="لا يمكن إغلاق الملف نهائياً — المتطلبات التالية غير مستوفاة:\n" + "\n".join(f"• {e}" for e in db_errors)
            )

    existing_record = get_closure_by_import_file_id(db, schema.import_file_id)
    if existing_record:
        existing_record.closure_checklist = checklist_dict
        existing_record.auditor_name = schema.auditor_name
        existing_record.archive_location = schema.archive_location
        existing_record.archival_notes = schema.archival_notes
        existing_record.status = "Draft" if schema.is_draft else "Closed"
        record = existing_record
    else:
        code = generate_closure_code(db)
        record = create_closure(db, schema, code)
        record.status = "Draft" if schema.is_draft else "Closed"

    if schema.is_draft:
        imp_file.current_module = "Phase 10 - Import File Closure & Historical Archive (Draft)"
        imp_file.current_stage = f"Closure In-Progress ({completed_count}/{total_items} items - {progress_percent:.0f}%)"
        imp_file.next_action = "Complete remaining closure checklist tasks"
    else:
        # Set ImportFile to 100% progress and status Closed
        imp_file.status = "Closed"
        imp_file.current_module = "Phase 10 - Import File Closure & Historical Archive"
        imp_file.current_stage = f"Archived & Closed (Certificate: {record.closure_code})"
        if (imp_file.progress_percent or 0.0) < 100.0:
            imp_file.progress_percent = 100.0
        imp_file.next_action = "File Archived - Read-Only Historical State"

    db.commit()
    db.refresh(record)

    # Lifecycle advance: STEP_20 → STEP_21 (Settlement approved → Final Closure)
    if not schema.is_draft:
        try:
            from modules.lifecycle_board.service import advance_lifecycle_step_service
            advance_lifecycle_step_service(
                db=db,
                import_file_id=schema.import_file_id,
                completed_step_code="STEP_20",
                target_step_codes=["STEP_21"],
                notes=f"تم الإغلاق النهائي للملف الاستيرادي وأرشفته (الكود: {record.closure_code}) بواسطة {schema.auditor_name or 'Finance Manager'}.",
                assigned_user=schema.auditor_name or "Finance Manager",
            )
        except Exception as e:
            import logging
            logging.getLogger(__name__).warning("Lifecycle advance STEP_20→STEP_21 failed: %s", e)

    return record


def get_closure_service(db: Session, closure_id: int) -> ImportFileClosureRecord:
    record = get_closure_by_id(db, closure_id)
    if not record:
        raise HTTPException(status_code=404, detail="سجل إغلاق وأرشفة الملف غير موجود.")
    return record

def list_closures_service(
    db: Session,
    include_inactive: bool = False,
    import_file_id: Optional[int] = None,
    search: Optional[str] = None,
) -> List[ImportFileClosureRecord]:
    return list_closures(db, include_inactive, import_file_id, search)

def update_closure_service(db: Session, closure_id: int, schema: FileClosureUpdate) -> ImportFileClosureRecord:
    get_closure_service(db, closure_id)
    updated = update_closure(db, closure_id, schema)
    if not updated:
        raise HTTPException(status_code=404, detail="فشل تحديث سجل الإغلاق.")
    return updated

def soft_delete_closure_service(db: Session, closure_id: int) -> bool:
    get_closure_service(db, closure_id)
    return soft_delete_closure(db, closure_id)

def restore_closure_service(db: Session, closure_id: int) -> ImportFileClosureRecord:
    record = restore_closure(db, closure_id)
    if not record:
        raise HTTPException(status_code=404, detail=f"سجل أرشفة وإغلاق الملف رقم {closure_id} غير موجود.")
    return record
