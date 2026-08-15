from datetime import datetime
from typing import Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from modules.freight_booking.model import ShipmentBooking


def validate_booking_dates(etd: datetime, eta: datetime):
    if etd and eta and eta < etd:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Estimated Time of Arrival (ETA) cannot be earlier than Estimated Time of Departure (ETD).",
        )


def validate_container_allocation(shipment_type: str, containers_data: list):
    if shipment_type == "Ocean FCL" and not containers_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ocean FCL shipments require at least one allocated container equipment specification.",
        )


def validate_no_duplicate_booking_for_file(
    db: Session, import_file_id: Optional[int], current_booking_id: Optional[int] = None
):
    if not import_file_id:
        return
    query = db.query(ShipmentBooking).filter(
        ShipmentBooking.import_file_id == import_file_id,
        ShipmentBooking.is_active == True,
    )
    if current_booking_id:
        query = query.filter(ShipmentBooking.booking_id != current_booking_id)
    existing = query.first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"يوجد بالفعل حجز شحن مسجل لهذا الملف الاستيرادي (كود الحجز: {existing.booking_code}). يرجى الذهاب لتعديل الحجز الحالي بدلاً من إنشاء حجز جديد.",
        )

