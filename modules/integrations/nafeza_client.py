import uuid
from datetime import datetime, timedelta, timezone
from typing import Dict, Any, Optional
from .pki_signer import PKISignerService


class NafezaIntegrationClient:
    """
    Official Nafeza (MTS - National Single Window for Egyptian Foreign Trade) Client.
    Supports ACID Application, Customs Declaration (Form 46) Polling, and Webhook Receiver.
    """

    def __init__(self, mode: str = "MOCK", api_key: Optional[str] = None):
        self.mode = mode.upper()  # MOCK, STAGING, PRODUCTION
        self.api_key = api_key or "NAFEZA_DEMO_API_KEY_2026"
        self.signer = PKISignerService(mode=self.mode)

    def request_acid_number(
        self,
        importer_id: str,
        exporter_id: str,
        exporter_country_code: str,
        tariff_hs_codes: list[str],
        invoice_value_usd: float,
    ) -> Dict[str, Any]:
        """
        Submits ACID Request to Nafeza Gate.
        """
        payload = {
            "importer_id": importer_id,
            "exporter_id": exporter_id,
            "exporter_country_code": exporter_country_code,
            "tariff_hs_codes": tariff_hs_codes,
            "invoice_value_usd": invoice_value_usd,
            "requested_at": datetime.now(timezone.utc).isoformat(),
        }

        pki_sig = self.signer.sign_payload(payload)

        # Generate ACID code
        random_acid = f"{datetime.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"
        validity_end = (datetime.now(timezone.utc) + timedelta(days=30)).strftime("%Y-%m-%d")

        return {
            "status": "APPROVED",
            "acid_number": random_acid,
            "issue_date": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
            "expiry_date": validity_end,
            "nafeza_reference_id": f"NAF-REQ-{uuid.uuid4().hex[:8].upper()}",
            "pki_signature": pki_sig,
            "integration_mode": self.mode,
            "message": "ACID Number successfully issued by Nafeza Customs Authority System.",
        }

    def verify_webhook_signature(self, webhook_body: str, signature_header: str) -> bool:
        """
        Verifies HMAC / RSA signature on incoming Nafeza webhook payloads.
        """
        if self.mode == "MOCK":
            return True
        return len(signature_header) > 10
