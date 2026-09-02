"""
FastAPI Router for CargoX & ACI Dispatch Hub (CGX-001)
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from database.database import get_db

from .schemas import (
    CargoXEnvelopeCreate,
    CargoXEnvelopeUpdate,
    CargoXEnvelopeResponse,
    CargoXSealAndTransferRequest,
    CargoXSealAndTransferResponse,
    CargoXAcidVerificationReport,
    DigitalManifestResponse,
)
from .service import CargoXService

router = APIRouter(prefix="/api/v1/cargox", tags=["CargoX & ACI Dispatch Hub"])


@router.get("/envelopes", response_model=List[CargoXEnvelopeResponse])
def get_cargox_envelopes(
    search: Optional[str] = Query(None, description="Search query by code, ACID, supplier, or B/L"),
    status: Optional[str] = Query(None, description="Status filter"),
    import_file_id: Optional[int] = Query(None, description="Filter by Import File ID"),
    supplier_id: Optional[int] = Query(None, description="Filter by Supplier ID"),
    include_inactive: bool = Query(False, description="Include soft-deleted records"),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """
    List all CargoX envelopes with advanced search and status filtering.
    """
    return CargoXService.get_envelopes(
        db=db,
        search=search,
        status=status,
        import_file_id=import_file_id,
        supplier_id=supplier_id,
        include_inactive=include_inactive,
        limit=limit,
        offset=offset,
    )


@router.get("/envelopes/{envelope_id}", response_model=CargoXEnvelopeResponse)
def get_cargox_envelope_by_id(
    envelope_id: int,
    db: Session = Depends(get_db),
):
    """
    Get detailed CargoX envelope by ID with all attached document items.
    """
    return CargoXService.get_envelope_by_id(db, envelope_id)


@router.post("/envelopes", response_model=CargoXEnvelopeResponse, status_code=status.HTTP_201_CREATED)
def create_cargox_envelope(
    payload: CargoXEnvelopeCreate,
    db: Session = Depends(get_db),
):
    """
    Create a new CargoX Blockchain Envelope with PKI Signature & initial attestation.
    """
    return CargoXService.create_envelope(db, payload, created_by="ADMIN")


@router.put("/envelopes/{envelope_id}", response_model=CargoXEnvelopeResponse)
def update_cargox_envelope(
    envelope_id: int,
    payload: CargoXEnvelopeUpdate,
    db: Session = Depends(get_db),
):
    """
    Update CargoX envelope details.
    """
    return CargoXService.update_envelope(db, envelope_id, payload, updated_by="ADMIN")


@router.post("/envelopes/{envelope_id}/seal-and-transfer", response_model=CargoXSealAndTransferResponse)
def seal_and_transfer_to_customs(
    envelope_id: int,
    request: CargoXSealAndTransferRequest,
    db: Session = Depends(get_db),
):
    """
    Seal CargoX envelope, verify mandatory documents, sign with PKI, and transfer to Egyptian Customs (Nafeza).
    """
    return CargoXService.seal_and_transfer_to_customs(db, envelope_id, request, updated_by="ADMIN")


@router.post("/envelopes/{envelope_id}/verify-acid", response_model=CargoXAcidVerificationReport)
def verify_envelope_acid_consistency(
    envelope_id: int,
    db: Session = Depends(get_db),
):
    """
    Perform 100% automated ACID consistency verification across all envelope documents.
    """
    return CargoXService.verify_acid_consistency(db, envelope_id)


@router.get("/envelopes/{envelope_id}/digital-manifest", response_model=DigitalManifestResponse)
def generate_digital_manifest(
    envelope_id: int,
    db: Session = Depends(get_db),
):
    """
    Generate and export official ACI Digital Manifest JSON & structured payload.
    """
    return CargoXService.generate_digital_manifest(db, envelope_id)


@router.delete("/envelopes/{envelope_id}", response_model=CargoXEnvelopeResponse)
def soft_delete_cargox_envelope(
    envelope_id: int,
    db: Session = Depends(get_db),
):
    """
    Soft delete a CargoX envelope.
    """
    return CargoXService.soft_delete_envelope(db, envelope_id, deleted_by="ADMIN")


@router.post("/envelopes/{envelope_id}/restore", response_model=CargoXEnvelopeResponse)
def restore_cargox_envelope(
    envelope_id: int,
    db: Session = Depends(get_db),
):
    """
    Restore a soft-deleted CargoX envelope.
    """
    return CargoXService.restore_envelope(db, envelope_id, restored_by="ADMIN")


# ============================================================================
# STANDARD EXCEL COMMERCIAL INVOICE ENDPOINTS (BP-025 / CGX-002)
# ============================================================================

from fastapi import UploadFile, File, Response
from .schemas import (
    StandardInvoicePayload,
    StandardInvoiceComparisonResponse,
    StandardInvoiceSessionCreate,
    StandardInvoiceSessionResponse,
    StandardInvoiceStatusUpdateRequest,
)
from .service import CargoXStandardInvoiceService


@router.get("/standard-invoice/generate/{import_file_id}")
def generate_standard_invoice_excel(
    import_file_id: int,
    db: Session = Depends(get_db),
):
    """
    Generate and download the official Standard Commercial Invoice (.xlsx)
    with all 36+ Named Ranges and structured InvoiceItems Table.
    """
    excel_bytes = CargoXStandardInvoiceService.generate_excel_template(db, import_file_id)
    return Response(
        content=excel_bytes,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={
            "Content-Disposition": f"attachment; filename=Commercial_Invoice_IMP_{import_file_id}.xlsx"
        },
    )


@router.post("/standard-invoice/parse", response_model=StandardInvoicePayload)
async def parse_supplier_invoice_excel(
    file: UploadFile = File(...),
):
    """
    Upload and parse supplier's completed Excel Commercial Invoice template
    using openpyxl Defined Names and the InvoiceItems table.
    """
    file_bytes = await file.read()
    return CargoXStandardInvoiceService.parse_excel_file(file_bytes)


@router.post("/standard-invoice/compare/{import_file_id}", response_model=StandardInvoiceComparisonResponse)
def compare_standard_invoice(
    import_file_id: int,
    supplier_data: StandardInvoicePayload,
    db: Session = Depends(get_db),
):
    """
    Run the side-by-side comparison engine between System Baseline Snapshot vs Supplier Uploaded Excel.
    """
    return CargoXStandardInvoiceService.compare_invoices(db, import_file_id, supplier_data)


@router.post("/standard-invoice/session", response_model=StandardInvoiceSessionResponse)
def save_or_upsert_standard_invoice_session(
    payload: StandardInvoiceSessionCreate,
    db: Session = Depends(get_db),
):
    """
    Create or update (Upsert) a Standard Commercial Invoice Review Session.
    Enforces mandatory override justification if approved with discrepancies.
    """
    return CargoXStandardInvoiceService.save_or_upsert_session(db, payload, created_by="ADMIN")


@router.get("/standard-invoice/session/by-file/{import_file_id}", response_model=Optional[StandardInvoiceSessionResponse])
def get_standard_invoice_session_by_file(
    import_file_id: int,
    db: Session = Depends(get_db),
):
    """
    Retrieve the active Standard Commercial Invoice Review Session for an import file.
    """
    return CargoXStandardInvoiceService.get_session_by_file(db, import_file_id)


@router.get("/standard-invoice/sessions", response_model=List[StandardInvoiceSessionResponse])
def list_standard_invoice_sessions(
    search: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    import_file_id: Optional[int] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """
    List all Standard Commercial Invoice Review Sessions with search and status filtering.
    """
    return CargoXStandardInvoiceService.list_sessions(
        db, search=search, status=status, import_file_id=import_file_id, limit=limit, offset=offset
    )


@router.put("/standard-invoice/session/{session_id}/status", response_model=StandardInvoiceSessionResponse)
def update_standard_invoice_session_status(
    session_id: int,
    payload: StandardInvoiceStatusUpdateRequest,
    db: Session = Depends(get_db),
):
    """
    Update session status (Approve, Reject, Under Review) with mandatory justification validation.
    """
    return CargoXStandardInvoiceService.update_session_status(db, session_id, payload, updated_by="ADMIN")


# ============================================================================
# CGX-003: Multi-Path Extraction Engine Endpoints
# ============================================================================

import io
import zipfile
from .schemas import ExtractionRequest, ExtractionResponse, CustomsInvoiceTrackCreate, CustomsInvoiceTrackResponse
from .service import CargoXExtractionEngine
from .excel_invoice_service import generate_standard_invoice_excel_bytes


@router.post("/standard-invoice/extract/{import_file_id}", response_model=ExtractionResponse)
def extract_invoice_multi_mode(
    import_file_id: int,
    request: ExtractionRequest,
    db: Session = Depends(get_db),
):
    """
    CGX-003: محرك الاستخراج متعدد المسارات.

    يدعم 4 modes للاستخراج:
    - all_consolidated: ملف واحد — بنود مجمعة بـ HS Code (weighted average price)
    - all_detailed: ملف واحد — بنود مفصلة
    - per_invoice_consolidated: ملف منفصل لكل فاتورة — مجمع
    - per_invoice_detailed: ملف منفصل لكل فاتورة — مفصل
    """
    return CargoXExtractionEngine.extract(db, import_file_id, request)


@router.post("/standard-invoice/generate-zip/{import_file_id}")
def generate_invoice_zip(
    import_file_id: int,
    request: ExtractionRequest,
    db: Session = Depends(get_db),
):
    """
    CGX-003: تحميل ملفات Excel كـ ZIP.
    - لو mode = all_* → ZIP يحتوي على ملف Excel واحد
    - لو mode = per_invoice_* → ZIP يحتوي على ملف لكل فاتورة
    """
    extraction = CargoXExtractionEngine.extract(db, import_file_id, request)

    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
        for result in extraction.results:
            excel_bytes = generate_standard_invoice_excel_bytes(result.payload)
            safe_inv = (result.invoice_number or f"Invoice_{result.payload.invoice_number or import_file_id}").replace("/", "-").replace("\\", "-")
            filename = f"Commercial_Invoice_{safe_inv}.xlsx"
            zf.writestr(filename, excel_bytes)

    zip_buffer.seek(0)
    return Response(
        content=zip_buffer.read(),
        media_type="application/zip",
        headers={
            "Content-Disposition": f"attachment; filename=CargoX_Invoices_IMP{import_file_id}_{request.mode}.zip"
        },
    )


@router.post("/customs-track/create", response_model=CustomsInvoiceTrackResponse)
def create_customs_invoice_track(
    payload: CustomsInvoiceTrackCreate,
    db: Session = Depends(get_db),
):
    """
    CGX-003: إنشاء وحفظ نسخة جمركية (Customs Invoice Track) مستقلة.
    يتم تطبيق weighted average price لكل HS Code وحفظ الـ snapshot في DB.
    """
    return CargoXExtractionEngine.create_customs_track(db, payload, created_by="ADMIN")


@router.get("/customs-track/by-file/{import_file_id}", response_model=List[CustomsInvoiceTrackResponse])
def list_customs_tracks_by_file(
    import_file_id: int,
    db: Session = Depends(get_db),
):
    """
    CGX-003: قايمة كافة النسخ الجمركية المحفوظة لملف استيراد معين.
    """
    from .model import CargoXCustomsInvoiceTrack
    tracks = (
        db.query(CargoXCustomsInvoiceTrack)
        .filter(
            CargoXCustomsInvoiceTrack.import_file_id == import_file_id,
            CargoXCustomsInvoiceTrack.is_active.is_(True),
        )
        .order_by(CargoXCustomsInvoiceTrack.track_id.desc())
        .all()
    )
    return tracks
