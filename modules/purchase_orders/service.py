import json
from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from modules.purchase_orders.model import PurchaseOrder
from modules.purchase_orders.repository import PurchaseOrderRepository
from modules.purchase_orders.schemas import (
    POLineItemResponse,
    PackingListItemResponse,
    PackingListSummaryByHSCode,
    PackingListValidationReport,
    PalletPlanItem,
    PurchaseOrderCreate,
    PurchaseOrderResponse,
    PurchaseOrderUpdate,
)
from modules.purchase_orders.validators import PurchaseOrderValidator


class PurchaseOrderService:

    def __init__(self, db: Session):
        self.db = db
        self.repo = PurchaseOrderRepository(db)
        self.validator = PurchaseOrderValidator(db)

    def get_packing_list_report(self, po_id: int) -> PackingListValidationReport:
        po = self.repo.get_by_id(po_id)
        if not po:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Purchase Order with ID {po_id} not found.",
            )

        errors = []
        warnings = []
        hs_map = {}

        tot_pcs = 0.0
        tot_pkg = 0.0
        tot_net = 0.0
        tot_gross = 0.0
        tot_cbm = 0.0
        tot_chg = 0.0

        if not po.packing_list_items:
            warnings.append("No packing list items recorded for this purchase order.")

        for idx, item in enumerate(po.packing_list_items, start=1):
            q_pcs = float(item.qty_pcs or 0.0)
            q_pkg = float(item.qty_pkg or 0.0)
            net_u = float(item.net_weight_unit_kg or 0.0)
            gross_u = float(item.gross_weight_unit_kg or 0.0)
            l_cm = float(item.length_cm or 0.0)
            w_cm = float(item.width_cm or 0.0)
            h_cm = float(item.height_cm or 0.0)

            t_net = float(item.total_net_weight_kg or 0.0)
            if t_net <= 0 and net_u > 0 and q_pkg > 0:
                t_net = round(q_pkg * net_u, 2)
            t_gross = float(item.total_gross_weight_kg or 0.0)
            if t_gross <= 0 and gross_u > 0 and q_pkg > 0:
                t_gross = round(q_pkg * gross_u, 2)
            t_cbm = float(item.total_cbm or 0.0)
            chg_wt = float(item.chargeable_weight_kg or 0.0)

            # Validation Rule: Gross Weight >= Net Weight
            if gross_u < net_u:
                errors.append(f"Item #{idx} ({item.item_code}): Gross weight per unit ({gross_u} kg) cannot be less than Net weight ({net_u} kg).")

            # Validation Rule: No negative weights
            if net_u < 0 or gross_u < 0:
                errors.append(f"Item #{idx} ({item.item_code}): Unit weights cannot be negative.")

            # Validation Rule: Dimensions zero warning
            if l_cm <= 0 or w_cm <= 0 or h_cm <= 0:
                warnings.append(f"Item #{idx} ({item.item_code}): Package dimensions missing or zero; CBM cannot be computed accurately.")

            tot_pcs += q_pcs
            tot_pkg += q_pkg
            tot_net += t_net
            tot_gross += t_gross
            tot_cbm += t_cbm
            tot_chg += chg_wt

            hs = item.hs_code or "UNSPECIFIED"
            if hs not in hs_map:
                hs_map[hs] = {
                    "hs_code": hs,
                    "qty_pcs": 0.0,
                    "qty_pkg": 0.0,
                    "total_net_weight_kg": 0.0,
                    "total_gross_weight_kg": 0.0,
                    "total_cbm": 0.0,
                }
            hs_map[hs]["qty_pcs"] += q_pcs
            hs_map[hs]["qty_pkg"] += q_pkg
            hs_map[hs]["total_net_weight_kg"] += t_net
            hs_map[hs]["total_gross_weight_kg"] += t_gross
            hs_map[hs]["total_cbm"] += t_cbm

        # Invoice HS Code Map
        invoice_hs_map = {}
        po_total_pcs = 0.0
        for l_item in po.line_items:
            l_qty = float(l_item.quantity or 0.0)
            po_total_pcs += l_qty
            l_hs = l_item.tariff.hs_code if (l_item.tariff and l_item.tariff.hs_code) else "UNASSIGNED"
            invoice_hs_map[l_hs] = invoice_hs_map.get(l_hs, 0.0) + l_qty

        # Detect Missing HS Codes
        missing_hs_in_packing = []
        if po.line_items and po.packing_list_items:
            for inv_hs in invoice_hs_map.keys():
                if inv_hs not in hs_map:
                    missing_hs_in_packing.append(inv_hs)
                    warnings.append(f"HS Code '{inv_hs}' exists in Commercial Invoice but is missing from Packing List.")

        missing_hs_in_invoice = []
        if po.line_items and po.packing_list_items:
            for pkg_hs in hs_map.keys():
                if pkg_hs not in invoice_hs_map:
                    missing_hs_in_invoice.append(pkg_hs)
                    warnings.append(f"HS Code '{pkg_hs}' exists in Packing List but is missing from Commercial Invoice.")

        # Populate all combined HS codes in summary
        all_hs_keys = set(hs_map.keys()).union(set(invoice_hs_map.keys()))
        has_qty_mismatch = False

        hs_summary = []
        for hs_key in sorted(all_hs_keys):
            pkg_data = hs_map.get(hs_key, {
                "hs_code": hs_key,
                "qty_pcs": 0.0,
                "qty_pkg": 0.0,
                "total_net_weight_kg": 0.0,
                "total_gross_weight_kg": 0.0,
                "total_cbm": 0.0,
            })
            inv_qty = invoice_hs_map.get(hs_key, 0.0)
            pkg_qty = pkg_data["qty_pcs"]
            diff = pkg_qty - inv_qty
            matched = abs(diff) < 0.001

            if not matched and po.line_items and po.packing_list_items:
                has_qty_mismatch = True
                warnings.append(f"HS Code '{hs_key}': Packing List Qty ({pkg_qty}) differs from Invoice Qty ({inv_qty}) [Diff: {diff:+.2f}].")

            hs_summary.append(
                PackingListSummaryByHSCode(
                    hs_code=pkg_data["hs_code"],
                    qty_pcs=pkg_data["qty_pcs"],
                    qty_pkg=pkg_data["qty_pkg"],
                    total_net_weight_kg=pkg_data["total_net_weight_kg"],
                    total_gross_weight_kg=pkg_data["total_gross_weight_kg"],
                    total_cbm=pkg_data["total_cbm"],
                    invoice_pcs=inv_qty,
                    discrepancy_pcs=diff,
                    is_matched=matched,
                )
            )

        # Check total PCS vs PO Invoice Line Items
        total_qty_mismatch = False
        if po.line_items and po.packing_list_items and abs(tot_pcs - po_total_pcs) > 0.01:
            total_qty_mismatch = True
            warnings.append(f"Total Quantity Mismatch: Packing List total PCS ({tot_pcs}) differs from Invoice total PCS ({po_total_pcs}) [Diff: {tot_pcs - po_total_pcs:+.2f}].")

        has_discrepancy = bool(
            missing_hs_in_packing
            or missing_hs_in_invoice
            or has_qty_mismatch
            or total_qty_mismatch
        )

        return PackingListValidationReport(
            is_valid=len(errors) == 0,
            has_discrepancy=has_discrepancy,
            errors=errors,
            warnings=warnings,
            total_items=len(po.packing_list_items),
            total_pcs=tot_pcs,
            total_pkg=tot_pkg,
            total_net_weight_kg=tot_net,
            total_gross_weight_kg=tot_gross,
            total_cbm=tot_cbm,
            chargeable_weight_kg=tot_chg,
            total_invoice_pcs=po_total_pcs,
            total_packing_pcs=tot_pcs,
            missing_hs_in_packing=missing_hs_in_packing,
            missing_hs_in_invoice=missing_hs_in_invoice,
            hs_code_summary=hs_summary,
        )


    def _to_response(self, po: PurchaseOrder) -> PurchaseOrderResponse:
        items_resp = []
        for item in po.line_items:
            items_resp.append(
                POLineItemResponse(
                    item_id=item.item_id,
                    po_id=item.po_id,
                    item_code=item.item_code,
                    description_ar=item.description_ar,
                    description_en=item.description_en,
                    country_of_origin=item.country_of_origin,
                    tariff_id=item.tariff_id,
                    quantity=float(item.quantity),
                    unit_of_measure=item.unit_of_measure,
                    unit_price=float(item.unit_price),
                    total_price=float(item.total_price),
                    cbm_per_unit=float(item.cbm_per_unit),
                    total_cbm=float(item.total_cbm),
                    gross_weight_kg=float(item.gross_weight_kg),
                    net_weight_kg=float(item.net_weight_kg),
                    created_at=item.created_at,
                    hs_code=item.tariff.hs_code if item.tariff else None,
                    duty_rate=float(item.tariff.customs_duty_rate) if item.tariff and item.tariff.customs_duty_rate is not None else None,
                    vat_rate=float(item.tariff.vat_rate) if item.tariff and item.tariff.vat_rate is not None else None,
                )
            )

        packing_items_resp = []
        for pitem in po.packing_list_items:
            packing_items_resp.append(
                PackingListItemResponse(
                    packing_item_id=pitem.packing_item_id,
                    po_id=pitem.po_id,
                    hs_code=pitem.hs_code,
                    item_code=pitem.item_code,
                    description=getattr(pitem, "description", None),
                    qty_pcs=float(pitem.qty_pcs),
                    qty_pkg=float(pitem.qty_pkg),
                    package_type=pitem.package_type,
                    weight_unit=getattr(pitem, "weight_unit", "KGM") or "KGM",
                    length_cm=float(pitem.length_cm or 0.0),
                    width_cm=float(pitem.width_cm or 0.0),
                    height_cm=float(pitem.height_cm or 0.0),
                    net_weight_unit_kg=float(pitem.net_weight_unit_kg),
                    gross_weight_unit_kg=float(pitem.gross_weight_unit_kg),
                    total_net_weight_kg=float(pitem.total_net_weight_kg),
                    total_gross_weight_kg=float(pitem.total_gross_weight_kg),
                    total_cbm=float(pitem.total_cbm),
                    chargeable_weight_kg=float(pitem.chargeable_weight_kg),
                    is_stackable=bool(pitem.is_stackable) if pitem.is_stackable is not None else True,
                    created_at=pitem.created_at,
                )
            )

        import_file_code = None
        if hasattr(po, "import_file") and po.import_file:
            import_file_code = getattr(po.import_file, "import_file_code", None) or getattr(po.import_file, "custom_file_number", None)

        return PurchaseOrderResponse(
            po_id=po.po_id,
            po_number=po.po_number,
            po_reference=getattr(po, "po_reference", None),
            import_file_id=po.import_file_id,
            import_file_code=import_file_code,
            proforma_invoice_number=po.proforma_invoice_number,
            country_of_origin=po.country_of_origin,
            project_id=po.project_id,
            company_id=po.company_id,
            supplier_id=po.supplier_id,
            incoterm_id=po.incoterm_id,
            currency_id=po.currency_id,
            order_date=po.order_date,
            expected_delivery_date=po.expected_delivery_date,
            exchange_rate=float(po.exchange_rate),
            payment_terms=po.payment_terms,
            total_amount_fob=float(po.total_amount_fob),
            total_cbm=float(po.total_cbm),
            total_gross_weight_kg=float(po.total_gross_weight_kg),
            total_net_weight_kg=float(po.total_net_weight_kg),
            total_packages_count=po.total_packages_count,
            pallet_count=getattr(po, "pallet_count", 0) or 0,
            pallet_type=getattr(po, "pallet_type", "Euro Pallet (120x80)") or "Euro Pallet (120x80)",
            is_pallet_stackable=bool(getattr(po, "is_pallet_stackable", False)),
            pallet_length_cm=float(getattr(po, "pallet_length_cm", 120.0) or 120.0),
            pallet_width_cm=float(getattr(po, "pallet_width_cm", 80.0) or 80.0),
            pallet_height_cm=float(getattr(po, "pallet_height_cm", 150.0) or 150.0),
            pallet_plan=(
                [PalletPlanItem(**p) if isinstance(p, dict) else p for p in json.loads(po.pallet_plan)]
                if getattr(po, "pallet_plan", None) and isinstance(po.pallet_plan, str)
                else (po.pallet_plan if isinstance(getattr(po, "pallet_plan", None), list) else [])
            ),
            status=po.status,
            notes=po.notes,
            is_active=po.is_active,
            created_at=po.created_at,
            updated_at=po.updated_at,
            project_name=po.project.project_name if po.project else None,
            company_name=po.company.importer_name if po.company else None,
            supplier_name=po.supplier.company_name if po.supplier else None,
            incoterm_code=po.incoterm.incoterm_code if po.incoterm else None,
            currency_code=po.currency.currency_code if po.currency else None,
            items=items_resp,
            packing_list_items=packing_items_resp,
        )

    def get_all(
        self,
        include_inactive: bool = False,
        status_filter: Optional[str] = None,
        project_id: Optional[int] = None,
        company_id: Optional[int] = None,
        supplier_id: Optional[int] = None,
        search: Optional[str] = None,
    ) -> List[PurchaseOrderResponse]:
        pos = self.repo.get_all(
            include_inactive=include_inactive,
            status_filter=status_filter,
            project_id=project_id,
            company_id=company_id,
            supplier_id=supplier_id,
            search=search,
        )
        return [self._to_response(po) for po in pos]

    def get_by_id(self, po_id: int) -> PurchaseOrderResponse:
        po = self.repo.get_by_id(po_id)
        if not po:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Purchase Order with ID {po_id} not found.",
            )
        return self._to_response(po)

    def create(self, data: PurchaseOrderCreate) -> PurchaseOrderResponse:
        self.validator.validate_foreign_keys(
            project_id=data.project_id,
            company_id=data.company_id,
            supplier_id=data.supplier_id,
            incoterm_id=data.incoterm_id,
            currency_id=data.currency_id,
        )
        if data.po_number:
            self.validator.validate_po_number_unique(data.po_number)

        po = self.repo.create(data)
        return self._to_response(po)

    def update(self, po_id: int, data: PurchaseOrderUpdate) -> PurchaseOrderResponse:
        po = self.repo.get_by_id(po_id)
        if not po:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Purchase Order with ID {po_id} not found.",
            )

        p_id = data.project_id or po.project_id
        c_id = data.company_id or po.company_id
        s_id = data.supplier_id or po.supplier_id
        i_id = data.incoterm_id or po.incoterm_id
        cur_id = data.currency_id or po.currency_id

        self.validator.validate_foreign_keys(
            project_id=p_id,
            company_id=c_id,
            supplier_id=s_id,
            incoterm_id=i_id,
            currency_id=cur_id,
        )

        updated_po = self.repo.update(po, data)
        return self._to_response(updated_po)

    def soft_delete(self, po_id: int) -> PurchaseOrderResponse:
        po = self.repo.get_by_id(po_id)
        if not po:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Purchase Order with ID {po_id} not found.",
            )
        deleted_po = self.repo.soft_delete(po)
        return self._to_response(deleted_po)

    def restore(self, po_id: int) -> PurchaseOrderResponse:
        po = self.repo.get_by_id(po_id)
        if not po:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Purchase Order with ID {po_id} not found.",
            )
        restored_po = self.repo.restore(po)
        return self._to_response(restored_po)
