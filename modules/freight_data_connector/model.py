from datetime import datetime, timezone, date
from sqlalchemy import Column, Integer, String, Numeric, DateTime, Date, Boolean, JSON, Text
from database.database import Base


class FreightIndexSnapshot(Base):
    """
    Snapshot of global container shipping freight indices (e.g. SFX via shaq-freight).
    Updated on a weekly schedule.
    """
    __tablename__ = "freight_index_snapshots"

    id = Column(Integer, primary_key=True, autoincrement=True)
    route_name = Column(String(150), nullable=False, index=True) # e.g. "China to Mediterranean"
    origin_region = Column(String(100), nullable=True)           # e.g. "East Asia"
    destination_region = Column(String(100), nullable=True)      # e.g. "Mediterranean / Egypt"
    fcl_20gp_usd = Column(Numeric(10, 2), nullable=True)
    fcl_40hq_usd = Column(Numeric(10, 2), nullable=False)
    transit_time_days = Column(Integer, nullable=True)           # e.g. 28
    source = Column(String(50), default="shaq-freight", nullable=False)
    snapshot_date = Column(DateTime, nullable=False, index=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)


class DemurrageRule(Base):
    """
    Carrier-specific container detention rules & rate slabs (USD).
    Synchronized monthly via ShippingRates.org API under quota protection.
    """
    __tablename__ = "demurrage_rules"

    rule_id = Column(Integer, primary_key=True, autoincrement=True)
    shipping_line = Column(String(50), nullable=False, index=True) # e.g. "maersk", "msc", "cma_cgm"
    country_code = Column(String(5), default="EG", nullable=False)
    container_type = Column(String(20), nullable=False)            # e.g. "20GP", "40HC", "40RF"
    default_free_days = Column(Integer, default=14, nullable=False)
    rate_slabs = Column(JSON, nullable=False)                      # list of {from_day, to_day, rate_usd_per_day}
    source = Column(String(50), default="shippingrates.org", nullable=False)
    last_synced_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)


class PortDemurrageTariff(Base):
    """
    Official Egyptian Port Authority storage tariff schedules (EGP).
    Versioned by ministerial decrees (e.g. Decision-554-2024).
    Calculated using the decree active at discharge_date.
    """
    __tablename__ = "port_demurrage_tariff"

    id = Column(Integer, primary_key=True, autoincrement=True)
    port_authority = Column(String(50), nullable=False, index=True) # e.g. "Alexandria", "Damietta", "Sokhna"
    container_type = Column(String(20), nullable=False)             # e.g. "20ft", "40ft", "40HC", "Reefer"
    free_days = Column(Integer, default=4, nullable=False)          # usually 3 to 5 days
    rate_slabs = Column(JSON, nullable=False)                       # list of {from_day, to_day, rate_egp_per_day}
    tariff_version = Column(String(50), nullable=False, index=True) # e.g. "Decision-554-2024"
    effective_from = Column(Date, nullable=False)
    effective_to = Column(Date, nullable=True)                      # None if currently active
    source_document = Column(String(255), nullable=True)            # PDF file name or official gazette ref
    entered_by = Column(String(100), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)


class ExternalApiQuotaLog(Base):
    """
    Tracks usage of monthly external API calls (e.g. ShippingRates.org 25 calls/mo free quota).
    """
    __tablename__ = "external_api_quota_logs"

    log_id = Column(Integer, primary_key=True, autoincrement=True)
    provider = Column(String(50), nullable=False, index=True)     # "shippingrates.org"
    call_month = Column(String(7), nullable=False, index=True)    # "YYYY-MM"
    call_timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    endpoint = Column(String(100), nullable=False)
    request_details = Column(Text, nullable=True)
    is_success = Column(Boolean, default=True, nullable=False)
