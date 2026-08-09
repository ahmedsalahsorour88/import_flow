from datetime import datetime, timezone

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import relationship

from database.database import Base


# ==================================================
# MD-006: Incoterm Master
# ==================================================

class Incoterm(Base):

    __tablename__ = "incoterms"

    # Primary Key
    incoterm_id = Column(Integer, primary_key=True, autoincrement=True, index=True)

    # Business Reference
    incoterm_code = Column(String(10), nullable=False, unique=True, index=True)
    incoterm_name = Column(String(100), nullable=False)
    version = Column(String(20), nullable=False, default="Incoterms 2020")
    description = Column(String(500), nullable=True)

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
    created_by = Column(String(100), nullable=True)
    updated_by = Column(String(100), nullable=True)

    # Relationships
    responsibilities = relationship("IncotermResponsibility", back_populates="incoterm", cascade="all, delete-orphan")


# ==================================================
# MD-006A: Cost Item Master
# ==================================================

class CostItem(Base):

    __tablename__ = "cost_items"

    # Primary Key
    cost_item_id = Column(Integer, primary_key=True, autoincrement=True, index=True)

    # Business Reference
    cost_item_code = Column(String(20), nullable=False, unique=True, index=True)
    cost_item_name = Column(String(150), nullable=False)

    # Category: Freight / Customs / Port / Bank / Other
    cost_category = Column(String(50), nullable=False)
    description = Column(String(500), nullable=True)

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
    created_by = Column(String(100), nullable=True)
    updated_by = Column(String(100), nullable=True)

    # Relationships
    responsibilities = relationship("IncotermResponsibility", back_populates="cost_item", cascade="all, delete-orphan")


# ==================================================
# MD-006B: Incoterm Responsibility Matrix
# ==================================================

class IncotermResponsibility(Base):

    __tablename__ = "incoterm_responsibilities"

    __table_args__ = (
        UniqueConstraint("incoterm_id", "cost_item_id", name="uq_incoterm_cost_item"),
    )

    # Primary Key
    responsibility_id = Column(Integer, primary_key=True, autoincrement=True, index=True)

    # Foreign Keys
    incoterm_id = Column(Integer, ForeignKey("incoterms.incoterm_id"), nullable=False, index=True)
    cost_item_id = Column(Integer, ForeignKey("cost_items.cost_item_id"), nullable=False, index=True)

    # Responsible Party: Importer / Exporter / Shared
    responsible_party = Column(String(20), nullable=False)

    # Is this cost included/covered under the Incoterm?
    included_in_incoterm = Column(Boolean, default=False, nullable=False)

    notes = Column(String(300), nullable=True)

    # Audit Trail
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    created_by = Column(String(100), nullable=True)
    updated_by = Column(String(100), nullable=True)

    # Relationships
    incoterm = relationship("Incoterm", back_populates="responsibilities")
    cost_item = relationship("CostItem", back_populates="responsibilities")

    @property
    def incoterm_code(self) -> Optional[str]:
        return self.incoterm.incoterm_code if self.incoterm else None

    @property
    def cost_item_name(self) -> Optional[str]:
        return self.cost_item.cost_item_name if self.cost_item else None

    @property
    def cost_category(self) -> Optional[str]:
        return self.cost_item.cost_category if self.cost_item else None
