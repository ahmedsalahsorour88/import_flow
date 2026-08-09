from fastapi import HTTPException

def validate_seal_integrity(seal_intact: bool, seal_number: str) -> None:
    """Logs warning or enforces registration of seal number."""
    if not seal_intact and (not seal_number or not seal_number.strip()):
        raise HTTPException(
            status_code=400,
            detail="في حالة كسر أو تلف الرصاص الأمني (Seal Broken)، يلزم إدخال رقم الرصاص المسجل للمطابقة وتوثيق المحضر.",
        )

def validate_discrepancy_claim(discrepancy_type: str, discrepancy_notes: str) -> None:
    """Validates discrepancy report notes when shortage or damage exists."""
    if discrepancy_type != "None" and (not discrepancy_notes or not discrepancy_notes.strip()):
        raise HTTPException(
            status_code=400,
            detail="عند إثبات عجز أو تلفيات أو أصناف مخالفة، يلزم كتابة ملاحظات وتفاصيل محضر الفحص والدليل.",
        )
