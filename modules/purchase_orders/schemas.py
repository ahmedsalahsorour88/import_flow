from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field, ConfigDict


class POLineItemBase(BaseModel):
    item_code: Optional[str] = Field(None, max_length=50)
    description_ar: str = Field(..., min_length=2, max_length=250)
    description_en: Optional[str] = Field(None, max_length=250)
    tariff_id: Optional[int] = None
    quantity: float = Field(1.0, gt=0)
    unit_of_measure: str = Field("PCS", max_length=30)
    unit_price: float = Field(0.0, ge=0)
    cbm_per_unit: float = Field(0.0, ge=0)
    gross_weight_kg: float = Field(0.0, ge=0)
    net_weight_kg: float = Field(0.0, ge=0)


class POLineItemCreate(POLineItemBase):
    pass


class POLineItemResponse(POLineItemBase):
    item_id: int
    po_id: int
    total_price: float
    total_cbm: float
    created_at: datetime
    hs_code: Optional[str] = None
    duty_rate: Optional[float] = None
    vat_rate: Optional[float] = None

    model_config = ConfigDict(from_attributes=True)


class PurchaseOrderBase(BaseModel):
    proforma_invoice_number: Optional[str] = Field(None, max_length=100)
    project_id: int
    company_id: int
    supplier_id: int
    incoterm_id: int
    currency_id: int
    expected_delivery_date: Optional[datetime] = None
    exchange_rate: float = Field(1.0, gt=0)
    payment_terms: Optional[str] = Field("LC at Sight / اعتماد مستندي", max_length=100)
    notes: Optional[str] = None


class PurchaseOrderCreate(PurchaseOrderBase):
    po_number: Optional[str] = Field(None, max_length=50, description="Auto-generated if empty (PO-YYYY-XXX)")
    items: List[POLineItemCreate] = Field(default_factory=list)


class PurchaseOrderUpdate(BaseModel):
    proforma_invoice_number: Optional[str] = Field(None, max_length=100)
    project_id: Optional[int] = None
    company_id: Optional[int] = None
    supplier_id: Optional[int] = None
    incoterm_id: Optional[int] = None
    currency_id: Optional[int] = None
    expected_delivery_date: Optional[datetime] = None
    exchange_rate: Optional[float] = Field(None, gt=0)
    payment_terms: Optional[str] = Field(None, max_length=100)
    status: Optional[str] = Field(None, max_length=50) # Draft, Approved, In Transit, Closed, Cancelled
    notes: Optional[str] = None
    is_active: Optional[bool] = None
    items: Optional[List[POLineItemCreate]] = None


class PurchaseOrderResponse(PurchaseOrderBase):
    po_id: int
    po_number: str
    total_amount_fob: float
    total_cbm: float
    total_gross_weight_kg: float
    total_net_weight_kg: float
    total_packages_count: int
    status: str
    is_active: bool
    created_at: datetime
    updated_at: datetime
    project_name: Optional[str] = None
    company_name: Optional[str] = None
    supplier_name: Optional[str] = None
    incoterm_code: Optional[str] = None
    currency_code: Optional[str] = None
    items: List[POLineItemResponse] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)
