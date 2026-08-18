"""
Smart Document Upload — SQLAlchemy Model
upload_sessions table — tracks every file upload & extraction result.
"""

import json
from datetime import datetime

from sqlalchemy import Column, Integer, String, Float, DateTime, Text, func
from database.database import Base


class UploadSession(Base):
    """
    Tracks every smart document upload & extraction session.
    Each row represents one file that was uploaded and parsed.
    """
    __tablename__ = "upload_sessions"

    id = Column(Integer, primary_key=True, autoincrement=True)

    # Business reference
    session_ref = Column(String(50), unique=True, nullable=False)   # UPLOAD-2026-00001

    # Context
    module_name = Column(String(100), nullable=False)               # 'purchase_orders' | 'cargo_shipping' | ...
    filename = Column(String(255), nullable=False)
    file_type = Column(String(20))                                  # 'pdf' | 'excel' | 'word' | 'text'
    file_size_bytes = Column(Integer)

    # Extraction results
    extraction_status = Column(String(30), default="PENDING")       # SUCCESS | PARTIAL | FAILED | PENDING
    confidence_score = Column(Float, default=0.0)                   # 0.0 – 1.0
    extracted_fields_json = Column(Text)                            # JSON blob of extracted data
    missing_fields_json = Column(Text)                              # JSON array of missing field names
    extraction_notes = Column(Text)                                 # Human-readable summary

    # Linkage — which record was created from this upload
    linked_record_id = Column(Integer)
    linked_module = Column(String(100))

    # Audit
    created_at = Column(DateTime, default=func.now())
    created_by = Column(Integer)
    is_active = Column(Integer, default=1)

    # ─── Helpers ──────────────────────────────────────────────────────────────

    def set_extracted_fields(self, fields: dict) -> None:
        self.extracted_fields_json = json.dumps(fields, ensure_ascii=False, default=str)

    def get_extracted_fields(self) -> dict:
        if not self.extracted_fields_json:
            return {}
        try:
            return json.loads(self.extracted_fields_json)
        except Exception:
            return {}

    def set_missing_fields(self, fields: list) -> None:
        self.missing_fields_json = json.dumps(fields, ensure_ascii=False)

    def get_missing_fields(self) -> list:
        if not self.missing_fields_json:
            return []
        try:
            return json.loads(self.missing_fields_json)
        except Exception:
            return []
