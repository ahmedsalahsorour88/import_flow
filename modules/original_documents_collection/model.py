from datetime import datetime, timezone
from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    Float,
    DateTime,
    ForeignKey,
    JSON,
    Text,
)
from sqlalchemy.orm import relationship

from database.database import Base


class OriginalDocumentsCollectionSession(Base):
    """
    Physical Original Documents Collection & Multi-Courier Tracking Session (BP-026 / DOC-ORIG-001)
    Tracks the physical receipt, multi-courier tracking (AWB/dates), verification,
    and archival of original hard-copy shipping & customs clearance documents.
    """
    __tablename__ = "original_documents_collection_sessions"

    collection_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    collection_code = Column(String(50), unique=True, index=True, nullable=False)

    import_file_id = Column(Integer, ForeignKey("import_files.import_file_id"), unique=True, index=True, nullable=False)
    import_file_code = Column(String(50), nullable=False)

    acid_number = Column(String(50), nullable=True)
    importer_name = Column(String(200), nullable=True)
    supplier_name = Column(String(200), nullable=True)

    # Status: 'DRAFT', 'IN_TRANSIT', 'PARTIALLY_RECEIVED', 'FULLY_RECEIVED', 'FULLY_VERIFIED', 'DISCREPANCY_NOTED'
    status = Column(String(50), default="DRAFT", nullable=False)

    # Multi-Courier List: list of objects:
    # [{"courier_no": "DHL-12345", "courier_company": "DHL", "dispatch_date": "2026-08-21", "received": true, "received_date": "2026-08-25", "received_by": "Ahmed", "notes": ""}]
    couriers_list = Column(JSON, default=list, nullable=False)

    # Document Items Matrix: list of objects:
    # [{"category": "Commercial", "document_name": "Commercial Invoice", "is_required": "Yes", "responsible_party": "Supplier", "courier_no": "DHL-123", "received": true, "received_date": "2026-08-25", "verified": true, "verified_by": "Kamal", "verification_date": "2026-08-25", "status": "Verified", "remarks": ""}]
    documents_list = Column(JSON, default=list, nullable=False)

    total_documents_count = Column(Integer, default=0, nullable=False)
    received_documents_count = Column(Integer, default=0, nullable=False)
    verified_documents_count = Column(Integer, default=0, nullable=False)
    pending_documents_count = Column(Integer, default=0, nullable=False)
    completion_percentage = Column(Float, default=0.0, nullable=False)

    discrepancy_override_reason = Column(Text, nullable=True)
    notes = Column(Text, nullable=True)

    # Audit & Soft-Delete Fields
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    created_by = Column(String(100), default="ADMIN", nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)
    updated_by = Column(String(100), default="ADMIN", nullable=False)

    # Relationships
    import_file = relationship("ImportFile", backref="original_documents_collection")
