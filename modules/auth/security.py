import base64
import hashlib
import json
import time
from typing import Optional

SECRET_KEY = "ImportFlow_ERP_Secret_Key_2026_Secure_RBAC"


def hash_password(password: str) -> str:
    salt = "importflow_salt_v1"
    return hashlib.sha256((password + salt).encode('utf-8')).hexdigest()


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return hash_password(plain_password) == hashed_password


def create_access_token(data: dict, expires_in_seconds: int = 86400) -> str:
    to_encode = data.copy()
    to_encode.update({"exp": int(time.time()) + expires_in_seconds})

    header = json.dumps({"alg": "HS256", "typ": "JWT"}).encode('utf-8')
    payload = json.dumps(to_encode).encode('utf-8')

    b64_header = base64.urlsafe_b64encode(header).decode('utf-8').rstrip("=")
    b64_payload = base64.urlsafe_b64encode(payload).decode('utf-8').rstrip("=")

    signature_input = f"{b64_header}.{b64_payload}"
    signature = hashlib.sha256((signature_input + SECRET_KEY).encode('utf-8')).hexdigest()

    return f"{signature_input}.{signature}"


def decode_access_token(token: str) -> Optional[dict]:
    try:
        parts = token.split(".")
        if len(parts) != 3:
            return None

        b64_header, b64_payload, signature = parts
        signature_input = f"{b64_header}.{b64_payload}"
        expected_signature = hashlib.sha256((signature_input + SECRET_KEY).encode('utf-8')).hexdigest()

        if signature != expected_signature:
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
