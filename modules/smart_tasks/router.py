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
)
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
