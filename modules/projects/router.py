from typing import List, Optional

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from database.database import get_db
from modules.projects.schemas import ProjectCreate, ProjectResponse, ProjectUpdate
from modules.projects.service import ProjectService

router = APIRouter(prefix="/api/v1/projects", tags=["Projects Module"])


@router.get("", response_model=List[ProjectResponse])
def get_all_projects(
    include_inactive: bool = Query(False, description="Include inactive projects"),
    status_filter: Optional[str] = Query(None, alias="status", description="Filter by status (Open, Closed, On Hold)"),
    company_id: Optional[int] = Query(None, description="Filter by Import Company ID"),
    supplier_id: Optional[int] = Query(None, description="Filter by Supplier ID"),
    search: Optional[str] = Query(None, description="Search by code, name or owner"),
    db: Session = Depends(get_db),
):
    service = ProjectService(db)
    return service.get_all(
        include_inactive=include_inactive,
        status_filter=status_filter,
        company_id=company_id,
        supplier_id=supplier_id,
        search=search,
    )


@router.get("/{project_id}", response_model=ProjectResponse)
def get_project_by_id(
    project_id: int,
    db: Session = Depends(get_db),
):
    service = ProjectService(db)
    return service.get_by_id(project_id)


@router.post("", response_model=ProjectResponse, status_code=status.HTTP_201_CREATED)
def create_project(
    data: ProjectCreate,
    db: Session = Depends(get_db),
):
    service = ProjectService(db)
    return service.create(data)


@router.put("/{project_id}", response_model=ProjectResponse)
def update_project(
    project_id: int,
    data: ProjectUpdate,
    db: Session = Depends(get_db),
):
    service = ProjectService(db)
    return service.update(project_id, data)


@router.delete("/{project_id}", response_model=ProjectResponse)
def soft_delete_project(
    project_id: int,
    db: Session = Depends(get_db),
):
    service = ProjectService(db)
    return service.soft_delete(project_id)


@router.post("/{project_id}/restore", response_model=ProjectResponse)
def restore_project(
    project_id: int,
    db: Session = Depends(get_db),
):
    service = ProjectService(db)
    return service.restore(project_id)
