"""
Business Validators for Smart Shipment Experience Guide (KB-GUIDE-012)
"""
from typing import List
from fastapi import HTTPException, status
from modules.experience_guide.schemas import GuideEntryCreate, GuideEntryUpdate, GuideScopeCreate

ALLOWED_ENTRY_TYPES = {"alert", "required_document", "task", "info"}
ALLOWED_SEVERITIES = {"info", "warning", "critical"}
ALLOWED_SCOPE_TYPES = {
    "hs_code",
    "product_category",
    "destination_port",
    "supplier",
    "shipping_line",
}


def validate_guide_entry_data(data: GuideEntryCreate) -> None:
    if data.entry_type not in ALLOWED_ENTRY_TYPES:
        raise HTTPException(
            status_code=422,
            detail=f"Invalid entry_type '{data.entry_type}'. Must be one of {sorted(ALLOWED_ENTRY_TYPES)}",
        )
    if data.severity not in ALLOWED_SEVERITIES:
        raise HTTPException(
            status_code=422,
            detail=f"Invalid severity '{data.severity}'. Must be one of {sorted(ALLOWED_SEVERITIES)}",
        )
    validate_scopes(data.scopes)


def validate_guide_entry_update(data: GuideEntryUpdate) -> None:
    if data.entry_type is not None and data.entry_type not in ALLOWED_ENTRY_TYPES:
        raise HTTPException(
            status_code=422,
            detail=f"Invalid entry_type '{data.entry_type}'. Must be one of {sorted(ALLOWED_ENTRY_TYPES)}",
        )
    if data.severity is not None and data.severity not in ALLOWED_SEVERITIES:
        raise HTTPException(
            status_code=422,
            detail=f"Invalid severity '{data.severity}'. Must be one of {sorted(ALLOWED_SEVERITIES)}",
        )
    if data.scopes is not None:
        validate_scopes(data.scopes)


def validate_scopes(scopes: List[GuideScopeCreate]) -> None:
    for idx, sc in enumerate(scopes):
        if sc.scope_type not in ALLOWED_SCOPE_TYPES:
            raise HTTPException(
                status_code=422,
                detail=f"Invalid scope_type '{sc.scope_type}' at index {idx}. Must be one of {sorted(ALLOWED_SCOPE_TYPES)}",
            )
        if not sc.scope_value or not sc.scope_value.strip():
            raise HTTPException(
                status_code=422,
                detail=f"scope_value cannot be empty at index {idx}",
            )
