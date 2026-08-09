from typing import List, Optional
from pydantic import BaseModel, Field


class ACIDLiveRequest(BaseModel):
    importer_id: str = Field(..., description="Importer Tax ID / Code")
    exporter_id: str = Field(..., description="Foreign Exporter Registration Code")
    exporter_country_code: str = Field("CN", min_length=2, max_length=2)
    tariff_hs_codes: List[str] = Field(..., min_items=1)
    invoice_value_usd: float = Field(..., gt=0)
    mode: Optional[str] = Field("MOCK", description="MOCK, STAGING, or PRODUCTION")


class CargoXEnvelopeLiveRequest(BaseModel):
    acid_number: str = Field(..., min_length=5)
    importer_company_code: str
    foreign_exporter_cargox_id: str
    document_types: List[str] = Field(default=["Commercial Invoice", "Bill of Lading", "Certificate of Origin", "Packing List"])
    mode: Optional[str] = Field("MOCK")


class CargoXTransferLiveRequest(BaseModel):
    envelope_id: str
    bl_number: str
    mode: Optional[str] = Field("MOCK")


class PKISignPayloadRequest(BaseModel):
    payload_data: dict
    mode: Optional[str] = Field("MOCK")
