from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from modules.projects.model import Project
from modules.projects.repository import ProjectRepository
from modules.projects.schemas import ProjectCreate, ProjectResponse, ProjectUpdate
from modules.projects.validators import ProjectValidator


class ProjectService:

    def __init__(self, db: Session):
        self.db = db
        self.repo = ProjectRepository(db)
        self.validator = ProjectValidator(db)

    def _to_response(self, project: Project) -> ProjectResponse:
        company_ids = [project.company_id]
        if project.additional_company_ids:
            try:
                extra_ids = [int(x.strip()) for x in project.additional_company_ids.split(",") if x.strip().isdigit()]
                company_ids.extend(extra_ids)
            except Exception:
                pass

        # Fetch names for all company IDs
        company_names = []
        if company_ids:
            from modules.import_companies.model import ImportCompany
            companies = self.db.query(ImportCompany).filter(ImportCompany.company_id.in_(company_ids)).all()
            comp_map = {c.company_id: c.importer_name for c in companies}
            company_names = [comp_map[cid] for cid in company_ids if cid in comp_map]

        company_names_str = ", ".join(company_names) if company_names else (project.company.importer_name if project.company else None)

        return ProjectResponse(
            project_id=project.project_id,
            project_code=project.project_code,
            project_name=project.project_name,
            project_owner=project.project_owner,
            company_id=project.company_id,
            company_ids=company_ids,
            supplier_id=project.supplier_id,
            incoterm_id=project.incoterm_id,
            import_type=project.import_type,
            priority=project.priority,
            shipment_category=project.shipment_category,
            allow_multi_shipment=project.allow_multi_shipment,
            allow_multi_company=project.allow_multi_company,
            total_budget_usd=float(project.total_budget_usd) if project.total_budget_usd is not None else None,
            status=project.status,
            notes=project.notes,
            is_active=project.is_active,
            created_at=project.created_at,
            updated_at=project.updated_at,
            company_name=company_names_str,
            supplier_name=project.supplier.company_name if project.supplier else None,
            incoterm_code=project.incoterm.incoterm_code if project.incoterm else None,
        )

    def get_all(
        self,
        include_inactive: bool = False,
        status_filter: Optional[str] = None,
        company_id: Optional[int] = None,
        supplier_id: Optional[int] = None,
        search: Optional[str] = None,
    ) -> List[ProjectResponse]:
        projects = self.repo.get_all(
            include_inactive=include_inactive,
            status_filter=status_filter,
            company_id=company_id,
            supplier_id=supplier_id,
            search=search,
        )
        return [self._to_response(p) for p in projects]

    def get_by_id(self, project_id: int) -> ProjectResponse:
        project = self.repo.get_by_id(project_id)
        if not project:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Project with ID {project_id} not found.",
            )
        return self._to_response(project)

    def create(self, data: ProjectCreate) -> ProjectResponse:
        if data.project_code:
            self.validator.validate_unique_code(data.project_code)
        self.validator.validate_foreign_keys(data.company_id, data.supplier_id, data.incoterm_id)
        project = self.repo.create(data)
        return self._to_response(project)

    def update(self, project_id: int, data: ProjectUpdate) -> ProjectResponse:
        project = self.repo.get_by_id(project_id)
        if not project:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Project with ID {project_id} not found.",
            )

        if data.company_id or data.supplier_id or data.incoterm_id:
            c_id = data.company_id or project.company_id
            s_id = data.supplier_id or project.supplier_id
            i_id = data.incoterm_id or project.incoterm_id
            self.validator.validate_foreign_keys(c_id, s_id, i_id)

        updated = self.repo.update(project, data)
        return self._to_response(updated)

    def soft_delete(self, project_id: int) -> ProjectResponse:
        project = self.repo.get_by_id(project_id)
        if not project:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Project with ID {project_id} not found.",
            )
        deleted = self.repo.soft_delete(project)
        return self._to_response(deleted)

    def restore(self, project_id: int) -> ProjectResponse:
        project = self.repo.get_by_id(project_id)
        if not project:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Project with ID {project_id} not found.",
            )
        restored = self.repo.restore(project)
        return self._to_response(restored)
