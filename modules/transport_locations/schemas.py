from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, ConfigDict


class TransportLocationBase(BaseModel):
    un_locode: str = Field(..., min_length=3, max_length=10, description="UN/LOCODE e.g. EGALY, EGCAI, CNSHA")
    location_name: str = Field(..., min_length=2, max_length=200)
    location_type: str = Field(..., min_length=2, max_length=50, description="Sea Port, Airport, Dry Port, Land Border, ICD, Rail Terminal")
    country: str = Field(..., min_length=2, max_length=100)
    city: str = Field(..., min_length=2, max_length=100)
    notes: Optional[str] = Field(None, max_length=500)


class TransportLocationCreate(TransportLocationBase):
    pass


class TransportLocationUpdate(BaseModel):
    location_name: Optional[str] = Field(None, min_length=2, max_length=200)
    location_type: Optional[str] = Field(None, min_length=2, max_length=50)
    country: Optional[str] = Field(None, min_length=2, max_length=100)
    city: Optional[str] = Field(None, min_length=2, max_length=100)
    notes: Optional[str] = Field(None, max_length=500)
    is_active: Optional[bool] = None


class TransportLocationResponse(TransportLocationBase):
    location_id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
