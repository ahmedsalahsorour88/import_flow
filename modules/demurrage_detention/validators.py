from datetime import date
from typing import List, Optional
from fastapi import HTTPException, status
from .schemas import TierRateItem


def validate_tier_rates(tiers: List[TierRateItem], tier_name: str = "Tiers") -> None:
    """Validates that tier rates are positive and sequentially structured."""
    if not tiers:
        return

    sorted_tiers = sorted(tiers, key=lambda t: t.from_day)
    if sorted_tiers[0].from_day != 1:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"{tier_name} must start from day 1 (First tier from_day must be 1).",
        )

    for i, t in enumerate(sorted_tiers):
        if t.rate_per_day < 0:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"{tier_name} daily rate cannot be negative.",
            )
        if t.to_day is not None and t.to_day < t.from_day:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"{tier_name} to_day ({t.to_day}) must be greater than or equal to from_day ({t.from_day}).",
            )


def validate_demurrage_dates(
    discharge_date: date,
    gate_out_date: Optional[date] = None,
    empty_return_date: Optional[date] = None,
) -> None:
    """Validates chronological order of container operational milestones."""
    if gate_out_date and gate_out_date < discharge_date:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="تاريخ خروج الحاوية من الميناء (Gate-Out) لا يمكن أن يكون قبل تاريخ تفريغها من السفينة (Discharge Date).",
        )

    if empty_return_date:
        if gate_out_date and empty_return_date < gate_out_date:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="تاريخ إعادة الحاوية الفارغة لا يمكن أن يكون قبل تاريخ خروجها من الميناء.",
            )
        elif not gate_out_date and empty_return_date < discharge_date:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="تاريخ إعادة الحاوية الفارغة لا يمكن أن يكون قبل تاريخ تفريغها.",
            )


def validate_positive_amount(val: float, field_name: str) -> None:
    if val <= 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Field {field_name} must be greater than zero.",
        )
