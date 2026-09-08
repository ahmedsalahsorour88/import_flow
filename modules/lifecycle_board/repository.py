"""
Repository for Shipment Stage Activity & Lifecycle Board Queries
"""

from typing import List, Optional, Dict
from sqlalchemy.orm import Session
from sqlalchemy import func
from modules.lifecycle_board.model import ShipmentStageActivity
from modules.import_files.model import ImportFile


def get_all_activities(db: Session, import_file_code: Optional[str] = None, status: Optional[str] = None) -> List[ShipmentStageActivity]:
    query = db.query(ShipmentStageActivity)
    if import_file_code:
        query = query.filter(ShipmentStageActivity.import_file_code == import_file_code)
    if status:
        query = query.filter(ShipmentStageActivity.status == status)
    return query.all()


def get_activity(db: Session, import_file_code: str, step_code: str) -> Optional[ShipmentStageActivity]:
    return (
        db.query(ShipmentStageActivity)
        .filter(
            ShipmentStageActivity.import_file_code == import_file_code,
            ShipmentStageActivity.step_code == step_code,
        )
        .first()
    )


def save_or_update_activity(
    db: Session,
    import_file_code: str,
    step_code: str,
    status: str,
    started_at: Optional[str] = None,
    completed_at: Optional[str] = None,
    assigned_user: Optional[str] = None,
    action_data: Optional[str] = None,
    notes: Optional[str] = None,
) -> ShipmentStageActivity:
    rec = get_activity(db, import_file_code, step_code)
    if not rec:
        rec = ShipmentStageActivity(
            import_file_code=import_file_code,
            step_code=step_code,
            status=status,
            started_at=started_at,
            completed_at=completed_at,
            assigned_user=assigned_user,
            action_data=action_data,
            notes=notes,
        )
        db.add(rec)
    else:
        rec.status = status
        if started_at:
            rec.started_at = started_at
        if completed_at:
            rec.completed_at = completed_at
        if assigned_user:
            rec.assigned_user = assigned_user
        if action_data:
            rec.action_data = action_data
        if notes:
            rec.notes = notes
    db.commit()
    db.refresh(rec)
    return rec


def get_step_counts(db: Session) -> Dict[str, int]:
    rows = (
        db.query(ShipmentStageActivity.step_code, func.count(ShipmentStageActivity.id))
        .filter(ShipmentStageActivity.status == "In-Progress")
        .group_by(ShipmentStageActivity.step_code)
        .all()
    )
    return {row[0]: row[1] for row in rows}


def get_active_shipments_with_details(db: Session, step_code: Optional[str] = None):
    query = (
        db.query(ShipmentStageActivity, ImportFile)
        .join(ImportFile, ShipmentStageActivity.import_file_code == ImportFile.import_file_code)
        .filter(ShipmentStageActivity.status == "In-Progress")
    )
    if step_code:
        query = query.filter(ShipmentStageActivity.step_code == step_code)
    return query.all()


def get_completed_activities_for_files(db: Session, import_file_codes: List[str]) -> Dict[str, List[ShipmentStageActivity]]:
    """
    Batch fetches all completed activities for a list of import file codes in a single query
    to eliminate N+1 roundtrips.
    """
    if not import_file_codes:
        return {}
    activities = (
        db.query(ShipmentStageActivity)
        .filter(
            ShipmentStageActivity.import_file_code.in_(import_file_codes),
            ShipmentStageActivity.status == "Completed",
        )
        .order_by(ShipmentStageActivity.id.asc())
        .all()
    )
    result: Dict[str, List[ShipmentStageActivity]] = {}
    for act in activities:
        result.setdefault(act.import_file_code, []).append(act)
    return result
