"""
CargoX & ACI Dispatch Hub SQLAlchemy Models (BP-024 / CGX-001)
"""

from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy import String, Float, Integer, DateTime, ForeignKey, Boolean, Text, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from database.database import Base


class CargoXEnvelope(Base):
    """
    CargoX Blockchain Envelope Model.
    Tracks digital transfer envelopes, blockchain transaction hashes, PKI signatures,
    and Egyptian Customs (Nafeza) dispatch receipts.
    """

    __tablename__ = "cargox_envelopes"

    envelope_id: Mapped[int] = mapped_column(
        Integer, primary_key=True, index=True, autoincrement=True
    )
    envelope_code: Mapped[str] = mapped_column(
        String(50), unique=True, index=True, nullable=False
    )

    import_file_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("import_files.import_file_id"), nullable=True, index=True
    )
    import_file_code: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)

    acid_number: Mapped[str] = mapped_column(
        String(50), index=True, nullable=False
    )

    importer_company_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("import_companies.company_id"), nullable=True, index=True
    )
    importer_company_name: Mapped[str] = mapped_column(String(200), nullable=False)
    importer_tax_number: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)

    supplier_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("suppliers.supplier_id"), nullable=True, index=True
    )
    supplier_name: Mapped[str] = mapped_column(String(200), nullable=False)
    supplier_cargox_id: Mapped[str] = mapped_column(String(100), nullable=False)

    bl_number: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)

    # Status: 'DRAFT', 'UPLOADED_BY_SUPPLIER', 'SEALED_AND_TRANSFERRED', 'ACCEPTED_BY_CUSTOMS', 'REJECTED_NEEDS_AMENDMENT'
    status: Mapped[str] = mapped_column(
        String(50), default="DRAFT", nullable=False, index=True
    )

    blockchain_tx_hash: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    pki_signature: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    is_acid_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    all_documents_sealed: Mapped[bool] = mapped_column(Boolean, default=False)

    transferred_to_customs_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    customs_confirmation_receipt: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    customs_rejection_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    manifest_payload: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc), nullable=False
    )
    created_by: Mapped[str] = mapped_column(String(100), default="SYSTEM", nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False
    )
    updated_by: Mapped[str] = mapped_column(String(100), default="SYSTEM", nullable=False)

    documents: Mapped[List["CargoXEnvelopeDocument"]] = relationship(
        "CargoXEnvelopeDocument", back_populates="envelope", cascade="all, delete-orphan", lazy="selectin"
    )


class CargoXEnvelopeDocument(Base):
    """
    CargoX Document Item within an Envelope.
    Stores metadata, hash (SHA-256), verification against ACID, and attestation status.
    """

    __tablename__ = "cargox_envelope_documents"

    doc_id: Mapped[int] = mapped_column(
        Integer, primary_key=True, index=True, autoincrement=True
    )
    envelope_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("cargox_envelopes.envelope_id"), nullable=False, index=True
    )

    doc_type: Mapped[str] = mapped_column(String(100), nullable=False)
    doc_number: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    file_name: Mapped[str] = mapped_column(String(255), nullable=False)
    file_hash: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    file_size_kb: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    is_mandatory: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_uploaded: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    uploaded_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc), nullable=False
    )

    verified_against_acid: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    pki_signature: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc), nullable=False
    )

    envelope: Mapped["CargoXEnvelope"] = relationship("CargoXEnvelope", back_populates="documents")


class CargoXStandardInvoiceReviewSession(Base):
    """
    CargoX Standard Excel Commercial Invoice Review Session Model (BP-025 / CGX-002).
    Tracks Excel invoice template generation, supplier uploaded template parsing (Named Ranges),
    side-by-side reconciliation, discrepancy overrides, and approval lifecycle.
    """

    __tablename__ = "cargox_standard_invoice_sessions"

    session_id: Mapped[int] = mapped_column(
        Integer, primary_key=True, index=True, autoincrement=True
    )
    session_code: Mapped[str] = mapped_column(
        String(50), unique=True, index=True, nullable=False
    )

    import_file_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("import_files.import_file_id"), nullable=False, index=True
    )
    import_file_code: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    acid_number: Mapped[str] = mapped_column(String(50), index=True, nullable=False)

    invoice_number: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    invoice_date: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    invoice_type: Mapped[str] = mapped_column(
        String(50), default="Commercial Invoice", nullable=False
    )

    purchase_order_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("purchase_orders.po_id"), nullable=True
    )
    purchase_order_number: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)

    supplier_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("suppliers.supplier_id"), nullable=True
    )
    exporter_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    exporter_tax_id: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    exporter_country_code: Mapped[Optional[str]] = mapped_column(String(10), nullable=True)

    importer_company_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("import_companies.company_id"), nullable=True
    )
    importer_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    importer_tax_id: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)

    currency_code: Mapped[str] = mapped_column(String(10), default="EUR", nullable=False)
    incoterm: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    pol_code: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    pod_code: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)

    gross_weight_kg: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    net_weight_kg: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    weight_unit: Mapped[str] = mapped_column(String(10), default="KGM", nullable=False)

    subtotal_amount: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    freight_cost: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    insurance_cost: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    other_costs: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    total_amount: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    line_items_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    system_snapshot_data: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    supplier_invoice_data: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    comparison_data: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)

    has_discrepancies: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    has_critical_mismatch: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    discrepancy_override_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Status: 'DRAFT', 'UNDER_REVIEW', 'APPROVED', 'REJECTED_NEEDS_MODIFICATION'
    status: Mapped[str] = mapped_column(
        String(50), default="DRAFT", nullable=False, index=True
    )

    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc), nullable=False
    )
    created_by: Mapped[str] = mapped_column(String(100), default="SYSTEM", nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False
    )
    updated_by: Mapped[str] = mapped_column(String(100), default="SYSTEM", nullable=False)

