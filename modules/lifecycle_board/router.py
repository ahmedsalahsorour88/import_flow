"""
FastAPI Router for 6-Phase Lifecycle Board & Stage Transitions
"""

from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from database.database import get_db
from modules.lifecycle_board.schemas import (
    LifecycleBoardSummaryResponse,
    StageActivityResponse,
    StepAdvancePayload,
    MultiStageSetPayload,
)
import modules.lifecycle_board.service as service
import modules.lifecycle_board.repository as repo

router = APIRouter(prefix="/api/v1/lifecycle-board", tags=["Shipment Lifecycle Board (6 Phases / 21 Steps)"])


@router.get(
    "/summary",
    response_model=LifecycleBoardSummaryResponse,
    summary="Get 6-phase board summary with active shipment cards and phase counts",
)
def get_board_summary(db: Session = Depends(get_db)):
    return service.get_board_summary_service(db)


@router.get(
    "/shipments/{import_file_code}/stages",
    response_model=List[StageActivityResponse],
    summary="Get all stage activities for a specific shipment",
)
def get_shipment_stages(import_file_code: str, db: Session = Depends(get_db)):
    return repo.get_all_activities(db, import_file_code=import_file_code)


@router.post(
    "/stages/advance",
    status_code=status.HTTP_200_OK,
    summary="Mark step completed and advance to next target step(s)",
)
def advance_step(payload: StepAdvancePayload, db: Session = Depends(get_db)):
    return service.advance_step_service(db, payload)


@router.post(
    "/stages/set-active",
    status_code=status.HTTP_200_OK,
    summary="Set concurrent active stages for a shipment",
)
def set_multi_active_stages(payload: MultiStageSetPayload, db: Session = Depends(get_db)):
    return service.set_multi_active_stages_service(db, payload)
