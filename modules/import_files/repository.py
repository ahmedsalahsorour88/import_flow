"""
Repository Layer for Import Files Master & Tracking Module
"""

from typing import List, Optional
from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import or_

from modules.import_files.model import ImportFile


def generate_import_file_code(db: Session) -> str:
    """Generates unique import file code: IMP-YYYY-XXXX"""
    current_year = datetime.utcnow().year
    prefix = f"IMP-{current_year}-"
    count = db.query(ImportFile).filter(ImportFile.import_file_code.like(f"{prefix}%")).count()
    return f"{prefix}{count + 1:04d}"


def get_all_import_files(
    db: Session,
    include_inactive: bool = False,
    search: Optional[str] = None,
    company_id: Optional[int] = None,
    supplier_id: Optional[int] = None,
    status: Optional[str] = None,
    owner: Optional[str] = None,
) -> List[ImportFile]:
    query = db.query(ImportFile)
    if not include_inactive:
        query = query.filter(ImportFile.is_active == True)

    if company_id:
        query = query.filter(ImportFile.company_id == company_id)
    if supplier_id:
        query = query.filter(ImportFile.supplier_id == supplier_id)
    if status and status != "All":
        query = query.filter(ImportFile.status == status)
    if owner and owner != "All":
        query = query.filter(ImportFile.owner == owner)

    if search and search.strip():
        term = f"%{search.strip()}%"
        query = query.filter(
            or_(
                ImportFile.import_file_code.ilike(term),
                ImportFile.custom_file_number.ilike(term),
                ImportFile.company_name.ilike(term),
                ImportFile.supplier_name.ilike(term),
                ImportFile.po_number.ilike(term),
                ImportFile.pi_number.ilike(term),
                ImportFile.owner.ilike(term),
            )
        )

    return query.order_by(ImportFile.import_file_id.desc()).all()


def get_import_file_by_id(db: Session, import_file_id: int) -> Optional[ImportFile]:
    return db.query(ImportFile).filter(
        ImportFile.import_file_id == import_file_id,
        ImportFile.is_active == True
    ).first()


def get_import_file_by_code(db: Session, code_or_custom_num: str) -> Optional[ImportFile]:
    return db.query(ImportFile).filter(
        or_(
            ImportFile.import_file_code == code_or_custom_num,
            ImportFile.custom_file_number == code_or_custom_num,
        ),
        ImportFile.is_active == True
    ).first()


def create_import_file(db: Session, obj_data: dict) -> ImportFile:
    db_obj = ImportFile(**obj_data)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def update_import_file(db: Session, import_file_id: int, update_data: dict) -> Optional[ImportFile]:
    db_obj = get_import_file_by_id(db, import_file_id)
    if not db_obj:
        return None

    for key, value in update_data.items():
        if hasattr(db_obj, key) and value is not None:
            setattr(db_obj, key, value)

    db_obj.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_obj)
    return db_obj


def soft_delete_import_file(db: Session, import_file_id: int) -> bool:
    db_obj = get_import_file_by_id(db, import_file_id)
    if not db_obj:
        return False

    db_obj.is_active = False
    db_obj.updated_at = datetime.utcnow()
    db.commit()
    return True
