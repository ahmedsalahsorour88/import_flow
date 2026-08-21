from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query, Response
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
import io

from database.database import get_db
from .service import OriginalDocumentsCollectionService
from .schemas import (
    OriginalDocumentsCollectionCreate,
    OriginalDocumentsCollectionUpdate,
    OriginalDocumentsCollectionResponse,
    OriginalDocumentsAutoPopulateResponse,
)

router = APIRouter(
    prefix="/api/v1/original-documents-collection",
    tags=["Physical Original Documents Collection & Courier Tracking (BP-026 / DOC-ORIG-001)"],
)


@router.get(
    "/auto-populate/{import_file_id}",
    response_model=OriginalDocumentsAutoPopulateResponse,
    status_code=status.HTTP_200_OK,
)
def auto_populate_documents(
    import_file_id: int,
    db: Session = Depends(get_db),
):
    """
    Auto-populates the required original documents matrix and couriers from Central Archive & Import File.
    """
    return OriginalDocumentsCollectionService.auto_populate_from_central_archive(db, import_file_id)


@router.post(
    "/sessions",
    response_model=OriginalDocumentsCollectionResponse,
    status_code=status.HTTP_200_OK,
)
def save_or_upsert_session(
    payload: OriginalDocumentsCollectionCreate,
    db: Session = Depends(get_db),
):
    """
    Saves (as Draft or Final) or Upserts an original documents collection & multi-courier session.
    """
    return OriginalDocumentsCollectionService.save_or_upsert_collection_session(db, payload)


@router.get(
    "/sessions/by-file/{import_file_id}",
    response_model=Optional[OriginalDocumentsCollectionResponse],
    status_code=status.HTTP_200_OK,
)
def get_session_by_file(
    import_file_id: int,
    db: Session = Depends(get_db),
):
    """
    Retrieves the collection session for a specific Import File ID.
    """
    return OriginalDocumentsCollectionService.get_session_by_file(db, import_file_id)


@router.get(
    "/sessions/{collection_id}",
    response_model=OriginalDocumentsCollectionResponse,
    status_code=status.HTTP_200_OK,
)
def get_session_by_id(
    collection_id: int,
    db: Session = Depends(get_db),
):
    """
    Retrieves a collection session by its Primary Key ID.
    """
    return OriginalDocumentsCollectionService.get_session_by_id(db, collection_id)


@router.get(
    "/sessions",
    response_model=List[OriginalDocumentsCollectionResponse],
    status_code=status.HTTP_200_OK,
)
def list_sessions(
    include_inactive: bool = False,
    status: Optional[str] = None,
    search: Optional[str] = None,
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """
    Lists all original documents collection sessions with status and search filtering.
    """
    return OriginalDocumentsCollectionService.list_sessions(
        db,
        include_inactive=include_inactive,
        status=status,
        search=search,
        limit=limit,
        offset=offset,
    )


@router.get(
    "/export/excel/{import_file_id_or_session_id}",
    status_code=status.HTTP_200_OK,
)
def export_excel(
    import_file_id_or_session_id: int,
    db: Session = Depends(get_db),
):
    """
    Generates and downloads a formatted Excel (.xlsx) collection sheet.
    """
    excel_bytes = OriginalDocumentsCollectionService.export_collection_to_excel_bytes(
        db, import_file_id_or_session_id
    )
    return StreamingResponse(
        io.BytesIO(excel_bytes),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={
            "Content-Disposition": f"attachment; filename=Original_Documents_Collection_{import_file_id_or_session_id}.xlsx"
        },
    )
