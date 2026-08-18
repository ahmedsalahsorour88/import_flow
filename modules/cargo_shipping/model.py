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
from modules.freight_booking.model import ShipmentBooking

class CargoShippingRecord(Base):
    """
    Phase 5 Cargo Preparation & Shipping Model (BP-020 to BP-025)
    Tracks cargo readiness date (CRD), container loading & seal numbers,
    container follow-up 48h SLA tracking, dual approval of shipping documents,
    courier tracking, and CargoX electronic exchange.
    """
    __tablename__ = "cargo_shipping_records"

    cargo_shipping_id = Column(Integer, primary_key=True, index=True)
    cargo_shipping_code = Column(String(50), unique=True, index=True, nullable=False)

    import_file_id = Column(Integer, ForeignKey("import_files.import_file_id"), nullable=False)
    booking_id = Column(Integer, ForeignKey("shipment_bookings.booking_id"), nullable=True)
    shipment_type = Column(String(20), default="FCL", nullable=False) # FCL, LCL, Air

    # BP-020 Cargo Readiness
    crd_date = Column(DateTime, nullable=True)
    cargo_cutoff_date = Column(DateTime, nullable=True)
    is_crd_validated = Column(Boolean, default=True)

    # BP-021 Cargo Loading & VGM (JSON List with 5-Milestones Tracking & 48h SLA)
    # List of {container_no, seal_no, container_type, tare_weight_kg, net_weight_kg, gross_weight_kg, vgm_status, vgm_ref_no,
    #          container_assignment_date, arrival_at_supplier_at, loading_start_at, loading_end_at, port_gate_in_at,
    #          sla_deadline_at, is_sla_breached, tracking_status, tracking_history, individual_units}
    containers_loading_data = Column(JSON, default=list, nullable=False)

    # LCL CFS Consolidation Tracking (if LCL)
    lcl_tracking_data = Column(JSON, default=dict, nullable=True)

    # BP-022 Dual Approval
    level1_approval_status = Column(String(30), default="Pending") # Pending, Approved, Rejected
    level1_approved_by = Column(String(100), nullable=True)
    level1_approved_at = Column(DateTime, nullable=True)
    level1_notes = Column(Text, nullable=True)

    level2_approval_status = Column(String(30), default="Pending") # Pending, Approved, Rejected
    level2_approved_by = Column(String(100), nullable=True)
    level2_approved_at = Column(DateTime, nullable=True)
    level2_notes = Column(Text, nullable=True)

    dual_approval_status = Column(String(30), default="Pending") # Pending, In Progress, Dual Approved, Rejected

    # BP-023 Courier & Original Shipping Documents Tracking
    # {courier_provider, tracking_number, dispatch_date, receipt_status, received_at, received_by}
    courier_tracking_data = Column(JSON, default=dict, nullable=False)

    # BP-024 Electronic Document Exchange (CargoX / Nafeza Integration)
    # {platform_provider, envelope_id, envelope_status, blockchain_tx_hash, verification_checklist: [{rule, passed, details}]}
    cargox_exchange_data = Column(JSON, default=dict, nullable=False)

    # BP-025 Live Tracking Link
    live_tracking_url = Column(String(500), nullable=True)

    # Operational status
    status = Column(String(50), default="Cargo Ready", index=True) # Cargo Ready, Loaded & Sealed, Dual Approved, Docs Dispatched, CargoX Transfer Completed, Completed
    owner = Column(String(100), default="Kamal", nullable=False)
    notes = Column(Text, nullable=True)

    # Soft Delete & Audit Trail
    is_active = Column(Boolean, default=True, index=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    created_by = Column(String(100), default="System")
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    updated_by = Column(String(100), default="System")

    # Relationships
    import_file = relationship("ImportFile", backref="cargo_shipping_records")
    booking = relationship("ShipmentBooking", backref="cargo_shipping_records")
