"""
Service Layer & Business Engine for Import Documentation & ACI (Phase 3 - BP-014 to BP-019)
"""

from datetime import date
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
import modules.import_documentation.repository as repo
from modules.import_documentation.validators import (
    validate_acid_number,
    validate_acid_expiry,
)


from modules.import_documentation.nafeza_acid_parser import (
    parse_nafeza_acid_text,
    compare_acid_data,
    generate_whatsapp_request_text,
    generate_email_request_template,
)


def enrich_acid_response(db: Session, item: AcidRegistrationSession) -> AcidRegistrationResponse:
    today = date.today()
    days_rem = (item.expiry_date - today).days if item.expiry_date else 0
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
        is_verified=is_ver,
        is_active=item.is_active,
        created_at=item.created_at,
        updated_at=item.updated_at,
    )


def enrich_banking_response(db: Session, item: BankingDocumentSession):
    import_file_code = None
    if item.import_file_id:
        from modules.import_files.model import ImportFile
        imp = db.query(ImportFile).filter(ImportFile.import_file_id == item.import_file_id).first()
        if imp:
            import_file_code = imp.import_file_code or imp.custom_file_number

    from modules.import_documentation.schemas import BankingDocumentResponse
    res = BankingDocumentResponse.model_validate(item)
    res.import_file_code = import_file_code
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

    db_item = repo.create_acid_session(db, schema)

    # Sync with import file if applicable
    if db_item.import_file_id and db_item.acid_number and db_item.acid_number != "PENDING":
        from modules.import_files.model import ImportFile
        imp = db.query(ImportFile).filter(ImportFile.import_file_id == db_item.import_file_id).first()
        if imp:
            imp.acid_number = db_item.acid_number
            imp.acid_issue_date = db_item.generated_date or db_item.requested_date
            imp.acid_expiry_date = db_item.expiry_date
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

    if schema.acid_number:
        validate_acid_number(schema.acid_number, allow_pending=True)

    updated = repo.update_acid_session(db, db_item, schema)

    # Sync with import file if applicable
    if updated.import_file_id and updated.acid_number and updated.acid_number != "PENDING":
        from modules.import_files.model import ImportFile
        imp = db.query(ImportFile).filter(ImportFile.import_file_id == updated.import_file_id).first()
        if imp:
            imp.acid_number = updated.acid_number
            if updated.generated_date:
                imp.acid_issue_date = updated.generated_date
            elif updated.requested_date and not imp.acid_issue_date:
                imp.acid_issue_date = updated.requested_date
            if updated.expiry_date:
                imp.acid_expiry_date = updated.expiry_date
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
                "cargox_id": getattr(supp_obj, "cargox_id", ""),
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
    item = repo.create_banking_document(db, schema)
    return enrich_banking_response(db, item)


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
