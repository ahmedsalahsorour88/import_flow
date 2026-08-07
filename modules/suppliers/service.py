from sqlalchemy.orm import Session

from modules.suppliers.model import Supplier

from .schemas import SupplierCreate
from .schemas import SupplierUpdate

from .repository import create_supplier
from .repository import get_all_suppliers
from .repository import get_supplier_by_id
from .repository import get_supplier_by_exporter_id
from .repository import update_supplier
from .repository import soft_delete_supplier
from .repository import restore_supplier


# ==================================================
# Generate Supplier Code
# ==================================================

def generate_supplier_code(
    db: Session
) -> str:

    last_supplier = (
        db.query(Supplier)
        .order_by(Supplier.supplier_id.desc())
        .first()
    )

    if not last_supplier:
        return "SUP-000001"

    next_id = last_supplier.supplier_id + 1

    return f"SUP-{next_id:06d}"



# ==================================================
# Create Supplier Service
# ==================================================

def create_supplier_service(
    db: Session,
    supplier_data: SupplierCreate
):

    # Check duplicate exporter ID

    existing_supplier = get_supplier_by_exporter_id(
        db,
        supplier_data.foreign_exporter_id
    )


    if existing_supplier:

        return None


    # Generate Supplier Code Automatically

    supplier_code = generate_supplier_code(db)


    supplier_dict = supplier_data.model_dump()

    supplier_dict["supplier_code"] = supplier_code


    return create_supplier(
        db,
        supplier_dict
    )



# ==================================================
# Get All Suppliers Service
# ==================================================

def get_all_suppliers_service(
    db: Session,
    skip: int = 0,
    limit: int = 50
):

    return get_all_suppliers(
        db,
        skip,
        limit
    )



# ==================================================
# Get Supplier By ID Service
# ==================================================

def get_supplier_by_id_service(
    db: Session,
    supplier_id: int
):

    return get_supplier_by_id(
        db,
        supplier_id
    )



# ==================================================
# Update Supplier Service
# ==================================================

def update_supplier_service(
    db: Session,
    supplier_id: int,
    supplier_data: SupplierUpdate
):

    supplier = get_supplier_by_id(
        db,
        supplier_id
    )


    if not supplier:

        return None


    return update_supplier(
        db,
        supplier,
        supplier_data
    )



# ==================================================
# Delete Supplier Service
# ==================================================

def delete_supplier_service(
    db: Session,
    supplier_id: int
):

    supplier = get_supplier_by_id(
        db,
        supplier_id
    )


    if not supplier:

        return None


    return soft_delete_supplier(
        db,
        supplier
    )



# ==================================================
# Restore Supplier Service
# ==================================================

def restore_supplier_service(
    db: Session,
    supplier_id: int
):

    supplier = get_supplier_by_id(
        db,
        supplier_id
    )


    if not supplier:

        return None


    return restore_supplier(
        db,
        supplier
    )