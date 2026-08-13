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

class WarehouseReceivingRecord(Base):
    """
    Phase 8 Warehouse Receiving & Quality Control Model (BP-033 to BP-035)
    Tracks truck arrival, seal integrity verification (Seal Intact),
    GRN quantity audit (Invoiced vs Accepted vs Shortage/Damage), and Quarantine Zone tagging.
    """
    __tablename__ = "warehouse_receiving_records"

    receiving_id = Column(Integer, primary_key=True, index=True)
    grn_code = Column(String(50), unique=True, index=True, nullable=False) # e.g. GRN-2026-0001

    import_file_id = Column(Integer, ForeignKey("import_files.import_file_id"), nullable=False)
    warehouse_name = Column(String(200), default="Main Warehouse - Cairo", nullable=False)

    # BP-033 Truck Arrival & Seal Intact
    arrival_datetime = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    truck_plate_number = Column(String(50), nullable=True)
    driver_name = Column(String(100), nullable=True)
    driver_phone = Column(String(50), nullable=True)
    seal_number = Column(String(100), nullable=True)
    seal_intact = Column(Boolean, default=True, nullable=False)

    # BP-034 Quantity Verification & GRN Line Items
    # JSON schema: [{"item_code": "ITM-001", "item_name": "Valves", "invoiced_qty": 100, "accepted_qty": 95, "shortage_qty": 3, "damaged_qty": 2, "quarantine_flag": true}]
    grn_items = Column(JSON, default=list, nullable=False)
    total_invoiced_qty = Column(Integer, default=0)
    total_accepted_qty = Column(Integer, default=0)
    total_shortage_qty = Column(Integer, default=0)
    total_damaged_qty = Column(Integer, default=0)

    # BP-035 Discrepancies & Damage Claim Report
    discrepancy_type = Column(String(50), default="None") # None, Shortage, Damage, Excess, Wrong Item
    discrepancy_notes = Column(Text, nullable=True)
    quarantine_zone_assigned = Column(Boolean, default=False)
    insurance_claim_filed = Column(Boolean, default=False)
    insurance_claim_ref = Column(String(100), nullable=True)

    # Status & Audit
    status = Column(String(50), default="Goods Received", index=True) # Goods Received, GRN Audited, Discrepancy Reported, Closed
    inspector_name = Column(String(100), default="Kamal", nullable=False)
    notes = Column(Text, nullable=True)

    is_active = Column(Boolean, default=True, index=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    created_by = Column(String(100), default="System")
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    updated_by = Column(String(100), default="System")

    # Relationships
    import_file = relationship("ImportFile", backref="warehouse_receiving_records")
