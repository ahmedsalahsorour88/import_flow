from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import func
from .model import DemurragePolicy, DemurrageTracking


def get_policy_by_id(db: Session, policy_id: int) -> Optional[DemurragePolicy]:
    return db.query(DemurragePolicy).filter(
        DemurragePolicy.policy_id == policy_id,
        DemurragePolicy.is_active == True,
    ).first()


def get_policy_for_carrier_container(
    db: Session, carrier_name: str, container_type: str
) -> Optional[DemurragePolicy]:
    return db.query(DemurragePolicy).filter(
        func.lower(DemurragePolicy.carrier_name) == carrier_name.strip().lower(),
        func.lower(DemurragePolicy.container_type) == container_type.strip().lower(),
        DemurragePolicy.is_active == True,
    ).first()


def get_policies(
    db: Session,
    carrier_name: Optional[str] = None,
    container_type: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
) -> List[DemurragePolicy]:
    q = db.query(DemurragePolicy).filter(DemurragePolicy.is_active == True)
    if carrier_name:
        q = q.filter(DemurragePolicy.carrier_name.ilike(f"%{carrier_name}%"))
    if container_type:
        q = q.filter(DemurragePolicy.container_type.ilike(f"%{container_type}%"))
    return q.offset(skip).limit(limit).all()


def create_policy(db: Session, data: dict, user: str = "System") -> DemurragePolicy:
    policy = DemurragePolicy(**data)
    policy.created_by = user
    policy.updated_by = user
    db.add(policy)
    db.commit()
    db.refresh(policy)
    return policy


def update_policy(db: Session, policy: DemurragePolicy, data: dict, user: str = "System") -> DemurragePolicy:
    for key, val in data.items():
        if val is not None:
            setattr(policy, key, val)
    policy.updated_by = user
    policy.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(policy)
    return policy


def delete_policy(db: Session, policy: DemurragePolicy, user: str = "System") -> DemurragePolicy:
    policy.is_active = False
    policy.updated_by = user
    policy.updated_at = datetime.now(timezone.utc)
    db.commit()
    return policy


def generate_tracking_code(db: Session) -> str:
    count = db.query(func.count(DemurrageTracking.tracking_id)).scalar() or 0
    year = datetime.now(timezone.utc).year
    return f"DND-{year}-{count + 1:04d}"


def get_tracking_by_id(db: Session, tracking_id: int) -> Optional[DemurrageTracking]:
    return db.query(DemurrageTracking).filter(
        DemurrageTracking.tracking_id == tracking_id,
        DemurrageTracking.is_active == True,
    ).first()


def get_tracking_by_code(db: Session, tracking_code: str) -> Optional[DemurrageTracking]:
    return db.query(DemurrageTracking).filter(
        DemurrageTracking.tracking_code == tracking_code.strip(),
        DemurrageTracking.is_active == True,
    ).first()


def get_trackings(
    db: Session,
    import_file_id: Optional[int] = None,
    carrier_name: Optional[str] = None,
    status_filter: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
) -> List[DemurrageTracking]:
    q = db.query(DemurrageTracking).filter(DemurrageTracking.is_active == True)
    if import_file_id:
        q = q.filter(DemurrageTracking.import_file_id == import_file_id)
    if carrier_name:
        q = q.filter(DemurrageTracking.carrier_name.ilike(f"%{carrier_name}%"))
    if status_filter:
        q = q.filter(DemurrageTracking.status == status_filter)
    return q.order_by(DemurrageTracking.tracking_id.desc()).offset(skip).limit(limit).all()


def create_tracking(db: Session, data: dict, user: str = "System") -> DemurrageTracking:
    if "tracking_code" not in data or not data["tracking_code"]:
        data["tracking_code"] = generate_tracking_code(db)
    tracking = DemurrageTracking(**data)
    tracking.created_by = user
    tracking.updated_by = user
    db.add(tracking)
    db.commit()
    db.refresh(tracking)
    return tracking


def update_tracking(db: Session, tracking: DemurrageTracking, data: dict, user: str = "System") -> DemurrageTracking:
    for key, val in data.items():
        if val is not None:
            setattr(tracking, key, val)
    tracking.updated_by = user
    tracking.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(tracking)
    return tracking


def delete_tracking(db: Session, tracking: DemurrageTracking, user: str = "System") -> DemurrageTracking:
    tracking.is_active = False
    tracking.updated_by = user
    tracking.updated_at = datetime.now(timezone.utc)
    db.commit()
    return tracking
