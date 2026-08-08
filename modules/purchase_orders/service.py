from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from modules.purchase_orders.model import PurchaseOrder
from modules.purchase_orders.repository import PurchaseOrderRepository
from modules.purchase_orders.schemas import POLineItemResponse, PurchaseOrderCreate, PurchaseOrderResponse, PurchaseOrderUpdate
from modules.purchase_orders.validators import PurchaseOrderValidator


class PurchaseOrderService:

    def __init__(self, db: Session):
        self.db = db
        self.repo = PurchaseOrderRepository(db)
        self.validator = PurchaseOrderValidator(db)

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

        return PurchaseOrderResponse(
            po_id=po.po_id,
            po_number=po.po_number,
            proforma_invoice_number=po.proforma_invoice_number,
            project_id=po.project_id,
            company_id=po.company_id,
            supplier_id=po.supplier_id,
            incoterm_id=po.incoterm_id,
            currency_id=po.currency_id,
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
