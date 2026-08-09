from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from database.database import get_db
from .schemas import (
    FileClosureCreate,
    FileClosureUpdate,
    FileClosureResponse,
)
from .service import (
    close_import_file_service,
    get_closure_service,
    list_closures_service,
    update_closure_service,
    soft_delete_closure_service,
)

router = APIRouter(prefix="/api/v1/file-closure", tags=["Phase 10 - Import File Closure & Historical Archival"])

@router.get("", response_model=List[FileClosureResponse])
def list_closures(
    include_inactive: bool = Query(False, description="Include soft-deleted records"),
    import_file_id: Optional[int] = Query(None, description="Filter by import file ID"),
    search: Optional[str] = Query(None, description="Search term"),
    db: Session = Depends(get_db),
):
    return list_closures_service(db, include_inactive, import_file_id, search)

@router.post("", response_model=FileClosureResponse, status_code=status.HTTP_201_CREATED)
def close_import_file(
    schema: FileClosureCreate,
    db: Session = Depends(get_db),
):
    return close_import_file_service(db, schema)

@router.get("/{closure_id}", response_model=FileClosureResponse)
def get_closure(
    closure_id: int,
    db: Session = Depends(get_db),
):
    return get_closure_service(db, closure_id)

@router.put("/{closure_id}", response_model=FileClosureResponse)
def update_closure(
    closure_id: int,
    schema: FileClosureUpdate,
    db: Session = Depends(get_db),
):
    return update_closure_service(db, closure_id, schema)

@router.delete("/{closure_id}", status_code=status.HTTP_204_NO_CONTENT)
def soft_delete_closure(
    closure_id: int,
    db: Session = Depends(get_db),
):
    soft_delete_closure_service(db, closure_id)
    return None
