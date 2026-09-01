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
    previous_step_code: Optional[str] = None
    previous_step_name_en: Optional[str] = None
    previous_step_name_ar: Optional[str] = None
    next_step_code: Optional[str] = None
    next_step_name_en: Optional[str] = None
    next_step_name_ar: Optional[str] = None
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


class LiveLogisticsTrackingItem(BaseModel):
    import_file_id: int
    import_file_code: str
    company_name: str
    supplier_name: str
    po_number: Optional[str] = None
    shipment_mode: str = "Sea FCL"
    incoterm_code: str = "FOB"
    priority: str = "High"

    # Voyage & Vessel Logistics
    bl_number: Optional[str] = None
    carrier_name: Optional[str] = None
    vessel_name: Optional[str] = None
    pol_name: Optional[str] = None
    pod_name: Optional[str] = None
    etd: Optional[str] = None
    eta: Optional[str] = None
    eta_countdown_days: Optional[int] = None # Positive = Days remaining to arrival, Negative = Days in port
    arrival_status: str = "Pre-Shipment" # Pre-Shipment, In Transit, In Port / Clearing, Cleared

    # Demurrage & Detention Free Time Radar
    demurrage_tracking_code: Optional[str] = None
    demurrage_status: str = "No Active Session" # Safe, Warning, Critical, Overdue, No Active Session
    free_days_total: int = 14
    free_days_remaining: int = 14
    used_free_days: int = 0
    demurrage_risk_level: str = "Low" # Low, Medium, High, Critical
    accumulated_demurrage_fx: float = 0.0
    accumulated_demurrage_egp: float = 0.0

    # Regulatory Testing & Laboratory Samples
    sample_test_status: str = "Not Applicable" # Pending, Under Testing, Approved, Rejected, Exempted, Not Applicable
    regulatory_agency: Optional[str] = None # GOEIC, Food Safety, Radiation, NTRA
    lab_receipt_number: Optional[str] = None
    sample_result_countdown_days: Optional[int] = None

    # Smart Document Readiness
    doc_readiness_percent: float = 0.0 # 0.0 to 100.0%
    verified_documents_count: int = 0
    total_required_documents: int = 7
    missing_documents: List[str] = []

    # Overall Operational Health & Stage
    operational_health_score: str = "Optimal" # Optimal, Attention Needed, Critical Alert
    current_step_code: str = "STEP_01"
    current_step_name_ar: str = ""
    current_step_name_en: str = ""
    next_action: str = ""


class LiveLogisticsSummaryResponse(BaseModel):
    total_active_shipments: int
    in_transit_count: int
    in_port_count: int
    high_risk_demurrage_count: int
    under_sample_testing_count: int
    incomplete_documents_count: int
    items: List[LiveLogisticsTrackingItem]
