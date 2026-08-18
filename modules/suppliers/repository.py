from sqlalchemy import exists, func
from sqlalchemy.orm import Session

from .model import Supplier
from .schemas import SupplierCreate, SupplierUpdate


# ==================================================
# Create Supplier
# ==================================================

def create_supplier(db: Session, supplier_data: dict) -> Supplier:
    supplier = Supplier(**supplier_data)
    db.add(supplier)
    db.commit()
    db.refresh(supplier)

    return supplier


# ==================================================
# Get Active Suppliers
# ==================================================

def get_active_suppliers(db: Session) -> list[Supplier]:
    return (
        db.query(Supplier)
        .filter(Supplier.is_active == True)
        .order_by(Supplier.supplier_id)
        .all()
    )


# ==================================================
# Get All Suppliers (Admin)
# ==================================================

def get_all_suppliers_admin(db: Session) -> list[Supplier]:
    return (
        db.query(Supplier)
        .order_by(Supplier.supplier_id)
        .all()
    )


# ==================================================
# Get Supplier By ID
# ==================================================

def get_supplier_by_id(db: Session, supplier_id: int) -> Supplier | None:
    return (
        db.query(Supplier)
        .filter(Supplier.supplier_id == supplier_id)
        .first()
    )


# ==================================================
# Get Supplier By Exporter ID
# ==================================================

def get_supplier_by_exporter_id(db: Session, foreign_exporter_id: str) -> Supplier | None:
    return (
        db.query(Supplier)
        .filter(Supplier.foreign_exporter_id == foreign_exporter_id)
        .first()
    )


# ==================================================
# Check Foreign Exporter ID Exists (Optimized SQL)
# ==================================================

def foreign_exporter_id_exists(db: Session, foreign_exporter_id: str) -> bool:
    return db.query(
        exists().where(Supplier.foreign_exporter_id == foreign_exporter_id)
    ).scalar()


# ==================================================
# Count Total Suppliers for Code Generation
# ==================================================

def count_suppliers(db: Session) -> int:
    return db.query(func.count(Supplier.supplier_id)).scalar() or 0


# ==================================================
# Update Supplier Data
# ==================================================

def update_supplier(db: Session, supplier: Supplier, supplier_data: SupplierUpdate) -> Supplier:
    update_data = supplier_data.model_dump(exclude_unset=True, exclude_none=True)
    old_data = {
        k: getattr(supplier, k, None)
        for k in update_data.keys()
    }

    for field, value in update_data.items():
        if field == "email" and value is not None:
            value = str(value)
        setattr(supplier, field, value)

    try:
        db.commit()
        db.refresh(supplier)
    except Exception:
        db.rollback()
        raise

    return supplier


# ==================================================
# Soft Delete Supplier
# ==================================================

def soft_delete_supplier(db: Session, supplier: Supplier) -> Supplier:
    supplier.is_active = False
    db.commit()
    db.refresh(supplier)

    return supplier


# ==================================================
# Restore Supplier
# ==================================================

def restore_supplier(db: Session, supplier: Supplier) -> Supplier:
    supplier.is_active = True
    db.commit()
    db.refresh(supplier)

    return supplier