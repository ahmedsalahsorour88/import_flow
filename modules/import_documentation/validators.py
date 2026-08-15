"""
Business Validation Rules for Import Documentation & ACI (Phase 3 - BP-014 to BP-019)
"""

from datetime import date
from fastapi import HTTPException, status
from sqlalchemy.orm import Session


def validate_acid_number(acid_number: str | None, allow_pending: bool = True):
    """
    Validates Egyptian Nafeza ACID Number structure:
    Must be exactly 19 numeric digits when issued, or PENDING during initial request stage.
    """
    if not acid_number:
        if allow_pending:
            return
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="ACID Number is required.",
        )
    cleaned = acid_number.strip()
    if allow_pending and cleaned.upper() in ["PENDING", "REQUESTED", "DRAFT", ""]:
        return
    if len(cleaned) != 19 or not cleaned.isdigit():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid ACID Number '{acid_number}'. Egyptian Nafeza ACID must be exactly 19 numeric digits.",
        )


def validate_acid_expiry(expiry_date: date | None, issue_date: date | None = None):
    """
    Validates that ACID expiry date is in the future.
    """
    if not expiry_date:
        return
    ref_date = issue_date or date.today()
    if expiry_date <= ref_date:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"ACID Expiry Date ({expiry_date}) must be after Issue/Requested Date ({ref_date}).",
        )
