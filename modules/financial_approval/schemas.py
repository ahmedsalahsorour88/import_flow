"""
Pydantic Schemas for Financial & Management Approval (BP-012 & BP-013)
"""

from typing import Optional, List
from datetime import date, datetime
from pydantic import BaseModel, ConfigDict, Field


# --- PAYMENT REQUEST SCHEMAS (BP-012) ---
class PaymentRequestBase(BaseModel):
    title: str = Field(..., min_length=3, max_length=200)
    import_file_id: Optional[int] = None
    po_id: Optional[int] = None
    supplier_id: Optional[int] = None
    supplier_name: str = Field(..., min_length=2, max_length=200)
    project_id: Optional[int] = None
    payment_type: str = Field(
        default="Advance Payment",
        description="Advance Payment, Against B/L, Letter of Credit (L/C), Documentary Collection (CAD), Final Settlement",
    )
    requested_amount: float = Field(..., gt=0.0)
    currency_code: str = Field(default="USD", max_length=10)
    exchange_rate: float = Field(default=50.0, gt=0.0)
    due_date: date
    request_date: Optional[date] = None
    beneficiary_name: Optional[str] = None
    bank_name: Optional[str] = None
    swift_code: Optional[str] = None
    iban_account_no: Optional[str] = None
    bank_country: Optional[str] = None
    notes: Optional[str] = None


class PaymentRequestCreate(PaymentRequestBase):
    pass


class PaymentRequestUpdate(BaseModel):
    title: Optional[str] = None
    import_file_id: Optional[int] = None
    payment_type: Optional[str] = None
    requested_amount: Optional[float] = None
    currency_code: Optional[str] = None
    exchange_rate: Optional[float] = None
    due_date: Optional[date] = None
    request_date: Optional[date] = None
    status: Optional[str] = None
    beneficiary_name: Optional[str] = None
    bank_name: Optional[str] = None
    swift_code: Optional[str] = None
    iban_account_no: Optional[str] = None
    swift_reference_no: Optional[str] = None
    swift_receipt_date: Optional[date] = None
    swift_transferred_amount: Optional[float] = None
    swift_transferred_currency: Optional[str] = None
    swift_variance_amount: Optional[float] = None
    swift_variance_status: Optional[str] = None
    swift_processing_days: Optional[int] = None
    swift_reconciliation_notes: Optional[str] = None
    notes: Optional[str] = None


class SwiftReconciliationRequest(BaseModel):
    swift_reference_no: str = Field(..., min_length=2, max_length=100, description="SWIFT Reference / MT103 No")
    swift_receipt_date: date = Field(..., description="Date SWIFT was received from the bank")
    swift_transferred_amount: float = Field(..., gt=0.0, description="Actual transferred amount according to SWIFT")
    swift_transferred_currency: str = Field(default="USD", max_length=10)
    swift_reconciliation_notes: Optional[str] = None


class PaymentRequestResponse(PaymentRequestBase):
    payment_id: int
    payment_code: str
    import_file_id: Optional[int] = None
    import_file_code: Optional[str] = None
    requested_amount_egp: float
    request_date: date
    status: str
    swift_reference_no: Optional[str] = None
    swift_receipt_date: Optional[date] = None
    swift_transferred_amount: Optional[float] = None
    swift_transferred_currency: Optional[str] = None
    swift_variance_amount: Optional[float] = None
    swift_variance_status: Optional[str] = None
    swift_processing_days: Optional[int] = None
    swift_reconciliation_notes: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# --- IMPORT BUDGET APPROVAL SCHEMAS (BP-013) ---
class ImportBudgetBase(BaseModel):
    title: str = Field(..., min_length=3, max_length=200)
    import_file_id: Optional[int] = None
    po_id: Optional[int] = None
    project_id: Optional[int] = None
    invoice_amount_egp: float = Field(default=0.0, ge=0.0)
    invoice_amount_foreign: float = Field(default=0.0, ge=0.0)
    invoice_currency: str = Field(default="USD", max_length=10)
    freight_cost_egp: float = Field(default=0.0, ge=0.0)
    freight_cost_foreign: float = Field(default=0.0, ge=0.0)
    freight_currency: str = Field(default="USD", max_length=10)
    customs_duties_egp: float = Field(default=0.0, ge=0.0)
    clearance_inland_egp: float = Field(default=0.0, ge=0.0)
    exchange_rate: float = Field(default=50.0, gt=0.0)
    notes: Optional[str] = None


class ImportBudgetCreate(ImportBudgetBase):
    pass


class ImportBudgetUpdate(BaseModel):
    title: Optional[str] = None
    import_file_id: Optional[int] = None
    invoice_amount_egp: Optional[float] = None
    invoice_amount_foreign: Optional[float] = None
    invoice_currency: Optional[str] = None
    freight_cost_egp: Optional[float] = None
    freight_cost_foreign: Optional[float] = None
    freight_currency: Optional[str] = None
    customs_duties_egp: Optional[float] = None
    clearance_inland_egp: Optional[float] = None
    exchange_rate: Optional[float] = None
    budget_status: Optional[str] = None
    approved_by: Optional[str] = None
    notes: Optional[str] = None


class ImportBudgetResponse(ImportBudgetBase):
    budget_id: int
    budget_code: str
    import_file_id: Optional[int] = None
    import_file_code: Optional[str] = None
    total_budget_egp: float
    budget_status: str
    approved_by: Optional[str] = None
    approved_date: Optional[date] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# --- CROSS-MODULE PREFILL SCHEMAS ---
class LinkedPOItemSchema(BaseModel):
    po_id: int
    po_number: str
    pi_number: Optional[str] = None
    project_id: Optional[int] = None
    project_name: Optional[str] = None
    payment_terms: str
    currency: str
    total_amount: float
    status: str


class BudgetPrefillResponse(BaseModel):
    import_file_id: int
    import_file_code: str
    import_file_title: str
    incoterm: str
    supplier_id: Optional[int] = None
    supplier_name: str
    beneficiary_name: Optional[str] = None
    bank_name: Optional[str] = None
    swift_code: Optional[str] = None
    account_number: Optional[str] = None
    iban: Optional[str] = None
    payment_terms_summary: str
    linked_pos: List[LinkedPOItemSchema] = []
    
    # Financial estimates
    total_invoice_amount: float = 0.0
    invoice_currency: str = "USD"
    total_invoice_amount_egp: float = 0.0
    
    estimated_freight_cost: float = 0.0
    freight_currency: str = "USD"
    estimated_freight_cost_egp: float = 0.0
    
    estimated_customs_duties_egp: float = 0.0
    estimated_clearance_fees_egp: float = 0.0
    estimated_grand_total_egp: float = 0.0
    exchange_rate: float = 50.0


# --- SMART AI SWIFT MT103 EXTRACTOR & RECONCILER SCHEMAS ---
class SmartSwiftExtractRequest(BaseModel):
    raw_text: str = Field(..., min_length=1, description="Raw SWIFT MT103 block or bank transfer advice text")
    target_payment_id: Optional[int] = Field(None, description="Optional target payment request ID to match specifically")


class SmartSwiftFileExtractRequest(BaseModel):
    filename: str
    file_base64: str
    target_payment_id: Optional[int] = None


class SmartSwiftExtractResponse(BaseModel):
    success: bool
    parsed_swift: dict
    matched_payment_request: Optional[dict] = None
    candidate_matches: List[dict] = []
    raw_text: Optional[str] = None
    detected_filename: Optional[str] = None
    detected_file_type: Optional[str] = None
    error: Optional[str] = None


class SmartSwiftReconcileRequest(BaseModel):
    payment_id: int
    raw_text: Optional[str] = None
    swift_reference_no: str
    swift_receipt_date: date
    swift_transferred_amount: float
    swift_transferred_currency: str = "USD"
    bank_name: Optional[str] = None
    swift_code: Optional[str] = None
    iban_account_no: Optional[str] = None
    swift_reconciliation_notes: Optional[str] = None
    auto_execute: bool = True

