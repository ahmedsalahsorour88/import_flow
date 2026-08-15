from datetime import datetime, timezone, timedelta
from typing import List, Optional
from sqlalchemy.orm import Session

from modules.freight_booking.model import ShipmentBooking
from modules.freight_booking.schemas import ShipmentBookingCreate, ShipmentBookingUpdate
import modules.freight_booking.repository as repo
import modules.freight_booking.validators as validators


def calculate_transit_time_and_costs(booking: ShipmentBooking):
    # Calculate transit time in days
    if booking.etd and booking.eta:
        validators.validate_booking_dates(booking.etd, booking.eta)
        delta = booking.eta - booking.etd
        booking.transit_time_days = max(0, delta.days)
    else:
        booking.transit_time_days = 0

    # Calculate departure delay days if actual departure (ATD) is recorded
    if booking.atd and booking.etd:
        delay = (booking.atd.date() - booking.etd.date()).days
        booking.departure_delay_days = max(0, delay)
    else:
        booking.departure_delay_days = 0

    # Calculate expected warehouse arrival date based on ETA + warehouse lead days
    wh_days = booking.expected_warehouse_days if booking.expected_warehouse_days is not None else 7
    if booking.eta:
        # If there was an actual departure delay, adjust ETA if ETA was not already updated
        adjusted_eta = booking.eta + timedelta(days=booking.departure_delay_days or 0)
        booking.expected_warehouse_arrival_date = adjusted_eta + timedelta(days=wh_days)
    elif booking.expected_warehouse_arrival_date is None and booking.etd:
        booking.expected_warehouse_arrival_date = booking.etd + timedelta(days=booking.transit_time_days + wh_days)

    # Calculate total container count
    total_containers = 0
    if booking.containers_data:
        for item in booking.containers_data:
            qty = item.get("quantity", 1) if isinstance(item, dict) else getattr(item, "quantity", 1)
            total_containers += qty

    # Calculate preliminary costs
    total_cost = 0.0
    if booking.cost_charges_data:
        updated_charges = []
        for charge in booking.cost_charges_data:
            c_dict = charge if isinstance(charge, dict) else charge.model_dump()
            unit = c_dict.get("unit", "Per Container")
            rate = float(c_dict.get("rate", 0.0))
            qty = int(c_dict.get("quantity", 1))

            if unit == "Per Container" and total_containers > 0:
                calc_qty = total_containers
            else:
                calc_qty = qty

            item_total = rate * calc_qty
            c_dict["quantity"] = calc_qty
            c_dict["total"] = item_total
            total_cost += item_total
            updated_charges.append(c_dict)

        booking.cost_charges_data = updated_charges

    booking.total_freight_cost_usd = round(total_cost, 2)


def create_booking_service(db: Session, payload: ShipmentBookingCreate) -> ShipmentBooking:
    validators.validate_container_allocation(payload.shipment_type, payload.containers_data)
    booking = repo.create_booking(db, payload)
    calculate_transit_time_and_costs(booking)
    db.commit()
    db.refresh(booking)
    return booking


def get_booking_service(db: Session, booking_id: int) -> Optional[ShipmentBooking]:
    return repo.get_booking_by_id(db, booking_id)


def list_bookings_service(
    db: Session,
    include_inactive: bool = False,
    import_file_id: Optional[int] = None,
    status: Optional[str] = None,
    search: Optional[str] = None
) -> List[ShipmentBooking]:
    return repo.list_bookings(db, include_inactive, import_file_id, status, search)


def update_booking_service(db: Session, booking_id: int, payload: ShipmentBookingUpdate) -> Optional[ShipmentBooking]:
    booking = repo.get_booking_by_id(db, booking_id)
    if not booking:
        return None

    updated = repo.update_booking(db, booking_id, payload)
    if updated:
        calculate_transit_time_and_costs(updated)
        db.commit()
        db.refresh(updated)
    return updated


def soft_delete_booking_service(db: Session, booking_id: int) -> bool:
    return repo.soft_delete_booking(db, booking_id)


def restore_booking_service(db: Session, booking_id: int) -> Optional[ShipmentBooking]:
    booking = repo.restore_booking(db, booking_id)
    if booking:
        calculate_transit_time_and_costs(booking)
        db.commit()
        db.refresh(booking)
    return booking
