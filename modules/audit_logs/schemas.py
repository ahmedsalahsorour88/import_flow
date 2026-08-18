from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class AuditLogBase(BaseModel):
    entity_type: str
    entity_id: int
    entity_code: Optional[str] = None
    action: str
    changes_summary: Optional[str] = None
    old_values: Optional[str] = None
    new_values: Optional[str] = None
    performed_by: Optional[str] = "System Admin"


class AuditLogCreate(AuditLogBase):
    pass


class AuditLogResponse(AuditLogBase):
    log_id: int
    performed_at: datetime

    model_config = ConfigDict(from_attributes=True)
