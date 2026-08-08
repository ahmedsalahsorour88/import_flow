from sqlalchemy.orm import Session

from . import repository


# ==================================================
# Incoterm Validators (MD-006)
# ==================================================

def validate_no_duplicate_incoterm_code(
    db: Session, incoterm_code: str, exclude_id: int = None
) -> None:
    """Raise ValueError if incoterm_code already exists."""
    existing = repository.get_incoterm_by_code(db, incoterm_code)
    if existing and (exclude_id is None or existing.incoterm_id != exclude_id):
        raise ValueError(f"Incoterm code '{incoterm_code}' already exists.")


def validate_incoterm_exists(db: Session, incoterm_id: int) -> None:
    """Raise ValueError if incoterm_id does not exist."""
    incoterm = repository.get_incoterm_by_id(db, incoterm_id)
    if not incoterm:
        raise ValueError(f"Incoterm with ID {incoterm_id} not found.")


# ==================================================
# Cost Item Validators (MD-006A)
# ==================================================

def validate_no_duplicate_cost_item_code(
    db: Session, cost_item_code: str, exclude_id: int = None
) -> None:
    """Raise ValueError if cost_item_code already exists."""
    existing = repository.get_cost_item_by_code(db, cost_item_code)
    if existing and (exclude_id is None or existing.cost_item_id != exclude_id):
        raise ValueError(f"Cost item code '{cost_item_code}' already exists.")


def validate_cost_item_exists(db: Session, cost_item_id: int) -> None:
    """Raise ValueError if cost_item_id does not exist."""
    item = repository.get_cost_item_by_id(db, cost_item_id)
    if not item:
        raise ValueError(f"Cost item with ID {cost_item_id} not found.")


# ==================================================
# Responsibility Validators (MD-006B)
# ==================================================

def validate_no_duplicate_responsibility(
    db: Session, incoterm_id: int, cost_item_id: int, exclude_id: int = None
) -> None:
    """Raise ValueError if the (incoterm_id, cost_item_id) pair already exists."""
    existing = repository.get_responsibility_by_pair(db, incoterm_id, cost_item_id)
    if existing and (exclude_id is None or existing.responsibility_id != exclude_id):
        raise ValueError(
            f"Responsibility for Incoterm ID {incoterm_id} and Cost Item ID {cost_item_id} already exists."
        )
