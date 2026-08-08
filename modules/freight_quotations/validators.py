"""
Freight Quotations Business Validators (BP-008)
"""

from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from modules.external_service_providers.model import ExternalServiceProvider


def validate_carrier_exists(db: Session, provider_id: int) -> ExternalServiceProvider:
    """
    Validates that carrier / freight provider ID exists in external_service_providers table.
    """
    provider = (
        db.query(ExternalServiceProvider)
        .filter(ExternalServiceProvider.provider_id == provider_id)
        .first()
    )
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Freight Carrier with ID '{provider_id}' not found.",
        )
    return provider


def validate_quotation_dates(crd_date, sailing_date, arrival_date) -> None:
    """
    Validates date sequence: sailing_date >= crd_date, arrival_date > sailing_date.
    """
    if sailing_date < crd_date:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Sailing date ({sailing_date}) cannot be before Cargo Ready Date ({crd_date}).",
        )

    if arrival_date <= sailing_date:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Estimated arrival date ({arrival_date}) must be after sailing date ({sailing_date}).",
        )
