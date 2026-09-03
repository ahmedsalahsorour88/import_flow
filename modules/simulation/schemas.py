"""
Pydantic Schemas for Logistics What-If Simulator & FX Exposure Radar
"""

from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class WhatIfSimulationRequest(BaseModel):
    import_file_id: Optional[int] = Field(None, description="Optional Import File ID to pull actual baseline data")
    invoice_amount: Optional[float] = Field(0.0, description="Invoice amount in Foreign Currency")
    currency: Optional[str] = Field("USD", description="Currency code (USD, EUR, CNY, etc.)")
    base_exchange_rate: Optional[float] = Field(None, description="Current baseline exchange rate to EGP")
    exchange_rate_change_pct: float = Field(0.0, description="Percentage change in FX rate (-50% to +200%)")
    freight_fcy: Optional[float] = Field(0.0, description="Freight cost in Foreign Currency (e.g. USD)")
    insurance_fcy: Optional[float] = Field(0.0, description="Insurance cost in Foreign Currency")
    shipping_route: str = Field("RED_SEA", description="RED_SEA or CAPE_OF_GOOD_HOPE")
    custom_transit_days: Optional[int] = Field(0, description="Additional maritime transit days")
    port_storage_delay_days: int = Field(0, description="Additional days delayed in port before release")
    container_count: int = Field(1, description="Number of containers")
    container_type: Optional[str] = Field("40HC", description="20GP, 40GP, 40HC")
    duty_rate_pct: Optional[float] = Field(5.0, description="Customs Import Duty %")
    vat_rate_pct: Optional[float] = Field(14.0, description="VAT %")
    schedule_tax_pct: Optional[float] = Field(0.0, description="Schedule Tax %")
    acid_issuance_date: Optional[str] = Field(None, description="ACID 19-digit issuance date YYYY-MM-DD")
    current_eta: Optional[str] = Field(None, description="Current Estimated Time of Arrival YYYY-MM-DD")


class WhatIfSimulationResponse(BaseModel):
    baseline_summary: Dict[str, Any]
    simulated_summary: Dict[str, Any]
    variances: Dict[str, Any]
    customs_breakdown: Dict[str, Any]
    demurrage_and_storage: Dict[str, Any]
    acid_risk_analysis: Dict[str, Any]
    risk_level: str  # LOW, MEDIUM, HIGH, CRITICAL
    risk_score: float  # 0 to 100
    hedging_recommendations: List[str]


class FXExposureItem(BaseModel):
    import_file_id: int
    import_file_code: str
    supplier_name: str
    currency: str
    total_invoice_fcy: float
    paid_fcy: float
    open_exposure_fcy: float
    official_rate_egp: float
    open_exposure_egp: float
    simulated_exposure_egp_at_plus_10_pct: float
    simulated_exposure_egp_at_plus_25_pct: float


class FXExposureSummaryResponse(BaseModel):
    total_open_usd: float
    total_open_eur: float
    total_open_cny: float
    total_open_egp_baseline: float
    total_open_egp_plus_10_pct: float
    total_open_egp_plus_25_pct: float
    var_at_risk_10_pct: float
    items: List[FXExposureItem]
    strategic_advice: List[str]


class SavedScenarioCreate(BaseModel):
    scenario_name: str
    import_file_id: Optional[int] = None
    simulation_request: WhatIfSimulationRequest
    simulation_result: Dict[str, Any]


class SavedScenarioResponse(BaseModel):
    scenario_id: int
    scenario_name: str
    import_file_id: Optional[int] = None
    base_currency: str
    base_exchange_rate: float
    simulated_exchange_rate: float
    rate_change_pct: float
    shipping_route: str
    transit_delay_days: int
    port_storage_delay_days: int
    baseline_landed_cost: float
    simulated_landed_cost: float
    cost_variance_amount: float
    cost_variance_pct: float
    acid_risk_status: str
    risk_level: str
    recommendations: Optional[List[str]] = None
    created_at: str
    created_by: str
