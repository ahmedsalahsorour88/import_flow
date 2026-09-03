"""
Business Validation Rules for Logistics What-If Simulation
"""

from fastapi import HTTPException, status
from modules.simulation.schemas import WhatIfSimulationRequest


def validate_simulation_request(request: WhatIfSimulationRequest) -> None:
    """Validates boundary rules for what-if simulation inputs."""
    if request.exchange_rate_change_pct < -50.0 or request.exchange_rate_change_pct > 200.0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="نسبة تغير سعر الصرف يجب أن تتراوح بين -50% إلى +200% كحد أقصى للمحاكاة.",
        )

    if request.custom_transit_days and (request.custom_transit_days < 0 or request.custom_transit_days > 120):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="أيام التأخير الإضافية في البحر يجب ألا تتجاوز 120 يوماً.",
        )

    if request.port_storage_delay_days < 0 or request.port_storage_delay_days > 90:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="أيام التأخير في ساحات الموانئ يجب أن تتراوح بين 0 و 90 يوماً.",
        )

    if request.container_count < 1 or request.container_count > 100:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="عدد الحاويات في المحاكاة يجب أن يكون بين 1 و 100 حاوية.",
        )

    if request.invoice_amount and request.invoice_amount < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="قيمة الفاتورة لا يمكن أن تكون سالبة.",
        )
