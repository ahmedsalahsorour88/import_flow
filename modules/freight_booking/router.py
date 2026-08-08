"""
FastAPI Router for Phase 4 – Freight Booking & Container Allocation
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from database.database import get_db
from modules.freight_booking.schemas import (
    ShipmentBookingCreate,
    ShipmentBookingUpdate,
    ShipmentBookingResponse,
)
import modules.freight_booking.service as service

router = APIRouter(prefix="/api/v1/freight-booking", tags=["Freight Booking & Container Allocation (Phase 4)"])


@router.post(
    "",
    response_model=ShipmentBookingResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new Shipment Booking request",
)
def create_booking(payload: ShipmentBookingCreate, db: Session = Depends(get_db)):
    return service.create_booking_service(db, payload)


@router.get(
    "",
    response_model=List[ShipmentBookingResponse],
    summary="List shipment bookings with filters",
)
def list_bookings(
    include_inactive: bool = False,
    import_file_id: Optional[int] = Query(None),
    status: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    return service.list_bookings_service(db, include_inactive, import_file_id, status, search)


@router.get(
    "/{booking_id}",
    response_model=ShipmentBookingResponse,
    summary="Get single shipment booking by ID",
)
def get_booking(booking_id: int, db: Session = Depends(get_db)):
    booking = service.get_booking_service(db, booking_id)
    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Shipment booking not found")
    return booking


@router.put(
    "/{booking_id}",
    response_model=ShipmentBookingResponse,
    summary="Update shipment booking record",
)
def update_booking(booking_id: int, payload: ShipmentBookingUpdate, db: Session = Depends(get_db)):
    updated = service.update_booking_service(db, booking_id, payload)
    if not updated:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Shipment booking not found")
    return updated


@router.delete(
    "/{booking_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Soft delete a shipment booking",
)
def delete_booking(booking_id: int, db: Session = Depends(get_db)):
    success = service.soft_delete_booking_service(db, booking_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Shipment booking not found")
    return None
