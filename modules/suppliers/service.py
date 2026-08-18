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

    supplier = create_supplier(db, supplier_dict)
    
    AuditLogService(db).log_activity(
        entity_type="Supplier",
        entity_id=supplier.supplier_id,
        entity_code=supplier.supplier_code,
        action="CREATE",
        new_data={"company_name": supplier.company_name, "foreign_exporter_id": supplier.foreign_exporter_id, "foreign_exporter_country_code": supplier.foreign_exporter_country_code}
    )
    
    return supplier



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

from modules.audit_logs.service import AuditLogService

def update_supplier_service(
    db: Session,
    supplier_id: int,
    supplier_data: SupplierUpdate
) -> Supplier | None:
    supplier = get_supplier_by_id(db, supplier_id)
    if not supplier:
        return None
    update_data = supplier_data.model_dump(exclude_unset=True, exclude_none=True)
    old_data = {
        k: getattr(supplier, k, None)
        for k in update_data.keys()
    }
    
    updated = update_supplier(db, supplier, supplier_data)
    
    AuditLogService(db).log_activity(
        entity_type="Supplier",
        entity_id=updated.supplier_id,
        entity_code=updated.supplier_code,
        action="UPDATE",
        old_data=old_data,
        new_data=update_data,
    )
    
    return updated


# ==================================================
# Delete Supplier Service
# ==================================================

def delete_supplier_service(db: Session, supplier_id: int) -> Supplier | None:
    supplier = get_supplier_by_id(db, supplier_id)
    if not supplier:
        return None
    if not supplier.is_active:
        return supplier
    deleted = soft_delete_supplier(db, supplier)
    AuditLogService(db).log_activity(
        entity_type="Supplier",
        entity_id=deleted.supplier_id,
        entity_code=deleted.supplier_code,
        action="DELETE",
    )
    return deleted


# ==================================================
# Restore Supplier Service
# ==================================================

def restore_supplier_service(db: Session, supplier_id: int) -> Supplier | None:
    supplier = get_supplier_by_id(db, supplier_id)
    if not supplier:
        return None
    restored = restore_supplier(db, supplier)
    AuditLogService(db).log_activity(
        entity_type="Supplier",
        entity_id=restored.supplier_id,
        entity_code=restored.supplier_code,
        action="RESTORE",
    )
    return restored