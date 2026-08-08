from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field, field_validator, model_validator


# ==================================================
# Customs Tariff Schemas (MD-008)
# ==================================================

class CustomsTariffCreate(BaseModel):
    hs_code: str = Field(..., min_length=4, max_length=20, description="HS Code البند الجمركي")
    hs_description: str = Field(..., min_length=5, max_length=500, description="وصف البند")
    customs_category: Optional[str] = Field(None, max_length=100, description="تصنيف البند")

    # Tax rates — must be >= 0 and <= 100
    customs_duty_rate: Decimal = Field(..., ge=0, le=100, description="نسبة ضريبة الوارد %")
    vat_rate: Decimal = Field(..., ge=0, le=100, description="نسبة ضريبة القيمة المضافة %")
    schedule_tax_rate: Decimal = Field(default=Decimal("0.00"), ge=0, le=100, description="نسبة ضريبة الجدول %")
    development_fee_rate: Decimal = Field(default=Decimal("0.00"), ge=0, le=100, description="نسبة رسم التنمية %")
    import_fee_rate: Decimal = Field(default=Decimal("0.00"), ge=0, le=100, description="نسبة رسم الوارد %")

    # Requirements
    requires_coo: bool = Field(default=False, description="يتطلب شهادة منشأ")
    requires_inspection: bool = Field(default=False, description="يتطلب شهادة فحص")
    requires_acid: bool = Field(default=True, description="يتطلب ACID")
    regulatory_authority: Optional[str] = Field(None, max_length=500, description="الجهات الرقابية")

    # Effective dates
    effective_from: date = Field(default_factory=date.today, description="تاريخ بداية السريان")
    effective_to: Optional[date] = Field(None, description="تاريخ انتهاء السريان (None = ساري حتى الآن)")

    notes: Optional[str] = Field(None, description="ملاحظات")

    @field_validator("hs_code")
    @classmethod
    def normalize_hs_code(cls, v: str) -> str:
        """Normalize HS Code — trim whitespace, keep as-is (dots are valid in HS codes)."""
        return v.strip()

    @model_validator(mode="after")
    def validate_effective_dates(self) -> "CustomsTariffCreate":
        if self.effective_to and self.effective_from:
            if self.effective_to <= self.effective_from:
                raise ValueError("effective_to must be after effective_from")
        return self


class CustomsTariffUpdate(BaseModel):
    hs_description: Optional[str] = Field(None, min_length=5, max_length=500)
    customs_category: Optional[str] = Field(None, max_length=100)

    customs_duty_rate: Optional[Decimal] = Field(None, ge=0, le=100)
    vat_rate: Optional[Decimal] = Field(None, ge=0, le=100)
    schedule_tax_rate: Optional[Decimal] = Field(None, ge=0, le=100)
    development_fee_rate: Optional[Decimal] = Field(None, ge=0, le=100)
    import_fee_rate: Optional[Decimal] = Field(None, ge=0, le=100)

    requires_coo: Optional[bool] = None
    requires_inspection: Optional[bool] = None
    requires_acid: Optional[bool] = None
    regulatory_authority: Optional[str] = Field(None, max_length=500)

    effective_from: Optional[date] = None
    effective_to: Optional[date] = None
    notes: Optional[str] = None

    @model_validator(mode="after")
    def validate_effective_dates(self) -> "CustomsTariffUpdate":
        if self.effective_to and self.effective_from:
            if self.effective_to <= self.effective_from:
                raise ValueError("effective_to must be after effective_from")
        return self


class CustomsTariffResponse(BaseModel):
    tariff_id: int
    hs_code: str
    hs_description: str
    customs_category: Optional[str]

    customs_duty_rate: Decimal
    vat_rate: Decimal
    schedule_tax_rate: Decimal
    development_fee_rate: Decimal
    import_fee_rate: Decimal

    requires_coo: bool
    requires_inspection: bool
    requires_acid: bool
    regulatory_authority: Optional[str]

    effective_from: date
    effective_to: Optional[date]

    notes: Optional[str]
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


# ==================================================
# Customs Duty Estimation Schemas
# ==================================================

class CustomsDutyEstimateRequest(BaseModel):
    """
    طلب حساب تقديري للجمارك.
    يجب تمرير قيمة CIF مباشرة (FOB + Freight + Insurance).
    """
    hs_code: str = Field(..., description="البند الجمركي المراد التقدير له")
    cif_value: Decimal = Field(..., gt=0, description="القيمة الجمركية CIF (بالجنيه المصري أو العملة المختارة)")
    freight: Decimal = Field(default=Decimal("0.00"), ge=0, description="النولون (مضمّن في CIF أو منفصل)")
    estimate_date: Optional[date] = Field(None, description="تاريخ التقدير — None يعني اليوم")


class CustomsDutyBreakdown(BaseModel):
    """
    تفاصيل كل بند من بنود الحساب الجمركي.
    يُحفظ هذا الـ Snapshot داخل ملف الاستيراد لضمان دقة الحساب التاريخي.
    """
    hs_code: str
    hs_description: str
    customs_category: Optional[str]
    estimate_date: date

    # القيم المُدخلة
    cif_value: Decimal
    freight: Decimal

    # نسب الضرائب المُستخرجة من سجل HS Code (لا hard-coding)
    customs_duty_rate: Decimal
    vat_rate: Decimal
    schedule_tax_rate: Decimal
    development_fee_rate: Decimal
    import_fee_rate: Decimal

    # نتائج الحساب
    import_duty_amount: Decimal
    """ضريبة الوارد = CIF × customs_duty_rate%"""

    vat_base: Decimal
    """الوعاء الضريبي = CIF + Import Duty + Freight"""

    vat_amount: Decimal
    """ضريبة القيمة المضافة = VAT Base × vat_rate%"""

    schedule_tax_amount: Decimal
    """ضريبة الجدول = CIF × schedule_tax_rate%"""

    development_fee_amount: Decimal
    """رسم التنمية = CIF × development_fee_rate%"""

    import_fee_amount: Decimal
    """رسم الوارد = CIF × import_fee_rate%"""

    total_taxes_and_fees: Decimal
    """إجمالي الضرائب والرسوم = مجموع جميع البنود"""

    # متطلبات الاستيراد
    requires_coo: bool
    requires_inspection: bool
    requires_acid: bool
    regulatory_authority: Optional[str]

    model_config = {"from_attributes": True}
