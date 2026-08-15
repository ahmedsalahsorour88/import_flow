from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class PartnerBase(BaseModel):
    partner_name: str = Field(..., min_length=2, max_length=200, example="National Bank of Egypt")
    partner_type: str = Field(..., example="Bank")  # Bank, Shipping Line, Customs Broker, Freight Forwarder, Inland Transport, Inspection Agency
    tax_id: Optional[str] = Field(None, max_length=50)
    commercial_register: Optional[str] = Field(None, max_length=50)

    # Category Specific
    clearance_license_number: Optional[str] = Field(None, max_length=50)
    scac_code: Optional[str] = Field(None, max_length=20)
    tracking_url: Optional[str] = Field(None, max_length=300)
    swift_code: Optional[str] = Field(None, max_length=20)
    bank_code: Optional[str] = Field(None, max_length=20)
    branch_name: Optional[str] = Field(None, max_length=100)

    # Contact & Info
    contact_person: Optional[str] = Field(None, max_length=150)
    phone: Optional[str] = Field(None, max_length=50)
    mobile: Optional[str] = Field(None, max_length=50)
    fax: Optional[str] = Field(None, max_length=50)
    email: Optional[str] = Field(None, max_length=150)
    secondary_email: Optional[str] = Field(None, max_length=150)
    website: Optional[str] = Field(None, max_length=200)
    address: Optional[str] = Field(None, max_length=300)
    country: Optional[str] = Field("Egypt", max_length=100)

    # Financial & Rating
    payment_type: Optional[str] = Field("Credit", max_length=50)
    credit_limit: Optional[float] = Field(0.0, ge=0.0)
    rating: Optional[float] = Field(5.0, ge=1.0, le=5.0)
    notes: Optional[str] = Field(None, max_length=1000)


class PartnerCreate(PartnerBase):
    pass


class PartnerUpdate(BaseModel):
    partner_name: Optional[str] = Field(None, min_length=2, max_length=200)
    partner_type: Optional[str] = None
    tax_id: Optional[str] = None
    commercial_register: Optional[str] = None
    clearance_license_number: Optional[str] = None
    scac_code: Optional[str] = None
    tracking_url: Optional[str] = None
    swift_code: Optional[str] = None
    bank_code: Optional[str] = None
    branch_name: Optional[str] = None
    contact_person: Optional[str] = None
    phone: Optional[str] = None
    mobile: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    country: Optional[str] = None
    payment_type: Optional[str] = None
    credit_limit: Optional[float] = None
    rating: Optional[float] = None
    notes: Optional[str] = None
    is_active: Optional[bool] = None


class PartnerResponse(PartnerBase):
    provider_id: int
    partner_code: str
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ==================================================
# Partner Statement of Account & Currency Balances Schemas
# كشف حساب مقدم الخدمة والشركاء متعدد العملات
# ==================================================

class PartnerCurrencyBalance(BaseModel):
    currency: str
    total_invoiced: float = 0.0
    total_paid: float = 0.0
    balance_due: float = 0.0


class PartnerLedgerEntry(BaseModel):
    entry_id: str
    entry_date: str
    entry_type: str  # 'Invoice (فاتورة مستحقة)', 'Payment (سداد مالي)', 'Quotation (عرض سعر معتمد)'
    reference_no: str
    description: str
    import_file_code: Optional[str] = None
    currency: str
    debit_amount: float = 0.0   # مستحق على الشركة لمقدم الخدمة
    credit_amount: float = 0.0  # مسدد لمقدم الخدمة
    running_balance: float = 0.0
    status: str = "Approved"


class PartnerStatementOfAccountResponse(BaseModel):
    provider_id: int
    partner_code: str
    partner_name: str
    partner_type: str
    currency_balances: list[PartnerCurrencyBalance] = []
    ledger_entries: list[PartnerLedgerEntry] = []
    total_invoices_count: int = 0
    total_payments_count: int = 0