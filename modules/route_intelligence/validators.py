"""
Route & Supplier Intelligence Validators (AI-ROUTE-006)
"""

from fastapi import HTTPException, status


def validate_note_content(text: str) -> None:
    if not text or len(text.strip()) < 3:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="نص الملاحظة التشغيلية يجب ألا يقل عن 3 أحرف.",
        )
