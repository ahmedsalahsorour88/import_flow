"""
modules/common/validators.py
Shared domain validation utilities for ImportFlow ERP.
Reusable FK existence checks to avoid duplication across modules.
"""
from typing import Type, Optional, Any
from sqlalchemy.orm import Session
from sqlalchemy import inspect as sa_inspect


def validate_foreign_key(
    db: Session,
    model: Type,
    entity_id: Any,
    field_name: str = "id",
    error_label: Optional[str] = None,
) -> object:
    """
    Validate that a foreign key references an existing record.
    Returns the found entity or raises ValueError.
    """
    if entity_id is None:
        return None
    label = error_label or model.__name__
    entity = db.query(model).filter(getattr(model, field_name) == entity_id).first()
    if not entity:
        raise ValueError(f"{label} with id={entity_id} not found.")
    return entity


def validate_active_foreign_key(
    db: Session,
    model: Type,
    entity_id: Any,
    field_name: str = "id",
    error_label: Optional[str] = None,
) -> object:
    """
    Validate that a foreign key references an existing AND active record.
    Returns the found entity or raises ValueError.
    """
    if entity_id is None:
        return None
    label = error_label or model.__name__
    query = db.query(model).filter(getattr(model, field_name) == entity_id)
    # Apply is_active filter only if the model has that column
    mapper = sa_inspect(model)
    col_names = [c.key for c in mapper.columns]
    if "is_active" in col_names:
        query = query.filter(model.is_active.is_(True))
    entity = query.first()
    if not entity:
        raise ValueError(f"{label} with id={entity_id} not found or is inactive.")
    return entity
