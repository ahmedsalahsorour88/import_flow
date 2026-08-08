from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from database.database import get_db
from .schemas import PartnerCreate, PartnerResponse, PartnerUpdate
from .service import ExternalServiceProviderService

router = APIRouter(
    prefix="/api/v1/external-service-providers",
    tags=["External Service Providers & Financial Partners (MD-003)"]
)


@router.get("", response_model=List[PartnerResponse])
def list_partners(
    partner_type: Optional[str] = Query(None, description="Filter by partner type e.g. Bank, Shipping Line, Customs Broker"),
    include_inactive: bool = Query(False, description="Set True to include deactivated partners"),
    db: Session = Depends(get_db)
):
    service = ExternalServiceProviderService(db)
    return service.get_all_partners(partner_type=partner_type, include_inactive=include_inactive)


@router.post("", response_model=PartnerResponse, status_code=status.HTTP_201_CREATED)
def create_partner(
    partner_data: PartnerCreate,
    db: Session = Depends(get_db)
):
    service = ExternalServiceProviderService(db)
    return service.create_partner(partner_data)


@router.get("/{provider_id}", response_model=PartnerResponse)
def get_partner(
    provider_id: int,
    db: Session = Depends(get_db)
):
    service = ExternalServiceProviderService(db)
    return service.get_partner_by_id(provider_id)


@router.put("/{provider_id}", response_model=PartnerResponse)
def update_partner(
    provider_id: int,
    partner_data: PartnerUpdate,
    db: Session = Depends(get_db)
):
    service = ExternalServiceProviderService(db)
    return service.update_partner(provider_id, partner_data)


@router.delete("/{provider_id}")
def delete_partner(
    provider_id: int,
    db: Session = Depends(get_db)
):
    service = ExternalServiceProviderService(db)
    return service.soft_delete_partner(provider_id)


@router.patch("/{provider_id}/restore")
def restore_partner(
    provider_id: int,
    db: Session = Depends(get_db)
):
    service = ExternalServiceProviderService(db)
    return service.restore_partner(provider_id)