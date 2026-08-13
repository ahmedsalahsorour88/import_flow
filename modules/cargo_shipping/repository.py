from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import desc

from .model import CargoShippingRecord
from .schemas import CargoShippingCreate, CargoShippingUpdate

def generate_cargo_shipping_code(db: Session) -> str:
    """Generates unique Cargo Shipping Code in format SHP-YYYY-XXXX."""
    current_year = datetime.now(timezone.utc).year
    prefix = f"SHP-{current_year}-"
    
    last_record = (
        db.query(CargoShippingRecord)
        .filter(CargoShippingRecord.cargo_shipping_code.like(f"{prefix}%"))
        .order_by(desc(CargoShippingRecord.cargo_shipping_id))
        .first()
    )
    
    if last_record:
        try:
            last_seq = int(last_record.cargo_shipping_code.split("-")[-1])
            new_seq = last_seq + 1
        except ValueError:
            new_seq = 1
    else:
        new_seq = 1
        
    return f"{prefix}{new_seq:04d}"

def get_cargo_shipping_by_id(db: Session, record_id: int, include_inactive: bool = False) -> Optional[CargoShippingRecord]:
    query = db.query(CargoShippingRecord).filter(CargoShippingRecord.cargo_shipping_id == record_id)
    if not include_inactive:
        query = query.filter(CargoShippingRecord.is_active == True)
    return query.first()

def get_cargo_shipping_list(
    db: Session,
    include_inactive: bool = False,
    import_file_id: Optional[int] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
) -> List[CargoShippingRecord]:
    query = db.query(CargoShippingRecord)
    if not include_inactive:
        query = query.filter(CargoShippingRecord.is_active == True)
    if import_file_id:
        query = query.filter(CargoShippingRecord.import_file_id == import_file_id)
    if status:
        query = query.filter(CargoShippingRecord.status == status)
    if search:
        pattern = f"%{search}%"
        query = query.filter(
            (CargoShippingRecord.cargo_shipping_code.ilike(pattern)) |
            (CargoShippingRecord.owner.ilike(pattern))
        )
    return query.order_by(desc(CargoShippingRecord.cargo_shipping_id)).all()

def create_cargo_shipping(db: Session, schema: CargoShippingCreate, code: str) -> CargoShippingRecord:
    db_obj = CargoShippingRecord(
        cargo_shipping_code=code,
        import_file_id=schema.import_file_id,
        booking_id=schema.booking_id,
        crd_date=schema.crd_date,
        cargo_cutoff_date=schema.cargo_cutoff_date,
        containers_loading_data=[c.model_dump() for c in schema.containers_loading_data],
        courier_tracking_data=schema.courier_tracking_data.model_dump() if schema.courier_tracking_data else {},
        cargox_exchange_data=schema.cargox_exchange_data.model_dump() if schema.cargox_exchange_data else {},
        live_tracking_url=schema.live_tracking_url,
        status=schema.status,
        owner=schema.owner,
        notes=schema.notes,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj

def update_cargo_shipping(db: Session, record_id: int, schema: CargoShippingUpdate) -> Optional[CargoShippingRecord]:
    db_obj = get_cargo_shipping_by_id(db, record_id, include_inactive=True)
    if not db_obj:
        return None

    update_data = schema.model_dump(exclude_unset=True)
    if "containers_loading_data" in update_data and update_data["containers_loading_data"] is not None:
        db_obj.containers_loading_data = [c.model_dump() if hasattr(c, 'model_dump') else c for c in schema.containers_loading_data]
        del update_data["containers_loading_data"]
    if "courier_tracking_data" in update_data and update_data["courier_tracking_data"] is not None:
        db_obj.courier_tracking_data = schema.courier_tracking_data.model_dump() if hasattr(schema.courier_tracking_data, 'model_dump') else update_data["courier_tracking_data"]
        del update_data["courier_tracking_data"]
    if "cargox_exchange_data" in update_data and update_data["cargox_exchange_data"] is not None:
        db_obj.cargox_exchange_data = schema.cargox_exchange_data.model_dump() if hasattr(schema.cargox_exchange_data, 'model_dump') else update_data["cargox_exchange_data"]
        del update_data["cargox_exchange_data"]

    for key, value in update_data.items():
        setattr(db_obj, key, value)

    db_obj.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(db_obj)
    return db_obj

def soft_delete_cargo_shipping(db: Session, record_id: int) -> bool:
    db_obj = get_cargo_shipping_by_id(db, record_id, include_inactive=False)
    if not db_obj:
        return False
    db_obj.is_active = False
    db_obj.updated_at = datetime.now(timezone.utc)
    db.commit()
    return True

def restore_cargo_shipping(db: Session, record_id: int) -> Optional[CargoShippingRecord]:
    db_obj = get_cargo_shipping_by_id(db, record_id, include_inactive=True)
    if not db_obj:
        return None
    db_obj.is_active = True
    db_obj.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(db_obj)
    return db_obj
