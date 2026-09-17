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
    incoterm_code: Optional[str] = "FOB"
    expense_invoices: List[ExpenseInvoiceSchema] = []
    item_landed_costs: List[ItemLandedCostSchema] = []
    accountant_name: str = "Kamal"
    notes: Optional[str] = None

class FinancialSettlementUpdate(BaseModel):
    incoterm_code: Optional[str] = None
    expense_invoices: Optional[List[ExpenseInvoiceSchema]] = None
    item_landed_costs: Optional[List[ItemLandedCostSchema]] = None
    status: Optional[str] = None
    accountant_name: Optional[str] = None
    notes: Optional[str] = None

class FinancialSettlementResponse(BaseModel):
    settlement_id: int
    settlement_code: str
    import_file_id: int
    incoterm_code: str = "FOB"
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

class OdooJournalLineItem(BaseModel):
    account_code: str
    account_name: str
    partner_name: str
    label: str
    debit: float = 0.0
    credit: float = 0.0
    currency: str = "EGP"
    amount_currency: Optional[float] = None
    analytic_account: Optional[str] = None
    cost_category: str = "Goods"

class OdooJournalEntryResponse(BaseModel):
    settlement_id: int
    settlement_code: str
    import_file_code: str
    company_name: str
    supplier_name: str
    project_name: Optional[str] = None
    entry_date: str
    journal_name: str = "Miscellaneous Operations / Vendor Bills"
    reference: str
    total_debit: float
    total_credit: float
    is_balanced: bool
    difference: float = 0.0
    lines: List[OdooJournalLineItem] = []
    items_breakdown: List[Dict[str, Any]] = []

class OdooExportConfig(BaseModel):
    inventory_account_code: str = "110400"
    inventory_account_name: str = "بضاعة بالطريق - Goods in Transit (Landed Cost)"
    supplier_account_code: str = "210100"
    freight_account_code: str = "210200"
    customs_broker_account_code: str = "210300"
    transport_account_code: str = "210400"
    customs_authority_account_code: str = "210500"
    demurrage_account_code: str = "210600"
    price_adjustment_account_code: str = "210700"
    other_expenses_account_code: str = "210800"
    journal_code: str = "MISC"


# ==============================================================================
# PL-08: Estimated Landed Cost Simulation Schemas
# ==============================================================================
from datetime import date

class EstimatedLandedCostItemBreakdown(BaseModel):
    line_no: int
    item_code: str
    item_name: str
    hs_code: str
    qty: float
    unit_price_fc: float
    fob_total_fc: float
    fob_unit_egp: float
    fob_total_egp: float
    allocated_freight_egp: float = 0.0
    allocated_insurance_egp: float = 0.0
    allocated_customs_duty_egp: float = 0.0
    allocated_vat_egp: float = 0.0
    allocated_clearance_and_port_egp: float = 0.0
    allocated_inland_transport_egp: float = 0.0
    allocated_other_egp: float = 0.0
    total_expenses_allocated_egp: float = 0.0
    total_landed_cost_egp: float = 0.0
    unit_landed_cost_egp: float = 0.0
    unit_landed_cost_fc: float = 0.0
    markup_factor: float = 1.0
    markup_percent: float = 0.0

class EstimatedLandedCostExpenseItem(BaseModel):
    category: str
    description: str
    amount_fc: float = 0.0
    currency: str = "EGP"
    amount_egp: float = 0.0
    is_estimated: bool = True
    source: str = "Standard Estimate"
    allocation_rule: str = "Value-Based"

class EstimatedLandedCostSimulationRequest(BaseModel):
    exchange_rate_override: Optional[float] = None
    freight_amount_egp_override: Optional[float] = None
    insurance_amount_egp_override: Optional[float] = None
    clearance_fees_egp_override: Optional[float] = None
    inland_transport_egp_override: Optional[float] = None
    port_handling_egp_override: Optional[float] = None
    bank_fees_egp_override: Optional[float] = None
    other_expenses_egp_override: Optional[float] = None
    allocation_preference: str = Field("Value-Based", description="Value-Based, Weight-Based, Volume-Based")
    estimate_date: Optional[date] = None

class EstimatedLandedCostSimulationResponse(BaseModel):
    import_file_id: int
    import_file_code: str
    currency: str = "USD"
    exchange_rate: float
    incoterm: str = "FOB"
    total_fob_fc: float
    total_fob_egp: float
    total_freight_egp: float
    total_insurance_egp: float
    total_customs_and_taxes_egp: float
    total_clearance_and_port_egp: float
    total_inland_transport_egp: float
    total_other_expenses_egp: float
    total_expenses_egp: float
    total_landed_cost_egp: float
    total_landed_cost_fc: float
    average_markup_factor: float
    average_markup_percent: float
    expenses_breakdown: List[EstimatedLandedCostExpenseItem] = []
    items_breakdown: List[EstimatedLandedCostItemBreakdown] = []
    executive_summary_ar: str

