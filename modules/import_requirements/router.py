from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database.database import get_db
from modules.import_requirements.schemas import (
    ImportRequirementCreate, ImportRequirementUpdate, ImportRequirementResponse
)
import modules.import_requirements.service as service
import modules.import_requirements.repository as repo

router = APIRouter(prefix="/api/v1/import-requirements", tags=["Import Requirements Assessment (BP-011)"])


@router.post("", response_model=ImportRequirementResponse, status_code=status.HTTP_201_CREATED,
    summary="Create a new Import Requirements Assessment (BP-011)")
def create_assessment(payload: ImportRequirementCreate, db: Session = Depends(get_db)):
    return service.create_assessment_service(db, payload)


@router.get("", response_model=List[ImportRequirementResponse],
    summary="List all Import Requirements Assessments")
def list_assessments(
    import_file_id: Optional[int] = None,
    overall_status: Optional[str] = None,
    risk_level: Optional[str] = None,
    search: Optional[str] = None,
    include_inactive: bool = False,
    db: Session = Depends(get_db),
):
    return repo.get_all_assessments(
        db, import_file_id=import_file_id, overall_status=overall_status,
        risk_level=risk_level, search=search, include_inactive=include_inactive
    )


@router.get("/{assessment_id}", response_model=ImportRequirementResponse,
    summary="Get a single Import Requirements Assessment by ID")
def get_assessment(assessment_id: int, db: Session = Depends(get_db)):
    obj = repo.get_assessment_by_id(db, assessment_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Assessment not found")
    return obj


@router.put("/{assessment_id}", response_model=ImportRequirementResponse,
    summary="Update an Import Requirements Assessment")
def update_assessment(assessment_id: int, payload: ImportRequirementUpdate, db: Session = Depends(get_db)):
    obj = service.update_assessment_service(db, assessment_id, payload)
    if not obj:
        raise HTTPException(status_code=404, detail="Assessment not found")
    return obj


@router.delete("/{assessment_id}", status_code=status.HTTP_204_NO_CONTENT,
    summary="Soft-delete an Import Requirements Assessment")
def delete_assessment(assessment_id: int, db: Session = Depends(get_db)):
    success = repo.soft_delete_assessment(db, assessment_id)
    if not success:
        raise HTTPException(status_code=404, detail="Assessment not found")
