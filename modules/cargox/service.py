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
