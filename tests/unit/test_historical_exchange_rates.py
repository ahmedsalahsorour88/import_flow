from datetime import date, timedelta
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.currencies.model import Currency, ExchangeRate
from modules.currencies.schemas import CurrencyCreate, ExchangeRateCreate
from modules.currencies.service import CurrencyService
from modules.customs_tariff.schemas import MultiItemCustomsEstimateRequest, MultiItemCustomsEstimateLine
from modules.customs_tariff.service import estimate_multi_item_customs_duty_service
from modules.financial_approval.service import create_payment_request_service
import modules.financial_approval.repository as fin_repo
from decimal import Decimal

# Import models required for metadata FK resolution
from modules.external_service_providers.model import ExternalServiceProvider
from modules.import_files.model import ImportFile
from modules.purchase_orders.model import PurchaseOrder
from modules.projects.model import Project
from modules.suppliers.model import Supplier
from modules.import_companies.model import ImportCompany
from modules.incoterms.model import Incoterm
from modules.financial_approval.model import PaymentRequestSession, ImportBudgetApproval


@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()


class TestHistoricalExchangeRatesPricing:

    def test_append_only_exchange_rates_history(self, db_session):
        """
        تغيير السعر يُضيف سجلاً جديداً بتاريخ سريان جديد (Append-Only) ولا يُعدّل السجلات السابقة.
        """
        service = CurrencyService(db_session)
        currency = service.create_currency(CurrencyCreate(
            currency_code="USD",
            currency_name="US Dollar",
            currency_symbol="$",
        ))

        # 1. Old rate on 2026-08-01
        rate1 = service.add_exchange_rate(ExchangeRateCreate(
            currency_id=currency.currency_id,
            commercial_rate=48.00,
            customs_rate=47.50,
            effective_date=date(2026, 8, 1),
            created_by="Admin",
        ))

        # 2. New rate on 2026-08-10
        rate2 = service.add_exchange_rate(ExchangeRateCreate(
            currency_id=currency.currency_id,
            commercial_rate=50.00,
            customs_rate=49.50,
            effective_date=date(2026, 8, 10),
            created_by="Admin",
        ))

        # 3. Future rate on 2026-08-20
        rate3 = service.add_exchange_rate(ExchangeRateCreate(
            currency_id=currency.currency_id,
            commercial_rate=52.00,
            customs_rate=51.50,
            effective_date=date(2026, 8, 20),
            created_by="Admin",
        ))

        # Verify history holds all 3 distinct records
        history = service.repo.get_rates_history(currency.currency_id)
        assert len(history) == 3
        # Sorted by effective_date desc
        assert history[0].commercial_rate == Decimal("52.00")
        assert history[1].commercial_rate == Decimal("50.00")
        assert history[2].commercial_rate == Decimal("48.00")

    def test_effective_dated_rate_lookup(self, db_session):
        """
        الاستعلام عن السعر يعيد السعر الساري في التاريخ المطلوب (effective_date <= target_date).
        """
        service = CurrencyService(db_session)
        currency = service.create_currency(CurrencyCreate(
            currency_code="EUR",
            currency_name="Euro",
            currency_symbol="€",
        ))

        service.add_exchange_rate(ExchangeRateCreate(
            currency_id=currency.currency_id,
            commercial_rate=52.00,
            customs_rate=51.00,
            effective_date=date(2026, 8, 1),
        ))
        service.add_exchange_rate(ExchangeRateCreate(
            currency_id=currency.currency_id,
            commercial_rate=55.00,
            customs_rate=54.00,
            effective_date=date(2026, 8, 10),
        ))

        # Query on 2026-08-05 -> should return rate from 2026-08-01 (52.00)
        rate_aug5 = service.repo.get_latest_rate(currency.currency_id, target_date=date(2026, 8, 5))
        assert rate_aug5 is not None
        assert float(rate_aug5.commercial_rate) == 52.00

        # Query on 2026-08-12 -> should return rate from 2026-08-10 (55.00)
        rate_aug12 = service.repo.get_latest_rate(currency.currency_id, target_date=date(2026, 8, 12))
        assert rate_aug12 is not None
        assert float(rate_aug12.commercial_rate) == 55.00

    def test_backdated_transaction_pricing(self, db_session):
        """
        عملية بتاريخ سابق (Backdated) تُحسب بالسعر الساري في تاريخها هي، لا بسعر اليوم.
        """
        service = CurrencyService(db_session)
        currency = service.create_currency(CurrencyCreate(
            currency_code="GBP",
            currency_name="British Pound",
            currency_symbol="£",
        ))

        # Rate on 2026-08-01 was 60.00 EGP
        service.add_exchange_rate(ExchangeRateCreate(
            currency_id=currency.currency_id,
            commercial_rate=60.00,
            customs_rate=59.00,
            effective_date=date(2026, 8, 1),
        ))

        # Today rate (2026-08-13) is 65.00 EGP
        service.add_exchange_rate(ExchangeRateCreate(
            currency_id=currency.currency_id,
            commercial_rate=65.00,
            customs_rate=64.00,
            effective_date=date(2026, 8, 13),
        ))

        # Convert amount for backdated transaction on 2026-08-05
        conversion = service.convert_currency(
            amount=1000.0,
            from_currency_code="GBP",
            to_currency_code="EGP",
            rate_type="commercial",
            as_of_date=date(2026, 8, 5),
        )

        assert conversion.applied_rate == 60.00
        assert conversion.converted_amount == 60000.0
        assert conversion.rate_date == date(2026, 8, 1)

    def test_confirmed_transaction_snapshot_isolation(self, db_session):
        """
        تعديل/تغيير السعر العام لاحقاً لا يؤثر إطلاقاً على العمليات المؤكدة سابقاً.
        """
        service = CurrencyService(db_session)
        currency = service.create_currency(CurrencyCreate(
            currency_code="USD",
            currency_name="US Dollar",
            currency_symbol="$",
        ))

        service.add_exchange_rate(ExchangeRateCreate(
            currency_id=currency.currency_id,
            commercial_rate=48.00,
            customs_rate=47.50,
            effective_date=date(2026, 8, 1),
        ))

        # Create financial payment request session using exchange_rate snapshot = 48.00
        from modules.financial_approval.schemas import PaymentRequestCreate
        req = create_payment_request_service(db_session, PaymentRequestCreate(
            payment_code="PAY-2026-001",
            title="Supplier Advance Payment",
            supplier_name="Global Trade Ltd",
            payment_type="Advance Payment",
            requested_amount=10000.0,
            currency_code="USD",
            exchange_rate=48.00,
            due_date=date(2026, 8, 20),
        ))

        assert req.exchange_rate == 48.00
        assert req.requested_amount_egp == 480000.0

        # Now global rate changes today to 55.00 EGP
        service.add_exchange_rate(ExchangeRateCreate(
            currency_id=currency.currency_id,
            commercial_rate=55.00,
            customs_rate=54.50,
            effective_date=date(2026, 8, 13),
        ))

        # Fetch payment request again -> snapshot value MUST remain 48.00 EGP
        fetched_req = fin_repo.get_payment_request_by_id(db_session, req.payment_id)
        assert fetched_req.exchange_rate == 48.00
        assert fetched_req.requested_amount_egp == 480000.0

    def test_live_currency_converter_historical(self, db_session):
        """
        اختبار محول العملات مع تمرير تاريخ سريان تاريخي as_of_date.
        """
        service = CurrencyService(db_session)
        currency = service.create_currency(CurrencyCreate(
            currency_code="CNY",
            currency_name="Chinese Yuan",
            currency_symbol="¥",
        ))

        service.add_exchange_rate(ExchangeRateCreate(
            currency_id=currency.currency_id,
            commercial_rate=6.50,
            customs_rate=6.40,
            effective_date=date(2026, 7, 1),
        ))
        service.add_exchange_rate(ExchangeRateCreate(
            currency_id=currency.currency_id,
            commercial_rate=7.00,
            customs_rate=6.90,
            effective_date=date(2026, 8, 1),
        ))

        # Historical lookup on 2026-07-15
        res_july = service.convert_currency(
            amount=10000.0,
            from_currency_code="CNY",
            to_currency_code="EGP",
            rate_type="commercial",
            as_of_date=date(2026, 7, 15),
        )
        assert res_july.applied_rate == 6.50
        assert res_july.converted_amount == 65000.0

        # Current lookup on 2026-08-05
        res_aug = service.convert_currency(
            amount=10000.0,
            from_currency_code="CNY",
            to_currency_code="EGP",
            rate_type="commercial",
            as_of_date=date(2026, 8, 5),
        )
        assert res_aug.applied_rate == 7.00
        assert res_aug.converted_amount == 70000.0

    def test_customs_engine_historical_customs_rate(self, db_session):
        """
        محرك الحساب الجمركي يسترجع سعر الصرف الجمركي الرسمي بتاريخ الإقرار.
        """
        service = CurrencyService(db_session)
        currency = service.create_currency(CurrencyCreate(
            currency_code="USD",
            currency_name="US Dollar",
            currency_symbol="$",
        ))

        service.add_exchange_rate(ExchangeRateCreate(
            currency_id=currency.currency_id,
            commercial_rate=50.00,
            customs_rate=49.00,
            effective_date=date(2026, 8, 1),
        ))
        service.add_exchange_rate(ExchangeRateCreate(
            currency_id=currency.currency_id,
            commercial_rate=52.00,
            customs_rate=51.50,
            effective_date=date(2026, 8, 10),
        ))

        # Create active tariff entry for HS Code 8471.30.00
        from modules.customs_tariff.service import create_tariff_service
        from modules.customs_tariff.schemas import CustomsTariffCreate
        create_tariff_service(db_session, CustomsTariffCreate(
            hs_code="8471.30.00",
            hs_description="Laptops and computers",
            customs_duty_rate=5.0,
            vat_rate=14.0,
            effective_from=date(2026, 1, 1),
        ))

        # Calculate customs duty on 2026-08-05 (should pick 49.00 customs rate)
        calc_aug5 = estimate_multi_item_customs_duty_service(
            db=db_session,
            request=MultiItemCustomsEstimateRequest(
                currency="USD",
                exchange_rate=None,  # Auto lookup by effective date
                insurance_egp=Decimal("1000.00"),
                freight_egp=Decimal("5000.00"),
                estimate_date=date(2026, 8, 5),
                lines=[
                    MultiItemCustomsEstimateLine(
                        line_no=1,
                        hs_code="8471.30.00",
                        value_fc=Decimal("10000.00"),
                    )
                ]
            )
        )
        assert calc_aug5.exchange_rate == Decimal("49")

        # Calculate customs duty on 2026-08-12 (should pick 51.50 customs rate)
        calc_aug12 = estimate_multi_item_customs_duty_service(
            db=db_session,
            request=MultiItemCustomsEstimateRequest(
                currency="USD",
                exchange_rate=None,  # Auto lookup by effective date
                insurance_egp=Decimal("1000.00"),
                freight_egp=Decimal("5000.00"),
                estimate_date=date(2026, 8, 12),
                lines=[
                    MultiItemCustomsEstimateLine(
                        line_no=1,
                        hs_code="8471.30.00",
                        value_fc=Decimal("10000.00"),
                    )
                ]
            )
        )
        assert calc_aug12.exchange_rate == Decimal("51.5")
