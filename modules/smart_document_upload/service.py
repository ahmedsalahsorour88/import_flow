"""
Smart Document Upload — Service
Orchestrates file parsing + field extraction for all ImportFlow modules.
Routes uploaded file to the correct extractor based on module_name.
"""

from __future__ import annotations

import io
import logging
from typing import Any, Dict, Optional, Tuple

from sqlalchemy.orm import Session

from modules.smart_document_upload.extractors.purchase_order import PurchaseOrderExtractor
from modules.smart_document_upload.extractors.import_file import ImportFileExtractor
from modules.smart_document_upload.extractors.cargo_shipping import CargoShippingExtractor
from modules.smart_document_upload.extractors.customs_clearance import CustomsClearanceExtractor
from modules.smart_document_upload.extractors.freight_quotation import FreightQuotationExtractor
from modules.smart_document_upload.extractors.freight_booking import FreightBookingExtractor
from modules.smart_document_upload.extractors.other_extractors import (
    COOCertificateExtractor,
    InspectionCertificateExtractor,
    FinancialDocumentExtractor,
)
from modules.smart_document_upload.extractors.base_extractor import BaseExtractor
import modules.smart_document_upload.repository as repo

logger = logging.getLogger(__name__)

# ─── Extractor Registry ───────────────────────────────────────────────────────

_EXTRACTOR_MAP: Dict[str, BaseExtractor] = {
    "purchase-order": PurchaseOrderExtractor(),
    "import-file": ImportFileExtractor(),
    "cargo-shipping": CargoShippingExtractor(),
    "customs-clearance": CustomsClearanceExtractor(),
    "freight-quotation": FreightQuotationExtractor(),
    "freight-booking": FreightBookingExtractor(),
    "coo-certificate": COOCertificateExtractor(),
    "inspection-certificate": InspectionCertificateExtractor(),
    "financial-document": FinancialDocumentExtractor(),
    # Aliases
    "customs-consultation": ImportFileExtractor(),   # extracts invoice fields
    "warehouse-receiving": ImportFileExtractor(),    # same as invoice extraction
    "demurrage": FinancialDocumentExtractor(),       # demurrage is a financial doc
}


# ─── Text Extraction ──────────────────────────────────────────────────────────

def extract_raw_text_and_boxes(filename: str, content_bytes: bytes) -> Tuple[str, dict]:
    """
    Reuses the existing extraction engine from import_documentation.
    Supports PDF (spatial), Word, Excel, and text files.
    """
    try:
        from modules.import_documentation.service import (
            extract_text_and_boxes_from_uploaded_file,
        )
        return extract_text_and_boxes_from_uploaded_file(filename, content_bytes)
    except Exception as e:
        logger.warning(f"Primary extractor failed for '{filename}': {e}. Using fallback.")
        return _fallback_text_extraction(filename, content_bytes), {}


def _fallback_text_extraction(filename: str, content_bytes: bytes) -> str:
    """Minimal text extraction fallback."""
    lower = filename.lower()
    try:
        if lower.endswith(".pdf"):
            import pypdf
            reader = pypdf.PdfReader(io.BytesIO(content_bytes))
            return "\n".join(p.extract_text() or "" for p in reader.pages)
        elif lower.endswith((".docx", ".doc")):
            import docx
            doc = docx.Document(io.BytesIO(content_bytes))
            return "\n".join(p.text for p in doc.paragraphs if p.text)
        elif lower.endswith((".xlsx", ".xls")):
            import openpyxl
            wb = openpyxl.load_workbook(io.BytesIO(content_bytes), data_only=True)
            parts = []
            for sheet in wb.sheetnames:
                ws = wb[sheet]
                for row in ws.iter_rows(values_only=True):
                    row_vals = [str(v).strip() for v in row if v is not None and str(v).strip()]
                    if row_vals:
                        parts.append(" | ".join(row_vals))
            return "\n".join(parts)
        else:
            return content_bytes.decode("utf-8", errors="ignore")
    except Exception as e:
        return f"[Extraction error: {e}]"


# ─── Main Service Function ────────────────────────────────────────────────────

def parse_uploaded_document(
    db: Session,
    module_name: str,
    filename: str,
    file_type: str,
    content_bytes: bytes,
    save_session: bool = True,
    created_by: Optional[int] = None,
) -> Dict[str, Any]:
    """
    Main orchestrator:
    1. Extracts raw text from uploaded file (PDF/Excel/Word)
    2. Routes to the appropriate module extractor
    3. Computes confidence score and missing fields
    4. Saves an upload session record
    5. Returns a structured response dict
    """
    file_size = len(content_bytes)

    # Step 1 — Extract raw text
    raw_text, spatial_boxes = extract_raw_text_and_boxes(filename, content_bytes)

    # Step 2 — Route to extractor
    extractor = _EXTRACTOR_MAP.get(module_name)
    if extractor is None:
        logger.warning(f"No extractor for module '{module_name}'. Using ImportFileExtractor as default.")
        extractor = ImportFileExtractor()

    # Step 3 — Extract fields
    try:
        extracted_fields = extractor.extract(raw_text, spatial_boxes)
    except Exception as e:
        logger.error(f"Extractor error for '{module_name}': {e}")
        extracted_fields = {}

    # Step 4 — Compute quality metrics
    confidence = extractor.compute_confidence(extracted_fields)
    missing = extractor.missing_required(extracted_fields)

    if confidence >= 0.8:
        status = "SUCCESS"
    elif confidence >= 0.4:
        status = "PARTIAL"
    else:
        status = "FAILED"

    notes = (
        f"Extracted {len([v for v in extracted_fields.values() if v is not None])} fields. "
        f"Confidence: {confidence:.0%}. "
        + (f"Missing: {', '.join(missing)}." if missing else "All required fields found.")
    )

    # Step 5 — Save session
    session_id = None
    session_ref = None
    if save_session:
        try:
            session = repo.create_upload_session(
                db=db,
                module_name=module_name,
                filename=filename,
                file_type=file_type,
                file_size_bytes=file_size,
                extraction_status=status,
                confidence_score=confidence,
                extracted_fields=extracted_fields,
                missing_fields=missing,
                extraction_notes=notes,
                created_by=created_by,
            )
            session_id = session.id
            session_ref = session.session_ref
        except Exception as e:
            logger.warning(f"Could not save upload session: {e}")

    return {
        "session_id": session_id,
        "session_ref": session_ref,
        "module_name": module_name,
        "filename": filename,
        "file_type": file_type,
        "file_size_bytes": file_size,
        "extraction_status": status,
        "confidence_score": confidence,
        "extracted_fields": extracted_fields,
        "missing_fields": missing,
        "extraction_notes": notes,
        "raw_text_preview": raw_text[:500] if raw_text else None,
    }
