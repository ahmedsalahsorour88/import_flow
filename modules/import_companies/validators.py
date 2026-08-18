from fastapi import HTTPException
from sqlalchemy.orm import Session

from modules.common.name_normalizer import check_duplicate_name
from .model import ImportCompany
from .repository import importer_id_exists, registration_number_exists, vat_id_exists
from .schemas import ImportCompanyCreate


def validate_company(
    db: Session,
    company_data: ImportCompanyCreate
) -> None:
    # 1. Importer Name Required
    if not company_data.importer_name or not company_data.importer_name.strip():
        raise HTTPException(
            status_code=400,
            detail="اسم الشركة المستوردة مطلوب."
        )

    # 2. Strict Duplicate Name Detection (Active & Inactive Companies)
    all_companies = db.query(ImportCompany).all()
    existing_names = [c.importer_name for c in all_companies if c.importer_name]
    matched_name = check_duplicate_name(company_data.importer_name, existing_names)

    if matched_name:
        existing_obj = next((c for c in all_companies if c.importer_name == matched_name), None)
        raise HTTPException(
            status_code=400,
            detail=f"عفواً! شركة الاستيراد '{company_data.importer_name.strip()}' مسجلة بالفعل بالنظام من قبل باسم متطابق أو تشابه كبير: '{matched_name}'. لا يمكن تكرار تسجيل الشركات المستوردة."
        )

    # 3. Duplicate Importer ID check
    imp_id = (company_data.importer_id or "").strip()
    if imp_id and not imp_id.startswith("IMP-REG-") and not imp_id.startswith("IMP-"):
        duplicate_imp = next((c for c in all_companies if c.importer_id == imp_id), None)
        if duplicate_imp:
            raise HTTPException(
                status_code=400,
                detail=f"عفواً! رقم كود المستورد '{imp_id}' مسجل بالفعل للشركة: '{duplicate_imp.importer_name}'."
            )

    # 4. Duplicate VAT ID check
    vat = (company_data.vat_id or "").strip()
    if vat and vat != "000000000":
        duplicate_vat = next((c for c in all_companies if c.vat_id == vat), None)
        if duplicate_vat:
            raise HTTPException(
                status_code=400,
                detail=f"عفواً! رقم التسجيل الضريبي '{vat}' مسجل بالفعل للشركة: '{duplicate_vat.importer_name}'."
            )

    # 5. Duplicate Commercial Registration Number check
    reg_num = (company_data.registration_number or "").strip()
    if reg_num and reg_num != "000000":
        duplicate_reg = next((c for c in all_companies if c.registration_number == reg_num), None)
        if duplicate_reg:
            raise HTTPException(
                status_code=400,
                detail=f"عفواً! رقم السجل التجاري '{reg_num}' مسجل بالفعل للشركة: '{duplicate_reg.importer_name}'."
            )