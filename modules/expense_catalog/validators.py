"""
Expense Catalog Validators (AI-EXPENSE-CATALOG-002)
Validation rules for ExpenseCatalog codes, categories, and unit types.
"""

from __future__ import annotations

import re
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from modules.expense_catalog.model import ExpenseCatalog


ALLOWED_CATEGORIES = {
    "Clearance Fees",
    "Procedures & Approvals",
    "Inland Transport",
    "Port & Handling",
    "Other Fees",
}

ALLOWED_UNIT_TYPES = {
    "fixed",
    "per_ton",
    "per_container",
    "per_vehicle",
    "per_night",
    "per_invoice",
    "per_shipment",
    "range",
}


class ExpenseCatalogValidator:

    @staticmethod
    def validate_code_format(code: str) -> str:
        clean = code.strip().upper()
        if not re.match(r"^[A-Z0-9]+(-[A-Z0-9]+)+$", clean) or len(clean) < 3 or len(clean) > 30:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Expense code must be 3-30 characters containing uppercase letters, numbers, and dashes (e.g. CLR-LCL-INV).",
            )
        return clean

    @staticmethod
    def validate_category(category: str) -> str:
        clean = category.strip()
        # Normalize if localized or slightly different
        for allowed in ALLOWED_CATEGORIES:
            if allowed.lower() in clean.lower():
                return allowed
        if clean not in ALLOWED_CATEGORIES:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Category '{category}' is invalid. Allowed: {sorted(list(ALLOWED_CATEGORIES))}.",
            )
        return clean

    @staticmethod
    def validate_unit_type(unit_type: str) -> str:
        clean = unit_type.strip().lower()
        if clean not in ALLOWED_UNIT_TYPES:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Unit type '{unit_type}' is invalid. Allowed: {sorted(list(ALLOWED_UNIT_TYPES))}.",
            )
        return clean

    @staticmethod
    def validate_unique_code(db: Session, code: str):
        normalized = ExpenseCatalogValidator.validate_code_format(code)
        exists = db.query(ExpenseCatalog).filter(ExpenseCatalog.code == normalized).first()
        if exists:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Expense code '{normalized}' already exists in the catalog.",
            )
