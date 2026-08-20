"""
Pydantic Schemas for CargoX & ACI Dispatch Hub (CGX-001)
"""

from datetime import datetime
from typing import List, Optional, Dict, Any
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
