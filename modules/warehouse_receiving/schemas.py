from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field

class GrnItemSchema(BaseModel):
    item_code: str
    item_name: str
    invoiced_qty: int = Field(0, ge=0)
    accepted_qty: int = Field(0, ge=0)
    shortage_qty: int = Field(0, ge=0)
    damaged_qty: int = Field(0, ge=0)
    quarantine_flag: bool = False

class WarehouseReceivingCreate(BaseModel):
    import_file_id: int
    warehouse_name: str = "Main Warehouse - Cairo"
    arrival_datetime: Optional[datetime] = None
    truck_plate_number: Optional[str] = None
    driver_name: Optional[str] = None
    driver_phone: Optional[str] = None
    seal_number: Optional[str] = None
    seal_intact: bool = True
    grn_items: List[GrnItemSchema] = []
    discrepancy_notes: Optional[str] = None
    inspector_name: str = "Kamal"
    notes: Optional[str] = None

class DiscrepancyReportSubmit(BaseModel):
    discrepancy_type: str = Field(..., description="Shortage, Damage, Excess, Wrong Item")
    discrepancy_notes: str
    quarantine_zone_assigned: bool = True
    insurance_claim_filed: bool = False
    insurance_claim_ref: Optional[str] = None

class WarehouseReceivingUpdate(BaseModel):
    warehouse_name: Optional[str] = None
    truck_plate_number: Optional[str] = None
    driver_name: Optional[str] = None
    seal_intact: Optional[bool] = None
    grn_items: Optional[List[GrnItemSchema]] = None
    discrepancy_type: Optional[str] = None
    discrepancy_notes: Optional[str] = None
    status: Optional[str] = None
    inspector_name: Optional[str] = None
    notes: Optional[str] = None

class WarehouseReceivingResponse(BaseModel):
    receiving_id: int
    grn_code: str
    import_file_id: int
    warehouse_name: str
    arrival_datetime: datetime
    truck_plate_number: Optional[str] = None
    driver_name: Optional[str] = None
    driver_phone: Optional[str] = None
    seal_number: Optional[str] = None
    seal_intact: bool
    grn_items: List[Dict[str, Any]]
    total_invoiced_qty: int
    total_accepted_qty: int
    total_shortage_qty: int
    total_damaged_qty: int
    discrepancy_type: str
    discrepancy_notes: Optional[str] = None
    quarantine_zone_assigned: bool
    insurance_claim_filed: bool
    insurance_claim_ref: Optional[str] = None
    is_under_bond_quarantine: bool = False
    quarantine_lock_active: bool = False
    dispatch_blocked: bool = False
    status: str
    inspector_name: str
    notes: Optional[str] = None
    is_active: bool
    created_at: datetime
    created_by: str
    updated_at: datetime
    updated_by: str

    model_config = ConfigDict(from_attributes=True)


class WarehouseDispatchValidationResponse(BaseModel):
    receiving_id: int
    grn_code: str
    is_dispatch_allowed: bool
    status: str
    message: str

