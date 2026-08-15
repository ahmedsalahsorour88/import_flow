from typing import Optional, List, Dict, Any
from datetime import date, datetime
from pydantic import BaseModel, ConfigDict, Field


# --- ACID REGISTRATION SCHEMAS (BP-014) ---
class AcidRegistrationBase(BaseModel):
    acid_number: Optional[str] = Field(default="PENDING", description="19-digit Nafeza ACID Number or PENDING during request")
    import_file_id: Optional[int] = None
    po_id: Optional[int] = None
    po_number: Optional[str] = None
    po_date: Optional[date] = None

    importer_id: Optional[int] = None
    importer_name: str = Field(..., min_length=2, max_length=200)
    importer_tax_id: str = Field(..., min_length=5, max_length=50)
    importer_address: Optional[str] = None

    supplier_id: Optional[int] = None
    exporter_name: str = Field(..., min_length=2, max_length=200)
    exporter_reg_type: Optional[str] = Field(default="VAT Number", max_length=100)
    exporter_reg_id: str = Field(..., min_length=1, max_length=100)
    exporter_country: str = Field(..., min_length=1, max_length=100)
    exporter_country_code: Optional[str] = Field(default=None, max_length=10)
    exporter_address: Optional[str] = None
    exporter_phone: Optional[str] = None
    cargox_id: Optional[str] = None

    proforma_invoice_no: str = Field(..., min_length=1, max_length=100)
    proforma_invoice_date: Optional[date] = None
    invoice_date: Optional[date] = None
    invoice_type: Optional[str] = Field(default="Proforma Invoice", max_length=50)
    invoice_attachment_name: Optional[str] = None

    pol_name: str = Field(..., min_length=1, max_length=150)
    pod_name: str = Field(..., min_length=1, max_length=150)

    customs_broker_id: Optional[int] = None
    customs_broker_name: Optional[str] = None
    customs_broker_phone: Optional[str] = None

    requested_date: Optional[date] = None
    generated_date: Optional[date] = None
    expiry_date: Optional[date] = None

    raw_nafeza_text: Optional[str] = None
    requested_data: Optional[Dict[str, Any]] = None
    generated_data: Optional[Dict[str, Any]] = None
    discrepancies_data: Optional[Dict[str, Any]] = None
    discrepancy_override_reason: Optional[str] = None
    verification_notes: Optional[str] = None

    from pydantic import field_validator

    @field_validator("acid_number")
    @classmethod
    def validate_acid_number_field(cls, v: Optional[str]) -> Optional[str]:
        if not v:
            return "PENDING"
        cleaned = v.strip()
        if cleaned.upper() in ["PENDING", "REQUESTED", "DRAFT", ""]:
            return cleaned.upper()
        if len(cleaned) != 19 or not cleaned.isdigit():
            raise ValueError(f"ACID Number must be exactly 19 numeric digits, got '{cleaned}' ({len(cleaned)} digits).")
        return cleaned


class AcidRegistrationCreate(AcidRegistrationBase):
    pass


class AcidRegistrationUpdate(BaseModel):
    acid_number: Optional[str] = None
    import_file_id: Optional[int] = None
    po_id: Optional[int] = None
    importer_name: Optional[str] = None
    importer_tax_id: Optional[str] = None
    importer_address: Optional[str] = None
    exporter_name: Optional[str] = None
    exporter_reg_type: Optional[str] = None
    exporter_reg_id: Optional[str] = None
    exporter_country: Optional[str] = None
    exporter_country_code: Optional[str] = None
    exporter_address: Optional[str] = None
    exporter_phone: Optional[str] = None
    cargox_id: Optional[str] = None
    proforma_invoice_no: Optional[str] = None
    proforma_invoice_date: Optional[date] = None
    invoice_date: Optional[date] = None
    invoice_type: Optional[str] = None
    invoice_attachment_name: Optional[str] = None
    pol_name: Optional[str] = None
    pod_name: Optional[str] = None
    customs_broker_name: Optional[str] = None
    customs_broker_phone: Optional[str] = None
    requested_date: Optional[date] = None
    generated_date: Optional[date] = None
    expiry_date: Optional[date] = None
    raw_nafeza_text: Optional[str] = None
    requested_data: Optional[Dict[str, Any]] = None
    generated_data: Optional[Dict[str, Any]] = None
    discrepancies_data: Optional[Dict[str, Any]] = None
    discrepancy_override_reason: Optional[str] = None
    status: Optional[str] = None
    is_importer_matched: Optional[bool] = None
    is_exporter_matched: Optional[bool] = None
    is_invoice_matched: Optional[bool] = None
    is_ports_matched: Optional[bool] = None
    has_discrepancies: Optional[bool] = None
    verification_notes: Optional[str] = None


class AcidRegistrationResponse(AcidRegistrationBase):
    acid_id: int
    acid_code: str
    import_file_id: Optional[int] = None
    import_file_code: Optional[str] = None
    is_importer_matched: bool = True
    is_exporter_matched: bool = True
    is_invoice_matched: bool = True
    is_ports_matched: bool = True
    has_discrepancies: bool = False
    status: str
    days_to_expiry: int
    is_verified: bool
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class AcidTextParseRequest(BaseModel):
    raw_text: str = Field(..., min_length=10, description="Raw MTS / Nafeza approval notification text")
    import_file_id: Optional[int] = None


class AcidTextParseResponse(BaseModel):
    parsed_data: Dict[str, Any]
    comparison: Optional[Dict[str, Any]] = None


class AcidComparisonRequest(BaseModel):
    requested: Dict[str, Any]
    generated: Dict[str, Any]


class AcidRequestTemplateResponse(BaseModel):
    whatsapp_text: str
    email_subject: str
    email_body: str


# --- BANKING DOCUMENT SCHEMAS (BP-015) ---
class BankingDocumentBase(BaseModel):
    doc_type: str = Field(default="Form 4", description="Form 4, Form 9, Letter of Credit (L/C)")
    import_file_id: Optional[int] = None
    po_id: Optional[int] = None
    bank_id: Optional[int] = None
    bank_name: str = Field(..., min_length=2, max_length=200)
    doc_reference_number: str = Field(..., min_length=2, max_length=100)
    amount: float = Field(..., gt=0.0)
    currency_code: str = Field(default="USD", max_length=10)
    issue_date: Optional[date] = None
    expiry_date: Optional[date] = None
    notes: Optional[str] = None


class BankingDocumentCreate(BankingDocumentBase):
    pass


class BankingDocumentUpdate(BaseModel):
    doc_reference_number: Optional[str] = None
    import_file_id: Optional[int] = None
    amount: Optional[float] = None
    expiry_date: Optional[date] = None
    status: Optional[str] = None
    notes: Optional[str] = None


class BankingDocumentResponse(BankingDocumentBase):
    bank_doc_id: int
    bank_doc_code: str
    import_file_id: Optional[int] = None
    import_file_code: Optional[str] = None
    status: str
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# --- SHIPMENT DOCUMENT ITEM SCHEMAS (BP-016, BP-017, BP-018) ---
class ShipmentDocumentBase(BaseModel):
    import_file_id: Optional[int] = None
    po_id: Optional[int] = None
    doc_name: str = Field(..., min_length=2, max_length=100)
    doc_number: str = Field(..., min_length=1, max_length=100)
    issue_date: Optional[date] = None
    received_date: Optional[date] = None
    notes: Optional[str] = None


class ShipmentDocumentCreate(ShipmentDocumentBase):
    pass


class ShipmentDocumentUpdate(BaseModel):
    doc_number: Optional[str] = None
    import_file_id: Optional[int] = None
    status: Optional[str] = None
    is_cargox_uploaded: Optional[bool] = None
    cargox_envelope_id: Optional[str] = None
    is_bl_endorsed: Optional[bool] = None
    endorsement_number: Optional[str] = None
    notes: Optional[str] = None


class ShipmentDocumentResponse(ShipmentDocumentBase):
    document_id: int
    document_code: str
    import_file_id: Optional[int] = None
    import_file_code: Optional[str] = None
    status: str
    is_cargox_uploaded: bool
    cargox_envelope_id: Optional[str] = None
    is_bl_endorsed: bool
    endorsement_number: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# --- CUSTOMS DECLARATION 46 DRAFT SCHEMAS (BP-019) ---
class CustomsDeclarationBase(BaseModel):
    import_file_id: Optional[int] = None
    po_id: Optional[int] = None
    acid_number: str = Field(..., min_length=19, max_length=19)
    form4_number: Optional[str] = None
    bl_number: Optional[str] = None
    total_cif_val_egp: float = Field(default=0.0, ge=0.0)
    total_customs_duties_egp: float = Field(default=0.0, ge=0.0)
    total_vat_egp: float = Field(default=0.0, ge=0.0)


class CustomsDeclarationCreate(CustomsDeclarationBase):
    pass


class CustomsDeclarationResponse(CustomsDeclarationBase):
    declaration_id: int
    declaration_code: str
    import_file_id: Optional[int] = None
    import_file_code: Optional[str] = None
    declaration_status: str
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# --- ACID EXPIRY TRACKER SCHEMAS ---
class AcidTrackerItem(BaseModel):
    import_file_id: Optional[int] = None
    import_file_code: Optional[str] = None
    custom_file_number: Optional[str] = None
    acid_session_id: Optional[int] = None
    acid_code: Optional[str] = None
    acid_number: str
    importer_name: str
    supplier_name: str
    po_number: Optional[str] = None
    pi_number: Optional[str] = None
    shipment_mode: Optional[str] = None
    current_stage: Optional[str] = None
    customs_broker_name: Optional[str] = None

    # Dates & Validity
    acid_issue_date: Optional[date] = None
    acid_expiry_date: Optional[date] = None
    days_remaining: int
    total_validity_days: int = 90
    validity_percentage: float  # 0 to 100%

    # Customs Release Status (Key Rule: alert removed once customs released)
    is_customs_released: bool = False
    customs_released_at: Optional[datetime] = None
    release_permit_no: Optional[str] = None

    # Tracker Status: 'Valid', 'Expiring Soon', 'Expired', 'Customs Released', 'Pending Issue'
    status: str
    status_label_ar: str
    alert_required: bool  # True only if NOT customs released AND (days_remaining <= 14 or expired)


class AcidTrackerSummary(BaseModel):
    total_acids_count: int
    valid_count: int
    expiring_soon_count: int
    expired_count: int
    customs_released_count: int
    pending_issue_count: int
    items: List[AcidTrackerItem]

