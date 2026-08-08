from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from modules.import_companies.model import ImportCompany
from modules.incoterms.model import Incoterm
from modules.projects.repository import ProjectRepository
from modules.suppliers.model import Supplier


class ProjectValidator:

    def __init__(self, db: Session):
        self.db = db
        self.repo = ProjectRepository(db)

    def validate_unique_code(self, project_code: str, exclude_id: Optional[int] = None):
        existing = self.repo.get_by_code(project_code)
        if existing and (exclude_id is None or existing.project_id != exclude_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Project with code '{project_code.upper()}' already exists.",
            )

    def validate_foreign_keys(self, company_id: int, supplier_id: int, incoterm_id: int):
        company = self.db.query(ImportCompany).filter(ImportCompany.company_id == company_id, ImportCompany.is_active.is_(True)).first()
        if not company:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Active Import Company with ID {company_id} does not exist.",
            )

        supplier = self.db.query(Supplier).filter(Supplier.supplier_id == supplier_id, Supplier.is_active.is_(True)).first()
        if not supplier:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Active Supplier with ID {supplier_id} does not exist.",
            )

        incoterm = self.db.query(Incoterm).filter(Incoterm.incoterm_id == incoterm_id, Incoterm.is_active.is_(True)).first()
        if not incoterm:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Active Incoterm with ID {incoterm_id} does not exist.",
            )
