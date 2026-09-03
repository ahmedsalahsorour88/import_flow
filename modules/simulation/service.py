"""
Core Business Logic & Simulation Calculation Engine for Logistics What-If and FX Hedging
"""

from __future__ import annotations

from datetime import datetime, date, timedelta, timezone
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from modules.simulation.schemas import (
    WhatIfSimulationRequest,
    WhatIfSimulationResponse,
    FXExposureItem,
    FXExposureSummaryResponse,
    SavedScenarioCreate,
)
from modules.simulation import repository
from modules.simulation.validators import validate_simulation_request
from modules.currencies import service as currency_service


def run_what_if_simulation_service(
    db: Session,
    request: WhatIfSimulationRequest,
) -> Dict[str, Any]:
    """
    Executes What-If Simulation:
    - Calculates impact of FX rate change on CIF, Import Duty, VAT, and Landed Cost.
    - Calculates impact of shipping route changes (Red Sea vs Cape of Good Hope) and port delays.
    - Computes dual-clock demurrage & port storage fees.
    - Tracks ACID 180-day regulatory expiry risk.
    - Generates strategic hedging and mitigation advice.
    """
    validate_simulation_request(request)

    # 1. Base Currency & FX Rates
    currency = (request.currency or "USD").upper()
    base_rate = request.base_exchange_rate

    if not base_rate or base_rate <= 0:
        # Default official rates if not provided
        default_rates = {"USD": 49.50, "EUR": 53.80, "CNY": 6.90, "GBP": 64.20, "AED": 13.48}
        base_rate = default_rates.get(currency, 50.0)

    # Rate change
    rate_change_factor = 1.0 + (request.exchange_rate_change_pct / 100.0)
    simulated_rate = round(base_rate * rate_change_factor, 4)

    # 2. Values & Freight adjustments
    fob_fcy = request.invoice_amount or 0.0
    freight_fcy = request.freight_fcy or 0.0
    insurance_fcy = request.insurance_fcy or 0.0

    # Route logic
    is_cape = request.shipping_route == "CAPE_OF_GOOD_HOPE"
    extra_route_days = 18 if is_cape else 0
    total_extra_transit_days = extra_route_days + (request.custom_transit_days or 0)

    # Cape of Good Hope Bunker Adjustment Factor (+25% freight surcharge)
    simulated_freight_fcy = freight_fcy * 1.25 if is_cape else freight_fcy

    # 3. Customs Values (CIF Base)
    baseline_cif_fcy = fob_fcy + freight_fcy + insurance_fcy
    simulated_cif_fcy = fob_fcy + simulated_freight_fcy + insurance_fcy

    baseline_cif_egp = round(baseline_cif_fcy * base_rate, 2)
    simulated_cif_egp = round(simulated_cif_fcy * simulated_rate, 2)

    # 4. Customs Duties & Taxes
    duty_rate = (request.duty_rate_pct or 5.0) / 100.0
    vat_rate = (request.vat_rate_pct or 14.0) / 100.0
    schedule_rate = (request.schedule_tax_pct or 0.0) / 100.0
    service_fee_rate = 0.025  # Customs administrative & service fees (~2.5%)

    # Baseline Taxes
    base_duty = round(baseline_cif_egp * duty_rate, 2)
    base_schedule = round(baseline_cif_egp * schedule_rate, 2)
    base_service_fees = round(baseline_cif_egp * service_fee_rate, 2)
    base_vat_base = baseline_cif_egp + base_duty + base_schedule + base_service_fees
    base_vat = round(base_vat_base * vat_rate, 2)
    base_customs_total = round(base_duty + base_vat + base_schedule + base_service_fees, 2)

    # Simulated Taxes
    sim_duty = round(simulated_cif_egp * duty_rate, 2)
    sim_schedule = round(simulated_cif_egp * schedule_rate, 2)
    sim_service_fees = round(simulated_cif_egp * service_fee_rate, 2)
    sim_vat_base = simulated_cif_egp + sim_duty + sim_schedule + sim_service_fees
    sim_vat = round(sim_vat_base * vat_rate, 2)
    sim_customs_total = round(sim_duty + sim_vat + sim_schedule + sim_service_fees, 2)

    # 5. Dual-Clock Demurrage & Port Storage
    containers = max(1, request.container_count)
    port_delay = request.port_storage_delay_days

    # Shipping Line Demurrage (USD)
    shipping_line_free_days = 14
    demurrage_days = max(0, port_delay - shipping_line_free_days)
    daily_demurrage_usd_per_ctr = 50.0  # standard 40HC rate
    demurrage_total_usd = demurrage_days * daily_demurrage_usd_per_ctr * containers

    base_demurrage_egp = round(demurrage_total_usd * base_rate, 2)
    sim_demurrage_egp = round(demurrage_total_usd * simulated_rate, 2)

    # Port Authority Storage (EGP)
    port_free_days = 4
    port_storage_days = max(0, port_delay - port_free_days)
    port_storage_egp = 0.0
    if port_storage_days > 0:
        # Tier 1: Days 1-7
        t1 = min(port_storage_days, 7)
        port_storage_egp += t1 * 350.0 * containers
        # Tier 2: Days 8-15
        if port_storage_days > 7:
            t2 = min(port_storage_days - 7, 8)
            port_storage_egp += t2 * 750.0 * containers
        # Tier 3: Days 16+
        if port_storage_days > 15:
            t3 = port_storage_days - 15
            port_storage_egp += t3 * 1400.0 * containers

    # Local clearance and inland transport estimate
    local_logistics_egp = containers * 5500.0

    # 6. Comprehensive Landed Cost
    baseline_landed_cost = round(
        baseline_cif_egp + base_customs_total + base_demurrage_egp + port_storage_egp + local_logistics_egp,
        2,
    )
    simulated_landed_cost = round(
        simulated_cif_egp + sim_customs_total + sim_demurrage_egp + port_storage_egp + local_logistics_egp,
        2,
    )

    cost_variance_amount = round(simulated_landed_cost - baseline_landed_cost, 2)
    cost_variance_pct = round(
        (cost_variance_amount / baseline_landed_cost * 100.0) if baseline_landed_cost > 0 else 0.0,
        2,
    )

    # 7. ACID 180-Day Regulatory Expiry Risk
    acid_risk = _evaluate_acid_risk(
        acid_issuance_date=request.acid_issuance_date,
        current_eta=request.current_eta,
        extra_transit_days=total_extra_transit_days,
    )

    # 8. Risk Scoring & Recommendations
    risk_level, risk_score = _calculate_risk_level_and_score(
        cost_variance_pct=cost_variance_pct,
        acid_status=acid_risk["status"],
        demurrage_days=demurrage_days,
    )

    recommendations = _generate_hedging_recommendations(
        rate_change_pct=request.exchange_rate_change_pct,
        is_cape=is_cape,
        acid_status=acid_risk["status"],
        demurrage_days=demurrage_days,
        cost_variance_pct=cost_variance_pct,
        currency=currency,
    )

    return {
        "baseline_summary": {
            "currency": currency,
            "exchange_rate": base_rate,
            "cif_fcy": baseline_cif_fcy,
            "cif_egp": baseline_cif_egp,
            "customs_and_taxes_egp": base_customs_total,
            "demurrage_usd": demurrage_total_usd,
            "demurrage_egp": base_demurrage_egp,
            "port_storage_egp": port_storage_egp,
            "total_landed_cost_egp": baseline_landed_cost,
        },
        "simulated_summary": {
            "currency": currency,
            "exchange_rate": simulated_rate,
            "rate_change_pct": request.exchange_rate_change_pct,
            "shipping_route": request.shipping_route,
            "total_extra_transit_days": total_extra_transit_days,
            "cif_fcy": simulated_cif_fcy,
            "cif_egp": simulated_cif_egp,
            "customs_and_taxes_egp": sim_customs_total,
            "demurrage_usd": demurrage_total_usd,
            "demurrage_egp": sim_demurrage_egp,
            "port_storage_egp": port_storage_egp,
            "total_landed_cost_egp": simulated_landed_cost,
        },
        "variances": {
            "landed_cost_variance_egp": cost_variance_amount,
            "landed_cost_variance_pct": cost_variance_pct,
            "cif_variance_egp": round(simulated_cif_egp - baseline_cif_egp, 2),
            "customs_duty_variance_egp": round(sim_duty - base_duty, 2),
            "vat_variance_egp": round(sim_vat - base_vat, 2),
            "demurrage_variance_egp": round(sim_demurrage_egp - base_demurrage_egp, 2),
        },
        "customs_breakdown": {
            "duty_rate_pct": request.duty_rate_pct or 5.0,
            "vat_rate_pct": request.vat_rate_pct or 14.0,
            "baseline_duty_egp": base_duty,
            "simulated_duty_egp": sim_duty,
            "baseline_vat_egp": base_vat,
            "simulated_vat_egp": sim_vat,
            "baseline_service_fees_egp": base_service_fees,
            "simulated_service_fees_egp": sim_service_fees,
        },
        "demurrage_and_storage": {
            "shipping_line_free_days": shipping_line_free_days,
            "port_free_days": port_free_days,
            "port_delay_days_applied": port_delay,
            "extra_demurrage_days": demurrage_days,
            "extra_port_storage_days": port_storage_days,
            "demurrage_cost_usd": demurrage_total_usd,
            "port_storage_cost_egp": port_storage_egp,
        },
        "acid_risk_analysis": acid_risk,
        "risk_level": risk_level,
        "risk_score": risk_score,
        "hedging_recommendations": recommendations,
    }


def calculate_open_fx_exposure_service(
    db: Session,
) -> Dict[str, Any]:
    """
    Computes total unhedged foreign currency financial obligations across all active import files.
    Calculates Value-at-Risk under +10% and +25% currency devaluation shocks.
    """
    active_files = repository.get_active_import_files_for_exposure(db)

    # Standard default market conversion rates
    rates = {"USD": 49.50, "EUR": 53.80, "CNY": 6.90, "GBP": 64.20}

    items: List[Dict[str, Any]] = []
    tot_usd = 0.0
    tot_eur = 0.0
    tot_cny = 0.0
    tot_egp_base = 0.0
    tot_egp_10 = 0.0
    tot_egp_25 = 0.0

    for f in active_files:
        curr = (f.estimated_cost_currency or "USD").upper()
        rate = rates.get(curr, 50.0)
        total_fcy = float(f.estimated_cost or 0.0)
        # Outstanding unhedged balance (if partially paid, or full invoice)
        paid_fcy = 0.0
        open_fcy = max(0.0, total_fcy - paid_fcy)

        if open_fcy <= 0:
            continue

        if curr == "USD":
            tot_usd += open_fcy
        elif curr == "EUR":
            tot_eur += open_fcy
        elif curr == "CNY":
            tot_cny += open_fcy

        base_egp = round(open_fcy * rate, 2)
        plus_10_egp = round(base_egp * 1.10, 2)
        plus_25_egp = round(base_egp * 1.25, 2)

        tot_egp_base += base_egp
        tot_egp_10 += plus_10_egp
        tot_egp_25 += plus_25_egp

        items.append({
            "import_file_id": f.import_file_id,
            "import_file_code": f.import_file_code,
            "supplier_name": f.supplier_name or f.supplier_entity_name or "المورد الأجنبي",
            "currency": curr,
            "total_invoice_fcy": total_fcy,
            "paid_fcy": paid_fcy,
            "open_exposure_fcy": open_fcy,
            "official_rate_egp": rate,
            "open_exposure_egp": base_egp,
            "simulated_exposure_egp_at_plus_10_pct": plus_10_egp,
            "simulated_exposure_egp_at_plus_25_pct": plus_25_egp,
        })

    var_10 = round(tot_egp_10 - tot_egp_base, 2)

    strategic_advice = [
        f"إجمالي الانكشاف المالي بالدولار: ${tot_usd:,.2f} وباليورو: €{tot_eur:,.2f}.",
        f"مخاطر تراجع الجنيه بنسبة 10% تمثل أعباء مالية إضافية فورية قدرها {var_10:,.2f} جنيه مصري.",
        "يُنصح بتثبيت أسعار الصرف للشحنات الحرجة عبر عقود شراء آجلة (FX Forwards) مع البنوك المعتمدة.",
        "التعجيل باستخراج نموذج 4 البنكي للشحنات المستوفاة لسداد الفواتير قبل أي تحديث في أسعار الصرف الرسمية.",
    ]

    return {
        "total_open_usd": round(tot_usd, 2),
        "total_open_eur": round(tot_eur, 2),
        "total_open_cny": round(tot_cny, 2),
        "total_open_egp_baseline": round(tot_egp_base, 2),
        "total_open_egp_plus_10_pct": round(tot_egp_10, 2),
        "total_open_egp_plus_25_pct": round(tot_egp_25, 2),
        "var_at_risk_10_pct": var_10,
        "items": items,
        "strategic_advice": strategic_advice,
    }


def save_scenario_service(
    db: Session,
    payload: SavedScenarioCreate,
    current_user: str = "System User",
) -> Dict[str, Any]:
    """Persists a simulation scenario into the database."""
    req = payload.simulation_request
    res = payload.simulation_result

    sim_summary = res.get("simulated_summary") or {}
    variances = res.get("variances") or {}
    acid_risk = res.get("acid_risk_analysis") or {}

    scenario_dict = {
        "scenario_name": payload.scenario_name,
        "import_file_id": payload.import_file_id,
        "base_currency": req.currency or "USD",
        "base_exchange_rate": sim_summary.get("exchange_rate", 50.0),
        "simulated_exchange_rate": sim_summary.get("exchange_rate", 50.0),
        "rate_change_pct": req.exchange_rate_change_pct,
        "shipping_route": req.shipping_route,
        "transit_delay_days": sim_summary.get("total_extra_transit_days", 0),
        "port_storage_delay_days": req.port_storage_delay_days,
        "baseline_landed_cost": res.get("baseline_summary", {}).get("total_landed_cost_egp", 0.0),
        "simulated_landed_cost": sim_summary.get("total_landed_cost_egp", 0.0),
        "cost_variance_amount": variances.get("landed_cost_variance_egp", 0.0),
        "cost_variance_pct": variances.get("landed_cost_variance_pct", 0.0),
        "acid_risk_status": acid_risk.get("status", "SAFE"),
        "risk_level": res.get("risk_level", "LOW"),
        "recommendations": res.get("hedging_recommendations", []),
        "scenario_data": res,
        "created_by": current_user,
    }

    saved = repository.save_simulation_scenario(db, scenario_dict)
    return {
        "scenario_id": saved.scenario_id,
        "scenario_name": saved.scenario_name,
        "import_file_id": saved.import_file_id,
        "base_currency": saved.base_currency,
        "base_exchange_rate": saved.base_exchange_rate,
        "simulated_exchange_rate": saved.simulated_exchange_rate,
        "rate_change_pct": saved.rate_change_pct,
        "shipping_route": saved.shipping_route,
        "transit_delay_days": saved.transit_delay_days,
        "port_storage_delay_days": saved.port_storage_delay_days,
        "baseline_landed_cost": saved.baseline_landed_cost,
        "simulated_landed_cost": saved.simulated_landed_cost,
        "cost_variance_amount": saved.cost_variance_amount,
        "cost_variance_pct": saved.cost_variance_pct,
        "acid_risk_status": saved.acid_risk_status,
        "risk_level": saved.risk_level,
        "recommendations": saved.recommendations or [],
        "created_at": saved.created_at.isoformat() if saved.created_at else "",
        "created_by": saved.created_by,
    }


def list_saved_scenarios_service(
    db: Session,
    limit: int = 50,
    offset: int = 0,
) -> List[Dict[str, Any]]:
    """Lists saved simulation history."""
    scenarios = repository.list_saved_simulation_scenarios(db, limit, offset)
    return [
        {
            "scenario_id": s.scenario_id,
            "scenario_name": s.scenario_name,
            "import_file_id": s.import_file_id,
            "base_currency": s.base_currency,
            "base_exchange_rate": s.base_exchange_rate,
            "simulated_exchange_rate": s.simulated_exchange_rate,
            "rate_change_pct": s.rate_change_pct,
            "shipping_route": s.shipping_route,
            "transit_delay_days": s.transit_delay_days,
            "port_storage_delay_days": s.port_storage_delay_days,
            "baseline_landed_cost": s.baseline_landed_cost,
            "simulated_landed_cost": s.simulated_landed_cost,
            "cost_variance_amount": s.cost_variance_amount,
            "cost_variance_pct": s.cost_variance_pct,
            "acid_risk_status": s.acid_risk_status,
            "risk_level": s.risk_level,
            "recommendations": s.recommendations or [],
            "created_at": s.created_at.isoformat() if s.created_at else "",
            "created_by": s.created_by,
        }
        for s in scenarios
    ]


# ─────────────────────────────────────────────────────────────────────────────
# Internal Helper Functions
# ─────────────────────────────────────────────────────────────────────────────

def _evaluate_acid_risk(
    acid_issuance_date: Optional[str],
    current_eta: Optional[str],
    extra_transit_days: int,
) -> Dict[str, Any]:
    """
    Validates the 180-day Egyptian Customs ACID validity window against arrival ETA.
    """
    total_validity_days = 180

    if not acid_issuance_date or not current_eta:
        return {
            "status": "NOT_APPLICABLE",
            "message_ar": "بيانات تاريخ إصدار ACID أو تاريخ الوصول غير مدخلة للمحاكاة.",
            "remaining_days_at_arrival": None,
            "expiry_date": None,
            "simulated_arrival_date": None,
        }

    try:
        issuance = datetime.strptime(acid_issuance_date[:10], "%Y-%m-%d").date()
        eta = datetime.strptime(current_eta[:10], "%Y-%m-%d").date()
    except Exception:
        return {
            "status": "PARSE_ERROR",
            "message_ar": "صيغة التاريخ غير صالحة، يجب أن تكون YYYY-MM-DD.",
            "remaining_days_at_arrival": None,
            "expiry_date": None,
            "simulated_arrival_date": None,
        }

    expiry_date = issuance + timedelta(days=total_validity_days)
    simulated_arrival = eta + timedelta(days=extra_transit_days)
    remaining_days = (expiry_date - simulated_arrival).days

    if remaining_days < 0:
        status = "EXPIRED_RISK"
        message_ar = (
            f"❌ خطر جسيم: الشحنة ستصل بعد انتهاء صلاحية الـ ACID بـ {abs(remaining_days)} يوماً. "
            f"تاريخ الانتهاء ({expiry_date}) والوصول المحاكى ({simulated_arrival}). "
            "يجب فوراً طلب ملحق مد صلاحية عبر نافذة أو إصدار ACID جديد قبل إبحار السفينة."
        )
    elif remaining_days <= 14:
        status = "CRITICAL_WINDOW"
        message_ar = (
            f"⚠️ تحذير حرج: متبقي {remaining_days} يوماً فقط على انتهاء صلاحية الـ ACID عند الوصول المتوقع. "
            "أي تأخير إضافي في التخليص يهدد برفض الإقرار وإعادة التصدير."
        )
    else:
        status = "SAFE"
        message_ar = f"✅ صلاحية الـ ACID آمنة (متبقي {remaining_days} يوماً كافية للتخليص والإفراج الجمركي)."

    return {
        "status": status,
        "message_ar": message_ar,
        "remaining_days_at_arrival": remaining_days,
        "expiry_date": expiry_date.isoformat(),
        "simulated_arrival_date": simulated_arrival.isoformat(),
        "total_extra_transit_days": extra_transit_days,
    }


def _calculate_risk_level_and_score(
    cost_variance_pct: float,
    acid_status: str,
    demurrage_days: int,
) -> tuple[str, float]:
    """Calculates composite financial and operational risk score (0-100)."""
    score = 10.0

    # Variance impact
    if cost_variance_pct > 0:
        score += min(50.0, cost_variance_pct * 1.5)

    # Demurrage impact
    if demurrage_days > 0:
        score += min(20.0, demurrage_days * 2.0)

    # ACID impact
    if acid_status == "EXPIRED_RISK":
        score += 35.0
    elif acid_status == "CRITICAL_WINDOW":
        score += 20.0

    score = min(100.0, round(score, 1))

    if acid_status == "EXPIRED_RISK" or score >= 75.0 or cost_variance_pct >= 30.0:
        level = "CRITICAL"
    elif score >= 50.0 or cost_variance_pct >= 15.0 or acid_status == "CRITICAL_WINDOW":
        level = "HIGH"
    elif score >= 30.0 or cost_variance_pct >= 5.0:
        level = "MEDIUM"
    else:
        level = "LOW"

    return level, score


def _generate_hedging_recommendations(
    rate_change_pct: float,
    is_cape: bool,
    acid_status: str,
    demurrage_days: int,
    cost_variance_pct: float,
    currency: str,
) -> List[str]:
    """Generates context-aware strategic and treasury mitigation advice."""
    advice: List[str] = []

    if rate_change_pct > 0:
        advice.append(
            f"تثبيت سعر صرف الـ {currency} عبر عقد شراء آجل (FX Forward Contract) مع البنك المتعامل للحد من تكلفة الارتفاع المحتملة."
        )
        advice.append(
            "الإسراع بفتح استمارة نموذج 4 البنكية وسداد المستحقات لتثبيت الوعاء الجمركي قبل صدور أسعار الصرف الرسمية الجديدة."
        )

    if is_cape:
        advice.append(
            "مسار رأس الرجاء الصالح يرفع تكلفة النولون بنسبة تقريبية 25% مع إضافة 18 يوماً زمن إبحار. يُنصح بالتفاوض على شروط Incoterms تتضمن النولون (CFR/CIF)."
        )
        advice.append(
            "التفاوض المسبق مع وكيل الخط الملاحي لمنح الشحنة 21 إلى 28 يوماً سماح مجاني للحاويات بدلاً من 14 يوماً."
        )

    if acid_status == "EXPIRED_RISK":
        advice.append(
            "🚨 إجراء إلزامي فوري: تقديم طلب تمديد لصلاحية القيد الجمركي المسبق ACID عبر منصة نافذة قبل إبحار السفينة لمنع الرفض القطعي للشحنة."
        )
    elif acid_status == "CRITICAL_WINDOW":
        advice.append(
            "تجهيز كافة المستندات الأصلية وإرسالها مسبقاً للمستخلص الجمركي للبدء في إجراءات الفحص المسبق فور وصول الحاوية."
        )

    if demurrage_days > 0:
        advice.append(
            f"تفعيل مسار السحب على عهدة (Under-Bond Release) في اليوم العاشر لتفادي غرامات التوكيل الملاحي بالدولار وأرضيات الميناء بالجنيه."
        )

    if cost_variance_pct > 20.0:
        advice.append(
            "إعادة تسعير المنتجات المستوردة في السوق المحلي بنسبة توازي الارتفاع المحاكى في تكلفة الوصول (Landed Cost) للحفاظ على هامش الربح المستهدف."
        )

    return advice
