"""
FastAPI Router for Smart Task Management & Reminder Engine (Feature 2.4 & 2.5)
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from database.database import get_db
from modules.smart_tasks.schemas import (
    SmartTaskCreate,
    SmartTaskUpdate,
    SmartTaskResponse,
    SmartTaskSummaryMetrics,
    ReminderEngineResponse,
)
from modules.smart_tasks.model import SmartTask
import modules.smart_tasks.service as service
import modules.smart_tasks.repository as repo

router = APIRouter(prefix="/api/v1/smart-tasks", tags=["Smart Task Management & Reminders"])


@router.post(
    "",
    response_model=SmartTaskResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new Smart Task or Manual To-Do",
)
def create_task(payload: SmartTaskCreate, db: Session = Depends(get_db)):
    return service.create_task_service(db, payload)


@router.get(
    "",
    response_model=List[SmartTaskResponse],
    summary="List all tasks with filters",
)
def list_tasks(
    include_inactive: bool = False,
    task_type: Optional[str] = None,
    status: Optional[str] = None,
    priority: Optional[str] = None,
    import_file_id: Optional[int] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
):
    return repo.get_all_tasks(
        db,
        include_inactive=include_inactive,
        task_type=task_type,
        status=status,
        priority=priority,
        import_file_id=import_file_id,
        search=search,
    )


@router.get(
    "/metrics/summary",
    response_model=SmartTaskSummaryMetrics,
    summary="Get operational dashboard metrics summary",
)
def get_metrics_summary(db: Session = Depends(get_db)):
    return service.get_dashboard_summary_metrics_service(db)


@router.get(
    "/reminders/due",
    response_model=ReminderEngineResponse,
    summary="Feature 2.5 — Reminder Engine: Get overdue, due today, and upcoming tasks",
)
def get_due_reminders(
    target_date: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """
    Reminder Engine (Feature 2.5):
    Returns tasks segmented into: overdue, due today, due this week.
    Optionally pass target_date=YYYY-MM-DD to simulate a specific day.
    """
    return repo.get_due_and_overdue_tasks(db, target_date_str=target_date)


@router.get(
    "/{task_id}",
    response_model=SmartTaskResponse,
    summary="Get single smart task by ID",
)
def get_task(task_id: int, db: Session = Depends(get_db)):
    task = repo.get_task_by_id(db, task_id)
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"المهمة رقم '{task_id}' غير موجودة.",
        )
    return task


@router.put(
    "/{task_id}",
    response_model=SmartTaskResponse,
    summary="Update smart task",
)
def update_task(task_id: int, payload: SmartTaskUpdate, db: Session = Depends(get_db)):
    return service.update_task_service(db, task_id, payload)


@router.delete(
    "/{task_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Soft delete a smart task",
)
def soft_delete_task(task_id: int, db: Session = Depends(get_db)):
    success = repo.soft_delete_task(db, task_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"المهمة رقم '{task_id}' غير موجودة.",
        )


@router.patch(
    "/{task_id}/restore",
    response_model=SmartTaskResponse,
    summary="Restore soft deleted smart task",
)
def restore_task(task_id: int, db: Session = Depends(get_db)):
    task = repo.restore_task(db, task_id)
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"المهمة رقم '{task_id}' غير موجودة.",
        )
    return task


# ─── Phase Transition Endpoints (Feature Medium Priority) ─────────────────────

@router.post(
    "/phase-transition/generate-tasks/{import_file_id}",
    summary="Generate system tasks automatically for current phase of import file",
    response_model=dict,
)
def generate_phase_tasks(import_file_id: int, db: Session = Depends(get_db)):
    """
    Medium Priority: Automatic Smart Task Generation on Phase Transition.
    Call this endpoint whenever an import file advances to a new phase.
    System will auto-create standard follow-up tasks for the current phase.
    """
    from modules.import_files.repository import get_import_file_by_id
    import_file = get_import_file_by_id(db, import_file_id)
    if not import_file:
        raise HTTPException(status_code=404, detail="ملف الاستيراد غير موجود.")

    before_count = db.query(SmartTask).filter(
        SmartTask.import_file_id == import_file_id,
        SmartTask.task_type == "System Generated",
        SmartTask.is_active == True,
    ).count()

    service.auto_generate_system_tasks_for_file(db, import_file)

    after_count = db.query(SmartTask).filter(
        SmartTask.import_file_id == import_file_id,
        SmartTask.task_type == "System Generated",
        SmartTask.is_active == True,
    ).count()

    new_tasks_created = after_count - before_count
    return {
        "import_file_id": import_file_id,
        "current_phase": import_file.current_module,
        "new_tasks_created": new_tasks_created,
        "total_system_tasks": after_count,
        "message": f"تم إنشاء {new_tasks_created} مهمة جديدة تلقائياً للمرحلة {import_file.current_module}",
    }


@router.post(
    "/phase-transition/complete-phase/{import_file_id}",
    summary="Auto-close system tasks when a phase is marked complete",
    response_model=dict,
)
def complete_phase_tasks(
    import_file_id: int,
    completed_phase: str,
    db: Session = Depends(get_db),
):
    """
    Medium Priority: Auto-close all system tasks belonging to a completed phase.
    E.g. when Phase 3 is done, all Phase 3 system tasks become 'Completed'.
    """
    from modules.import_files.repository import get_import_file_by_id
    import_file = get_import_file_by_id(db, import_file_id)
    if not import_file:
        raise HTTPException(status_code=404, detail="ملف الاستيراد غير موجود.")

    service.auto_close_completed_phase_tasks(db, import_file_id, completed_phase)

    return {
        "import_file_id": import_file_id,
        "completed_phase": completed_phase,
        "message": f"تم إغلاق جميع مهام المرحلة {completed_phase} تلقائياً.",
    }


@router.post(
    "/sync-all-active-files",
    summary="Synchronize and generate pending tasks for all active import files",
    response_model=dict,
)
def sync_all_active_files(db: Session = Depends(get_db)):
    count = service.sync_all_active_shipments_tasks(db)
    return {
        "processed_files_count": count,
        "message": f"تمت مزامنة وتوليد المهام الذكية لـ {count} ملف استيرادي نشط بنجاح.",
    }
