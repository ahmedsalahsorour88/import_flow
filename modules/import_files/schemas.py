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
    shipment_mode: str = Field("Sea FCL", description="Sea FCL, Sea LCL, Air, Land")
    incoterm_code: str = Field("FOB", description="FOB, CIF, CFR, etc.")
    priority: str = Field("High", description="Low, Medium, High, Critical")
    shipment_category: str = Field("New Purchase", description="New Purchase, Repair, Replacement, Sample")
    required_eta: Optional[date] = None
    file_opening_date: Optional[date] = Field(default_factory=date.today, description="تاريخ فتح الملف")
    selected_scenario: Optional[str] = Field(None, description="e.g. MSC Option")
    
    # Logistics & Freight RFQ Fields
    pickup_address: Optional[str] = Field(None, description="Pickup address for EXW shipment")
    port_of_loading: Optional[str] = Field(None, description="POL e.g. London Gateway, Shanghai Port, Jeddah")
    port_of_discharge: Optional[str] = Field("El Dekheila Port (non TMT)", description="POD e.g. El Dekheila Port")
    cargo_ready_date: Optional[date] = Field(None, description="Expected cargo ready date")
    target_free_days: Optional[int] = Field(21, description="Required demurrage/detention free time in days")
    service_type_preference: Optional[str] = Field("Direct", description="Direct, Transshipment, Any")
    shipping_instructions_notes: Optional[str] = Field(None, description="Special shipping instructions")

    acid_number: Optional[str] = Field(None, description="19-digit Nafeza ACID Number")
    acid_request_date: Optional[date] = None
    acid_issue_date: Optional[date] = None
    acid_expiry_date: Optional[date] = None
    acid_execution_days: Optional[int] = None
    is_customs_released: bool = Field(False, description="Shipment cleared and released from customs")
    customs_released_at: Optional[datetime] = None
    form4_no: Optional[str] = None
    form4_request_date: Optional[date] = None
    form4_received_date: Optional[date] = None
    form4_execution_days: Optional[int] = None
    swift_no: Optional[str] = None
    form46_no: Optional[str] = None
    estimated_cost: float = Field(0.0, ge=0.0, description="Estimated Landed/Import Cost")
    estimated_cost_currency: str = Field("USD", description="عملة التكلفة التقديرية")
    status: str = Field("Open", description="Open, In Progress, On Hold, Closed, Archived")
    owner: str = Field("Kamal", description="Operational Owner")
    notes: Optional[str] = None
    closure_reason: Optional[str] = Field(None, description="Reason for early closure or termination")
    closed_at_phase: Optional[str] = Field(None, description="Operational phase where closure occurred")


class CloseShipmentSubmit(BaseModel):
    closure_reason: str = Field(..., min_length=3, description="Reason for stopping/closing shipment")
    closed_at_phase: str = Field(..., description="Operational phase e.g. Phase 3 - Import Documentation")


class ReopenShipmentSubmit(BaseModel):
    reopen_reason: str = Field(..., min_length=3, description="Reason for reopening closed shipment")


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
    file_opening_date: Optional[date] = None
    selected_scenario: Optional[str] = None
    
    # Logistics & Freight RFQ Fields
    pickup_address: Optional[str] = None
    port_of_loading: Optional[str] = None
    port_of_discharge: Optional[str] = None
    cargo_ready_date: Optional[date] = None
    target_free_days: Optional[int] = None
    service_type_preference: Optional[str] = None
    shipping_instructions_notes: Optional[str] = None

    acid_number: Optional[str] = None
    acid_request_date: Optional[date] = None
    acid_issue_date: Optional[date] = None
    acid_expiry_date: Optional[date] = None
    acid_execution_days: Optional[int] = None
    is_customs_released: Optional[bool] = None
    customs_released_at: Optional[datetime] = None
    form4_no: Optional[str] = None
    form4_request_date: Optional[date] = None
    form4_received_date: Optional[date] = None
    form4_execution_days: Optional[int] = None
    swift_no: Optional[str] = None
    form46_no: Optional[str] = None
    estimated_cost: Optional[float] = None
    estimated_cost_currency: Optional[str] = None
    status: Optional[str] = None
    owner: Optional[str] = None
    notes: Optional[str] = None


class FreightRfqDataResponse(BaseModel):
    import_file_id: int
    import_file_code: str
    custom_file_number: Optional[str] = None
    company_name: str
    supplier_name: str
    incoterm_code: str
    commodity: str
    shipment_mode: str
    recommended_containers: str
    total_cbm: float
    gross_weight_kg: float
    net_weight_kg: float
    total_packages: int
    packages_breakdown: str
    pickup_address: str
    port_of_loading: str
    port_of_discharge: str
    cargo_ready_date: str
    target_free_days: int
    service_type: str
    special_requirements: str
    email_subject: str
    email_body_template: str
    whatsapp_text_template: str


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


class PaginatedImportFilesResponse(BaseModel):
    items: List[ImportFileResponse]
    total: int
    page: int
    page_size: int
    total_pages: int
