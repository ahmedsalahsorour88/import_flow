from datetime import date, timedelta
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from .model import DemurragePolicy, DemurrageTracking
from .schemas import (
    DemurragePolicyCreate,
    DemurragePolicyUpdate,
    DemurrageTrackingCreate,
    DemurrageTrackingUpdate,
    DemurrageSimulationRequest,
    DemurrageSimulationResponse,
    PushToSettlementRequest,
    TierRateItem,
)
from .validators import validate_tier_rates, validate_demurrage_dates, validate_positive_amount
from . import repository


DEFAULT_DEMURRAGE_TIERS = [
    {"from_day": 1, "to_day": 7, "rate_per_day": 40.0},
    {"from_day": 8, "to_day": 14, "rate_per_day": 70.0},
    {"from_day": 15, "to_day": None, "rate_per_day": 120.0},
]

DEFAULT_DETENTION_TIERS = [
    {"from_day": 1, "to_day": 7, "rate_per_day": 35.0},
    {"from_day": 8, "to_day": 14, "rate_per_day": 65.0},
    {"from_day": 15, "to_day": None, "rate_per_day": 110.0},
]


def calculate_tiered_fee(overdue_days: int, tiers: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Calculates the accumulated fee over overdue days based on tiered rate brackets.
    Returns total fee and tier breakdown.
    """
    if overdue_days <= 0 or not tiers:
        return {"total_fee": 0.0, "tier_breakdown": []}

    total_fee = 0.0
    tier_breakdown = []
    
    # Sort tiers by starting day
    sorted_tiers = sorted(tiers, key=lambda t: t.get("from_day", 1))

    for day in range(1, overdue_days + 1):
        matching_rate = 0.0
        applied_tier_name = "Base Tier"
        for t in sorted_tiers:
            from_d = t.get("from_day", 1)
            to_d = t.get("to_day")
            if from_d <= day and (to_d is None or day <= to_d):
                matching_rate = float(t.get("rate_per_day", 0.0))
                applied_tier_name = f"Day {from_d} to {to_d or '∞'}"
                break
        total_fee += matching_rate

    # Generate summary per tier
    for t in sorted_tiers:
        from_d = t.get("from_day", 1)
        to_d = t.get("to_day")
        rate = float(t.get("rate_per_day", 0.0))
        if overdue_days >= from_d:
            days_in_this_tier = min(overdue_days, to_d) - from_d + 1 if to_d else overdue_days - from_d + 1
            days_in_this_tier = max(0, days_in_this_tier)
            cost_in_tier = days_in_this_tier * rate
            tier_breakdown.append({
                "tier_name": f"الأيام {from_d} - {to_d or 'ما بعدها'}",
                "rate_per_day": rate,
                "days_applied": days_in_this_tier,
                "tier_cost": round(cost_in_tier, 2),
            })

    return {"total_fee": round(total_fee, 2), "tier_breakdown": tier_breakdown}


def simulate_demurrage_and_detention(req: DemurrageSimulationRequest) -> DemurrageSimulationResponse:
    """
    Simulates Demurrage, Detention, and Port Storage calculations with full breakdowns.
    """
    validate_demurrage_dates(req.discharge_date, req.gate_out_date, req.empty_return_date)

    calc_date = req.calculation_date or date.today()
    dem_tiers = [t.model_dump() if hasattr(t, 'model_dump') else t for t in (req.demurrage_tiers or DEFAULT_DEMURRAGE_TIERS)]
    det_tiers = [t.model_dump() if hasattr(t, 'model_dump') else t for t in (req.detention_tiers or DEFAULT_DETENTION_TIERS)]

    # 1. Demurrage calculation (Discharge to Gate-Out / Calc Date)
    demurrage_end_date = req.gate_out_date or calc_date
    demurrage_days_consumed = max(0, (demurrage_end_date - req.discharge_date).days)
    demurrage_days_overdue = max(0, demurrage_days_consumed - req.demurrage_free_days)
    demurrage_expiry_date = req.discharge_date + timedelta(days=req.demurrage_free_days)

    dem_calc = calculate_tiered_fee(demurrage_days_overdue, dem_tiers)
    single_container_dem_fx = dem_calc["total_fee"]
    total_demurrage_fx = round(single_container_dem_fx * req.containers_count, 2)

    # 2. Detention calculation (Gate-Out to Empty Return / Calc Date)
    detention_days_consumed = 0
    detention_days_overdue = 0
    total_detention_fx = 0.0
    detention_expiry_date = None
    det_calc = {"total_fee": 0.0, "tier_breakdown": []}

    if req.gate_out_date:
        detention_expiry_date = req.gate_out_date + timedelta(days=req.detention_free_days)
        detention_end_date = req.empty_return_date or calc_date
        detention_days_consumed = max(0, (detention_end_date - req.gate_out_date).days)
        detention_days_overdue = max(0, detention_days_consumed - req.detention_free_days)
        det_calc = calculate_tiered_fee(detention_days_overdue, det_tiers)
        total_detention_fx = round(det_calc["total_fee"] * req.containers_count, 2)

    # 3. Port Storage calculation
    storage_end_date = req.gate_out_date or calc_date
    storage_days_consumed = max(0, (storage_end_date - req.discharge_date).days)
    storage_days_overdue = max(0, storage_days_consumed - req.port_storage_free_days)
    storage_fee_egp = round(storage_days_overdue * req.port_storage_daily_rate_egp * req.containers_count, 2)

    # 4. Totals and Currency Conversions
    total_fee_fx = round(total_demurrage_fx + total_detention_fx, 2)
    total_cost_egp = round((total_fee_fx * req.exchange_rate) + storage_fee_egp, 2)

    # 5. Status & Countdown Summary
    if demurrage_days_overdue > 0 and detention_days_overdue > 0:
        status_badge = "DEMURRAGE_AND_DETENTION_INCURRED"
        countdown_summary = f"⚠️ تم تجاوز فترة السماح: تأخير أرضيات {demurrage_days_overdue} يوم + تأخير فارغ {detention_days_overdue} يوم."
    elif demurrage_days_overdue > 0:
        status_badge = "DEMURRAGE_INCURRED"
        countdown_summary = f"🚨 غرامة أرضيات سارية بمقدار {demurrage_days_overdue} يوم تأخير."
    elif detention_days_overdue > 0:
        status_badge = "DETENTION_INCURRED"
        countdown_summary = f"🚨 غرامة تأخير فارغ سارية بمقدار {detention_days_overdue} يوم تأخير."
    else:
        days_left_demurrage = max(0, req.demurrage_free_days - demurrage_days_consumed)
        if days_left_demurrage <= 3:
            status_badge = "WARNING"
            countdown_summary = f"⚠️ تحذير: متبقي {days_left_demurrage} أيام فقط على انتهاء سماح الأرضيات ({demurrage_expiry_date.strftime('%Y-%m-%d')})."
        else:
            status_badge = "SAFE"
            countdown_summary = f"✅ فترة السماح سارية: متبقي {days_left_demurrage} يوم بدون أي غرامات (حتى {demurrage_expiry_date.strftime('%Y-%m-%d')})."

    breakdown_details = [
        {
            "category": "Demurrage (أرضيات الميناء)",
            "days_consumed": demurrage_days_consumed,
            "free_days": req.demurrage_free_days,
            "days_overdue": demurrage_days_overdue,
            "fee_fx": total_demurrage_fx,
            "currency": req.currency,
            "expiry_date": str(demurrage_expiry_date),
            "tiers_applied": dem_calc.get("tier_breakdown", []),
        },
        {
            "category": "Detention (تأخير الحاوية الفارغة)",
            "days_consumed": detention_days_consumed,
            "free_days": req.detention_free_days,
            "days_overdue": detention_days_overdue,
            "fee_fx": total_detention_fx,
            "currency": req.currency,
            "expiry_date": str(detention_expiry_date) if detention_expiry_date else None,
            "tiers_applied": det_calc.get("tier_breakdown", []),
        },
        {
            "category": "Port Storage (تخزين ساحات الميناء)",
            "days_consumed": storage_days_consumed,
            "free_days": req.port_storage_free_days,
            "days_overdue": storage_days_overdue,
            "fee_egp": storage_fee_egp,
            "currency": "EGP",
        }
    ]

    return DemurrageSimulationResponse(
        demurrage_days_consumed=demurrage_days_consumed,
        demurrage_free_days=req.demurrage_free_days,
        demurrage_days_overdue=demurrage_days_overdue,
        demurrage_fee_fx=total_demurrage_fx,
        demurrage_expiry_date=demurrage_expiry_date,
        detention_days_consumed=detention_days_consumed,
        detention_free_days=req.detention_free_days,
        detention_days_overdue=detention_days_overdue,
        detention_fee_fx=total_detention_fx,
        detention_expiry_date=detention_expiry_date,
        storage_days_consumed=storage_days_consumed,
        storage_free_days=req.port_storage_free_days,
        storage_days_overdue=storage_days_overdue,
        storage_fee_egp=storage_fee_egp,
        total_fee_fx=total_fee_fx,
        total_cost_egp=total_cost_egp,
        status_badge=status_badge,
        countdown_summary_ar=countdown_summary,
        breakdown_details=breakdown_details,
    )


# ----------------------------------------------------
# Policy Service Operations
# ----------------------------------------------------

def create_demurrage_policy_service(db: Session, req: DemurragePolicyCreate, user: str = "System") -> DemurragePolicy:
    validate_tier_rates(req.demurrage_tiers, "Demurrage Tiers")
    validate_tier_rates(req.detention_tiers, "Detention Tiers")

    data = req.model_dump()
    if not data.get("demurrage_tiers"):
        data["demurrage_tiers"] = DEFAULT_DEMURRAGE_TIERS
    if not data.get("detention_tiers"):
        data["detention_tiers"] = DEFAULT_DETENTION_TIERS

    return repository.create_policy(db, data, user=user)


def get_demurrage_policies_service(
    db: Session, carrier_name: Optional[str] = None, container_type: Optional[str] = None
) -> List[DemurragePolicy]:
    return repository.get_policies(db, carrier_name=carrier_name, container_type=container_type)


def get_demurrage_policy_by_id_service(db: Session, policy_id: int) -> DemurragePolicy:
    policy = repository.get_policy_by_id(db, policy_id)
    if not policy:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Demurrage policy #{policy_id} not found.")
    return policy


def update_demurrage_policy_service(
    db: Session, policy_id: int, req: DemurragePolicyUpdate, user: str = "System"
) -> DemurragePolicy:
    policy = get_demurrage_policy_by_id_service(db, policy_id)
    if req.demurrage_tiers:
        validate_tier_rates(req.demurrage_tiers, "Demurrage Tiers")
    if req.detention_tiers:
        validate_tier_rates(req.detention_tiers, "Detention Tiers")

    return repository.update_policy(db, policy, req.model_dump(exclude_unset=True), user=user)


def delete_demurrage_policy_service(db: Session, policy_id: int, user: str = "System") -> DemurragePolicy:
    policy = get_demurrage_policy_by_id_service(db, policy_id)
    return repository.delete_policy(db, policy, user=user)


# ----------------------------------------------------
# Tracking Service Operations
# ----------------------------------------------------

def create_demurrage_tracking_service(
    db: Session, req: DemurrageTrackingCreate, user: str = "System"
) -> DemurrageTracking:
    validate_demurrage_dates(req.discharge_date, req.gate_out_date, req.empty_return_date)
    validate_positive_amount(req.exchange_rate, "exchange_rate")

    # Fetch policy if provided or search matching policy
    policy = None
    if req.policy_id:
        policy = repository.get_policy_by_id(db, req.policy_id)
    if not policy and req.carrier_name:
        first_container_type = req.containers[0].container_type if req.containers else "40ft High Cube"
        policy = repository.get_policy_for_carrier_container(db, req.carrier_name, first_container_type)

    dem_free = policy.demurrage_free_days if policy else 14
    det_free = policy.detention_free_days if policy else 7
    storage_free = policy.port_storage_free_days if policy else 5
    storage_rate = policy.port_storage_daily_rate_egp if policy else 250.0
    dem_tiers = policy.demurrage_tiers if policy else DEFAULT_DEMURRAGE_TIERS
    det_tiers = policy.detention_tiers if policy else DEFAULT_DETENTION_TIERS

    # Calculate per container
    calculated_containers = []
    total_dem_fx = 0.0
    total_det_fx = 0.0
    total_stor_egp = 0.0

    for c in req.containers:
        sim = simulate_demurrage_and_detention(DemurrageSimulationRequest(
            carrier_name=req.carrier_name,
            container_type=c.container_type,
            containers_count=1,
            demurrage_free_days=dem_free,
            detention_free_days=det_free,
            port_storage_free_days=storage_free,
            port_storage_daily_rate_egp=storage_rate,
            demurrage_tiers=dem_tiers,
            detention_tiers=det_tiers,
            discharge_date=req.discharge_date,
            gate_out_date=req.gate_out_date,
            empty_return_date=req.empty_return_date,
            currency=req.currency,
            exchange_rate=req.exchange_rate,
        ))

        c_item = {
            "container_no": c.container_no,
            "container_type": c.container_type,
            "demurrage_days": sim.demurrage_days_overdue,
            "detention_days": sim.detention_days_overdue,
            "storage_days": sim.storage_days_overdue,
            "demurrage_fx": sim.demurrage_fee_fx,
            "detention_fx": sim.detention_fee_fx,
            "storage_egp": sim.storage_fee_egp,
            "total_egp": sim.total_cost_egp,
            "status": sim.status_badge,
        }
        calculated_containers.append(c_item)
        total_dem_fx += sim.demurrage_fee_fx
        total_det_fx += sim.detention_fee_fx
        total_stor_egp += sim.storage_fee_egp

    total_cost_egp = round(((total_dem_fx + total_det_fx) * req.exchange_rate) + total_stor_egp, 2)

    # Determine overall status
    if total_dem_fx > 0 and total_det_fx > 0:
        overall_status = "Demurrage & Detention Incurred"
    elif total_dem_fx > 0:
        overall_status = "Demurrage Incurred"
    elif total_det_fx > 0:
        overall_status = "Detention Incurred"
    else:
        overall_status = "Free Time Active"

    tracking_data = {
        "tracking_code": repository.generate_tracking_code(db),
        "import_file_id": req.import_file_id,
        "import_file_code": req.import_file_code,
        "policy_id": policy.policy_id if policy else None,
        "carrier_name": req.carrier_name,
        "bill_of_lading_no": req.bill_of_lading_no,
        "port_name": req.port_name,
        "discharge_date": req.discharge_date,
        "gate_out_date": req.gate_out_date,
        "empty_return_date": req.empty_return_date,
        "containers": calculated_containers,
        "total_demurrage_fx": round(total_dem_fx, 2),
        "total_detention_fx": round(total_det_fx, 2),
        "total_storage_egp": round(total_stor_egp, 2),
        "currency": req.currency,
        "exchange_rate": req.exchange_rate,
        "total_cost_egp": total_cost_egp,
        "status": overall_status,
        "notes": req.notes,
    }

    return repository.create_tracking(db, tracking_data, user=user)


def get_demurrage_trackings_service(
    db: Session,
    import_file_id: Optional[int] = None,
    carrier_name: Optional[str] = None,
    status_filter: Optional[str] = None,
) -> List[DemurrageTracking]:
    return repository.get_trackings(db, import_file_id=import_file_id, carrier_name=carrier_name, status_filter=status_filter)


def get_demurrage_tracking_by_id_service(db: Session, tracking_id: int) -> DemurrageTracking:
    tracking = repository.get_tracking_by_id(db, tracking_id)
    if not tracking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Demurrage tracking #{tracking_id} not found.")
    return tracking


def recalculate_and_update_tracking_service(
    db: Session, tracking_id: int, req: DemurrageTrackingUpdate, user: str = "System"
) -> DemurrageTracking:
    tracking = get_demurrage_tracking_by_id_service(db, tracking_id)
    
    gate_out = req.gate_out_date or tracking.gate_out_date
    empty_return = req.empty_return_date or tracking.empty_return_date
    rate = req.exchange_rate or tracking.exchange_rate
    validate_demurrage_dates(tracking.discharge_date, gate_out, empty_return)

    policy = tracking.policy
    dem_free = policy.demurrage_free_days if policy else 14
    det_free = policy.detention_free_days if policy else 7
    storage_free = policy.port_storage_free_days if policy else 5
    storage_rate = policy.port_storage_daily_rate_egp if policy else 250.0
    dem_tiers = policy.demurrage_tiers if policy else DEFAULT_DEMURRAGE_TIERS
    det_tiers = policy.detention_tiers if policy else DEFAULT_DETENTION_TIERS

    recalculated_containers = []
    total_dem_fx = 0.0
    total_det_fx = 0.0
    total_stor_egp = 0.0

    for c in (tracking.containers or []):
        c_no = c.get("container_no", "")
        c_type = c.get("container_type", "40ft High Cube")
        sim = simulate_demurrage_and_detention(DemurrageSimulationRequest(
            carrier_name=tracking.carrier_name,
            container_type=c_type,
            containers_count=1,
            demurrage_free_days=dem_free,
            detention_free_days=det_free,
            port_storage_free_days=storage_free,
            port_storage_daily_rate_egp=storage_rate,
            demurrage_tiers=dem_tiers,
            detention_tiers=det_tiers,
            discharge_date=tracking.discharge_date,
            gate_out_date=gate_out,
            empty_return_date=empty_return,
            currency=tracking.currency,
            exchange_rate=rate,
        ))
        recalculated_containers.append({
            "container_no": c_no,
            "container_type": c_type,
            "demurrage_days": sim.demurrage_days_overdue,
            "detention_days": sim.detention_days_overdue,
            "storage_days": sim.storage_days_overdue,
            "demurrage_fx": sim.demurrage_fee_fx,
            "detention_fx": sim.detention_fee_fx,
            "storage_egp": sim.storage_fee_egp,
            "total_egp": sim.total_cost_egp,
            "status": sim.status_badge,
        })
        total_dem_fx += sim.demurrage_fee_fx
        total_det_fx += sim.detention_fee_fx
        total_stor_egp += sim.storage_fee_egp

    total_cost_egp = round(((total_dem_fx + total_det_fx) * rate) + total_stor_egp, 2)
    
    if total_dem_fx > 0 and total_det_fx > 0:
        overall_status = "Demurrage & Detention Incurred"
    elif total_dem_fx > 0:
        overall_status = "Demurrage Incurred"
    elif total_det_fx > 0:
        overall_status = "Detention Incurred"
    else:
        overall_status = "Free Time Active"

    data = {
        "gate_out_date": gate_out,
        "empty_return_date": empty_return,
        "exchange_rate": rate,
        "containers": recalculated_containers,
        "total_demurrage_fx": round(total_dem_fx, 2),
        "total_detention_fx": round(total_det_fx, 2),
        "total_storage_egp": round(total_stor_egp, 2),
        "total_cost_egp": total_cost_egp,
        "status": req.status or overall_status,
        "notes": req.notes or tracking.notes,
    }

    return repository.update_tracking(db, tracking, data, user=user)


def push_demurrage_to_financial_settlement_service(
    db: Session, req: PushToSettlementRequest, user: str = "System"
) -> Dict[str, Any]:
    """
    Pushes calculated Demurrage, Detention, and Storage expenses directly into Phase 9 Financial Settlement record.
    """
    tracking = get_demurrage_tracking_by_id_service(db, req.tracking_id)
    file_id = req.import_file_id or tracking.import_file_id

    if not file_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="لا يمكن ترحيل الغرامات بدون ربط جلسة التتبع برقم ملف استيراد (Import File ID).",
        )

    from modules.financial_settlement.model import LandedCostSettlementRecord

    settlement = db.query(LandedCostSettlementRecord).filter(
        LandedCostSettlementRecord.import_file_id == file_id,
        LandedCostSettlementRecord.is_active == True,
    ).first()

    if not settlement:
        # Create a new settlement record
        count = db.query(LandedCostSettlementRecord).count()
        settlement = LandedCostSettlementRecord(
            settlement_code=f"LCS-2026-{count + 1:04d}",
            import_file_id=file_id,
            accountant_name=req.accountant_name or "ImportFlow Accountant",
            expense_invoices=[],
            created_by=user,
            updated_by=user,
        )
        db.add(settlement)
        db.commit()
        db.refresh(settlement)

    invoices = list(settlement.expense_invoices or [])
    
    # Check if demurrage invoice already added for this tracking
    inv_no = f"INV-DND-{tracking.tracking_code}"
    existing_inv = next((inv for inv in invoices if inv.get("invoice_no") == inv_no), None)

    invoice_entry = {
        "invoice_no": inv_no,
        "category": "Demurrage & Storage",
        "provider_name": tracking.carrier_name,
        "currency": tracking.currency,
        "amount_fx": round(tracking.total_demurrage_fx + tracking.total_detention_fx, 2),
        "exchange_rate": tracking.exchange_rate,
        "amount_egp": tracking.total_cost_egp,
        "allocation_rule": "Volume-Based",
        "notes": f"Automated Demurrage & Detention fee for B/L: {tracking.bill_of_lading_no} (Tracking: {tracking.tracking_code})",
    }

    if existing_inv:
        invoices.remove(existing_inv)
    invoices.append(invoice_entry)

    settlement.expense_invoices = invoices
    settlement.total_expenses_egp = round(sum(float(i.get("amount_egp", 0.0)) for i in invoices), 2)
    settlement.updated_by = user
    
    tracking.is_pushed_to_settlement = True
    tracking.settlement_record_id = settlement.settlement_id
    tracking.status = "Pushed to Settlement"
    tracking.updated_by = user

    db.commit()
    db.refresh(settlement)
    db.refresh(tracking)

    return {
        "success": True,
        "message": f"تم ترحيل غرامات الحاويات بقيمة {tracking.total_cost_egp:,.2f} جنيه إلى التسوية المالية لملف الاستيراد بنجاح.",
        "settlement_id": settlement.settlement_id,
        "settlement_code": settlement.settlement_code,
        "invoice_entry": invoice_entry,
    }
