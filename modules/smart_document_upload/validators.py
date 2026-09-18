"""
Smart Document Upload — Validators
File type, size, and module validation.
"""

from fastapi import HTTPException, UploadFile, status

# Max file size: 20 MB
MAX_FILE_SIZE_BYTES = 20 * 1024 * 1024

ALLOWED_EXTENSIONS = {
    ".pdf", ".docx", ".doc",
    ".xlsx", ".xls",
    ".txt", ".csv",
    ".png", ".jpg", ".jpeg", ".webp",
}

EXTENSION_TO_TYPE = {
    ".pdf": "pdf",
    ".docx": "word",
    ".doc": "word",
    ".xlsx": "excel",
    ".xls": "excel",
    ".txt": "text",
    ".csv": "text",
    ".png": "image",
    ".jpg": "image",
    ".jpeg": "image",
    ".webp": "image",
}

SUPPORTED_MODULES = {
    "purchase-order",
    "import-file",
    "cargo-shipping",
    "customs-clearance",
    "freight-quotation",
    "freight-booking",
    "clearance-quotation",
    "customs-broker-quotation",
    "customs-consultation",
    "warehouse-receiving",
    "demurrage",
    "financial-document",
    "commercial-invoice",
    "commercial_invoice",
    "invoice",
    "bill-of-lading",
    "bill_of_lading",
    "bl",
    "awb",
    "coo-certificate",


    "inspection-certificate",
    "master-data-entity",
    "supplier-entity",
    "importer-entity",
    "import-company-entity",
    "partner-entity",
    "bank-entity",
    "shipping-line-entity",
    "customs-broker-entity",
    "freight-forwarder-entity",
    "inland-transport-entity",
    "inspection-agency-entity",
    "insurance-company-entity",
}


def validate_module_name(module: str) -> None:
    if module not in SUPPORTED_MODULES:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail=f"Unsupported module '{module}'. Supported: {sorted(SUPPORTED_MODULES)}",
        )


def validate_upload_file(file: UploadFile) -> str:
    """
    Validates file extension and returns the detected file type string.
    Raises HTTPException on invalid file.
    """
    filename = file.filename or ""
    lower = filename.lower()

    matched_ext = None
    for ext in ALLOWED_EXTENSIONS:
        if lower.endswith(ext):
            matched_ext = ext
            break

    if matched_ext is None:
        raise HTTPException(
            status_code=415,
            detail=(
                f"File type not supported: '{filename}'. "
                f"Allowed types: PDF, Word (.docx/.doc), Excel (.xlsx/.xls), Text (.txt/.csv)"
            ),
        )

    return EXTENSION_TO_TYPE[matched_ext]


import os
import re


def sanitize_filename(filename: str) -> str:
    """Sanitizes filename against path traversal and dangerous characters."""
    base = os.path.basename(filename.replace("\\", "/"))
    cleaned = re.sub(r'[^a-zA-Z0-9_.\-\u0600-\u06FF ]', '', base)
    return cleaned.strip() or "document"


def validate_magic_bytes(content_bytes: bytes, filename: str) -> None:
    """
    Validates binary content signature (magic bytes) against declared extension.
    Explicitly rejects disguised executables (PE, ELF, scripts).
    """
    if not content_bytes:
        raise HTTPException(
            status_code=400,
            detail=f"File '{filename}' is empty (0 bytes).",
        )

    # 1. Unconditional executable and script blocking
    if content_bytes.startswith(b"MZ"):
        raise HTTPException(
            status_code=415,
            detail=f"Security Violation: Windows executable (PE/EXE) detected in file '{filename}'.",
        )
    if content_bytes.startswith(b"\x7fELF"):
        raise HTTPException(
            status_code=415,
            detail=f"Security Violation: Linux executable (ELF) detected in file '{filename}'.",
        )
    if content_bytes.startswith(b"<!DOCTYPE html") or content_bytes.startswith(b"<html") or content_bytes.startswith(b"<?php"):
        raise HTTPException(
            status_code=415,
            detail=f"Security Violation: Web script or HTML file detected in file '{filename}'.",
        )

    # 2. Check declared extension against binary headers
    lower = filename.lower()
    if lower.endswith(".pdf"):
        if not content_bytes.startswith(b"%PDF-"):
            raise HTTPException(
                status_code=415,
                detail=f"File '{filename}' has .pdf extension but lacks a valid PDF header (%PDF-).",
            )
    elif lower.endswith(".xlsx") or lower.endswith(".docx"):
        if not content_bytes.startswith(b"PK\x03\x04"):
            raise HTTPException(
                status_code=415,
                detail=f"File '{filename}' has Office OpenXML extension but lacks valid ZIP header (PK..).",
            )
    elif lower.endswith(".xls") or lower.endswith(".doc"):
        if not content_bytes.startswith(b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1") and not content_bytes.startswith(b"PK\x03\x04"):
            raise HTTPException(
                status_code=415,
                detail=f"File '{filename}' has legacy Office extension but lacks valid CFBF/OLE header.",
            )
    elif lower.endswith(".png"):
        if not content_bytes.startswith(b"\x89PNG\r\n\x1a\n"):
            raise HTTPException(
                status_code=415,
                detail=f"File '{filename}' has .png extension but lacks valid PNG header.",
            )
    elif lower.endswith(".jpg") or lower.endswith(".jpeg"):
        if not content_bytes.startswith(b"\xff\xd8\xff"):
            raise HTTPException(
                status_code=415,
                detail=f"File '{filename}' has JPEG extension but lacks valid JPEG SOI marker.",
            )
    elif lower.endswith(".webp"):
        if not (content_bytes.startswith(b"RIFF") and len(content_bytes) >= 12 and content_bytes[8:12] == b"WEBP"):
            raise HTTPException(
                status_code=415,
                detail=f"File '{filename}' has .webp extension but lacks valid WEBP header.",
            )


def validate_file_size(content_bytes: bytes, filename: str) -> None:
    if len(content_bytes) > MAX_FILE_SIZE_BYTES:
        size_mb = len(content_bytes) / (1024 * 1024)
        raise HTTPException(
            status_code=413,
            detail=f"File '{filename}' is too large ({size_mb:.1f} MB). Maximum allowed: 20 MB.",
        )
    # Content magic bytes inspection
    validate_magic_bytes(content_bytes, filename)

