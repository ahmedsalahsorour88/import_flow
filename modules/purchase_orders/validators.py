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

    def validate_foreign_keys(
        self,
        project_id: int,
        company_id: int,
        supplier_id: int,
        incoterm_id: int,
        currency_id: int,
        import_file_id: int = None,
    ):
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

        if import_file_id is not None:
            from modules.import_files.model import ImportFile
            import_file = self.db.query(ImportFile).filter(
                ImportFile.import_file_id == import_file_id,
                ImportFile.is_active.is_(True),
            ).first()
            if not import_file:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Import File with ID {import_file_id} not found or inactive.",
                )

    def validate_line_items(self, items):
        for idx, item in enumerate(items, start=1):
            if item.quantity is not None and item.quantity <= 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Item #{idx}: Quantity must be greater than zero.",
                )
            if item.unit_price is not None and item.unit_price < 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Item #{idx}: Unit price cannot be negative.",
                )
            if getattr(item, "tariff_id", None) is not None:
                from modules.customs_tariff.model import CustomsTariff
                tariff = self.db.query(CustomsTariff).filter(
                    CustomsTariff.tariff_id == item.tariff_id,
                    CustomsTariff.is_active.is_(True),
                ).first()
                if not tariff:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Item #{idx}: Tariff with ID {item.tariff_id} not found or inactive.",
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
