from sqlalchemy.orm import Session

from .model import Supplier
from .schemas import SupplierCreate, SupplierUpdate
from .repository import (
    create_supplier,
    get_active_suppliers,
    get_all_suppliers_admin,
    get_supplier_by_id,
    get_supplier_by_exporter_id,
    count_suppliers,
    update_supplier,
    soft_delete_supplier,
    restore_supplier,
)


# ==================================================
# Generate Supplier Code (e.g. SUP-000001)
# ==================================================

def generate_supplier_code(db: Session) -> str:
    total = count_suppliers(db)
    next_id = total + 1
    return f"SUP-{next_id:06d}"


# ==================================================
# Create Supplier Service
# ==================================================

def create_supplier_service(db: Session, supplier_data: SupplierCreate) -> Supplier:
    from .validators import validate_supplier
    validate_supplier(db, supplier_data)

    code = getattr(supplier_data, "supplier_code", None) or generate_supplier_code(db)
    exporter_id = (supplier_data.foreign_exporter_id or "").strip()
    if not exporter_id:
        exporter_id = f"EXP-{code}"
        supplier_data.foreign_exporter_id = exporter_id

    supplier_dict = supplier_data.model_dump()
    supplier_dict["supplier_code"] = code

    return create_supplier(db, supplier_dict)



# ==================================================
# Get All Active Suppliers Service
# ==================================================

def get_all_suppliers_service(db: Session) -> list[Supplier]:
    return get_active_suppliers(db)


# ==================================================
# Get All Suppliers Admin Service (Active & Inactive)
# ==================================================

def get_all_suppliers_admin_service(db: Session) -> list[Supplier]:
    return get_all_suppliers_admin(db)


# ==================================================
# Get Supplier By ID Service
# ==================================================

def get_supplier_by_id_service(db: Session, supplier_id: int) -> Supplier | None:
    return get_supplier_by_id(db, supplier_id)


# ==================================================
# Update Supplier Service
# ==================================================

def update_supplier_service(
    db: Session,
    supplier_id: int,
    supplier_data: SupplierUpdate
) -> Supplier | None:
    supplier = get_supplier_by_id(db, supplier_id)
    if not supplier:
        return None
    return update_supplier(db, supplier, supplier_data)


# ==================================================
# Delete Supplier Service
# ==================================================

def delete_supplier_service(db: Session, supplier_id: int) -> Supplier | None:
    supplier = get_supplier_by_id(db, supplier_id)
    if not supplier:
        return None
    if not supplier.is_active:
        return supplier
    return soft_delete_supplier(db, supplier)


# ==================================================
# Restore Supplier Service
# ==================================================

def restore_supplier_service(db: Session, supplier_id: int) -> Supplier | None:
    supplier = get_supplier_by_id(db, supplier_id)
    if not supplier:
        return None
    return restore_supplier(db, supplier)