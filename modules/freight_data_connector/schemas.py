from datetime import datetime, date
from typing import List, Optional, Any
from pydantic import BaseModel, ConfigDict, Field


class RateSlabItem(BaseModel):
    from_day: int = Field(..., ge=1)
    to_day: Optional[int] = None # None means unlimited / and above
    rate_per_day: float = Field(..., ge=0.0)


# --- SFX Freight Index Schemas ---
class FreightIndexSnapshotResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    route_name: str
    origin_region: Optional[str] = None
    destination_region: Optional[str] = None
    fcl_20gp_usd: Optional[float] = None
    fcl_40hq_usd: float
    transit_time_days: Optional[int] = None
    source: str
    snapshot_date: datetime
    created_at: datetime


class FreightIndexSyncResponse(BaseModel):
    success: bool
    source: str
    records_synced: int
    synced_at: datetime
    message: str


# --- Demurrage Rule Schemas ---
class DemurrageRuleBase(BaseModel):
    shipping_line: str
    country_code: str = "EG"
    container_type: str
    default_free_days: int = 14
    rate_slabs: List[dict]


class DemurrageRuleCreate(DemurrageRuleBase):
    source: Optional[str] = "shippingrates.org"


class DemurrageRuleResponse(DemurrageRuleBase):
    model_config = ConfigDict(from_attributes=True)

    rule_id: int
    source: str
    last_synced_at: datetime
    is_active: bool
    created_at: datetime


# --- Port Demurrage Tariff Schemas ---
class PortDemurrageTariffBase(BaseModel):
    port_authority: str
    container_type: str
    free_days: int = 4
    rate_slabs: List[dict]
    tariff_version: str
    effective_from: date
    effective_to: Optional[date] = None
    source_document: Optional[str] = None
    entered_by: Optional[str] = None


class PortDemurrageTariffCreate(PortDemurrageTariffBase):
    pass


class PortDemurrageTariffResponse(PortDemurrageTariffBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_at: datetime


# --- Dual Demurrage Calculation Schemas ---
class DualDemurrageCalculateRequest(BaseModel):
    shipping_line: str
    port_authority: str
    container_type: str # "20GP", "40HC", "40ft", etc.
    discharge_date: date
    clearance_date: Optional[date] = None # defaults to today if omitted
    days_in_port: Optional[int] = None    # if provided directly overrides dates difference
    free_days_override: Optional[int] = None
    exchange_rate_usd_egp: Optional[float] = None # official customs exchange rate for consolidated display


class DetentionBreakdown(BaseModel):
    shipping_line: str
    free_days: int
    days_incurred: int
    chargeable_days: int
    currency: str = "USD"
    total_detention_usd: float
    slab_details: List[dict]


class PortDemurrageBreakdown(BaseModel):
    port_authority: str
    tariff_version_applied: str
    effective_from: date
    free_days: int
    days_incurred: int
    chargeable_days: int
    currency: str = "EGP"
    total_storage_egp: float
    slab_details: List[dict]


class DualDemurrageCalculateResponse(BaseModel):
    days_in_port: int
    discharge_date: date
    calculation_date: date
    detention: DetentionBreakdown
    port_storage: PortDemurrageBreakdown
    consolidated_total_egp: float
    consolidated_total_usd: float
    exchange_rate_applied: float
    exchange_rate_source: str
    advisory_notice_ar: str


# --- Quota & Status Schemas ---
class FreightConnectorStatusResponse(BaseModel):
    shaq_freight_status: str
    last_sfx_sync: Optional[datetime] = None
    total_sfx_routes_tracked: int
    shippingrates_status: str
    monthly_quota_limit: int = 25
    monthly_quota_used: int
    monthly_quota_remaining: int
    active_shipping_lines_tracked: int
    active_port_decrees_count: int
    active_port_authorities: List[str]
