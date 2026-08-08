from datetime import date
from typing import List, Optional

from sqlalchemy import or_
from sqlalchemy.orm import Session

from .model import CustomsTariff


# ==================================================
# Basic CRUD
# ==================================================

def get_tariff_by_id(db: Session, tariff_id: int) -> Optional[CustomsTariff]:
    return db.query(CustomsTariff).filter(CustomsTariff.tariff_id == tariff_id).first()


def get_tariff_by_hs_code(db: Session, hs_code: str) -> Optional[CustomsTariff]:
    return db.query(CustomsTariff).filter(CustomsTariff.hs_code == hs_code).first()


def get_all_tariffs(
    db: Session,
    include_inactive: bool = False,
    search: Optional[str] = None,
) -> List[CustomsTariff]:
    query = db.query(CustomsTariff)
    if not include_inactive:
        query = query.filter(CustomsTariff.is_active == True)
    if search:
        term = f"%{search.lower()}%"
        query = query.filter(
            or_(
                CustomsTariff.hs_code.ilike(term),
                CustomsTariff.hs_description.ilike(term),
                CustomsTariff.customs_category.ilike(term),
            )
        )
    return query.order_by(CustomsTariff.hs_code).all()


def create_tariff(db: Session, data: dict) -> CustomsTariff:
    tariff = CustomsTariff(**data)
    db.add(tariff)
    db.commit()
    db.refresh(tariff)
    return tariff


def update_tariff(db: Session, tariff_id: int, data: dict) -> Optional[CustomsTariff]:
    tariff = get_tariff_by_id(db, tariff_id)
    if not tariff:
        return None
    for key, value in data.items():
        setattr(tariff, key, value)
    db.commit()
    db.refresh(tariff)
    return tariff


def toggle_tariff_active(
    db: Session, tariff_id: int, is_active: bool
) -> Optional[CustomsTariff]:
    tariff = get_tariff_by_id(db, tariff_id)
    if not tariff:
        return None
    tariff.is_active = is_active
    db.commit()
    db.refresh(tariff)
    return tariff


# ==================================================
# Date-Aware Tariff Lookup (Snapshot Support)
# ==================================================

def get_active_tariff_on_date(
    db: Session, hs_code: str, on_date: date
) -> Optional[CustomsTariff]:
    """
    يرجع السجل الساري في تاريخ معين.
    يستخدم في حساب الجمارك التاريخي (Snapshot) داخل ملف الاستيراد.

    الأولوية:
    1. السجل الذي effective_from <= on_date AND (effective_to IS NULL OR effective_to > on_date)
    2. إذا لم يوجد بهذه الشروط — يرجع السجل الأحدث للـ HS Code هذا.
    """
    # First try: exact date range match
    exact = (
        db.query(CustomsTariff)
        .filter(
            CustomsTariff.hs_code == hs_code,
            CustomsTariff.effective_from <= on_date,
            or_(
                CustomsTariff.effective_to == None,
                CustomsTariff.effective_to > on_date,
            ),
            CustomsTariff.is_active == True,
        )
        .order_by(CustomsTariff.effective_from.desc())
        .first()
    )
    if exact:
        return exact

    # Fallback: latest active record for this HS Code
    return (
        db.query(CustomsTariff)
        .filter(
            CustomsTariff.hs_code == hs_code,
            CustomsTariff.is_active == True,
        )
        .order_by(CustomsTariff.effective_from.desc())
        .first()
    )
