"""
Pydantic Schemas for Shipment Update Engine & Daily Log
"""

from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class ShipmentUpdateLogBase(BaseModel):
    import_file_id: int
    import_file_code: str
    update_category: str = Field("Follow-up & Notes", description="Follow-up & Notes, Phase Cost Adjustment, Future Phase Alert, Daily Check-in")
    target_phase: str = Field(..., description="Target phase e.g. Phase 3")
    phase_status: str = Field("Current", description="Completed, Current, Future")
    log_date: str = Field(..., description="Date YYYY-MM-DD")
    note: str = Field(..., min_length=2, description="Update notes")
    adjusted_cost_item: Optional[str] = None
    previous_cost: Optional[float] = 0.0
    new_cost: Optional[float] = 0.0
    alert_priority: str = Field("Normal", description="Normal, High, Critical")
    assigned_user: str = Field("Kamal", description="User name")


class ShipmentUpdateLogCreate(ShipmentUpdateLogBase):
    pass


class ShipmentUpdateLogUpdate(BaseModel):
    note: Optional[str] = None
    log_date: Optional[str] = None
    adjusted_cost_item: Optional[str] = None
    previous_cost: Optional[float] = None
    new_cost: Optional[float] = None
    alert_priority: Optional[str] = None
    assigned_user: Optional[str] = None


class ShipmentUpdateLogResponse(ShipmentUpdateLogBase):
    update_id: int
    update_code: str
    is_active: bool
    created_at: datetime
    created_by: str
    updated_at: datetime
    updated_by: str

    model_config = ConfigDict(from_attributes=True)


class PhaseStatusInspection(BaseModel):
    phase_code: str
    phase_name: str
    phase_number: int
    status: str  # Completed, Current, Future
    completion_date: Optional[str] = None
    last_note: Optional[str] = None
    update_count: int = 0
