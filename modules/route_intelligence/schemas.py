"""
Route & Supplier Intelligence Engine Schemas (AI-ROUTE-006)
"""

from datetime import datetime, date
from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict


class ItemPriceHistory(BaseModel):
    item_code: str
    description_ar: str
    last_unit_price: float
    currency: str = "USD"
    last_po_date: Optional[date] = None
    last_po_code: Optional[str] = None


class RouteShippingMemory(BaseModel):
    last_ocean_freight_cost: float = 0.0
    freight_currency: str = "USD"
    last_shipping_line: str = "غير محدد"
    last_freight_forwarder: str = "غير محدد"
    last_pol: str = "غير محدد"
    last_pod: str = "غير محدد"
    last_free_days_granted: int = 14


class CustomsAndClearanceMemory(BaseModel):
    last_customs_rate_used: float = 0.0
    last_duty_payable_egp: float = 0.0
    last_vat_payable_egp: float = 0.0
    last_clearance_fees_egp: float = 0.0
    last_customs_broker_name: str = "غير محدد"
    last_inspection_agency: str = "غير محدد"
    last_clearance_days: int = 0


class OperationalNoteItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    note_id: int
    note_category: str
    note_text: str
    created_at: datetime
    created_by: str


class RouteOperationalNoteCreate(BaseModel):
    supplier_id: int
    route_name: Optional[str] = None
    note_category: Optional[str] = "General"
    note_text: str = Field(..., min_length=3, description="نص الملاحظة أو التنبيه التشغيلي")


class SupplierRouteIntelligenceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    supplier_id: int
    supplier_code: str
    company_name: str
    country: str
    total_completed_shipments: int
    items_price_history: List[ItemPriceHistory]
    shipping_memory: RouteShippingMemory
    customs_memory: CustomsAndClearanceMemory
    operational_notes: List[OperationalNoteItem]
    last_actual_lead_time_days: int
    lead_time_breakdown_ar: str
    advisory_recommendation_ar: str
