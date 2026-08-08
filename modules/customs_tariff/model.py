from datetime import date, datetime, timezone

from sqlalchemy import Boolean, Column, Date, DateTime, Integer, Numeric, String, Text, UniqueConstraint
from sqlalchemy.orm import relationship

from database.database import Base


class CustomsTariff(Base):
    """
    MD-008: Customs Tariff / HS Code Master Table.

    يحتوي على نسب الضرائب والرسوم لكل بند جمركي (HS Code).
    هذا الجدول هو المرجع الأساسي لمحرك الحساب الجمركي المصري.

    قواعد حرجة:
    - لا يجوز Hard-Code أي نسبة ضريبية خارج هذا الجدول.
    - كل HS Code له نسبه الخاصة المستخرجة من هذا السجل.
    - يجب الحفاظ على effective_from / effective_to لدعم Snapshot التاريخي.
    """

    __tablename__ = "customs_tariffs"

    # ==================================================
    # Primary Key & Identification
    # ==================================================
    tariff_id = Column(Integer, primary_key=True, autoincrement=True, index=True)
    hs_code = Column(String(20), nullable=False, unique=True, index=True)
    hs_description = Column(String(500), nullable=False)
    customs_category = Column(String(100), nullable=True)

    # ==================================================
    # Tax & Duty Rates (% values — never hard-coded externally)
    # ==================================================
    customs_duty_rate = Column(Numeric(5, 2), nullable=False, default=0.00)
    """ضريبة الوارد % — محسوبة من القيمة الجمركية (CIF)"""

    vat_rate = Column(Numeric(5, 2), nullable=False, default=0.00)
    """ضريبة القيمة المضافة % — محسوبة من الوعاء الضريبي (CIF + Import Duty + Freight + ...)"""

    schedule_tax_rate = Column(Numeric(5, 2), nullable=False, default=0.00)
    """ضريبة الجدول % — 0 إذا لم تنطبق على هذا البند"""

    development_fee_rate = Column(Numeric(5, 2), nullable=False, default=0.00)
    """رسم التنمية % — 0 إذا لم ينطبق على هذا البند"""

    import_fee_rate = Column(Numeric(5, 2), nullable=False, default=0.00)
    """رسم الوارد % — 0 إذا لم ينطبق"""

    # ==================================================
    # Import Requirements / Regulatory
    # ==================================================
    requires_coo = Column(Boolean, default=False, nullable=False)
    """يتطلب شهادة منشأ (Certificate of Origin)"""

    requires_inspection = Column(Boolean, default=False, nullable=False)
    """يتطلب شهادة فحص (Inspection Certificate)"""

    requires_acid = Column(Boolean, default=True, nullable=False)
    """يتطلب ACID (Advance Cargo Information Declaration)"""

    regulatory_authority = Column(String(500), nullable=True)
    """الجهات الرقابية المسؤولة (NTRA, GOEIC, MOH, etc.)"""

    # ==================================================
    # Validity / Effective Date (Tariff History Support)
    # ==================================================
    effective_from = Column(Date, nullable=False, default=date.today)
    """تاريخ بداية سريان هذه التعريفة"""

    effective_to = Column(Date, nullable=True, default=None)
    """تاريخ انتهاء سريان التعريفة. NULL يعني ساري حتى الآن."""

    # ==================================================
    # Notes & Status
    # ==================================================
    notes = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)

    # ==================================================
    # Audit Timestamps
    # ==================================================
    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    __table_args__ = (
        UniqueConstraint("hs_code", name="uq_customs_tariff_hs_code"),
    )

    def __repr__(self) -> str:
        return f"<CustomsTariff hs_code={self.hs_code} duty={self.customs_duty_rate}% vat={self.vat_rate}%>"
