"""
Financial & Management Approval Models (Phase 2 - BP-012 & BP-013)
"""

from datetime import datetime, date, timezone
from sqlalchemy import String, Float, Integer, DateTime, Date, ForeignKey, Boolean, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from database.database import Base


class PaymentRequestSession(Base):
    """
    Payment Request for Supplier or Financial Settlement (BP-012).
    Tracks requested amounts, beneficiary bank details, exchange rates, remaining PO balance, and payment status.
    """

    __tablename__ = "payment_request_sessions"

    payment_id: Mapped[int] = mapped_column(
        Integer, primary_key=True, index=True, autoincrement=True
    )
    payment_code: Mapped[str] = mapped_column(
        String(50), unique=True, index=True, nullable=False
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)

    # Optional Link to Import File, Purchase Order or Project
    import_file_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("import_files.import_file_id"), nullable=True, index=True
    )
    po_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("purchase_orders.po_id"), nullable=True, index=True
    )
    supplier_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("suppliers.supplier_id"), nullable=True, index=True
    )
    supplier_name: Mapped[str] = mapped_column(String(200), nullable=False)
    project_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("projects.project_id"), nullable=True, index=True
    )

    # Payment Type: 'Advance Payment', 'Against B/L', 'Letter of Credit (L/C)', 'Documentary Collection (CAD)', 'Final Settlement'
    payment_type: Mapped[str] = mapped_column(
        String(50), default="Advance Payment", nullable=False
    )

    # Financial Breakdown & Conversion
    requested_amount: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    currency_code: Mapped[str] = mapped_column(String(10), default="USD", nullable=False)
    exchange_rate: Mapped[float] = mapped_column(Float, default=50.0, nullable=False)
    requested_amount_egp: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    due_date: Mapped[date] = mapped_column(Date, nullable=False)
    request_date: Mapped[date] = mapped_column(Date, default=date.today, nullable=False)

    # Status: 'Draft', 'Pending Approval', 'Approved', 'Paid', 'Rejected'
    status: Mapped[str] = mapped_column(
        String(50), default="Draft", nullable=False, index=True
    )

    # Beneficiary Bank Details Snapshot
    beneficiary_name: Mapped[str] = mapped_column(String(200), nullable=True)
    bank_name: Mapped[str] = mapped_column(String(200), nullable=True)
    swift_code: Mapped[str] = mapped_column(String(50), nullable=True)
    iban_account_no: Mapped[str] = mapped_column(String(100), nullable=True)
    bank_country: Mapped[str] = mapped_column(String(100), nullable=True)

    # Verification & Confirmation
    swift_reference_no: Mapped[str] = mapped_column(String(100), nullable=True)
    notes: Mapped[str] = mapped_column(Text, nullable=True)

    # Audit & Soft Delete
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False
    )


class ImportBudgetApproval(Base):
    """
    Import File Budget Approval (BP-013).
    Consolidates Invoice Cost, Estimated Freight, Estimated Customs & VAT, and Local Handling to form total approved budget.
    """

    __tablename__ = "import_budget_approvals"

    budget_id: Mapped[int] = mapped_column(
        Integer, primary_key=True, index=True, autoincrement=True
    )
    budget_code: Mapped[str] = mapped_column(
        String(50), unique=True, index=True, nullable=False
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)

    import_file_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("import_files.import_file_id"), nullable=True, index=True
    )
    po_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("purchase_orders.po_id"), nullable=True, index=True
    )
    project_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("projects.project_id"), nullable=True, index=True
    )

    # Financial Components (EGP)
    invoice_amount_egp: Mapped[float] = mapped_column(Float, default=0.0)
    freight_cost_egp: Mapped[float] = mapped_column(Float, default=0.0)
    customs_duties_egp: Mapped[float] = mapped_column(Float, default=0.0)
    clearance_inland_egp: Mapped[float] = mapped_column(Float, default=0.0)
    total_budget_egp: Mapped[float] = mapped_column(Float, default=0.0)

    # Budget Status: 'Pending Review', 'Budget Approved', 'Budget Exceeded', 'Rejected'
    budget_status: Mapped[str] = mapped_column(
        String(50), default="Pending Review", nullable=False, index=True
    )
    approved_by: Mapped[str] = mapped_column(String(100), nullable=True)
    approved_date: Mapped[date] = mapped_column(Date, nullable=True)
    notes: Mapped[str] = mapped_column(Text, nullable=True)

    # Audit & Soft Delete
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False
    )
