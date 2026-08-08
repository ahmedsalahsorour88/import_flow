"""
Pydantic Schemas for Import Documentation & Regulatory Compliance (Phase 3 - BP-014 to BP-019)
"""

from typing import Optional, List
from datetime import date, datetime
from pydantic import BaseModel, ConfigDict, Field


# --- ACID REGISTRATION SCHEMAS (BP-014) ---
class AcidRegistrationBase(BaseModel):
    acid_number: str = Field(..., min_length=19, max_length=19, description="19-digit Nafeza ACID Number")
    import_file_id: Optional[int] = None
    po_id: Optional[int] = None
    importer_id: Optional[int] = None
    importer_name: str = Field(..., min_length=2, max_length=200)
    importer_tax_id: str = Field(..., min_length=5, max_length=50)
    supplier_id: Optional[int] = None
    exporter_name: str = Field(..., min_length=2, max_length=200)
    exporter_reg_id: str = Field(..., min_length=2, max_length=100)
    exporter_country: str = Field(..., min_length=2, max_length=100)
    proforma_invoice_no: str = Field(..., min_length=1, max_length=100)
    pol_name: str = Field(..., min_length=2, max_length=150)
    pod_name: str = Field(..., min_length=2, max_length=150)
    requested_date: Optional[date] = None
    generated_date: Optional[date] = None
    expiry_date: date
    verification_notes: Optional[str] = None


class AcidRegistrationCreate(AcidRegistrationBase):
    pass


class AcidRegistrationUpdate(BaseModel):
    acid_number: Optional[str] = None
    import_file_id: Optional[int] = None
    expiry_date: Optional[date] = None
    status: Optional[str] = None
    is_importer_matched: Optional[bool] = None
    is_exporter_matched: Optional[bool] = None
    is_invoice_matched: Optional[bool] = None
    is_ports_matched: Optional[bool] = None
    verification_notes: Optional[str] = None


class AcidRegistrationResponse(AcidRegistrationBase):
    acid_id: int
    acid_code: str
    import_file_id: Optional[int] = None
    import_file_code: Optional[str] = None
    is_importer_matched: bool
    is_exporter_matched: bool
    is_invoice_matched: bool
    is_ports_matched: bool
    status: str
    days_to_expiry: int
    is_verified: bool
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


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
