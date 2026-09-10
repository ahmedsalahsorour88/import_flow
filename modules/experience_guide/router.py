"""
FastAPI Router for Smart Shipment Experience Guide (KB-GUIDE-012)
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from database.database import get_db
from modules.experience_guide.schemas import (
    GuideEntryCreate,
    GuideEntryUpdate,
    GuideEntryResponse,
    GuideMatchRequest,
    GuideMatchResponse,
    SmartReferenceCardResponse,
)
from modules.experience_guide.service import ExperienceGuideService

router = APIRouter(
    prefix="/api/v1/experience-guide",
    tags=["Experience Guide & Smart Reference Card (KB-GUIDE-012)"],
)


@router.get("", response_model=List[GuideEntryResponse], summary="List experience guide entries")
def list_guide_entries(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    search: Optional[str] = Query(None, description="Search in title or content"),
    scope_type: Optional[str] = Query(None, description="Filter by scope_type"),
    scope_value: Optional[str] = Query(None, description="Filter by scope_value"),
    is_active: Optional[bool] = Query(True, description="Filter by active status"),
    db: Session = Depends(get_db),
):
    service = ExperienceGuideService(db)
    return service.list_entries(
        skip=skip,
        limit=limit,
        search=search,
        scope_type=scope_type,
        scope_value=scope_value,
        is_active=is_active,
    )


@router.post("", response_model=GuideEntryResponse, status_code=status.HTTP_201_CREATED, summary="Create new guide entry with scopes")
def create_guide_entry(
    payload: GuideEntryCreate,
    db: Session = Depends(get_db),
):
    service = ExperienceGuideService(db)
    return service.create_entry(payload)


@router.get("/{entry_id}", response_model=GuideEntryResponse, summary="Get single guide entry by ID")
def get_guide_entry(
    entry_id: int,
    db: Session = Depends(get_db),
):
    service = ExperienceGuideService(db)
    return service.get_entry(entry_id)


@router.put("/{entry_id}", response_model=GuideEntryResponse, summary="Update existing guide entry")
def update_guide_entry(
    entry_id: int,
    payload: GuideEntryUpdate,
    db: Session = Depends(get_db),
):
    service = ExperienceGuideService(db)
    return service.update_entry(entry_id, payload)


@router.delete("/{entry_id}", summary="Deactivate/delete guide entry")
def delete_guide_entry(
    entry_id: int,
    db: Session = Depends(get_db),
):
    service = ExperienceGuideService(db)
    service.delete_entry(entry_id)
    return {"message": "Guide entry deactivated successfully", "entry_id": entry_id}


@router.post("/match", response_model=GuideMatchResponse, summary="Match shipment against guide entries")
def match_shipment_against_guide(
    payload: GuideMatchRequest,
    db: Session = Depends(get_db),
):
    service = ExperienceGuideService(db)
    return service.match_shipment(payload)


@router.get("/reference-card/{import_file_id}", response_model=SmartReferenceCardResponse, summary="Get dynamic smart reference card for shipment")
def get_smart_reference_card(
    import_file_id: int,
    db: Session = Depends(get_db),
):
    service = ExperienceGuideService(db)
    return service.generate_smart_reference_card(import_file_id)
