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
    MultiItemCustomsBreakdown,
    MultiItemCustomsEstimateRequest,
    MultiItemCustomsLineBreakdown,
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


# ==================================================
# Bulk Import & Template Generator (MD-008 Excel/CSV)
# ==================================================

import csv
import io

def bulk_import_tariffs_service(db: Session, file_contents: bytes, filename: str) -> dict:
    """
    Bulk import or update Egyptian Customs Tariffs from CSV/Excel file.
    """
    try:
        text_content = file_contents.decode("utf-8-sig")
    except Exception:
        try:
            text_content = file_contents.decode("latin-1")
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Invalid file encoding: {str(e)}")

    reader = csv.DictReader(io.StringIO(text_content))
    if not reader.fieldnames:
        raise HTTPException(status_code=400, detail="CSV/Excel file is empty or invalid format")

    field_map = {}
    for name in reader.fieldnames:
        clean = name.strip().lower()
        if clean in ("hs_code", "hscode", "code", "كود البند"):
            field_map["hs_code"] = name
        elif clean in ("hs_description", "description", "name", "الوصف"):
            field_map["hs_description"] = name
        elif clean in ("customs_category", "category", "التصنيف"):
            field_map["customs_category"] = name
        elif clean in ("customs_duty_rate", "duty", "duty%", "duty_rate", "ضريبة الوارد"):
            field_map["customs_duty_rate"] = name
        elif clean in ("vat_rate", "vat", "vat%", "ضريبة القيمة المضافة"):
            field_map["vat_rate"] = name
        elif clean in ("schedule_tax_rate", "schedule_tax", "ضريبة الجدول"):
            field_map["schedule_tax_rate"] = name
        elif clean in ("development_fee_rate", "dev_fee", "development_fee", "رسم التنمية"):
            field_map["development_fee_rate"] = name
        elif clean in ("import_fee_rate", "import_fee", "رسم الوارد"):
            field_map["import_fee_rate"] = name
        elif clean in ("regulatory_authority", "authority", "الجهة الرقابية"):
            field_map["regulatory_authority"] = name
        elif clean in ("requires_coo", "coo"):
            field_map["requires_coo"] = name
        elif clean in ("requires_inspection", "inspection", "insp"):
            field_map["requires_inspection"] = name
        elif clean in ("requires_acid", "acid"):
            field_map["requires_acid"] = name
        elif clean in ("notes", "ملاحظات"):
            field_map["notes"] = name

    if "hs_code" not in field_map or "hs_description" not in field_map:
        raise HTTPException(
            status_code=400,
            detail="File must contain 'hs_code' (or 'hscode') and 'hs_description' (or 'description') columns.",
        )

    imported_count = 0
    updated_count = 0
    errors = []

    for row_idx, row in enumerate(reader, start=2):
        try:
            hs_code_val = row.get(field_map["hs_code"], "").strip()
            if not hs_code_val:
                continue

            desc_val = row.get(field_map["hs_description"], "").strip() or f"HS Code {hs_code_val}"
            category_val = row.get(field_map.get("customs_category", ""), "").strip() or "General"

            duty_val = float(row.get(field_map.get("customs_duty_rate", ""), 0) or 0)
            vat_val = float(row.get(field_map.get("vat_rate", ""), 0) or 0)
            sched_val = float(row.get(field_map.get("schedule_tax_rate", ""), 0) or 0)
            dev_val = float(row.get(field_map.get("development_fee_rate", ""), 0) or 0)
            imp_fee_val = float(row.get(field_map.get("import_fee_rate", ""), 0) or 0)

            auth_val = row.get(field_map.get("regulatory_authority", ""), "").strip() or None
            coo_val = str(row.get(field_map.get("requires_coo", ""), "true")).strip().lower() in ("true", "1", "yes", "نعم")
            insp_val = str(row.get(field_map.get("requires_inspection", ""), "true")).strip().lower() in ("true", "1", "yes", "نعم")
            acid_val = str(row.get(field_map.get("requires_acid", ""), "true")).strip().lower() in ("true", "1", "yes", "نعم")
            notes_val = row.get(field_map.get("notes", ""), "").strip() or None

            existing = repository.get_tariff_by_hs_code(db, hs_code_val)
            data_dict = {
                "hs_code": hs_code_val,
                "hs_description": desc_val,
                "customs_category": category_val,
                "customs_duty_rate": duty_val,
                "vat_rate": vat_val,
                "schedule_tax_rate": sched_val,
                "development_fee_rate": dev_val,
                "import_fee_rate": imp_fee_val,
                "regulatory_authority": auth_val,
                "requires_coo": coo_val,
                "requires_inspection": insp_val,
                "requires_acid": acid_val,
                "notes": notes_val,
                "is_active": True,
            }

            if existing:
                repository.update_tariff(db, existing.tariff_id, data_dict)
                updated_count += 1
            else:
                repository.create_tariff(db, data_dict)
                imported_count += 1
        except Exception as e:
            errors.append(f"Row {row_idx}: {str(e)}")

    return {
        "imported": imported_count,
        "updated": updated_count,
        "total_processed": imported_count + updated_count,
        "errors": errors,
    }


# ==================================================
# Multi-Item Egyptian Customs Engine (Nafeza Statement Engine)
# ==================================================

def estimate_multi_item_customs_duty_service(
    db: Session, request: MultiItemCustomsEstimateRequest
) -> MultiItemCustomsBreakdown:
    """
    محرك الحساب الجمركي المصري لشحنة متعددة الأصناف (Multi-HS Code Customs Engine)
    بناءً على المواصفة الفنية والنموذج الفعلي المعالج من منصة نافذة (Nafeza Statement Specification).
    """
    on_date = request.estimate_date or date.today()
    if not request.lines:
        raise HTTPException(status_code=400, detail="At least one line item is required")

    invoice_total_value_fc = sum(line.value_fc for line in request.lines)
    if invoice_total_value_fc <= Decimal("0.00"):
        raise HTTPException(status_code=400, detail="Total invoice value must be greater than 0")

    total_insurance_freight_egp = request.insurance_egp + request.freight_egp

    line_breakdowns: List[MultiItemCustomsLineBreakdown] = []
    total_duty_egp = Decimal("0.00")
    total_schedule_tax_egp = Decimal("0.00")
    total_vat_egp = Decimal("0.00")
    total_inspection_fees_egp = Decimal("0.00")

    for line in request.lines:
        tariff = repository.get_active_tariff_on_date(db, line.hs_code, on_date)

        duty_rate = Decimal(str(tariff.customs_duty_rate)) if tariff else Decimal("10.00")
        vat_rate = Decimal(str(request.vat_rate_override or (tariff.vat_rate if tariff else Decimal("14.00"))))
        sched_rate = Decimal(str(tariff.schedule_tax_rate)) if tariff else Decimal("10.00")

        schedule_tax_base = "duty"

        requires_coo = tariff.requires_coo if tariff else True
        requires_inspection = tariff.requires_inspection if tariff else True
        requires_acid = tariff.requires_acid if tariff else True
        regulatory_authority = tariff.regulatory_authority if tariff else None
        hs_description = tariff.hs_description if tariff else f"HS Code {line.hs_code}"
        customs_category = tariff.customs_category if tariff else None

        value_share = line.value_fc / invoice_total_value_fc
        allocated_ins_freight = total_insurance_freight_egp * value_share

        line_taxable_fc = line.value_fc - line.exempted_value_fc - line.value_without_payment_fc
        if request.cif_declared_total_egp and request.cif_declared_total_egp > Decimal("0.00"):
            cif_line_egp = _round(request.cif_declared_total_egp * value_share)
        else:
            cif_line_egp = _round((line_taxable_fc * request.exchange_rate) + allocated_ins_freight)

        duty_line_egp = _round(cif_line_egp * (duty_rate / Decimal("100")))

        if schedule_tax_base == "duty":
            schedule_tax_line_egp = _round(duty_line_egp * (sched_rate / Decimal("100")))
        elif schedule_tax_base == "cif":
            schedule_tax_line_egp = _round(cif_line_egp * (sched_rate / Decimal("100")))
        else:
            schedule_tax_line_egp = Decimal("0.00")

        vat_base_egp = cif_line_egp + duty_line_egp
        vat_line_egp = _round(vat_base_egp * (vat_rate / Decimal("100")))

        inspection_fee_line_egp = _round(line.inspection_fee_egp)

        total_duty_egp += duty_line_egp
        total_schedule_tax_egp += schedule_tax_line_egp
        total_vat_egp += vat_line_egp
        total_inspection_fees_egp += inspection_fee_line_egp

        line_breakdowns.append(
            MultiItemCustomsLineBreakdown(
                line_no=line.line_no,
                hs_code=line.hs_code,
                hs_description=hs_description,
                customs_category=customs_category,
                value_fc=line.value_fc,
                value_share=_round(value_share * Decimal("100")),
                allocated_insurance_freight_egp=_round(allocated_ins_freight),
                cif_value_egp=cif_line_egp,
                customs_duty_rate=duty_rate,
                duty_egp=duty_line_egp,
                schedule_tax_rate=sched_rate,
                schedule_tax_base=schedule_tax_base,
                schedule_tax_egp=schedule_tax_line_egp,
                vat_rate=vat_rate,
                vat_base_egp=vat_base_egp,
                vat_egp=vat_line_egp,
                inspection_fee_egp=inspection_fee_line_egp,
                requires_coo=requires_coo,
                requires_inspection=requires_inspection,
                requires_acid=requires_acid,
                regulatory_authority=regulatory_authority,
            )
        )

    items_taxes_total_egp = total_duty_egp + total_schedule_tax_egp + total_vat_egp
    grand_total_payable_egp = items_taxes_total_egp + _round(request.additional_fees_egp)

    return MultiItemCustomsBreakdown(
        currency=request.currency,
        exchange_rate=request.exchange_rate,
        invoice_total_value_fc=invoice_total_value_fc,
        insurance_egp=request.insurance_egp,
        freight_egp=request.freight_egp,
        additional_fees_egp=request.additional_fees_egp,
        estimate_date=on_date,
        lines=line_breakdowns,
        total_duty_egp=total_duty_egp,
        total_schedule_tax_egp=total_schedule_tax_egp,
        total_vat_egp=total_vat_egp,
        total_inspection_fees_egp=total_inspection_fees_egp,
        items_taxes_total_egp=items_taxes_total_egp,
        grand_total_payable_egp=grand_total_payable_egp,
    )


