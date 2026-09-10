"""
Pydantic Schemas for Smart Shipment Experience Guide (KB-GUIDE-012)
"""
from typing import List, Optional, Dict, Any
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict


class GuideScopeCreate(BaseModel):
    scope_type: str = Field(..., description="Scope type: hs_code, product_category, destination_port, supplier, shipping_line")
    scope_value: str = Field(..., description="Scope matching value, e.g. '8520' or 'Alexandria'")


class GuideScopeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    scope_id: int
    guide_entry_id: int
    scope_type: str
    scope_value: str


class GuideEntryCreate(BaseModel):
    title: str = Field(..., min_length=2, max_length=255, description="Guide entry title")
    content: str = Field(..., min_length=3, description="Detailed guidance, alert, or instructions")
    entry_type: str = Field(default="alert", description="alert | required_document | task | info")
    severity: str = Field(default="info", description="info | warning | critical")
    created_by: str = Field(default="System", description="Staff username or department")
    scopes: List[GuideScopeCreate] = Field(default_factory=list, description="Target scopes for multi-condition matching")


class GuideEntryUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=2, max_length=255)
    content: Optional[str] = Field(None, min_length=3)
    entry_type: Optional[str] = None
    severity: Optional[str] = None
    is_active: Optional[bool] = None
    scopes: Optional[List[GuideScopeCreate]] = None


class GuideEntryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    entry_id: int
    title: str
    content: str
    entry_type: str
    severity: str
    created_by: str
    created_at: datetime
    updated_at: datetime
    is_active: bool
    scopes: List[GuideScopeResponse] = Field(default_factory=list)


class GuideMatchRequest(BaseModel):
    hs_code: Optional[str] = None
    product_category: Optional[str] = None
    destination_port: Optional[str] = None
    supplier: Optional[str] = None
    shipping_line: Optional[str] = None


class GuideMatchResponse(BaseModel):
    matched_entries: List[GuideEntryResponse] = Field(default_factory=list)
    has_critical_alert: bool = False
    has_warning_alert: bool = False
    mandatory_ports: List[str] = Field(default_factory=list)
    required_documents: List[str] = Field(default_factory=list)
    suggested_notes: List[str] = Field(default_factory=list)


class SmartReferenceCardResponse(BaseModel):
    import_file_id: int
    import_file_code: str
    custom_file_number: Optional[str] = None
    product_summary: Dict[str, Any]
    route_summary: Dict[str, Any]
    critical_dates: Dict[str, Any]
    document_status: Dict[str, Any]
    matched_guide_entries: List[GuideEntryResponse] = Field(default_factory=list)
    cost_summary: Dict[str, Any]
