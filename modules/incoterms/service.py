from typing import List, Optional

from fastapi import HTTPException
from sqlalchemy.orm import Session

from .model import CostItem, Incoterm, IncotermResponsibility
from .schemas import (
    CostItemCreate,
    CostItemUpdate,
    IncotermCreate,
    IncotermResponsibilityCreate,
    IncotermResponsibilityUpdate,
    IncotermUpdate,
)
from . import repository
from .validators import (
    validate_cost_item_exists,
    validate_incoterm_exists,
    validate_no_duplicate_cost_item_code,
    validate_no_duplicate_incoterm_code,
    validate_no_duplicate_responsibility,
)


# ==================================================
# Incoterm Services (MD-006)
# ==================================================

def create_incoterm_service(db: Session, data: IncotermCreate) -> Incoterm:
    validate_no_duplicate_incoterm_code(db, data.incoterm_code)
    return repository.create_incoterm(db, data.model_dump())


def get_all_incoterms_service(db: Session, include_inactive: bool = False) -> List[Incoterm]:
    return repository.get_all_incoterms(db, include_inactive)


def get_incoterm_by_id_service(db: Session, incoterm_id: int) -> Incoterm:
    incoterm = repository.get_incoterm_by_id(db, incoterm_id)
    if not incoterm:
        raise HTTPException(status_code=404, detail="Incoterm not found")
    return incoterm


def update_incoterm_service(db: Session, incoterm_id: int, data: IncotermUpdate) -> Incoterm:
    incoterm = repository.get_incoterm_by_id(db, incoterm_id)
    if not incoterm:
        raise HTTPException(status_code=404, detail="Incoterm not found")
    update_dict = data.model_dump(exclude_unset=True, exclude_none=True)
    return repository.update_incoterm(db, incoterm_id, update_dict)


def delete_incoterm_service(db: Session, incoterm_id: int) -> Incoterm:
    incoterm = repository.get_incoterm_by_id(db, incoterm_id)
    if not incoterm:
        raise HTTPException(status_code=404, detail="Incoterm not found")
    return repository.toggle_incoterm_active(db, incoterm_id, is_active=False)


def restore_incoterm_service(db: Session, incoterm_id: int) -> Incoterm:
    incoterm = repository.get_incoterm_by_id(db, incoterm_id)
    if not incoterm:
        raise HTTPException(status_code=404, detail="Incoterm not found")
    return repository.toggle_incoterm_active(db, incoterm_id, is_active=True)


# ==================================================
# Cost Item Services (MD-006A)
# ==================================================

def create_cost_item_service(db: Session, data: CostItemCreate) -> CostItem:
    validate_no_duplicate_cost_item_code(db, data.cost_item_code)
    return repository.create_cost_item(db, data.model_dump())


def get_all_cost_items_service(db: Session, include_inactive: bool = False) -> List[CostItem]:
    return repository.get_all_cost_items(db, include_inactive)


def get_cost_item_by_id_service(db: Session, cost_item_id: int) -> CostItem:
    item = repository.get_cost_item_by_id(db, cost_item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Cost item not found")
    return item


def update_cost_item_service(db: Session, cost_item_id: int, data: CostItemUpdate) -> CostItem:
    item = repository.get_cost_item_by_id(db, cost_item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Cost item not found")
    update_dict = data.model_dump(exclude_unset=True, exclude_none=True)
    return repository.update_cost_item(db, cost_item_id, update_dict)


def delete_cost_item_service(db: Session, cost_item_id: int) -> CostItem:
    item = repository.get_cost_item_by_id(db, cost_item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Cost item not found")
    return repository.toggle_cost_item_active(db, cost_item_id, is_active=False)


def restore_cost_item_service(db: Session, cost_item_id: int) -> CostItem:
    item = repository.get_cost_item_by_id(db, cost_item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Cost item not found")
    return repository.toggle_cost_item_active(db, cost_item_id, is_active=True)


# ==================================================
# Responsibility Matrix Services (MD-006B)
# ==================================================

def create_responsibility_service(
    db: Session, data: IncotermResponsibilityCreate
) -> IncotermResponsibility:
    validate_incoterm_exists(db, data.incoterm_id)
    validate_cost_item_exists(db, data.cost_item_id)
    validate_no_duplicate_responsibility(db, data.incoterm_id, data.cost_item_id)
    return repository.create_responsibility(db, data.model_dump())


def get_all_responsibilities_service(db: Session) -> List[IncotermResponsibility]:
    return repository.get_all_responsibilities(db)


def get_matrix_for_incoterm_service(
    db: Session, incoterm_id: int
) -> List[IncotermResponsibility]:
    validate_incoterm_exists(db, incoterm_id)
    return repository.get_matrix_for_incoterm(db, incoterm_id)


def update_responsibility_service(
    db: Session, responsibility_id: int, data: IncotermResponsibilityUpdate
) -> IncotermResponsibility:
    responsibility = repository.get_responsibility_by_id(db, responsibility_id)
    if not responsibility:
        raise HTTPException(status_code=404, detail="Responsibility record not found")
    update_dict = data.model_dump(exclude_unset=True, exclude_none=True)
    return repository.update_responsibility(db, responsibility_id, update_dict)


def delete_responsibility_service(
    db: Session, responsibility_id: int
) -> IncotermResponsibility:
    responsibility = repository.get_responsibility_by_id(db, responsibility_id)
    if not responsibility:
        raise HTTPException(status_code=404, detail="Responsibility record not found")
    return repository.delete_responsibility(db, responsibility_id)
