"""
ImportFlow ERP — Smart Email Listener Credential Encryption Helper
Provides symmetric encryption for stored mailbox and SMTP passwords at rest using Fernet.
Fully backward-compatible with legacy plaintext passwords.
"""
import base64
import hashlib
import os
from cryptography.fernet import Fernet

def _get_fernet_cipher() -> Fernet:
    secret = os.getenv("SECRET_KEY", "ImportFlow_ERP_Secret_Key_2026_Secure_RBAC")
    key_32 = hashlib.sha256(secret.encode("utf-8")).digest()
    fernet_key = base64.urlsafe_b64encode(key_32)
    return Fernet(fernet_key)

def encrypt_email_password(plain_password: str) -> str:
    """Encrypts a plaintext password string. If empty or already encrypted, returns safe value."""
    if not plain_password:
        return ""
    if plain_password.startswith("enc:"):
        return plain_password
    cipher = _get_fernet_cipher()
    token = cipher.encrypt(plain_password.encode("utf-8")).decode("utf-8")
    return f"enc:{token}"

def decrypt_email_password(stored_password: str) -> str:
    """Decrypts a stored password. If stored as plaintext (legacy), returns as-is."""
    if not stored_password:
        return ""
    if not stored_password.startswith("enc:"):
        return stored_password
    try:
        cipher = _get_fernet_cipher()
        token = stored_password[4:]
        return cipher.decrypt(token.encode("utf-8")).decode("utf-8")
    except Exception:
        # Fallback in case of corruption or key mismatch
        return stored_password
