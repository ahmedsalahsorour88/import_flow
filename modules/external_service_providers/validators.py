from fastapi import HTTPException
from sqlalchemy.orm import Session

from .repository import partner_name_exists

from .schemas import ExternalServiceProviderCreate


# ==================================================
# Validate External Service Provider
# ==================================================

def validate_provider(
    db: Session,
    provider_data: ExternalServiceProviderCreate
) -> None:

    # ==============================================
    # Partner Name must be unique within Partner Type
    # ==============================================

    if partner_name_exists(
        db,
        provider_data.partner_name,
        provider_data.partner_type
    ):

        raise HTTPException(
            status_code=400,
            detail=(
                "Partner Name already exists "
                "for this Partner Type."
            )
        )

    # ==============================================
    # Credit Limit
    # ==============================================

    if provider_data.credit_limit < 0:

        raise HTTPException(
            status_code=400,
            detail="Credit Limit cannot be less than zero."
        )

    # ==============================================
    # Partner Name
    # ==============================================

    if not provider_data.partner_name.strip():

        raise HTTPException(
            status_code=400,
            detail="Partner Name is required."
        )

    # ==============================================
    # Partner Type
    # ==============================================

    if not provider_data.partner_type.strip():

        raise HTTPException(
            status_code=400,
            detail="Partner Type is required."
        )