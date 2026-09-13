"""
Database Repository for Smart Import Checklist Engine
"""

from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import select, and_

from modules.smart_checklists.model import ImportFileChecklistItem, DEFAULT_CHECKLIST_QUESTIONS
from modules.import_files.model import ImportFile


def get_items_by_file(
    db: Session,
    file_id: int,
    phase_code: Optional[str] = None,
    role: Optional[str] = None,
    status: Optional[str] = None,
) -> List[ImportFileChecklistItem]:
    """Retrieve checklist items for an import file with optional filters."""
    query = select(ImportFileChecklistItem).where(
        ImportFileChecklistItem.import_file_id == file_id,
        ImportFileChecklistItem.is_active == True,
    )

    if phase_code and phase_code != "ALL":
        query = query.where(ImportFileChecklistItem.phase_code == phase_code)

    if role and role != "ALL":
        query = query.where(ImportFileChecklistItem.responsible_role == role)

    if status and status != "ALL":
        query = query.where(ImportFileChecklistItem.status == status)

    query = query.order_by(ImportFileChecklistItem.item_id.asc())
    return list(db.scalars(query).all())


def get_item_by_id(db: Session, item_id: int) -> Optional[ImportFileChecklistItem]:
    """Retrieve a single checklist item by PK."""
    return db.scalar(
        select(ImportFileChecklistItem).where(
            ImportFileChecklistItem.item_id == item_id,
            ImportFileChecklistItem.is_active == True,
        )
    )


def seed_checklist_for_file(db: Session, file_id: int, file_code: Optional[str] = None) -> List[ImportFileChecklistItem]:
    """Seed the default 23 master questions if not already initialized for this file."""
    existing = get_items_by_file(db, file_id)
    if existing:
        return existing

    if not file_code:
        file_obj = db.scalar(select(ImportFile).where(ImportFile.import_file_id == file_id))
        file_code = file_obj.import_file_code if file_obj else f"FILE-{file_id}"

    created_items = []
    for q in DEFAULT_CHECKLIST_QUESTIONS:
        item = ImportFileChecklistItem(
            import_file_id=file_id,
            import_file_code=file_code,
            phase_code=q["phase_code"],
            question_code=q["question_code"],
            question_title_ar=q["question_title_ar"],
            description_ar=q["description_ar"],
            question_title_en=q.get("question_title_en"),
            description_en=q.get("description_en"),
            responsible_role=q["responsible_role"],
            is_mandatory=q["is_mandatory"],
            verification_type=q["verification_type"],
            auto_check_source=q["auto_check_source"],
            action_route=q.get("action_route"),
            status="PENDING",
            created_by="System",
            updated_by="System",
        )
        db.add(item)
        created_items.append(item)

    db.commit()
    for itm in created_items:
        db.refresh(itm)
    return created_items


def update_item_status(
    db: Session,
    item_id: int,
    status: str,
    verified_by: Optional[str] = "System",
    notes: Optional[str] = None,
    override_reason: Optional[str] = None,
) -> Optional[ImportFileChecklistItem]:
    """Update verification status, audit details, and optional override reason."""
    item = get_item_by_id(db, item_id)
    if not item:
        return None

    item.status = status
    item.verified_by = verified_by
    item.verified_at = datetime.now(timezone.utc)
    if notes is not None:
        item.notes = notes
    if override_reason is not None:
        item.override_reason = override_reason

    item.updated_at = datetime.now(timezone.utc)
    item.updated_by = verified_by or "System"

    db.commit()
    db.refresh(item)
    return item
