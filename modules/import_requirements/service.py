from datetime import datetime, timezone
from sqlalchemy.orm import Session
from modules.import_requirements.schemas import ImportRequirementCreate, ImportRequirementUpdate
from modules.import_requirements import repository as repo
from modules.import_requirements.validators import validate_risk_level, validate_overall_status, validate_shipment_value


def create_assessment_service(db: Session, payload: ImportRequirementCreate):
    validate_risk_level(payload.risk_level)
    validate_overall_status(payload.overall_status)
    validate_shipment_value(payload.shipment_value_usd)
    
    code = repo.generate_assessment_code(db)
    obj_data = payload.model_dump()
    obj_data["assessment_code"] = code
    obj_data["created_at"] = datetime.now(timezone.utc)
    obj_data["updated_at"] = datetime.now(timezone.utc)
    return repo.create_assessment(db, obj_data)


def update_assessment_service(db: Session, assessment_id: int, payload: ImportRequirementUpdate):
    update_data = {k: v for k, v in payload.model_dump().items() if v is not None}
    if "risk_level" in update_data:
        validate_risk_level(update_data["risk_level"])
    if "overall_status" in update_data:
        validate_overall_status(update_data["overall_status"])
    if "shipment_value_usd" in update_data:
        validate_shipment_value(update_data["shipment_value_usd"])
    update_data["updated_at"] = datetime.now(timezone.utc)
    return repo.update_assessment(db, assessment_id, update_data)
