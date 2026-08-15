from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field


class ContainerAllocationItem(BaseModel):
    container_type: str = Field(..., description="e.g. 20GP, 40HC, 45HC")
    quantity: int = Field(default=1, ge=1)
    container_numbers: Optional[List[str]] = Field(default_factory=list)
    seal_numbers: Optional[List[str]] = Field(default_factory=list)
    vgm_weight_kg: Optional[float] = Field(default=0.0)


class BookingChargeItem(BaseModel):
    charge_type: str = Field(..., description="e.g. Sea Freight, THC, VGM Fee, BL Fee, EUR1")
    unit: str = Field(default="Per Container", description="Per Container or Per Shipment")
    quantity: int = Field(default=1, ge=1)
    currency: str = Field(default="USD")
    rate: float = Field(default=0.0, ge=0.0)
    total: float = Field(default=0.0, ge=0.0)


class ShipmentBookingBase(BaseModel):
    booking_confirmation_no: Optional[str] = None
    import_file_id: Optional[int] = None
    rfq_request_id: Optional[int] = None
    scenario_session_id: Optional[int] = None
    scenario_item_id: Optional[int] = None
    scenario_provider_name: Optional[str] = None
    freight_forwarder_id: Optional[int] = None
    freight_forwarder_name: Optional[str] = None
    shipping_line_id: Optional[int] = None
    shipping_line_name: Optional[str] = None
    shipment_type: str = "Ocean FCL"
    pol_location_id: Optional[int] = None
    pol_name: Optional[str] = None
    pod_location_id: Optional[int] = None
    pod_name: Optional[str] = None
    etd: Optional[datetime] = None
    eta: Optional[datetime] = None
    atd: Optional[datetime] = None
    departure_delay_days: Optional[int] = 0
    expected_warehouse_days: Optional[int] = 7
    expected_warehouse_arrival_date: Optional[datetime] = None
    free_demurrage_days: int = 14
    cargo_cutoff_date: Optional[datetime] = None
    si_cutoff_date: Optional[datetime] = None
    vessel_name: Optional[str] = None
    voyage_number: Optional[str] = None
    container_release_order_no: Optional[str] = None
    freight_terms: str = "Collect"
    container_mismatch_reason: Optional[str] = None
    containers_data: List[ContainerAllocationItem] = Field(default_factory=list)
    cost_charges_data: List[BookingChargeItem] = Field(default_factory=list)
    quotation_details_data: Optional[dict] = Field(default_factory=dict)
    status: str = "Draft"
    owner: str = "Kamal"
    notes: Optional[str] = None


class ShipmentBookingCreate(ShipmentBookingBase):
    pass


class ShipmentBookingUpdate(BaseModel):
    booking_confirmation_no: Optional[str] = None
    scenario_session_id: Optional[int] = None
    scenario_item_id: Optional[int] = None
    scenario_provider_name: Optional[str] = None
    freight_forwarder_name: Optional[str] = None
    shipping_line_name: Optional[str] = None
    shipment_type: Optional[str] = None
    pol_name: Optional[str] = None
    pod_name: Optional[str] = None
    etd: Optional[datetime] = None
    eta: Optional[datetime] = None
    atd: Optional[datetime] = None
    departure_delay_days: Optional[int] = None
    expected_warehouse_days: Optional[int] = None
    expected_warehouse_arrival_date: Optional[datetime] = None
    free_demurrage_days: Optional[int] = None
    cargo_cutoff_date: Optional[datetime] = None
    si_cutoff_date: Optional[datetime] = None
    vessel_name: Optional[str] = None
    voyage_number: Optional[str] = None
    container_release_order_no: Optional[str] = None
    freight_terms: Optional[str] = None
    container_mismatch_reason: Optional[str] = None
    containers_data: Optional[List[ContainerAllocationItem]] = None
    cost_charges_data: Optional[List[BookingChargeItem]] = None
    quotation_details_data: Optional[dict] = None
    status: Optional[str] = None
    owner: Optional[str] = None
    notes: Optional[str] = None


class ShipmentBookingResponse(ShipmentBookingBase):
    booking_id: int
    booking_code: str
    booking_request_date: Optional[datetime] = None
    booking_confirmation_date: Optional[datetime] = None
    transit_time_days: int = 0
    total_freight_cost_usd: float = 0.0
    is_active: bool = True
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
