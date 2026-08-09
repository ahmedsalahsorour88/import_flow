from typing import Dict
from fastapi import HTTPException

def validate_closure_checklist(checklist: Dict[str, bool]) -> None:
    unmet = [k for k, v in checklist.items() if not v]
    if unmet:
        unmet_names = ", ".join(unmet)
        raise HTTPException(
            status_code=400,
            detail=f"لا يمكن إغلاق ملف الاستيراد نهائياً بسبب عدم اكتمال البنود التالية في قائمة التحقق: {unmet_names}",
        )
