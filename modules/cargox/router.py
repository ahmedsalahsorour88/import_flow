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
