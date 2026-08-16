"""
Database Repository for Import Documentation & ACI (Phase 3 - BP-014 to BP-019)
"""

from datetime import datetime, date, timezone
from sqlalchemy.orm import Session
from modules.import_documentation.model import (
    AcidRegistrationSession,
    BankingDocumentSession,
    ShipmentDocumentItem,
    CustomsDeclarationDraft,
    DraftBLReviewSession,
    CertificateOfOriginReviewSession,
    InspectionCertificateReviewSession,
)
from modules.import_documentation.schemas import (
    AcidRegistrationCreate,
    AcidRegistrationUpdate,
    BankingDocumentCreate,
    BankingDocumentUpdate,
    ShipmentDocumentCreate,
    ShipmentDocumentUpdate,
    CustomsDeclarationCreate,
)


# --- ACID REPOSITORY (BP-014) ---
def generate_acid_code(db: Session) -> str:
    current_year = datetime.now(timezone.utc).year
    prefix = f"ACID-{current_year}-"

    last_record = (
        db.query(AcidRegistrationSession)
        .filter(AcidRegistrationSession.acid_code.like(f"{prefix}%"))
        .order_by(AcidRegistrationSession.acid_id.desc())
        .first()
    )

    if not last_record:
        return f"{prefix}001"

    last_code = last_record.acid_code
    try:
        seq = int(last_code.split("-")[-1]) + 1
    except (ValueError, IndexError):
        seq = 1

    return f"{prefix}{seq:03d}"


def create_acid_session(db: Session, schema: AcidRegistrationCreate) -> AcidRegistrationSession:
    code = generate_acid_code(db)
    req_date = schema.requested_date or date.today()
    gen_date = schema.generated_date
    exp_date = schema.expiry_date or (date.today() if not gen_date else gen_date)

    db_item = AcidRegistrationSession(
        acid_code=code,
        acid_number=(schema.acid_number or "PENDING").strip(),
        import_file_id=schema.import_file_id,
        po_id=schema.po_id,
        po_number=schema.po_number,
        po_date=schema.po_date,
        importer_id=schema.importer_id,
        importer_name=schema.importer_name,
        importer_tax_id=schema.importer_tax_id,
        importer_address=schema.importer_address,
        supplier_id=schema.supplier_id,
        exporter_name=schema.exporter_name,
        exporter_reg_type=schema.exporter_reg_type or "VAT Number",
        exporter_reg_id=schema.exporter_reg_id,
        exporter_country=schema.exporter_country,
        exporter_country_code=schema.exporter_country_code,
        exporter_address=schema.exporter_address,
        exporter_phone=schema.exporter_phone,
        cargox_id=schema.cargox_id,
        proforma_invoice_no=schema.proforma_invoice_no,
        proforma_invoice_date=schema.proforma_invoice_date,
        invoice_date=schema.invoice_date,
        invoice_type=schema.invoice_type or "Proforma Invoice",
        invoice_attachment_name=schema.invoice_attachment_name,
        pol_name=schema.pol_name,
        pod_name=schema.pod_name,
        customs_broker_id=schema.customs_broker_id,
        customs_broker_name=schema.customs_broker_name,
        customs_broker_phone=schema.customs_broker_phone,
        requested_date=req_date,
        generated_date=gen_date,
        expiry_date=exp_date,
        raw_nafeza_text=schema.raw_nafeza_text,
        requested_data=schema.requested_data,
        generated_data=schema.generated_data,
        discrepancies_data=schema.discrepancies_data,
        discrepancy_override_reason=schema.discrepancy_override_reason,
        is_importer_matched=True,
        is_exporter_matched=True,
        is_invoice_matched=True,
        is_ports_matched=True,
        has_discrepancies=False,
        verification_notes=schema.verification_notes,
        status="Requested" if (schema.acid_number == "PENDING" or not gen_date) else "Verified",
        is_active=True,
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item


def get_acid_session_by_id(db: Session, acid_id: int, include_inactive: bool = False) -> AcidRegistrationSession | None:
    query = db.query(AcidRegistrationSession).filter(AcidRegistrationSession.acid_id == acid_id)
    if not include_inactive:
        query = query.filter(AcidRegistrationSession.is_active == True)
    return query.first()


def restore_acid_session(db: Session, acid_id: int) -> AcidRegistrationSession | None:
    item = get_acid_session_by_id(db, acid_id, include_inactive=True)
    if not item:
        return None
    item.is_active = True
    item.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(item)
    return item


def get_all_acid_sessions(
    db: Session,
    include_inactive: bool = False,
    search: str | None = None,
    import_file_id: int | None = None,
    status: str | None = None,
) -> list[AcidRegistrationSession]:
    query = db.query(AcidRegistrationSession)
    if not include_inactive:
        query = query.filter(AcidRegistrationSession.is_active == True)

    if import_file_id:
        query = query.filter(AcidRegistrationSession.import_file_id == import_file_id)

    if status and status != "All":
        query = query.filter(AcidRegistrationSession.status == status)

    if search:
        p = f"%{search}%"
        query = query.filter(
            AcidRegistrationSession.acid_code.ilike(p)
            | AcidRegistrationSession.acid_number.ilike(p)
            | AcidRegistrationSession.importer_name.ilike(p)
            | AcidRegistrationSession.exporter_name.ilike(p)
        )

    return query.order_by(AcidRegistrationSession.acid_id.desc()).all()


def update_acid_session(
    db: Session, db_item: AcidRegistrationSession, schema: AcidRegistrationUpdate
) -> AcidRegistrationSession:
    data = schema.model_dump(exclude_unset=True)
    for field, val in data.items():
        setattr(db_item, field, val)

    db_item.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(db_item)
    return db_item


def soft_delete_acid_session(db: Session, acid_id: int) -> bool:
    item = get_acid_session_by_id(db, acid_id)
    if not item:
        return False
    item.is_active = False
    item.updated_at = datetime.now(timezone.utc)
    db.commit()
    return True


# --- BANKING DOCUMENTS REPOSITORY (BP-015) ---
def generate_bank_doc_code(db: Session) -> str:
    current_year = datetime.now(timezone.utc).year
    prefix = f"FORM4-{current_year}-"

    last_record = (
        db.query(BankingDocumentSession)
        .filter(BankingDocumentSession.bank_doc_code.like(f"{prefix}%"))
        .order_by(BankingDocumentSession.bank_doc_id.desc())
        .first()
    )

    if not last_record:
        return f"{prefix}001"

    last_code = last_record.bank_doc_code
    try:
        seq = int(last_code.split("-")[-1]) + 1
    except (ValueError, IndexError):
        seq = 1

    return f"{prefix}{seq:03d}"


def create_banking_document(db: Session, schema: BankingDocumentCreate) -> BankingDocumentSession:
    code = generate_bank_doc_code(db)
    req_date = schema.request_date or schema.issue_date or date.today()
    iss_date = schema.issue_date or req_date
    rec_date = schema.received_date
    exec_days = schema.execution_days or 0
    if rec_date and req_date:
        exec_days = max(0, (rec_date - req_date).days)

    ref_num = schema.doc_reference_number or "PENDING"
    initial_status = "Received" if rec_date or (ref_num != "PENDING" and ref_num.strip()) else "Requested"

    db_item = BankingDocumentSession(
        bank_doc_code=code,
        doc_type=schema.doc_type,
        import_file_id=schema.import_file_id,
        po_id=schema.po_id,
        bank_id=schema.bank_id,
        bank_name=schema.bank_name,
        doc_reference_number=ref_num,
        amount=schema.amount,
        currency_code=schema.currency_code,
        request_date=req_date,
        received_date=rec_date,
        execution_days=exec_days,
        issue_date=iss_date,
        expiry_date=schema.expiry_date,
        status=initial_status,
        notes=schema.notes,
        is_active=True,
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item


def get_banking_document_by_id(db: Session, bank_doc_id: int) -> BankingDocumentSession | None:
    return db.query(BankingDocumentSession).filter(
        BankingDocumentSession.bank_doc_id == bank_doc_id,
        BankingDocumentSession.is_active == True,
    ).first()


def update_banking_document(
    db: Session, db_item: BankingDocumentSession, schema: BankingDocumentUpdate
) -> BankingDocumentSession:
    update_data = schema.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if hasattr(db_item, field) and value is not None:
            setattr(db_item, field, value)

    # Recalculate execution days if dates changed
    if db_item.received_date and db_item.request_date:
        db_item.execution_days = max(0, (db_item.received_date - db_item.request_date).days)
        if db_item.doc_reference_number and db_item.doc_reference_number != "PENDING":
            db_item.status = "Received"

    db_item.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(db_item)
    return db_item


def delete_banking_document(db: Session, db_item: BankingDocumentSession) -> bool:
    db_item.is_active = False
    db_item.updated_at = datetime.now(timezone.utc)
    db.commit()
    return True


def get_all_banking_documents(db: Session, import_file_id: int | None = None) -> list[BankingDocumentSession]:
    query = db.query(BankingDocumentSession).filter(BankingDocumentSession.is_active == True)
    if import_file_id:
        query = query.filter(BankingDocumentSession.import_file_id == import_file_id)
    return query.order_by(BankingDocumentSession.bank_doc_id.desc()).all()



# --- SHIPMENT DOCUMENT ITEMS REPOSITORY (BP-016 to BP-018) ---
def generate_shipment_doc_code(db: Session) -> str:
    current_year = datetime.now(timezone.utc).year
    prefix = f"DOC-{current_year}-"

    last_record = (
        db.query(ShipmentDocumentItem)
        .filter(ShipmentDocumentItem.document_code.like(f"{prefix}%"))
        .order_by(ShipmentDocumentItem.document_id.desc())
        .first()
    )

    if not last_record:
        return f"{prefix}001"

    last_code = last_record.document_code
    try:
        seq = int(last_code.split("-")[-1]) + 1
    except (ValueError, IndexError):
        seq = 1

    return f"{prefix}{seq:03d}"


def create_shipment_document(db: Session, schema: ShipmentDocumentCreate) -> ShipmentDocumentItem:
    code = generate_shipment_doc_code(db)
    iss_date = schema.issue_date or date.today()
    rec_date = schema.received_date or date.today()

    db_item = ShipmentDocumentItem(
        document_code=code,
        import_file_id=schema.import_file_id,
        po_id=schema.po_id,
        doc_name=schema.doc_name,
        doc_number=schema.doc_number,
        issue_date=iss_date,
        received_date=rec_date,
        status="Approved",
        is_cargox_uploaded=False,
        is_bl_endorsed=False,
        notes=schema.notes,
        is_active=True,
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item


def get_all_shipment_documents(db: Session, import_file_id: int | None = None) -> list[ShipmentDocumentItem]:
    query = db.query(ShipmentDocumentItem).filter(ShipmentDocumentItem.is_active == True)
    if import_file_id:
        query = query.filter(ShipmentDocumentItem.import_file_id == import_file_id)
    return query.order_by(ShipmentDocumentItem.document_id.desc()).all()


def update_shipment_document(
    db: Session, doc_id: int, schema: ShipmentDocumentUpdate
) -> ShipmentDocumentItem:
    item = (
        db.query(ShipmentDocumentItem)
        .filter(ShipmentDocumentItem.document_id == doc_id, ShipmentDocumentItem.is_active == True)
        .first()
    )
    if not item:
        raise ValueError(f"Shipment Document ID {doc_id} not found.")

    data = schema.model_dump(exclude_unset=True)
    for field, val in data.items():
        setattr(item, field, val)

    item.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(item)
    return item


# --- CUSTOMS DECLARATION 46 REPOSITORY (BP-019) ---
def create_customs_declaration(
    db: Session, schema: CustomsDeclarationCreate
) -> CustomsDeclarationDraft:
    current_year = datetime.now(timezone.utc).year
    code = f"DEC46-{current_year}-001"

    db_item = CustomsDeclarationDraft(
        declaration_code=code,
        import_file_id=schema.import_file_id,
        po_id=schema.po_id,
        acid_number=schema.acid_number,
        form4_number=schema.form4_number,
        bl_number=schema.bl_number,
        total_cif_val_egp=schema.total_cif_val_egp,
        total_customs_duties_egp=schema.total_customs_duties_egp,
        total_vat_egp=schema.total_vat_egp,
        declaration_status="Draft Prepared",
        is_active=True,
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item


# --- PHASE 6: DRAFT BILL OF LADING (B/L) REPOSITORY ---
def generate_bl_review_code(db: Session) -> str:
    current_year = datetime.now(timezone.utc).year
    prefix = f"BL-REV-{current_year}-"
    last_record = (
        db.query(DraftBLReviewSession)
        .filter(DraftBLReviewSession.bl_review_code.like(f"{prefix}%"))
        .order_by(DraftBLReviewSession.bl_review_id.desc())
        .first()
    )
    if not last_record:
        return f"{prefix}0001"
    try:
        num = int(last_record.bl_review_code.replace(prefix, "")) + 1
        return f"{prefix}{num:04d}"
    except ValueError:
        return f"{prefix}0001"


def get_draft_bl_reviews(
    db: Session,
    include_inactive: bool = False,
    import_file_id: int | None = None,
    status: str | None = None,
    search: str | None = None,
) -> list[DraftBLReviewSession]:
    query = db.query(DraftBLReviewSession)
    if not include_inactive:
        query = query.filter(DraftBLReviewSession.is_active == True)
    if import_file_id:
        query = query.filter(DraftBLReviewSession.import_file_id == import_file_id)
    if status and status != "All":
        query = query.filter(DraftBLReviewSession.status == status)
    if search:
        s = f"%{search.strip()}%"
        query = query.filter(
            (DraftBLReviewSession.bl_review_code.ilike(s))
            | (DraftBLReviewSession.draft_bl_number.ilike(s))
            | (DraftBLReviewSession.shipping_line.ilike(s))
            | (DraftBLReviewSession.booking_no.ilike(s))
            | (DraftBLReviewSession.hbl_no.ilike(s))
            | (DraftBLReviewSession.mbl_no.ilike(s))
        )
    return query.order_by(DraftBLReviewSession.bl_review_id.desc()).all()


def get_draft_bl_review_by_id(db: Session, review_id: int, include_inactive: bool = False) -> DraftBLReviewSession | None:
    query = db.query(DraftBLReviewSession).filter(DraftBLReviewSession.bl_review_id == review_id)
    if not include_inactive:
        query = query.filter(DraftBLReviewSession.is_active == True)
    return query.first()


def get_draft_bl_review_by_file_id(db: Session, import_file_id: int, include_inactive: bool = False) -> DraftBLReviewSession | None:
    query = db.query(DraftBLReviewSession).filter(DraftBLReviewSession.import_file_id == import_file_id)
    if not include_inactive:
        query = query.filter(DraftBLReviewSession.is_active == True)
    return query.order_by(DraftBLReviewSession.bl_review_id.desc()).first()


def create_draft_bl_review(db: Session, schema: DraftBLReviewCreate) -> DraftBLReviewSession:
    code = generate_bl_review_code(db)
    data = schema.model_dump(exclude_unset=True)
    db_item = DraftBLReviewSession(
        bl_review_code=code,
        **data,
        is_active=True,
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item


def update_draft_bl_review(db: Session, review_id: int, schema: DraftBLReviewUpdate) -> DraftBLReviewSession:
    item = db.query(DraftBLReviewSession).filter(DraftBLReviewSession.bl_review_id == review_id).first()
    if not item:
        raise ValueError(f"Draft B/L Review ID {review_id} not found.")
    data = schema.model_dump(exclude_unset=True)
    for k, v in data.items():
        setattr(item, k, v)
    item.is_active = True
    item.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(item)
    return item


def delete_draft_bl_review(db: Session, review_id: int) -> bool:
    item = db.query(DraftBLReviewSession).filter(DraftBLReviewSession.bl_review_id == review_id).first()
    if not item:
        return False
    item.is_active = False
    item.updated_at = datetime.now(timezone.utc)
    db.commit()
    return True


# --- PHASE 6: CERTIFICATE OF ORIGIN (COO / EUR.1) REPOSITORY ---
def generate_coo_review_code(db: Session) -> str:
    current_year = datetime.now(timezone.utc).year
    prefix = f"COO-{current_year}-"
    last_record = (
        db.query(CertificateOfOriginReviewSession)
        .filter(CertificateOfOriginReviewSession.coo_review_code.like(f"{prefix}%"))
        .order_by(CertificateOfOriginReviewSession.coo_review_id.desc())
        .first()
    )
    if not last_record:
        return f"{prefix}0001"
    try:
        num = int(last_record.coo_review_code.replace(prefix, "")) + 1
        return f"{prefix}{num:04d}"
    except ValueError:
        return f"{prefix}0001"


def get_coo_reviews(
    db: Session,
    include_inactive: bool = False,
    import_file_id: int | None = None,
    status: str | None = None,
    search: str | None = None,
) -> list[CertificateOfOriginReviewSession]:
    query = db.query(CertificateOfOriginReviewSession)
    if not include_inactive:
        query = query.filter(CertificateOfOriginReviewSession.is_active == True)
    if import_file_id:
        query = query.filter(CertificateOfOriginReviewSession.import_file_id == import_file_id)
    if status and status != "All":
        query = query.filter(CertificateOfOriginReviewSession.status == status)
    if search:
        s = f"%{search.strip()}%"
        query = query.filter(
            (CertificateOfOriginReviewSession.coo_review_code.ilike(s))
            | (CertificateOfOriginReviewSession.certificate_number.ilike(s))
            | (CertificateOfOriginReviewSession.exporter_name.ilike(s))
            | (CertificateOfOriginReviewSession.importer_name.ilike(s))
            | (CertificateOfOriginReviewSession.invoice_number.ilike(s))
        )
    return query.order_by(CertificateOfOriginReviewSession.coo_review_id.desc()).all()


def get_coo_review_by_id(db: Session, review_id: int, include_inactive: bool = False) -> CertificateOfOriginReviewSession | None:
    query = db.query(CertificateOfOriginReviewSession).filter(CertificateOfOriginReviewSession.coo_review_id == review_id)
    if not include_inactive:
        query = query.filter(CertificateOfOriginReviewSession.is_active == True)
    return query.first()


def get_coo_review_by_file_id(db: Session, import_file_id: int, include_inactive: bool = False) -> CertificateOfOriginReviewSession | None:
    query = db.query(CertificateOfOriginReviewSession).filter(CertificateOfOriginReviewSession.import_file_id == import_file_id)
    if not include_inactive:
        query = query.filter(CertificateOfOriginReviewSession.is_active == True)
    return query.order_by(CertificateOfOriginReviewSession.coo_review_id.desc()).first()


def create_coo_review(db: Session, schema: CertificateOfOriginReviewCreate) -> CertificateOfOriginReviewSession:
    code = generate_coo_review_code(db)
    data = schema.model_dump(exclude_unset=True)
    db_item = CertificateOfOriginReviewSession(
        coo_review_code=code,
        **data,
        is_active=True,
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item


def update_coo_review(db: Session, review_id: int, schema: CertificateOfOriginReviewUpdate) -> CertificateOfOriginReviewSession:
    item = db.query(CertificateOfOriginReviewSession).filter(CertificateOfOriginReviewSession.coo_review_id == review_id).first()
    if not item:
        raise ValueError(f"COO Review ID {review_id} not found.")
    data = schema.model_dump(exclude_unset=True)
    for k, v in data.items():
        setattr(item, k, v)
    item.is_active = True
    item.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(item)
    return item


def delete_coo_review(db: Session, review_id: int) -> bool:
    item = db.query(CertificateOfOriginReviewSession).filter(CertificateOfOriginReviewSession.coo_review_id == review_id).first()
    if not item:
        return False
    item.is_active = False
    item.updated_at = datetime.now(timezone.utc)
    db.commit()
    return True


# --- PHASE 6: INSPECTION CERTIFICATE REPOSITORY ---
def generate_inspection_review_code(db: Session) -> str:
    current_year = datetime.now(timezone.utc).year
    prefix = f"INSP-{current_year}-"
    last_record = (
        db.query(InspectionCertificateReviewSession)
        .filter(InspectionCertificateReviewSession.inspection_review_code.like(f"{prefix}%"))
        .order_by(InspectionCertificateReviewSession.inspection_review_id.desc())
        .first()
    )
    if not last_record:
        return f"{prefix}0001"
    try:
        num = int(last_record.inspection_review_code.replace(prefix, "")) + 1
        return f"{prefix}{num:04d}"
    except ValueError:
        return f"{prefix}0001"


def get_inspection_reviews(
    db: Session,
    include_inactive: bool = False,
    import_file_id: int | None = None,
    status: str | None = None,
    search: str | None = None,
) -> list[InspectionCertificateReviewSession]:
    query = db.query(InspectionCertificateReviewSession)
    if not include_inactive:
        query = query.filter(InspectionCertificateReviewSession.is_active == True)
    if import_file_id:
        query = query.filter(InspectionCertificateReviewSession.import_file_id == import_file_id)
    if status and status != "All":
        query = query.filter(InspectionCertificateReviewSession.status == status)
    if search:
        s = f"%{search.strip()}%"
        query = query.filter(
            (InspectionCertificateReviewSession.inspection_review_code.ilike(s))
            | (InspectionCertificateReviewSession.certificate_number.ilike(s))
            | (InspectionCertificateReviewSession.inspection_agency.ilike(s))
            | (InspectionCertificateReviewSession.inspection_type.ilike(s))
            | (InspectionCertificateReviewSession.regulatory_authority.ilike(s))
        )
    return query.order_by(InspectionCertificateReviewSession.inspection_review_id.desc()).all()


def get_inspection_review_by_id(db: Session, review_id: int, include_inactive: bool = False) -> InspectionCertificateReviewSession | None:
    query = db.query(InspectionCertificateReviewSession).filter(InspectionCertificateReviewSession.inspection_review_id == review_id)
    if not include_inactive:
        query = query.filter(InspectionCertificateReviewSession.is_active == True)
    return query.first()


def get_inspection_review_by_file_id(db: Session, import_file_id: int, include_inactive: bool = False) -> InspectionCertificateReviewSession | None:
    query = db.query(InspectionCertificateReviewSession).filter(InspectionCertificateReviewSession.import_file_id == import_file_id)
    if not include_inactive:
        query = query.filter(InspectionCertificateReviewSession.is_active == True)
    return query.order_by(InspectionCertificateReviewSession.inspection_review_id.desc()).first()


def create_inspection_review(db: Session, schema: InspectionCertificateReviewCreate) -> InspectionCertificateReviewSession:
    code = generate_inspection_review_code(db)
    data = schema.model_dump(exclude_unset=True)
    db_item = InspectionCertificateReviewSession(
        inspection_review_code=code,
        **data,
        is_active=True,
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item


def update_inspection_review(db: Session, review_id: int, schema: InspectionCertificateReviewUpdate) -> InspectionCertificateReviewSession:
    item = db.query(InspectionCertificateReviewSession).filter(InspectionCertificateReviewSession.inspection_review_id == review_id).first()
    if not item:
        raise ValueError(f"Inspection Review ID {review_id} not found.")
    data = schema.model_dump(exclude_unset=True)
    for k, v in data.items():
        setattr(item, k, v)
    item.is_active = True
    item.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(item)
    return item


def delete_inspection_review(db: Session, review_id: int) -> bool:
    item = db.query(InspectionCertificateReviewSession).filter(InspectionCertificateReviewSession.inspection_review_id == review_id).first()
    if not item:
        return False
    item.is_active = False
    item.updated_at = datetime.now(timezone.utc)
    db.commit()
    return True
