"""
Business Validators for Shipment Update Engine Module
"""

from fastapi import HTTPException, status
from modules.shipment_updates.schemas import ShipmentUpdateLogCreate


def validate_update_log_create(schema: ShipmentUpdateLogCreate):
    if not schema.note or not schema.note.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="ملاحظة وتفاصيل التحديث مطلوبة ولا يمكن تركها فارغة.",
        )

    if not schema.log_date:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="تاريخ التحديث مطلوب.",
        )
