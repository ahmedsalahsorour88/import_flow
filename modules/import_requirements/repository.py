from typing import List, Optional
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from sqlalchemy import or_
from modules.import_requirements.model import ImportRequirementAssessment


def generate_assessment_code(db: Session) -> str:
    year = datetime.now(timezone.utc).year
    prefix = f"BP011-{year}-"
    count = db.query(ImportRequirementAssessment).filter(
        ImportRequirementAssessment.assessment_code.like(f"{prefix}%")
    ).count()
    return f"{prefix}{count + 1:04d}"


def get_all_assessments(
    db: Session,
    import_file_id: Optional[int] = None,
    overall_status: Optional[str] = None,
    risk_level: Optional[str] = None,
    search: Optional[str] = None,
    include_inactive: bool = False,
) -> List[ImportRequirementAssessment]:
    query = db.query(ImportRequirementAssessment)
    if not include_inactive:
        query = query.filter(ImportRequirementAssessment.is_active == True)
    if import_file_id:
        query = query.filter(ImportRequirementAssessment.import_file_id == import_file_id)
    if overall_status and overall_status != "All":
        query = query.filter(ImportRequirementAssessment.overall_status == overall_status)
    if risk_level and risk_level != "All":
        query = query.filter(ImportRequirementAssessment.risk_level == risk_level)
    if search and search.strip():
        term = f"%{search.strip()}%"
        query = query.filter(
            or_(
                ImportRequirementAssessment.assessment_code.ilike(term),
                ImportRequirementAssessment.import_file_code.ilike(term),
                ImportRequirementAssessment.hs_code.ilike(term),
                ImportRequirementAssessment.commodity_description.ilike(term),
                ImportRequirementAssessment.country_of_origin.ilike(term),
            )
        )
    return query.order_by(ImportRequirementAssessment.assessment_id.desc()).all()


def get_assessment_by_id(db: Session, assessment_id: int) -> Optional[ImportRequirementAssessment]:
    return db.query(ImportRequirementAssessment).filter(
        ImportRequirementAssessment.assessment_id == assessment_id,
        ImportRequirementAssessment.is_active == True
    ).first()


def create_assessment(db: Session, obj_data: dict) -> ImportRequirementAssessment:
    obj = ImportRequirementAssessment(**obj_data)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def update_assessment(db: Session, assessment_id: int, update_data: dict) -> Optional[ImportRequirementAssessment]:
    obj = get_assessment_by_id(db, assessment_id)
    if not obj:
        return None
    for key, value in update_data.items():
        if hasattr(obj, key):
            setattr(obj, key, value)
    obj.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(obj)
    return obj


def soft_delete_assessment(db: Session, assessment_id: int) -> bool:
    obj = get_assessment_by_id(db, assessment_id)
    if not obj:
        return False
    obj.is_active = False
    obj.updated_at = datetime.now(timezone.utc)
    db.commit()
    return True
