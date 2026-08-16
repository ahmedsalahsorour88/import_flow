"""
Service Layer & Business Engine for Financial Approval (BP-012 & BP-013)
"""

from datetime import date
from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from modules.financial_approval.model import PaymentRequestSession, ImportBudgetApproval
from modules.financial_approval.schemas import (
    PaymentRequestCreate,
    PaymentRequestUpdate,
    SwiftReconciliationRequest,
    ImportBudgetCreate,
    ImportBudgetUpdate,
    BudgetPrefillResponse,
    LinkedPOItemSchema,
)
import modules.financial_approval.repository as repo
from modules.financial_approval.validators import (
    validate_payment_request_inputs,
    validate_status_transition,
)


def create_payment_request_service(
    db: Session, schema: PaymentRequestCreate
) -> PaymentRequestSession:
    """Service to validate and create Payment Request with duplicate prevention."""
    validate_payment_request_inputs(
        db=db,
        requested_amount=schema.requested_amount,
        po_id=schema.po_id,
        supplier_id=schema.supplier_id,
    )

    if schema.import_file_id:
        existing = repo.get_all_payment_requests(db, import_file_id=schema.import_file_id)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="يوجد بالفعل طلب سداد مالي محفوظ لهذا الملف. يرجى الذهاب لتعديل الطلب الحالي بدلاً من إنشاء طلب جديد.",
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
        if db_item.import_file_id:
            from modules.import_files.model import ImportFile
            imp = db.query(ImportFile).filter(ImportFile.import_file_id == db_item.import_file_id).first()
            if imp:
                imp.swift_no = swift_reference_no

    db.commit()
    db.refresh(db_item)
    return db_item


def reconcile_swift_service(
    db: Session, payment_id: int, payload: SwiftReconciliationRequest
) -> PaymentRequestSession:
    """
    Reconciles SWIFT Confirmation against Payment Request:
    - Calculates turnaround days between request_date and swift_receipt_date.
    - Compares swift_transferred_amount against requested_amount.
    - Calculates variance (swift_transferred_amount - requested_amount).
    - Determines variance status: 'Matched' (diff == 0), 'Deficit' (diff < 0), 'Surplus' (diff > 0).
    - Automatically updates linked Import File's `swift_no` in import_files table.
    - Sets Payment Request status to 'Paid'.
    """
    from modules.import_files.model import ImportFile

    db_item = repo.get_payment_request_by_id(db, payment_id)
    if not db_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Payment Request ID {payment_id} not found.",
        )

    # 1. Processing turnaround days
    req_date = db_item.request_date or date.today()
    receipt_date = payload.swift_receipt_date
    processing_days = max(0, (receipt_date - req_date).days)

    # 2. Variance calculation
    variance = round(payload.swift_transferred_amount - db_item.requested_amount, 2)
    if abs(variance) < 0.001:
        variance_status = "Matched"
    elif variance < 0:
        variance_status = "Deficit"
    else:
        variance_status = "Surplus"

    # 3. Update payment request session
    db_item.swift_reference_no = payload.swift_reference_no
    db_item.swift_receipt_date = payload.swift_receipt_date
    db_item.swift_transferred_amount = payload.swift_transferred_amount
    db_item.swift_transferred_currency = payload.swift_transferred_currency
    db_item.swift_variance_amount = variance
    db_item.swift_variance_status = variance_status
    db_item.swift_processing_days = processing_days
    db_item.swift_reconciliation_notes = payload.swift_reconciliation_notes
    db_item.status = "Paid"

    # 4. Automatically sync swift_no to linked Import File
    if db_item.import_file_id:
        imp = db.query(ImportFile).filter(ImportFile.import_file_id == db_item.import_file_id).first()
        if imp:
            imp.swift_no = payload.swift_reference_no

    db.commit()
    db.refresh(db_item)
    return db_item


# --- IMPORT BUDGET SERVICE ---
def create_import_budget_service(
    db: Session, schema: ImportBudgetCreate
) -> ImportBudgetApproval:
    """Creates import budget approval with duplicate prevention."""
    if schema.import_file_id:
        existing = repo.get_all_import_budgets(db, import_file_id=schema.import_file_id)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="يوجد بالفعل اعتماد ميزانية محفوظ لهذا الملف. يرجى الذهاب لتعديل الميزانية الحالية بدلاً من إنشاء اعتماد جديد.",
            )

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


# --- CROSS-MODULE PREFILL & AGGREGATOR ENGINE ---
def get_budget_prefill_service(
    db: Session, import_file_id: int
) -> BudgetPrefillResponse:
    """
    Cross-module aggregation engine for Payment Requests and Budget Approval.
    Pulls data from:
    1. Import Files & Linked Purchase Orders (Invoice Amounts & Payment Terms)
    2. Foreign Supplier Master Data (Bank Details, SWIFT, Account No, IBAN)
    3. Shipping Scenarios (Highest Estimated Freight Rate)
    4. Customs Consultation Engine (Estimated Customs Duty, VAT, & Broker Fees)
    """
    from modules.import_files.model import ImportFile
    from modules.purchase_orders.model import PurchaseOrder
    from modules.shipping_scenarios.model import ShippingEvaluationSession
    from modules.customs_consultation.model import CustomsConsultationSession
    from modules.suppliers.model import Supplier
    from modules.projects.model import Project

    imp = db.query(ImportFile).filter(ImportFile.import_file_id == import_file_id).first()
    if not imp:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Import File with ID {import_file_id} not found.",
        )

    # 1. Fetch Linked Purchase Orders
    po_query = db.query(PurchaseOrder).filter(PurchaseOrder.is_active == True)
    if imp.po_ids and isinstance(imp.po_ids, list):
        pos = po_query.filter(
            (PurchaseOrder.import_file_id == import_file_id) | (PurchaseOrder.po_id.in_(imp.po_ids))
        ).all()
    else:
        pos = po_query.filter(PurchaseOrder.import_file_id == import_file_id).all()

    linked_pos_schemas: List[LinkedPOItemSchema] = []
    total_invoice = 0.0
    invoice_curr = "USD"
    payment_terms_set = set()
    terms_list_str = []

    from modules.currencies.model import Currency

    for po in pos:
        prj_name = None
        if po.project_id:
            prj = db.query(Project).filter(Project.project_id == po.project_id).first()
            if prj:
                prj_name = prj.project_name

        p_term = po.payment_terms or "Standard Payment"
        payment_terms_set.add(p_term)
        terms_list_str.append(f"{po.po_number} ({p_term})")
        
        curr_code = "USD"
        if po.currency_id:
            curr_obj = db.query(Currency).filter(Currency.currency_id == po.currency_id).first()
            if curr_obj:
                curr_code = curr_obj.currency_code
                invoice_curr = curr_code

        po_amt = float(po.total_amount_fob or 0.0)
        if po_amt == 0.0 and po.items:
            po_amt = sum(float(it.quantity or 0.0) * float(it.unit_price or 0.0) for it in po.items)
            
        total_invoice += po_amt

        linked_pos_schemas.append(
            LinkedPOItemSchema(
                po_id=po.po_id,
                po_number=po.po_number,
                pi_number=po.proforma_invoice_number,
                project_id=po.project_id,
                project_name=prj_name,
                payment_terms=p_term,
                currency=curr_code,
                total_amount=po_amt,
                status=po.status,
            )
        )

    # If no purchase orders linked yet or total is 0, check invoices_data recorded in ImportFile
    if total_invoice == 0.0 and imp.invoices_data and isinstance(imp.invoices_data, list):
        for inv in imp.invoices_data:
            if isinstance(inv, dict):
                amt = float(inv.get("amount", 0.0) or 0.0)
                if amt > 0:
                    total_invoice += amt
                    if inv.get("currency"):
                        invoice_curr = inv["currency"]

    # If still 0, fallback to estimated_cost on import_file
    if total_invoice == 0.0 and imp.estimated_cost:
        total_invoice = float(imp.estimated_cost or 0.0)
        if imp.estimated_cost_currency:
            invoice_curr = imp.estimated_cost_currency

    if len(payment_terms_set) == 1:
        payment_terms_summary = next(iter(payment_terms_set))
    elif len(payment_terms_set) > 1:
        payment_terms_summary = f"متعدد ({', '.join(terms_list_str)})"
    else:
        payment_terms_summary = "Advance Payment"

    # 2. Supplier and Banking Info
    sup = None
    if imp.supplier_id:
        sup = db.query(Supplier).filter(Supplier.supplier_id == imp.supplier_id).first()
    elif pos and pos[0].supplier_id:
        sup = db.query(Supplier).filter(Supplier.supplier_id == pos[0].supplier_id).first()
    elif imp.supplier_name:
        sup = db.query(Supplier).filter(Supplier.company_name == imp.supplier_name).first()

    supplier_name = sup.company_name if sup else (imp.supplier_name or "Foreign Exporter")
    bank_name = sup.bank_name if sup else None
    swift_code = sup.swift_code if sup else None
    account_no = sup.account_number if sup else None
    iban = sup.iban if sup else None

    # 3. Estimated Freight: Always retrieve highest / maximum freight rate across all options
    po_ids = [p.po_id for p in pos]
    shipping_sessions = db.query(ShippingEvaluationSession).filter(
        (ShippingEvaluationSession.import_file_id == import_file_id) |
        (ShippingEvaluationSession.po_id.in_(po_ids) if po_ids else False),
        ShippingEvaluationSession.is_active == True,
    ).all()

    highest_freight = 0.0
    freight_currency = "USD"

    for s in shipping_sessions:
        for itm in s.items:
            f_amt = float(getattr(itm, "total_quotation_amount", 0.0) or 0.0)
            if f_amt == 0.0:
                c40 = (itm.container_40ft_price or 0.0) * (itm.container_40ft_qty or 1) if itm.container_40ft_applicable else 0.0
                c20 = (itm.container_20ft_price or 0.0) * (itm.container_20ft_qty or 1) if itm.container_20ft_applicable else 0.0
                lcl = (itm.lcl_cbm_price or 0.0) * (itm.lcl_cbm_qty or 1) if itm.lcl_cbm_applicable else 0.0
                f_amt = c40 + c20 + lcl

            curr = getattr(itm, "quotation_currency", None) or "USD"
            if f_amt > highest_freight:
                highest_freight = f_amt
                freight_currency = curr

    # 4. Customs Taxes and Broker Clearance from Customs Consultation
    customs_query = db.query(CustomsConsultationSession).filter(
        CustomsConsultationSession.is_active == True,
    )
    if po_ids:
        customs_sessions = customs_query.filter(
            (CustomsConsultationSession.import_file_id == import_file_id) |
            (CustomsConsultationSession.po_id.in_(po_ids))
        ).all()
    else:
        customs_sessions = customs_query.filter(
            CustomsConsultationSession.import_file_id == import_file_id
        ).all()

    estimated_duties_egp = 0.0
    estimated_clearance_fees_egp = 0.0
    for cs in customs_sessions:
        d_amt = float(cs.estimated_duties_egp or 0.0)
        c_amt = float(cs.total_broker_fees_egp or 0.0)
        if d_amt > 0:
            estimated_duties_egp = max(estimated_duties_egp, d_amt)
        if c_amt > 0:
            estimated_clearance_fees_egp = max(estimated_clearance_fees_egp, c_amt)

    # 5. Fetch Dynamic Exchange Rates from Currencies Master & Rates History
    from modules.currencies.repository import CurrencyRepository

    curr_repo = CurrencyRepository(db)
    currency_obj = curr_repo.get_currency_by_code(invoice_curr or "USD")
    exchange_rate = 50.0
    if currency_obj:
        if currency_obj.is_base_currency:
            exchange_rate = 1.0
        else:
            latest_rate = curr_repo.get_latest_rate(currency_obj.currency_id, target_date=date.today())
            if latest_rate and latest_rate.commercial_rate:
                exchange_rate = float(latest_rate.commercial_rate)

    # Freight Exchange Rate
    freight_exchange_rate = 50.0
    if freight_currency.upper() == "EGP":
        freight_exchange_rate = 1.0
    else:
        f_curr_obj = curr_repo.get_currency_by_code(freight_currency or "USD")
        if f_curr_obj:
            if f_curr_obj.is_base_currency:
                freight_exchange_rate = 1.0
            else:
                latest_f_rate = curr_repo.get_latest_rate(f_curr_obj.currency_id, target_date=date.today())
                if latest_f_rate and latest_f_rate.commercial_rate:
                    freight_exchange_rate = float(latest_f_rate.commercial_rate)

    total_invoice_egp = total_invoice * exchange_rate
    estimated_freight_egp = highest_freight * freight_exchange_rate
    grand_total_egp = total_invoice_egp + estimated_freight_egp + estimated_duties_egp + estimated_clearance_fees_egp

    incoterm_str = imp.incoterm_code or "FOB"
    file_code_str = imp.import_file_code or f"IMP-{imp.import_file_id}"
    file_title_str = f"شحنة {file_code_str}"

    return BudgetPrefillResponse(
        import_file_id=imp.import_file_id,
        import_file_code=file_code_str,
        import_file_title=file_title_str,
        incoterm=incoterm_str,
        supplier_id=sup.supplier_id if sup else None,
        supplier_name=supplier_name,
        beneficiary_name=supplier_name,
        bank_name=bank_name,
        swift_code=swift_code,
        account_number=account_no,
        iban=iban,
        payment_terms_summary=payment_terms_summary,
        linked_pos=linked_pos_schemas,
        total_invoice_amount=total_invoice,
        invoice_currency=invoice_curr,
        total_invoice_amount_egp=total_invoice_egp,
        estimated_freight_cost=highest_freight,
        freight_currency=freight_currency,
        estimated_freight_cost_egp=estimated_freight_egp,
        estimated_customs_duties_egp=estimated_duties_egp,
        estimated_clearance_fees_egp=estimated_clearance_fees_egp,
        estimated_grand_total_egp=grand_total_egp,
        exchange_rate=exchange_rate,
    )
