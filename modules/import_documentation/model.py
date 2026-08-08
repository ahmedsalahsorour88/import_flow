"""
Import Documentation & Regulatory Compliance Models (Phase 3 - BP-014 to BP-019)
"""

from datetime import datetime, date
from sqlalchemy import String, Float, Integer, DateTime, Date, ForeignKey, Boolean, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from database.database import Base


class AcidRegistrationSession(Base):
    """
    ACID Registration & Verification Session (BP-014).
    Stores Nafeza 19-digit ACID Number, issue/expiry dates, matching verification flags, and approval status.
    """

    __tablename__ = "acid_registration_sessions"

    acid_id: Mapped[int] = mapped_column(
        Integer, primary_key=True, index=True, autoincrement=True
    )
    acid_code: Mapped[str] = mapped_column(
        String(50), unique=True, index=True, nullable=False
    )
    acid_number: Mapped[str] = mapped_column(
        String(50), unique=True, index=True, nullable=False
    )

    po_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("purchase_orders.po_id"), nullable=True, index=True
    )
    importer_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("import_companies.company_id"), nullable=True, index=True
    )
    importer_name: Mapped[str] = mapped_column(String(200), nullable=False)
    importer_tax_id: Mapped[str] = mapped_column(String(50), nullable=False)

    supplier_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("suppliers.supplier_id"), nullable=True, index=True
    )
    exporter_name: Mapped[str] = mapped_column(String(200), nullable=False)
    exporter_reg_id: Mapped[str] = mapped_column(String(100), nullable=False)
    exporter_country: Mapped[str] = mapped_column(String(100), nullable=False)

    proforma_invoice_no: Mapped[str] = mapped_column(String(100), nullable=False)
    pol_name: Mapped[str] = mapped_column(String(150), nullable=False)
    pod_name: Mapped[str] = mapped_column(String(150), nullable=False)

    requested_date: Mapped[date] = mapped_column(Date, default=date.today, nullable=False)
    generated_date: Mapped[date] = mapped_column(Date, nullable=True)
    expiry_date: Mapped[date] = mapped_column(Date, nullable=False)

    # Verification Match Flags
    is_importer_matched: Mapped[bool] = mapped_column(Boolean, default=True)
    is_exporter_matched: Mapped[bool] = mapped_column(Boolean, default=True)
    is_invoice_matched: Mapped[bool] = mapped_column(Boolean, default=True)
    is_ports_matched: Mapped[bool] = mapped_column(Boolean, default=True)
    verification_notes: Mapped[str] = mapped_column(Text, nullable=True)

    # Status: 'Requested', 'Generated', 'Verified', 'Expired', 'Cancelled'
    status: Mapped[str] = mapped_column(
        String(50), default="Generated", nullable=False, index=True
    )

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )


class BankingDocumentSession(Base):
    """
    Form 4 / Form 9 / Letter of Credit (L/C) Banking Operations (BP-015).
    Manages Central Bank of Egypt import banking forms and L/C opening.
    """

    __tablename__ = "banking_document_sessions"

    bank_doc_id: Mapped[int] = mapped_column(
        Integer, primary_key=True, index=True, autoincrement=True
    )
    bank_doc_code: Mapped[str] = mapped_column(
        String(50), unique=True, index=True, nullable=False
    )

    # Doc Type: 'Form 4', 'Form 9', 'Letter of Credit (L/C)'
    doc_type: Mapped[str] = mapped_column(
        String(50), default="Form 4", nullable=False, index=True
    )

    po_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("purchase_orders.po_id"), nullable=True, index=True
    )
    bank_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("external_service_providers.provider_id"), nullable=True, index=True
    )
    bank_name: Mapped[str] = mapped_column(String(200), nullable=False)

    doc_reference_number: Mapped[str] = mapped_column(String(100), nullable=False)
    amount: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    currency_code: Mapped[str] = mapped_column(String(10), default="USD", nullable=False)

    issue_date: Mapped[date] = mapped_column(Date, default=date.today, nullable=False)
    expiry_date: Mapped[date] = mapped_column(Date, nullable=True)

    # Status: 'Draft', 'Submitted to Bank', 'Approved by Bank', 'Form Issued', 'Rejected'
    status: Mapped[str] = mapped_column(
        String(50), default="Form Issued", nullable=False, index=True
    )
    notes: Mapped[str] = mapped_column(Text, nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )


class ShipmentDocumentItem(Base):
    """
    Shipment Document Lifecycle & CargoX / B/L Endorsement (BP-016, BP-017, BP-018).
    Tracks Commercial Invoice, Packing List, Bill of Lading, Certificate of Origin, Inspection Certs.
    """

    __tablename__ = "shipment_document_items"

    document_id: Mapped[int] = mapped_column(
        Integer, primary_key=True, index=True, autoincrement=True
    )
    document_code: Mapped[str] = mapped_column(
        String(50), unique=True, index=True, nullable=False
    )

    po_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("purchase_orders.po_id"), nullable=True, index=True
    )
    doc_name: Mapped[str] = mapped_column(
        String(100), nullable=False, index=True
    )  # e.g. 'Commercial Invoice', 'Packing List', 'Bill of Lading (B/L)', 'Certificate of Origin (COO)', 'Form 4'

    doc_number: Mapped[str] = mapped_column(String(100), nullable=False)
    issue_date: Mapped[date] = mapped_column(Date, default=date.today, nullable=False)
    received_date: Mapped[date] = mapped_column(Date, nullable=True)

    # Status: 'Draft', 'Received', 'Under Review', 'Approved', 'Rejected', 'Endorsed'
    status: Mapped[str] = mapped_column(
        String(50), default="Approved", nullable=False, index=True
    )

    # CargoX Integration & B/L Endorsement
    is_cargox_uploaded: Mapped[bool] = mapped_column(Boolean, default=False)
    cargox_envelope_id: Mapped[str] = mapped_column(String(100), nullable=True)
    is_bl_endorsed: Mapped[bool] = mapped_column(Boolean, default=False)
    endorsement_number: Mapped[str] = mapped_column(String(100), nullable=True)

    notes: Mapped[str] = mapped_column(Text, nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )


class CustomsDeclarationDraft(Base):
    """
    Customs Declaration 46 Preparation (BP-019).
    Draft for Egyptian Customs Declaration 46 ready for Nafeza Submission.
    """

    __tablename__ = "customs_declaration_drafts"

    declaration_id: Mapped[int] = mapped_column(
        Integer, primary_key=True, index=True, autoincrement=True
    )
    declaration_code: Mapped[str] = mapped_column(
        String(50), unique=True, index=True, nullable=False
    )

    po_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("purchase_orders.po_id"), nullable=True, index=True
    )
    acid_number: Mapped[str] = mapped_column(String(50), nullable=False)
    form4_number: Mapped[str] = mapped_column(String(100), nullable=True)
    bl_number: Mapped[str] = mapped_column(String(100), nullable=True)

    total_cif_val_egp: Mapped[float] = mapped_column(Float, default=0.0)
    total_customs_duties_egp: Mapped[float] = mapped_column(Float, default=0.0)
    total_vat_egp: Mapped[float] = mapped_column(Float, default=0.0)

    # Status: 'Draft Prepared', 'Submitted to Customs Broker', 'Clearance Declaration 46 Issued'
    declaration_status: Mapped[str] = mapped_column(
        String(50), default="Draft Prepared", nullable=False, index=True
    )

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )
