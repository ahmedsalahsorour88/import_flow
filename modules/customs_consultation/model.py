"""
Customs Consultation Engine Models (BP-009)
"""

from datetime import datetime, date
from sqlalchemy import String, Float, Integer, DateTime, Date, ForeignKey, Boolean, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from database.database import Base


class CustomsConsultationSession(Base):
    """
    Master study session for Customs Consultation with Broker (BP-009).
    Tracks document checklist, regulatory approvals, readiness %, and blocking issues.
    """

    __tablename__ = "customs_consultation_sessions"

    consultation_id: Mapped[int] = mapped_column(
        Integer, primary_key=True, index=True, autoincrement=True
    )
    consultation_code: Mapped[str] = mapped_column(
        String(50), unique=True, index=True, nullable=False
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    
    # Linked Broker (Customs Broker from external_service_providers)
    broker_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("external_service_providers.provider_id"), nullable=False, index=True
    )
    broker_name: Mapped[str] = mapped_column(String(200), nullable=False)
    broker_contact_person: Mapped[str] = mapped_column(String(100), nullable=True)

    # Optional Link to Purchase Order or Project
    po_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("purchase_orders.po_id"), nullable=True, index=True
    )
    project_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("projects.project_id"), nullable=True, index=True
    )

    # Overall Status: 'Pending Review', 'In Progress', 'Action Required', 'Clearance Ready', 'Blocked'
    overall_status: Mapped[str] = mapped_column(
        String(50), default="Pending Review", nullable=False, index=True
    )
    has_blocking_issues: Mapped[bool] = mapped_column(Boolean, default=False)
    readiness_percentage: Mapped[float] = mapped_column(Float, default=0.0)

    # Financial & Notes
    estimated_duties_egp: Mapped[float] = mapped_column(Float, default=0.0)
    notes: Mapped[str] = mapped_column(Text, nullable=True)

    # Audit & Soft Delete
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    # Relationship to Items
    checklist_items: Mapped[list["CustomsChecklistItem"]] = relationship(
        "CustomsChecklistItem",
        back_populates="session",
        cascade="all, delete-orphan",
        lazy="selectin",
    )


class CustomsChecklistItem(Base):
    """
    Individual Document or Regulatory Approval Item in Customs Checklist (BP-009).
    """

    __tablename__ = "customs_checklist_items"

    item_id: Mapped[int] = mapped_column(
        Integer, primary_key=True, index=True, autoincrement=True
    )
    consultation_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("customs_consultation_sessions.consultation_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    
    # Document Type (Proforma Invoice, Commercial Invoice, Packing List, HS Code Confirmation, Certificate of Origin, Inspection Certificate, ACID Info, Booking Confirmation, Insurance Certificate, Regulatory Approval)
    document_type: Mapped[str] = mapped_column(String(100), nullable=False)
    hs_code: Mapped[str] = mapped_column(String(20), nullable=True)
    
    # Flags & Party
    is_required: Mapped[bool] = mapped_column(Boolean, default=True)
    is_blocking_shipment: Mapped[bool] = mapped_column(Boolean, default=True)
    responsible_party: Mapped[str] = mapped_column(String(100), default="Customs Broker")
    
    # Status: 'Pending', 'Received', 'Verified', 'Approved', 'Rejected'
    status: Mapped[str] = mapped_column(String(50), default="Pending", nullable=False)
    
    # Dates
    received_date: Mapped[date] = mapped_column(Date, nullable=True)
    verified_date: Mapped[date] = mapped_column(Date, nullable=True)
    
    # Regulatory Agency (e.g. GOEIC, NTRA, Food Safety, Radiation, Decree 43, Defense)
    regulatory_agency: Mapped[str] = mapped_column(String(100), nullable=True)
    
    # Remarks & Corrective Actions
    remarks: Mapped[str] = mapped_column(Text, nullable=True)
    corrective_action_required: Mapped[str] = mapped_column(Text, nullable=True)

    # Parent Relationship
    session: Mapped["CustomsConsultationSession"] = relationship(
        "CustomsConsultationSession", back_populates="checklist_items"
    )
