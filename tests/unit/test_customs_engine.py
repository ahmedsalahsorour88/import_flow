from decimal import Decimal
import pytest
from database.database import SessionLocal
from modules.customs_tariff.model import CustomsTariff
from modules.customs_tariff.schemas import (
    MultiItemCustomsEstimateLine,
    MultiItemCustomsEstimateRequest,
)
from modules.customs_tariff.service import (
    estimate_customs_duty_service,
    estimate_multi_item_customs_duty_service,
)


@pytest.fixture
def db_session():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


def test_nafeza_official_worked_example_multi_item_engine(db_session):
    """
    اختبار محرك الحساب الجمركي المصري المتعدد الأصناف بنفس أرقام البيان الجمركي الفعلي المرفق من منصة نافذة:
    - رقم البيان: 2026-612-1-94731
    - قيمة الفاتورة: 11,736.4 USD
    - سعر الصرف: 50.7917
    - التأمين: 14,902.793 EGP
    - النولون: 11,922.234 EGP
    - رسوم إضافية أساسية: 1,329.50 EGP
    - السطور 3 بنود:
      Line 1: 8536410000 | 607.6 USD | 10% duty | 10% sched tax | 0 inspection
      Line 2: 8537109000 | 4371.2 USD | 10% duty | 10% sched tax | 8514.81 inspection
      Line 3: 8537109000 | 6757.6 USD | 10% duty | 10% sched tax | 69772.09 inspection
    """
    request = MultiItemCustomsEstimateRequest(
        currency="USD",
        exchange_rate=Decimal("50.7917"),
        insurance_egp=Decimal("14902.793"),
        freight_egp=Decimal("11922.234"),
        additional_fees_egp=Decimal("1329.50"),
        cif_declared_total_egp=Decimal("623000.00"),
        vat_rate_override=Decimal("14.00"),
        lines=[
            MultiItemCustomsEstimateLine(
                line_no=1,
                hs_code="8536410000",
                value_fc=Decimal("607.6"),
                weight_kg=Decimal("4.68"),
                qty=Decimal("10"),
                inspection_fee_egp=Decimal("0.00"),
            ),
            MultiItemCustomsEstimateLine(
                line_no=2,
                hs_code="8537109000",
                value_fc=Decimal("4371.2"),
                weight_kg=Decimal("5.00"),
                qty=Decimal("5"),
                inspection_fee_egp=Decimal("8514.81"),
            ),
            MultiItemCustomsEstimateLine(
                line_no=3,
                hs_code="8537109000",
                value_fc=Decimal("6757.6"),
                weight_kg=Decimal("5.00"),
                qty=Decimal("10"),
                inspection_fee_egp=Decimal("69772.09"),
            ),
        ],
    )

    result = estimate_multi_item_customs_duty_service(db_session, request)

    # Assert Header Totals match Nafeza Statement exactly
    assert result.invoice_total_value_fc == Decimal("11736.4")
    assert len(result.lines) == 3

    # Assert Line 1 Totals
    line1 = result.lines[0]
    assert line1.duty_egp == Decimal("3225.31")
    assert line1.schedule_tax_egp == Decimal("322.53")
    assert line1.vat_egp == Decimal("4966.97")

    # Assert Line 2 Totals
    line2 = result.lines[1]
    assert line2.duty_egp == Decimal("23203.52")
    assert line2.schedule_tax_egp == Decimal("2320.35")
    assert line2.vat_egp == Decimal("35733.42")
    assert line2.inspection_fee_egp == Decimal("8514.81")

    # Assert Line 3 Totals
    line3 = result.lines[2]
    assert line3.duty_egp == Decimal("35871.18")
    assert line3.schedule_tax_egp == Decimal("3587.12")
    assert line3.vat_egp == Decimal("55241.61")
    assert line3.inspection_fee_egp == Decimal("69772.09")

    # Assert Global Aggregations
    assert result.total_duty_egp == Decimal("62300.01")
    assert result.total_schedule_tax_egp == Decimal("6230.00")
    assert result.total_vat_egp == Decimal("95942.00")
    assert result.total_inspection_fees_egp == Decimal("78286.90")
    assert result.items_taxes_total_egp == Decimal("164472.01")
    assert result.grand_total_payable_egp == Decimal("165801.51")


def test_value_based_apportionment_rule(db_session):
    """
    اختبار قاعدة التوزيع على أساس القيمة (Value-based Apportionment)
    """
    request = MultiItemCustomsEstimateRequest(
        currency="USD",
        exchange_rate=Decimal("50.00"),
        insurance_egp=Decimal("1000.00"),
        freight_egp=Decimal("1000.00"),
        additional_fees_egp=Decimal("0.00"),
        lines=[
            MultiItemCustomsEstimateLine(
                line_no=1,
                hs_code="1001.99.00",
                value_fc=Decimal("2000.00"),
            ),
            MultiItemCustomsEstimateLine(
                line_no=2,
                hs_code="1001.99.00",
                value_fc=Decimal("8000.00"),
            ),
        ],
    )

    result = estimate_multi_item_customs_duty_service(db_session, request)

    # Total insurance + freight = 2000 EGP
    # Line 1 (20% share) gets 400 EGP
    # Line 2 (80% share) gets 1600 EGP
    assert result.lines[0].allocated_insurance_freight_egp == Decimal("400.00")
    assert result.lines[1].allocated_insurance_freight_egp == Decimal("1600.00")


def test_deemed_insurance_and_freight_fallback(db_session):
    """
    اختبار التأمين والنولون الحكمي (Statutory/Deemed Insurance & Freight)
    عند غياب وثائق التأمين أو الشحن (2.5% تأمين حكمي و 2.0% نولون حكمي).
    """
    request = MultiItemCustomsEstimateRequest(
        currency="USD",
        exchange_rate=Decimal("50.00"),
        insurance_egp=Decimal("0.00"),
        freight_egp=Decimal("0.00"),
        has_insurance_document=False,  # No document -> Deemed 2.5%
        has_freight_document=False,    # No document -> Deemed 2.0%
        lines=[
            MultiItemCustomsEstimateLine(
                line_no=1,
                hs_code="8536410000",
                value_fc=Decimal("10000.00"),
            ),
        ],
    )

    result = estimate_multi_item_customs_duty_service(db_session, request)

    # FOB = 10,000 USD * 50.00 EGP = 500,000 EGP
    # Deemed Insurance = 500,000 * 2.5% = 12,500 EGP
    # Deemed Freight   = 500,000 * 2.0% = 10,000 EGP
    assert result.fob_value_egp == Decimal("500000.00")
    assert result.insurance_egp == Decimal("12500.00")
    assert result.freight_egp == Decimal("10000.00")
    assert result.insurance_source == "deemed"
    assert result.freight_source == "deemed"
    assert result.lines[0].cif_value_egp == Decimal("522500.00")  # 500k + 12.5k + 10k


def test_full_customs_exemption_duty_only(db_session):
    """
    اختبار الإعفاء الجمركي الكامل لضريبة الوارد (INV-LAW-EXEMPT-01 - قانون الاستثمار)
    الجمرك = صفر، ولكن ضريبة القيمة المضافة تُحسب على كامل الوعاء.
    """
    request = MultiItemCustomsEstimateRequest(
        currency="USD",
        exchange_rate=Decimal("50.00"),
        insurance_egp=Decimal("0.00"),
        freight_egp=Decimal("0.00"),
        has_insurance_document=False,  # Deemed costs 4.5% -> CIF 104,500 EGP
        has_freight_document=False,
        lines=[
            MultiItemCustomsEstimateLine(
                line_no=1,
                hs_code="8536410000",
                value_fc=Decimal("2000.00"),
                exemption_code="INV-LAW-EXEMPT-01",  # Exempt Duty Only
            ),
        ],
    )

    result = estimate_multi_item_customs_duty_service(db_session, request)

    line = result.lines[0]
    # FOB = 100,000 EGP. Deemed Insurance + Freight = 4,500 EGP -> CIF = 104,500 EGP
    assert line.cif_value_egp == Decimal("104500.00")
    assert line.duty_taxable_base_egp == Decimal("0.00")  # Base reduced to 0 by exemption
    assert line.duty_egp == Decimal("0.00")              # Duty = 0 EGP
    assert line.vat_base_egp == Decimal("104500.00")     # VAT Base = CIF (104.5k) + Duty (0)
    assert line.vat_egp == Decimal("14630.00")          # VAT 14% = 14,630 EGP
    assert line.exemption_code_applied == "INV-LAW-EXEMPT-01"


def test_partial_percentage_exemption(db_session):
    """
    اختبار الإعفاء الجمركي الجزئي بنسبة 50% (PARTIAL-50-EXEMPT)
    """
    request = MultiItemCustomsEstimateRequest(
        currency="USD",
        exchange_rate=Decimal("50.00"),
        insurance_egp=Decimal("0.00"),
        freight_egp=Decimal("0.00"),
        has_insurance_document=False,  # Deemed costs 4.5% -> CIF 104,500 EGP
        has_freight_document=False,
        lines=[
            MultiItemCustomsEstimateLine(
                line_no=1,
                hs_code="8536410000",  # Standard Tariff 10%
                value_fc=Decimal("2000.00"),
                exemption_code="PARTIAL-50-EXEMPT",
            ),
        ],
    )

    result = estimate_multi_item_customs_duty_service(db_session, request)

    line = result.lines[0]
    # CIF = 104,500 EGP
    # Taxable Base = 104,500 * (1 - 0.50) = 52,250 EGP
    # Duty 10% on 52,250 = 5,225 EGP
    assert line.cif_value_egp == Decimal("104500.00")
    assert line.duty_taxable_base_egp == Decimal("52250.00")
    assert line.duty_egp == Decimal("5225.00")


def test_trade_agreement_preferential_tariff(db_session):
    """
    اختبار تطبيق التخفيض الجمركي لاتفاقية الشراكة المصرية التركية (TR Origin -> 0% Duty)
    """
    request = MultiItemCustomsEstimateRequest(
        currency="USD",
        exchange_rate=Decimal("50.00"),
        insurance_egp=Decimal("0.00"),
        freight_egp=Decimal("0.00"),
        lines=[
            MultiItemCustomsEstimateLine(
                line_no=1,
                hs_code="8536410000",
                value_fc=Decimal("2000.00"),
                origin_country="TR",  # Turkey Partnership Agreement
            ),
        ],
    )

    result = estimate_multi_item_customs_duty_service(db_session, request)

    line = result.lines[0]
    assert line.customs_duty_rate == Decimal("0.00")
    assert line.duty_egp == Decimal("0.00")
    assert line.preferential_agreement_applied == "اتفاقية الشراكة المصرية التركية"

