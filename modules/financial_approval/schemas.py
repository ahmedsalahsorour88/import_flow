"""
Pydantic Schemas for Financial & Management Approval (BP-012 & BP-013)
"""

from typing import Optional, List
from datetime import date, datetime
from pydantic import BaseModel, ConfigDict, Field


# --- PAYMENT REQUEST SCHEMAS (BP-012) ---
class PaymentRequestBase(BaseModel):
    title: str = Field(..., min_length=3, max_length=200)
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
    payment_type: Optional[str] = None
    requested_amount: Optional[float] = None
    currency_code: Optional[str] = None
    exchange_rate: Optional[float] = None
    due_date: Optional[date] = None
    status: Optional[str] = None
    beneficiary_name: Optional[str] = None
    bank_name: Optional[str] = None
    swift_code: Optional[str] = None
    iban_account_no: Optional[str] = None
    swift_reference_no: Optional[str] = None
    notes: Optional[str] = None


class PaymentRequestResponse(PaymentRequestBase):
    payment_id: int
    payment_code: str
    requested_amount_egp: float
    status: str
    swift_reference_no: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# --- IMPORT BUDGET APPROVAL SCHEMAS (BP-013) ---
class ImportBudgetBase(BaseModel):
    title: str = Field(..., min_length=3, max_length=200)
    po_id: Optional[int] = None
    project_id: Optional[int] = None
    invoice_amount_egp: float = Field(default=0.0, ge=0.0)
    freight_cost_egp: float = Field(default=0.0, ge=0.0)
    customs_duties_egp: float = Field(default=0.0, ge=0.0)
    clearance_inland_egp: float = Field(default=0.0, ge=0.0)
    notes: Optional[str] = None


class ImportBudgetCreate(ImportBudgetBase):
    pass


class ImportBudgetUpdate(BaseModel):
    title: Optional[str] = None
    invoice_amount_egp: Optional[float] = None
    freight_cost_egp: Optional[float] = None
    customs_duties_egp: Optional[float] = None
    clearance_inland_egp: Optional[float] = None
    budget_status: Optional[str] = None
    approved_by: Optional[str] = None
    notes: Optional[str] = None


class ImportBudgetResponse(ImportBudgetBase):
    budget_id: int
    budget_code: str
    total_budget_egp: float
    budget_status: str
    approved_by: Optional[str] = None
    approved_date: Optional[date] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
