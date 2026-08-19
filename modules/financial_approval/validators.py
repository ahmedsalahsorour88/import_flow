"""
Business Validation Rules for Financial Approval (BP-012 & BP-013)
"""

from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from modules.suppliers.model import Supplier
from modules.purchase_orders.model import PurchaseOrder


def validate_payment_request_inputs(
    db: Session,
    requested_amount: float,
    po_id: int | None = None,
    supplier_id: int | None = None,
):
    """
    Validates payment request creation logic:
    - requested_amount must be > 0.
    - Supplier must exist if supplier_id is specified.
    - Purchase Order must exist if po_id is specified.
    """
    if requested_amount <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Requested amount must be greater than zero.",
        )

    if supplier_id:
        sup = (
            db.query(Supplier)
            .filter(Supplier.supplier_id == supplier_id, Supplier.is_active == True)
            .first()
        )
        if not sup:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Supplier ID {supplier_id} not found or inactive.",
            )

    if po_id:
        po = (
            db.query(PurchaseOrder)
            .filter(
                PurchaseOrder.po_id == po_id,
                PurchaseOrder.is_active == True,
            )
            .first()
        )
        if not po:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Purchase Order ID {po_id} not found or inactive.",
            )


def validate_status_transition(current_status: str, new_status: str):
    """
    Validates lifecycle status changes for payment requests:
    Draft -> Pending Approval -> Approved -> Paid / Rejected
    """
    if current_status == new_status:
        return

    allowed_transitions = {
        "Draft": {"Pending Approval", "Rejected"},
        "Pending Approval": {"Approved", "Rejected", "Draft"},
        "Approved": {"Paid", "Rejected"},
        "Paid": set(),  # Terminal state: cannot be moved back to draft or pending
        "Rejected": {"Draft"},  # Can be re-opened into Draft
    }

    if current_status not in allowed_transitions:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Current status '{current_status}' is invalid.",
        )

    valid_targets = allowed_transitions[current_status]
    if new_status not in valid_targets:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot transition payment request status from '{current_status}' to '{new_status}'. Allowed transitions: {sorted(list(valid_targets)) if valid_targets else 'None (Terminal state)'}",
        )
