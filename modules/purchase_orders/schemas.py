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


# ==================================================
# BP-003 Packing List Schemas
# ==================================================

class PackingListItemBase(BaseModel):
    hs_code: str = Field(..., min_length=2, max_length=50)
    item_code: str = Field(..., min_length=1, max_length=50)
    qty_pcs: float = Field(1.0, gt=0)
    qty_pkg: float = Field(1.0, gt=0)
    package_type: Optional[str] = Field("Carton", max_length=50)
    unit: Optional[str] = Field("cm", max_length=10)
    length_cm: Optional[float] = Field(0.0, ge=0)
    width_cm: Optional[float] = Field(0.0, ge=0)
    height_cm: Optional[float] = Field(0.0, ge=0)
    net_weight_unit_kg: float = Field(0.0, ge=0)
    gross_weight_unit_kg: float = Field(0.0, ge=0)


class PackingListItemCreate(PackingListItemBase):
    pass


class PackingListItemResponse(PackingListItemBase):
    packing_item_id: int
    po_id: int
    total_net_weight_kg: float
    total_gross_weight_kg: float
    total_cbm: float
    chargeable_weight_kg: float
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PackingListSummaryByHSCode(BaseModel):
    hs_code: str
    qty_pcs: float
    qty_pkg: float
    total_net_weight_kg: float
    total_gross_weight_kg: float
    total_cbm: float


class PackingListValidationReport(BaseModel):
    is_valid: bool
    errors: List[str] = Field(default_factory=list)
    warnings: List[str] = Field(default_factory=list)
    total_items: int = 0
    total_pcs: float = 0.0
    total_pkg: float = 0.0
    total_net_weight_kg: float = 0.0
    total_gross_weight_kg: float = 0.0
    total_cbm: float = 0.0
    chargeable_weight_kg: float = 0.0
    hs_code_summary: List[PackingListSummaryByHSCode] = Field(default_factory=list)


# ==================================================
# Purchase Order Schemas
# ==================================================

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
    packing_list_items: List[PackingListItemCreate] = Field(default_factory=list)


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
    packing_list_items: Optional[List[PackingListItemCreate]] = None


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
    packing_list_items: List[PackingListItemResponse] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)

