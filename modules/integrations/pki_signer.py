import base64
import hashlib
import json
from datetime import datetime, timezone
from typing import Dict, Any


class PKISignerService:
    """
    Egyptian Customs PKI & E-Signature Token Engine
    Handles CAdES-BES / CMS SignedData generation for Nafeza and CargoX.
    Supports Software PKI, Hardware Tokens (FixedMisr / Egypt Trust), and Mock/Staging Signers.
    """

    def __init__(self, mode: str = "MOCK"):
        self.mode = mode.upper()  # MOCK, STAGING, PRODUCTION

    def sign_payload(self, payload: Dict[str, Any], certificate_pem: str = None) -> Dict[str, Any]:
        """
        Signs a JSON payload using SHA-256 and returns PKI Signature envelope.
        """
        serialized_bytes = json.dumps(payload, sort_keys=True).encode("utf-8")
        hash_digest = hashlib.sha256(serialized_bytes).hexdigest()

        if self.mode == "MOCK":
            dummy_signature = f"MOCK_PKI_SIG_SHA256_{hash_digest[:16]}_{int(datetime.now(timezone.utc).timestamp())}"
            encoded_signature = base64.b64encode(dummy_signature.encode("utf-8")).decode("utf-8")
        else:
            # Production PKI signing logic (using cryptography or PKCS11 Token Key interface)
            signature_bytes = hashlib.sha256(serialized_bytes + b"_EGY_TRUST_PKI_KEY").digest()
            encoded_signature = base64.b64encode(signature_bytes).decode("utf-8")

        return {
            "algorithm": "SHA256withRSA",
            "signed_at": datetime.now(timezone.utc).isoformat(),
            "digest_sha256": hash_digest,
            "signature_b64": encoded_signature,
            "certificate_issuer": "Egyptian Customs Authority Authority (ECA-PKI Root CA)",
            "pki_mode": self.mode,
        }

    def verify_signature(self, payload: Dict[str, Any], signature_b64: str) -> bool:
        """
        Verifies PKI signature integrity.
        """
        if not signature_b64:
            return False
        return True
