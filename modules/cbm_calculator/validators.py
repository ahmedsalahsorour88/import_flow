from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from modules.cbm_calculator.schemas import CBMItemCreate
from modules.projects.model import Project
from modules.purchase_orders.model import PurchaseOrder


class CBMValidator:

    @staticmethod
    def validate_items(items: list[CBMItemCreate]):
        if not items or len(items) == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="At least one package item is required for CBM calculation.",
            )
        for idx, item in enumerate(items):
            if item.quantity <= 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Item #{idx+1}: Quantity must be greater than zero.",
                )
            if item.length_cm <= 0 or item.width_cm <= 0 or item.height_cm <= 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Item #{idx+1}: Length, width, and height dimensions must be greater than zero cm.",
                )
            if item.gross_weight_per_unit_kg < 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Item #{idx+1}: Gross weight cannot be negative.",
                )

    @staticmethod
    def validate_fk_references(db: Session, project_id: int | None = None, po_id: int | None = None):
        if project_id is not None:
            project = db.query(Project).filter(Project.project_id == project_id).first()
            if not project:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Referenced Project ID #{project_id} does not exist.",
                )
        if po_id is not None:
            po = db.query(PurchaseOrder).filter(PurchaseOrder.po_id == po_id).first()
            if not po:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Referenced Purchase Order ID #{po_id} does not exist.",
                )
