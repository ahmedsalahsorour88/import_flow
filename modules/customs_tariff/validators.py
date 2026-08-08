from datetime import date

from sqlalchemy.orm import Session

from . import repository


# ==================================================
# Validators (MD-008)
# ==================================================

def validate_no_duplicate_hs_code(
    db: Session, hs_code: str, exclude_id: int = None
) -> None:
    """
    Raise ValueError if hs_code already exists in the database.
    Accepts exclude_id to allow updating an existing record without self-conflict.
    """
    existing = repository.get_tariff_by_hs_code(db, hs_code)
    if existing and (exclude_id is None or existing.tariff_id != exclude_id):
        raise ValueError(
            f"HS Code '{hs_code}' already exists (Tariff ID: {existing.tariff_id}). "
            "يمنع النظام تكرار البند الجمركي."
        )


def validate_tariff_exists(db: Session, tariff_id: int) -> None:
    """Raise ValueError if tariff_id does not exist."""
    tariff = repository.get_tariff_by_id(db, tariff_id)
    if not tariff:
        raise ValueError(f"Tariff ID {tariff_id} not found.")


def validate_effective_date_range(
    effective_from: date, effective_to: date = None
) -> None:
    """
    Raise ValueError if effective_to is not after effective_from.
    None effective_to means open-ended (still active) — always valid.
    """
    if effective_to and effective_to <= effective_from:
        raise ValueError(
            "effective_to must be after effective_from. "
            "تاريخ انتهاء السريان يجب أن يكون بعد تاريخ البداية."
        )
