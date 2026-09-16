"""
Centralized Recalculation Engine — Service Layer (CRE-001)

This is the SINGLE place that:
1. Reads dependency relationships from recalculation_dependency_map.
2. Fetches live values from source entities dynamically.
3. Computes variance and determines action type.
4. Applies changes respecting immutability rules and permissions.
5. Writes unified audit logs to recalculation_logs.

ARCHITECTURAL RULE:
  No page, screen, or router may implement their own "sync" or "compare" logic.
  All pages call preview() then apply() from this service exclusively.
"""

import json
from datetime import datetime, date, timezone
from typing import List, Optional, Any, Dict
from sqlalchemy import func
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from modules.recalculation.model import RecalculationDependencyMap, RecalculationLog
import modules.recalculation.repository as repo
from modules.recalculation.schemas import (
    RecalculationPreviewItem,
    RecalculationPreviewResponse,
    RecalculationApplyRequest,
    RecalculationApplyResult,
)
from modules.users.model import User
from modules.auth.permissions import has_user_permission


# ──────────────────────────────────────────────────────────────────────────────
# Source Fetching Registry
# ──────────────────────────────────────────────────────────────────────────────
# Maps source_entity_type → callable(db, join_key_value, source_field, aggregation) → float
# Every new source entity type needs ONE entry here and ONE seed row in the DB table.
# Nothing else changes.

def _fetch_from_customs_consultation(
    db: Session, join_key_value: Any, source_field: str, aggregation: str
) -> float:
    """Fetches live value from CustomsConsultationSession."""
    from modules.customs_consultation.model import CustomsConsultationSession
    q = db.query(CustomsConsultationSession).filter(
        CustomsConsultationSession.import_file_id == join_key_value,
        CustomsConsultationSession.is_active == True,
    )
    sessions = q.all()
    if not sessions:
        return 0.0

    values = [float(getattr(s, source_field, 0.0) or 0.0) for s in sessions]
    return _aggregate(values, aggregation)


def _fetch_from_shipping_scenarios(
    db: Session, join_key_value: Any, source_field: str, aggregation: str
) -> float:
    """
    Fetches live value from ShippingEvaluationSession + ShippingScenarioItem.
    For total_quotation_amount: uses the RECOMMENDED item (is_recommended=True),
    falling back to the item with the highest is_selected flag, then max.
    """
    from modules.shipping_scenarios.model import ShippingEvaluationSession, ShippingScenarioItem
    sessions = db.query(ShippingEvaluationSession).filter(
        ShippingEvaluationSession.import_file_id == join_key_value,
        ShippingEvaluationSession.is_active == True,
    ).all()
    if not sessions:
        return 0.0

    values = []
    for session in sessions:
        items = db.query(ShippingScenarioItem).filter(
            ShippingScenarioItem.session_id == session.session_id
        ).all()
        if not items:
            continue

        # Priority: recommended → selected → aggregate
        preferred = next((i for i in items if i.is_recommended), None)
        if preferred is None:
            preferred = next((i for i in items if i.is_selected), None)

        if preferred:
            val = float(getattr(preferred, source_field, 0.0) or 0.0)
            values.append(val)
        else:
            # No recommendation: use the aggregation function across items
            item_vals = [float(getattr(i, source_field, 0.0) or 0.0) for i in items]
            values.append(_aggregate(item_vals, aggregation))

    return _aggregate(values, aggregation)


def _fetch_from_purchase_orders(
    db: Session, join_key_value: Any, source_field: str, aggregation: str
) -> float:
    """
    Fetches live value from PurchaseOrder.
    total_amount_fob is in foreign currency → convert to EGP using exchange_rate.
    The budgeted field is invoice_amount_egp.
    """
    from modules.purchase_orders.model import PurchaseOrder
    pos = db.query(PurchaseOrder).filter(
        PurchaseOrder.import_file_id == join_key_value,
        PurchaseOrder.is_active == True,
    ).all()
    if not pos:
        return 0.0

    values = []
    for po in pos:
        raw = float(getattr(po, source_field, 0.0) or 0.0)
        # Convert FOB foreign to EGP using PO exchange rate
        rate = float(po.exchange_rate or 1.0)
        values.append(raw * rate)

    return _aggregate(values, aggregation)


# Registry mapping source_entity_type → fetcher function
_SOURCE_FETCHERS: Dict[str, Any] = {
    "customs_consultation": _fetch_from_customs_consultation,
    "shipping_scenarios": _fetch_from_shipping_scenarios,
    "purchase_orders": _fetch_from_purchase_orders,
}


def _aggregate(values: List[float], func_name: str) -> float:
    """Applies the aggregation function to a list of float values."""
    if not values:
        return 0.0
    func_map = {
        "max": max,
        "min": min,
        "sum": sum,
        "latest": lambda v: v[-1],  # assumes list is chronologically ordered
    }
    fn = func_map.get(func_name, max)
    return round(fn(values), 4)


# ──────────────────────────────────────────────────────────────────────────────
# Target Entity Registry
# ──────────────────────────────────────────────────────────────────────────────

def _load_target_entity(db: Session, target_entity_type: str, entity_id: int) -> Any:
    """Resolves and returns the target entity from the DB."""
    if target_entity_type == "import_budget":
        from modules.financial_approval.model import ImportBudgetApproval
        entity = db.query(ImportBudgetApproval).filter(
            ImportBudgetApproval.budget_id == entity_id,
            ImportBudgetApproval.is_active == True,
        ).first()
        if not entity:
            raise HTTPException(status_code=404, detail=f"Import Budget [{entity_id}] not found.")
        return entity
    elif target_entity_type == "financial_settlement":
        from modules.financial_settlement.model import LandedCostSettlementRecord
        entity = db.query(LandedCostSettlementRecord).filter(
            LandedCostSettlementRecord.settlement_id == entity_id,
            LandedCostSettlementRecord.is_active == True,
        ).first()
        if not entity:
            raise HTTPException(status_code=404, detail=f"Financial Settlement [{entity_id}] not found.")
        return entity
    # Future entity types: add here
    raise HTTPException(status_code=400, detail=f"Unknown target entity type: '{target_entity_type}'")


def _get_entity_status(entity: Any, target_entity_type: str) -> str:
    """Returns the current status string of the entity."""
    if target_entity_type == "import_budget":
        return entity.budget_status
    elif target_entity_type == "financial_settlement":
        return entity.status
    return "Unknown"


def _get_entity_join_key_value(entity: Any, target_entity_type: str, join_key: str) -> Any:
    """Extracts the join key value from the entity."""
    val = getattr(entity, join_key, None)
    if val is None:
        raise HTTPException(
            status_code=422,
            detail=f"Entity [{target_entity_type}] does not have join key '{join_key}' or its value is None."
        )
    return val


def _get_entity_field_value(entity: Any, field_name: str, target_entity_type: str = "") -> float:
    """Gets the current float value of a field from the entity."""
    if target_entity_type == "financial_settlement" or hasattr(entity, "expense_invoices"):
        if field_name == "total_fob_egp":
            return float(getattr(entity, "total_fob_egp", 0.0) or 0.0)

        # Virtual expense field lookup from JSON expense_invoices
        category_map = {
            "freight_cost_egp": ("Freight", "Shipping", "Ocean Freight", "Air Freight"),
            "customs_duties_egp": ("Customs Duty", "Customs", "Taxes", "VAT", "Import Duty"),
            "clearance_fees_egp": ("Brokerage", "Clearance", "Brokerage Fees", "Customs Clearance", "Local Transport", "Transport", "Trucking", "Inland Transport"),
        }
        if field_name in category_map:
            kw_list = category_map[field_name]
            invoices = getattr(entity, "expense_invoices", []) or []
            tot = 0.0
            for exp in invoices:
                cat = exp.get("category", "")
                if any(kw.lower() in cat.lower() for kw in kw_list):
                    tot += float(exp.get("amount_egp", 0.0) or 0.0)
            return round(tot, 4)

    return float(getattr(entity, field_name, 0.0) or 0.0)


def _apply_field_to_entity(entity: Any, field_name: str, new_value: float, target_entity_type: str):
    """Sets a field on the entity in memory. Does NOT commit."""
    if target_entity_type == "financial_settlement" or hasattr(entity, "expense_invoices"):
        if field_name == "total_fob_egp":
            entity.total_fob_egp = new_value
            items = [dict(i) for i in (entity.item_landed_costs or [])]
            old_fob = sum(i.get("fob_total_egp", 0.0) for i in items)
            if old_fob > 0 and new_value > 0:
                ratio = new_value / old_fob
                for itm in items:
                    itm["fob_total_egp"] = round(itm.get("fob_total_egp", 0.0) * ratio, 2)
                    qty = max(itm.get("qty", 1), 1)
                    itm["fob_unit_egp"] = round(itm["fob_total_egp"] / qty, 2)
                entity.item_landed_costs = items
            return

        cat_defaults = {
            "freight_cost_egp": ("Freight", "Volume-Based", ("Freight", "Shipping", "Ocean Freight", "Air Freight")),
            "customs_duties_egp": ("Customs Duty", "Value-Based", ("Customs Duty", "Customs", "Taxes", "VAT", "Import Duty")),
            "clearance_fees_egp": ("Brokerage", "Equal", ("Brokerage", "Clearance", "Brokerage Fees", "Customs Clearance")),
        }
        if field_name in cat_defaults:
            default_cat, alloc_rule, kw_tuple = cat_defaults[field_name]
            invoices = [dict(x) for x in (entity.expense_invoices or [])]
            matched = False
            for exp in invoices:
                cat = exp.get("category", "")
                if any(kw.lower() in cat.lower() for kw in kw_tuple):
                    rate = float(exp.get("exchange_rate", 1.0) or 1.0)
                    exp["amount_egp"] = round(new_value, 2)
                    exp["amount_fx"] = round(new_value / rate, 2) if rate > 0 else new_value
                    matched = True
                    break
            if not matched:
                invoices.append({
                    "invoice_no": f"AUTO-{field_name[:3].upper()}",
                    "category": default_cat,
                    "provider_name": "Upstream Sync",
                    "currency": "EGP",
                    "amount_fx": round(new_value, 2),
                    "exchange_rate": 1.0,
                    "amount_egp": round(new_value, 2),
                    "allocation_rule": alloc_rule,
                })
            entity.expense_invoices = invoices
            return

    setattr(entity, field_name, new_value)


def _get_entity_code(entity: Any, target_entity_type: str) -> Optional[str]:
    if target_entity_type == "import_budget":
        return getattr(entity, "budget_code", None)
    elif target_entity_type == "financial_settlement":
        return getattr(entity, "settlement_code", None)
    return None



def _create_revision_for_approved_budget(
    db: Session, entity: Any, applied_changes: list, performed_by: str, justification: Optional[str]
) -> Any:
    """
    Creates a Revision for an Approved budget. The original becomes 'Superseded'.
    Returns the new revision entity.
    """
    from modules.financial_approval.model import ImportBudgetApproval
    from modules.common.sequence_generator import generate_reference_code

    now = datetime.now(timezone.utc)
    rev_num = (entity.revision_number or 1) + 1

    new_code = generate_reference_code(db, ImportBudgetApproval, prefix="BDG", id_field="budget_id")
    # Build the new revision with updated field values

    new_budget = ImportBudgetApproval(
        budget_code=new_code,
        title=f"{entity.title} (Rev {rev_num})",
        import_file_id=entity.import_file_id,
        po_id=entity.po_id,
        project_id=entity.project_id,
        invoice_amount_egp=entity.invoice_amount_egp,
        invoice_amount_foreign=entity.invoice_amount_foreign,
        invoice_currency=entity.invoice_currency,
        freight_cost_egp=entity.freight_cost_egp,
        freight_cost_foreign=entity.freight_cost_foreign,
        freight_currency=entity.freight_currency,
        customs_duties_egp=entity.customs_duties_egp,
        clearance_inland_egp=entity.clearance_inland_egp,
        exchange_rate=entity.exchange_rate,
        total_budget_egp=entity.total_budget_egp,
        budget_status="Pending Review",
        parent_budget_id=entity.budget_id,
        revision_number=rev_num,
        notes=(entity.notes or ""),
        has_unresolved_variance=False,
        last_variance_check=now,
        upstream_modified_by=performed_by,
        variance_override_reason=justification,
        variance_overridden_by=performed_by if justification else None,
    )

    # Apply the new field values to the revision
    for change in applied_changes:
        _apply_field_to_entity(new_budget, change["field_name"], change["new_value"], "import_budget")

    # Recalculate total
    new_budget.total_budget_egp = (
        new_budget.invoice_amount_egp
        + new_budget.freight_cost_egp
        + new_budget.customs_duties_egp
        + new_budget.clearance_inland_egp
    )

    # Supersede the original
    entity.budget_status = "Superseded"
    entity.is_active = False

    db.add(new_budget)
    db.flush()
    return new_budget


def _apply_in_place_to_entity(
    db: Session,
    entity: Any,
    applied_changes: list,
    target_entity_type: str,
    performed_by: str,
    justification: Optional[str],
) -> str:
    """
    Applies changes directly to the entity (for Draft / Pending Review status).
    Returns action_taken string.
    """
    now = datetime.now(timezone.utc)

    for change in applied_changes:
        _apply_field_to_entity(entity, change["field_name"], change["new_value"], target_entity_type)

    # Post-apply for import_budget
    if target_entity_type == "import_budget":
        entity.total_budget_egp = (
            entity.invoice_amount_egp
            + entity.freight_cost_egp
            + entity.customs_duties_egp
            + entity.clearance_inland_egp
        )
        entity.has_unresolved_variance = False
        entity.last_variance_check = now
        entity.upstream_modified_by = performed_by
        if justification:
            entity.variance_override_reason = justification
            entity.variance_overridden_by = performed_by

        current_status = entity.budget_status
        if current_status == "Draft":
            action_taken = "auto_updated"
        else:
            # Needs Revalidation or Pending Review: keep in revalidation
            entity.budget_status = "Pending Review"
            action_taken = "revalidation_required"

    elif target_entity_type == "financial_settlement":
        from modules.financial_settlement.service import calculate_landed_cost_engine
        incoterm = getattr(entity, "incoterm_code", "FOB") or "FOB"
        calc_res = calculate_landed_cost_engine(
            entity.expense_invoices or [],
            entity.item_landed_costs or [],
            incoterm=incoterm,
        )
        entity.total_fob_egp = calc_res["total_fob_egp"]
        entity.total_expenses_egp = calc_res["total_expenses_egp"]
        entity.total_landed_cost_egp = calc_res["total_landed_cost_egp"]
        entity.average_markup_factor = calc_res["average_markup_factor"]
        entity.item_landed_costs = calc_res["item_landed_costs"]
        entity.status = "Calculated"
        entity.updated_by = performed_by
        entity.updated_at = now
        action_taken = "recalculated"

    return action_taken if target_entity_type in ("import_budget", "financial_settlement") else "auto_updated"



# ──────────────────────────────────────────────────────────────────────────────
# Core Engine: preview()
# ──────────────────────────────────────────────────────────────────────────────

def preview(
    db: Session,
    target_entity_type: str,
    target_entity_id: int,
    source_page: str,
    performed_by: Optional[str] = "System",
) -> RecalculationPreviewResponse:
    """
    Compares current stored values in the target entity against live upstream values.
    Logs the preview action. Does NOT modify any data.
    """
    # 1. Load entity and get its dependencies
    entity = _load_target_entity(db, target_entity_type, target_entity_id)
    current_status = _get_entity_status(entity, target_entity_type)
    dependencies = repo.get_active_dependencies_for_target(db, target_entity_type)

    # 2. Load variance threshold (if relevant to entity type)
    threshold_pct = _get_variance_threshold(db, target_entity_type)

    # 3. Check if entity status blocks apply
    blocked_by_status = False
    items: List[RecalculationPreviewItem] = []
    has_hard_block = False
    max_variance_pct = 0.0
    can_apply = True

    # Collect all blocked_statuses across all deps
    all_blocked_statuses: set = set()
    for dep in dependencies:
        for s in dep.blocked_statuses_list:
            all_blocked_statuses.add(s)

    if current_status in all_blocked_statuses:
        blocked_by_status = True
        can_apply = False  # Will only be True if Revision engine is enabled

    # For Approved budgets: apply() creates Revision, so can_apply = True
    if target_entity_type == "import_budget" and current_status == "Budget Approved":
        blocked_by_status = True
        can_apply = True  # Revision creation is always allowed with permission

    # For Approved financial settlements: apply() recalculates and resets to Calculated, so can_apply = True
    if target_entity_type == "financial_settlement" and current_status == "Approved":
        blocked_by_status = True
        can_apply = True

    # 4. Fetch live values and compute variances
    for dep in dependencies:
        join_key_value = _get_entity_join_key_value(entity, target_entity_type, dep.join_key)
        old_value = _get_entity_field_value(entity, dep.target_field, target_entity_type)


        fetcher = _SOURCE_FETCHERS.get(dep.source_entity_type)
        if fetcher is None:
            # Unknown source type — skip gracefully
            continue

        new_value = fetcher(db, join_key_value, dep.source_field, dep.aggregation_function)
        variance_amount = new_value - old_value

        if old_value == 0.0:
            variance_pct = 100.0 if abs(variance_amount) > 0.01 else 0.0
        else:
            variance_pct = round((abs(variance_amount) / old_value) * 100.0, 4)

        is_hard = variance_pct > threshold_pct and abs(variance_amount) > 1.0
        if is_hard:
            has_hard_block = True
        if variance_pct > max_variance_pct:
            max_variance_pct = variance_pct

        items.append(RecalculationPreviewItem(
            field_name=dep.target_field,
            label_ar=dep.label_ar or dep.target_field,
            label_en=dep.label_en or dep.target_field,
            old_value=old_value,
            new_value=new_value,
            variance_amount=round(variance_amount, 4),
            variance_percentage=variance_pct,
            is_hard_block=is_hard,
            threshold_percentage=threshold_pct,
            source_entity_type=dep.source_entity_type,
            dependency_id=dep.id,
        ))

    has_any_variance = any(abs(i.variance_amount) > 0.01 for i in items)

    # 5. Build message
    if not has_any_variance:
        message_ar = "✅ لا توجد فوارق — جميع التكاليف متطابقة مع المصادر الحية."
    elif has_hard_block:
        message_ar = f"🔴 تحذير: تم رصد فارق يتجاوز الحد المسموح ({threshold_pct}%). مطلوب مبرر كتابي قبل التحديث."
    else:
        message_ar = f"⚠️ تم رصد فوارق في التكاليف (أقل من {threshold_pct}%). يمكنك المزامنة مع تحذير."

    # 6. Log the preview action
    preview_data_for_log = [
        {
            "field_name": i.field_name,
            "old_value": i.old_value,
            "new_value": i.new_value,
            "variance_amount": i.variance_amount,
            "variance_pct": i.variance_percentage,
            "is_hard_block": i.is_hard_block,
        }
        for i in items
    ]
    repo.create_log(
        db=db,
        target_entity_type=target_entity_type,
        target_entity_id=target_entity_id,
        action="preview",
        performed_by=performed_by,
        source_page=source_page,
        preview_data=preview_data_for_log,
        result_status="has_variance" if has_any_variance else "no_changes",
    )

    return RecalculationPreviewResponse(
        target_entity_type=target_entity_type,
        target_entity_id=target_entity_id,
        items=items,
        has_any_variance=has_any_variance,
        has_hard_block=has_hard_block,
        max_variance_pct=round(max_variance_pct, 2),
        blocked_by_status=blocked_by_status,
        current_entity_status=current_status,
        can_apply=can_apply,
        message_ar=message_ar,
    )


# ──────────────────────────────────────────────────────────────────────────────
# Core Engine: apply()
# ──────────────────────────────────────────────────────────────────────────────

def apply(
    db: Session,
    request: RecalculationApplyRequest,
    current_user: User,
) -> RecalculationApplyResult:
    """
    Applies live upstream values to the target entity.

    Rules (enforced centrally, NOT in pages):
    1. Permission check: user must have required_permission from dependency map.
    2. Segregation of Duties (SoD): user who modified upstream CANNOT sync if entity is Approved/Superseded.
    3. Hard Block: if variance > threshold AND no justification → HTTP 400.
    4. Immutability: if entity status is Approved → create Revision, mark original Superseded.
    5. Draft / Pending: update in-place.
    6. Unified audit log entry created for every apply.
    """
    target_entity_type = request.target_entity_type
    target_entity_id = request.target_entity_id
    justification = request.justification
    source_page = request.source_page
    performed_by = current_user.username

    # 1. Load entity
    entity = _load_target_entity(db, target_entity_type, target_entity_id)
    current_status = _get_entity_status(entity, target_entity_type)
    dependencies = repo.get_active_dependencies_for_target(db, target_entity_type)
    threshold_pct = _get_variance_threshold(db, target_entity_type)

    # 2. Permission check (uses most restrictive permission found in dependency map)
    required_perms = set(dep.required_permission for dep in dependencies if dep.required_permission)
    for perm in required_perms:
        if not has_user_permission(db, current_user, perm):
            log = repo.create_log(
                db=db,
                target_entity_type=target_entity_type,
                target_entity_id=target_entity_id,
                action="apply",
                performed_by=performed_by,
                source_page=source_page,
                result_status="blocked_permission",
                justification=justification,
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"ليس لديك صلاحية '{perm}' لتنفيذ المزامنة. يُرجى التواصل مع مدير النظام.",
            )

    # 3. Segregation of Duties check (for import_budget)
    if target_entity_type == "import_budget":
        upstream_mod = getattr(entity, "upstream_modified_by", None)
        is_admin = current_user.role == "ADMIN"
        if (
            upstream_mod
            and upstream_mod.lower() == performed_by.lower()
            and not is_admin
            and current_status in ("Budget Approved", "Superseded")
        ):
            repo.create_log(
                db=db,
                target_entity_type=target_entity_type,
                target_entity_id=target_entity_id,
                action="apply",
                performed_by=performed_by,
                source_page=source_page,
                result_status="blocked_sod",
                justification=justification,
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="فصل المهام (SoD): المستخدم الذي عدّل التكاليف الأصلية لا يمكنه مزامنة الميزانية المعتمدة. يرجى تعيين مستخدم آخر.",
            )

    # 4. Fetch live values and build applied_changes
    applied_changes = []
    has_hard_block = False

    for dep in dependencies:
        join_key_value = _get_entity_join_key_value(entity, target_entity_type, dep.join_key)
        old_value = _get_entity_field_value(entity, dep.target_field, target_entity_type)

        fetcher = _SOURCE_FETCHERS.get(dep.source_entity_type)
        if fetcher is None:
            continue

        new_value = fetcher(db, join_key_value, dep.source_field, dep.aggregation_function)
        variance_amount = new_value - old_value

        if old_value == 0.0:
            variance_pct = 100.0 if abs(variance_amount) > 0.01 else 0.0
        else:
            variance_pct = round((abs(variance_amount) / old_value) * 100.0, 4)

        is_hard = variance_pct > threshold_pct and abs(variance_amount) > 1.0
        if is_hard:
            has_hard_block = True

        if abs(variance_amount) > 0.01:
            applied_changes.append({
                "field_name": dep.target_field,
                "old_value": old_value,
                "new_value": new_value,
                "variance_amount": round(variance_amount, 4),
                "variance_pct": variance_pct,
                "is_hard_block": is_hard,
            })

    # 5. Hard Block check
    if has_hard_block and not justification:
        repo.create_log(
            db=db,
            target_entity_type=target_entity_type,
            target_entity_id=target_entity_id,
            action="apply",
            performed_by=performed_by,
            source_page=source_page,
            preview_data=applied_changes,
            result_status="hard_block_no_justification",
            justification=None,
        )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"تجاوز الفارق الحد المسموح ({threshold_pct}%). "
                "يجب تقديم مبرر كتابي لإتمام المزامنة."
            ),
        )

    # 6. No actual changes?
    if not applied_changes:
        log = repo.create_log(
            db=db,
            target_entity_type=target_entity_type,
            target_entity_id=target_entity_id,
            action="apply",
            performed_by=performed_by,
            source_page=source_page,
            result_status="no_changes",
            action_taken="no_op",
        )
        return RecalculationApplyResult(
            target_entity_type=target_entity_type,
            target_entity_id=target_entity_id,
            action_taken="no_op",
            revision_created=False,
            applied_changes=[],
            log_id=log.id,
            message_ar="✅ لا توجد تغييرات — التكاليف مطابقة للمصادر الحية.",
        )

    # 7. Apply based on entity status
    revision_created = False
    new_entity_id = None
    new_entity_code = None
    action_taken = "auto_updated"

    if target_entity_type == "import_budget" and current_status == "Budget Approved":
        # STRICT: create Revision, mark original Superseded
        new_entity = _create_revision_for_approved_budget(
            db, entity, applied_changes, performed_by, justification
        )
        db.commit()
        db.refresh(new_entity)
        revision_created = True
        new_entity_id = new_entity.budget_id
        new_entity_code = new_entity.budget_code
        action_taken = "revision_created"
        message_ar = f"✅ تم إنشاء مراجعة جديدة ({new_entity_code}) بالتكاليف المحدّثة. الميزانية الأصلية أصبحت 'Superseded'."
    else:
        # Draft / Pending / Needs Revalidation: update in-place
        action_taken = _apply_in_place_to_entity(
            db, entity, applied_changes, target_entity_type, performed_by, justification
        )
        db.commit()
        db.refresh(entity)
        if target_entity_type == "financial_settlement":
            message_ar = "✅ تمت إعادة احتساب التسوية وتكلفة الوصول بنجاح استناداً إلى التكاليف الحية."
        elif action_taken == "auto_updated":
            message_ar = "✅ تم تحديث الميزانية بالتكاليف الحية تلقائياً."
        else:
            message_ar = "✅ تم تحديث التكاليف. الميزانية في حالة 'Pending Review' للاعتماد."


    # 8. Unified audit log
    log = repo.create_log(
        db=db,
        target_entity_type=target_entity_type,
        target_entity_id=target_entity_id,
        action="apply",
        performed_by=performed_by,
        source_page=source_page,
        preview_data=applied_changes,
        changes_applied=applied_changes,
        justification=justification,
        result_status="success",
        action_taken=action_taken,
        new_entity_id=new_entity_id,
    )

    return RecalculationApplyResult(
        target_entity_type=target_entity_type,
        target_entity_id=target_entity_id,
        action_taken=action_taken,
        revision_created=revision_created,
        new_entity_id=new_entity_id,
        new_entity_code=new_entity_code,
        applied_changes=[],  # populated by preview items
        log_id=log.id,
        message_ar=message_ar,
    )


# ──────────────────────────────────────────────────────────────────────────────
# Convenience: recalculate() = preview() + apply() in one call
# ──────────────────────────────────────────────────────────────────────────────

def recalculate(
    db: Session,
    target_entity_type: str,
    target_entity_id: int,
    current_user: User,
    source_page: str,
    justification: Optional[str] = None,
) -> RecalculationApplyResult:
    """
    Convenience wrapper: runs preview (for audit) then apply immediately.
    Used for automated/system-triggered recalculations (e.g. Draft auto-update on upstream save).
    """
    preview(db, target_entity_type, target_entity_id, source_page, current_user.username)
    return apply(
        db=db,
        request=RecalculationApplyRequest(
            target_entity_type=target_entity_type,
            target_entity_id=target_entity_id,
            source_page=source_page,
            justification=justification,
        ),
        current_user=current_user,
    )


# ──────────────────────────────────────────────────────────────────────────────
# Helper: Variance threshold retrieval
# ──────────────────────────────────────────────────────────────────────────────

def _get_variance_threshold(db: Session, target_entity_type: str) -> float:
    """
    Returns the configured variance threshold for the entity type.
    Currently reads from budget_variance_settings for import_budget,
    defaults to 5.0% for all others.
    """
    if target_entity_type in ("import_budget", "financial_settlement"):
        from modules.financial_approval.model import BudgetVarianceSetting
        setting = db.query(BudgetVarianceSetting).filter(
            BudgetVarianceSetting.setting_key == "variance_threshold_percentage"
        ).first()

        if setting and setting.setting_value:
            try:
                return float(setting.setting_value)
            except ValueError:
                return 5.0
    return 5.0
