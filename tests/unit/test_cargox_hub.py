"""
Unit Tests for CargoX & ACI Dispatch Hub (CGX-001)
"""

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient
from main import app
from database.database import get_db, SessionLocal
from modules.cargox.model import CargoXEnvelope, CargoXEnvelopeDocument
from modules.cargox.schemas import (
    CargoXEnvelopeCreate,
    CargoXEnvelopeUpdate,
    CargoXDocumentCreate,
    CargoXSealAndTransferRequest,
)
from modules.cargox.service import CargoXService
from modules.cargox.validators import CargoXValidators
from modules.cargox.repository import CargoXRepository


@pytest.fixture
def db():
    db_session = SessionLocal()
    try:
        yield db_session
    finally:
        db_session.close()


@pytest.fixture
def client():
    return TestClient(app)


class TestCargoXHubBackend:

    def test_validate_acid_number(self):
        valid_acid = "7595528271020210010"
        assert CargoXValidators.validate_acid_number(valid_acid) == "7595528271020210010"

        with pytest.raises(HTTPException) as exc_info:
            CargoXValidators.validate_acid_number("12345")
        assert exc_info.value.status_code == 400

    def test_validate_cargox_id(self):
        valid_id = "CX-SUP-98214"
        assert CargoXValidators.validate_cargox_id(valid_id) == "CX-SUP-98214"

        with pytest.raises(HTTPException) as exc_info:
            CargoXValidators.validate_cargox_id("  ")
        assert exc_info.value.status_code == 400

    def test_create_envelope_service(self, db):
        payload = CargoXEnvelopeCreate(
            acid_number="7595528271020210010",
            importer_company_name="Al-Sorour Logistics & Trading Co.",
            importer_tax_number="100-294-812",
            supplier_name="SUZHOU YUHENG TEXTILE CO., LTD",
            supplier_cargox_id="CX-SUZHOU-9901",
            bl_number="MEDUST982145",
            notes="Full CargoX Envelope for Silk Shipment",
            documents=[
                CargoXDocumentCreate(
                    doc_type="Commercial Invoice",
                    doc_number="INV-2026-901",
                    file_name="Commercial_Invoice_Final.pdf",
                    file_size_kb=420.5,
                    is_mandatory=True,
                    verified_against_acid=True,
                ),
                CargoXDocumentCreate(
                    doc_type="Packing List",
                    doc_number="PL-2026-901",
                    file_name="Packing_List_Final.pdf",
                    file_size_kb=310.0,
                    is_mandatory=True,
                    verified_against_acid=True,
                ),
                CargoXDocumentCreate(
                    doc_type="Draft B/L",
                    doc_number="MEDUST982145",
                    file_name="Bill_of_Lading_Draft.pdf",
                    file_size_kb=650.0,
                    is_mandatory=True,
                    verified_against_acid=True,
                ),
            ],
            mode="MOCK",
        )

        envelope = CargoXService.create_envelope(db, payload, created_by="TEST_ADMIN")
        assert envelope.envelope_id is not None
        assert envelope.envelope_code.startswith("CGX-ENV-")
        assert envelope.acid_number == "7595528271020210010"
        assert envelope.supplier_cargox_id == "CX-SUZHOU-9901"
        assert envelope.status == "UPLOADED_BY_SUPPLIER"
        assert envelope.blockchain_tx_hash is not None
        assert len(envelope.documents) == 3

    def test_verify_acid_consistency_service(self, db):
        payload = CargoXEnvelopeCreate(
            acid_number="7595528271020210010",
            importer_company_name="Egyptian Import Enterprise",
            supplier_name="Ningbo Forwarding Corp",
            supplier_cargox_id="CX-NB-5541",
            documents=[
                CargoXDocumentCreate(
                    doc_type="Commercial Invoice",
                    file_name="invoice.pdf",
                    verified_against_acid=True,
                ),
                CargoXDocumentCreate(
                    doc_type="Packing List",
                    file_name="packing.pdf",
                    verified_against_acid=True,
                ),
                CargoXDocumentCreate(
                    doc_type="Draft B/L",
                    file_name="bl.pdf",
                    verified_against_acid=True,
                ),
            ],
        )
        envelope = CargoXService.create_envelope(db, payload)
        report = CargoXService.verify_acid_consistency(db, envelope.envelope_id)

        assert report.all_matched is True
        assert report.verified_count == 3
        assert report.verification_status == "ALL_DOCUMENTS_ACID_VERIFIED"

    def test_seal_and_transfer_to_customs_service(self, db):
        payload = CargoXEnvelopeCreate(
            acid_number="7595528271020210010",
            importer_company_name="Cairo Industrial Trade",
            supplier_name="Shanghai Global Steel",
            supplier_cargox_id="CX-SH-1122",
            bl_number="COSU6391024",
            documents=[
                CargoXDocumentCreate(
                    doc_type="Commercial Invoice",
                    file_name="invoice.pdf",
                    verified_against_acid=True,
                ),
                CargoXDocumentCreate(
                    doc_type="Packing List",
                    file_name="packing.pdf",
                    verified_against_acid=True,
                ),
                CargoXDocumentCreate(
                    doc_type="Draft B/L",
                    file_name="bl.pdf",
                    verified_against_acid=True,
                ),
            ],
        )
        envelope = CargoXService.create_envelope(db, payload)

        transfer_res = CargoXService.seal_and_transfer_to_customs(
            db, envelope.envelope_id, CargoXSealAndTransferRequest(mode="MOCK")
        )

        assert transfer_res.success is True
        assert transfer_res.status == "ACCEPTED_BY_CUSTOMS"
        assert transfer_res.customs_confirmation_receipt is not None
        assert transfer_res.pki_signature is not None

        # Verify Manifest Generation
        manifest_res = CargoXService.generate_digital_manifest(db, envelope.envelope_id)
        assert manifest_res.manifest_json["acid_number"] == "7595528271020210010"
        assert manifest_res.manifest_json["blockchain"]["customs_dispatch_status"] == "ACCEPTED_BY_CUSTOMS"
        assert len(manifest_res.manifest_json["documents"]) == 3

    def test_soft_delete_and_restore(self, db):
        payload = CargoXEnvelopeCreate(
            acid_number="7595528271020210010",
            importer_company_name="Alexandria Fibers",
            supplier_name="Istanbul Yarn Ltd",
            supplier_cargox_id="CX-IST-4412",
        )
        envelope = CargoXService.create_envelope(db, payload)
        env_id = envelope.envelope_id

        # Delete
        CargoXService.soft_delete_envelope(db, env_id)
        assert CargoXRepository.get_by_id(db, env_id, include_inactive=False) is None

        # Restore
        restored = CargoXService.restore_envelope(db, env_id)
        assert restored.is_active is True

    def test_api_endpoints(self, client):
        # 1. Create via API
        post_data = {
            "acid_number": "7595528271020210010",
            "importer_company_name": "API Test Importer",
            "importer_tax_number": "999-888-777",
            "supplier_name": "API Test Supplier",
            "supplier_cargox_id": "CX-API-001",
            "bl_number": "MSCU1234567",
            "documents": [
                {
                    "doc_type": "Commercial Invoice",
                    "file_name": "api_invoice.pdf",
                    "file_size_kb": 120.0,
                    "is_mandatory": True,
                    "verified_against_acid": True,
                },
                {
                    "doc_type": "Packing List",
                    "file_name": "api_packing.pdf",
                    "file_size_kb": 85.0,
                    "is_mandatory": True,
                    "verified_against_acid": True,
                },
                {
                    "doc_type": "Draft B/L",
                    "file_name": "api_bl.pdf",
                    "file_size_kb": 250.0,
                    "is_mandatory": True,
                    "verified_against_acid": True,
                },
            ],
            "mode": "MOCK",
        }
        res = client.post("/api/v1/cargox/envelopes", json=post_data)
        assert res.status_code == 201
        created = res.json()
        env_id = created["envelope_id"]
        assert created["acid_number"] == "7595528271020210010"

        # 2. Get List
        list_res = client.get("/api/v1/cargox/envelopes")
        assert list_res.status_code == 200
        assert len(list_res.json()) >= 1

        # 3. Verify ACID Endpoint
        verify_res = client.post(f"/api/v1/cargox/envelopes/{env_id}/verify-acid")
        assert verify_res.status_code == 200
        assert verify_res.json()["all_matched"] is True

        # 4. Seal & Transfer Endpoint
        seal_res = client.post(
            f"/api/v1/cargox/envelopes/{env_id}/seal-and-transfer",
            json={"mode": "MOCK"},
        )
        assert seal_res.status_code == 200
        assert seal_res.json()["status"] == "ACCEPTED_BY_CUSTOMS"

        # 5. Digital Manifest Endpoint
        man_res = client.get(f"/api/v1/cargox/envelopes/{env_id}/digital-manifest")
        assert man_res.status_code == 200
        assert "manifest_json" in man_res.json()
