from datetime import datetime
from typing import Any, List, Optional
from pydantic import BaseModel, ConfigDict, Field, model_validator


class CBMItemBase(BaseModel):
    package_type: str = Field(default="Carton", json_schema_extra={"example": "Carton"})
    quantity: int = Field(..., gt=0, json_schema_extra={"example": 10})
    length: float = Field(default=100.0, gt=0, json_schema_extra={"example": 120.0})
    width: float = Field(default=80.0, gt=0, json_schema_extra={"example": 80.0})
    height: float = Field(default=60.0, gt=0, json_schema_extra={"example": 100.0})
    unit: str = Field(default="cm", json_schema_extra={"example": "cm"})  # mm, cm, m
    gross_weight_per_unit_kg: float = Field(default=0.0, ge=0, json_schema_extra={"example": 25.0})
    is_stackable: bool = Field(default=True, json_schema_extra={"example": True})

    @model_validator(mode="before")
    @classmethod
    def populate_dimensions(cls, data: Any) -> Any:
        if isinstance(data, dict):
            if "length_cm" in data and ("length" not in data or not data["length"]):
                data["length"] = data["length_cm"]
            if "width_cm" in data and ("width" not in data or not data["width"]):
                data["width"] = data["width_cm"]
            if "height_cm" in data and ("height" not in data or not data["height"]):
                data["height"] = data["height_cm"]
        return data

    @property
    def length_cm(self) -> float:
        return self.length if self.unit == "cm" else (self.length / 10.0 if self.unit == "mm" else self.length * 100.0)

    @property
    def width_cm(self) -> float:
        return self.width if self.unit == "cm" else (self.width / 10.0 if self.unit == "mm" else self.width * 100.0)

    @property
    def height_cm(self) -> float:
        return self.height if self.unit == "cm" else (self.height / 10.0 if self.unit == "mm" else self.height * 100.0)


class CBMItemCreate(CBMItemBase):
    pass


class CBMItemResponse(BaseModel):
    item_id: int
    calc_id: int
    package_type: str
    quantity: int
    # DB stores dimensions in CM; optional raw fields for backwards compatibility
    length_cm: float
    width_cm: float
    height_cm: float
    # Virtual / optional raw fields (populated from compute, may be absent from DB rows)
    length: Optional[float] = None
    width: Optional[float] = None
    height: Optional[float] = None
    unit: Optional[str] = None
    gross_weight_per_unit_kg: float
    total_cbm: float
    volumetric_weight_kg: float
    total_gross_weight_kg: float
    is_stackable: bool = True

    model_config = ConfigDict(from_attributes=True)


class CBMCalculationBase(BaseModel):
    title: Optional[str] = Field(default=None, json_schema_extra={"example": "Solar Panels Batch Measurement"})
    shipment_mode: str = Field(default="air", json_schema_extra={"example": "air"})  # air, sea
    import_file_id: Optional[int] = None
    project_id: Optional[int] = None
    po_id: Optional[int] = None
    notes: Optional[str] = None
    is_stackable: Optional[bool] = Field(default=True, json_schema_extra={"example": True})


class CBMCalculationCreate(CBMCalculationBase):
    items: List[CBMItemCreate] = Field(..., min_length=1)


class CBMCalculationUpdate(BaseModel):
    title: Optional[str] = None
    import_file_id: Optional[int] = None
    project_id: Optional[int] = None
    po_id: Optional[int] = None
    notes: Optional[str] = None
    is_stackable: Optional[bool] = None
    items: Optional[List[CBMItemCreate]] = None


class CBMCalculationResponse(CBMCalculationBase):
    calc_id: int
    calc_code: str
    import_file_id: Optional[int] = None
    import_file_code: Optional[str] = None
    total_qty: int
    total_cbm: float
    total_gross_weight_kg: float
    total_volumetric_weight_kg: float
    air_chargeable_weight_kg: float
    recommended_shipping_method: Optional[str] = None
    recommended_container_type: Optional[str] = None
    recommended_container_count: int = 0
    smart_hybrid_containers: Optional[str] = None
    flat_only_containers: Optional[str] = None
    hybrid_savings_count: Optional[int] = 0
    is_stackable: Optional[bool] = True
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
    smart_hybrid_containers: Optional[str] = None
    flat_only_containers: Optional[str] = None
    hybrid_savings_count: Optional[int] = 0
    items: List[dict]


class LinkToPORequest(BaseModel):
    import_file_id: Optional[int] = None
    po_id: Optional[int] = None
    project_id: Optional[int] = None
