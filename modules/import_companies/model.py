from datetime import datetime

from sqlalchemy import Boolean
from sqlalchemy import Column
from sqlalchemy import Date
from sqlalchemy import DateTime
from sqlalchemy import Integer
from sqlalchemy import String

from database.database import Base


class ImportCompany(Base):

    __tablename__ = "import_companies"

    # ==================================================
    # Primary Key
    # ==================================================
    company_id = Column(
        Integer,
        primary_key=True,
        autoincrement=True,
        index=True
    )

    # ==================================================
    # Company Information
    # ==================================================
    importer_name = Column(
        String(200),
        nullable=False
    )

    address = Column(
        String(300),
        nullable=False
    )

    country = Column(
        String(100),
        nullable=False
    )

    foreign_exporter_registration_type = Column(
        String(100)
    )

    # ==================================================
    # Importer ID
    # ==================================================
    importer_id = Column(
        String(100),
        nullable=False,
        unique=True
    )

    importer_id_expiry = Column(
        Date,
        nullable=False
    )

    # ==================================================
    # VAT Registration
    # ==================================================
    vat_id = Column(
        String(100),
        nullable=False,
        unique=True
    )

    vat_id_expiry = Column(
        Date,
        nullable=False
    )

    # ==================================================
    # Commercial Registration
    # ==================================================
    registration_number = Column(
        String(100),
        nullable=False,
        unique=True
    )

    registration_expiry = Column(
        Date,
        nullable=False
    )

    # ==================================================
    # Contact Information
    # ==================================================
    phone = Column(
        String(50)
    )

    email = Column(
        String(150)
    )

    # ==================================================
    # System Fields
    # ==================================================
    is_active = Column(
        Boolean,
        default=True,
        nullable=False
    )

    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False
    )

    updated_at = Column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False
    )

    created_by = Column(
        String(100)
    )

    updated_by = Column(
        String(100)
    )

    notes = Column(
        String(500)
    )