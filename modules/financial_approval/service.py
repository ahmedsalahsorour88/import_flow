"""
Service Layer & Business Engine for Financial Approval (BP-012 & BP-013)
"""

from datetime import date
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from modules.financial_approval.model import PaymentRequestSession, ImportBudgetApproval
from modules.financial_approval.schemas import (
    PaymentRequestCreate,
    PaymentRequestUpdate,
    ImportBudgetCreate,
    ImportBudgetUpdate,
)
import modules.financial_approval.repository as repo
from modules.financial_approval.validators import (
    validate_payment_request_inputs,
    validate_status_transition,
)


def create_payment_request_service(
    db: Session, schema: PaymentRequestCreate
) -> PaymentRequestSession:
    """Service to validate and create Payment Request."""
    validate_payment_request_inputs(
        db=db,
        requested_amount=schema.requested_amount,
        po_id=schema.po_id,
        supplier_id=schema.supplier_id,
    )
    return repo.create_payment_request(db, schema)


def update_payment_request_service(
    db: Session, payment_id: int, schema: PaymentRequestUpdate
) -> PaymentRequestSession:
    db_item = repo.get_payment_request_by_id(db, payment_id)
    if not db_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Payment Request ID {payment_id} not found.",
        )

    if schema.status and schema.status != db_item.status:
        validate_status_transition(db_item.status, schema.status)

    return repo.update_payment_request(db, db_item, schema)


def approve_payment_request_service(
    db: Session, payment_id: int
) -> PaymentRequestSession:
    """Approves a payment request."""
    db_item = repo.get_payment_request_by_id(db, payment_id)
    if not db_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Payment Request ID {payment_id} not found.",
        )

    db_item.status = "Approved"
    db.commit()
    db.refresh(db_item)
    return db_item


def execute_payment_service(
    db: Session, payment_id: int, swift_reference_no: str | None = None
) -> PaymentRequestSession:
    """Marks payment request as Paid once SWIFT transfer copy is generated."""
    db_item = repo.get_payment_request_by_id(db, payment_id)
    if not db_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Payment Request ID {payment_id} not found.",
        )

    db_item.status = "Paid"
    if swift_reference_no:
        db_item.swift_reference_no = swift_reference_no

    db.commit()
    db.refresh(db_item)
    return db_item


# --- IMPORT BUDGET SERVICE ---
def create_import_budget_service(
    db: Session, schema: ImportBudgetCreate
) -> ImportBudgetApproval:
    return repo.create_import_budget(db, schema)


def approve_import_budget_service(
    db: Session, budget_id: int, approved_by: str = "Finance Manager"
) -> ImportBudgetApproval:
    db_item = repo.get_import_budget_by_id(db, budget_id)
    if not db_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Import Budget ID {budget_id} not found.",
        )

    db_item.budget_status = "Budget Approved"
    db_item.approved_by = approved_by
    db_item.approved_date = date.today()
    db.commit()
    db.refresh(db_item)
    return db_item
