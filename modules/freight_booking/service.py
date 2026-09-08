from datetime import datetime, timezone, timedelta
from typing import List, Optional
from sqlalchemy.orm import Session

from modules.freight_booking.model import ShipmentBooking
from modules.freight_booking.schemas import ShipmentBookingCreate, ShipmentBookingUpdate
import modules.freight_booking.repository as repo
import modules.freight_booking.validators as validators


def calculate_transit_time_and_costs(booking: ShipmentBooking, db: Optional[Session] = None):
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

    # --- Cost Savings & Rate Variance Calculation Engine ---
    quot_data = dict(booking.quotation_details_data or {})
    scenario_item = None

    # Retrieve scenario item if linked and needed
    if db and booking.scenario_item_id:
        from modules.shipping_scenarios.model import ShippingScenarioItem
        scenario_item = db.query(ShippingScenarioItem).filter(ShippingScenarioItem.item_id == booking.scenario_item_id).first()

    # Determine original quote amount
    orig_quote_total = float(quot_data.get("original_quote_total_usd") or 0.0)
    if orig_quote_total <= 0.0:
        if scenario_item and scenario_item.total_quotation_amount:
            orig_quote_total = float(scenario_item.total_quotation_amount)
        elif booking.original_freight_cost_usd and booking.original_freight_cost_usd > 0:
            orig_quote_total = float(booking.original_freight_cost_usd)

    booking.original_freight_cost_usd = round(orig_quote_total, 2)

    # Rates before modification
    orig_40ft_rate = float(quot_data.get("original_container_40ft_price") or (scenario_item.container_40ft_price if scenario_item else 0.0))
    orig_20ft_rate = float(quot_data.get("original_container_20ft_price") or (scenario_item.container_20ft_price if scenario_item else 0.0))
    orig_lcl_rate = float(quot_data.get("original_lcl_cbm_price") or (scenario_item.lcl_cbm_price if scenario_item else 0.0))
    orig_air_rate = float(quot_data.get("original_express_courier_price") or (scenario_item.express_courier_price if scenario_item else 0.0))

    # Calculate item-level savings breakdown
    savings_breakdown = []
    item_savings_sum = 0.0

    if booking.cost_charges_data:
        for ch in booking.cost_charges_data:
            c_dict = ch if isinstance(ch, dict) else ch.model_dump()
            c_type = c_dict.get("charge_type", "")
            exec_rate = float(c_dict.get("rate", 0.0))
            exec_qty = float(c_dict.get("quantity", 1))

            orig_rate = 0.0
            unit_label = "حاوية"

            if "40ft" in c_type or "40HC" in c_type or "40" in c_type:
                orig_rate = orig_40ft_rate
                unit_label = "حاوية 40 قدم"
            elif "20ft" in c_type or "20GP" in c_type or "20" in c_type:
                orig_rate = orig_20ft_rate
                unit_label = "حاوية 20 قدم"
            elif "LCL" in c_type or "CBM" in c_type:
                orig_rate = orig_lcl_rate
                unit_label = "متر مكعب CBM"
            elif "Air" in c_type or "Courier" in c_type:
                orig_rate = orig_air_rate
                unit_label = "شحنة / كجم جوي"

            if orig_rate > 0.0:
                diff = round(orig_rate - exec_rate, 2)
                sub_savings = round(diff * exec_qty, 2)
                item_savings_sum += sub_savings
                savings_breakdown.append({
                    "charge_type": c_type,
                    "unit_label": unit_label,
                    "unit_type": unit_label,
                    "original_rate": orig_rate,
                    "original_unit_rate": orig_rate,
                    "executed_rate": exec_rate,
                    "executed_unit_rate": exec_rate,
                    "difference": diff,
                    "unit_diff": diff,
                    "quantity": exec_qty,
                    "subtotal_savings": sub_savings,
                    "item_savings": sub_savings,
                    "currency": c_dict.get("currency", "USD"),
                    "is_saving": diff > 0,
                })

    # If item-level breakdown didn't capture or there are other charges, use overall total difference
    if orig_quote_total > 0.0:
        cost_variance = round(orig_quote_total - booking.total_freight_cost_usd, 2)
        booking.cost_variance_usd = cost_variance
        booking.cost_savings_usd = max(0.0, cost_variance)
    else:
        booking.cost_variance_usd = round(item_savings_sum, 2)
        booking.cost_savings_usd = max(0.0, item_savings_sum)

    # Format savings notes
    if booking.cost_savings_usd > 0:
        pct = round((booking.cost_savings_usd / booking.original_freight_cost_usd) * 100.0, 1) if booking.original_freight_cost_usd > 0 else 0.0
        breakdown_text = ""
        if savings_breakdown:
            parts = [f"{b['charge_type']}: (${b['original_rate']:,.2f} - ${b['executed_rate']:,.2f}) × {int(b['quantity']) if b['quantity'].is_integer() else b['quantity']} = ${b['subtotal_savings']:,.2f} USD" for b in savings_breakdown if b.get('is_saving')]
            if parts:
                breakdown_text = " [" + " | ".join(parts) + "]"
        booking.savings_notes = f"وفر محقق في النولون: ${booking.cost_savings_usd:,.2f} USD ({pct}% توفير في تكلفة الشحن){breakdown_text}"
    elif booking.cost_variance_usd < 0:
        booking.savings_notes = f"زيادة في تكلفة الشحن: +${abs(booking.cost_variance_usd):,.2f} USD عن العرض المبدئي"
    else:
        booking.savings_notes = "السعر المنفذ مطابق تماماً للعرض المعتمد"

    # Persist updated breakdown into quotation_details_data
    quot_data["original_quote_total_usd"] = booking.original_freight_cost_usd
    quot_data["executed_freight_cost_usd"] = booking.total_freight_cost_usd
    quot_data["cost_savings_usd"] = booking.cost_savings_usd
    quot_data["cost_variance_usd"] = booking.cost_variance_usd
    quot_data["savings_breakdown"] = savings_breakdown
    booking.quotation_details_data = quot_data


def create_booking_service(db: Session, payload: ShipmentBookingCreate) -> ShipmentBooking:
    validators.validate_container_allocation(payload.shipment_type, payload.containers_data)
    validators.validate_no_duplicate_booking_for_file(db, payload.import_file_id)
    booking = repo.create_booking(db, payload)
    calculate_transit_time_and_costs(booking, db=db)
    db.commit()
    db.refresh(booking)

    if booking.import_file_id:
        try:
            from modules.lifecycle_board.service import sync_booking_lifecycle_stage
            sync_booking_lifecycle_stage(
                db=db,
                import_file_id=booking.import_file_id,
                booking_code=booking.booking_code,
                booking_confirmation_no=booking.booking_confirmation_no,
                is_confirmed=(booking.status == "Confirmed"),
                vessel_name=booking.vessel_name,
            )
        except Exception:
            pass

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

    if payload.import_file_id is not None:
        validators.validate_no_duplicate_booking_for_file(db, payload.import_file_id, current_booking_id=booking_id)

    updated = repo.update_booking(db, booking_id, payload)
    if updated:
        calculate_transit_time_and_costs(updated, db=db)
        db.commit()
        db.refresh(updated)

        if updated.import_file_id:
            try:
                from modules.lifecycle_board.service import sync_booking_lifecycle_stage
                sync_booking_lifecycle_stage(
                    db=db,
                    import_file_id=updated.import_file_id,
                    booking_code=updated.booking_code,
                    booking_confirmation_no=updated.booking_confirmation_no,
                    is_confirmed=(updated.status == "Confirmed"),
                    vessel_name=updated.vessel_name,
                )
            except Exception:
                pass

    return updated


def soft_delete_booking_service(db: Session, booking_id: int) -> bool:
    return repo.soft_delete_booking(db, booking_id)


def restore_booking_service(db: Session, booking_id: int) -> Optional[ShipmentBooking]:
    booking = repo.restore_booking(db, booking_id)
    if booking:
        calculate_transit_time_and_costs(booking, db=db)
        db.commit()
        db.refresh(booking)
    return booking
