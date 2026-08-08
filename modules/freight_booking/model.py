from datetime import datetime, timezone
from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String, Text, JSON
from sqlalchemy.orm import relationship

from database.database import Base


class ShipmentBooking(Base):
    __tablename__ = "shipment_bookings"

    # Primary Key
    booking_id = Column(Integer, primary_key=True, autoincrement=True, index=True)

    # Business Reference Codes
    booking_code = Column(String(50), nullable=False, unique=True, index=True)
    booking_confirmation_no = Column(String(100), nullable=True, index=True)

    # Relationships & Linked Entities
    import_file_id = Column(Integer, ForeignKey("import_files.import_file_id"), nullable=True, index=True)
    rfq_request_id = Column(Integer, ForeignKey("freight_rfq_requests.rfq_id"), nullable=True, index=True)
    freight_forwarder_id = Column(Integer, ForeignKey("external_service_providers.provider_id"), nullable=True)
    freight_forwarder_name = Column(String(150), nullable=True)
    shipping_line_id = Column(Integer, ForeignKey("external_service_providers.provider_id"), nullable=True)
    shipping_line_name = Column(String(150), nullable=True)

    # Shipment Specifications
    shipment_type = Column(String(50), nullable=False, default="Ocean FCL")  # Ocean FCL, Ocean LCL, Air
    pol_location_id = Column(Integer, ForeignKey("transport_locations.location_id"), nullable=True)
    pol_name = Column(String(150), nullable=True)
    pod_location_id = Column(Integer, ForeignKey("transport_locations.location_id"), nullable=True)
    pod_name = Column(String(150), nullable=True)

    # Schedule & Dates
    booking_request_date = Column(DateTime, nullable=True, default=lambda: datetime.now(timezone.utc))
    booking_confirmation_date = Column(DateTime, nullable=True)
    etd = Column(DateTime, nullable=True)  # Estimated Time of Departure
    eta = Column(DateTime, nullable=True)  # Estimated Time of Arrival
    transit_time_days = Column(Integer, nullable=True, default=0)
    free_demurrage_days = Column(Integer, nullable=True, default=14)
    cargo_cutoff_date = Column(DateTime, nullable=True)
    si_cutoff_date = Column(DateTime, nullable=True)

    # Vessel & Equipment
    vessel_name = Column(String(150), nullable=True)
    voyage_number = Column(String(50), nullable=True)
    container_release_order_no = Column(String(100), nullable=True)
    freight_terms = Column(String(50), nullable=False, default="Collect")  # Prepaid, Collect

    # Complex JSON Structures
    containers_data = Column(JSON, nullable=True, default=list)
    cost_charges_data = Column(JSON, nullable=True, default=list)

    # Financials & Status
    total_freight_cost_usd = Column(Float, nullable=False, default=0.0)
    status = Column(String(50), nullable=False, default="Draft")  # Draft, Booking Requested, Confirmed, Amended, Cancelled, Sailed
    owner = Column(String(100), nullable=False, default="Kamal")
    notes = Column(Text, nullable=True)

    # Soft Delete
    is_active = Column(Boolean, default=True, nullable=False)

    # Audit Trail
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    # Relationships
    import_file = relationship("ImportFile", backref="bookings")
