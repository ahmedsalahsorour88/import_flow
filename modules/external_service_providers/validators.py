from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from modules.common.name_normalizer import check_duplicate_name
from .model import ExternalServiceProvider
from .schemas import PartnerCreate


class ExternalServiceProviderValidator:
    def __init__(self, db: Session):
        self.db = db

    def validate_create(self, data: PartnerCreate) -> None:
        p_name = (getattr(data, "partner_name", None) or getattr(data, "provider_name", None) or "").strip()
        if not p_name:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="اسم الشريك / مقدم الخدمة مطلوب."
            )

        # Strict Duplicate Name Check (Active & Inactive Partners/Banks)
        all_partners = self.db.query(ExternalServiceProvider).all()
        existing_names = [p.partner_name for p in all_partners if p.partner_name]
        matched_name = check_duplicate_name(p_name, existing_names)

        if matched_name:
            existing_obj = next((p for p in all_partners if p.partner_name == matched_name), None)
            code_info = f" (كود: {existing_obj.partner_code})" if existing_obj else ""
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"عفواً! الشريك / مقدم الخدمة / البنك '{p_name}' مسجل بالفعل بالنظام من قبل باسم متطابق أو تشابه كبير: '{matched_name}'{code_info}. لا يمكن تكرار التسجيل."
            )

        # If partner is a Commercial Bank and SWIFT Code is provided, ensure unique SWIFT Code
        if data.partner_type and data.partner_type.lower() == 'bank' and data.swift_code:
            duplicate_swift = next((p for p in all_partners if p.swift_code == data.swift_code), None)
            if duplicate_swift:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"عفواً! كود السويفت SWIFT Code '{data.swift_code}' مسجل بالفعل للبنك: '{duplicate_swift.partner_name}'."
                )