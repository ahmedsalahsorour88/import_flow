"""
SQLAlchemy Models for Import Files Master & Tracking (ملفات الشحنات الاستيرادية)
"""

from datetime import datetime, date, timezone
from typing import List, Optional
from sqlalchemy import (
    Column,
    Integer,
    String,
    Float,
    Boolean,
    DateTime,
    Date,
    ForeignKey,
    JSON,
    Text,
)
from sqlalchemy.orm import relationship

from database.database import Base


class ImportFile(Base):
    __tablename__ = "import_files"

    import_file_id = Column(Integer, primary_key=True, index=True)
    import_file_code = Column(String(50), unique=True, index=True, nullable=False)
    custom_file_number = Column(String(50), unique=True, index=True, nullable=True) # e.g. 6701068100

    # Foreign Key References
    company_id = Column(Integer, ForeignKey("import_companies.company_id"), nullable=True)
    company_name = Column(String(255), nullable=False)
    
    supplier_id = Column(Integer, ForeignKey("suppliers.supplier_id"), nullable=True)
    supplier_name = Column(String(255), nullable=False)

    broker_id = Column(Integer, ForeignKey("external_service_providers.provider_id"), nullable=True)
    broker_name = Column(String(255), nullable=True)

    po_number = Column(String(100), nullable=True) # e.g. PO-1001
    po_ids = Column(JSON, nullable=True) # List of linked PO IDs
    
    pi_number = Column(String(100), nullable=True) # Main PI number e.g. PI-889
    invoices_data = Column(JSON, nullable=True) # List of Proforma/Commercial Invoices: [{"invoice_no": "PI-889", "date": "2026-08-01", "amount": 24500.0, "currency": "USD"}]
    packing_lists_data = Column(JSON, nullable=True) # List of Packing Lists: [{"pl_no": "PL-889", "date": "2026-08-01", "total_packages": 50, "gross_weight_kg": 12000.0, "cbm": 35.5}]

    project_ids = Column(JSON, nullable=True) # List of linked Project IDs: [1, 2] (Must belong to company_id)
    project_names = Column(String(500), nullable=True)

    shipment_mode = Column(String(50), nullable=False, default="Sea FCL") # Sea FCL, Sea LCL, Air, Land
    incoterm_code = Column(String(20), nullable=False, default="FOB") # FOB, CIF, CFR, etc.
    priority = Column(String(20), nullable=False, default="High") # Low, Medium, High, Critical
    shipment_category = Column(String(50), nullable=False, default="New Purchase") # New Purchase, Repair, Replacement, Sample
    
    required_eta = Column(Date, nullable=True) # 15-Aug-2026
    selected_scenario = Column(String(100), nullable=True) # e.g. MSC Option

    # Banking & Customs Document Links
    acid_number = Column(String(50), nullable=True) # e.g. 1987654321098765432
    acid_request_date = Column(Date, nullable=True)
    acid_issue_date = Column(Date, nullable=True)
    acid_expiry_date = Column(Date, nullable=True)
    acid_execution_days = Column(Integer, nullable=True)
    is_customs_released = Column(Boolean, default=False, nullable=False)
    customs_released_at = Column(DateTime, nullable=True)
    form4_no = Column(String(100), nullable=True)
    form4_request_date = Column(Date, nullable=True)
    form4_received_date = Column(Date, nullable=True)
    form4_execution_days = Column(Integer, nullable=True)
    swift_no = Column(String(100), nullable=True)
    form46_no = Column(String(100), nullable=True)

    estimated_cost = Column(Float, nullable=False, default=0.0) # 24500.0

    # Formulas & Stage Tracking
    current_module = Column(String(100), nullable=False, default="BP-001 Receive Purchase Order")
    current_stage = Column(String(100), nullable=False, default="Phase 1 - Planning & Feasibility")
    progress_percent = Column(Float, nullable=False, default=10.0) # 0 to 100
    next_action = Column(String(255), nullable=False, default="Review Proforma Invoice & Packing List")
    
    status = Column(String(50), nullable=False, default="Open") # Open, In Progress, On Hold, Closed, Archived
    owner = Column(String(100), nullable=False, default="Kamal") # Operational owner e.g. Kamal
    notes = Column(Text, nullable=True)

    closure_reason = Column(Text, nullable=True)
    closed_at_phase = Column(String(100), nullable=True)

    # Audit Trail
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    created_by = Column(String(100), default="System", nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)
    updated_by = Column(String(100), default="System", nullable=False)

    # Relationships
    company = relationship("ImportCompany", foreign_keys=[company_id])
    supplier = relationship("Supplier", foreign_keys=[supplier_id])
