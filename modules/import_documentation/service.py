"""
Service Layer & Business Engine for Import Documentation & ACI (Phase 3 - BP-014 to BP-019)
"""

import io
import re
from datetime import date, datetime, timezone
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from modules.import_documentation.model import (
    AcidRegistrationSession,
    BankingDocumentSession,
    ShipmentDocumentItem,
    CustomsDeclarationDraft,
)
from modules.import_documentation.schemas import (
    AcidRegistrationCreate,
    AcidRegistrationUpdate,
    AcidRegistrationResponse,
    BankingDocumentCreate,
    ShipmentDocumentCreate,
    ShipmentDocumentUpdate,
    CustomsDeclarationCreate,
)
from modules.import_documentation.validators import (
    validate_acid_number,
    validate_acid_expiry,
    validate_no_duplicate_acid_session,
    validate_no_duplicate_form4_session,
)
import modules.import_documentation.repository as repo


from modules.import_documentation.nafeza_acid_parser import (
    parse_nafeza_acid_text,
    compare_acid_data,
    generate_whatsapp_request_text,
    generate_email_request_template,
)


def enrich_acid_response(db: Session, item: AcidRegistrationSession) -> AcidRegistrationResponse:
    today = date.today()
    # Safely compute days remaining — expiry_date can be None for legacy/pending records
    if item.expiry_date:
        try:
            days_rem = (item.expiry_date - today).days
        except Exception:
            days_rem = 0
    else:
        days_rem = 0
    is_ver = (
        item.status in ["Verified", "Discrepancy_Accepted"]
        and item.is_importer_matched
        and item.is_exporter_matched
        and item.is_invoice_matched
        and item.is_ports_matched
        and days_rem > 0
    )

    import_file_code = None
    if item.import_file_id:
        from modules.import_files.model import ImportFile
        imp = db.query(ImportFile).filter(ImportFile.import_file_id == item.import_file_id).first()
        if imp:
            import_file_code = imp.import_file_code or imp.custom_file_number

    return AcidRegistrationResponse(
        acid_id=item.acid_id,
        acid_code=item.acid_code,
        acid_number=item.acid_number,
        import_file_id=item.import_file_id,
        import_file_code=import_file_code,
        po_id=item.po_id,
        po_number=item.po_number,
        po_date=item.po_date,
        importer_id=item.importer_id,
        importer_name=item.importer_name,
        importer_tax_id=item.importer_tax_id,
        importer_address=item.importer_address,
        supplier_id=item.supplier_id,
        exporter_name=item.exporter_name,
        exporter_reg_type=item.exporter_reg_type,
        exporter_reg_id=item.exporter_reg_id,
        exporter_country=item.exporter_country,
        exporter_country_code=item.exporter_country_code,
        exporter_address=item.exporter_address,
        exporter_phone=item.exporter_phone,
        cargox_id=item.cargox_id,
        proforma_invoice_no=item.proforma_invoice_no,
        proforma_invoice_date=item.proforma_invoice_date,
        invoice_date=item.invoice_date,
        invoice_type=item.invoice_type,
        invoice_attachment_name=item.invoice_attachment_name,
        pol_name=item.pol_name,
        pod_name=item.pod_name,
        customs_broker_id=item.customs_broker_id,
        customs_broker_name=item.customs_broker_name,
        customs_broker_phone=item.customs_broker_phone,
        requested_date=item.requested_date,
        generated_date=item.generated_date,
        expiry_date=item.expiry_date,
        raw_nafeza_text=item.raw_nafeza_text,
        requested_data=item.requested_data,
        generated_data=item.generated_data,
        discrepancies_data=item.discrepancies_data,
        discrepancy_override_reason=item.discrepancy_override_reason,
        is_importer_matched=item.is_importer_matched,
        is_exporter_matched=item.is_exporter_matched,
        is_invoice_matched=item.is_invoice_matched,
        is_ports_matched=item.is_ports_matched,
        has_discrepancies=item.has_discrepancies,
        verification_notes=item.verification_notes,
        status=item.status,
        days_to_expiry=days_rem,
        execution_days=item.execution_days,
        is_verified=is_ver,
        is_active=item.is_active,
        created_at=item.created_at,
        updated_at=item.updated_at,
    )


def enrich_banking_response(db: Session, item: BankingDocumentSession):
    import_file_code = None
    importer_name = None
    supplier_name = None
    po_number = None

    if item.import_file_id:
        from modules.import_files.model import ImportFile
        imp = db.query(ImportFile).filter(ImportFile.import_file_id == item.import_file_id).first()
        if imp:
            import_file_code = imp.import_file_code or imp.custom_file_number
            importer_name = imp.company_name
            supplier_name = imp.supplier_name
            po_number = imp.po_number

    from modules.import_documentation.schemas import BankingDocumentResponse
    res = BankingDocumentResponse.model_validate(item)
    res.import_file_code = import_file_code
    res.importer_name = importer_name
    res.supplier_name = supplier_name
    res.po_number = po_number
    return res


def enrich_shipment_doc_response(db: Session, item: ShipmentDocumentItem):
    import_file_code = None
    if item.import_file_id:
        from modules.import_files.model import ImportFile
        imp = db.query(ImportFile).filter(ImportFile.import_file_id == item.import_file_id).first()
        if imp:
            import_file_code = imp.import_file_code or imp.custom_file_number

    from modules.import_documentation.schemas import ShipmentDocumentResponse
    res = ShipmentDocumentResponse.model_validate(item)
    res.import_file_code = import_file_code
    return res


def create_acid_session_service(
    db: Session, schema: AcidRegistrationCreate
) -> AcidRegistrationResponse:
    validate_acid_number(schema.acid_number, allow_pending=True)
    validate_acid_expiry(schema.expiry_date, schema.requested_date)
    validate_no_duplicate_acid_session(db, schema.import_file_id)

    db_item = repo.create_acid_session(db, schema)

    # Compute execution days if dates are present
    if db_item.generated_date and db_item.requested_date:
        db_item.execution_days = max(0, (db_item.generated_date - db_item.requested_date).days)
        db.commit()

    # Sync with import file if applicable
    if db_item.import_file_id and db_item.acid_number and db_item.acid_number != "PENDING":
        from modules.import_files.model import ImportFile
        imp = db.query(ImportFile).filter(ImportFile.import_file_id == db_item.import_file_id).first()
        if imp:
            imp.acid_number = db_item.acid_number
            imp.acid_request_date = db_item.requested_date
            imp.acid_issue_date = db_item.generated_date or db_item.requested_date
            imp.acid_expiry_date = db_item.expiry_date
            imp.acid_execution_days = db_item.execution_days
            db.commit()

    return enrich_acid_response(db, db_item)


def update_acid_session_service(
    db: Session, acid_id: int, schema: AcidRegistrationUpdate
) -> AcidRegistrationResponse:
    db_item = repo.get_acid_session_by_id(db, acid_id)
    if not db_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"ACID Registration Session ID {acid_id} not found.",
        )

    if schema.import_file_id is not None:
        validate_no_duplicate_acid_session(db, schema.import_file_id, current_acid_id=acid_id)

    if schema.acid_number:
        validate_acid_number(schema.acid_number, allow_pending=True)

    updated = repo.update_acid_session(db, db_item, schema)

    # Compute execution days if dates are present
    if updated.generated_date and updated.requested_date:
        updated.execution_days = max(0, (updated.generated_date - updated.requested_date).days)
        db.commit()

    # Sync with import file if applicable
    if updated.import_file_id and updated.acid_number and updated.acid_number != "PENDING":
        from modules.import_files.model import ImportFile
        imp = db.query(ImportFile).filter(ImportFile.import_file_id == updated.import_file_id).first()
        if imp:
            imp.acid_number = updated.acid_number
            if updated.requested_date:
                imp.acid_request_date = updated.requested_date
            if updated.generated_date:
                imp.acid_issue_date = updated.generated_date
            elif updated.requested_date and not imp.acid_issue_date:
                imp.acid_issue_date = updated.requested_date
            if updated.expiry_date:
                imp.acid_expiry_date = updated.expiry_date
            if updated.execution_days is not None:
                imp.acid_execution_days = updated.execution_days
            db.commit()

    return enrich_acid_response(db, updated)


def get_acid_tracker_service(db: Session):
    from datetime import timedelta
    from modules.import_files.model import ImportFile
    from modules.customs_clearance.model import CustomsClearanceRecord
    from modules.import_documentation.schemas import AcidTrackerItem, AcidTrackerSummary

    today = date.today()
    items = []

    # Map clearances for rapid release check
    clearances = db.query(CustomsClearanceRecord).filter(CustomsClearanceRecord.is_active == True).all()
    clearance_by_file = {}
    for cl in clearances:
        if cl.import_file_id not in clearance_by_file:
            clearance_by_file[cl.import_file_id] = cl
        elif cl.dispatch_authorized or cl.release_permit_no:
            clearance_by_file[cl.import_file_id] = cl

    # Query all acid sessions
    acid_sessions = db.query(AcidRegistrationSession).filter(AcidRegistrationSession.is_active == True).all()
    acid_sessions_by_file = {s.import_file_id: s for s in acid_sessions if s.import_file_id}
    processed_session_ids = set()

    # Query all import files
    import_files = db.query(ImportFile).filter(ImportFile.is_active == True).all()

    for imp in import_files:
        acid_sess = acid_sessions_by_file.get(imp.import_file_id)
        if acid_sess:
            processed_session_ids.add(acid_sess.acid_id)

        acid_num = imp.acid_number or (acid_sess.acid_number if acid_sess else None)
        if not acid_num and not acid_sess:
            continue

        acid_issue_date = imp.acid_issue_date or (acid_sess.generated_date if acid_sess else None) or (acid_sess.requested_date if acid_sess else None)
        acid_expiry_date = imp.acid_expiry_date or (acid_sess.expiry_date if acid_sess else None)
        if not acid_expiry_date and acid_issue_date:
            acid_expiry_date = acid_issue_date + timedelta(days=90)

        cl = clearance_by_file.get(imp.import_file_id)
        is_released = (
            imp.is_customs_released
            or (cl is not None and (cl.dispatch_authorized or bool(cl.release_permit_no) or cl.status in ["Final Release Granted", "Cleared", "Completed"]))
            or imp.current_stage in ["Phase 8 - Warehouse Receiving", "Phase 9 - Financial Settlement", "Phase 10 - Closure", "Warehouse Received", "Closed"]
        )
        customs_released_at = imp.customs_released_at or (cl.release_date if cl else None) or (cl.dispatch_date if cl else None)
        release_permit_no = cl.release_permit_no if cl else None

        days_rem = (acid_expiry_date - today).days if acid_expiry_date else 90
        total_days = (acid_expiry_date - acid_issue_date).days if (acid_expiry_date and acid_issue_date) else 90
        if total_days <= 0:
            total_days = 90
        validity_pct = max(0.0, min(100.0, (days_rem / total_days) * 100.0)) if not is_released else 100.0

        if is_released:
            status = "Customs Released"
            status_label_ar = "صُرفت من الجمرك (معفى من التنبيه)"
            alert_required = False
        elif not acid_num or acid_num.upper() in ["PENDING", "REQUESTED", "DRAFT", ""]:
            status = "Pending Issue"
            status_label_ar = "قيد استخراج الـ ACID"
            alert_required = False
        elif days_rem <= 0:
            status = "Expired"
            status_label_ar = f"منتهي الصلاحية (منذ {abs(days_rem)} يوم)"
            alert_required = True
        elif days_rem <= 14:
            status = "Expiring Soon"
            status_label_ar = f"يوشك على الانتهاء (متبقي {days_rem} يوم)"
            alert_required = True
        else:
            status = "Valid"
            status_label_ar = f"ساري وصالح (متبقي {days_rem} يوم)"
            alert_required = False

        items.append(
            AcidTrackerItem(
                import_file_id=imp.import_file_id,
                import_file_code=imp.import_file_code or imp.custom_file_number,
                custom_file_number=imp.custom_file_number,
                acid_session_id=acid_sess.acid_id if acid_sess else None,
                acid_code=acid_sess.acid_code if acid_sess else None,
                acid_number=acid_num or "PENDING",
                importer_name=imp.company_name or (acid_sess.importer_name if acid_sess else "الشركة المستوردة"),
                supplier_name=imp.supplier_name or (acid_sess.exporter_name if acid_sess else "المورد الأجنبي"),
                po_number=imp.po_number or (acid_sess.po_number if acid_sess else None),
                pi_number=imp.pi_number or (acid_sess.proforma_invoice_no if acid_sess else None),
                shipment_mode=imp.shipment_mode,
                current_stage=imp.current_stage,
                customs_broker_name=imp.broker_name or (acid_sess.customs_broker_name if acid_sess else None),
                acid_issue_date=acid_issue_date,
                acid_expiry_date=acid_expiry_date,
                execution_days=imp.acid_execution_days or (acid_sess.execution_days if acid_sess else None),
                days_remaining=days_rem,
                total_validity_days=total_days,
                validity_percentage=round(validity_pct, 1),
                is_customs_released=is_released,
                customs_released_at=customs_released_at,
                release_permit_no=release_permit_no,
                status=status,
                status_label_ar=status_label_ar,
                alert_required=alert_required,
            )
        )

    # Standalone acid sessions
    for sess in acid_sessions:
        if sess.acid_id in processed_session_ids:
            continue
        days_rem = (sess.expiry_date - today).days if sess.expiry_date else 90
        total_days = (sess.expiry_date - (sess.generated_date or sess.requested_date)).days if sess.expiry_date else 90
        if total_days <= 0:
            total_days = 90
        validity_pct = max(0.0, min(100.0, (days_rem / total_days) * 100.0))

        if sess.acid_number == "PENDING":
            status = "Pending Issue"
            status_label_ar = "قيد استخراج الـ ACID"
            alert_required = False
        elif days_rem <= 0:
            status = "Expired"
            status_label_ar = f"منتهي الصلاحية (منذ {abs(days_rem)} يوم)"
            alert_required = True
        elif days_rem <= 14:
            status = "Expiring Soon"
            status_label_ar = f"يوشك على الانتهاء (متبقي {days_rem} يوم)"
            alert_required = True
        else:
            status = "Valid"
            status_label_ar = f"ساري وصالح (متبقي {days_rem} يوم)"
            alert_required = False

        items.append(
            AcidTrackerItem(
                import_file_id=None,
                import_file_code=None,
                custom_file_number=None,
                acid_session_id=sess.acid_id,
                acid_code=sess.acid_code,
                acid_number=sess.acid_number,
                importer_name=sess.importer_name,
                supplier_name=sess.exporter_name,
                po_number=sess.po_number,
                pi_number=sess.proforma_invoice_no,
                shipment_mode=None,
                current_stage="ACID Registration",
                customs_broker_name=sess.customs_broker_name,
                acid_issue_date=sess.generated_date or sess.requested_date,
                acid_expiry_date=sess.expiry_date,
                execution_days=sess.execution_days,
                days_remaining=days_rem,
                total_validity_days=total_days,
                validity_percentage=round(validity_pct, 1),
                is_customs_released=False,
                customs_released_at=None,
                release_permit_no=None,
                status=status,
                status_label_ar=status_label_ar,
                alert_required=alert_required,
            )
        )

    valid_count = sum(1 for i in items if i.status == "Valid")
    expiring_soon_count = sum(1 for i in items if i.status == "Expiring Soon")
    expired_count = sum(1 for i in items if i.status == "Expired")
    customs_released_count = sum(1 for i in items if i.status == "Customs Released")
    pending_issue_count = sum(1 for i in items if i.status == "Pending Issue")

    return AcidTrackerSummary(
        total_acids_count=len(items),
        valid_count=valid_count,
        expiring_soon_count=expiring_soon_count,
        expired_count=expired_count,
        customs_released_count=customs_released_count,
        pending_issue_count=pending_issue_count,
        items=items,
    )



def parse_acid_text_service(
    db: Session, raw_text: str, import_file_id: int | None = None
) -> dict:
    parsed = parse_nafeza_acid_text(raw_text)
    comparison = None

    if import_file_id:
        from modules.import_files.model import ImportFile
        from modules.suppliers.model import Supplier
        from modules.import_companies.model import ImportCompany

        file_obj = db.query(ImportFile).filter(ImportFile.import_file_id == import_file_id).first()
        if file_obj:
            comp_obj = db.query(ImportCompany).filter(ImportCompany.company_id == file_obj.company_id).first() if file_obj.company_id else None
            supp_obj = db.query(Supplier).filter(Supplier.supplier_id == file_obj.supplier_id).first() if file_obj.supplier_id else None

            requested_dict = {
                "importer_name": comp_obj.importer_name if comp_obj else file_obj.company_name,
                "importer_tax_id": comp_obj.vat_id if comp_obj else "",
                "exporter_name": supp_obj.company_name if supp_obj else file_obj.supplier_name,
                "exporter_reg_type": supp_obj.registration_type if supp_obj else "VAT Number",
                "exporter_reg_id": supp_obj.foreign_exporter_id if supp_obj else "",
                "exporter_country": supp_obj.foreign_exporter_country if supp_obj else "",
                "exporter_country_code": supp_obj.foreign_exporter_country_code if supp_obj else "",
                "proforma_invoice_no": file_obj.pi_number or "",
                "pol_name": "",
                "pod_name": "",
                "cargox_id": getattr(supp_obj, "cargox_platform_id", None) or "",
            }
            comparison = compare_acid_data(requested_dict, parsed)

    return {
        "parsed_data": parsed,
        "comparison": comparison,
    }


def compare_acid_datasets_service(requested: dict, generated: dict) -> dict:
    return compare_acid_data(requested, generated)


def generate_acid_templates_service(req_data: dict) -> dict:
    wa_text = generate_whatsapp_request_text(req_data)
    email_dict = generate_email_request_template(req_data)
    return {
        "whatsapp_text": wa_text,
        "email_subject": email_dict["subject"],
        "email_body": email_dict["body"],
    }


def restore_acid_session_service(db: Session, acid_id: int) -> AcidRegistrationResponse:
    item = repo.restore_acid_session(db, acid_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"ACID Registration Session ID {acid_id} not found.",
        )
    return enrich_acid_response(db, item)


# --- BANKING DOCUMENTS SERVICE ---
def create_banking_document_service(
    db: Session, schema: BankingDocumentCreate
):
    if schema.doc_type == "Form 4":
        validate_no_duplicate_form4_session(db, schema.import_file_id)

    item = repo.create_banking_document(db, schema)
    
    # Sync with import file if applicable
    if item.import_file_id:
        from modules.import_files.model import ImportFile
        imp = db.query(ImportFile).filter(ImportFile.import_file_id == item.import_file_id).first()
        if imp:
            imp.form4_request_date = item.request_date
            if item.doc_reference_number and item.doc_reference_number != "PENDING":
                imp.form4_no = item.doc_reference_number
            if item.received_date:
                imp.form4_received_date = item.received_date
                imp.form4_execution_days = item.execution_days
            db.commit()

    return enrich_banking_response(db, item)


def update_banking_document_service(
    db: Session, bank_doc_id: int, schema: BankingDocumentUpdate
):
    item = repo.get_banking_document_by_id(db, bank_doc_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Banking Document ID {bank_doc_id} not found.",
        )

    if schema.import_file_id is not None:
        validate_no_duplicate_form4_session(db, schema.import_file_id, current_doc_id=bank_doc_id)

    updated = repo.update_banking_document(db, item, schema)

    # Sync with import file if applicable
    if updated.import_file_id:
        from modules.import_files.model import ImportFile
        imp = db.query(ImportFile).filter(ImportFile.import_file_id == updated.import_file_id).first()
        if imp:
            if updated.doc_reference_number and updated.doc_reference_number != "PENDING":
                imp.form4_no = updated.doc_reference_number
            if updated.request_date:
                imp.form4_request_date = updated.request_date
            if updated.received_date:
                imp.form4_received_date = updated.received_date
                imp.form4_execution_days = updated.execution_days
            db.commit()

    return enrich_banking_response(db, updated)


def receive_banking_document_service(
    db: Session, bank_doc_id: int, form4_number: str, received_date: date, notes: str | None = None
):
    item = repo.get_banking_document_by_id(db, bank_doc_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Banking Document ID {bank_doc_id} not found.",
        )

    req_date = item.request_date or item.issue_date or date.today()
    exec_days = max(0, (received_date - req_date).days)

    item.doc_reference_number = form4_number.strip()
    item.received_date = received_date
    item.execution_days = exec_days
    item.status = "Received"
    if notes:
        item.notes = f"{item.notes}\n{notes}" if item.notes else notes

    item.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(item)

    # Sync with import file
    if item.import_file_id:
        from modules.import_files.model import ImportFile
        imp = db.query(ImportFile).filter(ImportFile.import_file_id == item.import_file_id).first()
        if imp:
            imp.form4_no = item.doc_reference_number
            imp.form4_request_date = item.request_date
            imp.form4_received_date = item.received_date
            imp.form4_execution_days = item.execution_days
            db.commit()

    return enrich_banking_response(db, item)


def delete_banking_document_service(db: Session, bank_doc_id: int):
    item = repo.get_banking_document_by_id(db, bank_doc_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Banking Document ID {bank_doc_id} not found.",
        )
    repo.delete_banking_document(db, item)
    return {"status": "success", "message": f"Banking Document {bank_doc_id} deleted"}


# --- SHIPMENT DOCUMENTS SERVICE ---
def create_shipment_document_service(
    db: Session, schema: ShipmentDocumentCreate
):
    item = repo.create_shipment_document(db, schema)
    return enrich_shipment_doc_response(db, item)


def update_cargox_and_bl_endorsement_service(
    db: Session,
    doc_id: int,
    cargox_envelope_id: str | None = None,
    endorsement_number: str | None = None,
):
    schema = ShipmentDocumentUpdate()
    if cargox_envelope_id:
        schema.is_cargox_uploaded = True
        schema.cargox_envelope_id = cargox_envelope_id
    if endorsement_number:
        schema.is_bl_endorsed = True
        schema.endorsement_number = endorsement_number
        schema.status = "Endorsed"

    item = repo.update_shipment_document(db, doc_id, schema)
    return enrich_shipment_doc_response(db, item)


# --- CUSTOMS DECLARATION SERVICE ---
def create_customs_declaration_service(
    db: Session, schema: CustomsDeclarationCreate
) -> CustomsDeclarationDraft:
    return repo.create_customs_declaration(db, schema)


# ==============================================================================
# PHASE 6: INTELLIGENT DOCUMENT VERIFICATION & COMPARISON ENGINES
# ==============================================================================
import difflib
from modules.import_files.model import ImportFile
from modules.purchase_orders.model import PurchaseOrder, POLineItem, PackingListItem
from modules.freight_booking.model import ShipmentBooking
from modules.cargo_shipping.model import CargoShippingRecord
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.import_documentation.model import (
    DraftBLReviewSession,
    CertificateOfOriginReviewSession,
    InspectionCertificateReviewSession,
)
from modules.import_documentation.schemas import (
    POFinalAdjustmentRequest,
    DraftBLReviewCreate,
    DraftBLReviewUpdate,
    DraftBLReviewResponse,
    DraftBLComparisonRequest,
    CertificateOfOriginReviewCreate,
    CertificateOfOriginReviewUpdate,
    CertificateOfOriginReviewResponse,
    COOComparisonRequest,
    InspectionCertificateReviewCreate,
    InspectionCertificateReviewUpdate,
    InspectionCertificateReviewResponse,
    InspectionComparisonRequest,
    LegalDocsExpiryComplianceResponse,
    LegalDocAlertItem,
)


def _normalize_str(s: Any) -> str:
    if s is None:
        return ""
    return " ".join(str(s).lower().strip().split())


def _fuzzy_match(s1: Any, s2: Any, threshold: float = 0.70) -> tuple[bool, float]:
    n1 = _normalize_str(s1)
    n2 = _normalize_str(s2)
    if not n1 and not n2:
        return True, 1.0
    if not n1 or not n2:
        return False, 0.0
    if n1 == n2 or n1 in n2 or n2 in n1:
        return True, 1.0
    ratio = difflib.SequenceMatcher(None, n1, n2).ratio()
    w1 = set(n1.split())
    w2 = set(n2.split())
    if w1 and w2:
        overlap = len(w1.intersection(w2)) / max(len(w1), len(w2))
        if overlap >= 0.50:
            return True, max(ratio, overlap)
    return ratio >= threshold, ratio


def _numeric_match(val1: Any, val2: Any, tolerance_pct: float = 0.5) -> tuple[bool, float, float]:
    try:
        f1 = float(val1 or 0.0)
        f2 = float(val2 or 0.0)
    except (ValueError, TypeError):
        return False, 100.0, 0.0
    if f1 == 0.0 and f2 == 0.0:
        return True, 0.0, 0.0
    base = max(abs(f1), abs(f2))
    diff = abs(f1 - f2)
    pct = (diff / base) * 100.0 if base > 0 else 0.0
    return pct <= tolerance_pct, pct, diff


# --- 1. FINAL INVOICE & PACKING LIST PO RECONCILIATION ---
def reconcile_po_final_adjustments_service(db: Session, request: POFinalAdjustmentRequest) -> dict:
    imp_file = db.query(ImportFile).filter(ImportFile.import_file_id == request.import_file_id).first()
    if not imp_file:
        raise HTTPException(status_code=404, detail="Import File not found")

    updated_items = []
    total_net_weight = 0.0
    total_gross_weight = 0.0
    total_cbm = 0.0
    total_final_amount = 0.0

    for itm in request.items:
        final_price = itm.final_unit_price if itm.final_unit_price > 0 else itm.unit_price
        itm.unit_price = final_price
        itm.final_unit_price = final_price

        if itm.po_item_id:
            db_po_item = db.query(POLineItem).filter(POLineItem.item_id == itm.po_item_id).first()
            if db_po_item:
                db_po_item.quantity = itm.final_quantity
                if final_price > 0:
                    db_po_item.unit_price = final_price
                    db_po_item.total_price = itm.final_quantity * final_price
                if itm.final_net_weight_kg > 0:
                    db_po_item.net_weight_kg = itm.final_net_weight_kg
                if itm.final_gross_weight_kg > 0:
                    db_po_item.gross_weight_kg = itm.final_gross_weight_kg
                if itm.final_cbm > 0:
                    db_po_item.total_cbm = itm.final_cbm

            db_pl_item = db.query(PackingListItem).filter(PackingListItem.packing_item_id == itm.po_item_id).first()
            if db_pl_item:
                if itm.final_packages_count > 0:
                    db_pl_item.qty_pkg = itm.final_packages_count
                if itm.final_net_weight_kg > 0:
                    db_pl_item.total_net_weight_kg = itm.final_net_weight_kg
                if itm.final_gross_weight_kg > 0:
                    db_pl_item.total_gross_weight_kg = itm.final_gross_weight_kg
                if itm.final_cbm > 0:
                    db_pl_item.total_cbm = itm.final_cbm
                if itm.package_type:
                    db_pl_item.package_type = itm.package_type
        
        total_net_weight += itm.final_net_weight_kg
        total_gross_weight += itm.final_gross_weight_kg
        total_cbm += itm.final_cbm
        if final_price > 0:
            total_final_amount += itm.final_quantity * final_price
        
        qty_variance = 0.0
        if itm.initial_quantity > 0:
            qty_variance = ((itm.final_quantity - itm.initial_quantity) / itm.initial_quantity) * 100.0
        itm.variance_percentage = round(qty_variance, 2)

        price_variance = 0.0
        if itm.initial_unit_price > 0:
            price_variance = ((final_price - itm.initial_unit_price) / itm.initial_unit_price) * 100.0
        itm.price_variance_percentage = round(price_variance, 2)

        weight_variance = 0.0
        if itm.initial_gross_weight_kg > 0:
            weight_variance = ((itm.final_gross_weight_kg - itm.initial_gross_weight_kg) / itm.initial_gross_weight_kg) * 100.0
        itm.weight_variance_percentage = round(weight_variance, 2)

        updated_items.append(itm.model_dump())

    # Update Import File Snapshot
    imp_file.pi_number = request.final_invoice_number
    imp_file.total_amount = total_final_amount
    db.commit()

    return {
        "status": "success",
        "message": "Final Commercial Invoice & Packing List quantities, prices, and weights certified for downstream systems (B/L, Inventory in Transit, Warehouse Receiving).",
        "import_file_id": request.import_file_id,
        "final_invoice_number": request.final_invoice_number,
        "final_packing_list_number": request.final_packing_list_number,
        "total_items_count": len(updated_items),
        "total_net_weight_kg": round(total_net_weight, 2),
        "total_gross_weight_kg": round(total_gross_weight, 2),
        "total_cbm": round(total_cbm, 3),
        "total_final_amount": round(total_final_amount, 2),
        "items": updated_items,
    }


# --- 2. DRAFT BILL OF LADING (B/L) 5-STAGE REVIEW ENGINE ---
def _build_system_bl_snapshot(db: Session, import_file_id: int) -> dict:
    imp_file = db.query(ImportFile).filter(ImportFile.import_file_id == import_file_id).first()
    booking = db.query(ShipmentBooking).filter(ShipmentBooking.import_file_id == import_file_id, ShipmentBooking.is_active == True).first()
    cargo_shp = db.query(CargoShippingRecord).filter(CargoShippingRecord.import_file_id == import_file_id, CargoShippingRecord.is_active == True).first()
    company = db.query(ImportCompany).filter(ImportCompany.company_id == imp_file.company_id).first() if imp_file and imp_file.company_id else None
    supplier = db.query(Supplier).filter(Supplier.supplier_id == imp_file.supplier_id).first() if imp_file and imp_file.supplier_id else None
    pos = db.query(PurchaseOrder).filter(PurchaseOrder.import_file_id == import_file_id, PurchaseOrder.is_active == True).all()

    # Containers from Phase 5 Cargo Shipping
    containers = []
    cargo_gw = 0.0
    cargo_nw = 0.0
    hs_codes = set()
    goods_desc = []
    container_str_parts = []

    if cargo_shp and cargo_shp.containers_loading_data:
        for c in cargo_shp.containers_loading_data:
            c_dict = dict(c)
            c_no = c_dict.get("container_no", "")
            s_no = c_dict.get("seal_no", "")
            c_sz = c_dict.get("container_type", "40HC")
            containers.append({
                "container_no": c_no,
                "seal_no": s_no,
                "container_type": c_sz,
                "gross_weight_kg": float(c_dict.get("gross_weight_kg") or 0.0),
                "net_weight_kg": float(c_dict.get("net_weight_kg") or 0.0),
                "vgm_status": c_dict.get("vgm_status", "Submitted"),
            })
            cargo_gw += float(c_dict.get("gross_weight_kg") or 0.0)
            cargo_nw += float(c_dict.get("net_weight_kg") or 0.0)
            if c_no:
                container_str_parts.append(f"{c_no} / Seal: {s_no} ({c_sz})")

    has_any_pl = any(bool(po.packing_list_items) for po in pos)

    pl_total_cbm = 0.0
    pl_total_gw = 0.0
    pl_total_nw = 0.0
    pl_total_pkgs = 0
    pl_total_pcs = 0

    inv_total_cbm = 0.0
    inv_total_gw = 0.0
    inv_total_nw = 0.0
    inv_total_pkgs = 0
    inv_total_pcs = 0

    for po in pos:
        # 1. Line items
        if po.line_items:
            for itm in po.line_items:
                desc = itm.description_ar or itm.description_en or itm.item_code
                if desc and desc not in goods_desc:
                    goods_desc.append(desc)
                qty = float(itm.quantity or 0.0)
                inv_total_pcs += int(qty)
                inv_total_pkgs += int(qty)
                inv_total_cbm += float(itm.total_cbm or 0.0)
                inv_total_gw += float(itm.gross_weight_kg or 0.0)
                inv_total_nw += float(itm.net_weight_kg or 0.0)
                if itm.tariff and itm.tariff.hs_code:
                    hs_codes.add(itm.tariff.hs_code)

        # 2. Packing list items
        if po.packing_list_items:
            for pl in po.packing_list_items:
                p_code = pl.item_code or pl.hs_code
                if p_code and p_code not in goods_desc:
                    goods_desc.append(p_code)
                q_pkg = float(pl.qty_pkg or 0.0)
                q_pcs = float(pl.qty_pcs or 0.0)
                pl_total_pkgs += int(q_pkg)
                pl_total_pcs += int(q_pcs)

                # CBM
                cbm_val = float(pl.total_cbm or 0.0)
                if cbm_val <= 0:
                    l_m = float(pl.length_cm or 0.0) / 100.0
                    w_m = float(pl.width_cm or 0.0) / 100.0
                    h_m = float(pl.height_cm or 0.0) / 100.0
                    cbm_val = round(q_pkg * (l_m * w_m * h_m), 4) if (l_m > 0 and w_m > 0 and h_m > 0) else 0.0
                pl_total_cbm += cbm_val

                # Gross Weight
                gw_val = float(pl.total_gross_weight_kg or 0.0)
                if gw_val <= 0 and float(pl.gross_weight_unit_kg or 0.0) > 0:
                    gw_val = round(q_pkg * float(pl.gross_weight_unit_kg), 2)
                pl_total_gw += gw_val

                # Net Weight
                nw_val = float(pl.total_net_weight_kg or 0.0)
                if nw_val <= 0 and float(pl.net_weight_unit_kg or 0.0) > 0:
                    nw_val = round(q_pkg * float(pl.net_weight_unit_kg), 2)
                pl_total_nw += nw_val

                if pl.hs_code:
                    hs_codes.add(pl.hs_code)

    # Determine final totals with priority to detailed Packing List
    if has_any_pl and (pl_total_pkgs > 0 or pl_total_gw > 0 or pl_total_cbm > 0):
        total_cbm = pl_total_cbm
        total_gw = pl_total_gw
        total_nw = pl_total_nw
        total_pkgs = pl_total_pkgs
        total_pcs = pl_total_pcs if pl_total_pcs > 0 else inv_total_pcs
    else:
        total_cbm = inv_total_cbm
        total_gw = cargo_gw if cargo_gw > 0 else inv_total_gw
        total_nw = cargo_nw if cargo_nw > 0 else inv_total_nw
        total_pkgs = inv_total_pkgs
        total_pcs = inv_total_pcs

    shipper_name = supplier.company_name if supplier else (imp_file.supplier_name if imp_file else 'Foreign Supplier')
    shipper_addr = supplier.address if (supplier and supplier.address) else 'Export Industrial District, Global Port'
    shipper_phone = getattr(supplier, 'phone', None) or getattr(supplier, 'contact_phone', None) or '+49-89-636-00'
    shipper_full = f"{shipper_name}\nAddress: {shipper_addr}\nPhone: {shipper_phone}".strip()

    consignee_name = company.importer_name if company else (imp_file.company_name if imp_file else 'Importing Company')
    consignee_addr = company.address if (company and company.address) else '15 Industrial Zone, Cairo, Egypt'
    consignee_phone = getattr(company, 'phone', None) or '+20-2-25778899'
    consignee_full = f"{consignee_name}\nAddress: {consignee_addr}\nPhone: {consignee_phone}".strip()

    notify_party_full = consignee_full
    vessel = booking.vessel_name if (booking and booking.vessel_name) else "OCEAN VESSEL"
    voyage = getattr(booking, 'voyage_number', None) or getattr(booking, 'voyage_no', None) or "VOY-01"
    pol = booking.pol_name if (booking and booking.pol_name) else "Port of Loading (POL)"
    pod = booking.pod_name if (booking and booking.pod_name) else "Port of Discharge (POD)"
    freight_terms = getattr(booking, 'freight_terms', None) or "Freight Prepaid"
    place_of_deliv = getattr(booking, 'place_of_delivery', None) or pod
    bkg_no = booking.booking_confirmation_no if (booking and booking.booking_confirmation_no) else (cargo_shp.booking_no if (cargo_shp and cargo_shp.booking_no) else "BKG-REF")
    acid_no = imp_file.acid_number if (imp_file and imp_file.acid_number) else "N/A"
    tax_id = company.vat_id if company else "N/A"
    shipper_reg = getattr(supplier, 'registration_id', None) or getattr(supplier, 'tax_id', None) or "N/A"
    shp_mode = booking.shipment_type if (booking and booking.shipment_type) else "FCL / FCL"
    container_summary_str = "; ".join(container_str_parts) if container_str_parts else "N/A"

    return {
        "forwarder_name": booking.freight_forwarder_name if (booking and booking.freight_forwarder_name) else "Direct Shipping Line",
        "shipping_line": booking.shipping_line_name if (booking and booking.shipping_line_name) else (cargo_shp.shipping_line if (cargo_shp and cargo_shp.shipping_line) else "OCEAN CARRIER / FREIGHT LINE"),
        "vessel_name": vessel,
        "voyage_number": voyage,
        "pol": pol,
        "pod": pod,
        "freight_terms": freight_terms,
        "place_of_delivery": place_of_deliv,
        "booking_no": bkg_no,
        "acid_number": acid_no,
        "importer_tax_id": tax_id,
        "shipper_reg_id": shipper_reg,
        "shipping_mode": shp_mode,
        "container_summary": container_summary_str,
        "hbl_no": None,
        "mbl_no": None,
        "shipper": shipper_full,
        "consignee": consignee_full,
        "notify_party": notify_party_full,
        "hs_codes": list(hs_codes) if hs_codes else ["N/A"],
        "goods_description": ", ".join(goods_desc) if goods_desc else "General Merchandise & Import Goods",
        "qty_pcs": total_pcs,
        "qty_pkg": total_pkgs,
        "total_net_weight_kg": round(total_nw, 2),
        "total_gross_weight_kg": round(total_gw, 2),
        "cbm": round(total_cbm, 4),
        "containers": containers,
        "container_count": len(containers),
    }


def extract_text_from_uploaded_file(filename: str, content_bytes: bytes) -> str:
    """
    Extracts raw text and table structures from uploaded PDF, Word (.docx), Excel (.xlsx), or Text files.
    """
    lower_name = filename.lower()
    text_content = ""

    if lower_name.endswith(".pdf"):
        try:
            import pypdf
            reader = pypdf.PdfReader(io.BytesIO(content_bytes))
            parts = []
            for page in reader.pages:
                t = page.extract_text()
                if t:
                    parts.append(t)
            text_content = "\n".join(parts)
        except Exception as e:
            text_content = f"PDF Extraction Note: {str(e)}"

    elif lower_name.endswith(".docx") or lower_name.endswith(".doc"):
        try:
            import docx
            doc = docx.Document(io.BytesIO(content_bytes))
            parts = [p.text for p in doc.paragraphs if p.text]
            for tbl in doc.tables:
                for row in tbl.rows:
                    parts.append(" | ".join([cell.text.strip() for cell in row.cells if cell.text.strip()]))
            text_content = "\n".join(parts)
        except Exception as e:
            text_content = f"Word Document Extraction Note: {str(e)}"

    elif lower_name.endswith(".xlsx") or lower_name.endswith(".xls"):
        try:
            import openpyxl
            wb = openpyxl.load_workbook(io.BytesIO(content_bytes), data_only=True)
            parts = []
            for sheet in wb.sheetnames:
                ws = wb[sheet]
                for row in ws.iter_rows(values_only=True):
                    row_vals = [str(v).strip() for v in row if v is not None and str(v).strip() != ""]
                    if row_vals:
                        parts.append(" | ".join(row_vals))
            text_content = "\n".join(parts)
        except Exception as e:
            text_content = f"Excel Extraction Note: {str(e)}"

    else:
        try:
            text_content = content_bytes.decode("utf-8")
        except UnicodeDecodeError:
            text_content = content_bytes.decode("latin-1", errors="ignore")

    return text_content


def parse_draft_bl_raw_text(raw_text: str) -> dict:
    from modules.import_documentation.ai_document_parser import extract_draft_bl_with_ai
    return extract_draft_bl_with_ai(raw_text)



def compare_draft_bl_service(db: Session, request: DraftBLComparisonRequest) -> dict:
    sys_data = _build_system_bl_snapshot(db, request.import_file_id)
    draft_fields = dict(request.draft_fields or {})

    raw_input = getattr(request, "raw_draft_text", None) or getattr(request, "raw_text", None)
    if raw_input:
        extracted = parse_draft_bl_raw_text(raw_input)
        for k, v in extracted.items():
            if k not in draft_fields or not draft_fields[k]:
                draft_fields[k] = v

    if "container_summary" not in draft_fields and "containers" in draft_fields:
        c_parts = []
        for c in draft_fields["containers"]:
            c_no = c.get("container_no", "")
            s_no = c.get("seal_no", "")
            if c_no:
                c_parts.append(f"{c_no} / Seal: {s_no}" if s_no else c_no)
        if c_parts:
            draft_fields["container_summary"] = "; ".join(c_parts)

    # Field Mappings & Rules
    fields_spec = [
        ("shipper", "المصدر / الشاحن (Shipper)", "Shipper Name, Address & Phone", "Supplier Master Data", False, "fuzzy", "Supplier"),
        ("consignee", "المستورد / المرسل إليه (Consignee)", "Consignee Name, Address & Phone", "Importer Company Master Data", True, "fuzzy", "Importer"),
        ("notify_party", "جهة الإخطار (Notify Party)", "Notify Party Name, Address & Phone", "Importer / Contract", False, "fuzzy", "Importer"),
        ("vessel_name", "اسم الباخرة (Vessel)", "Vessel Name", "Final Booking", False, "text", "Shipping Provider"),
        ("voyage_number", "رقم الرحلة (Voyage)", "Voyage Number", "Final Booking", False, "text", "Shipping Provider"),
        ("pol", "ميناء الشحن (POL)", "Port of Loading (POL)", "Final Booking", False, "text", "Shipping Provider"),
        ("pod", "ميناء التفريغ (POD)", "Port of Discharge (POD)", "Final Booking", False, "text", "Shipping Provider"),
        ("freight_terms", "شروط النولون (Freight Terms)", "Freight Terms (Prepaid/Collect)", "Final Booking", False, "text", "Shipping Provider"),
        ("place_of_delivery", "مكان التسليم (Place of Delivery)", "Place of Delivery", "Final Booking", False, "text", "Shipping Provider"),
        ("booking_no", "رقم الحجز (Booking Number)", "Booking Number", "Final Booking", True, "text", "Shipping Provider"),
        ("acid_number", "رقم القيد الجمركي المبدئي (ACID)", "ACID Number", "Import File & Nafeza", True, "text", "Importer"),
        ("importer_tax_id", "البطاقة الضريبية للمستورد (Importer Tax ID)", "Egyptian Importer Tax ID", "Importer Company", True, "text", "Importer"),
        ("shipper_reg_id", "رقم تسجيل المصدر (Shipper Reg ID)", "Shipper Registration/ID", "Supplier", False, "text", "Supplier"),
        ("shipping_mode", "نمط الشحن (Shipping Mode)", "Shipping Mode (FCL/LCL/Air)", "Final Booking", False, "text", "Shipping Provider"),
        ("container_summary", "بيان الحاويات والسيل (Container Summary)", "Container No + Seal No + Size", "Container Allocation", True, "fuzzy", "Shipping Provider"),
        ("goods_description", "بيان التعبئة والوصف (Packing Summary)", "Packing Summary & Goods Description", "Final Approved Packing List", False, "fuzzy", "Supplier"),
        ("total_gross_weight_kg", "الوزن القائم (Gross Weight)", "Gross Weight (KG)", "Final Approved Packing List", False, "numeric_05", "Shipping Provider"),
        ("total_net_weight_kg", "الوزن الصافي (Net Weight)", "Net Weight (KG)", "Final Approved Packing List", False, "numeric_05", "Supplier"),
        ("cbm", "الحجم الإجمالي (Measurement CBM)", "Measurement (CBM)", "Final Approved Packing List", False, "numeric_05", "Shipping Provider"),
        ("qty_pkg", "عدد الطرود (Number of Packages)", "Number of Packages", "Final Approved Packing List", False, "numeric_strict", "Supplier"),
    ]

    matrix = []
    checklist = []
    blocking_reasons = []

    for key, label_ar, label_en, source, is_critical, match_type, resp_default in fields_spec:
        sys_val = sys_data.get(key)
        draft_val = draft_fields.get(key)

        if draft_val is None or str(draft_val).strip() == "":
            match_status = "MISSING_IN_DRAFT"
            is_explicitly_empty = key in draft_fields and draft_fields[key] == ""
            severity = "BLOCKING" if (is_critical and is_explicitly_empty) else "WARNING"
            details = "الحقل مطلوب ولم يتم استخراجه أو إدخاله في بيانات درافت البوليصة."
            if is_critical and is_explicitly_empty:
                blocking_reasons.append(f"حقل حرج فارغ: {label_ar}")
            tolerance_pct = 0.0
        elif sys_val is None or str(sys_val).strip() == "":
            match_status = "MATCH"
            severity = "NONE"
            details = f"تم استخراج القيمة من الدرافت ({draft_val})."
            tolerance_pct = 0.0
        elif match_type == "fuzzy":
            matched, ratio = _fuzzy_match(sys_val, draft_val, threshold=0.85)
            tolerance_pct = round((1.0 - ratio) * 100.0, 1)
            if matched:
                match_status = "MATCH"
                severity = "NONE"
                details = f"مطابقة ذكية ممتازة بنسبة {round(ratio * 100, 1)}%."
            else:
                match_status = "MISMATCH_CRITICAL" if is_critical else "MISMATCH_MINOR"
                severity = "BLOCKING" if is_critical else "WARNING"
                details = f"عدم تطابق! قيمة النظام: '{sys_val}' | قيمة الدرافت: '{draft_val}'."
                if is_critical:
                    blocking_reasons.append(f"اختلاف حرج في {label_ar}")
        elif match_type == "numeric_05":
            try:
                s_num = float(sys_val)
                d_num = float(draft_val)
                diff = abs(s_num - d_num)
                pct = (diff / s_num * 100.0) if s_num > 0 else 0.0
                tolerance_pct = round(pct, 2)
                if pct <= 0.5:
                    match_status = "MATCH"
                    severity = "NONE"
                    details = f"مطابقة رقمية ممتازة (فرق {tolerance_pct}% ضمن نسبة السماح 0.5%)."
                else:
                    match_status = "MISMATCH_MINOR"
                    severity = "WARNING"
                    details = f"فرق أوزان يتجاوز نسبة السماح ({tolerance_pct}%). النظام: {s_num} | الدرافت: {d_num}."
            except Exception:
                match_status = "MISMATCH_MINOR"
                severity = "WARNING"
                details = f"تعذر التحقق الرقمي من القيمة: {draft_val}"
        else: # text
            s_clean = str(sys_val).strip().upper()
            d_clean = str(draft_val).strip().upper()
            if s_clean == d_clean:
                match_status = "MATCH"
                severity = "NONE"
                details = "مطابقة نصية تامة 100%."
            else:
                match_status = "MISMATCH_CRITICAL" if is_critical else "MISMATCH_MINOR"
                severity = "BLOCKING" if is_critical else "WARNING"
                details = f"عدم تطابق! القيمة المعتمدة: '{sys_val}' | قيمة المسودة: '{draft_val}'."
                if is_critical:
                    blocking_reasons.append(f"اختلاف حرج في {label_ar}")

        matrix.append({
            "field_key": key,
            "field_label_ar": label_ar,
            "field_label_en": label_en,
            "source_entity": source,
            "system_value": sys_val,
            "draft_value": draft_val,
            "match_status": match_status,
            "severity": severity,
            "tolerance_pct": tolerance_pct,
            "details": details,
        })

        is_match = (match_status == "MATCH")
        checklist.append({
            "field_key": key,
            "field_label_ar": label_ar,
            "field_label_en": label_en,
            "source_entity": source,
            "system_value": sys_val,
            "draft_value": draft_val,
            "status": "Correct" if is_match else "Incorrect",
            "required_correction": f"Correct {label_en} to: {sys_val}" if not is_match else None,
            "reason": details if not is_match else None,
            "notes": None,
            "responsible_party": resp_default,
            "is_locked": False,
            "previous_status": None,
        })

    has_blocking = len(blocking_reasons) > 0
    open_discrepancies = [c for c in checklist if c["status"] == "Incorrect"]

    # Generate Revision Report Items
    revision_report = []
    for itm in open_discrepancies:
        revision_report.append({
            "item": itm["field_label_en"],
            "required_action": itm["required_correction"] or f"Update {itm['field_label_en']} to match system value ({itm['system_value']})",
            "responsible": itm["responsible_party"] or "Shipping Provider",
            "reason": itm["reason"] or "Value mismatch with master reference",
            "notes": itm["notes"],
        })

    # Auto-generate Correction Letter
    correction_letter = ""
    if revision_report:
        correction_letter = f"""Subject: Urgent: Draft B/L Correction Request - Booking Ref: {sys_data.get('booking_no')} / ACID: {sys_data.get('acid_number')}

Dear Shipping Line / Forwarder Operations Team,

Please be advised that upon verification of the Draft Bill of Lading received for Booking No: {sys_data.get('booking_no')}, the following discrepancies were identified and require immediate amendment prior to final B/L issuance:

"""
        for idx, item in enumerate(revision_report, 1):
            correction_letter += f"{idx}. Item: {item['item']}\n"
            correction_letter += f"   - Required Action: {item['required_action']}\n"
            correction_letter += f"   - Responsible Party: {item['responsible']}\n"
            correction_letter += f"   - Reason / Details: {item['reason']}\n\n"
        
        correction_letter += "Please provide the revised Draft B/L with the requested corrections at your earliest convenience.\n\nBest Regards,\nImport Operations Department"

    stage_calc = "Stage 2: Revision Required" if open_discrepancies else "Stage 4: Dual Approval"
    status_calc = "REVISION_REQUIRED" if open_discrepancies else "REVIEWED_PENDING_APPROVAL"

    return {
        "import_file_id": request.import_file_id,
        "draft_source": request.draft_source,
        "stage": stage_calc,
        "system_snapshot_data": sys_data,
        "draft_input_data": draft_fields,
        "comparison_matrix": matrix,
        "checklist_data": checklist,
        "revision_report_data": revision_report,
        "has_blocking_mismatch": has_blocking,
        "open_discrepancies_count": len(open_discrepancies),
        "blocking_reasons": blocking_reasons,
        "correction_request_letter": correction_letter,
        "status": status_calc,
    }


def create_draft_bl_review_service(db: Session, schema: DraftBLReviewCreate) -> DraftBLReviewSession:
    if schema.checklist_data:
        # Convert any Pydantic models to dicts
        raw_checklist = []
        revision_report = []
        open_count = 0
        for item in schema.checklist_data:
            item_dict = item.model_dump() if hasattr(item, "model_dump") else (item.dict() if hasattr(item, "dict") else item)
            status_val = item_dict.get("status", "Correct")
            if status_val == "Incorrect":
                open_count += 1
                revision_report.append({
                    "item": item_dict.get("field_label_ar") or item_dict.get("field_label_en", ""),
                    "required_action": item_dict.get("required_correction", ""),
                    "responsible": item_dict.get("responsible_party") or "Shipping Provider",
                    "reason": item_dict.get("reason", ""),
                    "notes": item_dict.get("notes"),
                })
            raw_checklist.append(item_dict)
        schema.checklist_data = raw_checklist
        schema.revision_report_data = revision_report
        schema.open_discrepancies_count = open_count
        if open_count > 0:
            schema.stage = "Stage 2: Revision Required"
            schema.status = "REVISION_REQUIRED"
        else:
            schema.stage = "Stage 4: Dual Approval"
            schema.status = "REVIEWED_PENDING_APPROVAL"
    elif not schema.comparison_matrix:
        comp_req = DraftBLComparisonRequest(
            import_file_id=schema.import_file_id,
            draft_source=schema.draft_source,
            draft_fields=schema.draft_input_data,
        )
        comp_res = compare_draft_bl_service(db, comp_req)
        schema.system_snapshot_data = comp_res["system_snapshot_data"]
        schema.comparison_matrix = comp_res["comparison_matrix"]
        schema.checklist_data = comp_res["checklist_data"]
        schema.revision_report_data = comp_res["revision_report_data"]
        schema.has_blocking_mismatch = comp_res["has_blocking_mismatch"]
        schema.open_discrepancies_count = comp_res["open_discrepancies_count"]
        schema.blocking_reasons = comp_res["blocking_reasons"]
        schema.correction_request_letter = comp_res["correction_request_letter"]
        schema.stage = comp_res["stage"]
        schema.status = comp_res["status"]

    existing = repo.get_draft_bl_review_by_file_id(db, schema.import_file_id, include_inactive=False)
    if existing:
        update_schema = DraftBLReviewUpdate(**schema.model_dump(exclude_unset=True))
        return repo.update_draft_bl_review(db, existing.bl_review_id, update_schema)
    return repo.create_draft_bl_review(db, schema)


def update_draft_bl_review_service(db: Session, review_id: int, schema: DraftBLReviewUpdate) -> DraftBLReviewSession:
    return repo.update_draft_bl_review(db, review_id, schema)


def update_draft_bl_checklist_service(db: Session, review_id: int, checklist_items: List[DraftBLChecklistItem], reviewer_name: str = "Kamal") -> DraftBLReviewSession:
    review = repo.get_draft_bl_review_by_id(db, review_id)
    if not review:
        raise HTTPException(status_code=404, detail="Draft B/L Review not found")

    updated_checklist = []
    revision_report = []
    open_count = 0

    for item in checklist_items:
        item_dict = item.model_dump()
        if item.status == "Incorrect":
            if not item.required_correction or not item.reason:
                raise HTTPException(
                    status_code=400,
                    detail=f"الحقول 'Required Correction' و 'Reason' إلزامية للبند غير المطابق: {item.field_label_ar}"
                )
            open_count += 1
            revision_report.append({
                "item": item.field_label_en,
                "required_action": item.required_correction,
                "responsible": item.responsible_party or "Shipping Provider",
                "reason": item.reason,
                "notes": item.notes,
            })
        updated_checklist.append(item_dict)

    review.checklist_data = updated_checklist
    review.revision_report_data = revision_report
    review.open_discrepancies_count = open_count
    review.reviewed_by = reviewer_name
    review.reviewed_at = datetime.now(timezone.utc)

    # Re-generate correction letter
    if revision_report:
        sys_data = review.system_snapshot_data or {}
        correction_letter = f"""Subject: Urgent: Draft B/L Correction Request - Booking Ref: {sys_data.get('booking_no')} / ACID: {sys_data.get('acid_number')}

Dear Shipping Line / Forwarder Operations Team,

Please be advised that upon review of the Draft Bill of Lading received for Booking No: {sys_data.get('booking_no')}, the following corrections are required:

"""
        for idx, itm in enumerate(revision_report, 1):
            correction_letter += f"{idx}. {itm['item']}:\n"
            correction_letter += f"   - Required Action: {itm['required_action']}\n"
            correction_letter += f"   - Responsible Party: {itm['responsible']}\n"
            correction_letter += f"   - Reason: {itm['reason']}\n\n"
        correction_letter += "Please reissue the draft B/L with these corrections at your earliest convenience.\n\nBest Regards,\nImport Operations Department"
        review.correction_request_letter = correction_letter
        review.stage = "Stage 2: Revision Required"
        review.status = "REVISION_REQUIRED"
    else:
        review.stage = "Stage 4: Dual Approval"
        review.status = "REVIEWED_PENDING_APPROVAL"

    db.commit()
    db.refresh(review)
    return review


def process_dual_approval_service(db: Session, request: DualApprovalRequest) -> DraftBLReviewSession:
    review = repo.get_draft_bl_review_by_id(db, request.bl_review_id)
    if not review:
        raise HTTPException(status_code=404, detail="Draft B/L Review not found")

    if review.open_discrepancies_count > 0:
        raise HTTPException(
            status_code=400,
            detail="لا يمكن اعتماد درافت البوليصة طالما توجد بنود غير مطابقة (Open Discrepancies) لم يتم إغلاقها."
        )

    now = datetime.now(timezone.utc)

    if request.role == "importer":
        if request.action == "Approved":
            review.importer_approval_status = "Approved"
            review.importer_approved_by = request.approved_by
            review.importer_approval_date = now
            review.importer_approval_notes = request.notes
        else:
            review.importer_approval_status = "Rejected"
            review.importer_approval_notes = request.notes
            review.stage = "Stage 2: Revision Required"
            review.status = "REVISION_REQUIRED"
    elif request.role == "customs_broker":
        if request.action == "Approved":
            review.broker_approval_status = "Approved"
            review.broker_approved_by = request.approved_by
            review.broker_approval_date = now
            review.broker_approval_notes = request.notes
        else:
            review.broker_approval_status = "Rejected"
            review.broker_approval_notes = request.notes
            review.stage = "Stage 2: Revision Required"
            review.status = "REVISION_REQUIRED"
    else:
        raise HTTPException(status_code=400, detail="Invalid approval role. Must be 'importer' or 'customs_broker'.")

    # If BOTH approved -> Stage 5 Final
    if review.importer_approval_status == "Approved" and review.broker_approval_status == "Approved":
        review.stage = "Stage 5: Final"
        review.status = "FINAL"
        review.approved_by = f"{review.importer_approved_by} & {review.broker_approved_by}"
        review.approved_at = now

    db.commit()
    db.refresh(review)
    return review


def create_new_draft_version_service(db: Session, request: NewDraftVersionRequest) -> DraftBLReviewSession:
    parent = repo.get_draft_bl_review_by_id(db, request.parent_session_id)
    if not parent:
        raise HTTPException(status_code=404, detail="Parent Draft B/L Review not found")

    # Run new comparison
    comp_req = DraftBLComparisonRequest(
        import_file_id=parent.import_file_id,
        draft_source=request.draft_source,
        raw_draft_text=request.raw_draft_text,
        draft_fields=request.draft_fields,
    )
    comp_res = compare_draft_bl_service(db, comp_req)

    # Carry forward locks for previously approved items whose draft value didn't change
    parent_checklist_map = {c["field_key"]: c for c in (parent.checklist_data or [])}
    new_checklist = []

    for itm in comp_res["checklist_data"]:
        f_key = itm["field_key"]
        prev_itm = parent_checklist_map.get(f_key)
        if prev_itm and prev_itm.get("status") == "Correct" and str(prev_itm.get("draft_value")) == str(itm.get("draft_value")):
            itm["status"] = "Correct"
            itm["is_locked"] = True
            itm["previous_status"] = "Correct"
        else:
            itm["is_locked"] = False
            itm["previous_status"] = prev_itm.get("status") if prev_itm else None
        new_checklist.append(itm)

    new_version_num = parent.version_number + 1
    new_code = f"{parent.bl_review_code}-v{new_version_num}"

    new_session = DraftBLReviewSession(
        bl_review_code=new_code,
        import_file_id=parent.import_file_id,
        po_id=parent.po_id,
        booking_id=parent.booking_id,
        draft_bl_number=f"{parent.draft_bl_number}-v{new_version_num}",
        shipping_line=parent.shipping_line,
        vessel_name=parent.vessel_name,
        voyage_number=parent.voyage_number,
        booking_no=parent.booking_no,
        hbl_no=parent.hbl_no,
        mbl_no=parent.mbl_no,
        freight_terms=parent.freight_terms,
        place_of_delivery=parent.place_of_delivery,
        importer_tax_id=parent.importer_tax_id,
        shipper_reg_id=parent.shipper_reg_id,
        measurement_cbm=parent.measurement_cbm,
        net_weight_kg=parent.net_weight_kg,
        packages_count=parent.packages_count,
        container_summary=parent.container_summary,
        draft_source=request.draft_source,
        version_number=new_version_num,
        parent_session_id=parent.bl_review_id,
        stage="Stage 3: Reviewed",
        system_snapshot_data=comp_res["system_snapshot_data"],
        draft_input_data=request.draft_fields,
        comparison_matrix=comp_res["comparison_matrix"],
        checklist_data=new_checklist,
        revision_report_data=comp_res["revision_report_data"],
        has_blocking_mismatch=comp_res["has_blocking_mismatch"],
        open_discrepancies_count=len([c for c in new_checklist if c["status"] == "Incorrect"]),
        blocking_reasons=comp_res["blocking_reasons"],
        correction_request_letter=comp_res["correction_request_letter"],
        status="REVIEWED_PENDING_APPROVAL" if len([c for c in new_checklist if c["status"] == "Incorrect"]) == 0 else "REVISION_REQUIRED",
    )
    db.add(new_session)
    db.commit()
    db.refresh(new_session)
    return new_session


def approve_draft_bl_service(db: Session, review_id: int, approved_by: str = "Kamal") -> DraftBLReviewSession:
    review = repo.get_draft_bl_review_by_id(db, review_id)
    if not review:
        raise HTTPException(status_code=404, detail="Draft B/L Review not found")
    if review.open_discrepancies_count > 0 or review.has_blocking_mismatch:
        raise HTTPException(
            status_code=400,
            detail=f"لا يمكن اعتماد درافت البوليصة لوجود بنود غير مطابقة أو أخطاء حرجة (Blocking Discrepancies)."
        )
    review.stage = "Stage 5: Final"
    review.status = "FINAL"
    review.importer_approval_status = "Approved"
    review.importer_approved_by = approved_by
    review.importer_approval_date = datetime.now(timezone.utc)
    review.broker_approval_status = "Approved"
    review.broker_approved_by = approved_by
    review.broker_approval_date = datetime.now(timezone.utc)
    review.approved_by = approved_by
    review.approved_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(review)
    return review


# --- 3. CERTIFICATE OF ORIGIN (COO / EUR.1) VERIFICATION ENGINE ---
def compare_coo_service(db: Session, request: COOComparisonRequest) -> dict:
    imp_file = db.query(ImportFile).filter(ImportFile.import_file_id == request.import_file_id).first()
    if not imp_file:
        raise HTTPException(status_code=404, detail="Import File not found")
    company = db.query(ImportCompany).filter(ImportCompany.company_id == imp_file.company_id).first() if imp_file.company_id else None
    supplier = db.query(Supplier).filter(Supplier.supplier_id == imp_file.supplier_id).first() if imp_file.supplier_id else None

    sys_snapshot = {
        "exporter_name": supplier.company_name if supplier else imp_file.supplier_name,
        "exporter_address": supplier.address if supplier else "",
        "country_of_origin": supplier.foreign_exporter_country if supplier else "Germany",
        "importer_name": company.importer_name if company else imp_file.company_name,
        "importer_address": company.address if company else "",
        "destination_country": "Egypt",
        "invoice_number": imp_file.pi_number or "INV-2026-FINAL",
        "invoice_date": str(date.today()),
        "certificate_type": request.certificate_type,
    }

    draft_fields = request.draft_fields or {}
    matrix = []
    has_critical = False
    has_discrepancies = False

    coo_checks = [
        ("exporter_name", "اسم المصدر (Exporter Name)", True),
        ("country_of_origin", "بلد المنشأ (Country of Origin)", True),
        ("importer_name", "اسم المستورد (Importer / Consignee)", True),
        ("destination_country", "بلد المقصد (Destination Country)", True),
        ("invoice_number", "رقم الفاتورة (Commercial Invoice No)", True),
        ("certificate_type", "نوع شهادة المنشأ (Certificate Type)", False),
    ]

    for key, label_ar, is_critical in coo_checks:
        sys_val = sys_snapshot.get(key)
        drf_val = draft_fields.get(key)
        matched, ratio = _fuzzy_match(sys_val, drf_val, threshold=0.88)
        if matched:
            match_status = "MATCH"
            severity = "NONE"
        else:
            has_discrepancies = True
            if is_critical:
                has_critical = True
                match_status = "MISMATCH_CRITICAL"
                severity = "BLOCKING"
            else:
                match_status = "MISMATCH_MINOR"
                severity = "WARNING"

        matrix.append({
            "field_key": key,
            "field_label_ar": label_ar,
            "system_value": sys_val,
            "draft_value": drf_val,
            "match_status": match_status,
            "severity": severity,
            "details": f"نسبة التشابه: {round(ratio * 100, 1)}%",
        })

    status_calc = "Verified" if not has_discrepancies else ("Discrepancy_Accepted" if not has_critical else "Correction Requested")

    return {
        "import_file_id": request.import_file_id,
        "certificate_type": request.certificate_type,
        "system_snapshot_data": sys_snapshot,
        "draft_input_data": draft_fields,
        "comparison_matrix": matrix,
        "has_discrepancies": has_discrepancies,
        "has_critical_mismatch": has_critical,
        "status": status_calc,
    }


def create_coo_review_service(db: Session, schema: CertificateOfOriginReviewCreate) -> CertificateOfOriginReviewSession:
    if not schema.comparison_matrix:
        comp = compare_coo_service(db, COOComparisonRequest(
            import_file_id=schema.import_file_id,
            certificate_type=schema.certificate_type,
            draft_fields=schema.draft_input_data,
        ))
        schema.system_snapshot_data = comp["system_snapshot_data"]
        schema.comparison_matrix = comp["comparison_matrix"]
        schema.has_discrepancies = comp["has_discrepancies"]
        schema.has_critical_mismatch = comp["has_critical_mismatch"]
        schema.status = comp["status"]

    existing = repo.get_coo_review_by_file_id(db, schema.import_file_id, include_inactive=False)
    if existing:
        update_schema = CertificateOfOriginReviewUpdate(**schema.model_dump(exclude_unset=True))
        return repo.update_coo_review(db, existing.coo_review_id, update_schema)
    return repo.create_coo_review(db, schema)


def update_coo_review_service(db: Session, review_id: int, schema: CertificateOfOriginReviewUpdate) -> CertificateOfOriginReviewSession:
    return repo.update_coo_review(db, review_id, schema)


# --- 4. INSPECTION CERTIFICATE (COC / COA / VOC) VERIFICATION ENGINE ---
def compare_inspection_cert_service(db: Session, request: InspectionComparisonRequest) -> dict:
    imp_file = db.query(ImportFile).filter(ImportFile.import_file_id == request.import_file_id).first()
    if not imp_file:
        raise HTTPException(status_code=404, detail="Import File not found")
    company = db.query(ImportCompany).filter(ImportCompany.company_id == imp_file.company_id).first() if imp_file.company_id else None
    supplier = db.query(Supplier).filter(Supplier.supplier_id == imp_file.supplier_id).first() if imp_file.supplier_id else None

    sys_snapshot = {
        "importer_name": company.importer_name if company else imp_file.company_name,
        "exporter_name": supplier.company_name if supplier else imp_file.supplier_name,
        "inspection_agency": request.inspection_agency,
        "inspection_type": request.inspection_type,
        "regulatory_authority": "GOEIC (الهيئة العامة للرقابة على الصادرات والواردات)",
        "invoice_number": imp_file.pi_number or "INV-2026-FINAL",
        "standard_specification": "Egyptian Standard ES Egyptian Conformity",
    }

    draft_fields = request.draft_fields or {}
    matrix = []
    has_critical = False
    has_discrepancies = False

    insp_checks = [
        ("inspection_agency", "جهة الفحص والمعاينة (Inspection Agency)", True),
        ("importer_name", "اسم المستورد (Importer Name)", True),
        ("exporter_name", "اسم المصدر (Exporter Name)", True),
        ("regulatory_authority", "الجهة الرقابية المصرية المختصة (Regulatory Authority)", True),
        ("invoice_number", "رقم الفاتورة الخاضعة للفحص (Invoice No)", True),
        ("standard_specification", "المواصفة القياسية المعتمدة (Specification)", False),
    ]

    for key, label_ar, is_critical in insp_checks:
        sys_val = sys_snapshot.get(key)
        drf_val = draft_fields.get(key)
        matched, ratio = _fuzzy_match(sys_val, drf_val, threshold=0.88)
        if matched:
            match_status = "MATCH"
            severity = "NONE"
        else:
            has_discrepancies = True
            if is_critical:
                has_critical = True
                match_status = "MISMATCH_CRITICAL"
                severity = "BLOCKING"
            else:
                match_status = "MISMATCH_MINOR"
                severity = "WARNING"

        matrix.append({
            "field_key": key,
            "field_label_ar": label_ar,
            "system_value": sys_val,
            "draft_value": drf_val,
            "match_status": match_status,
            "severity": severity,
            "details": f"نسبة التطابق: {round(ratio * 100, 1)}%",
        })

    status_calc = "Verified" if not has_discrepancies else ("Discrepancy_Accepted" if not has_critical else "Correction Requested")

    return {
        "import_file_id": request.import_file_id,
        "inspection_type": request.inspection_type,
        "inspection_agency": request.inspection_agency,
        "system_snapshot_data": sys_snapshot,
        "draft_input_data": draft_fields,
        "comparison_matrix": matrix,
        "has_discrepancies": has_discrepancies,
        "has_critical_mismatch": has_critical,
        "status": status_calc,
    }


def create_inspection_review_service(db: Session, schema: InspectionCertificateReviewCreate) -> InspectionCertificateReviewSession:
    if not schema.comparison_matrix:
        comp = compare_inspection_cert_service(db, InspectionComparisonRequest(
            import_file_id=schema.import_file_id,
            inspection_type=schema.inspection_type,
            inspection_agency=schema.inspection_agency,
            draft_fields=schema.draft_input_data,
        ))
        schema.system_snapshot_data = comp["system_snapshot_data"]
        schema.comparison_matrix = comp["comparison_matrix"]
        schema.has_discrepancies = comp["has_discrepancies"]
        schema.has_critical_mismatch = comp["has_critical_mismatch"]
        schema.status = comp["status"]

    existing = repo.get_inspection_review_by_file_id(db, schema.import_file_id, include_inactive=False)
    if existing:
        update_schema = InspectionCertificateReviewUpdate(**schema.model_dump(exclude_unset=True))
        return repo.update_inspection_review(db, existing.inspection_review_id, update_schema)
    return repo.create_inspection_review(db, schema)


def update_inspection_review_service(db: Session, review_id: int, schema: InspectionCertificateReviewUpdate) -> InspectionCertificateReviewSession:
    return repo.update_inspection_review(db, review_id, schema)


# --- 5. ACID & IMPORTER LEGAL DOCS EXPIRY & ETA + 30 DAYS SAFETY MARGIN ENGINE ---
def check_acid_and_company_docs_validity_service(db: Session, import_file_id: int) -> LegalDocsExpiryComplianceResponse:
    imp_file = db.query(ImportFile).filter(ImportFile.import_file_id == import_file_id).first()
    if not imp_file:
        raise HTTPException(status_code=404, detail="Import File not found")

    company = db.query(ImportCompany).filter(ImportCompany.company_id == imp_file.company_id).first() if imp_file.company_id else None
    booking = db.query(ShipmentBooking).filter(ShipmentBooking.import_file_id == import_file_id, ShipmentBooking.is_active == True).first()
    acid_session = db.query(AcidRegistrationSession).filter(AcidRegistrationSession.import_file_id == import_file_id, AcidRegistrationSession.is_active == True).first()

    today = date.today()

    # Determine Estimated Time of Arrival (ETA)
    eta_date: Optional[date] = None
    eta_source = "Estimated"

    if booking and booking.eta:
        eta_date = booking.eta.date() if hasattr(booking.eta, "date") else booking.eta
        eta_source = "Freight Booking (حجز الشحن الملاحي)"
    elif imp_file.required_eta:
        eta_date = imp_file.required_eta
        eta_source = "Import File (ملف الشحنة)"
    else:
        # Default safety assumption: 21 days from today
        from datetime import timedelta
        eta_date = today + timedelta(days=21)
        eta_source = "Estimated Default (+21 Days)"

    from datetime import timedelta
    safety_window_date = eta_date + timedelta(days=30)

    alerts: List[LegalDocAlertItem] = []
    has_critical_alerts = False

    # 1. ACID Expiry Check
    if acid_session and acid_session.expiry_date:
        acid_exp = acid_session.expiry_date
        days_rem = (acid_exp - today).days
        days_after_eta = (acid_exp - eta_date).days
        is_exp = days_rem <= 0
        is_breach = acid_exp <= safety_window_date
        
        if is_exp:
            status_str = "EXPIRED"
            msg = f"رقم الـ ACID ({acid_session.acid_number}) منتهي الصلاحية بتاريخ {acid_exp}. لا يمكن شحن البضائع أو الإفراج الجمركي!"
            has_critical_alerts = True
        elif is_breach:
            status_str = "CRITICAL_BREACH"
            msg = f"تحذير حرج: رقم الـ ACID ينتهي في {acid_exp} (أقل من 30 يوماً بعد تاريخ الوصول المتوقع {eta_date}). متبقي {days_after_eta} يوم فقط بعد الـ ETA."
            has_critical_alerts = True
        else:
            status_str = "VALID"
            msg = f"رقم الـ ACID ساري وصالح حتى {acid_exp} (صالح لمدة {days_after_eta} يوم بعد وصول الشحنة)."

        alerts.append(LegalDocAlertItem(
            doc_type="رقم الـ ACID للشحنة (Nafeza ACID)",
            doc_number=acid_session.acid_number,
            expiry_date=acid_exp,
            days_until_expiry=days_rem,
            days_after_eta=days_after_eta,
            is_expired=is_exp,
            is_critical_breach=is_breach,
            alert_message=msg,
            status=status_str,
        ))
    else:
        alerts.append(LegalDocAlertItem(
            doc_type="رقم الـ ACID للشحنة (Nafeza ACID)",
            doc_number=imp_file.acid_number or "لم يصدر بعد",
            expiry_date=None,
            days_until_expiry=0,
            days_after_eta=None,
            is_expired=False,
            is_critical_breach=True,
            alert_message="لم يتم استخراج أو تسجيل تاريخ صلاحية الـ ACID للشحنة بعد.",
            status="CRITICAL_BREACH",
        ))
        has_critical_alerts = True

    # 2. Importer Legal Documents Checks (Import Card, Commercial Registry, Tax Card)
    if company:
        docs_to_check = [
            ("البطاقة الاستيرادية (Import Card)", company.importer_id or "—", company.importer_id_expiry),
            ("السجل التجاري (Commercial Registry)", company.registration_number or "—", company.registration_expiry),
            ("البطاقة الضريبية / ملف القيمة المضافة (Tax Card)", company.vat_id or "—", company.vat_id_expiry),
        ]

        for doc_name, doc_num, exp_dt in docs_to_check:
            if exp_dt:
                days_rem = (exp_dt - today).days
                days_after_eta = (exp_dt - eta_date).days
                is_exp = days_rem <= 0
                is_breach = exp_dt <= safety_window_date

                if is_exp:
                    status_str = "EXPIRED"
                    msg = f"وثيقة {doc_name} منتهية بتاريخ {exp_dt}! يجب تجديدها فوراً وإلا ستتوقف إجراءات الإفراج الجمركي."
                    has_critical_alerts = True
                elif is_breach:
                    status_str = "CRITICAL_BREACH"
                    msg = f"تحذير حرج: {doc_name} تنتهي في {exp_dt} (قبل نافذة الـ 30 يوماً من وصول الشحنة في {eta_date})."
                    has_critical_alerts = True
                elif days_rem <= 60:
                    status_str = "EXPIRING_SOON"
                    msg = f"{doc_name} قاربت على الانتهاء في {exp_dt} (متبقي {days_rem} يوم)."
                else:
                    status_str = "VALID"
                    msg = f"{doc_name} سارية وصالحة حتى {exp_dt}."

                alerts.append(LegalDocAlertItem(
                    doc_type=doc_name,
                    doc_number=str(doc_num),
                    expiry_date=exp_dt,
                    days_until_expiry=days_rem,
                    days_after_eta=days_after_eta,
                    is_expired=is_exp,
                    is_critical_breach=is_breach,
                    alert_message=msg,
                    status=status_str,
                ))

    # Overall Compliance Calculation
    overall_status = "CRITICAL_ACTION_REQUIRED" if has_critical_alerts else "COMPLIANT"
    banner_text = None
    if has_critical_alerts:
        critical_msgs = [a.alert_message for a in alerts if a.is_critical_breach or a.is_expired]
        banner_text = "🚨 تحذير حرج لسلامة الشحنة والإفراج الجمركي (ETA + 30 Days Safety Margin):\n" + "\n".join(critical_msgs)

    return LegalDocsExpiryComplianceResponse(
        import_file_id=import_file_id,
        import_file_code=imp_file.import_file_code or f"IMP-{import_file_id}",
        company_name=company.importer_name if company else (imp_file.company_name or ""),
        eta_date=eta_date,
        eta_source=eta_source,
        safety_window_date=safety_window_date,
        has_critical_alerts=has_critical_alerts,
        total_alerts_count=len(alerts),
        alerts=alerts,
        overall_compliance_status=overall_status,
        persistent_banner_text=banner_text,
    )

