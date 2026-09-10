"""
Validators for Formal Letter Drafting (AI-DRAFT-014)
"""

from fastapi import HTTPException, status

VALID_TEMPLATE_TYPES = {
    "demurrage_extension",
    "bank_delegation",
    "bank_form4",
    "customs_broker_mandate",
}


def validate_formal_letter_request(import_file_id: int, template_type: str, extension_days: int = 21):
    if not import_file_id or import_file_id <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="معرف ملف الشحنة غير صالح.",
        )

    if template_type not in VALID_TEMPLATE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"نوع الخطاب المطلوب غير صالح. الأنواع المتاحة هي: {', '.join(VALID_TEMPLATE_TYPES)}",
        )

    if extension_days is not None and (extension_days < 1 or extension_days > 120):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="عدد أيام مهلة السماح يجب أن يتراوح بين 1 و 120 يوماً.",
        )
