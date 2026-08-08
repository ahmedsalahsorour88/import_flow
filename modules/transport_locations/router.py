from typing import List, Optional

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from database.database import get_db
from modules.transport_locations.schemas import (
    TransportLocationCreate,
    TransportLocationResponse,
    TransportLocationUpdate,
)
from modules.transport_locations.service import TransportLocationService

router = APIRouter(prefix="/transport-locations", tags=["Transport Locations (MD-009)"])


@router.get("", response_model=List[TransportLocationResponse])
def get_all_locations(
    include_inactive: bool = Query(False, description="Include inactive locations"),
    location_type: Optional[str] = Query(None, description="Filter by type (Sea Port, Airport, Dry Port, Land Border)"),
    country: Optional[str] = Query(None, description="Filter by country"),
    search: Optional[str] = Query(None, description="Search by code, name, city or country"),
    db: Session = Depends(get_db),
):
    service = TransportLocationService(db)
    return service.get_all(
        include_inactive=include_inactive,
        location_type=location_type,
        country=country,
        search=search,
    )


@router.get("/{location_id}", response_model=TransportLocationResponse)
def get_location_by_id(
    location_id: int,
    db: Session = Depends(get_db),
):
    service = TransportLocationService(db)
    return service.get_by_id(location_id)


@router.post("", response_model=TransportLocationResponse, status_code=status.HTTP_201_CREATED)
def create_location(
    data: TransportLocationCreate,
    db: Session = Depends(get_db),
):
    service = TransportLocationService(db)
    return service.create(data)


@router.put("/{location_id}", response_model=TransportLocationResponse)
def update_location(
    location_id: int,
    data: TransportLocationUpdate,
    db: Session = Depends(get_db),
):
    service = TransportLocationService(db)
    return service.update(location_id, data)


@router.delete("/{location_id}", response_model=TransportLocationResponse)
def soft_delete_location(
    location_id: int,
    db: Session = Depends(get_db),
):
    service = TransportLocationService(db)
    return service.soft_delete(location_id)


@router.post("/{location_id}/restore", response_model=TransportLocationResponse)
def restore_location(
    location_id: int,
    db: Session = Depends(get_db),
):
    service = TransportLocationService(db)
    return service.restore(location_id)
