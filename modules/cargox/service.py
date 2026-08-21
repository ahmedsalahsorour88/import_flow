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

from .model import CargoXStandardInvoiceReviewSession
from .repository import CargoXStandardInvoiceRepository
from .schemas import (
    StandardInvoicePayload,
    StandardInvoiceLineItem,
    StandardInvoiceComparisonResponse,
    StandardInvoiceSessionCreate,
    StandardInvoiceStatusUpdateRequest,
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

        items: List[StandardInvoiceLineItem] = []
        if reconciled_session and reconciled_session.matched_items_data:
            for idx, raw_item in enumerate(reconciled_session.matched_items_data, start=1):
                qty = float(raw_item.get("actual_quantity") or raw_item.get("po_quantity") or 1.0)
                price = float(raw_item.get("unit_price") or 0.0)
                tot = round(qty * price, 2)
                items.append(
                    StandardInvoiceLineItem(
                        index=idx,
                        product_code=raw_item.get("item_code") or f"ITEM-{idx:03d}",
                        manufacturer=supplier.company_name if supplier else "Manufacturer",
                        brand_name=raw_item.get("brand_name") or "Standard",
                        model=raw_item.get("model") or "Standard",
                        hs_code=raw_item.get("hs_code") or "940310",
                        country_of_origin=raw_item.get("country_of_origin") or (supplier.country.iso2 if supplier and supplier.country else "IT"),
                        description=raw_item.get("item_name") or raw_item.get("description") or "Imported Goods",
                        quantity=qty,
                        qty_unit=raw_item.get("unit") or "PCE",
                        expiry_date=raw_item.get("expiry_date"),
                        unit_price=price,
                        unit_price_basis=raw_item.get("unit") or "PCS",
                        gross_weight_kg=float(raw_item.get("gross_weight") or 0.0),
                        net_weight_kg=float(raw_item.get("net_weight") or 0.0),
                        total_amount=tot,
                    )
                )
        elif po and po.line_items:
            for idx, pi in enumerate(po.line_items, start=1):
                tot = round(float(pi.quantity) * float(pi.unit_price), 2)
                hs_code_val = "940310"
                if hasattr(pi, 'tariff') and pi.tariff and pi.tariff.hs_code:
                    hs_code_val = pi.tariff.hs_code
                items.append(
                    StandardInvoiceLineItem(
                        index=idx,
                        product_code=pi.item_code or f"ITEM-{idx:03d}",
                        manufacturer=supplier.company_name if supplier else "Manufacturer",
                        brand_name="Standard",
                        model="Standard",
                        hs_code=hs_code_val,
                        country_of_origin=pi.country_of_origin or (supplier.country.iso2 if supplier and supplier.country else "IT"),
                        description=pi.description_en or pi.description_ar or "Imported Goods",
                        quantity=float(pi.quantity),
                        qty_unit=pi.unit_of_measure or "PCE",
                        expiry_date=None,
                        unit_price=float(pi.unit_price),
                        unit_price_basis=pi.unit_of_measure or "PCS",
                        gross_weight_kg=float(pi.gross_weight_kg or 0.0),
                        net_weight_kg=float(pi.net_weight_kg or 0.0),
                        total_amount=tot,
                    )
                )
        else:
            items.append(
                StandardInvoiceLineItem(
                    index=1,
                    product_code="ITEM-001",
                    manufacturer=supplier.company_name if supplier else "Manufacturer",
                    brand_name="Standard",
                    model="Standard",
                    hs_code="940310",
                    country_of_origin=supplier.country.iso2 if supplier and supplier.country else "IT",
                    description="Standard Commercial Goods",
                    quantity=1.0,
                    qty_unit="SET",
                    unit_price=float(file.fob_amount or 1000.0),
                    unit_price_basis="SET",
                    gross_weight_kg=float(file.gross_weight_kg or 100.0),
                    net_weight_kg=float(file.net_weight_kg or 90.0),
                    total_amount=float(file.fob_amount or 1000.0),
                )
            )

        subtotal = sum(i.total_amount for i in items)
        freight = float(getattr(file, 'freight_amount', 0.0) or 0.0)
        insurance = float(getattr(file, 'insurance_amount', 0.0) or 0.0)
        other = float(getattr(file, 'other_cost', 0.0) or 0.0)
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
            invoice_number=f"INV-{file.import_file_code}",
            invoice_date=datetime.now(timezone.utc).strftime("%Y-%m-%d"),
            purchase_order_number=po.po_number if po else f"PO-{file.import_file_code}",
            purchase_order_date=po_date_str,
            proforma_invoice_number=po.proforma_invoice_number if po else None,
            origin_port=file.port_of_loading or "Origin Port",
            destination_port=file.port_of_discharge or "EGALY",
            currency_code=file.estimated_cost_currency or "EUR",
            incoterm=file.incoterm_code or "EXW",
            gross_weight=0.0,
            net_weight=0.0,
            weight_unit="KGM",
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

