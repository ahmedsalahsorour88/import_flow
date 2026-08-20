from typing import Dict, List, Optional
from fastapi import HTTPException

# Mapping of checklist keys to stage step codes
CHECKLIST_STAGE_MAPPING = {
    "docs_verified": ["STEP_08", "STEP_09", "docs_verified"],
    "customs_cleared": ["STEP_13", "STEP_14", "STEP_17", "customs_cleared"],
    "warehouse_received": ["STEP_19", "warehouse_received"],
    "landed_cost_settled": ["STEP_20", "landed_cost_settled"],
    "tasks_closed": ["STEP_21", "tasks_closed"],
}

def validate_closure_checklist(checklist: Dict[str, bool], skipped_stages: Optional[List[str]] = None) -> None:
    skipped_set = set(skipped_stages or [])
    unmet = []

    for key, is_done in checklist.items():
        if not is_done:
            # Check if this item is marked as skipped / exempt in shipment lifecycle
            equivalent_steps = CHECKLIST_STAGE_MAPPING.get(key, [key])
            if any(step in skipped_set for step in equivalent_steps):
                continue  # Bypassed legally due to stage exemption / skip
            unmet.append(key)

    if unmet:
        unmet_names = ", ".join(unmet)
        raise HTTPException(
            status_code=400,
            detail=f"لا يمكن إغلاق ملف الاستيراد نهائياً بسبب عدم اكتمال البنود التالية في قائمة التحقق: {unmet_names}",
        )

