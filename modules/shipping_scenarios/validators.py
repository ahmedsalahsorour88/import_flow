from datetime import date
from typing import List
from fastapi import HTTPException, status

from modules.shipping_scenarios.schemas import (
    ShippingEvaluationCreate,
    ShippingScenarioItemCreate,
)


class ShippingScenarioValidator:
    """
    Validation rules for BP-007 Shipping Scenarios Evaluation
    """

    @staticmethod
    def validate_evaluation_create(payload: ShippingEvaluationCreate) -> None:
        if payload.avg_form4_days < 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Average Form 4 days cannot be negative.",
            )

        if payload.avg_clearance_days < 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Average Customs Clearance days cannot be negative.",
            )

        if payload.items:
            ShippingScenarioValidator.validate_scenario_items(
                payload.cargo_ready_date, payload.items
            )

    @staticmethod
    def validate_scenario_items(
        cargo_ready_date: date, items: List[ShippingScenarioItemCreate]
    ) -> None:
        seen_keys = set()
        for idx, item in enumerate(items, start=1):
            if item.sailing_date < cargo_ready_date:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Option #{idx} ({item.provider_name}): Sailing date ({item.sailing_date}) cannot be before Cargo Ready Date ({cargo_ready_date}).",
                )

            if item.estimated_arrival_date <= item.sailing_date:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Option #{idx} ({item.provider_name}): Estimated Arrival Date (ETA) must be after Sailing Date.",
                )

            if item.expected_line_delay_days < 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Option #{idx} ({item.provider_name}): Expected delay days cannot be negative.",
                )

            key = (item.provider_id, item.provider_name.strip().lower(), item.vessel_name.strip().lower(), item.sailing_date)
            if key in seen_keys:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Duplicate shipping option found for Freight Forwarder ID '{item.provider_id}', Shipping Line '{item.provider_name}' on vessel '{item.vessel_name}' with sailing date {item.sailing_date}.",
                )
            seen_keys.add(key)
