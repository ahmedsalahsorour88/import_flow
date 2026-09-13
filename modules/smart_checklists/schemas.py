"""
Pydantic Schemas for Smart Import Checklist Engine
"""

from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict


class ChecklistItemBase(BaseModel):
    phase_code: str
    question_code: str
    question_title_ar: str
    description_ar: Optional[str] = None
    question_title_en: Optional[str] = None
    description_en: Optional[str] = None
    responsible_role: str
    is_mandatory: bool = True
    verification_type: str = "MANUAL"
    auto_check_source: Optional[str] = None
    status: str = "PENDING"
    verified_by: Optional[str] = None
    verified_at: Optional[datetime] = None
    notes: Optional[str] = None
    override_reason: Optional[str] = None
    action_route: Optional[str] = None


class ChecklistItemResponse(ChecklistItemBase):
    model_config = ConfigDict(from_attributes=True)

    item_id: int
    import_file_id: int
    import_file_code: Optional[str] = None
    is_active: bool = True
    created_at: datetime
    updated_at: datetime


class ChecklistSummaryResponse(BaseModel):
    import_file_id: int
    import_file_code: Optional[str] = None
    total_items: int
    passed_items: int
    pending_items: int
    waived_items: int
    mandatory_pending_items: int
    readiness_score_pct: int
    is_gate_blocked: bool
    blocking_questions: List[str]
    items: List[ChecklistItemResponse]


class ChecklistToggleRequest(BaseModel):
    status: str  # PASSED, PENDING, WAIVED
    notes: Optional[str] = None
    verified_by: Optional[str] = "Kamal"


class ChecklistOverrideRequest(BaseModel):
    reason: str
    authorized_by: Optional[str] = "Operations Manager"


class ChecklistAutoSyncResponse(BaseModel):
    import_file_id: int
    synced_items_count: int
    newly_passed_codes: List[str]
    readiness_score_pct: int
    is_gate_blocked: bool
    message: str


class GatekeeperStatusResponse(BaseModel):
    import_file_id: int
    current_phase: str
    target_phase: str
    can_advance: bool
    blocking_count: int
    blocking_questions: List[str]
    message: str
