"""
FastAPI Router for Import Files Master & Tracking Module
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from database.database import get_db
from modules.import_files.schemas import (
    ImportFileCreate,
    ImportFileUpdate,
    ImportFileResponse,
    PaginatedImportFilesResponse,
    ImportMasterReportSummary,
    OperationalDashboardResponse,
    CloseShipmentSubmit,
    ReopenShipmentSubmit,
)
import modules.import_files.service as service
import modules.import_files.repository as repo

router = APIRouter(prefix="/api/v1/import-files", tags=["Import Files Tracking"])


@router.post(
    "",
    response_model=ImportFileResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new Import File / Case Tracking record",
)
def create_import_file(payload: ImportFileCreate, db: Session = Depends(get_db)):
    return service.create_import_file_service(db, payload)


@router.get(
    "",
    response_model=List[ImportFileResponse],
    summary="List all import files with filters",
)
def list_import_files(
    include_inactive: bool = False,
    search: Optional[str] = None,
    company_id: Optional[int] = None,
    supplier_id: Optional[int] = None,
    status: Optional[str] = None,
    owner: Optional[str] = None,
    db: Session = Depends(get_db),
):
    return repo.get_all_import_files(
        db,
        include_inactive=include_inactive,
        search=search,
        company_id=company_id,
        supplier_id=supplier_id,
        status=status,
        owner=owner,
    )


@router.get(
    "/paginated",
    response_model=PaginatedImportFilesResponse,
    summary="List paginated import files with filters",
)
def list_paginated_import_files(
    page: int = 1,
    page_size: int = 50,
    include_inactive: bool = False,
    search: Optional[str] = None,
    company_id: Optional[int] = None,
    supplier_id: Optional[int] = None,
    status: Optional[str] = None,
    owner: Optional[str] = None,
    db: Session = Depends(get_db),
):
    return repo.get_paginated_import_files(
        db,
        include_inactive=include_inactive,
        search=search,
        company_id=company_id,
        supplier_id=supplier_id,
        status=status,
        owner=owner,
        page=page,
        page_size=page_size,
    )


@router.get(
    "/report/master",
    response_model=ImportMasterReportSummary,
    summary="Extract & summary report for all import files",
)
def get_master_report(
    company_id: Optional[int] = None,
    supplier_id: Optional[int] = None,
    status: Optional[str] = None,
    owner: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
):
    return service.generate_master_report_service(
        db,
        company_id=company_id,
        supplier_id=supplier_id,
        status=status,
        owner=owner,
        search=search,
    )


@router.get(
    "/operational-dashboard",
    response_model=OperationalDashboardResponse,
    summary="Operational Dashboard multi-criteria AND filtering",
)
def get_operational_dashboard(
    phase: Optional[str] = None,
    priority: Optional[str] = None,
    broker_id: Optional[int] = None,
    broker_name: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
):
    return repo.get_operational_dashboard_data(
        db,
        phase=phase,
        priority=priority,
        broker_id=broker_id,
        broker_name=broker_name,
        search=search,
    )


@router.get(
    "/{import_file_id}",
    response_model=ImportFileResponse,
    summary="Get single import file by ID or custom file number",
)
def get_import_file(import_file_id: str, db: Session = Depends(get_db)):
    if import_file_id.isdigit():
        item = repo.get_import_file_by_id(db, int(import_file_id))
    else:
        item = repo.get_import_file_by_code(db, import_file_id)

    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"ملف الاستيراد '{import_file_id}' غير موجود.",
        )
    return item


@router.put(
    "/{import_file_id}",
    response_model=ImportFileResponse,
    summary="Update import file record",
)
def update_import_file(
    import_file_id: int, payload: ImportFileUpdate, db: Session = Depends(get_db)
):
    return service.update_import_file_service(db, import_file_id, payload)


@router.delete(
    "/{import_file_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Soft delete an import file",
)
def soft_delete_import_file(import_file_id: int, db: Session = Depends(get_db)):
    success = repo.soft_delete_import_file(db, import_file_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"ملف الاستيراد '{import_file_id}' غير موجود.",
        )


@router.post(
    "/{import_file_id}/close-shipment",
    response_model=ImportFileResponse,
    summary="Early close and terminate shipment at current phase with reason notes",
)
def close_shipment(
    import_file_id: int,
    payload: CloseShipmentSubmit,
    db: Session = Depends(get_db),
):
    return service.close_shipment_service(db, import_file_id, payload)


@router.post(
    "/{import_file_id}/reopen-shipment",
    response_model=ImportFileResponse,
    summary="Reopen closed shipment and restore to its original phase with reason notes",
)
def reopen_shipment(
    import_file_id: int,
    payload: ReopenShipmentSubmit,
    db: Session = Depends(get_db),
):
    return service.reopen_shipment_service(db, import_file_id, payload)
