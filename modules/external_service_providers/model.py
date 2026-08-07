from datetime import datetime, timezone

from sqlalchemy import Boolean
from sqlalchemy import Column
from sqlalchemy import DateTime
from sqlalchemy import Float
from sqlalchemy import Integer
from sqlalchemy import String

from database.database import Base



class ExternalServiceProvider(Base):

    __tablename__ = "external_service_providers"

    # ==================================================
    # Primary Key
    # ==================================================

    provider_id = Column(
        Integer,
        primary_key=True,
        autoincrement=True,
        index=True
    )

    # ==================================================
    # System Code
    # ==================================================

    partner_code = Column(
        String(20),
        unique=True,
        index=True
    )

    # ==================================================
    # Company Information
    # ==================================================

    partner_name = Column(
        String(200),
        nullable=False
    )

    partner_type = Column(
        String(100),
        nullable=False
    )

    # ==================================================
    # Contact Information
    # ==================================================

    contact_person = Column(
        String(150)
    )

    phone = Column(
        String(50)
    )

    mobile = Column(
        String(50)
    )

    email = Column(
        String(150)
    )

    address = Column(
        String(300)
    )

    country = Column(
        String(100)
    )

    # ==================================================
    # Financial Information
    # ==================================================

    payment_type = Column(
        String(50)
    )

    credit_limit = Column(
        Float,
        default=0
    )

    # ==================================================
    # Notes
    # ==================================================

    notes = Column(
        String(1000)
    )

    # ==================================================
    # Status
    # ==================================================

    is_active = Column(
        Boolean,
        default=True,
        nullable=False
    )

    # ==================================================
    # Audit Fields
    # ==================================================

    created_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    updated_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False
    )


    created_by = Column(
        String(100)
    )

    updated_by = Column(
        String(100)
    )