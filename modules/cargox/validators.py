"""
CargoX & ACI Dispatch Hub Business Validators (CGX-001)
"""

import re
from fastapi import HTTPException, status
from .schemas import CargoXEnvelopeCreate, CargoXEnvelopeUpdate
from .model import CargoXEnvelope


class CargoXValidators:

    @staticmethod
    def validate_acid_number(acid_number: str) -> str:
        clean_acid = re.sub(r'[^0-9]', '', acid_number.strip())
        if len(clean_acid) != 19:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"رقم الـ ACID الجمركي غير صالح: يجب أن يتكون من 19 رقماً بالضبط طبقاً لمنظومة نافذة (تم إدخال: {len(clean_acid)} رقم).",
            )
        return clean_acid

    @staticmethod
    def validate_cargox_id(cargox_id: str) -> str:
        clean_id = cargox_id.strip()
        if not clean_id or len(clean_id) < 3:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="معرف منصة CargoX للمورد الأجنبي (CargoX Platform ID) إلزامي ولا يمكن تركه فارغاً.",
            )
        return clean_id

    @staticmethod
    def validate_envelope_creation(payload: CargoXEnvelopeCreate) -> None:
        CargoXValidators.validate_acid_number(payload.acid_number)
        CargoXValidators.validate_cargox_id(payload.supplier_cargox_id)
        if not payload.importer_company_name.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="اسم الشركة المستوردة مطلوب.",
            )
        if not payload.supplier_name.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="اسم المورد الأجنبي مطلوب.",
            )

    @staticmethod
    def validate_ready_for_customs_transfer(envelope: CargoXEnvelope) -> None:
        if envelope.status in ["SEALED_AND_TRANSFERRED", "ACCEPTED_BY_CUSTOMS"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="هذا المظروف تم إغلاقه وتحويله لمصلحة الجمارك المصرية مسبقاً ولا يجوز إعادة إرساله.",
            )

        if not envelope.documents or len(envelope.documents) == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="لا يمكن تحويل المظروف إلى الجمارك: المظروف لا يحتوي على أي مستندات شحن مرفقة.",
            )

        # Check mandatory documents (Commercial Invoice, Packing List, Draft/Final B/L)
        doc_types = [d.doc_type.lower() for d in envelope.documents if d.is_active]
        has_invoice = any("invoice" in dt or "فاتورة" in dt for dt in doc_types)
        has_packing = any("packing" in dt or "تعبئة" in dt for dt in doc_types)
        has_bl = any("b/l" in dt or "bl" in dt or "بوليصة" in dt or "lading" in dt for dt in doc_types)

        missing = []
        if not has_invoice:
            missing.append("الفاتورة التجارية (Commercial Invoice)")
        if not has_packing:
            missing.append("قائمة التعبئة (Packing List)")
        if not has_bl and not envelope.bl_number:
            missing.append("بوليصة الشحن (Bill of Lading)")

        if missing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"لا يمكن إغلاق المظروف للجمارك: المستندات الإلزامية التالية مفقودة: {', '.join(missing)}.",
            )
