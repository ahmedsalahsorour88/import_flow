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
    SmartSwiftExtractRequest,
    SmartSwiftExtractResponse,
    SmartSwiftReconcileRequest,
)
import modules.financial_approval.repository as repo
from modules.financial_approval.validators import (
    validate_payment_request_inputs,
    validate_status_transition,
)


def create_payment_request_service(
    db: Session, schema: PaymentRequestCreate
) -> PaymentRequestSession:
    """Service to validate and create Payment Request with duplicate prevention per payment type."""
    validate_payment_request_inputs(
        db=db,
        requested_amount=schema.requested_amount,
        po_id=schema.po_id,
        supplier_id=schema.supplier_id,
    )

    if schema.import_file_id:
        existing = repo.get_all_payment_requests(db, import_file_id=schema.import_file_id)
        # Prevent active duplicate of the same payment type for the same import file
        active_same_type = [
            p for p in existing
            if p.is_active and p.payment_type == schema.payment_type and p.status in ("Draft", "Pending Approval", "Approved")
        ]
        if active_same_type:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"يوجد بالفعل طلب سداد مالي قيد الإجراء من نوع '{schema.payment_type}' محفوظ لهذا الملف ({active_same_type[0].payment_code}). يرجى الذهاب لتعديله أو استخدام نوع سداد آخر.",
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
    if abs(variance) < 0.01:
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

def get_all_payment_requests_service(db: Session, include_inactive: bool = False, search: Optional[str] = None, po_id: Optional[int] = None, supplier_id: Optional[int] = None, status: Optional[str] = None) -> List[PaymentRequestSession]:
    return repo.get_all_payment_requests(db, include_inactive=include_inactive, search=search, po_id=po_id, supplier_id=supplier_id, status=status)

def get_payment_request_by_id_service(db: Session, payment_id: int) -> Optional[PaymentRequestSession]:
    return repo.get_payment_request_by_id(db, payment_id)

def soft_delete_payment_request_service(db: Session, payment_id: int) -> bool:
    return repo.soft_delete_payment_request(db, payment_id)

def restore_payment_request_service(db: Session, payment_id: int) -> bool:
    return repo.restore_payment_request(db, payment_id)

def get_all_import_budgets_service(db: Session, include_inactive: bool = False, search: Optional[str] = None, import_file_id: Optional[int] = None, po_id: Optional[int] = None, budget_status: Optional[str] = None) -> List[ImportBudgetApproval]:
    return repo.get_all_import_budgets(db, include_inactive=include_inactive, search=search, import_file_id=import_file_id, po_id=po_id, budget_status=budget_status)

def get_import_budget_by_id_service(db: Session, budget_id: int) -> Optional[ImportBudgetApproval]:
    return repo.get_import_budget_by_id(db, budget_id)

def update_import_budget_service(db: Session, budget_id: int, schema: ImportBudgetUpdate) -> ImportBudgetApproval:
    db_item = repo.get_import_budget_by_id(db, budget_id)
    if not db_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Import Budget ID {budget_id} not found.",
        )
    return repo.update_import_budget(db, db_item, schema)

def soft_delete_import_budget_service(db: Session, budget_id: int) -> bool:
    return repo.soft_delete_import_budget(db, budget_id)

def restore_import_budget_service(db: Session, budget_id: int) -> bool:
    return repo.restore_import_budget(db, budget_id)


# --- SMART AI SWIFT MT103 EXTRACTION & RECONCILIATION SERVICES ---
def smart_extract_swift_service(
    db: Session, payload: SmartSwiftExtractRequest
) -> SmartSwiftExtractResponse:
    """
    Parses raw SWIFT MT103 text and auto-matches against existing Payment Requests.
    """
    from modules.financial_approval.swift_mt103_parser import (
        parse_swift_mt103_text,
        match_swift_against_payment_request,
    )

    parsed = parse_swift_mt103_text(payload.raw_text)
    if not parsed.get("success"):
        return SmartSwiftExtractResponse(
            success=False,
            parsed_swift={},
            matched_payment_request=None,
            candidate_matches=[],
            error=parsed.get("error", "Failed to parse SWIFT MT103 text"),
        )

    all_requests = repo.get_all_payment_requests(db, include_inactive=False)

    candidate_matches = []
    best_match = None
    highest_score = -1

    for req in all_requests:
        match_info = match_swift_against_payment_request(parsed, req)
        candidate_matches.append(match_info)

        if payload.target_payment_id and req.payment_id == payload.target_payment_id:
            best_match = match_info
            highest_score = 999
        elif match_info["confidence_score"] > highest_score:
            highest_score = match_info["confidence_score"]
            best_match = match_info

    candidate_matches.sort(key=lambda x: x["confidence_score"], reverse=True)

    return SmartSwiftExtractResponse(
        success=True,
        parsed_swift=parsed,
        matched_payment_request=best_match,
        candidate_matches=candidate_matches[:10],
        raw_text=payload.raw_text,
    )


def smart_extract_swift_from_file_service(
    db: Session,
    filename: str,
    content_bytes: bytes,
    target_payment_id: Optional[int] = None,
) -> SmartSwiftExtractResponse:
    """
    Extracts text from uploaded Word, Excel, PDF, or Image file and auto-matches against payment requests.
    """
    from modules.financial_approval.swift_file_extractor import extract_text_from_swift_file
    from modules.financial_approval.swift_mt103_parser import (
        parse_swift_mt103_text,
        match_swift_against_payment_request,
    )

    raw_text, normalized_text = extract_text_from_swift_file(filename, content_bytes)
    if not normalized_text.strip() and not raw_text.strip():
        return SmartSwiftExtractResponse(
            success=False,
            parsed_swift={},
            matched_payment_request=None,
            candidate_matches=[],
            raw_text="",
            detected_filename=filename,
            error=f"Could not extract readable text from file '{filename}'. Ensure the file is not empty or corrupted.",
        )

    # Parse normalized text
    text_to_parse = normalized_text if normalized_text.strip() else raw_text
    parsed = parse_swift_mt103_text(text_to_parse)

    all_requests = repo.get_all_payment_requests(db, include_inactive=False)
    candidate_matches = []
    best_match = None
    highest_score = -1

    for req in all_requests:
        match_info = match_swift_against_payment_request(parsed, req)
        candidate_matches.append(match_info)

        if target_payment_id and req.payment_id == target_payment_id:
            best_match = match_info
            highest_score = 999
        elif match_info["confidence_score"] > highest_score:
            highest_score = match_info["confidence_score"]
            best_match = match_info

    candidate_matches.sort(key=lambda x: x["confidence_score"], reverse=True)

    # Detect file type label
    lower = filename.lower()
    if lower.endswith('.pdf'):
        f_type = "PDF Document"
    elif lower.endswith(('.docx', '.doc')):
        f_type = "Word Document"
    elif lower.endswith(('.xlsx', '.xls', '.csv')):
        f_type = "Excel Spreadsheet"
    elif lower.endswith(('.jpg', '.jpeg', '.png', '.webp', '.bmp', '.tiff', '.tif')):
        f_type = "Image / Scanned Slip (OCR)"
    else:
        f_type = "Text File"

    return SmartSwiftExtractResponse(
        success=parsed.get("success", True),
        parsed_swift=parsed,
        matched_payment_request=best_match,
        candidate_matches=candidate_matches[:10],
        raw_text=raw_text if raw_text.strip() else normalized_text,
        detected_filename=filename,
        detected_file_type=f_type,
    )


def smart_reconcile_swift_service(
    db: Session, payload: SmartSwiftReconcileRequest
) -> PaymentRequestSession:
    """
    Auto-updates Payment Request with confirmed SWIFT details, performs variance
    reconciliation, confirms bank info, and marks as Paid.
    """
    from modules.import_files.model import ImportFile

    db_item = repo.get_payment_request_by_id(db, payload.payment_id)
    if not db_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Payment Request ID {payload.payment_id} not found.",
        )

    # 1. Update SWIFT fields
    db_item.swift_reference_no = payload.swift_reference_no
    db_item.swift_receipt_date = payload.swift_receipt_date
    db_item.swift_transferred_amount = payload.swift_transferred_amount
    db_item.swift_transferred_currency = payload.swift_transferred_currency

    # 2. Update / Confirm Bank details if provided
    if payload.bank_name:
        db_item.bank_name = payload.bank_name
    if payload.swift_code:
        db_item.swift_code = payload.swift_code
    if payload.iban_account_no:
        db_item.iban_account_no = payload.iban_account_no

    # 3. Calculate variance & processing days
    variance = float(payload.swift_transferred_amount) - float(db_item.requested_amount)
    db_item.swift_variance_amount = round(variance, 2)

    if abs(variance) < 0.01:
        db_item.swift_variance_status = "Matched"
    elif variance < 0:
        db_item.swift_variance_status = "Deficit"
    else:
        db_item.swift_variance_status = "Surplus"

    if db_item.request_date and payload.swift_receipt_date:
        delta = (payload.swift_receipt_date - db_item.request_date).days
        db_item.swift_processing_days = max(0, delta)

    if payload.swift_reconciliation_notes:
        db_item.swift_reconciliation_notes = payload.swift_reconciliation_notes

    if payload.auto_execute:
        db_item.status = "Paid"

    # 4. Sync swift_no to linked Import File
    if db_item.import_file_id:
        imp = db.query(ImportFile).filter(ImportFile.import_file_id == db_item.import_file_id).first()
        if imp:
            imp.swift_no = payload.swift_reference_no

    db.commit()
    db.refresh(db_item)
    return db_item

