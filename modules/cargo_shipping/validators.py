from fastapi import HTTPException
from datetime import datetime, timezone, timedelta
from typing import Optional, Dict, Any, List
from sqlalchemy.orm import Session

def parse_iso_datetime(val: Any) -> Optional[datetime]:
    if not val:
        return None
    if isinstance(val, datetime):
        return val if val.tzinfo else val.replace(tzinfo=timezone.utc)
    if isinstance(val, str):
        val = val.strip()
        if not val:
            return None
        try:
            # Handle YYYY-MM-DD
            if len(val) == 10:
                dt = datetime.strptime(val, "%Y-%m-%d")
                return dt.replace(tzinfo=timezone.utc)
            # Handle ISO format
            dt = datetime.fromisoformat(val.replace("Z", "+00:00"))
            return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
        except Exception:
            return None
    return None

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

def validate_container_tracking_timestamps(
    container_assignment_date: Optional[str] = None,
    arrival_at_supplier_at: Optional[str] = None,
    loading_start_at: Optional[str] = None,
    loading_end_at: Optional[str] = None,
    port_gate_in_at: Optional[str] = None,
):
    """
    Section 5: Strict Sequential Timestamp Validation for Container Loading Follow-up
    1. arrival_at_supplier_at >= container_assignment_date
    2. loading_start_at >= arrival_at_supplier_at
    3. loading_end_at >= loading_start_at
    4. port_gate_in_at >= loading_end_at
    5. No subsequent date can be prior to container_assignment_date
    """
    dt_assign = parse_iso_datetime(container_assignment_date)
    dt_arrival = parse_iso_datetime(arrival_at_supplier_at)
    dt_start = parse_iso_datetime(loading_start_at)
    dt_end = parse_iso_datetime(loading_end_at)
    dt_gate_in = parse_iso_datetime(port_gate_in_at)

    if dt_assign:
        if dt_arrival and dt_arrival < dt_assign:
            raise HTTPException(
                status_code=400,
                detail="تاريخ ووقت وصول الحاوية لدى المورد/المخزن لا يمكن أن يكون قبل تاريخ ووقت تخصيص الحاوية (Container Assignment Date & Time)."
            )
        if dt_start and dt_start < dt_assign:
            raise HTTPException(
                status_code=400,
                detail="تاريخ ووقت بداية التحميل لا يمكن أن يكون قبل تاريخ ووقت تخصيص الحاوية."
            )
        if dt_end and dt_end < dt_assign:
            raise HTTPException(
                status_code=400,
                detail="تاريخ ووقت نهاية التحميل لا يمكن أن يكون قبل تاريخ ووقت تخصيص الحاوية."
            )
        if dt_gate_in and dt_gate_in < dt_assign:
            raise HTTPException(
                status_code=400,
                detail="تاريخ ووقت دخول الحاوية للميناء لا يمكن أن يكون قبل تاريخ ووقت تخصيص الحاوية."
            )

    if dt_arrival:
        if dt_start and dt_start < dt_arrival:
            raise HTTPException(
                status_code=400,
                detail="تاريخ ووقت بداية التحميل لا يمكن أن يكون قبل تاريخ ووقت وصول الحاوية لدى المورد/المخزن."
            )

    if dt_start:
        if dt_end and dt_end < dt_start:
            raise HTTPException(
                status_code=400,
                detail="تاريخ ووقت نهاية التحميل لا يمكن أن يكون قبل تاريخ ووقت بداية التحميل."
            )

    if dt_end:
        if dt_gate_in and dt_gate_in < dt_end:
            raise HTTPException(
                status_code=400,
                detail="تاريخ ووقت دخول الحاوية للميناء لا يمكن أن يكون قبل تاريخ ووقت إتمام التحميل."
            )

def calculate_container_sla_and_status(item_dict: Dict[str, Any], sla_hours: int = 48) -> Dict[str, Any]:
    """
    Section 4 & 5: Automatically computes SLA deadline, SLA breach flag, and status workflow.
    Status transitions:
    1) PENDING_ASSIGNMENT
    2) ASSIGNED
    3) ARRIVED_AT_SUPPLIER
    4) LOADING_IN_PROGRESS
    5) LOADING_COMPLETED
    6) GATED_IN_AT_PORT
    """
    updated = dict(item_dict)

    assign_val = updated.get("container_assignment_date") or updated.get("consolidation_scheduled_date")
    arrival_val = updated.get("arrival_at_supplier_at") or updated.get("arrival_at_cfs_at")
    start_val = updated.get("loading_start_at") or updated.get("stuffing_start_at")
    end_val = updated.get("loading_end_at") or updated.get("stuffing_end_at")
    gate_in_val = updated.get("port_gate_in_at")

    dt_assign = parse_iso_datetime(assign_val)
    dt_arrival = parse_iso_datetime(arrival_val)
    dt_start = parse_iso_datetime(start_val)
    dt_end = parse_iso_datetime(end_val)
    dt_gate_in = parse_iso_datetime(gate_in_val)

    # Calculate SLA Deadline
    if dt_assign:
        dt_deadline = dt_assign + timedelta(hours=sla_hours)
        updated["sla_deadline_at"] = dt_deadline.isoformat()
    else:
        dt_deadline = None

    # Calculate SLA Breach
    now = datetime.now(timezone.utc)
    is_breached = False
    if dt_deadline:
        if dt_gate_in:
            if dt_gate_in > dt_deadline:
                is_breached = True
        else:
            if now > dt_deadline:
                is_breached = True
    updated["is_sla_breached"] = is_breached

    # Auto Status Transition
    if dt_gate_in:
        status = "GATED_IN_AT_PORT"
    elif dt_end:
        status = "LOADING_COMPLETED"
    elif dt_start:
        status = "LOADING_IN_PROGRESS"
    elif dt_arrival:
        status = "ARRIVED_AT_SUPPLIER"
    elif dt_assign:
        status = "ASSIGNED"
    else:
        status = "PENDING_ASSIGNMENT"

    updated["tracking_status"] = status
    return updated

def validate_container_reuse_conflict(
    db: Session,
    containers_loading_data: List[Any],
    current_record_id: Optional[int] = None,
):
    """
    Validates that no container number is reused within a 15-day window from its assignment date
    unless there is a different seal number.
    """
    from .model import CargoShippingRecord
    
    query = db.query(CargoShippingRecord).filter(CargoShippingRecord.is_active == True)
    if current_record_id:
        query = query.filter(CargoShippingRecord.cargo_shipping_id != current_record_id)
    records = query.all()

    for c in containers_loading_data:
        c_dict = c if isinstance(c, dict) else (c.model_dump() if hasattr(c, "model_dump") else dict(c))
        c_no = (c_dict.get("container_no") or "").strip().upper()
        s_no = (c_dict.get("seal_no") or "").strip().upper()
        c_date_raw = c_dict.get("container_assignment_date")
        c_date = parse_iso_datetime(c_date_raw)

        if not c_no or not c_date:
            continue

        for rec in records:
            rec_containers = rec.containers_loading_data or []
            for existing_c in rec_containers:
                ex_no = (existing_c.get("container_no") or "").strip().upper()
                ex_seal = (existing_c.get("seal_no") or "").strip().upper()
                ex_date_raw = existing_c.get("container_assignment_date")
                ex_date = parse_iso_datetime(ex_date_raw)

                if ex_no == c_no and ex_date:
                    diff_days = abs((c_date.date() - ex_date.date()).days)
                    if diff_days <= 15 and ex_seal == s_no:
                        raise HTTPException(
                            status_code=400,
                            detail=f"لا يمكن استخدام نفس رقم الحاوية ({c_no}) ونفس رقم السيل ({s_no}) في محيط زمني 15 يوماً (الفرق: {diff_days} يوم) من تاريخ التخصيص السابق ({str(ex_date.date())}) المسجل بالشحنة ({rec.cargo_shipping_code}). يرجى التحقق من رقم الحاوية أو إدخال رقم سيل مختلف في حال تدوير واستخدام نفس الحاوية."
                        )
