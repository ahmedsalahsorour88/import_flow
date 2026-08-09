from datetime import datetime
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import desc

from .model import ImportFileClosureRecord
from .schemas import FileClosureCreate, FileClosureUpdate

def generate_closure_code(db: Session) -> str:
    """Generates unique File Closure Code in format CLR-YYYY-XXXX."""
    current_year = datetime.utcnow().year
    prefix = f"CLR-{current_year}-"
    
    last_record = (
        db.query(ImportFileClosureRecord)
        .filter(ImportFileClosureRecord.closure_code.like(f"{prefix}%"))
        .order_by(desc(ImportFileClosureRecord.closure_id))
        .first()
    )
    
    if last_record:
        try:
            last_seq = int(last_record.closure_code.split("-")[-1])
            new_seq = last_seq + 1
        except ValueError:
            new_seq = 1
    else:
        new_seq = 1
        
    return f"{prefix}{new_seq:04d}"

def get_closure_by_id(db: Session, closure_id: int, include_inactive: bool = False) -> Optional[ImportFileClosureRecord]:
    query = db.query(ImportFileClosureRecord).filter(ImportFileClosureRecord.closure_id == closure_id)
    if not include_inactive:
        query = query.filter(ImportFileClosureRecord.is_active == True)
    return query.first()

def get_closure_by_import_file_id(db: Session, import_file_id: int) -> Optional[ImportFileClosureRecord]:
    return db.query(ImportFileClosureRecord).filter(
        ImportFileClosureRecord.import_file_id == import_file_id,
        ImportFileClosureRecord.is_active == True
    ).first()

def list_closures(
    db: Session,
    include_inactive: bool = False,
    import_file_id: Optional[int] = None,
    search: Optional[str] = None,
) -> List[ImportFileClosureRecord]:
    query = db.query(ImportFileClosureRecord)
    if not include_inactive:
        query = query.filter(ImportFileClosureRecord.is_active == True)
    if import_file_id:
        query = query.filter(ImportFileClosureRecord.import_file_id == import_file_id)
    if search:
        pattern = f"%{search}%"
        query = query.filter(
            (ImportFileClosureRecord.closure_code.ilike(pattern)) |
            (ImportFileClosureRecord.auditor_name.ilike(pattern))
        )
    return query.order_by(desc(ImportFileClosureRecord.closure_id)).all()

def create_closure(db: Session, schema: FileClosureCreate, code: str) -> ImportFileClosureRecord:
    checklist = schema.closure_checklist.model_dump()
    db_obj = ImportFileClosureRecord(
        closure_code=code,
        import_file_id=schema.import_file_id,
        closure_checklist=checklist,
        auditor_name=schema.auditor_name,
        archive_location=schema.archive_location,
        archival_notes=schema.archival_notes,
        status="Closed",
        closed_at=datetime.utcnow(),
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj

def update_closure(db: Session, closure_id: int, schema: FileClosureUpdate) -> Optional[ImportFileClosureRecord]:
    db_obj = get_closure_by_id(db, closure_id, include_inactive=True)
    if not db_obj:
        return None

    update_data = schema.model_dump(exclude_unset=True)
    if "closure_checklist" in update_data and update_data["closure_checklist"] is not None:
        db_obj.closure_checklist = schema.closure_checklist.model_dump()
        del update_data["closure_checklist"]

    for key, value in update_data.items():
        setattr(db_obj, key, value)

    db_obj.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_obj)
    return db_obj

def soft_delete_closure(db: Session, closure_id: int) -> bool:
    db_obj = get_closure_by_id(db, closure_id, include_inactive=False)
    if not db_obj:
        return False
    db_obj.is_active = False
    db_obj.updated_at = datetime.utcnow()
    db.commit()
    return True
