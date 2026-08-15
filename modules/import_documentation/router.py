"""
FastAPI Router for Import Documentation & ACI (Phase 3 - BP-014 to BP-019)
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from database.database import get_db
from modules.import_documentation.schemas import (
    AcidRegistrationCreate,
    AcidRegistrationUpdate,
    AcidRegistrationResponse,
    AcidTextParseRequest,
    AcidTextParseResponse,
    AcidComparisonRequest,
    AcidRequestTemplateResponse,
    AcidTrackerSummary,
    BankingDocumentCreate,
    BankingDocumentUpdate,
    BankingDocumentReceive,
    BankingDocumentResponse,
    ShipmentDocumentCreate,
    ShipmentDocumentUpdate,
    ShipmentDocumentResponse,
    CustomsDeclarationCreate,
    CustomsDeclarationResponse,
)
import modules.import_documentation.service as service
import modules.import_documentation.repository as repo

router = APIRouter(prefix="/api/v1/import-documentation", tags=["Import Documentation"])


# --- ACID REGISTRATION & TRACKER ENDPOINTS (BP-014) ---
@router.get(
    "/acid/tracker",
    response_model=AcidTrackerSummary,
    status_code=status.HTTP_200_OK,
)
def get_acid_tracker(db: Session = Depends(get_db)):
    """
    ACID Expiry Tracker: Lists all active ACID registrations and import files with
    calculated days remaining, validity %, and customs release status (alerts removed once customs released).
    """
    return service.get_acid_tracker_service(db)


@router.post(
    "/acid/parse-text",
    response_model=AcidTextParseResponse,
    status_code=status.HTTP_200_OK,
)
def parse_acid_text(payload: AcidTextParseRequest, db: Session = Depends(get_db)):
    """
    Smart Nafeza Text Parser: Extracts structured ACID fields from raw MTS text notifications
    and optionally computes live discrepancy comparison against the selected import file.
    """
    res = service.parse_acid_text_service(db, payload.raw_text, payload.import_file_id)
    return res


@router.post(
    "/acid/compare",
    status_code=status.HTTP_200_OK,
)
def compare_acid_data(payload: AcidComparisonRequest):
    """
    Compares requested shipment parameters with generated ACID data and returns a discrepancy matrix.
    """
    return service.compare_acid_datasets_service(payload.requested, payload.generated)


@router.post(
    "/acid/templates",
    response_model=AcidRequestTemplateResponse,
    status_code=status.HTTP_200_OK,
)
def generate_acid_templates(payload: dict):
    """
    Generates ready-to-use WhatsApp and Email templates for customs broker communication.
    """
    return service.generate_acid_templates_service(payload)


@router.post(
    "/acid-sessions",
    response_model=AcidRegistrationResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_acid_session(
    payload: AcidRegistrationCreate, db: Session = Depends(get_db)
):
    return service.create_acid_session_service(db, payload)


@router.get("/acid-sessions", response_model=List[AcidRegistrationResponse])
def list_acid_sessions(
    include_inactive: bool = False,
    search: Optional[str] = None,
    import_file_id: Optional[int] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
):
    items = repo.get_all_acid_sessions(
        db, include_inactive=include_inactive, search=search, import_file_id=import_file_id, status=status
    )
    return [service.enrich_acid_response(db, item) for item in items]


@router.get(
    "/acid-sessions/{acid_id}", response_model=AcidRegistrationResponse
)
def get_acid_session(acid_id: int, db: Session = Depends(get_db)):
    item = repo.get_acid_session_by_id(db, acid_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"ACID Registration Session ID {acid_id} not found.",
        )
    return service.enrich_acid_response(db, item)


@router.put(
    "/acid-sessions/{acid_id}", response_model=AcidRegistrationResponse
)
def update_acid_session(
    acid_id: int,
    payload: AcidRegistrationUpdate,
    db: Session = Depends(get_db),
):
    return service.update_acid_session_service(db, acid_id, payload)


@router.delete("/acid-sessions/{acid_id}", status_code=status.HTTP_204_NO_CONTENT)
def soft_delete_acid_session(acid_id: int, db: Session = Depends(get_db)):
    success = repo.soft_delete_acid_session(db, acid_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"ACID Registration Session ID {acid_id} not found.",
        )


@router.patch("/acid-sessions/{acid_id}/restore", response_model=AcidRegistrationResponse)
def restore_acid_session(acid_id: int, db: Session = Depends(get_db)):
    return service.restore_acid_session_service(db, acid_id)


# --- BANKING DOCUMENTS ENDPOINTS (BP-015) ---
@router.post(
    "/banking-documents",
    response_model=BankingDocumentResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_banking_document(
    payload: BankingDocumentCreate, db: Session = Depends(get_db)
):
    return service.create_banking_document_service(db, payload)


@router.get("/banking-documents", response_model=List[BankingDocumentResponse])
def list_banking_documents(import_file_id: Optional[int] = None, db: Session = Depends(get_db)):
    items = repo.get_all_banking_documents(db, import_file_id=import_file_id)
    return [service.enrich_banking_response(db, item) for item in items]


@router.get("/banking-documents/{bank_doc_id}", response_model=BankingDocumentResponse)
def get_banking_document(bank_doc_id: int, db: Session = Depends(get_db)):
    item = repo.get_banking_document_by_id(db, bank_doc_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Banking Document ID {bank_doc_id} not found.",
        )
    return service.enrich_banking_response(db, item)


@router.put("/banking-documents/{bank_doc_id}", response_model=BankingDocumentResponse)
def update_banking_document(
    bank_doc_id: int, payload: BankingDocumentUpdate, db: Session = Depends(get_db)
):
    return service.update_banking_document_service(db, bank_doc_id, payload)


@router.post(
    "/banking-documents/{bank_doc_id}/receive",
    response_model=BankingDocumentResponse,
)
def receive_banking_document(
    bank_doc_id: int, payload: BankingDocumentReceive, db: Session = Depends(get_db)
):
    return service.receive_banking_document_service(
        db,
        bank_doc_id,
        form4_number=payload.form4_number,
        received_date=payload.received_date,
        notes=payload.notes,
    )


@router.delete("/banking-documents/{bank_doc_id}")
def delete_banking_document(bank_doc_id: int, db: Session = Depends(get_db)):
    return service.delete_banking_document_service(db, bank_doc_id)


# --- SHIPMENT DOCUMENTS & CARGOX ENDPOINTS (BP-016, BP-017, BP-018) ---
@router.post(
    "/shipment-documents",
    response_model=ShipmentDocumentResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_shipment_document(
    payload: ShipmentDocumentCreate, db: Session = Depends(get_db)
):
    return service.create_shipment_document_service(db, payload)


@router.get("/shipment-documents", response_model=List[ShipmentDocumentResponse])
def list_shipment_documents(import_file_id: Optional[int] = None, db: Session = Depends(get_db)):
    items = repo.get_all_shipment_documents(db, import_file_id=import_file_id)
    return [service.enrich_shipment_doc_response(db, item) for item in items]


@router.post(
    "/shipment-documents/{doc_id}/cargox-bl",
    response_model=ShipmentDocumentResponse,
)
def update_cargox_and_bl_endorsement(
    doc_id: int,
    cargox_envelope_id: Optional[str] = None,
    endorsement_number: Optional[str] = None,
    db: Session = Depends(get_db),
):
    return service.update_cargox_and_bl_endorsement_service(
        db, doc_id, cargox_envelope_id, endorsement_number
    )


# --- CUSTOMS DECLARATION 46 ENDPOINTS (BP-019) ---
@router.post(
    "/customs-declarations",
    response_model=CustomsDeclarationResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_customs_declaration(
    payload: CustomsDeclarationCreate, db: Session = Depends(get_db)
):
    return service.create_customs_declaration_service(db, payload)
