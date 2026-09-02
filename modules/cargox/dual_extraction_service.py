"""
CGX-004: CargoX Dual Extraction Engine — Independent Invoice + Packing List Engines.

يُفصل محرك استخراج الفاتورة التجارية الجمركية عن محرك قائمة التعبئة الجمركية،
ويدعم 4 modes مستقلة لكل منهما.
"""

from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from collections import defaultdict, OrderedDict
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from .model import CargoXCustomsInvoiceTrack
from .schemas import (
    DualExtractionRequest,
    DualExtractionResponse,
    DualCustomsTrackCreate,
    PackingListPayload,
    PackingListLineItem,
    PackingListResultItem,
    PalletInput,
    ExtractionRequest,
    ExtractionResultItem,
    CustomsInvoiceTrackResponse,
)
from .service import CargoXExtractionEngine
from ..import_files.model import ImportFile


class PackingListExtractionEngine:
    """
    محرك استخراج قائمة التعبئة الجمركية المستقل (CGX-004).

    يدعم 4 Modes مستقلة:
    - all_consolidated:        بيان واحد مجمع بـ HS Code
    - all_detailed:            بيان واحد مفصل كل بند منفصل
    - per_invoice_consolidated: ZIP — ملف لكل فاتورة مجمع
    - per_invoice_detailed:    ZIP — ملف لكل فاتورة مفصل

    ويدعم 4 هياكل للطرود (PackingListStructure):
    - by_hs_code:  سطر لكل HS Code (مجمع)
    - flat:        كل بند مستقل
    - by_pallet:   كل بالتة + محتوياتها (يتطلب pallet_details)
    - by_carton:   مجموعات طرود بحسب رقم التسلسل
    """

    @staticmethod
    def extract(
        db: Session,
        import_file_id: int,
        request: DualExtractionRequest,
        invoices_raw: Dict[str, List[Dict]] = None,
        base_meta: Dict = None,
    ) -> List[PackingListResultItem]:
        """
        المدخل الرئيسي لمحرك الباكينج ليست.
        يُرجع قائمة من PackingListResultItem.
        """
        file = db.query(ImportFile).filter(
            ImportFile.import_file_id == import_file_id
        ).first()
        if not file:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"ملف الاستيراد رقم {import_file_id} غير موجود.",
            )

        # إعادة استخدام invoices_raw من InvoiceEngine لو موجود (تجنب query مكرر)
        if invoices_raw is None:
            company, supplier, pos = CargoXExtractionEngine._load_entities(db, file)
            reconciled_session = CargoXExtractionEngine._load_reconciled_session(db, import_file_id)
            inv_req = ExtractionRequest(
                mode="all_detailed",  # نريد كل البنود بالتفصيل لبناء الباكينج ليست
                grouping_mode="flat",
                invoice_filter=request.packing_filter,
            )
            raw_inv_req_obj = type("R", (), {
                "mode": "all_detailed",
                "grouping_mode": "flat",
                "invoice_filter": request.packing_filter,
            })()
            invoices_raw = CargoXExtractionEngine._collect_invoices_raw(
                file, pos, reconciled_session, supplier, raw_inv_req_obj
            )
            company_obj, supplier_obj, _ = CargoXExtractionEngine._load_entities(db, file)
            base_meta = CargoXExtractionEngine._build_base_payload(file, company_obj, supplier_obj)
        else:
            company, supplier, pos = CargoXExtractionEngine._load_entities(db, file)

        mode = request.packing_list_mode
        structure = request.packing_list_structure
        results: List[PackingListResultItem] = []

        if mode in ("all_consolidated", "all_detailed"):
            # دمج كل الفواتير في بيان واحد
            all_raw = []
            for inv_items in invoices_raw.values():
                all_raw.extend(inv_items)

            total_gross = sum(r["gross_weight_kg"] for r in all_raw)
            total_net = sum(r["net_weight_kg"] for r in all_raw)
            total_qty = sum(r["quantity"] for r in all_raw)

            structured_items = PackingListExtractionEngine._apply_structure(
                all_raw, structure, mode, request.pallet_details or []
            )

            payload = PackingListExtractionEngine._build_payload(
                base_meta or {},
                structured_items,
                structure,
                total_gross=total_gross,
                total_net=total_net,
                inv_number=None,
                packing_ref="PL-001",
                file=file,
                pallet_details=request.pallet_details,
            )
            results.append(PackingListResultItem(
                packing_list_ref="PL-001",
                invoice_number=None,
                payload=payload,
            ))

        else:
            # per_invoice: ملف منفصل لكل فاتورة
            for pl_idx, (inv_no, inv_items) in enumerate(invoices_raw.items(), start=1):
                if request.packing_filter and inv_no != request.packing_filter:
                    continue
                total_gross = sum(r["gross_weight_kg"] for r in inv_items)
                total_net = sum(r["net_weight_kg"] for r in inv_items)

                structured_items = PackingListExtractionEngine._apply_structure(
                    inv_items, structure, mode, request.pallet_details or []
                )
                pl_ref = f"PL-{pl_idx:03d}"
                payload = PackingListExtractionEngine._build_payload(
                    base_meta or {},
                    structured_items,
                    structure,
                    total_gross=total_gross,
                    total_net=total_net,
                    inv_number=inv_no,
                    packing_ref=pl_ref,
                    file=file,
                    pallet_details=request.pallet_details,
                )
                results.append(PackingListResultItem(
                    packing_list_ref=pl_ref,
                    invoice_number=inv_no,
                    payload=payload,
                ))

        return results

    # ------------------------------------------------------------------ #
    # Structure Builders
    # ------------------------------------------------------------------ #

    @staticmethod
    def _apply_structure(
        raw_items: List[Dict],
        structure: str,
        mode: str,
        pallet_details: List[PalletInput],
    ) -> List[PackingListLineItem]:
        """اختيار وتطبيق هيكل الطرود المناسب."""
        if structure == "by_pallet" and pallet_details:
            return PackingListExtractionEngine._structure_by_pallet(pallet_details)
        elif structure == "by_carton":
            return PackingListExtractionEngine._structure_by_carton(raw_items)
        elif structure == "flat" or "detailed" in mode:
            return PackingListExtractionEngine._structure_flat(raw_items)
        else:
            # by_hs_code (default)
            return PackingListExtractionEngine._structure_by_hs_code(raw_items)

    @staticmethod
    def _structure_by_hs_code(raw_items: List[Dict]) -> List[PackingListLineItem]:
        """
        سطر واحد لكل HS Code — أوزان وكميات مجمعة.
        الأكثر شيوعاً في التعامل الجمركي المصري.
        """
        grouped: Dict[str, Dict] = OrderedDict()
        for r in raw_items:
            hs = r["hs_code"]
            if hs not in grouped:
                grouped[hs] = {
                    "hs_code": hs,
                    "description": r["description"],
                    "manufacturer": r.get("manufacturer") or "Manufacturer",
                    "qty_unit": r["qty_unit"],
                    "quantity": 0.0,
                    "net_weight_kg": 0.0,
                    "gross_weight_kg": 0.0,
                    "invoice_number": r.get("invoice_number"),
                }
            grouped[hs]["quantity"] += r["quantity"]
            grouped[hs]["net_weight_kg"] += r["net_weight_kg"]
            grouped[hs]["gross_weight_kg"] += r["gross_weight_kg"]

        items = []
        for idx, (hs, grp) in enumerate(grouped.items(), start=1):
            items.append(PackingListLineItem(
                line_number=idx,
                package_ref=f"PKG-{idx:02d}",
                hs_code=grp["hs_code"],
                description=grp["description"],
                manufacturer=grp["manufacturer"],
                quantity=round(grp["quantity"], 2),
                qty_unit=grp["qty_unit"],
                net_weight_kg=round(grp["net_weight_kg"], 2),
                gross_weight_kg=round(grp["gross_weight_kg"], 2),
                invoice_number=grp.get("invoice_number"),
            ))
        return items

    @staticmethod
    def _structure_flat(raw_items: List[Dict]) -> List[PackingListLineItem]:
        """كل بند استيراد في سطر مستقل بكامل بياناته."""
        items = []
        for idx, r in enumerate(raw_items, start=1):
            items.append(PackingListLineItem(
                line_number=idx,
                package_ref=f"CTN-{idx:02d}",
                hs_code=r["hs_code"],
                description=r["description"],
                manufacturer=r.get("manufacturer") or "Manufacturer",
                quantity=round(r["quantity"], 2),
                qty_unit=r["qty_unit"],
                net_weight_kg=round(r["net_weight_kg"], 2),
                gross_weight_kg=round(r["gross_weight_kg"], 2),
                invoice_number=r.get("invoice_number"),
            ))
        return items

    @staticmethod
    def _structure_by_pallet(pallet_details: List[PalletInput]) -> List[PackingListLineItem]:
        """
        كل بالتة = مجموعة سطور + تفصيل محتوياتها.
        يستخدم البيانات المُدخلة يدوياً من المستخدم.
        """
        items = []
        line_num = 1
        for pallet in pallet_details:
            for item in pallet.items:
                items.append(PackingListLineItem(
                    line_number=line_num,
                    package_ref=pallet.pallet_number,
                    hs_code=item.hs_code,
                    description=item.description,
                    manufacturer=None,
                    quantity=round(item.quantity, 2),
                    qty_unit=item.qty_unit,
                    net_weight_kg=round(item.net_weight_kg, 2),
                    gross_weight_kg=round(item.gross_weight_kg, 2),
                    pallet_number=pallet.pallet_number,
                    carton_numbers=item.carton_numbers,
                    dimensions_cm=pallet.dimensions_cm,
                ))
                line_num += 1
        return items

    @staticmethod
    def _structure_by_carton(raw_items: List[Dict]) -> List[PackingListLineItem]:
        """
        تجميع بحسب مجموعات الكراتين/الطرود.
        كل بند له رقم طرد تسلسلي (CTN-001).
        """
        # نفس flat لكن يمكن تطويره لدعم carton_numbers من packing_list_items مستقبلاً
        return PackingListExtractionEngine._structure_flat(raw_items)

    @staticmethod
    def _build_payload(
        base_meta: Dict,
        structured_items: List[PackingListLineItem],
        structure: str,
        total_gross: float,
        total_net: float,
        inv_number: Optional[str],
        packing_ref: str,
        file: "ImportFile",
        pallet_details: Optional[List[PalletInput]] = None,
    ) -> PackingListPayload:
        """بناء PackingListPayload الكامل."""
        pallets_summary = None
        if pallet_details:
            pallets_summary = [
                {
                    "pallet_number": p.pallet_number,
                    "pallet_type": p.pallet_type,
                    "dimensions_cm": p.dimensions_cm,
                    "gross_weight_kg": p.gross_weight_kg,
                    "net_weight_kg": p.net_weight_kg,
                    "items_count": len(p.items),
                }
                for p in pallet_details
            ]

        return PackingListPayload(
            acid_number=base_meta.get("acid_number") or getattr(file, "acid_number", None),
            seller_name=base_meta.get("seller_name"),
            seller_address=base_meta.get("seller_address"),
            seller_country_code=base_meta.get("seller_country_code"),
            buyer_name=base_meta.get("buyer_name"),
            buyer_address=base_meta.get("buyer_address"),
            buyer_tax_id=base_meta.get("buyer_tax_id"),
            invoice_number=inv_number,
            invoice_date=datetime.now(timezone.utc).strftime("%Y-%m-%d"),
            packing_list_ref=packing_ref,
            origin_port=base_meta.get("origin_port"),
            destination_port=base_meta.get("destination_port"),
            incoterm=base_meta.get("incoterm"),
            currency_code=base_meta.get("currency_code"),
            total_packages=len(structured_items),
            total_gross_weight_kg=round(total_gross, 2),
            total_net_weight_kg=round(total_net, 2),
            structure=structure,
            items=structured_items,
            pallets=pallets_summary,
        )


class CargoXDualExtractionEngine:
    """
    محرك الاستخراج المزدوج (CGX-004).
    يُشغّل InvoiceExtractionEngine و PackingListExtractionEngine باستقلالية كاملة
    ثم يُجمع النتائج في DualExtractionResponse.
    """

    @staticmethod
    def extract_dual(
        db: Session,
        import_file_id: int,
        request: DualExtractionRequest,
    ) -> DualExtractionResponse:
        """
        استخراج مزدوج كامل — فاتورة + باكينج ليست.
        """
        file = db.query(ImportFile).filter(
            ImportFile.import_file_id == import_file_id
        ).first()
        if not file:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"ملف الاستيراد رقم {import_file_id} غير موجود.",
            )

        # ---- 1. استخراج الفاتورة (Invoice Engine) ----
        inv_req = ExtractionRequest(
            mode=request.invoice_mode,
            grouping_mode=request.invoice_grouping,
            invoice_filter=request.invoice_filter,
        )
        invoice_response = CargoXExtractionEngine.extract(db, import_file_id, inv_req)

        # ---- 2. جمع البيانات الخام المشتركة لتمريرها للـ PL Engine ----
        company, supplier, pos = CargoXExtractionEngine._load_entities(db, file)
        reconciled_session = CargoXExtractionEngine._load_reconciled_session(db, import_file_id)
        # نستخدم flat + all_detailed لجمع كل البنود للباكينج ليست
        pl_raw_req = type("R", (), {
            "mode": "all_detailed",
            "grouping_mode": "flat",
            "invoice_filter": request.packing_filter,
        })()
        invoices_raw_for_pl = CargoXExtractionEngine._collect_invoices_raw(
            file, pos, reconciled_session, supplier, pl_raw_req
        )
        base_meta = CargoXExtractionEngine._build_base_payload(file, company, supplier)

        # ---- 3. استخراج الباكينج ليست (Packing List Engine) ----
        pl_results = PackingListExtractionEngine.extract(
            db,
            import_file_id,
            request,
            invoices_raw=invoices_raw_for_pl,
            base_meta=base_meta,
        )

        return DualExtractionResponse(
            import_file_id=import_file_id,
            import_file_code=file.import_file_code,
            invoice_mode=request.invoice_mode,
            invoice_grouping=request.invoice_grouping,
            invoice_invoices_count=invoice_response.invoices_count,
            invoice_total_line_items=invoice_response.total_line_items,
            invoice_results=invoice_response.results,
            packing_list_mode=request.packing_list_mode,
            packing_list_structure=request.packing_list_structure,
            packing_list_count=len(pl_results),
            packing_list_total_items=sum(len(r.payload.items) for r in pl_results),
            packing_list_results=pl_results,
        )

    @staticmethod
    def create_dual_customs_track(
        db: Session,
        payload: DualCustomsTrackCreate,
        created_by: str = "SYSTEM",
    ) -> CargoXCustomsInvoiceTrack:
        """
        إنشاء مسار جمركي مزدوج ويحفظه في DB.
        يُشغّل المحرك المزدوج ثم يحفظ snapshots الفاتورة والباكينج ليست مستقلاً.
        """
        file = db.query(ImportFile).filter(
            ImportFile.import_file_id == payload.import_file_id
        ).first()
        if not file:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"ملف الاستيراد رقم {payload.import_file_id} غير موجود.",
            )

        dual_req = DualExtractionRequest(
            invoice_mode=payload.invoice_mode,
            invoice_grouping=payload.invoice_grouping,
            invoice_filter=payload.invoice_filter,
            packing_list_mode=payload.packing_list_mode,
            packing_list_structure=payload.packing_list_structure,
            packing_filter=payload.packing_filter,
            include_pallets=payload.include_pallets,
            pallet_details=payload.pallet_details,
            notes=payload.notes,
        )

        dual_response = CargoXDualExtractionEngine.extract_dual(
            db, payload.import_file_id, dual_req
        )

        # بناء track code
        existing_count = (
            db.query(CargoXCustomsInvoiceTrack)
            .filter(CargoXCustomsInvoiceTrack.import_file_id == payload.import_file_id)
            .count()
        )
        track_code = f"CX-CUST-{file.import_file_code}-{existing_count + 1:03d}"

        # مجاميع من الفاتورة
        total_amount = sum(r.payload.total_amount for r in dual_response.invoice_results)
        total_gross = sum(r.payload.gross_weight for r in dual_response.invoice_results)
        total_net = sum(r.payload.net_weight for r in dual_response.invoice_results)
        source_invs = [r.invoice_number for r in dual_response.invoice_results if r.invoice_number]

        # snapshot الفاتورة
        all_inv_data = [r.payload.model_dump() for r in dual_response.invoice_results]
        inv_snapshot = all_inv_data if len(all_inv_data) > 1 else (all_inv_data[0] if all_inv_data else {})

        # snapshot الباكينج ليست
        pl_snapshots = [
            {
                "packing_list_ref": r.packing_list_ref,
                "invoice_number": r.invoice_number,
                "structure": r.payload.structure,
                "total_packages": r.payload.total_packages,
                "total_gross_weight_kg": r.payload.total_gross_weight_kg,
                "total_net_weight_kg": r.payload.total_net_weight_kg,
                "items": [item.model_dump() for item in r.payload.items],
                "pallets": r.payload.pallets,
            }
            for r in dual_response.packing_list_results
        ]
        pl_snapshot = pl_snapshots if len(pl_snapshots) > 1 else (pl_snapshots[0] if pl_snapshots else {})

        # بيانات البالتات لحفظها
        pallets_snapshot = None
        if payload.pallet_details:
            pallets_snapshot = [p.model_dump() for p in payload.pallet_details]

        track = CargoXCustomsInvoiceTrack(
            track_code=track_code,
            import_file_id=payload.import_file_id,
            import_file_code=file.import_file_code,
            source_invoice_numbers=source_invs,
            # Invoice fields
            extraction_mode=payload.invoice_mode,
            grouping_mode=payload.invoice_grouping,
            # PL fields (CGX-004)
            packing_list_mode=payload.packing_list_mode,
            packing_list_structure=payload.packing_list_structure,
            packing_list_count=dual_response.packing_list_count,
            include_pallets=payload.include_pallets,
            pallets_data=pallets_snapshot,
            # Totals
            customs_total_amount=round(total_amount, 2),
            customs_gross_weight=round(total_gross, 2),
            customs_net_weight=round(total_net, 2),
            customs_packages_count=sum(r.payload.total_packages for r in dual_response.packing_list_results),
            line_items_count=dual_response.invoice_total_line_items,
            # Snapshots
            customs_invoice_data=inv_snapshot,
            customs_packing_list_data=pl_snapshot,
            status="DRAFT",
            notes=payload.notes,
            created_by=created_by,
            updated_by=created_by,
        )
        db.add(track)
        db.commit()
        db.refresh(track)
        return track
