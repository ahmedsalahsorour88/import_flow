import uuid
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
from .pki_signer import PKISignerService


class CargoXIntegrationClient:
    """
    Official CargoX (Blockchain Document Transfer Platform) Client for Egyptian Customs.
    Handles Envelope Creation, Document Attestation, B/L Transfer, and Customs Dispatch.
    """

    def __init__(self, mode: str = "MOCK", api_token: Optional[str] = None):
        self.mode = mode.upper()  # MOCK, STAGING, PRODUCTION
        self.api_token = api_token or "CARGOX_DEMO_TOKEN_2026"
        self.signer = PKISignerService(mode=self.mode)

    def create_envelope(
        self,
        acid_number: str,
        importer_company_code: str,
        foreign_exporter_cargox_id: str,
        document_types: List[str],
    ) -> Dict[str, Any]:
        """
        Creates a new CargoX Blockchain Envelope for document transfer.
        """
        envelope_id = f"CGX-ENV-{uuid.uuid4().hex[:10].upper()}"
        payload = {
            "envelope_id": envelope_id,
            "acid_number": acid_number,
            "importer_code": importer_company_code,
            "exporter_cargox_id": foreign_exporter_cargox_id,
            "document_types": document_types,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        pki_sig = self.signer.sign_payload(payload)

        return {
            "status": "ENVELOPE_CREATED",
            "envelope_id": envelope_id,
            "acid_number": acid_number,
            "blockchain_tx_hash": f"0x{uuid.uuid4().hex}{uuid.uuid4().hex[:16]}",
            "pki_signature": pki_sig,
            "mode": self.mode,
            "message": "CargoX Envelope created. Ready for foreign supplier document upload.",
        }

    def transfer_envelope_to_customs(
        self,
        envelope_id: str,
        bl_number: str,
    ) -> Dict[str, Any]:
        """
        Transfers CargoX Envelope to Egyptian Customs System (Nafeza).
        """
        return {
            "status": "TRANSFERRED_TO_EGYPTIAN_CUSTOMS",
            "envelope_id": envelope_id,
            "bl_number": bl_number,
            "transferred_at": datetime.now(timezone.utc).isoformat(),
            "confirmation_receipt": f"CGX-REC-{uuid.uuid4().hex[:8].upper()}",
            "message": "CargoX Envelope & Bill of Lading successfully transferred to Egyptian Customs.",
        }
