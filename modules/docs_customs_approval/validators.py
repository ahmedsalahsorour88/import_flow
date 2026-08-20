"""
Validators for Docs Customs Approval Hub (DCA-001)
"""

from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from modules.import_files.model import ImportFile


VALID_DOCUMENT_TYPES = [
    "Commercial Invoice",
    "Packing List",
    "Bill of Lading",
    "Certificate of Origin",
    "EUR.1",
    "Inspection Certificate",
    "Bank Form 4",
    "Insurance Certificate",
]

VALID_APPROVAL_STATUSES = [
    "Draft",
    "Pending Review",
    "Approved for Clearance",
    "Rectification Required",
    "Rejected",
]


def validate_import_file_exists(db: Session, import_file_id: int) -> ImportFile:
    file = db.query(ImportFile).filter(
        ImportFile.import_file_id == import_file_id,
        ImportFile.is_active == True
    ).first()
    if not file:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Import File with ID {import_file_id} not found or inactive."
        )
    return file


def validate_document_type(doc_type: str) -> None:
    if doc_type not in VALID_DOCUMENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid document type '{doc_type}'. Allowed types: {', '.join(VALID_DOCUMENT_TYPES)}"
        )


def validate_ticket_creation(description: str, issue_category: str) -> None:
    if not description or len(description.strip()) < 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Discrepancy ticket description must be at least 5 characters long."
        )
    if not issue_category:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Issue category is required."
        )
