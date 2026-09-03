from datetime import datetime, date
from typing import List, Optional, Any, Dict
from pydantic import BaseModel, Field, ConfigDict


class TierRateItem(BaseModel):
    from_day: int = Field(..., ge=1, description="بداية شريحة الأيام (1-indexed)")
    to_day: Optional[int] = Field(None, ge=1, description="نهاية شريحة الأيام (None تعني إلى ما لا نهاية)")
    rate_per_day: float = Field(..., ge=0.0, description="قيمة الغرامة اليومية للحاوية")


class DemurragePolicyBase(BaseModel):
    carrier_name: str = Field(..., min_length=2, max_length=100, description="اسم الخط الملاحي")
    container_type: str = Field(..., min_length=2, max_length=50, description="نوع الحاوية")
    demurrage_free_days: int = Field(14, ge=0, description="أيام سماح بقاء الحاوية بالميناء")
    detention_free_days: int = Field(7, ge=0, description="أيام سماح إعادة الحاوية الفارغة")
    port_storage_free_days: int = Field(5, ge=0, description="أيام سماح تخزين ساحات الميناء")
    currency: str = Field("USD", min_length=3, max_length=10, description="عملة الغرامات")
    port_storage_daily_rate_egp: float = Field(250.0, ge=0.0, description="رسم تخزين الميناء اليومي بالجنيه")
    demurrage_tiers: List[TierRateItem] = Field(default_factory=list, description="شرائح غرامة الأرضيات")
    detention_tiers: List[TierRateItem] = Field(default_factory=list, description="شرائح غرامة تأخير الفارغ")
    notes: Optional[str] = None


class DemurragePolicyCreate(DemurragePolicyBase):
    pass


class DemurragePolicyUpdate(BaseModel):
    carrier_name: Optional[str] = None
    container_type: Optional[str] = None
    demurrage_free_days: Optional[int] = None
    detention_free_days: Optional[int] = None
    port_storage_free_days: Optional[int] = None
    currency: Optional[str] = None
    port_storage_daily_rate_egp: Optional[float] = None
    demurrage_tiers: Optional[List[TierRateItem]] = None
    detention_tiers: Optional[List[TierRateItem]] = None
    notes: Optional[str] = None
    is_active: Optional[bool] = None


class DemurragePolicyResponse(DemurragePolicyBase):
    model_config = ConfigDict(from_attributes=True)

    policy_id: int
    is_active: bool
    created_at: Optional[datetime] = None
    created_by: Optional[str] = None
    updated_at: Optional[datetime] = None
    updated_by: Optional[str] = None


class ContainerItemInput(BaseModel):
    container_no: str = Field(..., min_length=4, max_length=50, description="رقم الحاوية (مثال: MSCU1234567)")
    container_type: str = Field("40ft High Cube", min_length=2, max_length=50, description="نوع الحاوية")


class DemurrageTrackingBase(BaseModel):
    import_file_id: Optional[int] = Field(None, description="رقم ملف الاستيراد المرتبط")
    import_file_code: Optional[str] = Field(None, description="كود ملف الاستيراد")
    policy_id: Optional[int] = Field(None, description="رقم سياسة الخط الملاحي المطبقة")
    carrier_name: str = Field(..., min_length=2, max_length=100, description="اسم الخط الملاحي")
    bill_of_lading_no: str = Field(..., min_length=3, max_length=100, description="رقم بوليصة الشحن")
    port_name: str = Field("Alexandria Port", min_length=2, max_length=100, description="ميناء الوصول")
    discharge_date: date = Field(..., description="تاريخ تفريغ الحاويات من السفينة بالميناء")
    gate_out_date: Optional[date] = Field(None, description="تاريخ خروج الحاوية من بوابة الميناء")
    empty_return_date: Optional[date] = Field(None, description="تاريخ إعادة الحاوية الفارغة لساحة الخط")
    containers: List[ContainerItemInput] = Field(default_factory=list, min_length=1, description="قائمة الحاويات")
    currency: str = Field("USD", min_length=3, max_length=10)
    exchange_rate: float = Field(50.0, gt=0.0)
    notes: Optional[str] = None


class DemurrageTrackingCreate(DemurrageTrackingBase):
    pass


class DemurrageTrackingUpdate(BaseModel):
    gate_out_date: Optional[date] = None
    empty_return_date: Optional[date] = None
    exchange_rate: Optional[float] = None
    notes: Optional[str] = None
    status: Optional[str] = None


class DemurrageTrackingResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    tracking_id: int
    tracking_code: str
    import_file_id: Optional[int] = None
    import_file_code: Optional[str] = None
    policy_id: Optional[int] = None
    carrier_name: str
    bill_of_lading_no: str
    port_name: str
    discharge_date: date
    gate_out_date: Optional[date] = None
    empty_return_date: Optional[date] = None
    containers: List[Dict[str, Any]]
    total_demurrage_fx: float
    total_detention_fx: float
    total_storage_egp: float
    currency: str
    exchange_rate: float
    total_cost_egp: float
    status: str
    is_pushed_to_settlement: bool
    settlement_record_id: Optional[int] = None
    notes: Optional[str] = None
    is_active: bool
    created_at: Optional[datetime] = None
    created_by: Optional[str] = None
    updated_at: Optional[datetime] = None
    updated_by: Optional[str] = None


class DemurrageSimulationRequest(BaseModel):
    carrier_name: str = "MSC"
    container_type: str = "40ft High Cube"
    containers_count: int = Field(1, ge=1, le=100)
    demurrage_free_days: int = Field(14, ge=0)
    detention_free_days: int = Field(7, ge=0)
    port_storage_free_days: int = Field(5, ge=0)
    port_storage_daily_rate_egp: float = Field(250.0, ge=0.0)
    demurrage_tiers: Optional[List[TierRateItem]] = None
    detention_tiers: Optional[List[TierRateItem]] = None
    discharge_date: date
    gate_out_date: Optional[date] = None
    empty_return_date: Optional[date] = None
    calculation_date: Optional[date] = None
    currency: str = "USD"
    exchange_rate: float = Field(50.0, gt=0.0)


class DemurrageSimulationResponse(BaseModel):
    demurrage_days_consumed: int
    demurrage_free_days: int
    demurrage_days_overdue: int
    demurrage_fee_fx: float
    demurrage_expiry_date: date
    
    detention_days_consumed: int
    detention_free_days: int
    detention_days_overdue: int
    detention_fee_fx: float
    detention_expiry_date: Optional[date] = None
    
    storage_days_consumed: int
    storage_free_days: int
    storage_days_overdue: int
    storage_fee_egp: float

    total_fee_fx: float
    total_cost_egp: float
    status_badge: str  # "SAFE", "WARNING", "DEMURRAGE_INCURRED", "DETENTION_INCURRED", "OVERDUE"
    countdown_summary_ar: str
    breakdown_details: List[Dict[str, Any]]


class PushToSettlementRequest(BaseModel):
    tracking_id: int
    import_file_id: Optional[int] = None
    accountant_name: Optional[str] = "ImportFlow Accountant"


# =========================================================================
# LOG-DUAL-001: Dual Clock Radar Schemas (Carrier USD vs Port Storage EGP)
# =========================================================================

class CarrierDemurrageClock(BaseModel):
    carrier_name: str
    free_days_allowed: int
    days_consumed: int
    days_remaining: int
    expiry_date: Optional[date] = None
    accrued_demurrage_fx: float
    currency: str = "USD"
    status: str  # "SAFE", "WARNING_LAST_3_DAYS", "OVERDUE_DEMURRAGE"


class PortStorageClock(BaseModel):
    port_name: str
    storage_free_days: int
    days_consumed: int
    days_remaining: int
    hours_until_penalties: int
    daily_rate_egp: float
    accrued_storage_egp: float
    is_critical_72h_warning: bool
    status: str  # "SAFE", "CRITICAL_72H_ALERT", "OVERDUE_STORAGE"


class DualClockResponse(BaseModel):
    tracking_id: int
    tracking_code: str
    bill_of_lading_no: str
    discharge_date: date
    carrier_clock: CarrierDemurrageClock
    port_storage_clock: PortStorageClock
    overall_alert_level: str  # "NORMAL", "URGENT_STORAGE_72H", "ACTION_REQUIRED"
    summary_ar: str


# =========================================================================
# LOG-CONT-002: Container-Level Lifecycle & Partial Gate-Out Schemas
# =========================================================================

class ContainerIndividualUpdate(BaseModel):
    container_no: Optional[str] = None
    seal_no: Optional[str] = None
    gate_out_date: Optional[date] = None
    empty_return_date: Optional[date] = None
    eir_number: Optional[str] = None
    status: Optional[str] = None
    notes: Optional[str] = None

