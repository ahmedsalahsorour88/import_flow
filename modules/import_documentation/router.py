"""
FastAPI Router for Import Documentation & ACI (Phase 3 - BP-014 to BP-019)
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
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
    DraftBLComparisonRequest,
    DraftBLReviewCreate,
    DraftBLReviewUpdate,
    DraftBLReviewResponse,
    CertificateOfOriginReviewCreate,
    CertificateOfOriginReviewUpdate,
    CertificateOfOriginReviewResponse,
    COOComparisonRequest,
    InspectionCertificateReviewCreate,
    InspectionCertificateReviewUpdate,
    InspectionCertificateReviewResponse,
    InspectionComparisonRequest,
    LegalDocsExpiryComplianceResponse,
    InvoiceBLExtractAndMatchRequest,
    InvoiceBLExtractAndMatchResponse,
    InvoiceBLSyncRequest,
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


# ==============================================================================
# PHASE 6: INTELLIGENT DOCUMENT VERIFICATION & COMPARISON ENDPOINTS
# ==============================================================================
from modules.import_documentation.schemas import (
    POFinalAdjustmentRequest,
    POExtractAndCompareRequest,
    POExtractAndCompareResponse,
    DraftBLComparisonRequest,
    DraftBLReviewCreate,
    DraftBLReviewUpdate,
    DraftBLReviewResponse,
    COOComparisonRequest,
    CertificateOfOriginReviewCreate,
    CertificateOfOriginReviewUpdate,
    CertificateOfOriginReviewResponse,
    InspectionComparisonRequest,
    InspectionCertificateReviewCreate,
    InspectionCertificateReviewUpdate,
    InspectionCertificateReviewResponse,
    LegalDocsExpiryComplianceResponse,
)


# --- 1. PO FINAL RECONCILIATION ---
@router.post("/po-reconciliation", status_code=status.HTTP_200_OK)
def reconcile_po_final_adjustments(
    payload: POFinalAdjustmentRequest, db: Session = Depends(get_db)
):
    return service.reconcile_po_final_adjustments_service(db, payload)


@router.post(
    "/po-reconciliation/extract-and-compare",
    response_model=POExtractAndCompareResponse,
    status_code=status.HTTP_200_OK,
)
def extract_and_compare_po_documents(
    payload: POExtractAndCompareRequest, db: Session = Depends(get_db)
):
    """
    Intelligently extracts Commercial Invoice and Final Packing List data,
    executes 3-way reconciliation against System PO, and returns discrepancy variances.
    """
    return service.extract_and_compare_po_documents_service(db, payload)


@router.post(
    "/po-reconciliation/extract-files-and-compare",
    response_model=POExtractAndCompareResponse,
    status_code=status.HTTP_200_OK,
)
async def extract_po_reconciliation_files_and_compare(
    invoice_file: Optional[UploadFile] = File(None),
    packing_file: Optional[UploadFile] = File(None),
    import_file_id: Optional[int] = Form(None),
    invoice_text: Optional[str] = Form(None),
    packing_text: Optional[str] = Form(None),
    db: Session = Depends(get_db),
):
    """
    Accepts uploaded Commercial Invoice and/or Packing List files (PDF, Word, Excel, Text)
    and executes 3-way reconciliation against System PO data.
    """
    inv_raw = invoice_text or ""
    pl_raw = packing_text or ""

    if invoice_file:
        content = await invoice_file.read()
        inv_raw = service.extract_text_from_uploaded_file(invoice_file.filename, content)

    if packing_file:
        content = await packing_file.read()
        pl_raw = service.extract_text_from_uploaded_file(packing_file.filename, content)

    req = POExtractAndCompareRequest(
        import_file_id=import_file_id,
        invoice_raw_text=inv_raw,
        packing_list_raw_text=pl_raw,
    )
    return service.extract_and_compare_po_documents_service(db, req)



# --- 2. DRAFT BILL OF LADING (B/L) ENDPOINTS ---
@router.post("/draft-bl/extract-file", status_code=status.HTTP_200_OK)
async def extract_draft_bl_from_file(
    file: UploadFile = File(...),
    import_file_id: Optional[int] = Form(None),
    db: Session = Depends(get_db),
):
    """
    Extracts raw text from uploaded PDF, Word, Excel, or Text file, extracts B/L fields,
    and optionally executes comparison against the active import file.
    """
    content_bytes = await file.read()
    raw_text = service.extract_text_from_uploaded_file(file.filename, content_bytes)
    extracted_fields = service.parse_draft_bl_raw_text(raw_text)

    comp_result = None
    if import_file_id:
        comp_req = DraftBLComparisonRequest(
            import_file_id=import_file_id,
            draft_source="FILE_UPLOAD",
            raw_draft_text=raw_text,
            draft_fields=extracted_fields,
        )
        comp_result = service.compare_draft_bl_service(db, comp_req)
    guardrails = extracted_fields.get("_guardrails", {})
    return {
        "filename": file.filename,
        "raw_text": raw_text,
        "extracted_fields": extracted_fields,
        "extraction_status": guardrails.get("extraction_status", "EXTRACTION_COMPLETE"),
        "missing_critical_fields": guardrails.get("missing_critical_fields", []),
        "safety_warning": guardrails.get("safety_warning"),
        "comparison_result": comp_result,
    }


@router.post("/draft-bl/compare", status_code=status.HTTP_200_OK)
def compare_draft_bl(
    payload: DraftBLComparisonRequest, db: Session = Depends(get_db)
):
    return service.compare_draft_bl_service(db, payload)


@router.post(
    "/draft-bl",
    response_model=DraftBLReviewResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_draft_bl_review(
    payload: DraftBLReviewCreate, db: Session = Depends(get_db)
):
    return service.create_draft_bl_review_service(db, payload)


@router.get("/draft-bl", response_model=List[DraftBLReviewResponse])
def list_draft_bl_reviews(
    include_inactive: bool = False,
    import_file_id: Optional[int] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
):
    return repo.get_draft_bl_reviews(
        db,
        include_inactive=include_inactive,
        import_file_id=import_file_id,
        status=status,
        search=search,
    )


@router.get("/draft-bl/{review_id}", response_model=DraftBLReviewResponse)
def get_draft_bl_review(review_id: int, db: Session = Depends(get_db)):
    item = repo.get_draft_bl_review_by_id(db, review_id, include_inactive=True)
    if not item:
        raise HTTPException(status_code=404, detail="Draft B/L Review not found")
    return item


@router.put("/draft-bl/{review_id}", response_model=DraftBLReviewResponse)
def update_draft_bl_review(
    review_id: int, payload: DraftBLReviewUpdate, db: Session = Depends(get_db)
):
    return service.update_draft_bl_review_service(db, review_id, payload)


@router.put("/draft-bl/{review_id}/checklist", response_model=DraftBLReviewResponse)
def update_draft_bl_checklist(
    review_id: int,
    checklist_items: List[DraftBLChecklistItem],
    reviewer_name: str = "Kamal",
    db: Session = Depends(get_db),
):
    return service.update_draft_bl_checklist_service(
        db, review_id, checklist_items, reviewer_name=reviewer_name
    )


@router.post("/draft-bl/dual-approval", response_model=DraftBLReviewResponse)
def process_draft_bl_dual_approval(
    payload: DualApprovalRequest, db: Session = Depends(get_db)
):
    return service.process_dual_approval_service(db, payload)


@router.post("/draft-bl/new-version", response_model=DraftBLReviewResponse, status_code=status.HTTP_201_CREATED)
def create_new_draft_version(
    payload: NewDraftVersionRequest, db: Session = Depends(get_db)
):
    return service.create_new_draft_version_service(db, payload)


@router.post("/draft-bl/{review_id}/approve", response_model=DraftBLReviewResponse)
def approve_draft_bl(
    review_id: int, approved_by: str = "Kamal", db: Session = Depends(get_db)
):
    return service.approve_draft_bl_service(db, review_id, approved_by=approved_by)


# --- 3. CERTIFICATE OF ORIGIN (COO / EUR.1) ENDPOINTS ---
@router.post("/coo/compare", status_code=status.HTTP_200_OK)
def compare_coo(payload: COOComparisonRequest, db: Session = Depends(get_db)):
    return service.compare_coo_service(db, payload)


@router.post(
    "/coo",
    response_model=CertificateOfOriginReviewResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_coo_review(
    payload: CertificateOfOriginReviewCreate, db: Session = Depends(get_db)
):
    return service.create_coo_review_service(db, payload)


@router.get("/coo", response_model=List[CertificateOfOriginReviewResponse])
def list_coo_reviews(
    include_inactive: bool = False,
    import_file_id: Optional[int] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
):
    return repo.get_coo_reviews(
        db,
        include_inactive=include_inactive,
        import_file_id=import_file_id,
        status=status,
        search=search,
    )


@router.put("/coo/{review_id}", response_model=CertificateOfOriginReviewResponse)
def update_coo_review(
    review_id: int, payload: CertificateOfOriginReviewUpdate, db: Session = Depends(get_db)
):
    return service.update_coo_review_service(db, review_id, payload)


# --- 4. INSPECTION CERTIFICATE ENDPOINTS ---
@router.post("/inspection/compare", status_code=status.HTTP_200_OK)
def compare_inspection(
    payload: InspectionComparisonRequest, db: Session = Depends(get_db)
):
    return service.compare_inspection_cert_service(db, payload)


@router.post(
    "/inspection",
    response_model=InspectionCertificateReviewResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_inspection_review(
    payload: InspectionCertificateReviewCreate, db: Session = Depends(get_db)
):
    return service.create_inspection_review_service(db, payload)


@router.get("/inspection", response_model=List[InspectionCertificateReviewResponse])
def list_inspection_reviews(
    include_inactive: bool = False,
    import_file_id: Optional[int] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
):
    return repo.get_inspection_reviews(
        db,
        include_inactive=include_inactive,
        import_file_id=import_file_id,
        status=status,
        search=search,
    )


@router.put("/inspection/{review_id}", response_model=InspectionCertificateReviewResponse)
def update_inspection_review(
    review_id: int, payload: InspectionCertificateReviewUpdate, db: Session = Depends(get_db)
):
    return service.update_inspection_review_service(db, review_id, payload)


# --- 5. LEGAL DOCUMENTS & ACID EXPIRY COMPLIANCE (+30 DAYS SAFETY MARGIN) ---
@router.get(
    "/legal-compliance/{import_file_id}",
    response_model=LegalDocsExpiryComplianceResponse,
    status_code=status.HTTP_200_OK,
)
def get_legal_compliance(import_file_id: int, db: Session = Depends(get_db)):
    return service.check_acid_and_company_docs_validity_service(db, import_file_id)


# --- 6. COMMERCIAL INVOICE VS. BILL OF LADING CROSS-MATCHING & RECONCILIATION ---
@router.post(
    "/invoice-bl/extract-and-match",
    response_model=InvoiceBLExtractAndMatchResponse,
    status_code=status.HTTP_200_OK,
)
def extract_and_match_invoice_bl(
    payload: InvoiceBLExtractAndMatchRequest, db: Session = Depends(get_db)
):
    """
    Intelligently extracts Commercial Invoice and Draft B/L data,
    executes 10-point cross-comparison matrix, and generates a formal discrepancy/correction report.
    """
    return service.extract_and_match_invoice_bl_service(db, payload)


@router.post(
    "/invoice-bl/extract-files-and-match",
    response_model=InvoiceBLExtractAndMatchResponse,
    status_code=status.HTTP_200_OK,
)
async def extract_invoice_bl_files_and_match(
    invoice_file: Optional[UploadFile] = File(None),
    bl_file: Optional[UploadFile] = File(None),
    import_file_id: Optional[int] = Form(None),
    invoice_text: Optional[str] = Form(None),
    bl_text: Optional[str] = Form(None),
    db: Session = Depends(get_db),
):
    """
    Accepts uploaded Invoice and/or B/L files (PDF, Word, Excel, Text) and executes automated cross-matching.
    """
    inv_raw = invoice_text or ""
    bl_raw = bl_text or ""

    if invoice_file:
        content = await invoice_file.read()
        inv_raw = service.extract_text_from_uploaded_file(invoice_file.filename, content)

    if bl_file:
        content = await bl_file.read()
        bl_raw = service.extract_text_from_uploaded_file(bl_file.filename, content)

    req = InvoiceBLExtractAndMatchRequest(
        import_file_id=import_file_id,
        invoice_raw_text=inv_raw,
        bl_raw_text=bl_raw,
    )
    return service.extract_and_match_invoice_bl_service(db, req)


@router.post(
    "/invoice-bl/certify-and-sync",
    status_code=status.HTTP_200_OK,
)
def certify_and_sync_invoice_bl(
    payload: InvoiceBLSyncRequest, db: Session = Depends(get_db)
):
    """
    Certifies reconciled invoice and B/L parameters and synchronizes them with the Import File and Downstream Records.
    """
    return service.sync_certified_invoice_bl_to_file_service(db, payload)


