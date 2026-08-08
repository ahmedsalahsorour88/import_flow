from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from modules.currencies.model import Currency
from modules.import_companies.model import ImportCompany
from modules.incoterms.model import Incoterm
from modules.projects.model import Project
from modules.purchase_orders.model import PurchaseOrder
from modules.suppliers.model import Supplier


class PurchaseOrderValidator:

    def __init__(self, db: Session):
        self.db = db

    def validate_foreign_keys(self, project_id: int, company_id: int, supplier_id: int, incoterm_id: int, currency_id: int):
        project = self.db.query(Project).filter(Project.project_id == project_id, Project.is_active.is_(True)).first()
        if not project:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Project with ID {project_id} not found or inactive.",
            )

        company = self.db.query(ImportCompany).filter(ImportCompany.company_id == company_id, ImportCompany.is_active.is_(True)).first()
        if not company:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Import Company with ID {company_id} not found or inactive.",
            )

        supplier = self.db.query(Supplier).filter(Supplier.supplier_id == supplier_id, Supplier.is_active.is_(True)).first()
        if not supplier:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Supplier with ID {supplier_id} not found or inactive.",
            )

        incoterm = self.db.query(Incoterm).filter(Incoterm.incoterm_id == incoterm_id, Incoterm.is_active.is_(True)).first()
        if not incoterm:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Incoterm with ID {incoterm_id} not found or inactive.",
            )

        currency = self.db.query(Currency).filter(Currency.currency_id == currency_id, Currency.is_active.is_(True)).first()
        if not currency:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Currency with ID {currency_id} not found or inactive.",
            )

    def validate_po_number_unique(self, po_number: str, exclude_id: int = None):
        pattern = po_number.upper().strip()
        query = self.db.query(PurchaseOrder).filter(PurchaseOrder.po_number == pattern)
        if exclude_id:
            query = query.filter(PurchaseOrder.po_id != exclude_id)
        if query.first():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Purchase Order Number '{po_number}' already exists.",
            )
