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


def validate_file_size(content_bytes: bytes, filename: str) -> None:
    if len(content_bytes) > MAX_FILE_SIZE_BYTES:
        size_mb = len(content_bytes) / (1024 * 1024)
        raise HTTPException(
            status_code=413,
            detail=f"File '{filename}' is too large ({size_mb:.1f} MB). Maximum allowed: 20 MB.",
        )
