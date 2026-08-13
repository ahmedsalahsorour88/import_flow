from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import desc

from .model import CustomsClearanceRecord
from .schemas import CustomsClearanceCreate, CustomsClearanceUpdate

def generate_customs_clearance_code(db: Session) -> str:
    """Generates unique Customs Clearance Code in format CLR-YYYY-XXXX."""
    current_year = datetime.now(timezone.utc).year
    prefix = f"CLR-{current_year}-"
    
    last_record = (
        db.query(CustomsClearanceRecord)
        .filter(CustomsClearanceRecord.clearance_code.like(f"{prefix}%"))
        .order_by(desc(CustomsClearanceRecord.customs_clearance_id))
        .first()
    )
    
    if last_record:
        try:
            last_seq = int(last_record.clearance_code.split("-")[-1])
            new_seq = last_seq + 1
        except ValueError:
            new_seq = 1
    else:
        new_seq = 1
        
    return f"{prefix}{new_seq:04d}"

def get_customs_clearance_by_id(db: Session, record_id: int, include_inactive: bool = False) -> Optional[CustomsClearanceRecord]:
    query = db.query(CustomsClearanceRecord).filter(CustomsClearanceRecord.customs_clearance_id == record_id)
    if not include_inactive:
        query = query.filter(CustomsClearanceRecord.is_active == True)
    return query.first()

def get_customs_clearance_list(
    db: Session,
    include_inactive: bool = False,
    import_file_id: Optional[int] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
) -> List[CustomsClearanceRecord]:
    query = db.query(CustomsClearanceRecord)
    if not include_inactive:
        query = query.filter(CustomsClearanceRecord.is_active == True)
    if import_file_id:
        query = query.filter(CustomsClearanceRecord.import_file_id == import_file_id)
    if status:
        query = query.filter(CustomsClearanceRecord.status == status)
    if search:
        pattern = f"%{search}%"
        query = query.filter(
            (CustomsClearanceRecord.clearance_code.ilike(pattern)) |
            (CustomsClearanceRecord.declaration_46_no.ilike(pattern)) |
            (CustomsClearanceRecord.release_permit_no.ilike(pattern)) |
            (CustomsClearanceRecord.owner.ilike(pattern))
        )
    return query.order_by(desc(CustomsClearanceRecord.customs_clearance_id)).all()

def create_customs_clearance(db: Session, schema: CustomsClearanceCreate, code: str) -> CustomsClearanceRecord:
    total_duty = schema.import_duty_amount + schema.vat_amount + schema.schedule_tax_amount + schema.wht_amount + schema.lab_service_fees
    
    db_obj = CustomsClearanceRecord(
        clearance_code=code,
        import_file_id=schema.import_file_id,
        declaration_46_no=schema.declaration_46_no,
        customs_office_name=schema.customs_office_name,
        channel_type=schema.channel_type,
        inspection_date=schema.inspection_date or datetime.now(timezone.utc),
        regulatory_bodies=schema.regulatory_bodies,
        inspection_notes=schema.inspection_notes,
        import_duty_amount=schema.import_duty_amount,
        vat_amount=schema.vat_amount,
        schedule_tax_amount=schema.schedule_tax_amount,
        wht_amount=schema.wht_amount,
        lab_service_fees=schema.lab_service_fees,
        total_duty_payable=total_duty,
        owner=schema.owner,
        notes=schema.notes,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj

def update_customs_clearance(db: Session, record_id: int, schema: CustomsClearanceUpdate) -> Optional[CustomsClearanceRecord]:
    db_obj = get_customs_clearance_by_id(db, record_id, include_inactive=True)
    if not db_obj:
        return None

    update_data = schema.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_obj, key, value)

    # Recalculate total duty
    db_obj.total_duty_payable = db_obj.import_duty_amount + db_obj.vat_amount + db_obj.schedule_tax_amount + db_obj.wht_amount + db_obj.lab_service_fees
    db_obj.updated_at = datetime.now(timezone.utc)
    
    db.commit()
    db.refresh(db_obj)
    return db_obj

def soft_delete_customs_clearance(db: Session, record_id: int) -> bool:
    db_obj = get_customs_clearance_by_id(db, record_id, include_inactive=False)
    if not db_obj:
        return False
    db_obj.is_active = False
    db_obj.updated_at = datetime.now(timezone.utc)
    db.commit()
    return True

def restore_customs_clearance(db: Session, record_id: int) -> Optional[CustomsClearanceRecord]:
    db_obj = get_customs_clearance_by_id(db, record_id, include_inactive=True)
    if not db_obj:
        return None
    db_obj.is_active = True
    db_obj.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(db_obj)
    return db_obj
