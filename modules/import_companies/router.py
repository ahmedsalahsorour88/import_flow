from fastapi import APIRouter
from fastapi import Depends
from fastapi import HTTPException

from sqlalchemy.orm import Session

from database.database import get_db

from .schemas import ImportCompanyCreate
from .schemas import ImportCompanyUpdate
from .schemas import ImportCompanyResponse

from .service import create_import_company
from .service import get_all_companies
from .service import get_company_by_id
from .service import update_import_company
from .service import delete_import_company
from .service import restore_import_company


# ==================================================
# Router
# ==================================================

import_router = APIRouter(
    prefix="/import-companies",
    tags=["Import Companies"]
)


# ==================================================
# Create Company
# ==================================================

@import_router.post(
    "/",
    response_model=ImportCompanyResponse
)
def create_company(
    company: ImportCompanyCreate,
    db: Session = Depends(get_db)
):

    return create_import_company(
        db,
        company
    )


# ==================================================
# Get Active Companies
# ==================================================

@import_router.get(
    "/",
    response_model=list[ImportCompanyResponse]
)
def get_companies(
    db: Session = Depends(get_db)
):

    return get_all_companies(
        db
    )


# ==================================================
# Get Company By ID
# ==================================================

@import_router.get(
    "/{company_id}",
    response_model=ImportCompanyResponse
)
def get_company(
    company_id: int,
    db: Session = Depends(get_db)
):

    company = get_company_by_id(
        db,
        company_id
    )

    if company is None:
        raise HTTPException(
            status_code=404,
            detail="Import Company not found"
        )

    return company


# ==================================================
# Update Company
# ==================================================

@import_router.put(
    "/{company_id}",
    response_model=ImportCompanyResponse
)
def update_company(
    company_id: int,
    company: ImportCompanyUpdate,
    db: Session = Depends(get_db)
):

    updated_company = update_import_company(
        db,
        company_id,
        company
    )

    if updated_company is None:
        raise HTTPException(
            status_code=404,
            detail="Import Company not found"
        )

    return updated_company


# ==================================================
# Soft Delete Company
# ==================================================

@import_router.delete(
    "/{company_id}",
    response_model=ImportCompanyResponse
)
def delete_company(
    company_id: int,
    db: Session = Depends(get_db)
):

    deleted_company = delete_import_company(
        db,
        company_id
    )

    if deleted_company is None:
        raise HTTPException(
            status_code=404,
            detail="Import Company not found"
        )

    return deleted_company


# ==================================================
# Restore Company
# ==================================================

@import_router.patch(
    "/{company_id}/restore",
    response_model=ImportCompanyResponse
)
def restore_company(
    company_id: int,
    db: Session = Depends(get_db)
):

    restored_company = restore_import_company(
        db,
        company_id
    )

    if restored_company is None:
        raise HTTPException(
            status_code=404,
            detail="Import Company not found"
        )

    return restored_company