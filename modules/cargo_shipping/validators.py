from fastapi import HTTPException
from datetime import datetime

def validate_crd_against_cutoff(crd_date: datetime, cargo_cutoff_date: datetime) -> bool:
    """
    BP-020: Validates Cargo Readiness Date (CRD) against Cargo Cut-off date.
    Returns True if valid (CRD <= Cutoff), False if CRD exceeds Cutoff date.
    """
    if crd_date and cargo_cutoff_date:
        if crd_date > cargo_cutoff_date:
            return False
    return True

def validate_dual_approval_sequence(level1_status: str, level2_status: str):
    """
    BP-022: Level 2 Approval (Management Review) cannot occur before Level 1 (Operational Review) is Approved.
    """
    if level2_status == "Approved" and level1_status != "Approved":
        raise HTTPException(
            status_code=400,
            detail="لا يمكن تنفيذ الاعتماد النهائي (Level 2 Approval) قبل إتمام واجتياز اعتماد مراجعة التشغيل (Level 1 Approval) بنجاح."
        )

def validate_cargox_ready_for_upload(checklist: list):
    """
    BP-024: Stage 3 Upload Preparation requires 100% pass on all CargoX verification rules.
    """
    if not checklist:
        raise HTTPException(
            status_code=400,
            detail="قائمة مراجعة التبادل الإلكتروني CargoX فارغة. يجب تنفيذ فحص القواعد أولاً."
        )
    
    unpassed = [rule for rule in checklist if not rule.get("passed", False)]
    if unpassed:
        failed_names = ", ".join([r.get("rule_name", "قاعدة غير معروفة") for r in unpassed])
        raise HTTPException(
            status_code=400,
            detail=f"لا يمكن تجهيز المظروف للرفع على CargoX حتى تجتاز جميع بنود الفحص بنسبة 100%. البنود المعلقة: {failed_names}"
        )
