import pytest
from modules.integrations.pki_signer import PKISignerService
from modules.integrations.nafeza_client import NafezaIntegrationClient
from modules.integrations.cargox_client import CargoXIntegrationClient


class TestIntegrationsAndPKIModule:
    def test_pki_signer_service(self):
        signer = PKISignerService(mode="MOCK")
        payload = {"acid_number": "2026-TEST-9988", "value_usd": 15000.0}
        sig = signer.sign_payload(payload)

        assert sig["algorithm"] == "SHA256withRSA"
        assert "signature_b64" in sig
        assert sig["pki_mode"] == "MOCK"
        assert signer.verify_signature(payload, sig["signature_b64"]) is True

    def test_nafeza_client_acid_request(self):
        client = NafezaIntegrationClient(mode="MOCK")
        res = client.request_acid_number(
            importer_id="IMP-100200",
            exporter_id="EXP-CN-8899",
            exporter_country_code="CN",
            tariff_hs_codes=["8471.30.00"],
            invoice_value_usd=25000.0,
        )

        assert res["status"] == "APPROVED"
        assert res["acid_number"] is not None
        assert "pki_signature" in res

    def test_cargox_client_envelope(self):
        client = CargoXIntegrationClient(mode="MOCK")
        env = client.create_envelope(
            acid_number="2026-TEST-9988",
            importer_company_code="IMP-100200",
            foreign_exporter_cargox_id="CGX-EXP-5544",
            document_types=["Commercial Invoice", "Bill of Lading"],
        )

        assert env["status"] == "ENVELOPE_CREATED"
        assert env["envelope_id"].startswith("CGX-ENV-")
        assert "blockchain_tx_hash" in env

        transfer = client.transfer_envelope_to_customs(
            envelope_id=env["envelope_id"],
            bl_number="BL-MAEU-998877",
        )
        assert transfer["status"] == "TRANSFERRED_TO_EGYPTIAN_CUSTOMS"
