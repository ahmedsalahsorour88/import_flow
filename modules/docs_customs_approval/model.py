"""
SQLAlchemy Models for Docs Customs Approval Hub (DCA-001)
Dual-Tiered Customs Pre-Clearance Approvals & Discrepancy Rectification Tickets.
"""

from datetime import datetime, date, timezone
from sqlalchemy import String, Integer, DateTime, Date, ForeignKey, Boolean, Text, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from database.database import Base


class CustomsDocumentApproval(Base):
    """
    Tracks dual-level compliance sign-off (Commercial + Customs Broker)
    for pre-clearance documents in an Import File.
    """
    __tablename__ = "customs_document_approvals"

    approval_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True, autoincrement=True)
    approval_code: Mapped[str] = mapped_column(String(50), unique=True, index=True, nullable=False)

    import_file_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("import_files.import_file_id"), nullable=False, index=True
    )
    import_file_code: Mapped[str] = mapped_column(String(100), nullable=True)
    po_id: Mapped[int] = mapped_column(Integer, nullable=True)

    document_type: Mapped[str] = mapped_column(String(100), nullable=False)  # Commercial Invoice, Packing List, Bill of Lading, Certificate of Origin, EUR.1, Inspection Cert, Form 4
    document_reference_no: Mapped[str] = mapped_column(String(100), nullable=True)
    document_date: Mapped[date] = mapped_column(Date, nullable=True)

    # Tier 1: Commercial / Operations Review
    commercial_status: Mapped[str] = mapped_column(String(50), default="Pending")  # Pending, Approved, Rejected, Under Review
    commercial_reviewed_by: Mapped[str] = mapped_column(String(100), nullable=True)
    commercial_reviewed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=True)
    commercial_notes: Mapped[str] = mapped_column(Text, nullable=True)

    # Tier 2: Customs Broker / Legal Compliance Sign-off
    customs_status: Mapped[str] = mapped_column(String(50), default="Pending")  # Pending, Approved, Rejected, Conditionally Approved
    customs_reviewed_by: Mapped[str] = mapped_column(String(100), nullable=True)
    customs_reviewed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=True)
    customs_broker_name: Mapped[str] = mapped_column(String(200), nullable=True)
    customs_notes: Mapped[str] = mapped_column(Text, nullable=True)

    # Overall Approval State
    overall_status: Mapped[str] = mapped_column(String(50), default="Draft")  # Draft, Pending Review, Approved for Clearance, Rectification Required, Rejected
    cross_check_summary: Mapped[dict] = mapped_column(JSON, nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class DiscrepancyRectificationTicket(Base):
    """
    Formal rectification and query ticket issued to foreign supplier or carrier
    to amend errors before original document issuance.
    """
    __tablename__ = "discrepancy_rectification_tickets"

    ticket_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True, autoincrement=True)
    ticket_code: Mapped[str] = mapped_column(String(50), unique=True, index=True, nullable=False)

    approval_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("customs_document_approvals.approval_id"), nullable=True, index=True
    )
    import_file_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("import_files.import_file_id"), nullable=False, index=True
    )
    import_file_code: Mapped[str] = mapped_column(String(100), nullable=True)

    issue_category: Mapped[str] = mapped_column(String(100), nullable=False)  # HS Code Mismatch, Weight Discrepancy, CBM Discrepancy, Value Mismatch, Missing ACID, Incoterm Conflict, Other
    severity: Mapped[str] = mapped_column(String(50), default="Major")  # Critical, Major, Minor
    description: Mapped[str] = mapped_column(Text, nullable=False)
    expected_value: Mapped[str] = mapped_column(String(250), nullable=True)
    found_value: Mapped[str] = mapped_column(String(250), nullable=True)

    supplier_action_required: Mapped[str] = mapped_column(Text, nullable=True)
    supplier_response: Mapped[str] = mapped_column(Text, nullable=True)

    status: Mapped[str] = mapped_column(String(50), default="Open")  # Open, Sent to Supplier, Resolved, Waived, Closed
    resolved_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=True)
    resolved_by: Mapped[str] = mapped_column(String(100), nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class DocsCustomsApprovalSession(Base):
    """
    Certified Session for Docs Customs Approval Hub & Central Archive (STEP-09).
    Holds the complete audit and sign-off record across all 5 core documents for an Import File.
    """
    __tablename__ = "docs_customs_approval_sessions"

    session_id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True, autoincrement=True)
    session_code: Mapped[str] = mapped_column(String(50), unique=True, index=True, nullable=False)

    import_file_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("import_files.import_file_id"), nullable=False, index=True
    )
    import_file_code: Mapped[str] = mapped_column(String(100), nullable=True)
    po_id: Mapped[int] = mapped_column(Integer, nullable=True)

    overall_status: Mapped[str] = mapped_column(String(50), default="APPROVED")  # DRAFT, APPROVED, CONDITIONALLY_APPROVED, RECTIFICATION_REQUIRED, REJECTED
    is_draft: Mapped[bool] = mapped_column(Boolean, default=False)

    # 5 Documents References & Compliance Summaries
    final_invoice_ref: Mapped[str] = mapped_column(String(100), nullable=True)
    final_invoice_status: Mapped[str] = mapped_column(String(50), default="Approved")

    final_pl_ref: Mapped[str] = mapped_column(String(100), nullable=True)
    final_pl_status: Mapped[str] = mapped_column(String(50), default="Approved")

    draft_bl_ref: Mapped[str] = mapped_column(String(100), nullable=True)
    draft_bl_status: Mapped[str] = mapped_column(String(50), default="Approved")

    coo_ref: Mapped[str] = mapped_column(String(100), nullable=True)
    coo_status: Mapped[str] = mapped_column(String(50), default="Approved")

    coc_ref: Mapped[str] = mapped_column(String(100), nullable=True)
    coc_status: Mapped[str] = mapped_column(String(50), default="Waived / Not Required")

    # Dual-Tier Signoffs
    commercial_signoff_by: Mapped[str] = mapped_column(String(100), nullable=True)
    commercial_signoff_date: Mapped[date] = mapped_column(Date, nullable=True)
    customs_signoff_by: Mapped[str] = mapped_column(String(100), nullable=True)
    customs_signoff_date: Mapped[date] = mapped_column(Date, nullable=True)
    customs_broker_name: Mapped[str] = mapped_column(String(200), nullable=True)

    discrepancies_count: Mapped[int] = mapped_column(Integer, default=0)
    open_tickets_count: Mapped[int] = mapped_column(Integer, default=0)

    # Full JSON snapshot of archive state
    session_snapshot: Mapped[dict] = mapped_column(JSON, nullable=True)
    notes: Mapped[str] = mapped_column(Text, nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_by: Mapped[str] = mapped_column(String(100), nullable=True, default="ADMIN")
    updated_by: Mapped[str] = mapped_column(String(100), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

