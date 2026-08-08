from datetime import date
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.currencies.model import Currency, ExchangeRate
from modules.currencies.schemas import CurrencyCreate, CurrencyUpdate, ExchangeRateCreate
from modules.currencies.service import CurrencyService
from fastapi import HTTPException


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


class TestCurrenciesBackend:

    def test_create_currency_and_rate(self, db_session):
        service = CurrencyService(db_session)
        currency = service.create_currency(CurrencyCreate(
            currency_code="usd",
            currency_name="US Dollar",
            currency_symbol="$",
            is_base_currency=False,
            decimal_places=2,
        ))

        assert currency.currency_id is not None
        assert currency.currency_code == "USD"  # Uppercased

        # Add exchange rate
        rate_resp = service.add_exchange_rate(ExchangeRateCreate(
            currency_id=currency.currency_id,
            commercial_rate=50.25,
            customs_rate=50.10,
            effective_date=date(2026, 8, 8),
        ))

        assert rate_resp.commercial_rate == 50.25
        assert rate_resp.customs_rate == 50.10

        # Retrieve currency with latest rate
        fetched = service.get_currency_by_id(currency.currency_id)
        assert fetched.latest_commercial_rate == 50.25
        assert fetched.latest_customs_rate == 50.10

    def test_duplicate_currency_code_raises_400(self, db_session):
        service = CurrencyService(db_session)
        service.create_currency(CurrencyCreate(currency_code="EUR", currency_name="Euro", currency_symbol="€"))

        with pytest.raises(HTTPException) as exc_info:
            service.create_currency(CurrencyCreate(currency_code="eur", currency_name="Euro Second", currency_symbol="€"))

        assert exc_info.value.status_code == 400
        assert "already exists" in exc_info.value.detail

    def test_soft_delete_and_restore_currency(self, db_session):
        service = CurrencyService(db_session)
        c = service.create_currency(CurrencyCreate(currency_code="GBP", currency_name="British Pound", currency_symbol="£"))

        service.soft_delete_currency(c.currency_id)
        active_list = service.get_all_currencies(include_inactive=False)
        assert len(active_list) == 0

        restored = service.restore_currency(c.currency_id)
        assert restored.is_active is True
        active_list = service.get_all_currencies(include_inactive=False)
        assert len(active_list) == 1
