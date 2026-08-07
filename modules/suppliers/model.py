from datetime import datetime

from sqlalchemy import Column
from sqlalchemy import Integer
from sqlalchemy import String
from sqlalchemy import Text
from sqlalchemy import Boolean
from sqlalchemy import DateTime

from database.database import Base


class Supplier(Base):

    __tablename__ = "suppliers"


    # ==================================================
    # Primary Key
    # ==================================================

    supplier_id = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )


    supplier_code = Column(
        String(50),
        nullable=False,
        unique=True,
        index=True
    )


    # ==================================================
    # Company Information
    # ==================================================

    company_name = Column(
        String(200),
        nullable=False,
        index=True
    )


    supplier_type = Column(
        String(50),
        nullable=False,
        index=True
    )


    registration_type = Column(
        String(50),
        nullable=False
    )


    foreign_exporter_id = Column(
        String(100),
        nullable=False,
        unique=True
    )


    # ==================================================
    # Country Information
    # ==================================================

    foreign_exporter_country = Column(
        String(100),
        nullable=False
    )


    foreign_exporter_country_code = Column(
        String(10),
        nullable=False
    )


    # ==================================================
    # Contact Information
    # ==================================================

    address = Column(
        String(300),
        nullable=False
    )


    phone = Column(
        String(50),
        nullable=True
    )


    email = Column(
        String(150),
        nullable=True,
        index=True
    )


    website = Column(
        String(200),
        nullable=True
    )


    # ==================================================
    # Business Information
    # ==================================================

    brands = Column(
        Text,
        nullable=True
    )


    notes = Column(
        Text,
        nullable=True
    )


    # ==================================================
    # ERP Status
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
        String(100),
        nullable=True
    )


    updated_by = Column(
        String(100),
        nullable=True
    )


    # ==================================================
    # Representation
    # ==================================================

    def __repr__(self):

        return (
            f"<Supplier "
            f"id={self.supplier_id} "
            f"name={self.company_name}>"
        )