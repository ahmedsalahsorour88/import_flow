from sqlalchemy.orm import Session

from .model import ExternalServiceProvider

from .repository import create_provider
from .repository import get_providers
from .repository import get_provider_by_id
from .repository import update_provider
from .repository import delete_provider
from .repository import restore_provider

from .schemas import ExternalServiceProviderCreate
from .schemas import ExternalServiceProviderUpdate

from .validators import validate_provider


# ==================================================
# Create Provider
# ==================================================

def create_external_service_provider(
    db: Session,
    provider_data: ExternalServiceProviderCreate
) -> ExternalServiceProvider:

    validate_provider(
        db,
        provider_data
    )

    return create_provider(
        db,
        provider_data
    )


# ==================================================
# Get Active Providers
# ==================================================

def get_all_providers(
    db: Session
) -> list[ExternalServiceProvider]:

    return get_providers(
        db
    )


# ==================================================
# Get Provider By ID
# ==================================================

def get_provider(
    db: Session,
    provider_id: int
) -> ExternalServiceProvider | None:

    return get_provider_by_id(
        db,
        provider_id
    )


# ==================================================
# Update Provider
# ==================================================

def update_external_service_provider(
    db: Session,
    provider_id: int,
    provider_data: ExternalServiceProviderUpdate
) -> ExternalServiceProvider | None:

    provider = get_provider_by_id(
        db,
        provider_id
    )

    if not provider:

        return None

    update_data = provider_data.model_dump(
        exclude_unset=True,
        exclude_none=True
    )

    for field, value in update_data.items():

        if field == "email":

            value = str(value)

        setattr(
            provider,
            field,
            value
        )

    return update_provider(
        db,
        provider
    )


# ==================================================
# Soft Delete Provider
# ==================================================

def delete_external_service_provider(
    db: Session,
    provider_id: int
) -> ExternalServiceProvider | None:

    provider = get_provider_by_id(
        db,
        provider_id
    )

    if not provider:

        return None

    if not provider.is_active:

        return provider

    provider.updated_by = "admin"

    return delete_provider(
        db,
        provider
    )


# ==================================================
# Restore Provider
# ==================================================

def restore_external_service_provider(
    db: Session,
    provider_id: int
) -> ExternalServiceProvider | None:

    provider = get_provider_by_id(
        db,
        provider_id
    )

    if not provider:

        return None

    provider.updated_by = "admin"

    return restore_provider(
        db,
        provider
    )