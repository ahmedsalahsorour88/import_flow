"""
Repository for Formal Letter Records (AI-DRAFT-014)
"""

from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import desc

from .model import FormalLetterRecord


def create_letter_record(db: Session, data: dict, user: str = "System") -> FormalLetterRecord:
    count = db.query(FormalLetterRecord).count() + 1
    letter_code = f"LTR-{count:05d}"

    record = FormalLetterRecord(
        letter_code=letter_code,
        import_file_id=data["import_file_id"],
        template_type=data["template_type"],
        letter_title_ar=data["letter_title_ar"],
        recipient_name=data.get("recipient_name"),
        letter_body=data["letter_body"],
        notes=data.get("notes"),
        created_by=user,
        updated_by=user,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def get_letters_by_file(db: Session, import_file_id: int) -> List[FormalLetterRecord]:
    return (
        db.query(FormalLetterRecord)
        .filter(
            FormalLetterRecord.import_file_id == import_file_id,
            FormalLetterRecord.is_active == True,
        )
        .order_by(desc(FormalLetterRecord.created_at))
        .all()
    )


def get_letter_by_id(db: Session, letter_id: int) -> Optional[FormalLetterRecord]:
    return (
        db.query(FormalLetterRecord)
        .filter(
            FormalLetterRecord.letter_id == letter_id,
            FormalLetterRecord.is_active == True,
        )
        .first()
    )
