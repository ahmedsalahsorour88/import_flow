"""
Database Repository for Shipment Update Engine
"""

from typing import List, Optional
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from sqlalchemy import or_, func

from modules.shipment_updates.model import ShipmentUpdateLog
from modules.shipment_updates.schemas import ShipmentUpdateLogCreate, ShipmentUpdateLogUpdate


def generate_update_code(db: Session) -> str:
    year = datetime.now(timezone.utc).year
    count = db.query(func.count(ShipmentUpdateLog.update_id)).scalar() or 0
    return f"UPD-{year}-{(count + 1):05d}"


def create_update_log(db: Session, schema: ShipmentUpdateLogCreate, created_by: str = "System") -> ShipmentUpdateLog:
    code = generate_update_code(db)
    db_obj = ShipmentUpdateLog(
        update_code=code,
        import_file_id=schema.import_file_id,
        import_file_code=schema.import_file_code,
        update_category=schema.update_category,
        target_phase=schema.target_phase,
        phase_status=schema.phase_status,
        log_date=schema.log_date,
        note=schema.note,
        adjusted_cost_item=schema.adjusted_cost_item,
        previous_cost=schema.previous_cost or 0.0,
        new_cost=schema.new_cost or 0.0,
        alert_priority=schema.alert_priority,
        assigned_user=schema.assigned_user,
        created_by=created_by,
        updated_by=created_by,
    )
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def get_update_log_by_id(db: Session, update_id: int) -> Optional[ShipmentUpdateLog]:
    return db.query(ShipmentUpdateLog).filter(
        ShipmentUpdateLog.update_id == update_id,
        ShipmentUpdateLog.is_active == True,
    ).first()


def get_all_update_logs(
    db: Session,
    import_file_id: Optional[int] = None,
    update_category: Optional[str] = None,
    target_phase: Optional[str] = None,
    search: Optional[str] = None,
) -> List[ShipmentUpdateLog]:
    query = db.query(ShipmentUpdateLog).filter(ShipmentUpdateLog.is_active == True)

    if import_file_id:
        query = query.filter(ShipmentUpdateLog.import_file_id == import_file_id)

    if update_category and update_category != "All":
        query = query.filter(ShipmentUpdateLog.update_category == update_category)

    if target_phase and target_phase != "All":
        query = query.filter(ShipmentUpdateLog.target_phase.ilike(f"%{target_phase}%"))

    if search:
        term = f"%{search}%"
        query = query.filter(
            or_(
                ShipmentUpdateLog.update_code.ilike(term),
                ShipmentUpdateLog.import_file_code.ilike(term),
                ShipmentUpdateLog.note.ilike(term),
            )
        )

    return query.order_by(ShipmentUpdateLog.update_id.desc()).all()


def update_log_record(db: Session, update_id: int, update_data: dict, updated_by: str = "System") -> Optional[ShipmentUpdateLog]:
    db_obj = get_update_log_by_id(db, update_id)
    if not db_obj:
        return None

    for key, value in update_data.items():
        if hasattr(db_obj, key):
            setattr(db_obj, key, value)

    db_obj.updated_at = datetime.now(timezone.utc)
    db_obj.updated_by = updated_by
    db.commit()
    db.refresh(db_obj)
    return db_obj


def soft_delete_update_log(db: Session, update_id: int, deleted_by: str = "System") -> bool:
    db_obj = get_update_log_by_id(db, update_id)
    if not db_obj:
        return False

    db_obj.is_active = False
    db_obj.updated_at = datetime.now(timezone.utc)
    db_obj.updated_by = deleted_by
    db.commit()
    return True
