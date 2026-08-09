from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from database.database import get_db
from .schemas import (
    WarehouseReceivingCreate,
    WarehouseReceivingUpdate,
    WarehouseReceivingResponse,
    DiscrepancyReportSubmit,
)
from .service import (
    create_warehouse_receiving_service,
    get_warehouse_receiving_service,
    list_warehouse_receivings_service,
    report_receiving_discrepancy_service,
    update_warehouse_receiving_service,
    soft_delete_warehouse_receiving_service,
)

router = APIRouter(prefix="/api/v1/warehouse-receiving", tags=["Phase 8 - Warehouse Receiving"])

@router.get("", response_model=List[WarehouseReceivingResponse])
def list_warehouse_receivings(
    include_inactive: bool = Query(False, description="Include soft-deleted records"),
    import_file_id: Optional[int] = Query(None, description="Filter by import file ID"),
    status_filter: Optional[str] = Query(None, alias="status", description="Filter by operational status"),
    search: Optional[str] = Query(None, description="Search term"),
    db: Session = Depends(get_db),
):
    return list_warehouse_receivings_service(db, include_inactive, import_file_id, status_filter, search)

@router.post("", response_model=WarehouseReceivingResponse, status_code=status.HTTP_201_CREATED)
def create_warehouse_receiving(
    schema: WarehouseReceivingCreate,
    db: Session = Depends(get_db),
):
    return create_warehouse_receiving_service(db, schema)

@router.get("/{record_id}", response_model=WarehouseReceivingResponse)
def get_warehouse_receiving(
    record_id: int,
    db: Session = Depends(get_db),
):
    return get_warehouse_receiving_service(db, record_id)

@router.put("/{record_id}", response_model=WarehouseReceivingResponse)
def update_warehouse_receiving(
    record_id: int,
    schema: WarehouseReceivingUpdate,
    db: Session = Depends(get_db),
):
    return update_warehouse_receiving_service(db, record_id, schema)

@router.post("/{record_id}/report-discrepancy", response_model=WarehouseReceivingResponse)
def report_receiving_discrepancy(
    record_id: int,
    payload: DiscrepancyReportSubmit,
    db: Session = Depends(get_db),
):
    return report_receiving_discrepancy_service(db, record_id, payload)

@router.delete("/{record_id}", status_code=status.HTTP_204_NO_CONTENT)
def soft_delete_warehouse_receiving(
    record_id: int,
    db: Session = Depends(get_db),
):
    soft_delete_warehouse_receiving_service(db, record_id)
    return None
