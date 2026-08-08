from datetime import datetime
from fastapi import HTTPException, status


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
