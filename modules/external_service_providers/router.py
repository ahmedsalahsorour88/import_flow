from fastapi import APIRouter
from fastapi import Depends
from fastapi import HTTPException

from sqlalchemy.orm import Session

from database.database import get_db

from .schemas import ExternalServiceProviderCreate
from .schemas import ExternalServiceProviderUpdate
from .schemas import ExternalServiceProviderResponse

from .service import create_external_service_provider
from .service import get_all_providers
from .service import get_provider
from .service import update_external_service_provider
from .service import delete_external_service_provider
from .service import restore_external_service_provider


# ==================================================
# Router
# ==================================================

provider_router = APIRouter(
    prefix="/external-service-providers",
    tags=["External Service Providers"]
)


# ==================================================
# Create Provider
# ==================================================

@provider_router.post(
    "/",
    response_model=ExternalServiceProviderResponse
)
def create_provider(
    provider: ExternalServiceProviderCreate,
    db: Session = Depends(get_db)
):

    return create_external_service_provider(
        db,
        provider
    )


# ==================================================
# Get Active Providers
# ==================================================

@provider_router.get(
    "/",
    response_model=list[ExternalServiceProviderResponse]
)
def get_providers(
    db: Session = Depends(get_db)
):

    return get_all_providers(
        db
    )


# ==================================================
# Get Provider By ID
# ==================================================

@provider_router.get(
    "/{provider_id}",
    response_model=ExternalServiceProviderResponse
)
def get_provider_by_id(
    provider_id: int,
    db: Session = Depends(get_db)
):

    provider = get_provider(
        db,
        provider_id
    )

    if provider is None:

        raise HTTPException(
            status_code=404,
            detail="External Service Provider not found."
        )

    return provider


# ==================================================
# Update Provider
# ==================================================

@provider_router.put(
    "/{provider_id}",
    response_model=ExternalServiceProviderResponse
)
def update_provider(
    provider_id: int,
    provider: ExternalServiceProviderUpdate,
    db: Session = Depends(get_db)
):

    updated_provider = update_external_service_provider(
        db,
        provider_id,
        provider
    )

    if updated_provider is None:

        raise HTTPException(
            status_code=404,
            detail="External Service Provider not found."
        )

    return updated_provider


# ==================================================
# Soft Delete Provider
# ==================================================

@provider_router.delete(
    "/{provider_id}",
    response_model=ExternalServiceProviderResponse
)
def delete_provider(
    provider_id: int,
    db: Session = Depends(get_db)
):

    deleted_provider = delete_external_service_provider(
        db,
        provider_id
    )

    if deleted_provider is None:

        raise HTTPException(
            status_code=404,
            detail="External Service Provider not found."
        )

    return deleted_provider


# ==================================================
# Restore Provider
# ==================================================

@provider_router.patch(
    "/{provider_id}/restore",
    response_model=ExternalServiceProviderResponse
)
def restore_provider(
    provider_id: int,
    db: Session = Depends(get_db)
):

    restored_provider = restore_external_service_provider(
        db,
        provider_id
    )

    if restored_provider is None:

        raise HTTPException(
            status_code=404,
            detail="External Service Provider not found."
        )

    return restored_provider