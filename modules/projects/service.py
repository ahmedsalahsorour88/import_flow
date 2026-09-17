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

        # Compute financial commitments from active purchase orders
        from modules.purchase_orders.model import PurchaseOrder
        from sqlalchemy import func
        po_stats = self.db.query(
            func.coalesce(func.sum(PurchaseOrder.total_amount_fob), 0.0),
            func.count(PurchaseOrder.po_id)
        ).filter(
            PurchaseOrder.project_id == project.project_id,
            PurchaseOrder.is_active.is_(True)
        ).first()

        total_committed = round(float(po_stats[0]), 2) if po_stats else 0.0
        po_count = int(po_stats[1]) if po_stats else 0
        remaining_budget = None
        if project.total_budget_usd is not None:
            remaining_budget = round(float(project.total_budget_usd) - total_committed, 2)

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
            target_end_date=project.target_end_date,
            status=project.status,
            notes=project.notes,
            is_active=project.is_active,
            created_at=project.created_at,
            updated_at=project.updated_at,
            company_name=company_names_str,
            supplier_name=project.supplier.company_name if project.supplier else None,
            incoterm_code=project.incoterm.incoterm_code if project.incoterm else None,
            total_committed_usd=total_committed,
            po_count=po_count,
            remaining_budget_usd=remaining_budget,
        )

    def get_financial_commitments(self, project_id: int) -> dict:
        project = self.repo.get_by_id(project_id)
        if not project:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Project with ID {project_id} not found.",
            )
        from modules.purchase_orders.model import PurchaseOrder
        pos = self.db.query(PurchaseOrder).filter(
            PurchaseOrder.project_id == project_id,
            PurchaseOrder.is_active.is_(True)
        ).all()

        total_committed = sum(float(p.total_amount_fob or 0.0) for p in pos)
        total_cbm = sum(float(p.total_cbm or 0.0) for p in pos)
        total_gross_wt = sum(float(p.total_gross_weight_kg or 0.0) for p in pos)
        budget = float(project.total_budget_usd) if project.total_budget_usd is not None else None
        remaining = round(budget - total_committed, 2) if budget is not None else None
        budget_utilization_percent = round((total_committed / budget) * 100.0, 1) if (budget and budget > 0) else 0.0

        return {
            "project_id": project.project_id,
            "project_code": project.project_code,
            "project_name": project.project_name,
            "total_budget_usd": budget,
            "total_committed_usd": round(total_committed, 2),
            "remaining_budget_usd": remaining,
            "budget_utilization_percent": budget_utilization_percent,
            "po_count": len(pos),
            "total_cbm": round(total_cbm, 4),
            "total_gross_weight_kg": round(total_gross_wt, 2),
            "purchase_orders": [
                {
                    "po_id": p.po_id,
                    "po_number": p.po_number,
                    "po_reference": p.po_reference,
                    "status": p.status,
                    "total_amount_fob": float(p.total_amount_fob),
                    "total_cbm": float(p.total_cbm),
                    "total_gross_weight_kg": float(p.total_gross_weight_kg),
                    "import_file_id": p.import_file_id,
                    "order_date": p.order_date.isoformat() if p.order_date else None,
                }
                for p in pos
            ],
        }

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
