"""
Pydantic Schemas for Import Files Master & Tracking Module
"""

from typing import List, Optional, Any, Dict
from datetime import date, datetime
from pydantic import BaseModel, Field


from pydantic import BaseModel, Field, ConfigDict

class InvoiceItemSchema(BaseModel):
    invoice_no: str = Field(..., description="Invoice Number e.g. PI-889")
    invoice_type: str = Field("Proforma Invoice", description="Proforma or Commercial Invoice")
    date: Optional[str] = None
    amount: float = Field(0.0, ge=0.0)
    currency: str = Field("USD")


class PackingListItemSchema(BaseModel):
    pl_no: str = Field(..., description="Packing List Number e.g. PL-889")
    date: Optional[str] = None
    total_packages: int = Field(0, ge=0)
    gross_weight_kg: float = Field(0.0, ge=0.0)
    cbm: float = Field(0.0, ge=0.0)


class ImportFileBase(BaseModel):
    custom_file_number: Optional[str] = Field(None, description="Custom File ID e.g. 6701068100")
    company_id: Optional[int] = None
    company_name: str = Field(..., min_length=2, description="Importing Company Name")
    supplier_id: Optional[int] = None
    supplier_name: str = Field(..., min_length=2, description="Foreign Supplier Name")
    broker_id: Optional[int] = None
    broker_name: Optional[str] = Field(None, description="Customs Broker Name")
    po_number: Optional[str] = Field(None, description="PO Number e.g. PO-1001")
    po_ids: Optional[List[int]] = None
    pi_number: Optional[str] = Field(None, description="Main PI Number e.g. PI-889")
    invoices_data: Optional[List[Dict[str, Any]]] = Field(default_factory=list, description="Multiple Invoices")
    packing_lists_data: Optional[List[Dict[str, Any]]] = Field(default_factory=list, description="Multiple Packing Lists")
    project_ids: Optional[List[int]] = Field(default_factory=list, description="List of linked Project IDs")
    project_names: Optional[str] = None
    shipment_mode: str = Field("Sea", description="Sea, Air, Land")
    incoterm_code: str = Field("FOB", description="FOB, CIF, CFR, etc.")
    priority: str = Field("High", description="Low, Medium, High, Critical")
    shipment_category: str = Field("New Purchase", description="New Purchase, Repair, Replacement, Sample")
    required_eta: Optional[date] = None
    selected_scenario: Optional[str] = Field(None, description="e.g. MSC Option")
    form4_no: Optional[str] = None
    swift_no: Optional[str] = None
    form46_no: Optional[str] = None
    estimated_cost: float = Field(0.0, ge=0.0, description="Estimated Landed/Import Cost")
    status: str = Field("Open", description="Open, In Progress, On Hold, Closed, Archived")
    owner: str = Field("Kamal", description="Operational Owner")
    notes: Optional[str] = None
    closure_reason: Optional[str] = Field(None, description="Reason for early closure or termination")
    closed_at_phase: Optional[str] = Field(None, description="Operational phase where closure occurred")


class CloseShipmentSubmit(BaseModel):
    closure_reason: str = Field(..., min_length=3, description="Reason for stopping/closing shipment")
    closed_at_phase: str = Field(..., description="Operational phase e.g. Phase 3 - Import Documentation")


class ImportFileCreate(ImportFileBase):
    pass


class ImportFileUpdate(BaseModel):
    custom_file_number: Optional[str] = None
    company_id: Optional[int] = None
    company_name: Optional[str] = None
    supplier_id: Optional[int] = None
    supplier_name: Optional[str] = None
    broker_id: Optional[int] = None
    broker_name: Optional[str] = None
    po_number: Optional[str] = None
    po_ids: Optional[List[int]] = None
    pi_number: Optional[str] = None
    invoices_data: Optional[List[Dict[str, Any]]] = None
    packing_lists_data: Optional[List[Dict[str, Any]]] = None
    project_ids: Optional[List[int]] = None
    project_names: Optional[str] = None
    shipment_mode: Optional[str] = None
    incoterm_code: Optional[str] = None
    priority: Optional[str] = None
    shipment_category: Optional[str] = None
    required_eta: Optional[date] = None
    selected_scenario: Optional[str] = None
    form4_no: Optional[str] = None
    swift_no: Optional[str] = None
    form46_no: Optional[str] = None
    estimated_cost: Optional[float] = None
    status: Optional[str] = None
    owner: Optional[str] = None
    notes: Optional[str] = None


class ImportFileResponse(ImportFileBase):
    model_config = ConfigDict(from_attributes=True)

    import_file_id: int
    import_file_code: str
    current_module: str
    current_stage: str
    progress_percent: float
    next_action: str
    is_active: bool
    created_at: datetime
    created_by: str
    updated_at: datetime
    updated_by: str


class ImportMasterReportSummary(BaseModel):
    total_import_files: int
    open_files_count: int
    in_progress_count: int
    closed_files_count: int
    total_estimated_cost: float
    files: List[ImportFileResponse]


class OperationalDashboardBroker(BaseModel):
    broker_id: Optional[int] = None
    broker_name: str


class OperationalDashboardResponse(BaseModel):
    shipment_count: int
    shipments: List[ImportFileResponse]
    last_updated_at: datetime
    available_brokers: List[OperationalDashboardBroker]
    phase_counts: Dict[str, int]

