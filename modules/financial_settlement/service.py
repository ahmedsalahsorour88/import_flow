from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from fastapi import HTTPException

from .model import LandedCostSettlementRecord
from .schemas import (
    FinancialSettlementCreate,
    FinancialSettlementUpdate,
    ExpenseInvoiceSchema,
    ItemLandedCostSchema,
)
from .repository import (
    generate_settlement_code,
    get_settlement_by_id,
    get_settlement_by_import_file_id,
    list_settlements,
    create_settlement,
    update_settlement,
    soft_delete_settlement,
    restore_settlement,
)
from .validators import validate_expense_invoice, validate_items_allocation_readiness
from modules.import_files.model import ImportFile

def calculate_landed_cost_engine(
    expenses: List[Dict[str, Any]],
    items: List[Dict[str, Any]],
    incoterm: str = "FOB",
) -> Dict[str, Any]:
    """
    Core Landed Cost & Cost Allocation Calculation Engine (BP-038 & BP-039).
    Allocates freight, customs duties, brokerage, local transport, and storage expenses
    across items based on Value, Weight, Volume (CBM), or Equal distribution rules,
    tailored to the Incoterms 2020 rules:
    - FOB / FAS / FCA: Importer pays international freight, insurance, customs duties, and clearance.
    - CIF / CIP: Invoice already covers freight and insurance.
    - CFR / CPT: Invoice already covers freight. Importer pays insurance, customs duties, and clearance.
    - EXW: Importer pays origin trucking/clearance, freight, insurance, customs duties, and local transport.
    - DDP: Exporter covers transport/duties; only exceptional storage or unincluded local charges apply.
    """
    incoterm_normalized = (incoterm or "FOB").upper().strip()

    if not items or len(items) == 0:
        return {
            "incoterm_code": incoterm_normalized,
            "total_fob_egp": 0.0,
            "total_expenses_egp": sum(e.get("amount_egp", 0.0) for e in expenses),
            "total_landed_cost_egp": sum(e.get("amount_egp", 0.0) for e in expenses),
            "average_markup_factor": 1.0,
            "item_landed_costs": [],
        }

    # Reset allocation buckets on items
    for item in items:
        qty = item.get("qty", 1)
        fob_unit = item.get("fob_unit_egp", 0.0)
        item["fob_total_egp"] = qty * fob_unit
        item["allocated_freight_egp"] = 0.0
        item["allocated_customs_egp"] = 0.0
        item["allocated_clearance_egp"] = 0.0
        item["allocated_transport_egp"] = 0.0
        item["allocated_other_egp"] = 0.0

    total_fob_egp = sum(i["fob_total_egp"] for i in items)
    total_weight_kg = sum(i.get("gross_weight_kg", 0.0) for i in items)
    total_cbm = sum(i.get("cbm", 0.0) for i in items)
    num_items = len(items)

    total_expenses_egp = 0.0

    for exp in expenses:
        # If marked as seller-paid under CIF/CFR/DDP, do not double-add to importer's expense total
        if exp.get("is_seller_paid", False) or exp.get("payer", "").lower() == "seller":
            continue

        amount_egp = exp.get("amount_egp", 0.0)
        if amount_egp == 0.0:
            amount_egp = exp.get("amount_fx", 0.0) * exp.get("exchange_rate", 1.0)
            exp["amount_egp"] = amount_egp

        total_expenses_egp += amount_egp
        category = exp.get("category", "Other")
        rule = exp.get("allocation_rule", "Value-Based")

        for item in items:
            ratio = 1.0 / num_items
            if rule == "Value-Based" and total_fob_egp > 0:
                ratio = item["fob_total_egp"] / total_fob_egp
            elif rule == "Weight-Based" and total_weight_kg > 0:
                ratio = item.get("gross_weight_kg", 0.0) / total_weight_kg
            elif rule == "Volume-Based" and total_cbm > 0:
                ratio = item.get("cbm", 0.0) / total_cbm
            elif rule == "Equal":
                ratio = 1.0 / num_items

            allocated_share = amount_egp * ratio

            if category in ("Freight", "Shipping", "Ocean Freight", "Air Freight"):
                item["allocated_freight_egp"] += allocated_share
            elif category in ("Customs Duty", "Customs", "Taxes", "VAT", "Import Duty"):
                item["allocated_customs_egp"] += allocated_share
            elif category in ("Brokerage", "Clearance", "Brokerage Fees", "Customs Clearance"):
                item["allocated_clearance_egp"] += allocated_share
            elif category in ("Local Transport", "Transport", "Trucking", "Inland Transport"):
                item["allocated_transport_egp"] += allocated_share
            else:
                item["allocated_other_egp"] += allocated_share

    # Compute final landed cost per item
    for item in items:
        qty = max(item.get("qty", 1), 1)
        tot_alloc = (
            item["allocated_freight_egp"] +
            item["allocated_customs_egp"] +
            item["allocated_clearance_egp"] +
            item["allocated_transport_egp"] +
            item["allocated_other_egp"]
        )
        item["total_landed_cost_egp"] = item["fob_total_egp"] + tot_alloc
        item["unit_landed_cost_egp"] = item["total_landed_cost_egp"] / qty
        item["markup_factor"] = (
            item["unit_landed_cost_egp"] / item["fob_unit_egp"]
            if item["fob_unit_egp"] > 0
            else 1.0
        )

    total_landed_cost_egp = total_fob_egp + total_expenses_egp
    average_markup_factor = (
        total_landed_cost_egp / total_fob_egp if total_fob_egp > 0 else 1.0
    )

    return {
        "incoterm_code": incoterm_normalized,
        "total_fob_egp": round(total_fob_egp, 2),
        "total_expenses_egp": round(total_expenses_egp, 2),
        "total_landed_cost_egp": round(total_landed_cost_egp, 2),
        "average_markup_factor": round(average_markup_factor, 4),
        "item_landed_costs": items,
    }

def create_settlement_service(db: Session, schema: FinancialSettlementCreate) -> LandedCostSettlementRecord:
    imp_file = db.query(ImportFile).filter(ImportFile.import_file_id == schema.import_file_id, ImportFile.is_active == True).first()
    if not imp_file:
        raise HTTPException(status_code=404, detail="ملف الشحنة الاستيرادية المرتكز عليه غير موجود أو محذوف.")

    incoterm = (schema.incoterm_code or imp_file.incoterm_code or "FOB").upper()

    # ── Auto-fetch: Customs Duty totals → expense_invoices pre-fill ──────────
    expenses_in = [e if isinstance(e, dict) else e.model_dump() for e in (schema.expense_invoices or [])]
    has_duty_expense = any(
        (e.get("category", "") or "").lower() in ("customs duty", "customs", "import duty", "taxes")
        for e in expenses_in
    )
    if not has_duty_expense:
        try:
            from modules.customs_clearance.model import CustomsClearanceRecord
            clearance = db.query(CustomsClearanceRecord).filter(
                CustomsClearanceRecord.import_file_id == schema.import_file_id,
                CustomsClearanceRecord.is_active == True,
                CustomsClearanceRecord.status == "Final Release Granted",
            ).order_by(CustomsClearanceRecord.customs_clearance_id.desc()).first()
            if clearance and (clearance.actual_duty_total or 0) > 0:
                total_duty = float(clearance.actual_duty_total or clearance.total_duty_payable or 0)
                if total_duty > 0:
                    expenses_in.append({
                        "category": "Customs Duty",
                        "description": f"ضرائب ورسوم جمركية — إقرار {clearance.declaration_46_no or clearance.clearance_code}",
                        "amount_egp": total_duty,
                        "amount_fx": 0.0,
                        "exchange_rate": 1.0,
                        "currency": "EGP",
                        "allocation_rule": "Value-Based",
                        "is_seller_paid": False,
                        "payer": "Importer",
                        "note": "تم جلبه تلقائياً من سجل التخليص الجمركي",
                    })
            if clearance and (clearance.lab_service_fees or 0) > 0:
                expenses_in.append({
                    "category": "Clearance",
                    "description": f"رسوم خدمات جمركية — {clearance.clearance_code}",
                    "amount_egp": float(clearance.lab_service_fees),
                    "amount_fx": 0.0,
                    "exchange_rate": 1.0,
                    "currency": "EGP",
                    "allocation_rule": "Value-Based",
                    "is_seller_paid": False,
                    "payer": "Importer",
                    "note": "رسوم الخدمات الجمركية — مجلوبة تلقائياً",
                })
        except Exception as e:
            import logging
            logging.getLogger(__name__).warning("Auto-fetch customs duty for settlement failed: %s", e)
    schema.expense_invoices = expenses_in

    # ── Auto-populate: item_landed_costs from PO Line Items ────────────────
    items_in = [i if isinstance(i, dict) else i.model_dump() for i in (schema.item_landed_costs or [])]
    if not items_in:
        try:
            from modules.purchase_orders.model import PurchaseOrder, POLineItem
            po_ids_raw = imp_file.po_ids or []
            if isinstance(po_ids_raw, str):
                import json as _json
                po_ids_raw = _json.loads(po_ids_raw) if po_ids_raw else []
            if po_ids_raw:
                po_line_items = db.query(POLineItem).filter(
                    POLineItem.po_id.in_(po_ids_raw),
                    POLineItem.is_active == True,
                ).all()
                for li in po_line_items:
                    items_in.append({
                        "item_code": li.item_code or f"ITEM-{li.line_item_id}",
                        "description": li.item_description or li.item_code or "",
                        "qty": float(li.quantity or 1),
                        "fob_unit_egp": float(li.unit_price_egp or 0),
                        "gross_weight_kg": float(li.gross_weight_kg or 0),
                        "cbm": float(li.total_cbm or 0),
                        "hs_code": li.hs_code or "",
                        "note": "مجلوب تلقائياً من بنود أمر الشراء",
                    })
        except Exception as e:
            import logging
            logging.getLogger(__name__).warning("Auto-populate settlement items from PO failed: %s", e)
    schema.item_landed_costs = items_in

    code = generate_settlement_code(db)
    record = create_settlement(db, schema, code)
    record.incoterm_code = incoterm

    # Perform Landed Cost Engine calculation based on Incoterm
    calc_res = calculate_landed_cost_engine(record.expense_invoices, record.item_landed_costs, incoterm=incoterm)
    record.total_fob_egp = calc_res["total_fob_egp"]
    record.total_expenses_egp = calc_res["total_expenses_egp"]
    record.total_landed_cost_egp = calc_res["total_landed_cost_egp"]
    record.average_markup_factor = calc_res["average_markup_factor"]
    record.item_landed_costs = calc_res["item_landed_costs"]
    record.status = "Calculated"

    # Update Import File progress
    imp_file.current_module = "Phase 9 - Financial Settlement & Landed Cost Engine"
    imp_file.current_stage = f"Landed Cost Calculated ({incoterm} - Code: {code})"
    if (imp_file.progress_percent or 0.0) < 95.0:
        imp_file.progress_percent = 95.0
    imp_file.next_action = "Review Final Settlement & Perform File Closure (Phase 10)"
    db.commit()

    # Lifecycle advance: STEP_19 → STEP_20 (GRN complete → Landed Cost Settlement)
    try:
        from modules.lifecycle_board.service import advance_lifecycle_step_service
        advance_lifecycle_step_service(
            db=db,
            import_file_id=schema.import_file_id,
            completed_step_code="STEP_19",
            target_step_codes=["STEP_20"],
            notes=f"تم إنشاء سجل التسوية المالية وحساب تكلفة الوصول الشاملة ({code}).",
            assigned_user="Finance Manager",
        )
    except Exception as e:
        import logging
        logging.getLogger(__name__).warning("Lifecycle advance STEP_19→STEP_20 failed: %s", e)

    return record



def recalculate_settlement_service(db: Session, settlement_id: int) -> LandedCostSettlementRecord:
    record = get_settlement_by_id(db, settlement_id)
    if not record:
        raise HTTPException(status_code=404, detail="سجل التسوية المالية غير موجود.")

    incoterm = record.incoterm_code or (record.import_file.incoterm_code if record.import_file else "FOB")
    calc_res = calculate_landed_cost_engine(record.expense_invoices, record.item_landed_costs, incoterm=incoterm)
    record.total_fob_egp = calc_res["total_fob_egp"]
    record.total_expenses_egp = calc_res["total_expenses_egp"]
    record.total_landed_cost_egp = calc_res["total_landed_cost_egp"]
    record.average_markup_factor = calc_res["average_markup_factor"]
    record.item_landed_costs = calc_res["item_landed_costs"]
    record.status = "Calculated"
    record.updated_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(record)
    return record

def update_settlement_service(db: Session, settlement_id: int, schema: FinancialSettlementUpdate) -> LandedCostSettlementRecord:
    get_settlement_by_id(db, settlement_id)
    updated = update_settlement(db, settlement_id, schema)
    return recalculate_settlement_service(db, settlement_id)

def get_settlement_service(db: Session, settlement_id: int) -> LandedCostSettlementRecord:
    record = get_settlement_by_id(db, settlement_id)
    if not record:
        raise HTTPException(status_code=404, detail="سجل التسوية المالية غير موجود.")
    return record

def list_settlements_service(
    db: Session,
    include_inactive: bool = False,
    import_file_id: Optional[int] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
) -> List[LandedCostSettlementRecord]:
    return list_settlements(db, include_inactive, import_file_id, status, search)

def soft_delete_settlement_service(db: Session, settlement_id: int) -> bool:
    get_settlement_service(db, settlement_id)
    return soft_delete_settlement(db, settlement_id)

def restore_settlement_service(db: Session, settlement_id: int) -> LandedCostSettlementRecord:
    record = restore_settlement(db, settlement_id)
    if not record:
        raise HTTPException(status_code=404, detail=f"سجل التسوية التكليفية رقم {settlement_id} غير موجود.")
    return record


# ==============================================================================
# PL-08: Estimated Landed Cost Simulation Service
# ==============================================================================
from datetime import date
from decimal import Decimal
from .schemas import (
    EstimatedLandedCostSimulationRequest,
    EstimatedLandedCostSimulationResponse,
    EstimatedLandedCostItemBreakdown,
    EstimatedLandedCostExpenseItem,
)

def simulate_estimated_landed_cost_service(
    db: Session,
    import_file_id: int,
    request: Optional[EstimatedLandedCostSimulationRequest] = None,
) -> EstimatedLandedCostSimulationResponse:
    """
    محاكاة واحتساب تكلفة الوصول التقديرية للشحنة وللوحدة الواحدة (PL-08: Estimated Landed Cost Simulation).
    تجمع بين:
    1. قيمة البضاعة التقديرية (FOB).
    2. النولون التقديري (من العرض الفائز في RFQ أو النولون الحكمي 2%).
    3. التأمين البحري التقديري (من الوثيقة أو التأمين الحكمي 2.5%).
    4. الرسوم الجمركية والضرائب ورسوم الخدمات (من محرك التعريفة الجمركية المصري MD-008).
    5. مصاريف الميناء والعتالة والتخليص الجمركي والنقل الداخلي والمصاريف البنكية.
    6. توزيع المصاريف على الأصناف واحتساب تكلفة الوصول للوحدة ومعامل الزيادة Markup %.
    """
    from modules.purchase_orders.model import PurchaseOrder
    from modules.customs_tariff.service import estimate_multi_item_customs_duty_service
    from modules.customs_tariff.schemas import (
        MultiItemCustomsEstimateRequest,
        MultiItemCustomsEstimateLine,
    )
    from modules.freight_quotations.model import FreightRFQRequest, FreightQuotationItem
    from modules.currencies.service import CurrencyService

    req = request or EstimatedLandedCostSimulationRequest()
    calc_date = req.estimate_date or date.today()

    imp_file = db.query(ImportFile).filter(ImportFile.import_file_id == import_file_id).first()
    if not imp_file:
        raise HTTPException(
            status_code=404,
            detail=f"ملف الشحنة الاستيرادية رقم {import_file_id} غير موجود.",
        )

    # 1. Fetch Purchase Orders and Items
    pos = (
        db.query(PurchaseOrder)
        .filter(PurchaseOrder.import_file_id == import_file_id, PurchaseOrder.is_active == True)
        .all()
    )

    currency = "USD"
    items_raw = []
    line_no = 1

    for po in pos:
        if po.currency and getattr(po.currency, "currency_code", None):
            currency = po.currency.currency_code
        for itm in (po.line_items or []):
            hs = (itm.tariff.hs_code if getattr(itm, "tariff", None) else getattr(itm, "hs_code", "")) or ""
            hs = hs.strip() if hs else (imp_file.hs_code or "8479.89.90").strip()
            qty = float(itm.quantity or 1.0)
            u_price = float(itm.unit_price or 0.0)
            tot_price = float(itm.total_price or (qty * u_price))
            if tot_price <= 0:
                tot_price = 1000.0
                u_price = tot_price / max(qty, 1.0)

            w_kg = float(getattr(itm, "gross_weight_kg", 0.0) or 0.0)
            cbm_val = float(getattr(itm, "cbm", 0.0) or 0.0)
            origin = (getattr(itm, "country_of_origin", "") or getattr(po, "country_of_origin", "") or "").strip()
            if origin and " - " in origin:
                origin = origin.split(" - ")[0].strip()
            if origin and len(origin) > 2:
                origin = origin[:2]

            items_raw.append({
                "line_no": line_no,
                "item_code": getattr(itm, "item_code", "") or f"ITM-{line_no:03d}",
                "item_name": getattr(itm, "commercial_name", "") or getattr(itm, "item_name", "") or f"Item #{line_no}",
                "hs_code": hs,
                "qty": qty,
                "unit_price_fc": u_price,
                "fob_total_fc": tot_price,
                "weight_kg": w_kg,
                "cbm": cbm_val,
                "origin_country": origin.upper() if origin else None,
            })
            line_no += 1

    # Fallback to invoices or estimated_cost if no items
    if not items_raw and imp_file.invoices_data:
        for inv in imp_file.invoices_data:
            inv_amt = float(inv.get("amount") or 0.0)
            if inv_amt > 0:
                inv_curr = inv.get("currency") or "USD"
                currency = inv_curr
                items_raw.append({
                    "line_no": line_no,
                    "item_code": f"INV-{line_no:03d}",
                    "item_name": inv.get("description") or f"Invoice Item #{line_no}",
                    "hs_code": (imp_file.hs_code or "8479.89.90").strip(),
                    "qty": 1.0,
                    "unit_price_fc": inv_amt,
                    "fob_total_fc": inv_amt,
                    "weight_kg": 0.0,
                    "cbm": 0.0,
                    "origin_country": None,
                })
                line_no += 1

    if not items_raw:
        cost = float(imp_file.estimated_cost or 10000.0)
        currency = imp_file.estimated_cost_currency or "USD"
        items_raw.append({
            "line_no": 1,
            "item_code": "ITM-001",
            "item_name": getattr(imp_file, "product_category", "") or "General Imported Cargo",
            "hs_code": (imp_file.hs_code or "8479.89.90").strip(),
            "qty": 1.0,
            "unit_price_fc": cost,
            "fob_total_fc": cost,
            "weight_kg": 0.0,
            "cbm": 0.0,
            "origin_country": None,
        })

    # 2. Resolve Exchange Rate
    if req.exchange_rate_override and req.exchange_rate_override > 0:
        fx_rate = float(req.exchange_rate_override)
    else:
        try:
            c_svc = CurrencyService(db)
            r_val, _, _ = c_svc._get_rate_to_egp(currency, rate_type="customs", as_of_date=calc_date)
            fx_rate = float(r_val)
        except Exception:
            fx_rate = 48.5

    total_fob_fc = sum(i["fob_total_fc"] for i in items_raw)
    total_fob_egp = total_fob_fc * fx_rate

    # 3. Resolve Freight (RFQ or Deemed 2%)
    expenses_breakdown: List[EstimatedLandedCostExpenseItem] = []
    has_freight_doc = False
    if req.freight_amount_egp_override is not None and req.freight_amount_egp_override >= 0:
        freight_egp = float(req.freight_amount_egp_override)
        freight_src = "تعديل يدوي (User Override)"
        has_freight_doc = True
    else:
        awarded_rfq = (
            db.query(FreightRFQRequest)
            .filter(FreightRFQRequest.import_file_id == import_file_id)
            .order_by(FreightRFQRequest.rfq_id.desc())
            .first()
        )
        if awarded_rfq and awarded_rfq.selected_quotation_id:
            winning_q = db.query(FreightQuotationItem).filter(
                FreightQuotationItem.quotation_id == awarded_rfq.selected_quotation_id
            ).first()
            if winning_q and winning_q.total_cost:
                q_cost = float(winning_q.total_cost)
                q_curr = winning_q.currency_code or currency
                freight_egp = q_cost if q_curr.upper() == "EGP" else (q_cost * fx_rate)
                p_name = getattr(winning_q, "provider_name", None) or getattr(winning_q, "carrier_name", "RFQ Winner")
                freight_src = f"العرض الفائز في مناقصة النولون ({p_name})"
                has_freight_doc = True
            else:
                freight_egp = total_fob_egp * 0.02
                freight_src = "نولون حكمي جمركي (2.0% من قيمة FOB)"
        else:
            freight_egp = total_fob_egp * 0.02
            freight_src = "نولون حكمي جمركي (2.0% من قيمة FOB)"

    expenses_breakdown.append(EstimatedLandedCostExpenseItem(
        category="Ocean/Air Freight",
        description="النولون والشحن الدولي التقديري",
        amount_fc=round(freight_egp / fx_rate, 2),
        currency=currency,
        amount_egp=round(freight_egp, 2),
        is_estimated=True,
        source=freight_src,
        allocation_rule="Volume-Based" if any(i["cbm"] > 0 for i in items_raw) else "Weight-Based" if any(i["weight_kg"] > 0 for i in items_raw) else "Value-Based",
    ))

    # 4. Resolve Marine Insurance (2.5% deemed or override)
    has_ins_doc = False
    if req.insurance_amount_egp_override is not None and req.insurance_amount_egp_override >= 0:
        insurance_egp = float(req.insurance_amount_egp_override)
        ins_src = "تعديل يدوي (User Override)"
        has_ins_doc = True
    else:
        insurance_egp = total_fob_egp * 0.025
        ins_src = "تأمين بحري حكمي جمركي (2.5% من قيمة FOB)"

    expenses_breakdown.append(EstimatedLandedCostExpenseItem(
        category="Marine Insurance",
        description="التأمين البحري / الجوي التقديري",
        amount_fc=round(insurance_egp / fx_rate, 2),
        currency=currency,
        amount_egp=round(insurance_egp, 2),
        is_estimated=True,
        source=ins_src,
        allocation_rule="Value-Based",
    ))

    # 5. Call Egyptian Customs Engine (PL-07) for accurate per-item customs & VAT
    customs_lines = [
        MultiItemCustomsEstimateLine(
            line_no=itm["line_no"],
            hs_code=itm["hs_code"],
            value_fc=Decimal(str(round(itm["fob_total_fc"], 2))),
            weight_kg=Decimal(str(round(itm["weight_kg"], 2))),
            qty=Decimal(str(round(itm["qty"], 2))),
            origin_country=itm["origin_country"],
        )
        for itm in items_raw
    ]

    calc_req = MultiItemCustomsEstimateRequest(
        currency=currency,
        exchange_rate=Decimal(str(round(fx_rate, 4))),
        insurance_egp=Decimal(str(round(insurance_egp, 2))),
        freight_egp=Decimal(str(round(freight_egp, 2))),
        packaging_egp=Decimal("0.00"),
        has_insurance_document=has_ins_doc,
        has_freight_document=has_freight_doc,
        estimate_date=calc_date,
        lines=customs_lines,
    )

    customs_breakdown = estimate_multi_item_customs_duty_service(db, calc_req)

    total_customs_duty_egp = float(customs_breakdown.total_duty_egp)
    total_vat_egp = float(customs_breakdown.total_vat_egp)
    total_schedule_tax_egp = float(customs_breakdown.total_schedule_tax_egp)
    total_service_fee_egp = float(customs_breakdown.total_customs_service_fee_egp)
    total_taxes_and_fees_egp = float(getattr(customs_breakdown, "items_taxes_total_egp", None) or getattr(customs_breakdown, "grand_total_payable_egp", 0.0) or (total_customs_duty_egp + total_vat_egp + total_schedule_tax_egp + total_service_fee_egp))

    expenses_breakdown.append(EstimatedLandedCostExpenseItem(
        category="Customs Duties",
        description="ضريبة الوارد الجمركية (Import Duty)",
        amount_fc=round(total_customs_duty_egp / fx_rate, 2),
        currency="EGP",
        amount_egp=round(total_customs_duty_egp, 2),
        is_estimated=True,
        source="محرك التعريفة الجمركية المصري MD-008",
        allocation_rule="Direct HS Code Allocation",
    ))

    expenses_breakdown.append(EstimatedLandedCostExpenseItem(
        category="VAT & Taxes",
        description="ضريبة القيمة المضافة وضريبة الجدول ورسوم الخدمات الجمركية 1%",
        amount_fc=round((total_vat_egp + total_schedule_tax_egp + total_service_fee_egp) / fx_rate, 2),
        currency="EGP",
        amount_egp=round(total_vat_egp + total_schedule_tax_egp + total_service_fee_egp, 2),
        is_estimated=True,
        source="مصلحة الضرائب المصرية وقانون القيمة المضافة",
        allocation_rule="Direct HS Code Allocation",
    ))

    # 6. Additional Logistics & Clearance Expenses
    clearance_fee = float(req.clearance_fees_egp_override) if req.clearance_fees_egp_override is not None else 4500.0
    port_handling = float(req.port_handling_egp_override) if req.port_handling_egp_override is not None else 5000.0
    inland_trucking = float(req.inland_transport_egp_override) if req.inland_transport_egp_override is not None else 7500.0
    bank_fees = float(req.bank_fees_egp_override) if req.bank_fees_egp_override is not None else 2500.0
    other_fees = float(req.other_expenses_egp_override) if req.other_expenses_egp_override is not None else 2000.0

    expenses_breakdown.append(EstimatedLandedCostExpenseItem(
        category="Customs Clearance & Brokerage",
        description="أتعاب التخليص الجمركي وإصدار إذن التسليم والتراخيص",
        amount_fc=round(clearance_fee / fx_rate, 2),
        currency="EGP",
        amount_egp=round(clearance_fee, 2),
        is_estimated=True,
        source="تقدير قياسي / مخلص معتمد" if req.clearance_fees_egp_override is None else "تعديل يدوي",
        allocation_rule="Weight-Based" if any(i["weight_kg"] > 0 for i in items_raw) else "Value-Based",
    ))

    expenses_breakdown.append(EstimatedLandedCostExpenseItem(
        category="Port & Terminal Handling (THC)",
        description="مصاريف الميناء والتفريغ والعتالة والتخزين المؤقت",
        amount_fc=round(port_handling / fx_rate, 2),
        currency="EGP",
        amount_egp=round(port_handling, 2),
        is_estimated=True,
        source="تعريفة محطة الحاويات والميناء" if req.port_handling_egp_override is None else "تعديل يدوي",
        allocation_rule="Volume-Based" if any(i["cbm"] > 0 for i in items_raw) else "Weight-Based" if any(i["weight_kg"] > 0 for i in items_raw) else "Value-Based",
    ))

    expenses_breakdown.append(EstimatedLandedCostExpenseItem(
        category="Inland Transport",
        description="النقل الداخلي بالشاحنات من ميناء الوصول لمخازن الشركة",
        amount_fc=round(inland_trucking / fx_rate, 2),
        currency="EGP",
        amount_egp=round(inland_trucking, 2),
        is_estimated=True,
        source="أسعار النقل البري المعتمدة" if req.inland_transport_egp_override is None else "تعديل يدوي",
        allocation_rule="Weight-Based" if any(i["weight_kg"] > 0 for i in items_raw) else "Volume-Based" if any(i["cbm"] > 0 for i in items_raw) else "Value-Based",
    ))

    expenses_breakdown.append(EstimatedLandedCostExpenseItem(
        category="Banking & Form 4 Fees",
        description="عمولات التحويلات البنكية ومصاريف استخراج نموذج 4 وفتح الاعتماد",
        amount_fc=round(bank_fees / fx_rate, 2),
        currency="EGP",
        amount_egp=round(bank_fees, 2),
        is_estimated=True,
        source="جدول العمولات البنكية الرسمي" if req.bank_fees_egp_override is None else "تعديل يدوي",
        allocation_rule="Value-Based",
    ))

    expenses_breakdown.append(EstimatedLandedCostExpenseItem(
        category="Inspection & Administrative",
        description="فحص الرقابة على الصادرات والواردات، رسوم كارجو إكس، ومصاريف إدارية",
        amount_fc=round(other_fees / fx_rate, 2),
        currency="EGP",
        amount_egp=round(other_fees, 2),
        is_estimated=True,
        source="مصاريف إدارية تقديرية" if req.other_expenses_egp_override is None else "تعديل يدوي",
        allocation_rule="Value-Based",
    ))

    # 7. Allocation per item
    pref = req.allocation_preference or "Value-Based"
    total_weight = sum(i["weight_kg"] for i in items_raw)
    total_cbm = sum(i["cbm"] for i in items_raw)

    items_breakdown: List[EstimatedLandedCostItemBreakdown] = []

    # Map line-level customs results
    customs_line_map = {l.line_no: l for l in customs_breakdown.lines}

    for itm in items_raw:
        l_no = itm["line_no"]
        c_line = customs_line_map.get(l_no)

        fob_item_egp = itm["fob_total_fc"] * fx_rate
        qty = max(itm["qty"], 1.0)
        fob_unit_egp = fob_item_egp / qty

        # Ratios
        val_ratio = (fob_item_egp / total_fob_egp) if total_fob_egp > 0 else (1.0 / len(items_raw))
        wt_ratio = (itm["weight_kg"] / total_weight) if total_weight > 0 else val_ratio
        cbm_ratio = (itm["cbm"] / total_cbm) if total_cbm > 0 else wt_ratio

        # Select allocation ratio based on preference
        if pref == "Weight-Based" and total_weight > 0:
            primary_ratio = wt_ratio
        elif pref == "Volume-Based" and total_cbm > 0:
            primary_ratio = cbm_ratio
        else:
            primary_ratio = val_ratio

        # Allocation shares
        alloc_freight = freight_egp * (cbm_ratio if total_cbm > 0 else (wt_ratio if total_weight > 0 else val_ratio))
        alloc_ins = insurance_egp * val_ratio

        alloc_duty = float(c_line.duty_egp) if c_line else (total_customs_duty_egp * val_ratio)
        alloc_vat = (
            float(
                c_line.vat_egp
                + c_line.schedule_tax_egp
                + c_line.customs_service_fee_egp
                + getattr(c_line, "development_fee_egp", 0.0)
                + getattr(c_line, "import_fee_egp", 0.0)
            )
            if c_line
            else ((total_vat_egp + total_schedule_tax_egp + total_service_fee_egp) * val_ratio)
        )

        alloc_clearance_port = (clearance_fee + port_handling) * primary_ratio
        alloc_inland = inland_trucking * (wt_ratio if total_weight > 0 else primary_ratio)
        alloc_other = (bank_fees + other_fees) * val_ratio

        tot_alloc_expenses = (
            alloc_freight + alloc_ins + alloc_duty + alloc_vat +
            alloc_clearance_port + alloc_inland + alloc_other
        )

        item_total_landed = fob_item_egp + tot_alloc_expenses
        item_unit_landed_egp = item_total_landed / qty
        item_unit_landed_fc = item_unit_landed_egp / fx_rate
        item_markup_factor = (item_unit_landed_egp / fob_unit_egp) if fob_unit_egp > 0 else 1.0
        item_markup_pct = (item_markup_factor - 1.0) * 100.0

        items_breakdown.append(EstimatedLandedCostItemBreakdown(
            line_no=l_no,
            item_code=itm["item_code"],
            item_name=itm["item_name"],
            hs_code=itm["hs_code"],
            qty=qty,
            unit_price_fc=round(itm["unit_price_fc"], 2),
            fob_total_fc=round(itm["fob_total_fc"], 2),
            fob_unit_egp=round(fob_unit_egp, 2),
            fob_total_egp=round(fob_item_egp, 2),
            allocated_freight_egp=round(alloc_freight, 2),
            allocated_insurance_egp=round(alloc_ins, 2),
            allocated_customs_duty_egp=round(alloc_duty, 2),
            allocated_vat_egp=round(alloc_vat, 2),
            allocated_clearance_and_port_egp=round(alloc_clearance_port, 2),
            allocated_inland_transport_egp=round(alloc_inland, 2),
            allocated_other_egp=round(alloc_other, 2),
            total_expenses_allocated_egp=round(tot_alloc_expenses, 2),
            total_landed_cost_egp=round(item_total_landed, 2),
            unit_landed_cost_egp=round(item_unit_landed_egp, 2),
            unit_landed_cost_fc=round(item_unit_landed_fc, 2),
            markup_factor=round(item_markup_factor, 4),
            markup_percent=round(item_markup_pct, 2),
        ))

    # 8. Grand Totals
    total_clearance_and_port = clearance_fee + port_handling
    total_other = bank_fees + other_fees
    total_expenses = (
        freight_egp + insurance_egp + total_taxes_and_fees_egp +
        total_clearance_and_port + inland_trucking + total_other
    )
    total_landed_cost_egp = total_fob_egp + total_expenses
    total_landed_cost_fc = total_landed_cost_egp / fx_rate
    avg_markup_factor = (total_landed_cost_egp / total_fob_egp) if total_fob_egp > 0 else 1.0
    avg_markup_pct = (avg_markup_factor - 1.0) * 100.0

    # Executive Summary in Arabic
    customs_pct = round((total_taxes_and_fees_egp / total_expenses * 100.0), 1) if total_expenses > 0 else 0.0
    freight_pct = round(((freight_egp + insurance_egp) / total_expenses * 100.0), 1) if total_expenses > 0 else 0.0

    summary_ar = (
        f"تبلغ تكلفة الوصول التقديرية الإجمالية للشحنة {total_landed_cost_egp:,.2f} جنيه مصري "
        f"({total_landed_cost_fc:,.2f} {currency}) مقارنة بقيمة البضاعة FOB البالغة {total_fob_egp:,.2f} جنيه، "
        f"بمتوسط معامل زيادة {avg_markup_factor:.3f} (أي بنسبة زيادة إجمالية قدرها {avg_markup_pct:.1f}%). "
        f"تشكل الضرائب والرسوم الجمركية النسبة الأكبر من المصاريف المضافة ({customs_pct}%)، "
        f"بينما يمثل النولون والتأمين البحري ({freight_pct}%)، والباقي موزع بين مصاريف الموانئ والتخليص والنقل الداخلي."
    )

    return EstimatedLandedCostSimulationResponse(
        import_file_id=import_file_id,
        import_file_code=imp_file.import_file_code or f"IMP-{import_file_id}",
        currency=currency,
        exchange_rate=round(fx_rate, 4),
        incoterm=imp_file.incoterm_code or "FOB",
        total_fob_fc=round(total_fob_fc, 2),
        total_fob_egp=round(total_fob_egp, 2),
        total_freight_egp=round(freight_egp, 2),
        total_insurance_egp=round(insurance_egp, 2),
        total_customs_and_taxes_egp=round(total_taxes_and_fees_egp, 2),
        total_clearance_and_port_egp=round(total_clearance_and_port, 2),
        total_inland_transport_egp=round(inland_trucking, 2),
        total_other_expenses_egp=round(total_other, 2),
        total_expenses_egp=round(total_expenses, 2),
        total_landed_cost_egp=round(total_landed_cost_egp, 2),
        total_landed_cost_fc=round(total_landed_cost_fc, 2),
        average_markup_factor=round(avg_markup_factor, 4),
        average_markup_percent=round(avg_markup_pct, 2),
        expenses_breakdown=expenses_breakdown,
        items_breakdown=items_breakdown,
        executive_summary_ar=summary_ar,
    )
