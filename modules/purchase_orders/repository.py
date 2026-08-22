from datetime import datetime, timezone
from typing import List, Optional

from sqlalchemy import or_
from sqlalchemy.orm import Session

from modules.purchase_orders.model import POLineItem, PackingListItem, PurchaseOrder
from modules.purchase_orders.schemas import PurchaseOrderCreate, PurchaseOrderUpdate


class PurchaseOrderRepository:

    def __init__(self, db: Session):
        self.db = db

    def generate_po_number(self) -> str:
        year = datetime.now().year
        count = self.db.query(PurchaseOrder).count() + 1
        return f"PO-{year}-{count:03d}"

    def get_by_id(self, po_id: int) -> Optional[PurchaseOrder]:
        return self.db.query(PurchaseOrder).filter(PurchaseOrder.po_id == po_id).first()

    def get_by_number(self, po_number: str) -> Optional[PurchaseOrder]:
        return self.db.query(PurchaseOrder).filter(PurchaseOrder.po_number == po_number.upper().strip()).first()

    def get_all(
        self,
        include_inactive: bool = False,
        status_filter: Optional[str] = None,
        project_id: Optional[int] = None,
        company_id: Optional[int] = None,
        supplier_id: Optional[int] = None,
        search: Optional[str] = None,
    ) -> List[PurchaseOrder]:
        query = self.db.query(PurchaseOrder)

        if not include_inactive:
            query = query.filter(PurchaseOrder.is_active.is_(True))

        if status_filter:
            query = query.filter(PurchaseOrder.status == status_filter)

        if project_id:
            query = query.filter(PurchaseOrder.project_id == project_id)

        if company_id:
            query = query.filter(PurchaseOrder.company_id == company_id)

        if supplier_id:
            query = query.filter(PurchaseOrder.supplier_id == supplier_id)

        if search:
            pattern = f"%{search.strip()}%"
            query = query.filter(
                or_(
                    PurchaseOrder.po_number.ilike(pattern),
                    PurchaseOrder.proforma_invoice_number.ilike(pattern),
                    PurchaseOrder.notes.ilike(pattern),
                )
            )

        return query.order_by(PurchaseOrder.created_at.desc()).all()

    def create(self, data: PurchaseOrderCreate) -> PurchaseOrder:
        po_num = data.po_number.upper().strip() if data.po_number else self.generate_po_number()

        po = PurchaseOrder(
            po_number=po_num,
            import_file_id=data.import_file_id,
            proforma_invoice_number=data.proforma_invoice_number.strip() if data.proforma_invoice_number else None,
            country_of_origin=data.country_of_origin.strip() if data.country_of_origin else None,
            project_id=data.project_id,
            company_id=data.company_id,
            supplier_id=data.supplier_id,
            incoterm_id=data.incoterm_id,
            currency_id=data.currency_id,
            order_date=data.order_date or datetime.now(timezone.utc),
            expected_delivery_date=data.expected_delivery_date,
            exchange_rate=data.exchange_rate,
            payment_terms=data.payment_terms.strip() if data.payment_terms else None,
            notes=data.notes.strip() if data.notes else None,
            pallet_count=getattr(data, "pallet_count", 0) or 0,
            pallet_type=getattr(data, "pallet_type", "Euro Pallet (120x80)") or "Euro Pallet (120x80)",
            is_pallet_stackable=bool(getattr(data, "is_pallet_stackable", False)),
            pallet_length_cm=float(getattr(data, "pallet_length_cm", 120.0) or 120.0),
            pallet_width_cm=float(getattr(data, "pallet_width_cm", 80.0) or 80.0),
            pallet_height_cm=float(getattr(data, "pallet_height_cm", 150.0) or 150.0),
            status="Draft",
            is_active=True,
        )

        total_fob = 0.0
        total_cbm = 0.0
        total_gross = 0.0
        total_net = 0.0
        total_pkgs = 0

        for item in data.items:
            line_price = round(item.quantity * item.unit_price, 2)
            line_cbm = round(item.quantity * item.cbm_per_unit, 4)

            total_fob += line_price
            total_cbm += line_cbm
            total_gross += item.gross_weight_kg
            total_net += item.net_weight_kg
            total_pkgs += int(item.quantity)

            po_item = POLineItem(
                item_code=item.item_code.strip() if item.item_code else None,
                description_ar=item.description_ar.strip(),
                description_en=item.description_en.strip() if item.description_en else None,
                country_of_origin=item.country_of_origin.strip() if item.country_of_origin else None,
                tariff_id=item.tariff_id,
                quantity=item.quantity,
                unit_of_measure=item.unit_of_measure.strip(),
                unit_price=item.unit_price,
                total_price=line_price,
                cbm_per_unit=item.cbm_per_unit,
                total_cbm=line_cbm,
                gross_weight_kg=item.gross_weight_kg,
                net_weight_kg=item.net_weight_kg,
            )
            po.line_items.append(po_item)

        # Process Packing List Items
        if data.packing_list_items:
            pkg_total_net = 0.0
            pkg_total_gross = 0.0
            pkg_total_cbm = 0.0
            pkg_count = 0.0

            for pitem in data.packing_list_items:
                tot_net = round(pitem.qty_pkg * pitem.net_weight_unit_kg, 2)
                tot_gross = round(pitem.qty_pkg * pitem.gross_weight_unit_kg, 2)
                unit_str = getattr(pitem, "unit", "cm") or "cm"
                l_val = pitem.length_cm or 0.0
                w_val = pitem.width_cm or 0.0
                h_val = pitem.height_cm or 0.0

                if unit_str == "mm":
                    l_m, w_m, h_m = l_val / 1000.0, w_val / 1000.0, h_val / 1000.0
                    l_cm_val, w_cm_val, h_cm_val = l_val / 10.0, w_val / 10.0, h_val / 10.0
                elif unit_str == "m":
                    l_m, w_m, h_m = l_val, w_val, h_val
                    l_cm_val, w_cm_val, h_cm_val = l_val * 100.0, w_val * 100.0, h_val * 100.0
                else:
                    l_m, w_m, h_m = l_val / 100.0, w_val / 100.0, h_val / 100.0
                    l_cm_val, w_cm_val, h_cm_val = l_val, w_val, h_val

                direct_cbm = float(getattr(pitem, "total_cbm", 0.0) or 0.0)
                tot_cbm = round(pitem.qty_pkg * (l_m * w_m * h_m), 4) if (l_m > 0 and w_m > 0 and h_m > 0) else direct_cbm
                chg_wt = max(tot_gross, round(tot_cbm * 167.0, 2))

                pkg_total_net += tot_net
                pkg_total_gross += tot_gross
                pkg_total_cbm += tot_cbm
                pkg_count += pitem.qty_pkg

                pli = PackingListItem(
                    hs_code=pitem.hs_code.strip(),
                    item_code=pitem.item_code.strip(),
                    qty_pcs=pitem.qty_pcs,
                    qty_pkg=pitem.qty_pkg,
                    package_type=pitem.package_type.strip() if pitem.package_type else "Carton",
                    length_cm=l_cm_val,
                    width_cm=w_cm_val,
                    height_cm=h_cm_val,
                    net_weight_unit_kg=pitem.net_weight_unit_kg,
                    gross_weight_unit_kg=pitem.gross_weight_unit_kg,
                    total_net_weight_kg=tot_net,
                    total_gross_weight_kg=tot_gross,
                    total_cbm=tot_cbm,
                    chargeable_weight_kg=chg_wt,
                    is_stackable=bool(getattr(pitem, "is_stackable", True)),
                )
                po.packing_list_items.append(pli)

            # Sync PO totals from Packing List if provided
            total_cbm = pkg_total_cbm if pkg_total_cbm > 0 else total_cbm
            total_gross = pkg_total_gross if pkg_total_gross > 0 else total_gross
            total_net = pkg_total_net if pkg_total_net > 0 else total_net
            total_pkgs = int(pkg_count) if pkg_count > 0 else total_pkgs

        po.total_amount_fob = total_fob
        po.total_cbm = total_cbm
        po.total_gross_weight_kg = total_gross
        po.total_net_weight_kg = total_net
        po.total_packages_count = total_pkgs

        self.db.add(po)
        self.db.commit()
        self.db.refresh(po)
        return po

    def update(self, po: PurchaseOrder, data: PurchaseOrderUpdate) -> PurchaseOrder:
        update_data = data.model_dump(exclude_unset=True)
        items_data = update_data.pop("items", None)
        packing_items_data = update_data.pop("packing_list_items", None)

        for field, value in update_data.items():
            if value is not None and isinstance(value, str):
                value = value.strip()
            setattr(po, field, value)

        total_fob = float(po.total_amount_fob or 0.0)
        total_cbm = float(po.total_cbm or 0.0)
        total_gross = float(po.total_gross_weight_kg or 0.0)
        total_net = float(po.total_net_weight_kg or 0.0)
        total_pkgs = int(po.total_packages_count or 0)

        if items_data is not None:
            # Recreate line items
            po.line_items.clear()

            total_fob = 0.0
            total_cbm = 0.0
            total_gross = 0.0
            total_net = 0.0
            total_pkgs = 0

            for item_dict in items_data:
                qty = item_dict.get("quantity", 0.0)
                price = item_dict.get("unit_price", 0.0)
                cbm_unit = item_dict.get("cbm_per_unit", 0.0)
                gross = item_dict.get("gross_weight_kg", 0.0)
                net = item_dict.get("net_weight_kg", 0.0)

                line_price = round(qty * price, 2)
                line_cbm = round(qty * cbm_unit, 4)

                total_fob += line_price
                total_cbm += line_cbm
                total_gross += gross
                total_net += net
                total_pkgs += int(qty)

                po_item = POLineItem(
                    item_code=item_dict.get("item_code"),
                    description_ar=item_dict.get("description_ar", "").strip(),
                    description_en=item_dict.get("description_en"),
                    country_of_origin=item_dict.get("country_of_origin", "").strip() if item_dict.get("country_of_origin") else None,
                    tariff_id=item_dict.get("tariff_id"),
                    quantity=qty,
                    unit_of_measure=item_dict.get("unit_of_measure", "PCS"),
                    unit_price=price,
                    total_price=line_price,
                    cbm_per_unit=cbm_unit,
                    total_cbm=line_cbm,
                    gross_weight_kg=gross,
                    net_weight_kg=net,
                )
                po.line_items.append(po_item)

        if packing_items_data is not None:
            po.packing_list_items.clear()

            pkg_total_net = 0.0
            pkg_total_gross = 0.0
            pkg_total_cbm = 0.0
            pkg_count = 0.0

            for pitem in packing_items_data:
                q_pcs = pitem.get("qty_pcs", 1.0)
                q_pkg = pitem.get("qty_pkg", 1.0)
                net_u = pitem.get("net_weight_unit_kg", 0.0)
                gross_u = pitem.get("gross_weight_unit_kg", 0.0)
                unit_str = pitem.get("unit", "cm") or "cm"
                l_val = pitem.get("length_cm") or 0.0
                w_val = pitem.get("width_cm") or 0.0
                h_val = pitem.get("height_cm") or 0.0

                if unit_str == "mm":
                    l_m, w_m, h_m = l_val / 1000.0, w_val / 1000.0, h_val / 1000.0
                    l_cm_val, w_cm_val, h_cm_val = l_val / 10.0, w_val / 10.0, h_val / 10.0
                elif unit_str == "m":
                    l_m, w_m, h_m = l_val, w_val, h_val
                    l_cm_val, w_cm_val, h_cm_val = l_val * 100.0, w_val * 100.0, h_val * 100.0
                else:
                    l_m, w_m, h_m = l_val / 100.0, w_val / 100.0, h_val / 100.0
                    l_cm_val, w_cm_val, h_cm_val = l_val, w_val, h_val

                tot_net = round(q_pkg * net_u, 2)
                tot_gross = round(q_pkg * gross_u, 2)
                direct_cbm = float(pitem.get("total_cbm", 0.0) or 0.0)
                tot_cbm = round(q_pkg * (l_m * w_m * h_m), 4) if (l_m > 0 and w_m > 0 and h_m > 0) else direct_cbm
                chg_wt = max(tot_gross, round(tot_cbm * 167.0, 2))

                pkg_total_net += tot_net
                pkg_total_gross += tot_gross
                pkg_total_cbm += tot_cbm
                pkg_count += q_pkg

                pli = PackingListItem(
                    hs_code=str(pitem.get("hs_code", "")).strip(),
                    item_code=str(pitem.get("item_code", "")).strip(),
                    qty_pcs=q_pcs,
                    qty_pkg=q_pkg,
                    package_type=pitem.get("package_type", "Carton"),
                    length_cm=l_cm_val,
                    width_cm=w_cm_val,
                    height_cm=h_cm_val,
                    net_weight_unit_kg=net_u,
                    gross_weight_unit_kg=gross_u,
                    total_net_weight_kg=tot_net,
                    total_gross_weight_kg=tot_gross,
                    total_cbm=tot_cbm,
                    chargeable_weight_kg=chg_wt,
                    is_stackable=bool(pitem.get("is_stackable", True)),
                )
                po.packing_list_items.append(pli)

            if pkg_total_cbm > 0:
                total_cbm = pkg_total_cbm
            if pkg_total_gross > 0:
                total_gross = pkg_total_gross
            if pkg_total_net > 0:
                total_net = pkg_total_net
            if pkg_count > 0:
                total_pkgs = int(pkg_count)

        po.total_amount_fob = total_fob
        po.total_cbm = total_cbm
        po.total_gross_weight_kg = total_gross
        po.total_net_weight_kg = total_net
        po.total_packages_count = total_pkgs

        self.db.commit()
        self.db.refresh(po)
        return po

    def soft_delete(self, po: PurchaseOrder) -> PurchaseOrder:
        po.is_active = False
        self.db.commit()
        self.db.refresh(po)
        return po

    def restore(self, po: PurchaseOrder) -> PurchaseOrder:
        po.is_active = True
        self.db.commit()
        self.db.refresh(po)
        return po
