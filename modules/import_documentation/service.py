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


def enrich_acid_response(item: AcidRegistrationSession) -> AcidRegistrationResponse:
    today = date.today()
    days_rem = (item.expiry_date - today).days if item.expiry_date else 0
    is_ver = (
        item.status == "Verified"
        and item.is_importer_matched
        and item.is_exporter_matched
        and item.is_invoice_matched
        and item.is_ports_matched
        and days_rem > 0
    )

    return AcidRegistrationResponse(
        acid_id=item.acid_id,
        acid_code=item.acid_code,
        acid_number=item.acid_number,
        po_id=item.po_id,
        importer_id=item.importer_id,
        importer_name=item.importer_name,
        importer_tax_id=item.importer_tax_id,
        supplier_id=item.supplier_id,
        exporter_name=item.exporter_name,
        exporter_reg_id=item.exporter_reg_id,
        exporter_country=item.exporter_country,
        proforma_invoice_no=item.proforma_invoice_no,
        pol_name=item.pol_name,
        pod_name=item.pod_name,
        requested_date=item.requested_date,
        generated_date=item.generated_date,
        expiry_date=item.expiry_date,
        is_importer_matched=item.is_importer_matched,
        is_exporter_matched=item.is_exporter_matched,
        is_invoice_matched=item.is_invoice_matched,
        is_ports_matched=item.is_ports_matched,
        verification_notes=item.verification_notes,
        status=item.status,
        days_to_expiry=days_rem,
        is_verified=is_ver,
        is_active=item.is_active,
        created_at=item.created_at,
        updated_at=item.updated_at,
    )


def create_acid_session_service(
    db: Session, schema: AcidRegistrationCreate
) -> AcidRegistrationResponse:
    validate_acid_number(schema.acid_number)
    validate_acid_expiry(schema.expiry_date, schema.requested_date)

    db_item = repo.create_acid_session(db, schema)
    return enrich_acid_response(db_item)


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
        validate_acid_number(schema.acid_number)

    updated = repo.update_acid_session(db, db_item, schema)
    return enrich_acid_response(updated)


# --- BANKING DOCUMENTS SERVICE ---
def create_banking_document_service(
    db: Session, schema: BankingDocumentCreate
) -> BankingDocumentSession:
    return repo.create_banking_document(db, schema)


# --- SHIPMENT DOCUMENTS SERVICE ---
def create_shipment_document_service(
    db: Session, schema: ShipmentDocumentCreate
) -> ShipmentDocumentItem:
    return repo.create_shipment_document(db, schema)


def update_cargox_and_bl_endorsement_service(
    db: Session,
    doc_id: int,
    cargox_envelope_id: str | None = None,
    endorsement_number: str | None = None,
) -> ShipmentDocumentItem:
    schema = ShipmentDocumentUpdate()
    if cargox_envelope_id:
        schema.is_cargox_uploaded = True
        schema.cargox_envelope_id = cargox_envelope_id
    if endorsement_number:
        schema.is_bl_endorsed = True
        schema.endorsement_number = endorsement_number
        schema.status = "Endorsed"

    return repo.update_shipment_document(db, doc_id, schema)


# --- CUSTOMS DECLARATION SERVICE ---
def create_customs_declaration_service(
    db: Session, schema: CustomsDeclarationCreate
) -> CustomsDeclarationDraft:
    return repo.create_customs_declaration(db, schema)
