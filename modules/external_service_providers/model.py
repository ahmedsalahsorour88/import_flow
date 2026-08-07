from datetime import datetime, timezone
from sqlalchemy import Boolean, Column, DateTime, Float, Integer, String
from database.database import Base


class ExternalServiceProvider(Base):
    __tablename__ = "external_service_providers"

    # ==================================================
    # Primary Key
    # ==================================================
    provider_id = Column(Integer, primary_key=True, autoincrement=True, index=True)

    # ==================================================
    # System Code
    # ==================================================
    partner_code = Column(String(20), unique=True, index=True, nullable=False)

    # ==================================================
    # Partner Category & Name
    # ==================================================
    partner_name = Column(String(200), nullable=False)
    partner_type = Column(String(100), nullable=False)  # Bank, Shipping Line, Customs Broker, Freight Forwarder, Inland Transport, Inspection Agency

    # ==================================================
    # Registration & Tax Information
    # ==================================================
    tax_id = Column(String(50))
    commercial_register = Column(String(50))

    # ==================================================
    # Category-Specific Details
    # ==================================================
    # For Customs Brokers:
    clearance_license_number = Column(String(50))

    # For Shipping Lines & Carriers:
    scac_code = Column(String(20))
    tracking_url = Column(String(300))

    # For Commercial Banks:
    swift_code = Column(String(20))
    bank_code = Column(String(20))
    branch_name = Column(String(100))

    # ==================================================
    # Contact Information
    # ==================================================
    contact_person = Column(String(150))
    phone = Column(String(50))
    mobile = Column(String(50))
    email = Column(String(150))
    address = Column(String(300))
    country = Column(String(100), default="Egypt")

    # ==================================================
    # Financial & Performance Rating
    # ==================================================
    payment_type = Column(String(50), default="Credit")  # Cash, Credit, Deferred
    credit_limit = Column(Float, default=0.0)
    rating = Column(Float, default=5.0)  # 1 to 5 stars

    # ==================================================
    # Notes
    # ==================================================
    notes = Column(String(1000))

    # ==================================================
    # Status & Audit
    # ==================================================
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)
    created_by = Column(String(100))
    updated_by = Column(String(100))