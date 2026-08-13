from datetime import datetime
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import desc

from .model import WarehouseReceivingRecord
from .schemas import WarehouseReceivingCreate, WarehouseReceivingUpdate

def generate_grn_code(db: Session) -> str:
    """Generates unique Goods Receipt Note Code in format GRN-YYYY-XXXX."""
    current_year = datetime.utcnow().year
    prefix = f"GRN-{current_year}-"
    
    last_record = (
        db.query(WarehouseReceivingRecord)
        .filter(WarehouseReceivingRecord.grn_code.like(f"{prefix}%"))
        .order_by(desc(WarehouseReceivingRecord.receiving_id))
        .first()
    )
    
    if last_record:
        try:
            last_seq = int(last_record.grn_code.split("-")[-1])
            new_seq = last_seq + 1
        except ValueError:
            new_seq = 1
    else:
        new_seq = 1
        
    return f"{prefix}{new_seq:04d}"

def get_warehouse_receiving_by_id(db: Session, record_id: int, include_inactive: bool = False) -> Optional[WarehouseReceivingRecord]:
    query = db.query(WarehouseReceivingRecord).filter(WarehouseReceivingRecord.receiving_id == record_id)
    if not include_inactive:
        query = query.filter(WarehouseReceivingRecord.is_active == True)
    return query.first()

def get_warehouse_receiving_list(
    db: Session,
    include_inactive: bool = False,
    import_file_id: Optional[int] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
) -> List[WarehouseReceivingRecord]:
    query = db.query(WarehouseReceivingRecord)
    if not include_inactive:
        query = query.filter(WarehouseReceivingRecord.is_active == True)
    if import_file_id:
        query = query.filter(WarehouseReceivingRecord.import_file_id == import_file_id)
    if status:
        query = query.filter(WarehouseReceivingRecord.status == status)
    if search:
        pattern = f"%{search}%"
        query = query.filter(
            (WarehouseReceivingRecord.grn_code.ilike(pattern)) |
            (WarehouseReceivingRecord.truck_plate_number.ilike(pattern)) |
            (WarehouseReceivingRecord.driver_name.ilike(pattern)) |
            (WarehouseReceivingRecord.inspector_name.ilike(pattern))
        )
    return query.order_by(desc(WarehouseReceivingRecord.receiving_id)).all()

def create_warehouse_receiving(db: Session, schema: WarehouseReceivingCreate, code: str) -> WarehouseReceivingRecord:
    items_list = [item.model_dump() for item in schema.grn_items]
    
    total_inv = sum(i['invoiced_qty'] for i in items_list)
    total_acc = sum(i['accepted_qty'] for i in items_list)
    total_short = sum(i['shortage_qty'] for i in items_list)
    total_dmg = sum(i['damaged_qty'] for i in items_list)

    discrepancy = "None"
    if total_short > 0:
        discrepancy = "Shortage"
    elif total_dmg > 0:
        discrepancy = "Damage"
    elif total_acc > total_inv:
        discrepancy = "Excess"

    db_obj = WarehouseReceivingRecord(
        grn_code=code,
        import_file_id=schema.import_file_id,
        warehouse_name=schema.warehouse_name,
        arrival_datetime=schema.arrival_datetime or datetime.utcnow(),
        truck_plate_number=schema.truck_plate_number,
        driver_name=schema.driver_name,
        driver_phone=schema.driver_phone,
        seal_number=schema.seal_number,
        seal_intact=schema.seal_intact,
        grn_items=items_list,
        total_invoiced_qty=total_inv,
        total_accepted_qty=total_acc,
        total_shortage_qty=total_short,
        total_damaged_qty=total_dmg,
        discrepancy_type=discrepancy,
        discrepancy_notes=schema.discrepancy_notes,
        inspector_name=schema.inspector_name,
        notes=schema.notes,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj

def update_warehouse_receiving(db: Session, record_id: int, schema: WarehouseReceivingUpdate) -> Optional[WarehouseReceivingRecord]:
    db_obj = get_warehouse_receiving_by_id(db, record_id, include_inactive=True)
    if not db_obj:
        return None

    update_data = schema.model_dump(exclude_unset=True)
    if "grn_items" in update_data and update_data["grn_items"] is not None:
        items = [i.model_dump() if hasattr(i, 'model_dump') else i for i in schema.grn_items]
        db_obj.grn_items = items
        db_obj.total_invoiced_qty = sum(i.get('invoiced_qty', 0) for i in items)
        db_obj.total_accepted_qty = sum(i.get('accepted_qty', 0) for i in items)
        db_obj.total_shortage_qty = sum(i.get('shortage_qty', 0) for i in items)
        db_obj.total_damaged_qty = sum(i.get('damaged_qty', 0) for i in items)
        del update_data["grn_items"]

    for key, value in update_data.items():
        setattr(db_obj, key, value)

    db_obj.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_obj)
    return db_obj

def soft_delete_warehouse_receiving(db: Session, record_id: int) -> bool:
    db_obj = get_warehouse_receiving_by_id(db, record_id, include_inactive=False)
    if not db_obj:
        return False
    db_obj.is_active = False
    db_obj.updated_at = datetime.utcnow()
    db.commit()
    return True

def restore_warehouse_receiving(db: Session, record_id: int) -> Optional[WarehouseReceivingRecord]:
    db_obj = get_warehouse_receiving_by_id(db, record_id, include_inactive=True)
    if not db_obj:
        return None
    db_obj.is_active = True
    db_obj.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_obj)
    return db_obj
