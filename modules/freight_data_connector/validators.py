from typing import List, Dict, Any
from fastapi import HTTPException, status


def validate_rate_slabs(slabs: List[Dict[str, Any]], currency_label: str = "USD") -> None:
    if not slabs:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Rate slabs list cannot be empty for {currency_label}."
        )
    for idx, s in enumerate(slabs):
        if "from_day" not in s or "rate_per_day" not in s:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Slab #{idx+1} must contain 'from_day' and 'rate_per_day'."
            )
        if s["from_day"] < 1:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Slab #{idx+1} 'from_day' must be >= 1."
            )
        if s["rate_per_day"] < 0:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Slab #{idx+1} rate must be non-negative."
            )


def validate_quota_guard(used_calls: int, max_limit: int = 25, reserved_safety: int = 15) -> None:
    """
    Quota Guard ensures we do not exceed safe monthly limits (max 10 calls = 25 limit - 15 safety).
    """
    effective_limit = max_limit - reserved_safety # e.g. 10
    if used_calls >= effective_limit:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=(
                f"External API Quota Guard triggered: {used_calls} calls already consumed this month "
                f"(Safety cap: {effective_limit}/25). Local cached rules will be used."
            )
        )
