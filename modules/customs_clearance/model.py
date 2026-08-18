from datetime import datetime, timezone
from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    ForeignKey,
    Float,
    JSON,
    Text,
)
from sqlalchemy.orm import relationship
from database.database import Base

# Referenced models for SQLAlchemy registry
from modules.import_files.model import ImportFile

class CustomsClearanceRecord(Base):
    """
    Phase 7 Customs Clearance & Inspection Model (BP-029 to BP-032)
    Tracks field customs inspection, channel routing (Green/Red),
    duty payment request breakdown, payment receipt details, and final release permit.
    """
    __tablename__ = "customs_clearance_records"

    customs_clearance_id = Column(Integer, primary_key=True, index=True)
    clearance_code = Column(String(50), unique=True, index=True, nullable=False)

    import_file_id = Column(Integer, ForeignKey("import_files.import_file_id"), nullable=False)
    declaration_46_no = Column(String(100), nullable=True, index=True)
    customs_office_name = Column(String(200), default="Alexandria Port Customs", nullable=False)

    # BP-029 Field Inspection & Channel
    channel_type = Column(String(30), default="Red Channel") # Red Channel, Green Channel, Yellow Channel
    inspection_date = Column(DateTime, nullable=True)
    regulatory_bodies = Column(JSON, default=list, nullable=False) # ["GOEIC", "Food Safety Authority", "NTRA"]
    sample_test_status = Column(String(50), default="Samples Under Testing") # Pending, Samples Under Testing, Approved, Rejected
    inspection_notes = Column(Text, nullable=True)

    # BP-030 Duty Payment Breakdown
    import_duty_amount = Column(Float, default=0.0)
    vat_amount = Column(Float, default=0.0)
    schedule_tax_amount = Column(Float, default=0.0)
    wht_amount = Column(Float, default=0.0)
    lab_service_fees = Column(Float, default=0.0)
    total_duty_payable = Column(Float, default=0.0)

    # BP-031 Duty Payment Recording
    payment_status = Column(String(30), default="Unpaid") # Unpaid, Payment Requested, Paid & Verified
    bank_receipt_no = Column(String(100), nullable=True)
    paying_bank_name = Column(String(200), nullable=True)
    payment_date = Column(DateTime, nullable=True)
    payment_notes = Column(Text, nullable=True)

    # BP-032 Complete Customs Release
    release_permit_no = Column(String(100), nullable=True, index=True)
    release_date = Column(DateTime, nullable=True)
    demurrage_storage_fees = Column(Float, default=0.0)
    dispatch_authorized = Column(Boolean, default=False)
    dispatch_date = Column(DateTime, nullable=True)

    # Status & Audit
    status = Column(String(50), default="Inspection In Progress", index=True) # Inspection In Progress, Duty Requested, Duty Paid, Final Release Granted
    owner = Column(String(100), default="Kamal", nullable=False)
    notes = Column(Text, nullable=True)

    is_active = Column(Boolean, default=True, index=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    created_by = Column(String(100), default="System")
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    updated_by = Column(String(100), default="System")

    # Relationships
    import_file = relationship("ImportFile", backref="customs_clearance_records")
