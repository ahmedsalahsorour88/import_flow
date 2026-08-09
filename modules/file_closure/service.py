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
)
from .validators import validate_closure_checklist
from modules.import_files.model import ImportFile

def close_import_file_service(db: Session, schema: FileClosureCreate) -> ImportFileClosureRecord:
    imp_file = db.query(ImportFile).filter(ImportFile.import_file_id == schema.import_file_id, ImportFile.is_active == True).first()
    if not imp_file:
        raise HTTPException(status_code=404, detail="ملف الشحنة الاستيرادية المرتكز عليه غير موجود أو محذوف.")

    checklist_dict = schema.closure_checklist.model_dump()
    validate_closure_checklist(checklist_dict)

    code = generate_closure_code(db)
    record = create_closure(db, schema, code)

    # Set ImportFile to 100% progress and status Closed
    imp_file.status = "Closed"
    imp_file.current_module = "Phase 10 - Import File Closure & Historical Archive"
    imp_file.current_stage = f"Archived & Closed (Certificate: {code})"
    imp_file.progress_percent = 100.0
    imp_file.next_action = "File Archived - Read-Only Historical State"
    db.commit()

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
