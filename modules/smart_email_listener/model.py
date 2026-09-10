"""
SQLAlchemy Model for Inbound Email Logs (INT-EMAIL-010)
"""

from datetime import datetime, timezone, date
from sqlalchemy import Column, Integer, String, Text, Date, DateTime, Boolean, ForeignKey
from database.database import Base


class InboundEmailLog(Base):
    __tablename__ = "inbound_email_logs"

    email_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    sender_email = Column(String(150), nullable=False, default="notifications@carrier.com")
    subject = Column(String(300), nullable=False)
    body_text = Column(Text, nullable=False)
    received_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    email_type = Column(String(50), default="Arrival Notice", nullable=False)

    # Extracted data
    extracted_bl_number = Column(String(100), nullable=True, index=True)
    extracted_eta = Column(Date, nullable=True)
    extracted_vessel = Column(String(150), nullable=True)
    extracted_voyage = Column(String(50), nullable=True)
    extracted_containers = Column(String(300), nullable=True)

    # Association & Outcome
    import_file_id = Column(Integer, ForeignKey("import_files.import_file_id"), nullable=True, index=True)
    processing_status = Column(String(50), default="Processed", nullable=False)  # Matched, Unmatched, Task_Created
    task_id = Column(Integer, nullable=True)
    notes = Column(Text, nullable=True)

    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    created_by = Column(String(100), default="SmartEmailListener", nullable=False)
