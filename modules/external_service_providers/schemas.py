from datetime import datetime

from pydantic import BaseModel
from pydantic import ConfigDict
from pydantic import EmailStr
from pydantic import Field


# ==========================================================
# Base Schema
# ==========================================================

class ExternalServiceProviderBase(BaseModel):

    # ==========================
    # Company Information
    # ==========================

    partner_name: str

    partner_type: str


    # ==========================
    # Contact Information
    # ==========================

    contact_person: str | None = None

    phone: str | None = None

    mobile: str | None = None

    email: EmailStr | None = None

    address: str | None = None

    country: str | None = None


    # ==========================
    # Financial Information
    # ==========================

    payment_type: str | None = None

    credit_limit: float = Field(
        default=0,
        ge=0
    )


    # ==========================
    # Notes
    # ==========================

    notes: str | None = None


# ==========================================================
# Create Schema
# ==========================================================

class ExternalServiceProviderCreate(
    ExternalServiceProviderBase
):

    created_by: str | None = None


# ==========================================================
# Update Schema
# ==========================================================

class ExternalServiceProviderUpdate(
    BaseModel
):

    # ==========================
    # Company Information
    # ==========================

    partner_name: str | None = None

    partner_type: str | None = None


    # ==========================
    # Contact Information
    # ==========================

    contact_person: str | None = None

    phone: str | None = None

    mobile: str | None = None

    email: EmailStr | None = None

    address: str | None = None

    country: str | None = None


    # ==========================
    # Financial Information
    # ==========================

    payment_type: str | None = None

    credit_limit: float | None = Field(
        default=None,
        ge=0
    )


    # ==========================
    # Other
    # ==========================

    notes: str | None = None

    is_active: bool | None = None

    updated_by: str | None = None


# ==========================================================
# Response Schema
# ==========================================================

class ExternalServiceProviderResponse(
    ExternalServiceProviderBase
):

    # ==========================
    # Primary Key
    # ==========================

    provider_id: int

    partner_code: str | None = None


    # ==========================
    # Status
    # ==========================

    is_active: bool


    # ==========================
    # Audit Fields
    # ==========================

    created_at: datetime

    updated_at: datetime

    created_by: str | None = None

    updated_by: str | None = None


    model_config = ConfigDict(
        from_attributes=True
    )