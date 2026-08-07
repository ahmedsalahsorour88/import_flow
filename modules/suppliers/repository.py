from sqlalchemy.orm import Session

from .model import Supplier
from .schemas import SupplierCreate
from .schemas import SupplierUpdate
from sqlalchemy.orm import Session

from .model import Supplier

# ==================================================
# Create Supplier
# ==================================================

def create_supplier(
    db: Session,
    supplier_data: dict
):

    supplier = Supplier(
        **supplier_data
    )

    db.add(supplier)

    db.commit()

    db.refresh(supplier)

    return supplier

# ==================================================
# Get All Suppliers
# ==================================================

def get_all_suppliers(
    db: Session,
    skip: int = 0,
    limit: int = 50
):

    return (
        db.query(Supplier)
        .filter(
            Supplier.is_active == True
        )
        .offset(skip)
        .limit(limit)
        .all()
    )



# ==================================================
# Get Supplier By ID
# ==================================================

def get_supplier_by_id(
    db: Session,
    supplier_id: int
):

    return (
        db.query(Supplier)
        .filter(
            Supplier.supplier_id == supplier_id
        )
        .first()
    )



# ==================================================
# Get Supplier By Exporter ID
# ==================================================

def get_supplier_by_exporter_id(
    db: Session,
    foreign_exporter_id: str
):

    return (
        db.query(Supplier)
        .filter(
            Supplier.foreign_exporter_id == foreign_exporter_id
        )
        .first()
    )



# ==================================================
# Update Supplier
# ==================================================

def update_supplier(
    db: Session,
    supplier: Supplier,
    supplier_data: SupplierUpdate
):

    update_data = supplier_data.model_dump(
        exclude_unset=True
    )


    for field, value in update_data.items():

        setattr(
            supplier,
            field,
            value
        )


    db.commit()

    db.refresh(supplier)

    return supplier



# ==================================================
# Soft Delete Supplier
# ==================================================

def soft_delete_supplier(
    db: Session,
    supplier: Supplier
):

    supplier.is_active = False

    db.commit()

    db.refresh(supplier)

    return supplier



# ==================================================
# Restore Supplier
# ==================================================

def restore_supplier(
    db: Session,
    supplier: Supplier
):

    supplier.is_active = True

    db.commit()

    db.refresh(supplier)

    return supplier