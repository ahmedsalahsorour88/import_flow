from typing import Optional, Dict, Any
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field

class ClosureChecklistSchema(BaseModel):
    docs_verified: bool = True
    customs_cleared: bool = True
    warehouse_received: bool = True
    landed_cost_settled: bool = True
    tasks_closed: bool = True

class FileClosureCreate(BaseModel):
    import_file_id: int
    closure_checklist: ClosureChecklistSchema = Field(default_factory=ClosureChecklistSchema)
    auditor_name: str = "Internal Auditor"
    archive_location: str = "Digital Archive Vault - 2026"
    archival_notes: Optional[str] = None

class FileClosureUpdate(BaseModel):
    closure_checklist: Optional[ClosureChecklistSchema] = None
    auditor_name: Optional[str] = None
    archive_location: Optional[str] = None
    archival_notes: Optional[str] = None
    status: Optional[str] = None

class FileClosureResponse(BaseModel):
    closure_id: int
    closure_code: str
    import_file_id: int
    closure_checklist: Dict[str, bool]
    auditor_name: str
    archive_location: str
    archival_notes: Optional[str] = None
    status: str
    is_active: bool
    closed_at: datetime
    created_at: datetime
    created_by: str
    updated_at: datetime
    updated_by: str

    model_config = ConfigDict(from_attributes=True)
