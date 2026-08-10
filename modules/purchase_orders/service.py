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
            t_gross = float(item.total_gross_weight_kg or 0.0)
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

        # Check total PCS vs PO Invoice Line Items
        po_total_pcs = sum(float(i.quantity) for i in po.line_items)
        if po.line_items and abs(tot_pcs - po_total_pcs) > 0.01:
            warnings.append(f"Packing List total PCS ({tot_pcs}) differs from PO line items total PCS ({po_total_pcs}).")

        hs_summary = [PackingListSummaryByHSCode(**data) for data in hs_map.values()]

        return PackingListValidationReport(
            is_valid=len(errors) == 0,
            errors=errors,
            warnings=warnings,
            total_items=len(po.packing_list_items),
            total_pcs=tot_pcs,
            total_pkg=tot_pkg,
            total_net_weight_kg=tot_net,
            total_gross_weight_kg=tot_gross,
            total_cbm=tot_cbm,
            chargeable_weight_kg=tot_chg,
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
                    qty_pcs=float(pitem.qty_pcs),
                    qty_pkg=float(pitem.qty_pkg),
                    package_type=pitem.package_type,
                    length_cm=float(pitem.length_cm or 0.0),
                    width_cm=float(pitem.width_cm or 0.0),
                    height_cm=float(pitem.height_cm or 0.0),
                    net_weight_unit_kg=float(pitem.net_weight_unit_kg),
                    gross_weight_unit_kg=float(pitem.gross_weight_unit_kg),
                    total_net_weight_kg=float(pitem.total_net_weight_kg),
                    total_gross_weight_kg=float(pitem.total_gross_weight_kg),
                    total_cbm=float(pitem.total_cbm),
                    chargeable_weight_kg=float(pitem.chargeable_weight_kg),
                    created_at=pitem.created_at,
                )
            )

        import_file_code = None
        if hasattr(po, "import_file") and po.import_file:
            import_file_code = getattr(po.import_file, "file_code", None) or getattr(po.import_file, "custom_file_number", None)

        return PurchaseOrderResponse(
            po_id=po.po_id,
            po_number=po.po_number,
            import_file_id=po.import_file_id,
            import_file_code=import_file_code,
            proforma_invoice_number=po.proforma_invoice_number,
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
