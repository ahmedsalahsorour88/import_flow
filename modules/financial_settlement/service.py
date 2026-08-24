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

    # Update Import File progress to 95%
    imp_file.current_module = "Phase 9 - Financial Settlement & Landed Cost Engine"
    imp_file.current_stage = f"Landed Cost Calculated ({incoterm} - Code: {code})"
    imp_file.progress_percent = 95.0
    imp_file.next_action = "Review Final Settlement & Perform File Closure (Phase 10)"
    db.commit()

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
