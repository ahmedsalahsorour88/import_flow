"""
Customs Clearance Quotations & Price Lists Validators
"""

from __future__ import annotations

from typing import Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from modules.customs_clearance_quotations.schemas import (
    CustomsClearanceRFQCreate,
    CustomsClearanceQuotationCreate,
    ClearancePriceListItemCreate,
)


def validate_rfq_create(data: CustomsClearanceRFQCreate) -> None:
    if not data.title or len(data.title.strip()) < 3:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="عنوان طلب عرض أسعار التخليص مطلوب ويجب ألا يقل عن 3 أحرف.",
        )
    if not data.port_name or len(data.port_name.strip()) < 2:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="ميناء التخليص الجمركي مطلوب.",
        )
    if data.containers_count < 1:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="عدد الحاويات / الشحنات يجب أن يكون 1 على الأقل.",
        )


def validate_quotation_create(data: CustomsClearanceQuotationCreate) -> None:
    if not data.provider_name or len(data.provider_name.strip()) < 2:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="اسم المخلص الجمركي / المكتب مطلوب.",
        )
    if data.provider_id <= 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="معرف الشريك / المخلص الجمركي غير صالح.",
        )
    if (data.clearance_fee + data.inland_transport_fee + data.inspection_fee + data.port_expenses + data.miscellaneous_fee) <= 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="يجب إدخال قيمة موجبة لأحد بنود عرض أسعار التخليص على الأقل.",
        )


def validate_price_item_create(data: ClearancePriceListItemCreate) -> None:
    if data.unit_price <= 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="سعر البند في قائمة الأسعار يجب أن يكون أكبر من الصفر.",
        )
    if not data.port_name or len(data.port_name.strip()) < 2:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="ميناء الخدمة مطلوب.",
        )
