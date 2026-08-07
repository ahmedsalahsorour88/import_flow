from datetime import date
from datetime import datetime

from pydantic import BaseModel
from pydantic import ConfigDict
from pydantic import EmailStr


# ==========================================================
# Base Schema
# ==========================================================

class ImportCompanyBase(BaseModel):

    # ==========================
    # Company Information
    # ==========================

    importer_name: str
    address: str
    country: str
    foreign_exporter_registration_type: str | None = None

    # ==========================
    # Importer ID
    # ==========================

    importer_id: str
    importer_id_expiry: date

    # ==========================
    # VAT Registration
    # ==========================

    vat_id: str
    vat_id_expiry: date

    # ==========================
    # Commercial Registration
    # ==========================

    registration_number: str
    registration_expiry: date

    # ==========================
    # Contact Information
    # ==========================

    phone: str | None = None
    email: EmailStr | None = None

    # ==========================
    # Notes
    # ==========================

    notes: str | None = None


# ==========================================================
# Create Schema
# ==========================================================

class ImportCompanyCreate(ImportCompanyBase):

    created_by: str | None = None


# ==========================================================
# Update Schema
# ==========================================================

class ImportCompanyUpdate(BaseModel):

    importer_name: str | None = None
    address: str | None = None
    country: str | None = None

    foreign_exporter_registration_type: str | None = None

    importer_id: str | None = None
    importer_id_expiry: date | None = None

    vat_id: str | None = None
    vat_id_expiry: date | None = None

    registration_number: str | None = None
    registration_expiry: date | None = None

    phone: str | None = None
    email: EmailStr | None = None

    notes: str | None = None

    is_active: bool | None = None

    updated_by: str | None = None


# ==========================================================
# Response Schema
# ==========================================================

class ImportCompanyResponse(ImportCompanyBase):

    company_id: int

    importer_id_days_to_renew: int | None = None
    vat_id_days_to_renew: int | None = None
    registration_days_to_renew: int | None = None

    is_active: bool

    created_at: datetime
    updated_at: datetime

    created_by: str | None = None
    updated_by: str | None = None

    model_config = ConfigDict(
        from_attributes=True
    )