from fastapi import APIRouter
from fastapi import Depends
from fastapi import HTTPException
from fastapi import status

from sqlalchemy.orm import Session

from database.database import get_db

from .schemas import SupplierCreate
from .schemas import SupplierUpdate
from .schemas import SupplierResponse

from .service import create_supplier_service
from .service import get_all_suppliers_service
from .service import get_supplier_by_id_service
from .service import update_supplier_service
from .service import delete_supplier_service
from .service import restore_supplier_service



# ==================================================
# Router
# ==================================================

supplier_router = APIRouter(
    prefix="/suppliers",
    tags=["Suppliers"]
)



# ==================================================
# Create Supplier
# ==================================================

@supplier_router.post(
    "/",
    response_model=SupplierResponse,
    status_code=status.HTTP_201_CREATED
)
def create_supplier(
    supplier: SupplierCreate,
    db: Session = Depends(get_db)
):

    new_supplier = create_supplier_service(
        db,
        supplier
    )


    if not new_supplier:

        raise HTTPException(
            status_code=400,
            detail="Supplier already exists"
        )


    return new_supplier



# ==================================================
# Get All Suppliers
# ==================================================

@supplier_router.get(
    "/",
    response_model=list[SupplierResponse]
)
def get_suppliers(
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db)
):

    return get_all_suppliers_service(
        db,
        skip,
        limit
    )



# ==================================================
# Get Supplier By ID
# ==================================================

@supplier_router.get(
    "/{supplier_id}",
    response_model=SupplierResponse
)
def get_supplier(
    supplier_id: int,
    db: Session = Depends(get_db)
):

    supplier = get_supplier_by_id_service(
        db,
        supplier_id
    )


    if not supplier:

        raise HTTPException(
            status_code=404,
            detail="Supplier not found"
        )


    return supplier



# ==================================================
# Update Supplier
# ==================================================

@supplier_router.put(
    "/{supplier_id}",
    response_model=SupplierResponse
)
def update_supplier(
    supplier_id: int,
    supplier: SupplierUpdate,
    db: Session = Depends(get_db)
):

    updated_supplier = update_supplier_service(
        db,
        supplier_id,
        supplier
    )


    if not updated_supplier:

        raise HTTPException(
            status_code=404,
            detail="Supplier not found"
        )


    return updated_supplier



# ==================================================
# Soft Delete Supplier
# ==================================================

@supplier_router.delete(
    "/{supplier_id}",
    response_model=SupplierResponse
)
def delete_supplier(
    supplier_id: int,
    db: Session = Depends(get_db)
):

    supplier = delete_supplier_service(
        db,
        supplier_id
    )


    if not supplier:

        raise HTTPException(
            status_code=404,
            detail="Supplier not found"
        )


    return supplier



# ==================================================
# Restore Supplier
# ==================================================

@supplier_router.patch(
    "/{supplier_id}/restore",
    response_model=SupplierResponse
)
def restore_supplier(
    supplier_id: int,
    db: Session = Depends(get_db)
):

    supplier = restore_supplier_service(
        db,
        supplier_id
    )


    if not supplier:

        raise HTTPException(
            status_code=404,
            detail="Supplier not found"
        )


    return supplier