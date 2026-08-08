from datetime import date
from decimal import Decimal, ROUND_HALF_UP
from typing import List, Optional

from fastapi import HTTPException
from sqlalchemy.orm import Session

from . import repository
from .model import CustomsTariff
from .schemas import (
    CustomsDutyBreakdown,
    CustomsDutyEstimateRequest,
    CustomsTariffCreate,
    CustomsTariffUpdate,
)
from .validators import (
    validate_effective_date_range,
    validate_no_duplicate_hs_code,
    validate_tariff_exists,
)


def _round(value: Decimal) -> Decimal:
    """Helper to round financial decimals to 2 decimal places using HALF_UP."""
    return value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


# ==================================================
# Customs Tariff Services (MD-008)
# ==================================================

def create_tariff_service(db: Session, data: CustomsTariffCreate) -> CustomsTariff:
    validate_no_duplicate_hs_code(db, data.hs_code)
    validate_effective_date_range(data.effective_from, data.effective_to)
    return repository.create_tariff(db, data.model_dump())


def get_all_tariffs_service(
    db: Session, include_inactive: bool = False, search: Optional[str] = None
) -> List[CustomsTariff]:
    return repository.get_all_tariffs(db, include_inactive=include_inactive, search=search)


def get_tariff_by_id_service(db: Session, tariff_id: int) -> CustomsTariff:
    tariff = repository.get_tariff_by_id(db, tariff_id)
    if not tariff:
        raise HTTPException(status_code=404, detail="Customs Tariff record not found")
    return tariff


def get_tariff_by_hs_code_service(db: Session, hs_code: str) -> CustomsTariff:
    tariff = repository.get_tariff_by_hs_code(db, hs_code)
    if not tariff:
        raise HTTPException(status_code=404, detail=f"Customs Tariff for HS Code '{hs_code}' not found")
    return tariff


def update_tariff_service(
    db: Session, tariff_id: int, data: CustomsTariffUpdate
) -> CustomsTariff:
    tariff = repository.get_tariff_by_id(db, tariff_id)
    if not tariff:
        raise HTTPException(status_code=404, detail="Customs Tariff record not found")

    update_dict = data.model_dump(exclude_unset=True, exclude_none=True)

    if "effective_from" in update_dict or "effective_to" in update_dict:
        eff_from = update_dict.get("effective_from", tariff.effective_from)
        eff_to = update_dict.get("effective_to", tariff.effective_to)
        validate_effective_date_range(eff_from, eff_to)

    return repository.update_tariff(db, tariff_id, update_dict)


def delete_tariff_service(db: Session, tariff_id: int) -> CustomsTariff:
    tariff = repository.get_tariff_by_id(db, tariff_id)
    if not tariff:
        raise HTTPException(status_code=404, detail="Customs Tariff record not found")
    return repository.toggle_tariff_active(db, tariff_id, is_active=False)


def restore_tariff_service(db: Session, tariff_id: int) -> CustomsTariff:
    tariff = repository.get_tariff_by_id(db, tariff_id)
    if not tariff:
        raise HTTPException(status_code=404, detail="Customs Tariff record not found")
    return repository.toggle_tariff_active(db, tariff_id, is_active=True)


# ==================================================
# Egyptian Customs Duty Calculation Engine (7.2)
# ==================================================

def estimate_customs_duty_service(
    db: Session, request: CustomsDutyEstimateRequest
) -> CustomsDutyBreakdown:
    """
    محرك الحساب الجمركي المصري (Egyptian Customs Calculation Engine)

    يتم حساب جميع الرسوم والضرائب بناءً على نسب الـ HS Code المحددة في MD-008.
    لا يتم استخدام أي نسب ثنائية أو Hard-coded (مثل VAT 14%).

    تسلسل الحساب:
    1. Customs Value (CIF) = request.cif_value
    2. Import Duty = CIF * (customs_duty_rate / 100)
    3. VAT Base = CIF + Import Duty + Freight
    4. VAT = VAT Base * (vat_rate / 100)
    5. Schedule Tax = CIF * (schedule_tax_rate / 100)
    6. Development Fee = CIF * (development_fee_rate / 100)
    7. Import Fee = CIF * (import_fee_rate / 100)
    8. Total Taxes & Fees = Import Duty + VAT + Schedule Tax + Development Fee + Import Fee
    """
    on_date = request.estimate_date or date.today()
    tariff = repository.get_active_tariff_on_date(db, request.hs_code, on_date)

    if not tariff:
        raise HTTPException(
            status_code=404,
            detail=f"No active Customs Tariff rule found for HS Code '{request.hs_code}' on {on_date}",
        )

    cif = request.cif_value
    freight = request.freight

    # Convert numeric fields to Decimal safely
    duty_rate = Decimal(str(tariff.customs_duty_rate))
    vat_rate = Decimal(str(tariff.vat_rate))
    schedule_rate = Decimal(str(tariff.schedule_tax_rate))
    dev_rate = Decimal(str(tariff.development_fee_rate))
    import_fee_rate = Decimal(str(tariff.import_fee_rate))

    # Calculation Steps
    import_duty_amount = _round(cif * (duty_rate / Decimal("100")))
    schedule_tax_amount = _round(cif * (schedule_rate / Decimal("100")))
    development_fee_amount = _round(cif * (dev_rate / Decimal("100")))
    import_fee_amount = _round(cif * (import_fee_rate / Decimal("100")))

    # VAT Base includes CIF + Import Duty + Freight
    vat_base = cif + import_duty_amount + freight
    vat_amount = _round(vat_base * (vat_rate / Decimal("100")))

    total_taxes = (
        import_duty_amount
        + vat_amount
        + schedule_tax_amount
        + development_fee_amount
        + import_fee_amount
    )

    return CustomsDutyBreakdown(
        hs_code=tariff.hs_code,
        hs_description=tariff.hs_description,
        customs_category=tariff.customs_category,
        estimate_date=on_date,
        cif_value=cif,
        freight=freight,
        customs_duty_rate=duty_rate,
        vat_rate=vat_rate,
        schedule_tax_rate=schedule_rate,
        development_fee_rate=dev_rate,
        import_fee_rate=import_fee_rate,
        import_duty_amount=import_duty_amount,
        vat_base=vat_base,
        vat_amount=vat_amount,
        schedule_tax_amount=schedule_tax_amount,
        development_fee_amount=development_fee_amount,
        import_fee_amount=import_fee_amount,
        total_taxes_and_fees=total_taxes,
        requires_coo=tariff.requires_coo,
        requires_inspection=tariff.requires_inspection,
        requires_acid=tariff.requires_acid,
        regulatory_authority=tariff.regulatory_authority,
    )
