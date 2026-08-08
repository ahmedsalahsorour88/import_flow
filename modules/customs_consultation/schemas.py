"""
Customs Consultation Pydantic Schemas (BP-009)
"""

from datetime import datetime, date
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field


class CustomsChecklistItemBase(BaseModel):
    document_type: str = Field(..., min_length=2, max_length=100)
    hs_code: Optional[str] = None
    is_required: bool = True
    is_blocking_shipment: bool = True
    responsible_party: str = "Customs Broker"
    status: str = "Pending"  # Pending, Received, Verified, Approved, Rejected
    received_date: Optional[date] = None
    verified_date: Optional[date] = None
    regulatory_agency: Optional[str] = None
    remarks: Optional[str] = None
    corrective_action_required: Optional[str] = None


class CustomsChecklistItemCreate(CustomsChecklistItemBase):
    pass


class CustomsChecklistItemResponse(CustomsChecklistItemBase):
    item_id: int
    consultation_id: int

    model_config = ConfigDict(from_attributes=True)


class CustomsConsultationBase(BaseModel):
    title: str = Field(..., min_length=2, max_length=200)
    broker_id: int
    broker_name: str
    broker_contact_person: Optional[str] = None
    po_id: Optional[int] = None
    project_id: Optional[int] = None
    overall_status: str = "Pending Review"  # Pending Review, In Progress, Action Required, Clearance Ready, Blocked
    estimated_duties_egp: float = 0.0
    notes: Optional[str] = None


class CustomsConsultationCreate(CustomsConsultationBase):
    checklist_items: List[CustomsChecklistItemCreate] = []


class CustomsConsultationUpdate(BaseModel):
    title: Optional[str] = None
    broker_id: Optional[int] = None
    broker_name: Optional[str] = None
    broker_contact_person: Optional[str] = None
    po_id: Optional[int] = None
    project_id: Optional[int] = None
    overall_status: Optional[str] = None
    estimated_duties_egp: Optional[float] = None
    notes: Optional[str] = None
    checklist_items: Optional[List[CustomsChecklistItemCreate]] = None


class CustomsConsultationResponse(CustomsConsultationBase):
    consultation_id: int
    consultation_code: str
    has_blocking_issues: bool
    readiness_percentage: float
    is_active: bool
    created_at: datetime
    updated_at: datetime
    checklist_items: List[CustomsChecklistItemResponse] = []
    
    # Computed metrics
    total_documents_count: int = 0
    approved_documents_count: int = 0
    blocking_issues_count: int = 0

    model_config = ConfigDict(from_attributes=True)
