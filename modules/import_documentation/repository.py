"""
Database Repository for Import Documentation & ACI (Phase 3 - BP-014 to BP-019)
"""

from datetime import datetime, date
from sqlalchemy.orm import Session
from modules.import_documentation.model import (
    AcidRegistrationSession,
    BankingDocumentSession,
    ShipmentDocumentItem,
    CustomsDeclarationDraft,
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
    current_year = datetime.utcnow().year
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
    gen_date = schema.generated_date or date.today()

    db_item = AcidRegistrationSession(
        acid_code=code,
        acid_number=schema.acid_number.strip(),
        import_file_id=schema.import_file_id,
        po_id=schema.po_id,
        importer_id=schema.importer_id,
        importer_name=schema.importer_name,
        importer_tax_id=schema.importer_tax_id,
        supplier_id=schema.supplier_id,
        exporter_name=schema.exporter_name,
        exporter_reg_id=schema.exporter_reg_id,
        exporter_country=schema.exporter_country,
        proforma_invoice_no=schema.proforma_invoice_no,
        pol_name=schema.pol_name,
        pod_name=schema.pod_name,
        requested_date=req_date,
        generated_date=gen_date,
        expiry_date=schema.expiry_date,
        is_importer_matched=True,
        is_exporter_matched=True,
        is_invoice_matched=True,
        is_ports_matched=True,
        verification_notes=schema.verification_notes,
        status="Verified",
        is_active=True,
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item


def get_acid_session_by_id(db: Session, acid_id: int) -> AcidRegistrationSession | None:
    return (
        db.query(AcidRegistrationSession)
        .filter(AcidRegistrationSession.acid_id == acid_id, AcidRegistrationSession.is_active == True)
        .first()
    )


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

    db_item.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_item)
    return db_item


def soft_delete_acid_session(db: Session, acid_id: int) -> bool:
    item = get_acid_session_by_id(db, acid_id)
    if not item:
        return False
    item.is_active = False
    item.updated_at = datetime.utcnow()
    db.commit()
    return True


# --- BANKING DOCUMENTS REPOSITORY (BP-015) ---
def generate_bank_doc_code(db: Session) -> str:
    current_year = datetime.utcnow().year
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
    iss_date = schema.issue_date or date.today()

    db_item = BankingDocumentSession(
        bank_doc_code=code,
        doc_type=schema.doc_type,
        import_file_id=schema.import_file_id,
        po_id=schema.po_id,
        bank_id=schema.bank_id,
        bank_name=schema.bank_name,
        doc_reference_number=schema.doc_reference_number,
        amount=schema.amount,
        currency_code=schema.currency_code,
        issue_date=iss_date,
        expiry_date=schema.expiry_date,
        status="Form Issued",
        notes=schema.notes,
        is_active=True,
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item


def get_all_banking_documents(db: Session, import_file_id: int | None = None) -> list[BankingDocumentSession]:
    query = db.query(BankingDocumentSession).filter(BankingDocumentSession.is_active == True)
    if import_file_id:
        query = query.filter(BankingDocumentSession.import_file_id == import_file_id)
    return query.order_by(BankingDocumentSession.bank_doc_id.desc()).all()


# --- SHIPMENT DOCUMENT ITEMS REPOSITORY (BP-016 to BP-018) ---
def generate_shipment_doc_code(db: Session) -> str:
    current_year = datetime.utcnow().year
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

    item.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(item)
    return item


# --- CUSTOMS DECLARATION 46 REPOSITORY (BP-019) ---
def create_customs_declaration(
    db: Session, schema: CustomsDeclarationCreate
) -> CustomsDeclarationDraft:
    current_year = datetime.utcnow().year
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
