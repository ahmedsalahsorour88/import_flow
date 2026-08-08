from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field


class CBMItemBase(BaseModel):
    package_type: str = Field(default="Carton", example="Carton")
    quantity: int = Field(..., gt=0, example=10)
    length_cm: float = Field(..., gt=0, example=120.0)
    width_cm: float = Field(..., gt=0, example=80.0)
    height_cm: float = Field(..., gt=0, example=100.0)
    gross_weight_per_unit_kg: float = Field(..., gt=0, example=25.0)


class CBMItemCreate(CBMItemBase):
    pass


class CBMItemResponse(CBMItemBase):
    item_id: int
    calc_id: int
    total_cbm: float
    volumetric_weight_kg: float
    total_gross_weight_kg: float

    model_config = ConfigDict(from_attributes=True)


class CBMCalculationBase(BaseModel):
    title: Optional[str] = Field(default=None, example="Solar Panels Batch Measurement")
    project_id: Optional[int] = None
    po_id: Optional[int] = None
    notes: Optional[str] = None


class CBMCalculationCreate(CBMCalculationBase):
    items: List[CBMItemCreate] = Field(..., min_length=1)


class CBMCalculationUpdate(BaseModel):
    title: Optional[str] = None
    project_id: Optional[int] = None
    po_id: Optional[int] = None
    notes: Optional[str] = None
    items: Optional[List[CBMItemCreate]] = None


class CBMCalculationResponse(CBMCalculationBase):
    calc_id: int
    calc_code: str
    total_qty: int
    total_cbm: float
    total_gross_weight_kg: float
    total_volumetric_weight_kg: float
    air_chargeable_weight_kg: float
    recommended_shipping_method: Optional[str] = None
    recommended_container_type: Optional[str] = None
    recommended_container_count: int = 0
    is_active: bool
    created_at: datetime
    updated_at: datetime
    project_name: Optional[str] = None
    po_number: Optional[str] = None
    items: List[CBMItemResponse] = []

    model_config = ConfigDict(from_attributes=True)


class CBMQuickCalcRequest(BaseModel):
    items: List[CBMItemCreate] = Field(..., min_length=1)


class CBMQuickCalcResponse(BaseModel):
    total_qty: int
    total_cbm: float
    total_gross_weight_kg: float
    total_volumetric_weight_kg: float
    air_chargeable_weight_kg: float
    recommended_shipping_method: str
    recommended_container_type: str
    recommended_container_count: int
    items: List[dict]


class LinkToPORequest(BaseModel):
    po_id: Optional[int] = None
    project_id: Optional[int] = None
