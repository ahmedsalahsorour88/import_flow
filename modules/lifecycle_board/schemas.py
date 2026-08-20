"""
Pydantic Schemas for Shipment Stage Activity & Lifecycle Board
"""

from typing import List, Optional, Dict, Any
from pydantic import BaseModel, ConfigDict, Field


class StageStepInfo(BaseModel):
    step_code: str
    phase_id: int
    name_en: str
    name_ar: str
    action_url: str
    icon: str
    color: str


class StageActivityBase(BaseModel):
    import_file_code: str = Field(..., min_length=2, max_length=50)
    step_code: str = Field(..., min_length=2, max_length=50)
    status: str = Field("In-Progress", max_length=50)
    started_at: Optional[str] = None
    completed_at: Optional[str] = None
    assigned_user: Optional[str] = None
    action_data: Optional[str] = None
    notes: Optional[str] = None


class StageActivityCreate(StageActivityBase):
    pass


class StageActivityUpdate(BaseModel):
    status: Optional[str] = None
    completed_at: Optional[str] = None
    assigned_user: Optional[str] = None
    action_data: Optional[str] = None
    notes: Optional[str] = None


class StageActivityResponse(StageActivityBase):
    id: int
    model_config = ConfigDict(from_attributes=True)


class StepAdvancePayload(BaseModel):
    import_file_code: str
    current_step_code: str
    next_step_codes: List[str] = [] # Supports multi-target next steps
    notes: Optional[str] = None
    action_data: Optional[Dict[str, Any]] = None


class SkipStepPayload(BaseModel):
    import_file_code: str
    current_step_code: str
    skip_reason: str = Field(..., min_length=2, description="Reason for skipping the operational step")
    next_step_codes: List[str] = Field(default_factory=list, description="Next operational step codes to activate")


class MultiStageSetPayload(BaseModel):
    import_file_code: str
    active_step_codes: List[str]
    notes: Optional[str] = None


class ShipmentStageCard(BaseModel):
    import_file_code: str
    company_name: str
    supplier_name: str
    po_number: Optional[str] = None
    shipment_mode: str = "Sea FCL"
    incoterm_code: str = "FOB"
    priority: str = "High"
    estimated_cost: Optional[float] = 0.0
    estimated_cost_currency: Optional[str] = "USD"
    step_code: str
    step_name_en: str
    step_name_ar: str
    status: str
    started_at: Optional[str] = None
    notes: Optional[str] = None


class PhaseSummary(BaseModel):
    phase_id: int
    title_en: str
    title_ar: str
    color_hex: str
    step_codes: List[str]
    total_active_shipments: int
    step_counts: Dict[str, int]


class LifecycleBoardSummaryResponse(BaseModel):
    phases: List[PhaseSummary]
    total_active_files: int
    all_shipments: List[ShipmentStageCard]
