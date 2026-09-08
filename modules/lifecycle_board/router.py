"""
FastAPI Router for 6-Phase Lifecycle Board & Stage Transitions
"""

from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from database.database import get_db
from modules.lifecycle_board.schemas import (
    LifecycleBoardSummaryResponse,
    LiveLogisticsSummaryResponse,
    StageActivityResponse,
    StepAdvancePayload,
    SkipStepPayload,
    MultiStageSetPayload,
    LifecycleSyncRequest,
)
import modules.lifecycle_board.service as service

router = APIRouter(prefix="/api/v1/lifecycle-board", tags=["Shipment Lifecycle Board (6 Phases / 21 Steps)"])


@router.get(
    "/summary",
    response_model=LifecycleBoardSummaryResponse,
    summary="Get 6-phase board summary with active shipment cards and phase counts",
)
def get_board_summary(db: Session = Depends(get_db)):
    return service.get_board_summary_service(db)


@router.get(
    "/live-tracking",
    response_model=LiveLogisticsSummaryResponse,
    summary="Get aggregated live logistics tracking intelligence (ETA, Demurrage Risk, Samples, Document Completeness)",
)
def get_live_logistics_tracking(db: Session = Depends(get_db)):
    return service.get_live_logistics_tracking_service(db)


@router.get(
    "/shipments/{import_file_code}/stages",
    response_model=List[StageActivityResponse],
    summary="Get all stage activities for a specific shipment",
)
def get_shipment_stages(import_file_code: str, db: Session = Depends(get_db)):
    return service.get_all_activities_service(db, import_file_code=import_file_code)


@router.post(
    "/stages/advance",
    status_code=status.HTTP_200_OK,
    summary="Mark step completed and advance to next target step(s)",
)
def advance_step(payload: StepAdvancePayload, db: Session = Depends(get_db)):
    return service.advance_step_service(db, payload)


@router.post(
    "/stages/sync",
    status_code=status.HTTP_200_OK,
    summary="Generic centralized lifecycle synchronization engine for all 21 operational steps",
)
def sync_lifecycle_step(payload: LifecycleSyncRequest, db: Session = Depends(get_db)):
    return service.advance_lifecycle_step_service(
        db=db,
        completed_step_code=payload.completed_step_code,
        import_file_code=payload.import_file_code,
        import_file_id=payload.import_file_id,
        target_step_codes=payload.target_step_codes,
        auto_complete_prior=payload.auto_complete_prior,
        assigned_user=payload.assigned_user,
        action_data=payload.action_data,
        notes=payload.notes,
        source_module=payload.source_module,
    )



@router.post(
    "/stages/skip",
    status_code=status.HTTP_200_OK,
    summary="Skip an operational step and activate next step(s) without disrupting workflow",
)
def skip_step(payload: SkipStepPayload, db: Session = Depends(get_db)):
    return service.skip_step_service(db, payload)


@router.post(
    "/stages/set-active",
    status_code=status.HTTP_200_OK,
    summary="Set concurrent active stages for a shipment",
)
def set_multi_active_stages(payload: MultiStageSetPayload, db: Session = Depends(get_db)):
    return service.set_multi_active_stages_service(db, payload)

