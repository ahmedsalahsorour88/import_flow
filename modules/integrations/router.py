from fastapi import APIRouter, Depends, status
from .schemas import ACIDLiveRequest, CargoXEnvelopeLiveRequest, CargoXTransferLiveRequest, PKISignPayloadRequest
from .nafeza_client import NafezaIntegrationClient
from .cargox_client import CargoXIntegrationClient
from .pki_signer import PKISignerService

router = APIRouter(prefix="/api/v1/integrations", tags=["Nafeza & CargoX Integration & PKI E-Signature Engine"])


@router.post("/nafeza/request-acid")
def request_acid_from_nafeza(request: ACIDLiveRequest):
    client = NafezaIntegrationClient(mode=request.mode)
    return client.request_acid_number(
        importer_id=request.importer_id,
        exporter_id=request.exporter_id,
        exporter_country_code=request.exporter_country_code,
        tariff_hs_codes=request.tariff_hs_codes,
        invoice_value_usd=request.invoice_value_usd,
    )


@router.post("/cargox/create-envelope")
def create_cargox_envelope(request: CargoXEnvelopeLiveRequest):
    client = CargoXIntegrationClient(mode=request.mode)
    return client.create_envelope(
        acid_number=request.acid_number,
        importer_company_code=request.importer_company_code,
        foreign_exporter_cargox_id=request.foreign_exporter_cargox_id,
        document_types=request.document_types,
    )


@router.post("/cargox/transfer-envelope")
def transfer_cargox_envelope(request: CargoXTransferLiveRequest):
    client = CargoXIntegrationClient(mode=request.mode)
    return client.transfer_envelope_to_customs(
        envelope_id=request.envelope_id,
        bl_number=request.bl_number,
    )


@router.post("/pki/sign-payload")
def sign_payload_with_pki(request: PKISignPayloadRequest):
    signer = PKISignerService(mode=request.mode)
    return signer.sign_payload(request.payload_data)
