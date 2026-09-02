"""
Pydantic Schemas for CargoX & ACI Dispatch Hub (CGX-001)
"""

from datetime import datetime
from typing import List, Optional, Dict, Any, Literal
from pydantic import BaseModel, ConfigDict, Field


class CargoXDocumentCreate(BaseModel):
    doc_type: str = Field(..., description="Document type, e.g. Commercial Invoice, Packing List, Draft B/L, COO")
    doc_number: Optional[str] = None
    file_name: str
    file_hash: Optional[str] = None
    file_size_kb: float = 0.0
    is_mandatory: bool = True
    verified_against_acid: bool = True
    notes: Optional[str] = None


class CargoXDocumentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    doc_id: int
    envelope_id: int
    doc_type: str
    doc_number: Optional[str] = None
    file_name: str
    file_hash: Optional[str] = None
    file_size_kb: float
    is_mandatory: bool
    is_uploaded: bool
    uploaded_at: datetime
    verified_against_acid: bool
    pki_signature: Optional[str] = None
    notes: Optional[str] = None
    is_active: bool
    created_at: datetime


class CargoXEnvelopeCreate(BaseModel):
    import_file_id: Optional[int] = None
    acid_number: str = Field(..., min_length=19, max_length=19, description="19-digit Egyptian ACID Number")
    importer_company_id: Optional[int] = None
    importer_company_name: str
    importer_tax_number: Optional[str] = None
    supplier_id: Optional[int] = None
    supplier_name: str
    supplier_cargox_id: str = Field(..., description="Foreign Exporter CargoX Platform ID")
    bl_number: Optional[str] = None
    notes: Optional[str] = None
    documents: Optional[List[CargoXDocumentCreate]] = None
    mode: str = "MOCK"  # MOCK, STAGING, PRODUCTION


class CargoXEnvelopeUpdate(BaseModel):
    acid_number: Optional[str] = None
    importer_company_name: Optional[str] = None
    importer_tax_number: Optional[str] = None
    supplier_name: Optional[str] = None
    supplier_cargox_id: Optional[str] = None
    bl_number: Optional[str] = None
    status: Optional[str] = None
    notes: Optional[str] = None


class CargoXEnvelopeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    envelope_id: int
    envelope_code: str
    import_file_id: Optional[int] = None
    import_file_code: Optional[str] = None
    acid_number: str
    importer_company_id: Optional[int] = None
    importer_company_name: str
    importer_tax_number: Optional[str] = None
    supplier_id: Optional[int] = None
    supplier_name: str
    supplier_cargox_id: str
    bl_number: Optional[str] = None
    status: str
    blockchain_tx_hash: Optional[str] = None
    pki_signature: Optional[str] = None
    is_acid_verified: bool
    all_documents_sealed: bool
    transferred_to_customs_at: Optional[datetime] = None
    customs_confirmation_receipt: Optional[str] = None
    customs_rejection_reason: Optional[str] = None
    notes: Optional[str] = None
    is_active: bool
    created_at: datetime
    created_by: str
    updated_at: datetime
    updated_by: str
    documents: List[CargoXDocumentResponse] = []


class CargoXSealAndTransferRequest(BaseModel):
    bl_number: Optional[str] = None
    mode: str = "MOCK"


class CargoXSealAndTransferResponse(BaseModel):
    success: bool
    envelope_id: int
    envelope_code: str
    acid_number: str
    status: str
    bl_number: Optional[str] = None
    blockchain_tx_hash: str
    pki_signature: str
    transferred_at: datetime
    customs_confirmation_receipt: str
    message: str


class ACIDDocumentVerificationItem(BaseModel):
    doc_type: str
    doc_number: Optional[str] = None
    document_acid: str
    is_matched: bool
    status: str
    notes: Optional[str] = None


class CargoXAcidVerificationReport(BaseModel):
    envelope_id: int
    envelope_code: str
    target_acid_number: str
    all_matched: bool
    verified_count: int
    total_documents: int
    verification_status: str
    items: List[ACIDDocumentVerificationItem] = []


class DigitalManifestPayload(BaseModel):
    manifest_id: str
    envelope_code: str
    acid_number: str
    generated_at: str
    importer: Dict[str, Any]
    exporter: Dict[str, Any]
    transport: Dict[str, Any]
    blockchain: Dict[str, Any]
    documents: List[Dict[str, Any]]


class DigitalManifestResponse(BaseModel):
    envelope_id: int
    envelope_code: str
    acid_number: str
    manifest_json: Dict[str, Any]
    exported_at: datetime
    formatted_summary: str


# ============================================================================
# STANDARD EXCEL COMMERCIAL INVOICE SCHEMAS (BP-025 / CGX-002)
# ============================================================================

class StandardInvoiceLineItem(BaseModel):
    index: int = 1
    product_code: Optional[str] = None
    manufacturer: Optional[str] = None
    brand_name: Optional[str] = None
    model: Optional[str] = None
    hs_code: str = Field(..., description="HS Tariff Code (6 to 10 digits)")
    country_of_origin: str = Field(..., description="ISO-2 Country Code (e.g. IT, LT, CN)")
    description: str = Field(..., description="Item Description")
    quantity: float = 1.0
    qty_unit: str = "PCE"  # KGM, SET, PCE, CT, BX, etc.
    expiry_date: Optional[str] = None
    unit_price: float = 0.0
    unit_price_basis: str = "PCS"
    gross_weight_kg: float = 0.0
    net_weight_kg: float = 0.0
    total_amount: float = 0.0


class StandardInvoicePayload(BaseModel):
    # Seller Data
    seller_name: Optional[str] = None
    seller_address: Optional[str] = None
    seller_city: Optional[str] = None
    seller_country_code: Optional[str] = None
    seller_tax_id: Optional[str] = None
    seller_contact_name: Optional[str] = None
    seller_phone: Optional[str] = None
    seller_fax: Optional[str] = None
    seller_email: Optional[str] = None
    seller_website: Optional[str] = None

    # Buyer Data
    buyer_name: Optional[str] = None
    buyer_address: Optional[str] = None
    buyer_tax_id: Optional[str] = None
    buyer_contact_name: Optional[str] = None
    buyer_phone: Optional[str] = None
    buyer_fax: Optional[str] = None
    buyer_email: Optional[str] = None
    acid_number: Optional[str] = None

    # Shipment / Invoice Header
    invoice_type: str = "Commercial Invoice"
    invoice_number: Optional[str] = None
    invoice_date: Optional[str] = None
    purchase_order_number: Optional[str] = None
    purchase_order_date: Optional[str] = None
    proforma_invoice_number: Optional[str] = None
    origin_port: Optional[str] = None
    destination_port: Optional[str] = None
    currency_code: str = "EUR"
    incoterm: Optional[str] = "EXW"
    gross_weight: float = 0.0
    net_weight: float = 0.0
    weight_unit: str = "KGM"

    # Line Items
    items: List[StandardInvoiceLineItem] = []

    # Financial Totals
    subtotal: float = 0.0
    freight_cost: float = 0.0
    insurance_cost: float = 0.0
    other_costs: float = 0.0
    total_amount: float = 0.0


class StandardInvoiceComparisonRow(BaseModel):
    field_key: str
    field_label_ar: str
    field_label_en: str
    system_value: Any
    supplier_value: Any
    status: str  # MATCH, WARNING, CRITICAL_MISMATCH
    difference: Optional[str] = None
    notes: Optional[str] = None


class StandardInvoiceLineComparisonRow(BaseModel):
    index: int
    product_code: Optional[str] = None
    hs_code_system: Optional[str] = None
    hs_code_supplier: Optional[str] = None
    description_system: Optional[str] = None
    description_supplier: Optional[str] = None
    qty_system: float = 0.0
    qty_supplier: float = 0.0
    unit_price_system: float = 0.0
    unit_price_supplier: float = 0.0
    total_system: float = 0.0
    total_supplier: float = 0.0
    gross_weight_system: float = 0.0
    gross_weight_supplier: float = 0.0
    status: str  # MATCH, WARNING, CRITICAL_MISMATCH
    notes: Optional[str] = None


class StandardInvoiceComparisonResponse(BaseModel):
    import_file_id: int
    import_file_code: Optional[str] = None
    acid_number: str
    has_discrepancies: bool
    has_critical_mismatch: bool
    total_discrepancies_count: int
    critical_mismatches_count: int
    warnings_count: int
    header_comparisons: List[StandardInvoiceComparisonRow] = []
    financial_comparisons: List[StandardInvoiceComparisonRow] = []
    line_item_comparisons: List[StandardInvoiceLineComparisonRow] = []
    system_snapshot: StandardInvoicePayload
    supplier_data: StandardInvoicePayload
    rectification_notice_en: Optional[str] = None
    rectification_notice_ar: Optional[str] = None


class StandardInvoiceSessionCreate(BaseModel):
    import_file_id: int
    import_file_code: Optional[str] = None
    acid_number: str
    invoice_number: Optional[str] = None
    invoice_date: Optional[str] = None
    invoice_type: str = "Commercial Invoice"
    purchase_order_id: Optional[int] = None
    purchase_order_number: Optional[str] = None
    supplier_id: Optional[int] = None
    exporter_name: Optional[str] = None
    exporter_tax_id: Optional[str] = None
    exporter_country_code: Optional[str] = None
    importer_company_id: Optional[int] = None
    importer_name: Optional[str] = None
    importer_tax_id: Optional[str] = None
    currency_code: str = "EUR"
    incoterm: Optional[str] = None
    pol_code: Optional[str] = None
    pod_code: Optional[str] = None
    gross_weight_kg: float = 0.0
    net_weight_kg: float = 0.0
    weight_unit: str = "KGM"
    subtotal_amount: float = 0.0
    freight_cost: float = 0.0
    insurance_cost: float = 0.0
    other_costs: float = 0.0
    total_amount: float = 0.0
    line_items_count: int = 0
    system_snapshot_data: Optional[Dict[str, Any]] = None
    supplier_invoice_data: Optional[Dict[str, Any]] = None
    comparison_data: Optional[Dict[str, Any]] = None
    has_discrepancies: bool = False
    has_critical_mismatch: bool = False
    discrepancy_override_reason: Optional[str] = None
    status: str = "DRAFT"  # DRAFT, UNDER_REVIEW, APPROVED, REJECTED_NEEDS_MODIFICATION
    notes: Optional[str] = None


class StandardInvoiceStatusUpdateRequest(BaseModel):
    status: str
    discrepancy_override_reason: Optional[str] = None
    notes: Optional[str] = None


class StandardInvoiceSessionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    session_id: int
    session_code: str
    import_file_id: int
    import_file_code: Optional[str] = None
    acid_number: str
    invoice_number: Optional[str] = None
    invoice_date: Optional[str] = None
    invoice_type: str
    purchase_order_id: Optional[int] = None
    purchase_order_number: Optional[str] = None
    supplier_id: Optional[int] = None
    exporter_name: Optional[str] = None
    exporter_tax_id: Optional[str] = None
    exporter_country_code: Optional[str] = None
    importer_company_id: Optional[int] = None
    importer_name: Optional[str] = None
    importer_tax_id: Optional[str] = None
    currency_code: str
    incoterm: Optional[str] = None
    pol_code: Optional[str] = None
    pod_code: Optional[str] = None
    gross_weight_kg: float
    net_weight_kg: float
    weight_unit: str
    subtotal_amount: float
    freight_cost: float
    insurance_cost: float
    other_costs: float
    total_amount: float
    line_items_count: int
    system_snapshot_data: Optional[Dict[str, Any]] = None
    supplier_invoice_data: Optional[Dict[str, Any]] = None
    comparison_data: Optional[Dict[str, Any]] = None
    has_discrepancies: bool
    has_critical_mismatch: bool
    discrepancy_override_reason: Optional[str] = None
    status: str
    notes: Optional[str] = None
    is_active: bool
    created_at: datetime
    created_by: str
    updated_at: datetime
    updated_by: str


# ============================================================================
# CGX-003: Multi-Path Extraction Engine Schemas
# ============================================================================

# Extraction Mode Type
ExtractionMode = Literal[
    "all_consolidated",          # ملف Excel واحد — بنود مجمعة بـ HS Code (weighted average price)
    "all_detailed",              # ملف Excel واحد — بنود مفصلة (مع تكرار HS Code لو في أكثر من سعر)
    "per_invoice_consolidated",  # ZIP بعدد الفواتير — كل ملف مجمع بـ HS Code
    "per_invoice_detailed",      # ZIP بعدد الفواتير — كل ملف مفصل
]

# Grouping Mode Type
GroupingMode = Literal[
    "by_hs_code",     # تجميع وحساب متوسط سعر موزون لكل HS Code (الافتراضي للجمرك)
    "by_price_group", # تجميع لكل HS Code + سعر (لو أسعار مختلفة = سطور مختلفة)
    "flat",           # بدون تجميع — كل سطر منفصل كما هو
]


class ExtractionRequest(BaseModel):
    """
    طلب استخراج فاتورة CargoX متعدد المسارات (CGX-003).
    يحدد mode الاستخراج ومنطق تجميع البنود.
    """
    mode: ExtractionMode = "all_consolidated"
    grouping_mode: GroupingMode = "by_hs_code"
    invoice_filter: Optional[str] = None  # رقم فاتورة محدد لو عايز تستخرج فاتورة واحدة بعينها
    notes: Optional[str] = None


class ExtractionResultItem(BaseModel):
    """نتيجة استخراج فاتورة واحدة ضمن نتائج multi-extract."""
    invoice_number: Optional[str] = None
    payload: StandardInvoicePayload


class ExtractionResponse(BaseModel):
    """استجابة محرك الاستخراج متعدد المسارات."""
    import_file_id: int
    import_file_code: Optional[str] = None
    mode: str
    grouping_mode: str
    invoices_count: int
    total_line_items: int
    results: List[ExtractionResultItem]  # دايماً قايمة — حتى لو عنصر واحد (all_* modes)


class CustomsInvoiceTrackCreate(BaseModel):
    """
    إنشاء نسخة جمركية (Customs Invoice Track).
    """
    import_file_id: int
    extraction_mode: ExtractionMode = "all_consolidated"
    grouping_mode: GroupingMode = "by_hs_code"
    invoice_filter: Optional[str] = None
    notes: Optional[str] = None


class CustomsInvoiceTrackUpdate(BaseModel):
    """
    تعديل نسخة جمركية (Customs Invoice Track).
    """
    status: Optional[str] = None  # "DRAFT" | "APPROVED" | "SEALED"
    notes: Optional[str] = None
    customs_total_amount: Optional[float] = None
    customs_gross_weight: Optional[float] = None
    customs_net_weight: Optional[float] = None
    customs_packages_count: Optional[int] = None
    customs_invoice_data: Optional[Any] = None
    customs_packing_list_data: Optional[Any] = None


class CustomsInvoiceTrackResponse(BaseModel):
    """استجابة نسخة الفاتورة الجمركية المحفوظة."""
    model_config = ConfigDict(from_attributes=True)

    track_id: int
    track_code: str
    import_file_id: int
    import_file_code: Optional[str] = None
    source_invoice_numbers: Optional[Any] = None
    extraction_mode: str
    grouping_mode: str
    customs_total_amount: float
    customs_gross_weight: float
    customs_net_weight: float
    customs_packages_count: int
    line_items_count: int
    customs_invoice_data: Optional[Any] = None
    customs_packing_list_data: Optional[Any] = None
    status: str
    notes: Optional[str] = None
    is_active: bool
    created_at: datetime
    created_by: str
    updated_at: datetime
    updated_by: str
