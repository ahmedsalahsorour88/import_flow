"""
Database Repository for Financial & Management Approval (BP-012 & BP-013)
"""

from datetime import datetime, date, timezone
from sqlalchemy.orm import Session
from sqlalchemy import func
from modules.financial_approval.model import PaymentRequestSession, ImportBudgetApproval
from modules.financial_approval.schemas import (
    PaymentRequestCreate,
    PaymentRequestUpdate,
    ImportBudgetCreate,
    ImportBudgetUpdate,
)


# --- PAYMENT REQUEST REPOSITORY ---
def generate_payment_code(db: Session) -> str:
    """Generates unique Payment Request Code in format PAY-YYYY-XXX."""
    current_year = datetime.now(timezone.utc).year
    prefix = f"PAY-{current_year}-"

    last_record = (
        db.query(PaymentRequestSession)
        .filter(PaymentRequestSession.payment_code.like(f"{prefix}%"))
        .order_by(PaymentRequestSession.payment_id.desc())
        .first()
    )

    if not last_record:
        return f"{prefix}001"

    last_code = last_record.payment_code
    try:
        sequence_num = int(last_code.split("-")[-1])
        new_seq = sequence_num + 1
    except (ValueError, IndexError):
        new_seq = 1

    return f"{prefix}{new_seq:03d}"


def create_payment_request(db: Session, schema: PaymentRequestCreate) -> PaymentRequestSession:
    code = generate_payment_code(db)
    req_date = schema.request_date or date.today()
    egp_amount = schema.requested_amount * schema.exchange_rate

    db_item = PaymentRequestSession(
        payment_code=code,
        title=schema.title,
        import_file_id=schema.import_file_id,
        po_id=schema.po_id,
        supplier_id=schema.supplier_id,
        supplier_name=schema.supplier_name,
        project_id=schema.project_id,
        payment_type=schema.payment_type,
        requested_amount=schema.requested_amount,
        currency_code=schema.currency_code,
        exchange_rate=schema.exchange_rate,
        requested_amount_egp=egp_amount,
        due_date=schema.due_date,
        request_date=req_date,
        status="Draft",
        beneficiary_name=schema.beneficiary_name,
        bank_name=schema.bank_name,
        swift_code=schema.swift_code,
        iban_account_no=schema.iban_account_no,
        bank_country=schema.bank_country,
        notes=schema.notes,
        is_active=True,
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item


def get_payment_request_by_id(db: Session, payment_id: int) -> PaymentRequestSession | None:
    return (
        db.query(PaymentRequestSession)
        .filter(PaymentRequestSession.payment_id == payment_id, PaymentRequestSession.is_active == True)
        .first()
    )


def get_all_payment_requests(
    db: Session,
    include_inactive: bool = False,
    search: str | None = None,
    import_file_id: int | None = None,
    po_id: int | None = None,
    supplier_id: int | None = None,
    status: str | None = None,
) -> list[PaymentRequestSession]:
    query = db.query(PaymentRequestSession)
    if not include_inactive:
        query = query.filter(PaymentRequestSession.is_active == True)

    if import_file_id:
        query = query.filter(PaymentRequestSession.import_file_id == import_file_id)
    if po_id:
        query = query.filter(PaymentRequestSession.po_id == po_id)
    if supplier_id:
        query = query.filter(PaymentRequestSession.supplier_id == supplier_id)
    if status and status != "All":
        query = query.filter(PaymentRequestSession.status == status)

    if search:
        search_pattern = f"%{search}%"
        query = query.filter(
            PaymentRequestSession.payment_code.ilike(search_pattern)
            | PaymentRequestSession.title.ilike(search_pattern)
            | PaymentRequestSession.supplier_name.ilike(search_pattern)
        )

    return query.order_by(PaymentRequestSession.payment_id.desc()).all()


def update_payment_request(
    db: Session, db_item: PaymentRequestSession, schema: PaymentRequestUpdate
) -> PaymentRequestSession:
    update_data = schema.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_item, field, value)

    # Recalculate EGP if amount or rate changed
    db_item.requested_amount_egp = db_item.requested_amount * db_item.exchange_rate
    db_item.updated_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(db_item)
    return db_item


def soft_delete_payment_request(db: Session, payment_id: int) -> bool:
    item = get_payment_request_by_id(db, payment_id)
    if not item:
        return False
    item.is_active = False
    item.updated_at = datetime.now(timezone.utc)
    db.commit()
    return True


def restore_payment_request(db: Session, payment_id: int) -> bool:
    item = (
        db.query(PaymentRequestSession)
        .filter(PaymentRequestSession.payment_id == payment_id, PaymentRequestSession.is_active == False)
        .first()
    )
    if not item:
        return False
    item.is_active = True
    item.updated_at = datetime.now(timezone.utc)
    db.commit()
    return True


# --- IMPORT BUDGET REPOSITORY ---
def generate_budget_code(db: Session) -> str:
    """Generates unique Budget Code in format BGT-YYYY-XXX."""
    current_year = datetime.now(timezone.utc).year
    prefix = f"BGT-{current_year}-"

    last_record = (
        db.query(ImportBudgetApproval)
        .filter(ImportBudgetApproval.budget_code.like(f"{prefix}%"))
        .order_by(ImportBudgetApproval.budget_id.desc())
        .first()
    )

    if not last_record:
        return f"{prefix}001"

    last_code = last_record.budget_code
    try:
        sequence_num = int(last_code.split("-")[-1])
        new_seq = sequence_num + 1
    except (ValueError, IndexError):
        new_seq = 1

    return f"{prefix}{new_seq:03d}"


def create_import_budget(db: Session, schema: ImportBudgetCreate) -> ImportBudgetApproval:
    code = generate_budget_code(db)
    total_budget = (
        schema.invoice_amount_egp
        + schema.freight_cost_egp
        + schema.customs_duties_egp
        + schema.clearance_inland_egp
    )

    db_item = ImportBudgetApproval(
        budget_code=code,
        title=schema.title,
        import_file_id=schema.import_file_id,
        po_id=schema.po_id,
        project_id=schema.project_id,
        invoice_amount_egp=schema.invoice_amount_egp,
        freight_cost_egp=schema.freight_cost_egp,
        customs_duties_egp=schema.customs_duties_egp,
        clearance_inland_egp=schema.clearance_inland_egp,
        total_budget_egp=total_budget,
        budget_status="Pending Review",
        notes=schema.notes,
        is_active=True,
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item


def get_import_budget_by_id(db: Session, budget_id: int) -> ImportBudgetApproval | None:
    return (
        db.query(ImportBudgetApproval)
        .filter(ImportBudgetApproval.budget_id == budget_id, ImportBudgetApproval.is_active == True)
        .first()
    )


def get_all_import_budgets(
    db: Session,
    include_inactive: bool = False,
    search: str | None = None,
    import_file_id: int | None = None,
    po_id: int | None = None,
    budget_status: str | None = None,
) -> list[ImportBudgetApproval]:
    query = db.query(ImportBudgetApproval)
    if not include_inactive:
        query = query.filter(ImportBudgetApproval.is_active == True)

    if import_file_id:
        query = query.filter(ImportBudgetApproval.import_file_id == import_file_id)

    if po_id:
        query = query.filter(ImportBudgetApproval.po_id == po_id)
    if budget_status and budget_status != "All":
        query = query.filter(ImportBudgetApproval.budget_status == budget_status)

    if search:
        search_pattern = f"%{search}%"
        query = query.filter(
            ImportBudgetApproval.budget_code.ilike(search_pattern)
            | ImportBudgetApproval.title.ilike(search_pattern)
        )

    return query.order_by(ImportBudgetApproval.budget_id.desc()).all()


def update_import_budget(
    db: Session, db_item: ImportBudgetApproval, schema: ImportBudgetUpdate
) -> ImportBudgetApproval:
    update_data = schema.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_item, field, value)

    db_item.total_budget_egp = (
        db_item.invoice_amount_egp
        + db_item.freight_cost_egp
        + db_item.customs_duties_egp
        + db_item.clearance_inland_egp
    )

    if schema.budget_status == "Budget Approved" and not db_item.approved_date:
        db_item.approved_date = date.today()

    db_item.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(db_item)
    return db_item
