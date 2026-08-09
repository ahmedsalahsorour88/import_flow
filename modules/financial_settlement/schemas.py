from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field

class ExpenseInvoiceSchema(BaseModel):
    invoice_no: str
    category: str = Field(..., description="Freight, Customs Duty, Brokerage, Local Transport, Storage, Insurance, Other")
    provider_name: str
    currency: str = "USD"
    amount_fx: float = Field(..., ge=0.0)
    exchange_rate: float = Field(..., gt=0.0)
    amount_egp: float = Field(0.0, ge=0.0)
    allocation_rule: str = Field("Value-Based", description="Value-Based, Weight-Based, Volume-Based, Equal")

class ItemLandedCostSchema(BaseModel):
    item_code: str
    item_name: str
    qty: int = Field(..., gt=0)
    gross_weight_kg: float = Field(0.0, ge=0.0)
    cbm: float = Field(0.0, ge=0.0)
    fob_unit_egp: float = Field(..., ge=0.0)
    fob_total_egp: float = Field(0.0, ge=0.0)
    allocated_freight_egp: float = 0.0
    allocated_customs_egp: float = 0.0
    allocated_clearance_egp: float = 0.0
    allocated_transport_egp: float = 0.0
    allocated_other_egp: float = 0.0
    total_landed_cost_egp: float = 0.0
    unit_landed_cost_egp: float = 0.0
    markup_factor: float = 1.0

class FinancialSettlementCreate(BaseModel):
    import_file_id: int
    expense_invoices: List[ExpenseInvoiceSchema] = []
    item_landed_costs: List[ItemLandedCostSchema] = []
    accountant_name: str = "Kamal"
    notes: Optional[str] = None

class FinancialSettlementUpdate(BaseModel):
    expense_invoices: Optional[List[ExpenseInvoiceSchema]] = None
    item_landed_costs: Optional[List[ItemLandedCostSchema]] = None
    status: Optional[str] = None
    accountant_name: Optional[str] = None
    notes: Optional[str] = None

class FinancialSettlementResponse(BaseModel):
    settlement_id: int
    settlement_code: str
    import_file_id: int
    expense_invoices: List[Dict[str, Any]]
    total_fob_egp: float
    total_expenses_egp: float
    total_landed_cost_egp: float
    average_markup_factor: float
    item_landed_costs: List[Dict[str, Any]]
    status: str
    accountant_name: str
    notes: Optional[str] = None
    is_active: bool
    created_at: datetime
    created_by: str
    updated_at: datetime
    updated_by: str

    model_config = ConfigDict(from_attributes=True)
