from fastapi import HTTPException
from sqlalchemy.orm import Session

from modules.common.name_normalizer import check_duplicate_name
from .model import Supplier
from .schemas import SupplierCreate


def validate_supplier(
    db: Session,
    supplier: SupplierCreate
) -> None:
    # 1. Company Name Required
    if not supplier.company_name or not supplier.company_name.strip():
        raise HTTPException(
            status_code=400,
            detail="اسم الشركة / المورد الأجنبي مطلوب."
        )

    # 2. Strict Duplicate Name Detection (Active & Inactive Suppliers)
    all_suppliers = db.query(Supplier).all()
    existing_names = [s.company_name for s in all_suppliers if s.company_name]
    matched_name = check_duplicate_name(supplier.company_name, existing_names)

    if matched_name:
        existing_obj = next((s for s in all_suppliers if s.company_name == matched_name), None)
        code_info = f" (كود المورد: {existing_obj.supplier_code})" if existing_obj else ""
        raise HTTPException(
            status_code=400,
            detail=f"عفواً! المورد الأجنبي '{supplier.company_name.strip()}' مسجل بالفعل بالنظام من قبل باسم متطابق أو تشابه كبير: '{matched_name}'{code_info}. لا يمكن تكرار تسجيل الموردين."
        )

    # 3. Duplicate Exporter ID check
    exp_id = (supplier.foreign_exporter_id or "").strip()
    if exp_id and not exp_id.startswith("EXP-SUP-"):
        duplicate_exporter = next((s for s in all_suppliers if s.foreign_exporter_id == exp_id), None)
        if duplicate_exporter:
            raise HTTPException(
                status_code=400,
                detail=f"عفواً! رقم السجل / المعرف الضريبي للمورد الأجنبي '{exp_id}' مسجل بالفعل للنظام من قبل باسم: '{duplicate_exporter.company_name}'."
            )