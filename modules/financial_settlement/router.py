from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from database.database import get_db
from .schemas import (
    FinancialSettlementCreate,
    FinancialSettlementUpdate,
    FinancialSettlementResponse,
)
from .service import (
    create_settlement_service,
    recalculate_settlement_service,
    update_settlement_service,
    get_settlement_service,
    list_settlements_service,
    soft_delete_settlement_service,
)

router = APIRouter(prefix="/api/v1/financial-settlement", tags=["Phase 9 - Financial Settlement & Landed Cost"])

@router.get("", response_model=List[FinancialSettlementResponse])
def list_settlements(
    include_inactive: bool = Query(False, description="Include soft-deleted records"),
    import_file_id: Optional[int] = Query(None, description="Filter by import file ID"),
    status_filter: Optional[str] = Query(None, alias="status", description="Filter by operational status"),
    search: Optional[str] = Query(None, description="Search term"),
    db: Session = Depends(get_db),
):
    return list_settlements_service(db, include_inactive, import_file_id, status_filter, search)

@router.post("", response_model=FinancialSettlementResponse, status_code=status.HTTP_201_CREATED)
def create_settlement(
    schema: FinancialSettlementCreate,
    db: Session = Depends(get_db),
):
    return create_settlement_service(db, schema)

@router.get("/{settlement_id}", response_model=FinancialSettlementResponse)
def get_settlement(
    settlement_id: int,
    db: Session = Depends(get_db),
):
    return get_settlement_service(db, settlement_id)

@router.put("/{settlement_id}", response_model=FinancialSettlementResponse)
def update_settlement(
    settlement_id: int,
    schema: FinancialSettlementUpdate,
    db: Session = Depends(get_db),
):
    return update_settlement_service(db, settlement_id, schema)

@router.post("/{settlement_id}/recalculate", response_model=FinancialSettlementResponse)
def recalculate_settlement(
    settlement_id: int,
    db: Session = Depends(get_db),
):
    return recalculate_settlement_service(db, settlement_id)

@router.delete("/{settlement_id}", status_code=status.HTTP_204_NO_CONTENT)
def soft_delete_settlement(
    settlement_id: int,
    db: Session = Depends(get_db),
):
    soft_delete_settlement_service(db, settlement_id)
    return None
