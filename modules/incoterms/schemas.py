from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, field_validator


# ==================================================
# Incoterm Schemas (MD-006)
# ==================================================

class IncotermCreate(BaseModel):
    incoterm_code: str
    incoterm_name: str
    version: str = "Incoterms 2020"
    description: Optional[str] = None

    @field_validator("incoterm_code")
    @classmethod
    def uppercase_code(cls, v: str) -> str:
        return v.strip().upper()


class IncotermUpdate(BaseModel):
    incoterm_name: Optional[str] = None
    version: Optional[str] = None
    description: Optional[str] = None


class IncotermResponse(BaseModel):
    incoterm_id: int
    incoterm_code: str
    incoterm_name: str
    version: str
    description: Optional[str]
    is_active: bool
    created_at: datetime
    updated_at: datetime
    created_by: Optional[str]
    updated_by: Optional[str]

    model_config = {"from_attributes": True}


# ==================================================
# Cost Item Schemas (MD-006A)
# ==================================================

VALID_COST_CATEGORIES = {"Freight", "Customs", "Port", "Bank", "Other"}


class CostItemCreate(BaseModel):
    cost_item_code: str
    cost_item_name: str
    cost_category: str
    description: Optional[str] = None

    @field_validator("cost_item_code")
    @classmethod
    def uppercase_code(cls, v: str) -> str:
        return v.strip().upper()

    @field_validator("cost_category")
    @classmethod
    def validate_category(cls, v: str) -> str:
        if v not in VALID_COST_CATEGORIES:
            raise ValueError(f"cost_category must be one of {VALID_COST_CATEGORIES}")
        return v


class CostItemUpdate(BaseModel):
    cost_item_name: Optional[str] = None
    cost_category: Optional[str] = None
    description: Optional[str] = None

    @field_validator("cost_category")
    @classmethod
    def validate_category(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in VALID_COST_CATEGORIES:
            raise ValueError(f"cost_category must be one of {VALID_COST_CATEGORIES}")
        return v


class CostItemResponse(BaseModel):
    cost_item_id: int
    cost_item_code: str
    cost_item_name: str
    cost_category: str
    description: Optional[str]
    is_active: bool
    created_at: datetime
    updated_at: datetime
    created_by: Optional[str]
    updated_by: Optional[str]

    model_config = {"from_attributes": True}


# ==================================================
# Incoterm Responsibility Schemas (MD-006B)
# ==================================================

VALID_RESPONSIBLE_PARTIES = {"Importer", "Exporter", "Shared"}


class IncotermResponsibilityCreate(BaseModel):
    incoterm_id: int
    cost_item_id: int
    responsible_party: str
    included_in_incoterm: bool = False
    notes: Optional[str] = None

    @field_validator("responsible_party")
    @classmethod
    def validate_party(cls, v: str) -> str:
        if v not in VALID_RESPONSIBLE_PARTIES:
            raise ValueError(f"responsible_party must be one of {VALID_RESPONSIBLE_PARTIES}")
        return v


class IncotermResponsibilityUpdate(BaseModel):
    responsible_party: Optional[str] = None
    included_in_incoterm: Optional[bool] = None
    notes: Optional[str] = None

    @field_validator("responsible_party")
    @classmethod
    def validate_party(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in VALID_RESPONSIBLE_PARTIES:
            raise ValueError(f"responsible_party must be one of {VALID_RESPONSIBLE_PARTIES}")
        return v


class IncotermResponsibilityResponse(BaseModel):
    responsibility_id: int
    incoterm_id: int
    cost_item_id: int
    responsible_party: str
    included_in_incoterm: bool
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime

    # Nested info for display
    incoterm_code: Optional[str] = None
    cost_item_name: Optional[str] = None
    cost_category: Optional[str] = None

    model_config = {"from_attributes": True}
