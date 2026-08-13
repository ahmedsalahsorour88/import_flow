from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import extract

from modules.freight_booking.model import ShipmentBooking
from modules.freight_booking.schemas import ShipmentBookingCreate, ShipmentBookingUpdate


def generate_booking_code(db: Session) -> str:
    current_year = datetime.now(timezone.utc).year
    count = db.query(ShipmentBooking).filter(
        extract("year", ShipmentBooking.created_at) == current_year
    ).count()
    return f"BKG-{current_year}-{(count + 1):04d}"


def create_booking(db: Session, payload: ShipmentBookingCreate) -> ShipmentBooking:
    code = generate_booking_code(db)
    containers_json = [c.model_dump() for c in payload.containers_data]
    costs_json = [c.model_dump() for c in payload.cost_charges_data]

    booking = ShipmentBooking(
        booking_code=code,
        booking_confirmation_no=payload.booking_confirmation_no,
        import_file_id=payload.import_file_id,
        rfq_request_id=payload.rfq_request_id,
        freight_forwarder_id=payload.freight_forwarder_id,
        freight_forwarder_name=payload.freight_forwarder_name,
        shipping_line_id=payload.shipping_line_id,
        shipping_line_name=payload.shipping_line_name,
        shipment_type=payload.shipment_type,
        pol_location_id=payload.pol_location_id,
        pol_name=payload.pol_name,
        pod_location_id=payload.pod_location_id,
        pod_name=payload.pod_name,
        etd=payload.etd,
        eta=payload.eta,
        free_demurrage_days=payload.free_demurrage_days,
        cargo_cutoff_date=payload.cargo_cutoff_date,
        si_cutoff_date=payload.si_cutoff_date,
        vessel_name=payload.vessel_name,
        voyage_number=payload.voyage_number,
        container_release_order_no=payload.container_release_order_no,
        freight_terms=payload.freight_terms,
        containers_data=containers_json,
        cost_charges_data=costs_json,
        status=payload.status,
        owner=payload.owner,
        notes=payload.notes,
    )

    db.add(booking)
    db.commit()
    db.refresh(booking)
    return booking


def get_booking_by_id(db: Session, booking_id: int) -> Optional[ShipmentBooking]:
    return db.query(ShipmentBooking).filter(
        ShipmentBooking.booking_id == booking_id,
        ShipmentBooking.is_active == True
    ).first()


def list_bookings(
    db: Session,
    include_inactive: bool = False,
    import_file_id: Optional[int] = None,
    status: Optional[str] = None,
    search: Optional[str] = None
) -> List[ShipmentBooking]:
    query = db.query(ShipmentBooking)
    if not include_inactive:
        query = query.filter(ShipmentBooking.is_active == True)
    if import_file_id is not None:
        query = query.filter(ShipmentBooking.import_file_id == import_file_id)
    if status is not None and status != "All":
        query = query.filter(ShipmentBooking.status == status)
    if search:
        pattern = f"%{search}%"
        query = query.filter(
            (ShipmentBooking.booking_code.like(pattern)) |
            (ShipmentBooking.booking_confirmation_no.like(pattern)) |
            (ShipmentBooking.vessel_name.like(pattern)) |
            (ShipmentBooking.freight_forwarder_name.like(pattern))
        )
    return query.order_by(ShipmentBooking.created_at.desc()).all()


def update_booking(db: Session, booking_id: int, payload: ShipmentBookingUpdate) -> Optional[ShipmentBooking]:
    booking = get_booking_by_id(db, booking_id)
    if not booking:
        return None

    data = payload.model_dump(exclude_unset=True)
    if "containers_data" in data and data["containers_data"] is not None:
        data["containers_data"] = [c.model_dump() if hasattr(c, "model_dump") else c for c in data["containers_data"]]
    if "cost_charges_data" in data and data["cost_charges_data"] is not None:
        data["cost_charges_data"] = [c.model_dump() if hasattr(c, "model_dump") else c for c in data["cost_charges_data"]]

    for key, val in data.items():
        setattr(booking, key, val)

    booking.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(booking)
    return booking


def soft_delete_booking(db: Session, booking_id: int) -> bool:
    booking = db.query(ShipmentBooking).filter(ShipmentBooking.booking_id == booking_id).first()
    if not booking:
        return False
    booking.is_active = False
    booking.updated_at = datetime.now(timezone.utc)
    db.commit()
    return True


def restore_booking(db: Session, booking_id: int) -> Optional[ShipmentBooking]:
    booking = db.query(ShipmentBooking).filter(ShipmentBooking.booking_id == booking_id).first()
    if not booking:
        return None
    booking.is_active = True
    booking.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(booking)
    return booking
