from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from database.database import get_db
from modules.cbm_calculator.schemas import (
    CBMCalculationCreate,
    CBMCalculationResponse,
    CBMCalculationUpdate,
    CBMQuickCalcRequest,
    CBMQuickCalcResponse,
    LinkToPORequest,
)
from modules.cbm_calculator.service import CBMService

router = APIRouter(prefix="/api/v1/cbm-calculator", tags=["Cargo Measurement Engine & CBM Calculator"])


@router.post("/quick-calculate", response_model=CBMQuickCalcResponse, status_code=status.HTTP_200_OK)
def quick_calculate_cbm(payload: CBMQuickCalcRequest):
    """
    Perform instant standalone calculation without persisting to database.
    """
    return CBMService.quick_calculate(payload)


@router.post("", response_model=CBMCalculationResponse, status_code=status.HTTP_201_CREATED)
def create_cbm_calculation(
    payload: CBMCalculationCreate, db: Session = Depends(get_db)
):
    """
    Create and save a new CBM calculation session (Standalone or linked to PO/Project).
    """
    return CBMService.create_calculation_service(db, payload)


@router.get("", response_model=List[CBMCalculationResponse])
def list_cbm_calculations(
    include_inactive: bool = Query(False, description="Include soft-deleted calculations"),
    project_id: Optional[int] = Query(None, description="Filter by Project ID"),
    po_id: Optional[int] = Query(None, description="Filter by Purchase Order ID"),
    search: Optional[str] = Query(None, description="Search term for code, title, or notes"),
    db: Session = Depends(get_db),
):
    """
    Retrieve stored CBM calculation history logs with optional search & filters.
    """
    return CBMService.list_calculations_service(
        db,
        include_inactive=include_inactive,
        project_id=project_id,
        po_id=po_id,
        search=search,
    )


@router.get("/{calc_id}", response_model=CBMCalculationResponse)
def get_cbm_calculation(calc_id: int, db: Session = Depends(get_db)):
    """
    Get detailed information and items for a specific calculation session.
    """
    return CBMService.get_calculation_service(db, calc_id)


@router.put("/{calc_id}", response_model=CBMCalculationResponse)
def update_cbm_calculation(
    calc_id: int, payload: CBMCalculationUpdate, db: Session = Depends(get_db)
):
    """
    Update items, dimensions, or title/notes of a saved calculation session.
    """
    return CBMService.update_calculation_service(db, calc_id, payload)


@router.post("/{calc_id}/link", response_model=CBMCalculationResponse)
def link_calculation_to_po(
    calc_id: int, payload: LinkToPORequest, db: Session = Depends(get_db)
):
    """
    Link or assign a saved calculation record to a Purchase Order or Project.
    """
    return CBMService.link_to_po_service(
        db, calc_id, po_id=payload.po_id, project_id=payload.project_id
    )


@router.delete("/{calc_id}", status_code=status.HTTP_200_OK)
def soft_delete_cbm_calculation(calc_id: int, db: Session = Depends(get_db)):
    """
    Soft delete a CBM calculation record.
    """
    return CBMService.soft_delete_service(db, calc_id)


@router.post("/{calc_id}/restore", response_model=CBMCalculationResponse)
def restore_cbm_calculation(calc_id: int, db: Session = Depends(get_db)):
    """
    Restore a soft-deleted CBM calculation record.
    """
    return CBMService.restore_service(db, calc_id)
