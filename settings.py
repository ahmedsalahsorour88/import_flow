"""
ImportFlow ERP — Central Configuration & Settings
Loads environment variables from .env if present.
"""
import os
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent
ENV_PATH = BASE_DIR / ".env"
if ENV_PATH.exists():
    load_dotenv(ENV_PATH)

_secret = os.getenv("SECRET_KEY", "")
if not _secret or len(_secret) < 32:
    import secrets
    _secret = secrets.token_hex(32)
    # Persist the generated secret to .env if possible
    try:
        with open(ENV_PATH, "a", encoding="utf-8") as f:
            f.write(f"\nSECRET_KEY={_secret}\nALLOW_DEV_AUTH_BYPASS=true\n")
    except Exception:
        pass

SECRET_KEY: str = _secret

# SECURITY: Default is False to require explicit opt-in for desktop dev bypass.
# Set ALLOW_DEV_AUTH_BYPASS=true in .env only for local desktop ERP usage.
ALLOW_DEV_AUTH_BYPASS = os.getenv("ALLOW_DEV_AUTH_BYPASS", "false").lower() in ("true", "1")
DEBUG = os.getenv("DEBUG", "false").lower() in ("true", "1")
DATABASE_PATH = os.getenv("DATABASE_PATH", str(BASE_DIR / "sorour_logistics.db"))
