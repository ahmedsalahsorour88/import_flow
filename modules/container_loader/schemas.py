from typing import List, Optional
from pydantic import BaseModel, Field


class CargoPackageSchema(BaseModel):
    length: float = Field(..., gt=0, description="Package length")
    width: float = Field(..., gt=0, description="Package width")
    height: float = Field(..., gt=0, description="Package height")
    qty: int = Field(1, ge=1, description="Quantity of packages")
    weight_kg: float = Field(0.0, ge=0, description="Gross weight per unit in kg")
    stackable: bool = Field(False, description="Whether cargo is stackable vertically")
    unit: str = Field("mm", description="Unit of measurement: mm, cm, m")


class ContainerLoaderRequest(BaseModel):
    packages: List[CargoPackageSchema] = Field(..., min_length=1, description="List of cargo packages")
    is_stackable_override: Optional[bool] = Field(None, description="Global stackable override")


class ContainerOptionEvaluation(BaseModel):
    container_code: str
    container_name: str
    status: str  # FIT, OVERWEIGHT, DOOR_BLOCKED, DIMENSION_EXCEEDED, FLOOR_EXCEEDED, CEILING_TOO_TIGHT
    required_count: int
    total_cbm: float
    total_weight_kg: float
    floor_area_required_m2: float
    container_floor_area_m2: float
    volume_utilization_pct: float
    weight_utilization_pct: float
    floor_utilization_pct: float
    reasons: List[str]
    reasons_ar: List[str]


class ContainerLoaderEvaluationResult(BaseModel):
    recommended_container: str
    recommended_container_name: str
    recommended_count: int
    status: str
    total_cbm: float
    total_weight_kg: float
    is_stackable: bool
    floor_required: bool
    floor_utilization_pct: float
    volume_utilization_pct: float
    weight_utilization_pct: float
    reasons: List[str]
    reasons_ar: List[str]
    all_options: List[ContainerOptionEvaluation]
