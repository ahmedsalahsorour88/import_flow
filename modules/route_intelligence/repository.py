"""
Route & Supplier Intelligence Repository (AI-ROUTE-006)
"""

from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import desc

from .model import RouteOperationalNote
from modules.suppliers.model import Supplier
from modules.purchase_orders.model import PurchaseOrder
from modules.import_files.model import ImportFile
from modules.cargo_shipping.model import CargoShippingRecord
from modules.customs_clearance.model import CustomsClearanceRecord
from modules.freight_booking.model import ShipmentBooking
from modules.financial_settlement.model import LandedCostSettlementRecord


def get_supplier_by_id(db: Session, supplier_id: int) -> Optional[Supplier]:
    return db.query(Supplier).filter(Supplier.supplier_id == supplier_id).first()


def get_supplier_by_name(db: Session, name: str) -> Optional[Supplier]:
    return db.query(Supplier).filter(Supplier.company_name.ilike(f"%{name}%")).first()


def get_notes_by_supplier(db: Session, supplier_id: int) -> List[RouteOperationalNote]:
    return (
        db.query(RouteOperationalNote)
        .filter(RouteOperationalNote.supplier_id == supplier_id, RouteOperationalNote.is_active == True)
        .order_by(desc(RouteOperationalNote.created_at))
        .all()
    )


def create_operational_note(db: Session, data: dict, user: str = "System") -> RouteOperationalNote:
    note = RouteOperationalNote(
        supplier_id=data["supplier_id"],
        route_name=data.get("route_name"),
        note_category=data.get("note_category", "General"),
        note_text=data["note_text"],
        created_by=user,
    )
    db.add(note)
    db.commit()
    db.refresh(note)
    return note


def get_supplier_purchase_orders(db: Session, supplier_id: int) -> List[PurchaseOrder]:
    return (
        db.query(PurchaseOrder)
        .filter(PurchaseOrder.supplier_id == supplier_id, PurchaseOrder.is_active == True)
        .order_by(desc(PurchaseOrder.order_date))
        .all()
    )


def get_supplier_import_files(db: Session, supplier_id: int) -> List[ImportFile]:
    return (
        db.query(ImportFile)
        .filter(ImportFile.supplier_id == supplier_id, ImportFile.is_active == True)
        .order_by(desc(ImportFile.created_at))
        .all()
    )


def get_latest_shipping_record_for_files(db: Session, file_ids: List[int]) -> Optional[CargoShippingRecord]:
    if not file_ids:
        return None
    return (
        db.query(CargoShippingRecord)
        .filter(CargoShippingRecord.import_file_id.in_(file_ids), CargoShippingRecord.is_active == True)
        .order_by(desc(CargoShippingRecord.created_at))
        .first()
    )


def get_latest_booking_for_files(db: Session, file_ids: List[int]) -> Optional[ShipmentBooking]:
    if not file_ids:
        return None
    return (
        db.query(ShipmentBooking)
        .filter(ShipmentBooking.import_file_id.in_(file_ids), ShipmentBooking.is_active == True)
        .order_by(desc(ShipmentBooking.created_at))
        .first()
    )


def get_latest_customs_record_for_files(db: Session, file_ids: List[int]) -> Optional[CustomsClearanceRecord]:
    if not file_ids:
        return None
    return (
        db.query(CustomsClearanceRecord)
        .filter(CustomsClearanceRecord.import_file_id.in_(file_ids), CustomsClearanceRecord.is_active == True)
        .order_by(desc(CustomsClearanceRecord.created_at))
        .first()
    )


def get_latest_settlement_for_files(db: Session, file_ids: List[int]) -> Optional[LandedCostSettlementRecord]:
    if not file_ids:
        return None
    return (
        db.query(LandedCostSettlementRecord)
        .filter(LandedCostSettlementRecord.import_file_id.in_(file_ids), LandedCostSettlementRecord.is_active == True)
        .order_by(desc(LandedCostSettlementRecord.created_at))
        .first()
    )
