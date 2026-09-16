import base64
import hashlib
import hmac
import json
import secrets
import time
from typing import Optional

from settings import SECRET_KEY


def hash_password(password: str) -> str:
    """
    Hashes password using PBKDF2-HMAC-SHA256 with 600,000 iterations and random salt.
    Format: pbkdf2_sha256$<iterations>$<salt_hex>$<hash_hex>
    """
    salt = secrets.token_hex(16)
    iterations = 600_000
    derived = hashlib.pbkdf2_hmac(
        'sha256',
        password.encode('utf-8'),
        salt.encode('utf-8'),
        iterations
    ).hex()
    return f"pbkdf2_sha256${iterations}${salt}${derived}"


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verifies a plain password against a stored hash.
    Supports modern PBKDF2 and seamlessly verifies legacy SHA-256 hashes.
    """
    if not hashed_password:
        return False

    if hashed_password.startswith("pbkdf2_sha256$"):
        parts = hashed_password.split("$")
        if len(parts) == 4:
            try:
                iterations = int(parts[1])
                salt = parts[2]
                stored_hash = parts[3]
                computed = hashlib.pbkdf2_hmac(
                    'sha256',
                    plain_password.encode('utf-8'),
                    salt.encode('utf-8'),
                    iterations
                ).hex()
                return hmac.compare_digest(computed, stored_hash)
            except Exception:
                return False

    # Legacy SHA-256 fallback (importflow_salt_v1)
    legacy_salt = "importflow_salt_v1"
    legacy_hash = hashlib.sha256((plain_password + legacy_salt).encode('utf-8')).hexdigest()
    return hmac.compare_digest(legacy_hash, hashed_password)


def create_access_token(data: dict, expires_in_seconds: int = 86400) -> str:
    to_encode = data.copy()
    to_encode.update({"exp": int(time.time()) + expires_in_seconds})

    header = json.dumps({"alg": "HS256", "typ": "JWT"}).encode('utf-8')
    payload = json.dumps(to_encode).encode('utf-8')

    b64_header = base64.urlsafe_b64encode(header).decode('utf-8').rstrip("=")
    b64_payload = base64.urlsafe_b64encode(payload).decode('utf-8').rstrip("=")

    signature_input = f"{b64_header}.{b64_payload}"
    # S-006 fix: use proper HMAC-SHA256, not raw SHA256(data+key)
    signature = hmac.new(
        SECRET_KEY.encode('utf-8'),
        signature_input.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()

    return f"{signature_input}.{signature}"


def decode_access_token(token: str) -> Optional[dict]:
    try:
        parts = token.split(".")
        if len(parts) != 3:
            return None

        b64_header, b64_payload, signature = parts
        signature_input = f"{b64_header}.{b64_payload}"
        # S-006 fix: verify with proper HMAC-SHA256
        expected_signature = hmac.new(
            SECRET_KEY.encode('utf-8'),
            signature_input.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()

        if not hmac.compare_digest(signature, expected_signature):
            return None

        # Pad payload if needed
        padded_payload = b64_payload + "=" * (-len(b64_payload) % 4)
        payload_bytes = base64.urlsafe_b64decode(padded_payload)
        payload = json.loads(payload_bytes.decode('utf-8'))

        if payload.get("exp", 0) < int(time.time()):
            return None  # Expired

        return payload
    except Exception:
        return None

