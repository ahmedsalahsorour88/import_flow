from datetime import date, datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field


class ShippingScenarioItemBase(BaseModel):
    provider_id: Optional[int] = None
    provider_name: str = Field(..., min_length=2, max_length=150)
    vessel_name: str = Field(..., min_length=2, max_length=150)
    voyage_number: Optional[str] = None
    sailing_date: date
    estimated_arrival_date: date
    expected_line_delay_days: int = Field(0, ge=0)
    is_excluded_from_average: bool = False
    is_recommended: bool = False
    is_selected: bool = False
    risk_level: str = "Low"
    notes: Optional[str] = None


class ShippingScenarioItemCreate(ShippingScenarioItemBase):
    pass


class ShippingScenarioItemUpdate(BaseModel):
    provider_id: Optional[int] = None
    provider_name: Optional[str] = None
    vessel_name: Optional[str] = None
    voyage_number: Optional[str] = None
    sailing_date: Optional[date] = None
    estimated_arrival_date: Optional[date] = None
    expected_line_delay_days: Optional[int] = None
    is_excluded_from_average: Optional[bool] = None
    is_recommended: Optional[bool] = None
    is_selected: Optional[bool] = None
    risk_level: Optional[str] = None
    notes: Optional[str] = None


class ShippingScenarioItemCalculated(ShippingScenarioItemBase):
    item_id: Optional[int] = None
    vessel_lead_time_days: int
    ready_for_shipping_days: int
    expected_total_days_to_warehouse: int
    expected_warehouse_arrival_date: date

    model_config = ConfigDict(from_attributes=True)


class ShippingEvaluationBase(BaseModel):
    title: Optional[str] = None
    cargo_ready_date: date
    port_of_loading_id: Optional[int] = None
    port_of_discharge_id: Optional[int] = None
    avg_form4_days: int = Field(5, ge=0)
    avg_clearance_days: int = Field(7, ge=0)
    import_file_id: Optional[int] = None
    po_id: Optional[int] = None
    project_id: Optional[int] = None
    notes: Optional[str] = None


class ShippingEvaluationCreate(ShippingEvaluationBase):
    items: List[ShippingScenarioItemCreate] = Field(default_factory=list)


class ShippingEvaluationUpdate(BaseModel):
    title: Optional[str] = None
    cargo_ready_date: Optional[date] = None
    port_of_loading_id: Optional[int] = None
    port_of_discharge_id: Optional[int] = None
    avg_form4_days: Optional[int] = None
    avg_clearance_days: Optional[int] = None
    import_file_id: Optional[int] = None
    po_id: Optional[int] = None
    project_id: Optional[int] = None
    notes: Optional[str] = None
    items: Optional[List[ShippingScenarioItemCreate]] = None


class ShippingEvaluationResponse(ShippingEvaluationBase):
    session_id: int
    session_code: str
    import_file_id: Optional[int] = None
    import_file_code: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    po_number: Optional[str] = None
    project_name: Optional[str] = None
    pol_name: Optional[str] = None
    pod_name: Optional[str] = None

    items: List[ShippingScenarioItemCalculated] = Field(default_factory=list)

    # Calculated summary metrics across all valid non-excluded scenarios
    avg_expected_transit_days: float = 0.0
    avg_expected_warehouse_arrival_date: Optional[date] = None
    earliest_arrival_scenario_provider: Optional[str] = None
    earliest_arrival_date: Optional[date] = None
    latest_arrival_scenario_provider: Optional[str] = None
    latest_arrival_date: Optional[date] = None
    recommended_scenario_provider: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
