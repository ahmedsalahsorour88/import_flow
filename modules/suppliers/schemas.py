from datetime import datetime

from pydantic import BaseModel
from pydantic import ConfigDict


# ==================================================
# Base Schema
# ==================================================

class SupplierBase(BaseModel):

    company_name: str

    # Supplier Classification

    supplier_type: str

    registration_type: str

    foreign_exporter_id: str

    foreign_exporter_country: str

    foreign_exporter_country_code: str

    address: str

    phone: str | None = None

    email: str | None = None

    website: str | None = None

    brands: str | None = None

    notes: str | None = None



# ==================================================
# Create Supplier
# ==================================================

class SupplierCreate(SupplierBase):

    created_by: str | None = None



# ==================================================
# Update Supplier
# ==================================================

class SupplierUpdate(BaseModel):

    company_name: str | None = None

    supplier_type: str | None = None

    registration_type: str | None = None

    foreign_exporter_id: str | None = None

    foreign_exporter_country: str | None = None

    foreign_exporter_country_code: str | None = None

    address: str | None = None

    phone: str | None = None

    email: str | None = None

    website: str | None = None

    brands: str | None = None

    notes: str | None = None

    is_active: bool | None = None

    updated_by: str | None = None



# ==================================================
# Response Schema
# ==================================================

class SupplierResponse(SupplierBase):

    supplier_id: int

    # Auto Generated Supplier Code
    supplier_code: str

    is_active: bool

    created_at: datetime

    updated_at: datetime | None = None

    created_by: str | None = None

    updated_by: str | None = None


    model_config = ConfigDict(
        from_attributes=True
    )