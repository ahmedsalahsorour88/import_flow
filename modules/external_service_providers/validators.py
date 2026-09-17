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
        if data.partner_type and ("bank" in data.partner_type.lower()) and data.swift_code:
            swift_clean = data.swift_code.strip().upper()
            duplicate_swift = next(
                (p for p in all_partners if p.swift_code and p.swift_code.strip().upper() == swift_clean),
                None
            )
            if duplicate_swift:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"عفواً! كود السويفت SWIFT Code '{data.swift_code}' مسجل بالفعل للبنك: '{duplicate_swift.partner_name}'."
                )

        # If partner is a Shipping Line and SCAC Code is provided, ensure unique SCAC Code
        if data.partner_type and ("shipping line" in data.partner_type.lower() or "carrier" in data.partner_type.lower()) and data.scac_code:
            scac_clean = data.scac_code.strip().upper()
            duplicate_scac = next(
                (p for p in all_partners if p.scac_code and p.scac_code.strip().upper() == scac_clean),
                None
            )
            if duplicate_scac:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"عفواً! كود الـ SCAC '{data.scac_code}' مسجل بالفعل للخط الملاحي: '{duplicate_scac.partner_name}'."
                )

        # If partner is a Freight Forwarder and FIATA ID is provided, ensure unique FIATA ID
        if data.partner_type and ("freight forwarder" in data.partner_type.lower() or "forwarder" in data.partner_type.lower()) and data.fiata_id:
            fiata_clean = data.fiata_id.strip().upper()
            duplicate_fiata = next(
                (p for p in all_partners if p.fiata_id and p.fiata_id.strip().upper() == fiata_clean),
                None
            )
            if duplicate_fiata:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"عفواً! رخصة أو كود الفياتا FIATA ID '{data.fiata_id}' مسجل بالفعل لوكيل الشحن: '{duplicate_fiata.partner_name}'."
                )

        # If partner is an Inspection Agency and Accreditation Number is provided, ensure uniqueness
        if data.partner_type and ("inspection" in data.partner_type.lower() or "معاينة" in data.partner_type.lower() or "فحص" in data.partner_type.lower()) and data.inspection_accreditation_number:
            acc_clean = data.inspection_accreditation_number.strip().upper()
            duplicate_acc = next(
                (p for p in all_partners if p.inspection_accreditation_number and p.inspection_accreditation_number.strip().upper() == acc_clean),
                None
            )
            if duplicate_acc:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"عفواً! رقم اعتماد جهة الفحص '{data.inspection_accreditation_number}' مسجل بالفعل لشركة الفحص: '{duplicate_acc.partner_name}'."
                )

        # If partner is a Customs Broker and Clearance License Number is provided, ensure uniqueness
        if data.partner_type and ("broker" in data.partner_type.lower() or "مخلص" in data.partner_type.lower() or "تخليص" in data.partner_type.lower()) and data.clearance_license_number:
            lic_clean = data.clearance_license_number.strip().upper()
            duplicate_lic = next(
                (p for p in all_partners if p.clearance_license_number and p.clearance_license_number.strip().upper() == lic_clean),
                None
            )
            if duplicate_lic:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"عفواً! رقم رخصة مزاولة التخليص الجمركي '{data.clearance_license_number}' مسجل بالفعل للمخلص الجمركي: '{duplicate_lic.partner_name}'."
                )

        # If partner is Inland Transport and Transport License Number is provided, ensure uniqueness
        if data.partner_type and ("inland transport" in data.partner_type.lower() or "نقل" in data.partner_type.lower() or "بري" in data.partner_type.lower()) and data.transport_license_number:
            t_lic_clean = data.transport_license_number.strip().upper()
            duplicate_t_lic = next(
                (p for p in all_partners if p.transport_license_number and p.transport_license_number.strip().upper() == t_lic_clean),
                None
            )
            if duplicate_t_lic:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"عفواً! رقم ترخيص النقل البري '{data.transport_license_number}' مسجل بالفعل لشركة النقل: '{duplicate_t_lic.partner_name}'."
                )

        # If partner is an Insurance Company and Insurance License Number is provided, ensure uniqueness
        if data.partner_type and ("insurance" in data.partner_type.lower() or "تأمين" in data.partner_type.lower()) and data.insurance_license_number:
            ins_clean = data.insurance_license_number.strip().upper()
            duplicate_ins = next(
                (p for p in all_partners if p.insurance_license_number and p.insurance_license_number.strip().upper() == ins_clean),
                None
            )
            if duplicate_ins:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"عفواً! رقم ترخيص شركة التأمين (FRA) '{data.insurance_license_number}' مسجل بالفعل لشركة التأمين: '{duplicate_ins.partner_name}'."
                )

        if data.default_free_days is not None and data.default_free_days < 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="فترة السماح الافتراضية (Free Days) يجب أن تكون رقماً موجباً أو صفراً."
            )