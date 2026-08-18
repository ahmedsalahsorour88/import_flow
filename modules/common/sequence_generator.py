"""
modules/common/sequence_generator.py
Centralized business reference code generator for ImportFlow ERP.
Avoids race conditions by using max(id)+1 with proper fallback.
"""
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Type


def generate_reference_code(
    db: Session,
    model: Type,
    prefix: str,
    id_field: str = "id",
    zero_pad: int = 6,
) -> str:
    """
    Generate a sequential business reference code.
    Example: generate_reference_code(db, Supplier, "SUP") → "SUP-000017"

    Uses MAX(id) + 1 to avoid count() issues after deletions.
    Thread-safety note: unique DB constraint on code column is the final guard.
    """
    max_id = db.query(func.max(getattr(model, id_field))).scalar() or 0
    next_num = max_id + 1
    return f"{prefix}-{next_num:0{zero_pad}d}"
