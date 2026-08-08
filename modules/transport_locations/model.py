from datetime import datetime, timezone

from sqlalchemy import Boolean, Column, DateTime, Integer, String

from database.database import Base


# ==================================================
# MD-009: Transport Locations (Sea Ports, Airports, Dry Ports, Land Borders)
# ==================================================

class TransportLocation(Base):

    __tablename__ = "transport_locations"

    # Primary Key
    location_id = Column(Integer, primary_key=True, autoincrement=True, index=True)

    # UN/LOCODE (e.g. EGALY, EGCAI, CNSHA, NLRTM)
    un_locode = Column(String(10), nullable=False, unique=True, index=True)

    # Location Details
    location_name = Column(String(200), nullable=False)
    location_type = Column(String(50), nullable=False, index=True)  # Sea Port, Airport, Dry Port, Land Border, ICD, Rail Terminal
    country = Column(String(100), nullable=False, index=True)
    city = Column(String(100), nullable=False)
    notes = Column(String(500), nullable=True)

    # Soft Delete
    is_active = Column(Boolean, default=True, nullable=False)

    # Audit Trail
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
