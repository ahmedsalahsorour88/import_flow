"""
Smart Document Upload — Pydantic Schemas
Request & Response schemas for every supported module.
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field


# ─────────────────────────────────────────────────────────────────────────────
# Supported module names (used as URL path segment)
# ─────────────────────────────────────────────────────────────────────────────

SUPPORTED_MODULES = {
    "purchase-order",
    "import-file",
    "cargo-shipping",
    "customs-clearance",
    "freight-quotation",
    "freight-booking",
    "clearance-quotation",
    "customs-broker-quotation",
    "customs-consultation",
    "warehouse-receiving",
    "demurrage",
    "financial-document",
    "coo-certificate",
    "inspection-certificate",
}


# ─────────────────────────────────────────────────────────────────────────────
# Generic extraction response
# ─────────────────────────────────────────────────────────────────────────────

class SmartUploadResponse(BaseModel):
    """Universal response returned by every smart-upload parse endpoint."""
    session_id: Optional[int] = None
    session_ref: Optional[str] = None
    module_name: str
    filename: str
    file_type: str
    file_size_bytes: Optional[int] = None
    extraction_status: str               # SUCCESS | PARTIAL | FAILED
    confidence_score: float = 0.0        # 0.0 – 1.0
    extracted_fields: Dict[str, Any] = Field(default_factory=dict)
    missing_fields: List[str] = Field(default_factory=list)
    extraction_notes: Optional[str] = None
    raw_text_preview: Optional[str] = None  # First 500 chars of extracted text (debug)

    # ── Entity Verification Results ─────────────────────────────────────────
    # Indicates whether supplier_name / importer_name extracted from the document
    # were matched against existing records in the database.
    supplier_verified: Optional[bool] = None   # True=found, False=not found, None=not applicable
    supplier_id: Optional[int] = None          # DB supplier_id if matched
    supplier_code: Optional[str] = None        # Business code if matched (e.g. SUP-000001)
    importer_verified: Optional[bool] = None   # True=found, False=not found, None=not applicable
    importer_id: Optional[int] = None          # DB company_id if matched
    importer_code: Optional[str] = None        # Business importer_id code if matched


# ─────────────────────────────────────────────────────────────────────────────
# Upload Session list/detail
# ─────────────────────────────────────────────────────────────────────────────

class UploadSessionResponse(BaseModel):
    id: int
    session_ref: str
    module_name: str
    filename: str
    file_type: Optional[str]
    file_size_bytes: Optional[int]
    extraction_status: str
    confidence_score: float
    extracted_fields: Dict[str, Any] = Field(default_factory=dict)
    missing_fields: List[str] = Field(default_factory=list)
    extraction_notes: Optional[str]
    linked_record_id: Optional[int]
    linked_module: Optional[str]
    created_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)


# ─────────────────────────────────────────────────────────────────────────────
# Per-module extracted field schemas (for type safety in Flutter)
# ─────────────────────────────────────────────────────────────────────────────

class POLineItemExtracted(BaseModel):
    description: Optional[str] = None
    quantity: Optional[float] = None
    unit: Optional[str] = None
    unit_price: Optional[float] = None
    total_price: Optional[float] = None
    hs_code: Optional[str] = None


class PurchaseOrderExtracted(BaseModel):
    po_number: Optional[str] = None
    supplier_name: Optional[str] = None
    order_date: Optional[str] = None
    currency: Optional[str] = None
    incoterms: Optional[str] = None
    delivery_port: Optional[str] = None
    payment_terms: Optional[str] = None
    total_amount: Optional[float] = None
    items: List[POLineItemExtracted] = Field(default_factory=list)


class ContainerExtracted(BaseModel):
    container_no: Optional[str] = None
    seal_no: Optional[str] = None
    container_type: Optional[str] = None
    gross_weight_kg: Optional[float] = None
    cbm: Optional[float] = None


class CargoShippingExtracted(BaseModel):
    bl_number: Optional[str] = None
    vessel_name: Optional[str] = None
    voyage_number: Optional[str] = None
    carrier_name: Optional[str] = None
    loading_port: Optional[str] = None
    discharge_port: Optional[str] = None
    etd: Optional[str] = None
    eta: Optional[str] = None
    total_gross_weight_kg: Optional[float] = None
    total_cbm: Optional[float] = None
    containers: List[ContainerExtracted] = Field(default_factory=list)
    shipper: Optional[str] = None
    consignee: Optional[str] = None


class CustomsClearanceExtracted(BaseModel):
    declaration_no: Optional[str] = None
    declaration_date: Optional[str] = None
    hs_code: Optional[str] = None
    commodity_description: Optional[str] = None
    origin_country: Optional[str] = None
    customs_value_egp: Optional[float] = None
    exchange_rate: Optional[float] = None
    import_duty: Optional[float] = None
    vat_amount: Optional[float] = None
    schedule_tax: Optional[float] = None
    other_fees: Optional[float] = None
    total_taxes: Optional[float] = None


class ImportFileExtracted(BaseModel):
    commodity_description: Optional[str] = None
    hs_code: Optional[str] = None
    origin_country: Optional[str] = None
    loading_port: Optional[str] = None
    discharge_port: Optional[str] = None
    incoterms: Optional[str] = None
    currency: Optional[str] = None
    invoice_value: Optional[float] = None
    supplier_name: Optional[str] = None
    invoice_number: Optional[str] = None
    invoice_date: Optional[str] = None


class FreightQuotationExtracted(BaseModel):
    carrier_name: Optional[str] = None
    origin_port: Optional[str] = None
    destination_port: Optional[str] = None
    freight_rate: Optional[float] = None
    currency: Optional[str] = None
    transit_days: Optional[int] = None
    validity_date: Optional[str] = None
    container_type: Optional[str] = None
    free_days_demurrage: Optional[int] = None
    free_days_detention: Optional[int] = None


class FreightBookingExtracted(BaseModel):
    booking_number: Optional[str] = None
    carrier_name: Optional[str] = None
    vessel_name: Optional[str] = None
    voyage_number: Optional[str] = None
    loading_port: Optional[str] = None
    discharge_port: Optional[str] = None
    etd: Optional[str] = None
    eta: Optional[str] = None
    si_cutoff: Optional[str] = None
    vgm_cutoff: Optional[str] = None
    container_type: Optional[str] = None
    containers_count: Optional[int] = None


class COOCertificateExtracted(BaseModel):
    certificate_number: Optional[str] = None
    issue_date: Optional[str] = None
    origin_country: Optional[str] = None
    exporter_name: Optional[str] = None
    consignee_name: Optional[str] = None
    product_description: Optional[str] = None
    hs_code: Optional[str] = None
    gross_weight: Optional[str] = None
    invoice_number: Optional[str] = None


class InspectionCertificateExtracted(BaseModel):
    certificate_number: Optional[str] = None
    inspection_date: Optional[str] = None
    inspector_name: Optional[str] = None
    inspection_company: Optional[str] = None
    product_description: Optional[str] = None
    quantity_inspected: Optional[str] = None
    result: Optional[str] = None          # PASS | FAIL | CONDITIONAL
    defects_found: Optional[str] = None
    remarks: Optional[str] = None


class FinancialDocumentExtracted(BaseModel):
    invoice_number: Optional[str] = None
    invoice_date: Optional[str] = None
    supplier_name: Optional[str] = None
    amount: Optional[float] = None
    currency: Optional[str] = None
    payment_terms: Optional[str] = None
    bank_name: Optional[str] = None
    swift_code: Optional[str] = None
    iban: Optional[str] = None
    due_date: Optional[str] = None
