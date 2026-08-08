from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from database.database import get_db
from .schemas import SupplierCreate, SupplierUpdate, SupplierResponse
from .service import (
    create_supplier_service,
    get_all_suppliers_service,
    get_all_suppliers_admin_service,
    get_supplier_by_id_service,
    update_supplier_service,
    delete_supplier_service,
    restore_supplier_service,
)

# ==================================================
# Router Setup
# ==================================================

supplier_router = APIRouter(
    prefix="/api/v1/suppliers",
    tags=["Suppliers & Foreign Exporters"]
)


# ==================================================
# Create Supplier Endpoint
# ==================================================

@supplier_router.post(
    "",
    response_model=SupplierResponse,
    status_code=status.HTTP_201_CREATED
)
def create_supplier(supplier: SupplierCreate, db: Session = Depends(get_db)):
    created = create_supplier_service(db, supplier)
    if not created:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Foreign Exporter ID '{supplier.foreign_exporter_id}' already exists."
        )
    return created


# ==================================================
# Get All Suppliers (Active or All) Endpoint
# ==================================================

@supplier_router.get(
    "",
    response_model=list[SupplierResponse]
)
def get_suppliers(include_inactive: bool = False, db: Session = Depends(get_db)):
    if include_inactive:
        return get_all_suppliers_admin_service(db)
    return get_all_suppliers_service(db)


# ==================================================
# Get Supplier By ID Endpoint
# ==================================================

@supplier_router.get(
    "/{supplier_id}",
    response_model=SupplierResponse
)
def get_supplier_by_id(supplier_id: int, db: Session = Depends(get_db)):
    supplier = get_supplier_by_id_service(db, supplier_id)
    if not supplier:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Supplier with ID {supplier_id} not found."
        )
    return supplier


# ==================================================
# Update Supplier Endpoint
# ==================================================

@supplier_router.put(
    "/{supplier_id}",
    response_model=SupplierResponse
)
def update_supplier(
    supplier_id: int,
    supplier_data: SupplierUpdate,
    db: Session = Depends(get_db)
):
    updated = update_supplier_service(db, supplier_id, supplier_data)
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Supplier with ID {supplier_id} not found."
        )
    return updated


# ==================================================
# Soft Delete Supplier Endpoint
# ==================================================

@supplier_router.delete(
    "/{supplier_id}",
    response_model=SupplierResponse
)
def delete_supplier(supplier_id: int, db: Session = Depends(get_db)):
    deleted = delete_supplier_service(db, supplier_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Supplier with ID {supplier_id} not found."
        )
    return deleted


# ==================================================
# Restore Supplier Endpoint
# ==================================================

@supplier_router.patch(
    "/{supplier_id}/restore",
    response_model=SupplierResponse
)
def restore_supplier(supplier_id: int, db: Session = Depends(get_db)):
    restored = restore_supplier_service(db, supplier_id)
    if not restored:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Supplier with ID {supplier_id} not found."
        )
    return restored