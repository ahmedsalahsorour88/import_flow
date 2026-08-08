"""
Customs Consultation REST Router (BP-009)
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from database.database import get_db
from modules.customs_consultation.schemas import (
    CustomsConsultationCreate,
    CustomsConsultationUpdate,
    CustomsConsultationResponse,
)
from modules.customs_consultation.service import CustomsConsultationService

router = APIRouter(
    prefix="/api/v1/customs-consultations",
    tags=["Customs Consultation (BP-009)"],
)


@router.post(
    "",
    response_model=CustomsConsultationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new Customs Consultation study session (BP-009)",
)
def create_consultation(
    session_in: CustomsConsultationCreate,
    db: Session = Depends(get_db),
):
    return CustomsConsultationService.create_consultation(db, session_in)


@router.get(
    "",
    response_model=List[CustomsConsultationResponse],
    summary="List all Customs Consultation studies with filtering (BP-009)",
)
def list_consultations(
    include_inactive: bool = Query(False, description="Include soft-deleted studies"),
    search: Optional[str] = Query(None, description="Search by code, title, or broker name"),
    broker_id: Optional[int] = Query(None, description="Filter by Customs Broker ID"),
    import_file_id: Optional[int] = Query(None, description="Filter by Import File ID"),
    po_id: Optional[int] = Query(None, description="Filter by Purchase Order ID"),
    project_id: Optional[int] = Query(None, description="Filter by Project ID"),
    status: Optional[str] = Query(None, description="Filter by overall status"),
    db: Session = Depends(get_db),
):
    return CustomsConsultationService.list_consultations(
        db,
        include_inactive=include_inactive,
        search=search,
        broker_id=broker_id,
        import_file_id=import_file_id,
        po_id=po_id,
        project_id=project_id,
        status=status,
    )


@router.get(
    "/{consultation_id}",
    response_model=CustomsConsultationResponse,
    summary="Get Customs Consultation study by ID",
)
def get_consultation(
    consultation_id: int,
    db: Session = Depends(get_db),
):
    return CustomsConsultationService.get_consultation(db, consultation_id)


@router.put(
    "/{consultation_id}",
    response_model=CustomsConsultationResponse,
    summary="Update Customs Consultation study",
)
def update_consultation(
    consultation_id: int,
    update_in: CustomsConsultationUpdate,
    db: Session = Depends(get_db),
):
    return CustomsConsultationService.update_consultation(db, consultation_id, update_in)


@router.delete(
    "/{consultation_id}",
    response_model=CustomsConsultationResponse,
    summary="Soft delete Customs Consultation study",
)
def soft_delete_consultation(
    consultation_id: int,
    db: Session = Depends(get_db),
):
    return CustomsConsultationService.soft_delete_consultation(db, consultation_id)


@router.post(
    "/{consultation_id}/restore",
    response_model=CustomsConsultationResponse,
    summary="Restore soft-deleted Customs Consultation study",
)
def restore_consultation(
    consultation_id: int,
    db: Session = Depends(get_db),
):
    return CustomsConsultationService.restore_consultation(db, consultation_id)
