from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field

class ContainerLoadingItem(BaseModel):
    container_no: str
    seal_no: str
    tare_weight_kg: float = 0.0
    net_weight_kg: float = 0.0
    gross_weight_kg: float = 0.0
    vgm_status: str = "Submitted"
    vgm_ref_no: Optional[str] = None

class CourierTrackingItem(BaseModel):
    courier_provider: str = "DHL Express"
    tracking_number: Optional[str] = None
    dispatch_date: Optional[str] = None
    receipt_status: str = "Dispatched" # Dispatched, Received at Office, Received at Bank
    received_at: Optional[str] = None
    received_by: Optional[str] = None

class CargoXVerificationRule(BaseModel):
    rule_name: str
    passed: bool = False
    details: Optional[str] = None

class CargoXExchangeItem(BaseModel):
    platform_provider: str = "CargoX Platform"
    envelope_id: Optional[str] = None
    envelope_status: str = "Created" # Created, Invited, Checklist Passed, Ready for Upload, Uploaded, Completed
    blockchain_tx_hash: Optional[str] = None
    verification_checklist: List[CargoXVerificationRule] = []

class CargoShippingCreate(BaseModel):
    import_file_id: int
    booking_id: Optional[int] = None
    crd_date: Optional[datetime] = None
    cargo_cutoff_date: Optional[datetime] = None
    containers_loading_data: List[ContainerLoadingItem] = []
    courier_tracking_data: Optional[CourierTrackingItem] = None
    cargox_exchange_data: Optional[CargoXExchangeItem] = None
    live_tracking_url: Optional[str] = None
    status: str = "Cargo Ready"
    owner: str = "Kamal"
    notes: Optional[str] = None

class DualApprovalLevel1Submit(BaseModel):
    approved_by: str
    approved: bool
    notes: Optional[str] = None

class DualApprovalLevel2Submit(BaseModel):
    approved_by: str
    approved: bool
    notes: Optional[str] = None

class CargoShippingUpdate(BaseModel):
    booking_id: Optional[int] = None
    crd_date: Optional[datetime] = None
    cargo_cutoff_date: Optional[datetime] = None
    containers_loading_data: Optional[List[ContainerLoadingItem]] = None
    courier_tracking_data: Optional[CourierTrackingItem] = None
    cargox_exchange_data: Optional[CargoXExchangeItem] = None
    live_tracking_url: Optional[str] = None
    status: Optional[str] = None
    owner: Optional[str] = None
    notes: Optional[str] = None

class CargoShippingResponse(BaseModel):
    cargo_shipping_id: int
    cargo_shipping_code: str
    import_file_id: int
    booking_id: Optional[int] = None
    crd_date: Optional[datetime] = None
    cargo_cutoff_date: Optional[datetime] = None
    is_crd_validated: bool
    containers_loading_data: List[Dict[str, Any]]
    level1_approval_status: str
    level1_approved_by: Optional[str] = None
    level1_approved_at: Optional[datetime] = None
    level1_notes: Optional[str] = None
    level2_approval_status: str
    level2_approved_by: Optional[str] = None
    level2_approved_at: Optional[datetime] = None
    level2_notes: Optional[str] = None
    dual_approval_status: str
    courier_tracking_data: Dict[str, Any]
    cargox_exchange_data: Dict[str, Any]
    live_tracking_url: Optional[str] = None
    status: str
    owner: str
    notes: Optional[str] = None
    is_active: bool
    created_at: datetime
    created_by: str
    updated_at: datetime
    updated_by: str

    model_config = ConfigDict(from_attributes=True)
