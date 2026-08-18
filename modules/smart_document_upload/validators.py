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
}

EXTENSION_TO_TYPE = {
    ".pdf": "pdf",
    ".docx": "word",
    ".doc": "word",
    ".xlsx": "excel",
    ".xls": "excel",
    ".txt": "text",
    ".csv": "text",
}

SUPPORTED_MODULES = {
    "purchase-order",
    "import-file",
    "cargo-shipping",
    "customs-clearance",
    "freight-quotation",
    "freight-booking",
    "customs-consultation",
    "warehouse-receiving",
    "demurrage",
    "financial-document",
    "coo-certificate",
    "inspection-certificate",
}


def validate_module_name(module: str) -> None:
    if module not in SUPPORTED_MODULES:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
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
