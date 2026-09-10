"""
SQLAlchemy Models for Smart Shipment Experience Guide (دليل خبرة المنتج والشحنة الذكي)
Module: KB-GUIDE-012
Institutional Memory for Logistics & Customs Knowledge
"""
from datetime import datetime, timezone
from sqlalchemy import (
    Column,
    Integer,
    String,
    Text,
    Boolean,
    DateTime,
    ForeignKey,
    Index,
)
from sqlalchemy.orm import relationship

from database.database import Base


class GuideEntry(Base):
    """
    Main Guide Entry / Institutional Memory Record
    """
    __tablename__ = "guide_entries"

    entry_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    entry_type = Column(String(30), nullable=False, default="alert")  # alert, required_document, task, info
    severity = Column(String(20), nullable=False, default="info")     # info, warning, critical
    created_by = Column(String(100), default="System", nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)

    # Relationships
    scopes = relationship("GuideEntryScope", back_populates="guide_entry", cascade="all, delete-orphan", lazy="joined")


class GuideEntryScope(Base):
    """
    Scope condition for Guide Entry matching (Multi-Scope AND logic)
    """
    __tablename__ = "guide_entry_scopes"

    scope_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    guide_entry_id = Column(Integer, ForeignKey("guide_entries.entry_id", ondelete="CASCADE"), nullable=False, index=True)
    scope_type = Column(String(50), nullable=False)  # hs_code, product_category, destination_port, supplier, shipping_line
    scope_value = Column(String(150), nullable=False)

    # Relationships
    guide_entry = relationship("GuideEntry", back_populates="scopes")


Index("idx_guide_entry_scopes_type_val", GuideEntryScope.scope_type, GuideEntryScope.scope_value)
