"""
SQLAlchemy Model for AI Formal Letter Drafting (AI-DRAFT-014)
"""

from datetime import datetime, timezone
from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    ForeignKey,
    Text,
)
from database.database import Base


class FormalLetterRecord(Base):
    """
    Stores generated formal corporate letters for export, printing, and audit history.
    """
    __tablename__ = "formal_letters_history"

    letter_id = Column(Integer, primary_key=True, autoincrement=True, index=True)
    letter_code = Column(String(50), unique=True, index=True, nullable=False)

    import_file_id = Column(Integer, ForeignKey("import_files.import_file_id"), nullable=False, index=True)
    template_type = Column(String(100), nullable=False, index=True)  # demurrage_extension, bank_delegation, bank_form4, customs_broker_mandate
    letter_title_ar = Column(String(255), nullable=False)
    recipient_name = Column(String(255), nullable=True)

    letter_body = Column(Text, nullable=False)
    notes = Column(Text, nullable=True)

    # Audit Trail
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    created_by = Column(String(100), default="System", nullable=False)
    updated_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    updated_by = Column(String(100), default="System", nullable=False)
