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
    clean_hs = hs_code.strip()
    nodots = clean_hs.replace(".", "")
    formatted = f"{nodots[:4]}.{nodots[4:6]}.{nodots[6:8]}" if len(nodots) in (8, 10) else clean_hs
    targets = list(dict.fromkeys([clean_hs, nodots, formatted]))
    return (
        db.query(CustomsTariff)
        .filter(CustomsTariff.hs_code.in_(targets), CustomsTariff.is_active == True)
        .order_by(CustomsTariff.effective_from.desc())
        .first()
    )


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


def archive_and_create_new_tariff_version(
    db: Session, current_tariff: CustomsTariff, new_data: dict, effective_date: date
) -> CustomsTariff:
    """
    سلسلة الأتمتة التاريخية (Addendum 3):
    1. إغلاق السجل القديم بتحديد effective_to = effective_date.
    2. إنشاء سجل جديد فعّال يبدأ من effective_date مع effective_to = NULL.
    """
    current_tariff.effective_to = effective_date
    current_tariff.is_active = False  # Mark historical version inactive for default list query

    new_version_data = {
        "hs_code": current_tariff.hs_code,
        "hs_description": new_data.get("hs_description", current_tariff.hs_description),
        "customs_category": current_tariff.customs_category,
        "customs_duty_rate": new_data.get("customs_duty_rate", current_tariff.customs_duty_rate),
        "vat_rate": new_data.get("vat_rate", current_tariff.vat_rate),
        "schedule_tax_rate": new_data.get("schedule_tax_rate", current_tariff.schedule_tax_rate),
        "development_fee_rate": new_data.get("development_fee_rate", current_tariff.development_fee_rate),
        "import_fee_rate": new_data.get("import_fee_rate", current_tariff.import_fee_rate),
        "requires_coo": current_tariff.requires_coo,
        "requires_inspection": current_tariff.requires_inspection,
        "requires_acid": current_tariff.requires_acid,
        "regulatory_authority": new_data.get("regulatory_authority", current_tariff.regulatory_authority),
        "prior_approval_note": new_data.get("prior_approval_note", current_tariff.prior_approval_note),
        "effective_from": effective_date,
        "effective_to": None,
        "source_url": new_data.get("source_url", current_tariff.source_url),
        "last_verified_date": date.today(),
        "verified_by": new_data.get("verified_by", "System Admin"),
        "confidence": new_data.get("confidence", "verified_manual"),
        "notes": current_tariff.notes,
        "is_active": True,
    }

    new_tariff = CustomsTariff(**new_version_data)
    db.add(new_tariff)
    db.commit()
    db.refresh(new_tariff)
    return new_tariff


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
    db: Session, hs_code: str, on_date: date, strict: bool = True
) -> Optional[CustomsTariff]:
    """
    يرجع السجل الساري في تاريخ معين.
    يستخدم في حساب الجمارك التاريخي (Snapshot) داخل ملف الاستيراد.
    إذا كان strict=True، يرجع None فقط لو لم يوجد بند فعّال في هذا التاريخ.
    """
    clean_hs = hs_code.strip()
    nodots = clean_hs.replace(".", "")
    formatted = f"{nodots[:4]}.{nodots[4:6]}.{nodots[6:8]}" if len(nodots) in (8, 10) else clean_hs
    targets = list(dict.fromkeys([clean_hs, nodots, formatted]))
    if len(nodots) == 10:
        targets.append(f"{nodots[:4]}.{nodots[4:6]}.{nodots[6:8]}.{nodots[8:]}")

    exact = (
        db.query(CustomsTariff)
        .filter(
            CustomsTariff.hs_code.in_(targets),
            CustomsTariff.effective_from <= on_date,
            or_(
                CustomsTariff.effective_to == None,
                CustomsTariff.effective_to >= on_date,
            ),
        )
        .order_by(CustomsTariff.effective_from.desc())
        .first()
    )
    if exact:
        return exact

    if strict:
        return None

    return (
        db.query(CustomsTariff)
        .filter(
            CustomsTariff.hs_code.in_(targets),
            CustomsTariff.is_active == True,
        )
        .order_by(CustomsTariff.effective_from.desc())
        .first()
    )


# ==================================================
# Preferential Agreements CRUD (Addendum 3)
# ==================================================

from .model import FeeCode, PreferentialAgreement


def create_preferential_agreement(db: Session, data: dict) -> PreferentialAgreement:
    agreement = PreferentialAgreement(**data)
    db.add(agreement)
    db.commit()
    db.refresh(agreement)
    return agreement


def get_agreements_by_hs_code(
    db: Session, hs_code: str, origin_country: Optional[str] = None
) -> List[PreferentialAgreement]:
    query = db.query(PreferentialAgreement).filter(PreferentialAgreement.hs_code == hs_code)
    if origin_country:
        query = query.filter(PreferentialAgreement.origin_countries.ilike(f"%{origin_country}%"))
    return query.all()


# ==================================================
# Fee Codes Repository (Nafeza Statement Registry)
# ==================================================

def get_all_fee_codes(db: Session, include_inactive: bool = False) -> List[FeeCode]:
    query = db.query(FeeCode)
    if not include_inactive:
        query = query.filter(FeeCode.is_active == True)
    return query.order_by(FeeCode.fee_code_id).all()


def get_active_fee_codes(db: Session, on_date: Optional[date] = None) -> List[FeeCode]:
    target_date = on_date or date.today()
    return (
        db.query(FeeCode)
        .filter(
            FeeCode.is_active == True,
            FeeCode.effective_from <= target_date,
            or_(
                FeeCode.effective_to == None,
                FeeCode.effective_to >= target_date,
            ),
        )
        .order_by(FeeCode.fee_code_id)
        .all()
    )


def create_fee_code(db: Session, data: dict) -> FeeCode:
    fc = FeeCode(**data)
    db.add(fc)
    db.commit()
    db.refresh(fc)
    return fc


