"""
Pydantic Schemas for Docs Customs Approval Hub (DCA-001)
"""

from typing import Optional, List, Any, Dict
from datetime import datetime, date
from pydantic import BaseModel, ConfigDict, Field


# --- Discrepancy Ticket Schemas ---

class DiscrepancyTicketBase(BaseModel):
    import_file_id: int
    approval_id: Optional[int] = None
    issue_category: str = Field(..., description="HS Code Mismatch, Weight Discrepancy, CBM Discrepancy, Value Mismatch, Missing ACID, Incoterm Conflict, Other")
    severity: str = Field("Major", description="Critical, Major, Minor")
    description: str
    expected_value: Optional[str] = None
    found_value: Optional[str] = None
    supplier_action_required: Optional[str] = None


class DiscrepancyTicketCreate(DiscrepancyTicketBase):
    pass


class DiscrepancyTicketUpdate(BaseModel):
    issue_category: Optional[str] = None
    severity: Optional[str] = None
    description: Optional[str] = None
    expected_value: Optional[str] = None
    found_value: Optional[str] = None
    supplier_action_required: Optional[str] = None
    supplier_response: Optional[str] = None
    status: Optional[str] = None


class DiscrepancyTicketResolve(BaseModel):
    supplier_response: str
    resolved_by: str = "Compliance Officer"
    new_status: str = "Resolved"  # Resolved, Waived, Closed


class DiscrepancyTicketResponse(BaseModel):
    ticket_id: int
    ticket_code: str
    approval_id: Optional[int] = None
    import_file_id: int
    import_file_code: Optional[str] = None
    issue_category: str
    severity: str
    description: str
    expected_value: Optional[str] = None
    found_value: Optional[str] = None
    supplier_action_required: Optional[str] = None
    supplier_response: Optional[str] = None
    status: str
    resolved_at: Optional[datetime] = None
    resolved_by: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# --- Customs Document Approval Schemas ---

class CustomsDocumentApprovalBase(BaseModel):
    import_file_id: int
    po_id: Optional[int] = None
    document_type: str = Field(..., description="Commercial Invoice, Packing List, Bill of Lading, Certificate of Origin, EUR.1, Inspection Cert, Form 4")
    document_reference_no: Optional[str] = None
    document_date: Optional[date] = None


class CustomsDocumentApprovalCreate(CustomsDocumentApprovalBase):
    pass


class CustomsDocumentApprovalUpdate(BaseModel):
    document_reference_no: Optional[str] = None
    document_date: Optional[date] = None
    commercial_status: Optional[str] = None
    commercial_notes: Optional[str] = None
    customs_status: Optional[str] = None
    customs_broker_name: Optional[str] = None
    customs_notes: Optional[str] = None
    overall_status: Optional[str] = None


class CommercialReviewPayload(BaseModel):
    reviewer_name: str
    status: str = Field(..., description="Approved, Rejected, Under Review")
    notes: Optional[str] = None


class CustomsBrokerReviewPayload(BaseModel):
    broker_name: str
    reviewer_name: str
    status: str = Field(..., description="Approved, Rejected, Conditionally Approved")
    notes: Optional[str] = None


class CustomsDocumentApprovalResponse(BaseModel):
    approval_id: int
    approval_code: str
    import_file_id: int
    import_file_code: Optional[str] = None
    po_id: Optional[int] = None
    document_type: str
    document_reference_no: Optional[str] = None
    document_date: Optional[date] = None

    commercial_status: str
    commercial_reviewed_by: Optional[str] = None
    commercial_reviewed_at: Optional[datetime] = None
    commercial_notes: Optional[str] = None

    customs_status: str
    customs_reviewed_by: Optional[str] = None
    customs_reviewed_at: Optional[datetime] = None
    customs_broker_name: Optional[str] = None
    customs_notes: Optional[str] = None

    overall_status: str
    cross_check_summary: Optional[Dict[str, Any]] = None

    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# --- Cross-Document Matrix Audit Schemas ---

class MatrixCheckItem(BaseModel):
    parameter: str
    status: str  # Match, Mismatch, Warning, Missing
    invoice_val: Optional[str] = None
    bl_val: Optional[str] = None
    packing_val: Optional[str] = None
    coo_val: Optional[str] = None
    acid_val: Optional[str] = None
    notes: Optional[str] = None


class CrossDocumentMatrixCheckResponse(BaseModel):
    import_file_id: int
    import_file_code: str
    overall_compliance: str  # Fully Compliant, Discrepancies Found, Critical Blocker
    total_checks: int
    passed_checks: int
    failed_checks: int
    checks: List[MatrixCheckItem]
    recommendations: List[str]
    open_tickets_count: int
