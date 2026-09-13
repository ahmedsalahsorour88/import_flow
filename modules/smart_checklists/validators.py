"""
Validation logic for Smart Import Checklist Engine
"""

from fastapi import HTTPException, status
from typing import Optional


ALLOWED_STATUSES = {"PASSED", "PENDING", "WAIVED"}
ALLOWED_PHASES = {"PRE_SHIPMENT", "IN_TRANSIT", "PORT_ARRIVAL", "CLEARANCE", "POST_CLEARANCE"}
ALLOWED_ROLES = {"COORDINATOR", "SUPPLIER", "CUSTOMS_BROKER", "SHIPPING_LINE"}


def validate_status(status_str: str) -> None:
    if status_str.upper() not in ALLOWED_STATUSES:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Invalid status '{status_str}'. Allowed values: {sorted(list(ALLOWED_STATUSES))}",
        )


def validate_override(is_mandatory: bool, override_reason: Optional[str]) -> None:
    if is_mandatory and (not override_reason or not override_reason.strip()):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Override justification reason is mandatory when waiving a critical gatekeeper checklist item.",
        )
