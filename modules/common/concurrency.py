"""
ImportFlow ERP — Optimistic Concurrency Control & Conflict Logging Subsystem
=============================================================================
Provides model-level optimistic concurrency protection, standardized conflict
exceptions (mapped to HTTP 409), and database audit logging for collision events.
"""

from datetime import datetime, timezone
from typing import Optional, Dict, Any
from sqlalchemy import Column, Integer, String, DateTime, Text
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from database.database import Base


class ConcurrencyConflictException(HTTPException):
    """
    Exception raised when an optimistic concurrency version mismatch is detected.
    Maps directly to HTTP 409 Conflict with structured metadata.
    """
    def __init__(
        self,
        entity: str,
        record_id: int,
        current_version: int,
        submitted_version: Optional[int],
        updated_at: Optional[datetime] = None,
        updated_by: Optional[str] = None,
        custom_message: Optional[str] = None,
    ):
        updated_at_iso = updated_at.isoformat() if updated_at else None
        modifier = updated_by or "مستخدم آخر"
        default_msg = (
            f"تعذر حفظ التعديلات لأن السجل تم تعديله وحفظه مسبقاً بواسطة ({modifier}) "
            f"في {updated_at_iso or 'وقت سابق'}. يرجى إعادة تحميل أحدث نسخة من السجل لتجنب مسح تعديلات الطرف الآخر."
        )
        self.entity = entity
        self.record_id = record_id
        self.current_version = current_version
        self.submitted_version = submitted_version
        self.updated_at = updated_at_iso
        self.updated_by = updated_by

        detail_payload = {
            "error": "CONCURRENCY_CONFLICT",
            "message": custom_message or default_msg,
            "entity": entity,
            "record_id": record_id,
            "current_version": current_version,
            "submitted_version": submitted_version,
            "updated_at": updated_at_iso,
            "updated_by": updated_by,
        }
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail=detail_payload,
        )


class ConcurrencyConflictLog(Base):
    """
    Audit table capturing all concurrent edit collisions across the ERP system.
    Used for telemetry and identifying contentious records.
    """
    __tablename__ = "concurrency_conflict_logs"

    conflict_id = Column(Integer, primary_key=True, autoincrement=True, index=True)
    entity_name = Column(String(100), nullable=False, index=True)
    record_id = Column(Integer, nullable=False, index=True)
    attempted_by = Column(String(100), nullable=True)
    conflicting_user = Column(String(100), nullable=True)
    submitted_version = Column(Integer, nullable=True)
    current_version = Column(Integer, nullable=False)
    details = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "conflict_id": self.conflict_id,
            "entity_name": self.entity_name,
            "record_id": self.record_id,
            "attempted_by": self.attempted_by,
            "conflicting_user": self.conflicting_user,
            "submitted_version": self.submitted_version,
            "current_version": self.current_version,
            "details": self.details,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


def log_concurrency_conflict(
    db: Session,
    entity_name: str,
    record_id: int,
    current_version: int,
    submitted_version: Optional[int],
    attempted_by: Optional[str] = None,
    conflicting_user: Optional[str] = None,
    details: Optional[str] = None,
) -> ConcurrencyConflictLog:
    """Safely logs a collision event into the database audit trail."""
    try:
        conflict_entry = ConcurrencyConflictLog(
            entity_name=entity_name,
            record_id=record_id,
            current_version=current_version,
            submitted_version=submitted_version,
            attempted_by=attempted_by,
            conflicting_user=conflicting_user,
            details=details,
        )
        db.add(conflict_entry)
        db.commit()
        db.refresh(conflict_entry)
        return conflict_entry
    except Exception as e:
        db.rollback()
        return None
