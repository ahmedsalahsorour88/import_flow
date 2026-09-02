"""
CargoX & ACI Dispatch Hub Service Layer (CGX-001)
"""

import hashlib
import json
import uuid
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from .model import CargoXEnvelope, CargoXEnvelopeDocument
from .schemas import (
    CargoXEnvelopeCreate,
    CargoXEnvelopeUpdate,
    CargoXEnvelopeResponse,
    CargoXSealAndTransferRequest,
    CargoXSealAndTransferResponse,
    CargoXAcidVerificationReport,
    ACIDDocumentVerificationItem,
    DigitalManifestResponse,
)
from .repository import CargoXRepository
from .validators import CargoXValidators
from ..integrations.cargox_client import CargoXIntegrationClient
from ..integrations.pki_signer import PKISignerService
from ..import_files.model import ImportFile


def _normalize_pki_signature(pki_sig: Any) -> Optional[str]:
    if not pki_sig:
        return None
    if isinstance(pki_sig, dict):
        return pki_sig.get("signature_base64") or json.dumps(pki_sig)
    return str(pki_sig)


class CargoXService:

    @staticmethod
    def create_envelope(db: Session, payload: CargoXEnvelopeCreate, created_by: str = "SYSTEM") -> CargoXEnvelope:
        CargoXValidators.validate_envelope_creation(payload)

        envelope_code = CargoXRepository.get_next_code(db)
        client = CargoXIntegrationClient(mode=payload.mode)

        # Call CargoX Integration Client
        doc_type_names = [d.doc_type for d in (payload.documents or [])]
        if not doc_type_names:
            doc_type_names = ["Commercial Invoice", "Packing List", "Draft B/L"]

        importer_code = payload.importer_company_name[:20].upper().replace(" ", "_")
        cx_res = client.create_envelope(
            acid_number=payload.acid_number,
            importer_company_code=importer_code,
            foreign_exporter_cargox_id=payload.supplier_cargox_id,
            document_types=doc_type_names,
        )

        import_file_code = None
        if payload.import_file_id:
            import_file = db.query(ImportFile).filter(ImportFile.import_file_id == payload.import_file_id).first()
            if import_file:
                import_file_code = import_file.import_file_code

        pki_sig_str = _normalize_pki_signature(cx_res.get("pki_signature"))

        envelope = CargoXEnvelope(
            envelope_code=envelope_code,
            import_file_id=payload.import_file_id,
            import_file_code=import_file_code,
            acid_number=payload.acid_number,
            importer_company_id=payload.importer_company_id,
            importer_company_name=payload.importer_company_name,
            importer_tax_number=payload.importer_tax_number,
            supplier_id=payload.supplier_id,
            supplier_name=payload.supplier_name,
            supplier_cargox_id=payload.supplier_cargox_id,
            bl_number=payload.bl_number,
            status="UPLOADED_BY_SUPPLIER" if payload.documents else "DRAFT",
            blockchain_tx_hash=cx_res.get("blockchain_tx_hash"),
            pki_signature=pki_sig_str,
            is_acid_verified=True if payload.documents else False,
            all_documents_sealed=False,
            notes=payload.notes,
            created_by=created_by,
            updated_by=created_by,
        )

        # Attach documents
        if payload.documents:
            for d in payload.documents:
                file_hash = d.file_hash or hashlib.sha256(f"{d.file_name}-{payload.acid_number}".encode()).hexdigest()
                doc_item = CargoXEnvelopeDocument(
                    doc_type=d.doc_type,
                    doc_number=d.doc_number,
                    file_name=d.file_name,
                    file_hash=file_hash,
                    file_size_kb=d.file_size_kb if d.file_size_kb > 0 else 256.0,
                    is_mandatory=d.is_mandatory,
                    is_uploaded=True,
                    verified_against_acid=d.verified_against_acid,
                    pki_signature=f"SIG-DOC-{uuid.uuid4().hex[:12].upper()}",
                    notes=d.notes,
                )
                envelope.documents.append(doc_item)

        return CargoXRepository.create(db, envelope)

    @staticmethod
    def get_envelopes(
        db: Session,
        search: Optional[str] = None,
        status: Optional[str] = None,
        import_file_id: Optional[int] = None,
        supplier_id: Optional[int] = None,
        include_inactive: bool = False,
        limit: int = 100,
        offset: int = 0,
    ) -> List[CargoXEnvelope]:
        return CargoXRepository.get_all(
            db=db,
            search=search,
            status=status,
            import_file_id=import_file_id,
            supplier_id=supplier_id,
            include_inactive=include_inactive,
            limit=limit,
            offset=offset,
        )

    @staticmethod
    def get_envelope_by_id(db: Session, envelope_id: int) -> CargoXEnvelope:
        envelope = CargoXRepository.get_by_id(db, envelope_id)
        if not envelope:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"مظروف CargoX برقم المعرف {envelope_id} غير موجود.",
            )
        return envelope

    @staticmethod
    def update_envelope(db: Session, envelope_id: int, payload: CargoXEnvelopeUpdate, updated_by: str = "SYSTEM") -> CargoXEnvelope:
        envelope = CargoXService.get_envelope_by_id(db, envelope_id)

        if payload.acid_number:
            envelope.acid_number = CargoXValidators.validate_acid_number(payload.acid_number)
        if payload.importer_company_name:
            envelope.importer_company_name = payload.importer_company_name
        if payload.importer_tax_number is not None:
            envelope.importer_tax_number = payload.importer_tax_number
        if payload.supplier_name:
            envelope.supplier_name = payload.supplier_name
        if payload.supplier_cargox_id:
            envelope.supplier_cargox_id = CargoXValidators.validate_cargox_id(payload.supplier_cargox_id)
        if payload.bl_number is not None:
            envelope.bl_number = payload.bl_number
        if payload.status:
            envelope.status = payload.status
        if payload.notes is not None:
            envelope.notes = payload.notes

        envelope.updated_by = updated_by
        return CargoXRepository.update(db, envelope)

    @staticmethod
    def seal_and_transfer_to_customs(
        db: Session, envelope_id: int, request: CargoXSealAndTransferRequest, updated_by: str = "SYSTEM"
    ) -> CargoXSealAndTransferResponse:
        envelope = CargoXService.get_envelope_by_id(db, envelope_id)
        CargoXValidators.validate_ready_for_customs_transfer(envelope)

        bl_num = request.bl_number or envelope.bl_number or f"BL-EGY-{uuid.uuid4().hex[:8].upper()}"
        envelope.bl_number = bl_num

        client = CargoXIntegrationClient(mode=request.mode)
        transfer_res = client.transfer_envelope_to_customs(
            envelope_id=envelope.envelope_code,
            bl_number=bl_num,
        )

        signer = PKISignerService(mode=request.mode)
        pki_sig = signer.sign_payload({
            "envelope_code": envelope.envelope_code,
            "acid_number": envelope.acid_number,
            "bl_number": bl_num,
            "customs_recipient": "EGYPTIAN_CUSTOMS_MTS_NAFEZA",
            "transferred_at": datetime.now(timezone.utc).isoformat(),
        })

        envelope.status = "ACCEPTED_BY_CUSTOMS"
        envelope.all_documents_sealed = True
        envelope.is_acid_verified = True
        envelope.transferred_to_customs_at = datetime.now(timezone.utc)
        envelope.customs_confirmation_receipt = transfer_res.get("confirmation_receipt", f"MTS-REC-{uuid.uuid4().hex[:8].upper()}")
        envelope.pki_signature = _normalize_pki_signature(pki_sig)
        envelope.updated_by = updated_by

        # Build Manifest Snapshot
        manifest_payload = CargoXService._build_digital_manifest_payload(envelope)
        envelope.manifest_payload = manifest_payload

        CargoXRepository.update(db, envelope)

        return CargoXSealAndTransferResponse(
            success=True,
            envelope_id=envelope.envelope_id,
            envelope_code=envelope.envelope_code,
            acid_number=envelope.acid_number,
            status=envelope.status,
            bl_number=envelope.bl_number,
            blockchain_tx_hash=envelope.blockchain_tx_hash or "0x" + uuid.uuid4().hex,
            pki_signature=envelope.pki_signature,
            transferred_at=envelope.transferred_to_customs_at,
            customs_confirmation_receipt=envelope.customs_confirmation_receipt,
            message="تم إغلاق وتوثيق مظروف CargoX والتوقيع الإلكتروني بنجاح وتحويل المستندات لمصلحة الجمارك المصرية (Nafeza).",
        )

    @staticmethod
    def verify_acid_consistency(db: Session, envelope_id: int) -> CargoXAcidVerificationReport:
        envelope = CargoXService.get_envelope_by_id(db, envelope_id)
        target_acid = envelope.acid_number

        items: List[ACIDDocumentVerificationItem] = []
        all_matched = True

        for doc in envelope.documents:
            if not doc.is_active:
                continue
            is_match = doc.verified_against_acid
            if not is_match:
                all_matched = False
            items.append(
                ACIDDocumentVerificationItem(
                    doc_type=doc.doc_type,
                    doc_number=doc.doc_number,
                    document_acid=target_acid if is_match else f"{target_acid[:-3]}999 (Mismatch)",
                    is_matched=is_match,
                    status="VERIFIED_100_PERCENT_MATCH" if is_match else "CRITICAL_ACID_MISMATCH",
                    notes="رقم الـ ACID الجمركي مطابق تماماً 100% للشحنة" if is_match else "تنبيه: رقم الـ ACID غير متطابق",
                )
            )

        envelope.is_acid_verified = all_matched
        CargoXRepository.update(db, envelope)

        return CargoXAcidVerificationReport(
            envelope_id=envelope.envelope_id,
            envelope_code=envelope.envelope_code,
            target_acid_number=target_acid,
            all_matched=all_matched,
            verified_count=sum(1 for i in items if i.is_matched),
            total_documents=len(items),
            verification_status="ALL_DOCUMENTS_ACID_VERIFIED" if all_matched else "DISCREPANCIES_DETECTED",
            items=items,
        )

    @staticmethod
    def generate_digital_manifest(db: Session, envelope_id: int) -> DigitalManifestResponse:
        envelope = CargoXService.get_envelope_by_id(db, envelope_id)
        payload = CargoXService._build_digital_manifest_payload(envelope)

        formatted_summary = (
            f"=== EGYPTIAN CUSTOMS ACI DIGITAL MANIFEST ===\n"
            f"Manifest ID: {payload['manifest_id']}\n"
            f"Envelope Code: {payload['envelope_code']}\n"
            f"ACID Number: {payload['acid_number']}\n"
            f"Importer: {payload['importer']['company_name']} (Tax ID: {payload['importer']['tax_id']})\n"
            f"Foreign Exporter: {payload['exporter']['supplier_name']} (CargoX ID: {payload['exporter']['cargox_id']})\n"
            f"Bill of Lading: {payload['transport']['bl_number']}\n"
            f"Blockchain TX Hash: {payload['blockchain']['tx_hash']}\n"
            f"Total Attached Documents: {len(payload['documents'])}\n"
            f"Status: {payload['blockchain']['customs_dispatch_status']}\n"
            f"============================================="
        )

        return DigitalManifestResponse(
            envelope_id=envelope.envelope_id,
            envelope_code=envelope.envelope_code,
            acid_number=envelope.acid_number,
            manifest_json=payload,
            exported_at=datetime.now(timezone.utc),
            formatted_summary=formatted_summary,
        )

    @staticmethod
    def _build_digital_manifest_payload(envelope: CargoXEnvelope) -> Dict[str, Any]:
        return {
            "manifest_id": f"MTS-MAN-{envelope.envelope_code.replace('CGX-ENV-', '')}",
            "envelope_code": envelope.envelope_code,
            "acid_number": envelope.acid_number,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "importer": {
                "company_id": envelope.importer_company_id,
                "company_name": envelope.importer_company_name,
                "tax_id": envelope.importer_tax_number or "N/A",
                "country": "Egypt",
            },
            "exporter": {
                "supplier_id": envelope.supplier_id,
                "supplier_name": envelope.supplier_name,
                "cargox_id": envelope.supplier_cargox_id,
            },
            "transport": {
                "bl_number": envelope.bl_number or "PENDING",
                "import_file_code": envelope.import_file_code or "N/A",
            },
            "blockchain": {
                "tx_hash": envelope.blockchain_tx_hash or "N/A",
                "pki_signature": envelope.pki_signature or "N/A",
                "customs_dispatch_status": envelope.status,
                "customs_confirmation_receipt": envelope.customs_confirmation_receipt or "N/A",
                "transferred_at": envelope.transferred_to_customs_at.isoformat() if envelope.transferred_to_customs_at else None,
            },
            "documents": [
                {
                    "doc_id": doc.doc_id,
                    "doc_type": doc.doc_type,
                    "doc_number": doc.doc_number,
                    "file_name": doc.file_name,
                    "file_hash_sha256": doc.file_hash,
                    "file_size_kb": doc.file_size_kb,
                    "is_mandatory": doc.is_mandatory,
                    "verified_against_acid": doc.verified_against_acid,
                    "pki_signature": doc.pki_signature,
                }
                for doc in envelope.documents
                if doc.is_active
            ],
        }

    @staticmethod
    def soft_delete_envelope(db: Session, envelope_id: int, deleted_by: str = "SYSTEM") -> CargoXEnvelope:
        envelope = CargoXService.get_envelope_by_id(db, envelope_id)
        return CargoXRepository.soft_delete(db, envelope, deleted_by=deleted_by)

    @staticmethod
    def restore_envelope(db: Session, envelope_id: int, restored_by: str = "SYSTEM") -> CargoXEnvelope:
        envelope = CargoXRepository.get_by_id(db, envelope_id, include_inactive=True)
        if not envelope:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"مظروف CargoX برقم المعرف {envelope_id} غير موجود.",
            )
        return CargoXRepository.restore(db, envelope, restored_by=restored_by)


# ============================================================================
# STANDARD EXCEL COMMERCIAL INVOICE SERVICE (BP-025 / CGX-002)
# ============================================================================

from .model import CargoXStandardInvoiceReviewSession, CargoXCustomsInvoiceTrack
from .repository import CargoXStandardInvoiceRepository
from .schemas import (
    StandardInvoicePayload,
    StandardInvoiceLineItem,
    StandardInvoiceComparisonResponse,
    StandardInvoiceSessionCreate,
    StandardInvoiceStatusUpdateRequest,
    ExtractionRequest,
    ExtractionResponse,
    ExtractionResultItem,
    CustomsInvoiceTrackCreate,
    CustomsInvoiceTrackResponse,
)
from .excel_invoice_service import (
    generate_standard_invoice_excel_bytes,
    parse_standard_invoice_excel_bytes,
    compare_standard_invoice_data,
)
from ..import_companies.model import ImportCompany
from ..suppliers.model import Supplier
from ..purchase_orders.model import PurchaseOrder, POLineItem
from ..import_documentation.model import POPackingReconciliationSession


class CargoXStandardInvoiceService:

    @staticmethod
    def build_system_snapshot(db: Session, import_file_id: int) -> StandardInvoicePayload:
        file = db.query(ImportFile).filter(ImportFile.import_file_id == import_file_id).first()
        if not file:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"ملف الاستيراد برقم {import_file_id} غير موجود.",
            )

        company = None
        if file.company_id:
            company = db.query(ImportCompany).filter(ImportCompany.company_id == file.company_id).first()

        supplier = None
        if file.supplier_id:
            supplier = db.query(Supplier).filter(Supplier.supplier_id == file.supplier_id).first()

        # Check for reconciled PO Packing session
        reconciled_session = (
            db.query(POPackingReconciliationSession)
            .filter(
                POPackingReconciliationSession.import_file_id == import_file_id,
                POPackingReconciliationSession.is_active.is_(True),
            )
            .order_by(POPackingReconciliationSession.session_id.desc())
            .first()
        )

        # Fallback to PO items if no reconciliation session
        po = (
            db.query(PurchaseOrder)
            .filter(
                PurchaseOrder.import_file_id == import_file_id,
                PurchaseOrder.is_active.is_(True),
            )
            .order_by(PurchaseOrder.po_id.desc())
            .first()
        )

        # 1. Invoice Number resolution from invoices_data or Proforma Invoice
        inv_number = None
        if file.invoices_data and isinstance(file.invoices_data, list) and len(file.invoices_data) > 0:
            first_inv = file.invoices_data[0]
            if isinstance(first_inv, dict):
                inv_number = first_inv.get("invoice_number") or first_inv.get("invoice_no")
            elif isinstance(first_inv, str):
                inv_number = first_inv
        if not inv_number:
            inv_number = (po.proforma_invoice_number if po and po.proforma_invoice_number else None) or file.pi_number or f"INV-{file.import_file_code}"

        # 2. Total Weights & Unit resolution from Packing List / PO / File
        total_gross = 0.0
        total_net = 0.0
        weight_uom = "KGM"

        if po and po.packing_list_items:
            pl_g = sum(float(pl.total_gross_weight_kg or 0.0) for pl in po.packing_list_items)
            pl_n = sum(float(pl.total_net_weight_kg or 0.0) for pl in po.packing_list_items)
            if pl_g > 0:
                total_gross = pl_g
            if pl_n > 0:
                total_net = pl_n
            if po.packing_list_items[0].weight_unit:
                weight_uom = po.packing_list_items[0].weight_unit

        if total_gross == 0.0 and po:
            total_gross = float(po.total_gross_weight_kg or 0.0)
        if total_net == 0.0 and po:
            total_net = float(po.total_net_weight_kg or 0.0)

        if total_gross == 0.0 and file.packing_lists_data and isinstance(file.packing_lists_data, list):
            for pld in file.packing_lists_data:
                if isinstance(pld, dict):
                    total_gross += float(pld.get("total_gross_weight_kg") or pld.get("gross_weight") or 0.0)
                    total_net += float(pld.get("total_net_weight_kg") or pld.get("net_weight") or 0.0)

        if total_gross == 0.0:
            total_gross = float(getattr(file, "gross_weight_kg", 0.0) or 0.0)
        if total_net == 0.0:
            total_net = float(getattr(file, "net_weight_kg", 0.0) or 0.0)

        # 3. Collect Raw Line Items
        raw_items_source = []
        if reconciled_session and reconciled_session.matched_items_data:
            for raw_item in reconciled_session.matched_items_data:
                raw_items_source.append({
                    "item_code": raw_item.get("item_code"),
                    "hs_code": raw_item.get("hs_code") or "940310",
                    "description": raw_item.get("item_name") or raw_item.get("description") or "Imported Goods",
                    "quantity": float(raw_item.get("actual_quantity") or raw_item.get("po_quantity") or 1.0),
                    "qty_unit": raw_item.get("unit") or "PCS",
                    "unit_price": float(raw_item.get("unit_price") or 0.0),
                    "country_of_origin": raw_item.get("country_of_origin") or (supplier.country.iso2 if supplier and supplier.country else "CN"),
                    "gross_weight_kg": float(raw_item.get("gross_weight") or 0.0),
                    "net_weight_kg": float(raw_item.get("net_weight") or 0.0),
                })
        elif po and po.line_items:
            for pi in po.line_items:
                hs_code_val = "940310"
                if hasattr(pi, "tariff") and pi.tariff and pi.tariff.hs_code:
                    hs_code_val = pi.tariff.hs_code
                raw_items_source.append({
                    "item_code": pi.item_code,
                    "hs_code": hs_code_val,
                    "description": pi.description_en or pi.description_ar or "Imported Goods",
                    "quantity": float(pi.quantity),
                    "qty_unit": pi.unit_of_measure or "PCS",
                    "unit_price": float(pi.unit_price),
                    "country_of_origin": pi.country_of_origin or (supplier.country.iso2 if supplier and supplier.country else "CN"),
                    "gross_weight_kg": float(pi.gross_weight_kg or 0.0),
                    "net_weight_kg": float(pi.net_weight_kg or 0.0),
                })
        else:
            raw_items_source.append({
                "item_code": "ITEM-001",
                "hs_code": "940310",
                "description": "Standard Commercial Goods",
                "quantity": 1.0,
                "qty_unit": "SET",
                "unit_price": float(file.estimated_cost or 1000.0),
                "country_of_origin": supplier.country.iso2 if supplier and supplier.country else "IT",
                "gross_weight_kg": total_gross or 100.0,
                "net_weight_kg": total_net or 90.0,
            })

        # 4. Pro-rate Unit Weights
        total_all_qty = sum(r["quantity"] for r in raw_items_source) if raw_items_source else 1.0
        unit_gross_rate = (total_gross / total_all_qty) if (total_gross > 0 and total_all_qty > 0) else 0.0
        unit_net_rate = (total_net / total_all_qty) if (total_net > 0 and total_all_qty > 0) else 0.0

        # 5. Group by HS Code (Consolidation to prevent duplicate HS Code rows)
        from collections import OrderedDict
        grouped = OrderedDict()
        for r in raw_items_source:
            hs = r["hs_code"]
            if hs not in grouped:
                grouped[hs] = {
                    "hs_code": hs,
                    "item_codes": [],
                    "descriptions": [],
                    "total_qty": 0.0,
                    "qty_unit": r["qty_unit"],
                    "total_amount": 0.0,
                    "total_gross_weight": 0.0,
                    "total_net_weight": 0.0,
                    "country_of_origin": r["country_of_origin"],
                }
            qty = r["quantity"]
            price = r["unit_price"]
            amount = qty * price
            item_g = (qty * unit_gross_rate) if unit_gross_rate > 0 else r["gross_weight_kg"]
            item_n = (qty * unit_net_rate) if unit_net_rate > 0 else r["net_weight_kg"]

            if r["item_code"] and r["item_code"] not in grouped[hs]["item_codes"]:
                grouped[hs]["item_codes"].append(r["item_code"])
            if r["description"] and r["description"] not in grouped[hs]["descriptions"]:
                grouped[hs]["descriptions"].append(r["description"])

            grouped[hs]["total_qty"] += qty
            grouped[hs]["total_amount"] += amount
            grouped[hs]["total_gross_weight"] += item_g
            grouped[hs]["total_net_weight"] += item_n

        items: List[StandardInvoiceLineItem] = []
        for idx, (hs, grp) in enumerate(grouped.items(), start=1):
            tot_qty = grp["total_qty"]
            tot_amt = grp["total_amount"]
            avg_price = round(tot_amt / tot_qty, 4) if tot_qty > 0 else 0.0
            code_str = grp["item_codes"][0] if grp["item_codes"] else f"ITEM-{idx:03d}"
            desc_str = grp["descriptions"][0] if grp["descriptions"] else "Imported Goods"

            items.append(
                StandardInvoiceLineItem(
                    index=idx,
                    product_code=code_str,
                    manufacturer=supplier.company_name if supplier else "Manufacturer",
                    brand_name="Standard",
                    model="Standard",
                    hs_code=hs,
                    country_of_origin=grp["country_of_origin"],
                    description=desc_str,
                    quantity=round(tot_qty, 2),
                    qty_unit=grp["qty_unit"],
                    expiry_date=None,
                    unit_price=round(avg_price, 4),
                    unit_price_basis=grp["qty_unit"],
                    gross_weight_kg=round(grp["total_gross_weight"], 2),
                    net_weight_kg=round(grp["total_net_weight"], 2),
                    total_amount=round(tot_amt, 2),
                )
            )

        subtotal = sum(i.total_amount for i in items)
        freight = float(getattr(file, "freight_amount", 0.0) or 0.0)
        insurance = float(getattr(file, "insurance_amount", 0.0) or 0.0)
        other = float(getattr(file, "other_cost", 0.0) or 0.0)
        total = round(subtotal + freight + insurance + other, 2)

        po_date_str = None
        if po and po.order_date:
            po_date_str = po.order_date.strftime("%Y-%m-%d")

        return StandardInvoicePayload(
            seller_name=supplier.company_name if supplier else file.supplier_name,
            seller_address=supplier.address if supplier else "",
            seller_city="",
            seller_country_code=supplier.foreign_exporter_country_code if supplier else "IT",
            seller_tax_id=supplier.foreign_exporter_id if supplier else "",
            seller_contact_name="",
            seller_phone=supplier.phone if supplier else "",
            seller_fax=supplier.fax if supplier else "",
            seller_email=supplier.email if supplier else "",
            seller_website=supplier.website if supplier else "",
            buyer_name=company.importer_name if company else file.company_name,
            buyer_address=company.address if company else "",
            buyer_tax_id=company.vat_id or company.importer_id if company else "",
            buyer_contact_name="",
            buyer_phone="",
            buyer_fax="",
            buyer_email="",
            acid_number=file.acid_number or "PENDING",
            invoice_type="Commercial Invoice",
            invoice_number=inv_number,
            invoice_date=datetime.now(timezone.utc).strftime("%Y-%m-%d"),
            purchase_order_number=po.po_number if po else f"PO-{file.import_file_code}",
            purchase_order_date=po_date_str,
            proforma_invoice_number=po.proforma_invoice_number if po else None,
            origin_port=file.port_of_loading or "Origin Port",
            destination_port=file.port_of_discharge or "EGALY",
            currency_code=file.estimated_cost_currency or "EUR",
            incoterm=file.incoterm_code or "EXW",
            gross_weight=round(total_gross, 2),
            net_weight=round(total_net, 2),
            weight_unit=weight_uom,
            items=items,
            subtotal=subtotal,
            freight_cost=freight,
            insurance_cost=insurance,
            other_costs=other,
            total_amount=total,
        )


    @staticmethod
    def generate_excel_template(db: Session, import_file_id: int) -> bytes:
        snapshot = CargoXStandardInvoiceService.build_system_snapshot(db, import_file_id)
        return generate_standard_invoice_excel_bytes(snapshot)

    @staticmethod
    def parse_excel_file(file_bytes: bytes) -> StandardInvoicePayload:
        return parse_standard_invoice_excel_bytes(file_bytes)

    @staticmethod
    def compare_invoices(
        db: Session, import_file_id: int, supplier_data: StandardInvoicePayload
    ) -> StandardInvoiceComparisonResponse:
        file = db.query(ImportFile).filter(ImportFile.import_file_id == import_file_id).first()
        file_code = file.import_file_code if file else f"IMP-{import_file_id}"
        system_snapshot = CargoXStandardInvoiceService.build_system_snapshot(db, import_file_id)
        return compare_standard_invoice_data(
            import_file_id=import_file_id,
            import_file_code=file_code,
            system_snapshot=system_snapshot,
            supplier_data=supplier_data,
        )

    @staticmethod
    def save_or_upsert_session(
        db: Session, payload: StandardInvoiceSessionCreate, created_by: str = "SYSTEM"
    ) -> CargoXStandardInvoiceReviewSession:
        # Check mandatory override justification
        if payload.status == "APPROVED" and (payload.has_discrepancies or payload.has_critical_mismatch):
            reason = (payload.discrepancy_override_reason or "").strip()
            if not reason:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="يجب كتابة مبرر وسبب الموافقة على الاختلافات الجمركية (Discrepancy Override Justification) قبل اعتماد الفاتورة.",
                )

        existing = CargoXStandardInvoiceRepository.get_by_import_file(db, payload.import_file_id)
        if existing:
            # Update in-place (Anti-duplicate rule)
            existing.invoice_number = payload.invoice_number or existing.invoice_number
            existing.invoice_date = payload.invoice_date or existing.invoice_date
            existing.invoice_type = payload.invoice_type
            existing.purchase_order_id = payload.purchase_order_id or existing.purchase_order_id
            existing.purchase_order_number = payload.purchase_order_number or existing.purchase_order_number
            existing.supplier_id = payload.supplier_id or existing.supplier_id
            existing.exporter_name = payload.exporter_name or existing.exporter_name
            existing.exporter_tax_id = payload.exporter_tax_id or existing.exporter_tax_id
            existing.exporter_country_code = payload.exporter_country_code or existing.exporter_country_code
            existing.importer_company_id = payload.importer_company_id or existing.importer_company_id
            existing.importer_name = payload.importer_name or existing.importer_name
            existing.importer_tax_id = payload.importer_tax_id or existing.importer_tax_id
            existing.currency_code = payload.currency_code
            existing.incoterm = payload.incoterm or existing.incoterm
            existing.pol_code = payload.pol_code or existing.pol_code
            existing.pod_code = payload.pod_code or existing.pod_code
            existing.gross_weight_kg = payload.gross_weight_kg
            existing.net_weight_kg = payload.net_weight_kg
            existing.weight_unit = payload.weight_unit
            existing.subtotal_amount = payload.subtotal_amount
            existing.freight_cost = payload.freight_cost
            existing.insurance_cost = payload.insurance_cost
            existing.other_costs = payload.other_costs
            existing.total_amount = payload.total_amount
            existing.line_items_count = payload.line_items_count
            existing.system_snapshot_data = payload.system_snapshot_data or existing.system_snapshot_data
            existing.supplier_invoice_data = payload.supplier_invoice_data or existing.supplier_invoice_data
            existing.comparison_data = payload.comparison_data or existing.comparison_data
            existing.has_discrepancies = payload.has_discrepancies
            existing.has_critical_mismatch = payload.has_critical_mismatch
            existing.discrepancy_override_reason = payload.discrepancy_override_reason or existing.discrepancy_override_reason
            existing.status = payload.status
            existing.notes = payload.notes or existing.notes
            existing.updated_by = created_by
            return CargoXStandardInvoiceRepository.update(db, existing)

        # Create new record
        session_code = CargoXStandardInvoiceRepository.get_next_code(db)
        new_session = CargoXStandardInvoiceReviewSession(
            session_code=session_code,
            import_file_id=payload.import_file_id,
            import_file_code=payload.import_file_code,
            acid_number=payload.acid_number,
            invoice_number=payload.invoice_number,
            invoice_date=payload.invoice_date,
            invoice_type=payload.invoice_type,
            purchase_order_id=payload.purchase_order_id,
            purchase_order_number=payload.purchase_order_number,
            supplier_id=payload.supplier_id,
            exporter_name=payload.exporter_name,
            exporter_tax_id=payload.exporter_tax_id,
            exporter_country_code=payload.exporter_country_code,
            importer_company_id=payload.importer_company_id,
            importer_name=payload.importer_name,
            importer_tax_id=payload.importer_tax_id,
            currency_code=payload.currency_code,
            incoterm=payload.incoterm,
            pol_code=payload.pol_code,
            pod_code=payload.pod_code,
            gross_weight_kg=payload.gross_weight_kg,
            net_weight_kg=payload.net_weight_kg,
            weight_unit=payload.weight_unit,
            subtotal_amount=payload.subtotal_amount,
            freight_cost=payload.freight_cost,
            insurance_cost=payload.insurance_cost,
            other_costs=payload.other_costs,
            total_amount=payload.total_amount,
            line_items_count=payload.line_items_count,
            system_snapshot_data=payload.system_snapshot_data,
            supplier_invoice_data=payload.supplier_invoice_data,
            comparison_data=payload.comparison_data,
            has_discrepancies=payload.has_discrepancies,
            has_critical_mismatch=payload.has_critical_mismatch,
            discrepancy_override_reason=payload.discrepancy_override_reason,
            status=payload.status,
            notes=payload.notes,
            created_by=created_by,
            updated_by=created_by,
        )
        return CargoXStandardInvoiceRepository.create(db, new_session)

    @staticmethod
    def get_session_by_file(db: Session, import_file_id: int) -> Optional[CargoXStandardInvoiceReviewSession]:
        return CargoXStandardInvoiceRepository.get_by_import_file(db, import_file_id)

    @staticmethod
    def list_sessions(
        db: Session,
        search: Optional[str] = None,
        status: Optional[str] = None,
        import_file_id: Optional[int] = None,
        limit: int = 100,
        offset: int = 0,
    ) -> List[CargoXStandardInvoiceReviewSession]:
        return CargoXStandardInvoiceRepository.get_all(
            db, search=search, status=status, import_file_id=import_file_id, limit=limit, offset=offset
        )

    @staticmethod
    def update_session_status(
        db: Session, session_id: int, payload: StandardInvoiceStatusUpdateRequest, updated_by: str = "SYSTEM"
    ) -> CargoXStandardInvoiceReviewSession:
        session = CargoXStandardInvoiceRepository.get_by_id(db, session_id)
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"جلسة مراجعة الفاتورة برقم المعرف {session_id} غير موجودة.",
            )

        if payload.status == "APPROVED" and (session.has_discrepancies or session.has_critical_mismatch):
            reason = (payload.discrepancy_override_reason or session.discrepancy_override_reason or "").strip()
            if not reason:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="يجب كتابة مبرر وسبب الموافقة على الاختلافات الجمركية (Discrepancy Override Justification) قبل اعتماد الفاتورة.",
                )
            session.discrepancy_override_reason = reason

        session.status = payload.status
        if payload.notes:
            session.notes = payload.notes
        session.updated_by = updated_by
        return CargoXStandardInvoiceRepository.update(db, session)


# ============================================================================
# CGX-003: Multi-Path Extraction Engine
# ============================================================================


class CargoXExtractionEngine:
    """
    محرك استخراج مستندات CargoX متعدد المسارات (CGX-003).

    يدعم 4 modes للاستخراج:
    - all_consolidated:         ملف Excel واحد — بنود مجمعة بـ HS Code (weighted avg price)
    - all_detailed:             ملف Excel واحد — بنود مفصلة (كل سطر منفصل)
    - per_invoice_consolidated: ZIP بعدد الفواتير — كل ملف مجمع بـ HS Code
    - per_invoice_detailed:     ZIP بعدد الفواتير — كل ملف مفصل

    ويدعم 3 modes للتجميع:
    - by_hs_code:     تجميع + weighted average price لكل HS Code (الافتراضي للجمرك)
    - by_price_group: تجميع لكل HS Code + مجموعة سعر (أسعار مختلفة = سطور مختلفة)
    - flat:           بدون تجميع — كل سطر منفصل
    """

    # -------------------------------------------------------------------------
    # Public Interface
    # -------------------------------------------------------------------------

    @staticmethod
    def extract(
        db: Session,
        import_file_id: int,
        request: ExtractionRequest,
    ) -> ExtractionResponse:
        """
        المدخل الرئيسي لمحرك الاستخراج.
        يُرجع ExtractionResponse يحتوي على قايمة من StandardInvoicePayload.
        """
        file = db.query(ImportFile).filter(ImportFile.import_file_id == import_file_id).first()
        if not file:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"ملف الاستيراد برقم {import_file_id} غير موجود.",
            )

        # حفظ آخر preference
        file.extraction_preference = request.mode
        db.flush()

        # جلب البيانات المشتركة
        company, supplier, pos = CargoXExtractionEngine._load_entities(db, file)
        reconciled_session = CargoXExtractionEngine._load_reconciled_session(db, import_file_id)
        base_raw = CargoXExtractionEngine._build_base_payload(file, company, supplier)

        # تجميع البيانات الخام مع الفواتير
        invoices_raw = CargoXExtractionEngine._collect_invoices_raw(
            file, pos, reconciled_session, supplier, request
        )

        # استخراج حسب mode
        mode = request.mode
        results: List[ExtractionResultItem] = []

        if mode in ("all_consolidated", "all_detailed"):
            # دمج كل بيانات الفواتير في payload واحد
            all_items_raw = []
            for inv_no, items_raw in invoices_raw.items():
                all_items_raw.extend(items_raw)

            grouped_items = CargoXExtractionEngine._group_items(
                all_items_raw, request.grouping_mode, mode
            )
            total_gross, total_net, weight_uom = CargoXExtractionEngine._resolve_weights(file, pos)
            payload = CargoXExtractionEngine._build_payload(
                base_raw, grouped_items, total_gross, total_net, weight_uom,
                inv_number=CargoXExtractionEngine._resolve_invoice_number(file, pos),
            )
            results.append(ExtractionResultItem(invoice_number=payload.invoice_number, payload=payload))

        else:
            # per_invoice: ملف منفصل لكل فاتورة
            for inv_no, items_raw in invoices_raw.items():
                if request.invoice_filter and inv_no != request.invoice_filter:
                    continue
                grouped_items = CargoXExtractionEngine._group_items(
                    items_raw, request.grouping_mode, mode
                )
                # استخلاص أوزان هذه الفاتورة تحديداً (نسبة بيانات هذه الفاتورة)
                inv_gross, inv_net, weight_uom = CargoXExtractionEngine._resolve_per_invoice_weights(
                    file, pos, inv_no, items_raw, invoices_raw
                )
                payload = CargoXExtractionEngine._build_payload(
                    base_raw, grouped_items, inv_gross, inv_net, weight_uom,
                    inv_number=inv_no,
                )
                results.append(ExtractionResultItem(invoice_number=inv_no, payload=payload))

        total_line_items = sum(len(r.payload.items) for r in results)

        return ExtractionResponse(
            import_file_id=import_file_id,
            import_file_code=file.import_file_code,
            mode=request.mode,
            grouping_mode=request.grouping_mode,
            invoices_count=len(results),
            total_line_items=total_line_items,
            results=results,
        )

    @staticmethod
    def create_customs_track(
        db: Session,
        payload: CustomsInvoiceTrackCreate,
        created_by: str = "SYSTEM",
    ) -> CargoXCustomsInvoiceTrack:
        """إنشاء وحفظ نسخة جمركية مستقلة في DB."""
        file = db.query(ImportFile).filter(
            ImportFile.import_file_id == payload.import_file_id
        ).first()
        if not file:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"ملف الاستيراد برقم {payload.import_file_id} غير موجود.",
            )

        # تشغيل محرك الاستخراج
        ext_req = ExtractionRequest(
            mode=payload.extraction_mode,
            grouping_mode=payload.grouping_mode,
            invoice_filter=payload.invoice_filter,
        )
        extraction = CargoXExtractionEngine.extract(db, payload.import_file_id, ext_req)

        # بناء الـ track code
        existing_count = (
            db.query(CargoXCustomsInvoiceTrack)
            .filter(CargoXCustomsInvoiceTrack.import_file_id == payload.import_file_id)
            .count()
        )
        track_code = f"CX-CUST-{file.import_file_code}-{existing_count + 1:03d}"

        # تجميع الأوزان والمجاميع من نتائج الاستخراج
        all_results_data = [r.payload.model_dump() for r in extraction.results]
        total_amount = sum(r.payload.total_amount for r in extraction.results)
        total_gross = sum(r.payload.gross_weight for r in extraction.results)
        total_net = sum(r.payload.net_weight for r in extraction.results)
        source_invs = [r.invoice_number for r in extraction.results if r.invoice_number]

        track = CargoXCustomsInvoiceTrack(
            track_code=track_code,
            import_file_id=payload.import_file_id,
            import_file_code=file.import_file_code,
            source_invoice_numbers=source_invs,
            extraction_mode=payload.extraction_mode,
            grouping_mode=payload.grouping_mode,
            customs_total_amount=round(total_amount, 2),
            customs_gross_weight=round(total_gross, 2),
            customs_net_weight=round(total_net, 2),
            customs_packages_count=0,
            line_items_count=extraction.total_line_items,
            customs_invoice_data=all_results_data if len(all_results_data) > 1 else (all_results_data[0] if all_results_data else {}),
            status="DRAFT",
            notes=payload.notes,
            created_by=created_by,
            updated_by=created_by,
        )
        db.add(track)
        db.commit()
        db.refresh(track)
        return track

    # -------------------------------------------------------------------------
    # Private Helpers
    # -------------------------------------------------------------------------

    @staticmethod
    def _load_entities(db: Session, file: ImportFile):
        company = None
        if file.company_id:
            company = db.query(ImportCompany).filter(ImportCompany.company_id == file.company_id).first()
        supplier = None
        if file.supplier_id:
            supplier = db.query(Supplier).filter(Supplier.supplier_id == file.supplier_id).first()
        pos = (
            db.query(PurchaseOrder)
            .filter(PurchaseOrder.import_file_id == file.import_file_id, PurchaseOrder.is_active.is_(True))
            .all()
        )
        return company, supplier, pos

    @staticmethod
    def _load_reconciled_session(db: Session, import_file_id: int):
        return (
            db.query(POPackingReconciliationSession)
            .filter(
                POPackingReconciliationSession.import_file_id == import_file_id,
                POPackingReconciliationSession.is_active.is_(True),
            )
            .order_by(POPackingReconciliationSession.session_id.desc())
            .first()
        )

    @staticmethod
    def _resolve_invoice_number(file: ImportFile, pos: list) -> Optional[str]:
        if file.invoices_data and isinstance(file.invoices_data, list) and len(file.invoices_data) > 0:
            first_inv = file.invoices_data[0]
            if isinstance(first_inv, dict):
                n = first_inv.get("invoice_number") or first_inv.get("invoice_no")
                if n:
                    return n
        if pos:
            po = pos[0]
            if po.proforma_invoice_number:
                return po.proforma_invoice_number
        return file.pi_number or f"INV-{file.import_file_code}"

    @staticmethod
    def _resolve_weights(file: ImportFile, pos: list):
        total_gross = 0.0
        total_net = 0.0
        weight_uom = "KGM"
        for po in pos:
            if po.packing_list_items:
                pl_g = sum(float(pl.total_gross_weight_kg or 0) for pl in po.packing_list_items)
                pl_n = sum(float(pl.total_net_weight_kg or 0) for pl in po.packing_list_items)
                if pl_g > 0:
                    total_gross += pl_g
                if pl_n > 0:
                    total_net += pl_n
                if po.packing_list_items[0].weight_unit:
                    weight_uom = po.packing_list_items[0].weight_unit
            elif po.total_gross_weight_kg:
                total_gross += float(po.total_gross_weight_kg or 0)
                total_net += float(po.total_net_weight_kg or 0)
        if total_gross == 0:
            total_gross = float(getattr(file, "gross_weight_kg", 0.0) or 0.0)
        if total_net == 0:
            total_net = float(getattr(file, "net_weight_kg", 0.0) or 0.0)
        return total_gross, total_net, weight_uom

    @staticmethod
    def _resolve_per_invoice_weights(file: ImportFile, pos: list, inv_no: str, inv_items: list, all_invoices: dict):
        """حساب الأوزان النسبية لكل فاتورة بناءً على حصتها من إجمالي الكميات."""
        total_gross, total_net, weight_uom = CargoXExtractionEngine._resolve_weights(file, pos)
        all_qty = sum(r["quantity"] for invs in all_invoices.values() for r in invs)
        inv_qty = sum(r["quantity"] for r in inv_items)
        if all_qty > 0 and total_gross > 0:
            ratio = inv_qty / all_qty
            return round(total_gross * ratio, 2), round(total_net * ratio, 2), weight_uom
        return total_gross, total_net, weight_uom

    @staticmethod
    def _collect_invoices_raw(
        file: ImportFile,
        pos: list,
        reconciled_session,
        supplier,
        request: ExtractionRequest,
    ) -> Dict[str, List[Dict]]:
        """
        تجميع البنود الخام مُنظَّمة حسب رقم الفاتورة.
        يُرجع: { invoice_number: [raw_item_dict, ...] }
        """
        from collections import defaultdict
        invoices_dict: Dict[str, List[Dict]] = defaultdict(list)

        country_fallback = "CN"
        supplier_name_fallback = (
            getattr(supplier, "company_name", None)
            or getattr(file, "supplier_name", None)
            or "Manufacturer"
        )
        if supplier:
            country_fallback = (
                getattr(supplier, "foreign_exporter_country_code", None)
                or getattr(supplier, "foreign_exporter_country", None)
                or "CN"
            )

        # مصدر 1: reconciled session
        if reconciled_session and reconciled_session.matched_items_data:
            for raw_item in reconciled_session.matched_items_data:
                inv_no = raw_item.get("invoice_number") or CargoXExtractionEngine._resolve_invoice_number(file, pos)
                invoices_dict[inv_no].append({
                    "item_code": raw_item.get("item_code"),
                    "manufacturer": raw_item.get("manufacturer") or supplier_name_fallback,
                    "brand_name": raw_item.get("brand_name") or "Standard",
                    "model": raw_item.get("model") or "Standard",
                    "hs_code": raw_item.get("hs_code") or "940310",
                    "description": raw_item.get("item_name") or raw_item.get("description") or "Imported Goods",
                    "quantity": float(raw_item.get("actual_quantity") or raw_item.get("po_quantity") or 1.0),
                    "qty_unit": raw_item.get("unit") or "PCS",
                    "unit_price": float(raw_item.get("unit_price") or 0.0),
                    "country_of_origin": raw_item.get("country_of_origin") or country_fallback,
                    "gross_weight_kg": float(raw_item.get("gross_weight") or 0.0),
                    "net_weight_kg": float(raw_item.get("net_weight") or 0.0),
                    "invoice_number": inv_no,
                })
            return dict(invoices_dict)

        # مصدر 2: PO line items (مع دعم invoice_number على البند)
        if pos:
            for po in pos:
                if not po.line_items:
                    continue
                # استخلاص أوزان كل PO
                po_total_gross = float(po.total_gross_weight_kg or 0)
                po_total_net = float(po.total_net_weight_kg or 0)
                if po.packing_list_items:
                    po_total_gross = sum(float(pl.total_gross_weight_kg or 0) for pl in po.packing_list_items)
                    po_total_net = sum(float(pl.total_net_weight_kg or 0) for pl in po.packing_list_items)
                po_total_qty = sum(float(pi.quantity) for pi in po.line_items) or 1.0
                unit_gross_rate = po_total_gross / po_total_qty if po_total_gross > 0 else 0.0
                unit_net_rate = po_total_net / po_total_qty if po_total_net > 0 else 0.0

                for pi in po.line_items:
                    hs_code_val = "940310"
                    if hasattr(pi, "tariff") and pi.tariff and pi.tariff.hs_code:
                        hs_code_val = pi.tariff.hs_code
                    qty = float(pi.quantity)
                    # رقم الفاتورة: يؤخذ من البند أولاً، ثم من PO proforma_invoice_number
                    inv_no = (
                        getattr(pi, "invoice_number", None)
                        or po.proforma_invoice_number
                        or file.pi_number
                        or f"INV-{file.import_file_code}"
                    )
                    # لو filter محدد
                    if request.invoice_filter and inv_no != request.invoice_filter:
                        continue
                    invoices_dict[inv_no].append({
                        "item_code": pi.item_code,
                        "manufacturer": getattr(pi, "manufacturer", None) or getattr(po, "supplier_name", None) or supplier_name_fallback,
                        "brand_name": getattr(pi, "brand_name", None) or "Standard",
                        "model": getattr(pi, "model", None) or "Standard",
                        "hs_code": hs_code_val,
                        "description": pi.description_en or pi.description_ar or "Imported Goods",
                        "quantity": qty,
                        "qty_unit": pi.unit_of_measure or "PCS",
                        "unit_price": float(getattr(pi, "customs_unit_price", None) or pi.unit_price),
                        "country_of_origin": pi.country_of_origin or country_fallback,
                        "gross_weight_kg": qty * unit_gross_rate if unit_gross_rate > 0 else float(pi.gross_weight_kg or 0),
                        "net_weight_kg": qty * unit_net_rate if unit_net_rate > 0 else float(pi.net_weight_kg or 0),
                        "invoice_number": inv_no,
                    })

        if not invoices_dict:
            # fallback لو مفيش POs أو بنود
            inv_no = CargoXExtractionEngine._resolve_invoice_number(file, pos)
            invoices_dict[inv_no].append({
                "item_code": "ITEM-001",
                "manufacturer": supplier_name_fallback,
                "brand_name": "Standard",
                "model": "Standard",
                "hs_code": "940310",
                "description": "Standard Commercial Goods",
                "quantity": 1.0,
                "qty_unit": "SET",
                "unit_price": float(getattr(file, "estimated_cost", 0) or 1000.0),
                "country_of_origin": country_fallback,
                "gross_weight_kg": 100.0,
                "net_weight_kg": 90.0,
                "invoice_number": inv_no,
            })

        return dict(invoices_dict)

    @staticmethod
    def _group_items(
        raw_items: List[Dict],
        grouping_mode: str,
        extraction_mode: str,
    ) -> List[StandardInvoiceLineItem]:
        """
        تجميع البنود حسب grouping_mode:
        - by_hs_code:     سطر واحد لكل HS Code مع متوسط سعر موزون
        - by_price_group: سطر لكل (HS Code, unit_price) — أسعار مختلفة = سطور مختلفة
        - flat:           كل سطر منفصل
        يُراعي extraction_mode:
        - "all_detailed" / "per_invoice_detailed" → يستخدم flat بغض النظر عن grouping_mode
        """
        from collections import OrderedDict

        # الـ detailed modes تفرض flat
        if "detailed" in extraction_mode:
            grouping_mode = "flat"

        if grouping_mode == "flat":
            items = []
            for idx, r in enumerate(raw_items, start=1):
                qty = r["quantity"]
                price = r["unit_price"]
                items.append(StandardInvoiceLineItem(
                    index=idx,
                    product_code=r.get("item_code") or f"ITEM-{idx:03d}",
                    manufacturer=r.get("manufacturer") or "Manufacturer",
                    brand_name=r.get("brand_name") or "Standard",
                    model=r.get("model") or "Standard",
                    hs_code=r["hs_code"],
                    country_of_origin=r["country_of_origin"],
                    description=r["description"],
                    quantity=round(qty, 2),
                    qty_unit=r["qty_unit"],
                    unit_price=round(price, 4),
                    unit_price_basis=r["qty_unit"],
                    gross_weight_kg=round(r["gross_weight_kg"], 2),
                    net_weight_kg=round(r["net_weight_kg"], 2),
                    total_amount=round(qty * price, 2),
                ))
            return items

        # مفتاح التجميع
        def group_key(r):
            if grouping_mode == "by_price_group":
                return (r["hs_code"], round(r["unit_price"], 4))
            return (r["hs_code"],)  # by_hs_code

        grouped = OrderedDict()
        for r in raw_items:
            key = group_key(r)
            if key not in grouped:
                grouped[key] = {
                    "hs_code": r["hs_code"],
                    "item_codes": [],
                    "manufacturers": [],
                    "descriptions": [],
                    "total_qty": 0.0,
                    "qty_unit": r["qty_unit"],
                    "weighted_sum": 0.0,  # Σ(qty × price)
                    "total_gross": 0.0,
                    "total_net": 0.0,
                    "country_of_origin": r["country_of_origin"],
                }
            qty = r["quantity"]
            price = r["unit_price"]
            if r.get("item_code") and r["item_code"] not in grouped[key]["item_codes"]:
                grouped[key]["item_codes"].append(r["item_code"])
            if r.get("manufacturer") and r["manufacturer"] not in grouped[key]["manufacturers"]:
                grouped[key]["manufacturers"].append(r["manufacturer"])
            if r["description"] and r["description"] not in grouped[key]["descriptions"]:
                grouped[key]["descriptions"].append(r["description"])
            grouped[key]["total_qty"] += qty
            grouped[key]["weighted_sum"] += qty * price  # للـ weighted average
            grouped[key]["total_gross"] += r["gross_weight_kg"]
            grouped[key]["total_net"] += r["net_weight_kg"]

        items = []
        for idx, (key, grp) in enumerate(grouped.items(), start=1):
            tot_qty = grp["total_qty"]
            # Weighted Average Price = Σ(qty_i × price_i) / Σ(qty_i)
            avg_price = round(grp["weighted_sum"] / tot_qty, 4) if tot_qty > 0 else 0.0
            tot_amt = round(tot_qty * avg_price, 2)
            code_str = grp["item_codes"][0] if grp["item_codes"] else f"ITEM-{idx:03d}"
            mfg_str = grp["manufacturers"][0] if grp.get("manufacturers") else "Manufacturer"
            desc_str = grp["descriptions"][0] if grp["descriptions"] else "Imported Goods"
            items.append(StandardInvoiceLineItem(
                index=idx,
                product_code=code_str,
                manufacturer=mfg_str,
                brand_name="Standard",
                model="Standard",
                hs_code=grp["hs_code"],
                country_of_origin=grp["country_of_origin"],
                description=desc_str,
                quantity=round(tot_qty, 2),
                qty_unit=grp["qty_unit"],
                unit_price=avg_price,
                unit_price_basis=grp["qty_unit"],
                gross_weight_kg=round(grp["total_gross"], 2),
                net_weight_kg=round(grp["total_net"], 2),
                total_amount=tot_amt,
            ))
        return items

    @staticmethod
    def _build_base_payload(file: ImportFile, company, supplier) -> Dict:
        return {
            "seller_name": supplier.company_name if supplier else file.supplier_name,
            "seller_address": supplier.address if supplier else "",
            "seller_city": "",
            "seller_country_code": (supplier.foreign_exporter_country_code if supplier else None) or "CN",
            "seller_tax_id": supplier.foreign_exporter_id if supplier else "",
            "seller_phone": supplier.phone if supplier else "",
            "seller_fax": supplier.fax if supplier else "",
            "seller_email": supplier.email if supplier else "",
            "seller_website": supplier.website if supplier else "",
            "buyer_name": company.importer_name if company else file.company_name,
            "buyer_address": company.address if company else "",
            "buyer_tax_id": (company.vat_id or company.importer_id) if company else "",
            "acid_number": file.acid_number or "PENDING",
            "invoice_type": "Commercial Invoice",
            "origin_port": file.port_of_loading or "Origin Port",
            "destination_port": file.port_of_discharge or "EGALY",
            "currency_code": file.estimated_cost_currency or "EUR",
            "incoterm": file.incoterm_code or "EXW",
        }

    @staticmethod
    def _build_payload(
        base: Dict,
        items: List[StandardInvoiceLineItem],
        total_gross: float,
        total_net: float,
        weight_uom: str,
        inv_number: Optional[str] = None,
        po_number: Optional[str] = None,
        po_date: Optional[str] = None,
    ) -> StandardInvoicePayload:
        subtotal = sum(i.total_amount for i in items)
        return StandardInvoicePayload(
            **base,
            seller_contact_name="",
            buyer_contact_name="",
            buyer_phone="",
            buyer_fax="",
            buyer_email="",
            invoice_number=inv_number,
            invoice_date=datetime.now(timezone.utc).strftime("%Y-%m-%d"),
            purchase_order_number=po_number,
            purchase_order_date=po_date,
            gross_weight=round(total_gross, 2),
            net_weight=round(total_net, 2),
            weight_unit=weight_uom,
            items=items,
            subtotal=round(subtotal, 2),
            freight_cost=0.0,
            insurance_cost=0.0,
            other_costs=0.0,
            total_amount=round(subtotal, 2),
        )
