from datetime import datetime, date
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, ConfigDict, Field


class CourierEntry(BaseModel):
    courier_no: str = Field(..., description="Courier Air Waybill / Tracking Number (e.g. DHL-981245)")
    courier_company: Optional[str] = Field("DHL", description="Courier Service Provider (DHL, FedEx, Aramex, UPS, Naqel, etc.)")
    dispatch_date: Optional[str] = Field(None, description="Courier dispatch date (YYYY-MM-DD)")
    is_received: bool = Field(False, description="Whether courier envelope package is physically delivered")
    received_date: Optional[str] = Field(None, description="Physical delivery / reception date (YYYY-MM-DD)")
    received_by: Optional[str] = Field(None, description="Staff member who received the courier envelope")
    notes: Optional[str] = Field(None, description="Courier specific notes")


class OriginalDocumentItem(BaseModel):
    category: str = Field("Commercial", description="Document category: Commercial, Certificate, Shipping, Egypt Import, Banking, Regulatory, Other")
    document_name: str = Field(..., description="Document Name (e.g. Commercial Invoice, Packing List, Certificate of Origin, etc.)")
    is_required: str = Field("Yes", description="'Yes', 'No', 'Conditional'")
    responsible_party: str = Field("Supplier", description="Responsible party: 'Supplier', 'Freight Forwarder', 'Inspection Agency', 'Bank', 'Importer'")
    courier_no: Optional[str] = Field(None, description="Assigned Courier Tracking / AWB Number")
    is_received: bool = Field(False, description="Physical hard-copy document received")
    received_date: Optional[str] = Field(None, description="Document receipt date (YYYY-MM-DD)")
    is_verified: bool = Field(False, description="Physical hard-copy verified & matched against electronic archive")
    verified_by: Optional[str] = Field(None, description="Auditor / customs specialist who verified the original document")
    verification_date: Optional[str] = Field(None, description="Document verification date (YYYY-MM-DD)")
    status: str = Field("Pending", description="'Pending', 'In Transit', 'Received', 'Verified', 'Discrepant', 'Not Required'")
    remarks: Optional[str] = Field(None, description="Specific notes or discrepancy remarks")


class OriginalDocumentsCollectionBase(BaseModel):
    import_file_id: int
    import_file_code: str
    acid_number: Optional[str] = None
    importer_name: Optional[str] = None
    supplier_name: Optional[str] = None
    status: str = "DRAFT"
    couriers_list: List[CourierEntry] = Field(default_factory=list)
    documents_list: List[OriginalDocumentItem] = Field(default_factory=list)
    discrepancy_override_reason: Optional[str] = None
    notes: Optional[str] = None


class OriginalDocumentsCollectionCreate(OriginalDocumentsCollectionBase):
    pass


class OriginalDocumentsCollectionUpdate(BaseModel):
    status: Optional[str] = None
    couriers_list: Optional[List[CourierEntry]] = None
    documents_list: Optional[List[OriginalDocumentItem]] = None
    discrepancy_override_reason: Optional[str] = None
    notes: Optional[str] = None


class OriginalDocumentsCollectionResponse(OriginalDocumentsCollectionBase):
    collection_id: int
    collection_code: str
    total_documents_count: int = 0
    received_documents_count: int = 0
    verified_documents_count: int = 0
    pending_documents_count: int = 0
    completion_percentage: float = 0.0
    is_active: bool = True
    created_at: datetime
    created_by: str
    updated_at: datetime
    updated_by: str

    model_config = ConfigDict(from_attributes=True)


class OriginalDocumentsAutoPopulateResponse(BaseModel):
    import_file_id: int
    import_file_code: str
    acid_number: Optional[str] = None
    importer_name: Optional[str] = None
    supplier_name: Optional[str] = None
    default_couriers: List[CourierEntry] = Field(default_factory=list)
    required_documents: List[OriginalDocumentItem] = Field(default_factory=list)
    existing_session: Optional[OriginalDocumentsCollectionResponse] = None
