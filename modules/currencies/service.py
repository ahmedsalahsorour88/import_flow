from datetime import date
from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from modules.currencies.model import Currency, ExchangeRate
from modules.currencies.repository import CurrencyRepository
from modules.currencies.schemas import (
    CurrencyCreate,
    CurrencyResponse,
    CurrencyUpdate,
    ExchangeRateCreate,
    ExchangeRateResponse,
)
from modules.currencies.validators import CurrencyValidator


class CurrencyService:

    def __init__(self, db: Session):
        self.db = db
        self.repo = CurrencyRepository(db)
        self.validator = CurrencyValidator(db)

    def get_all_currencies(
        self, include_inactive: bool = False, search: Optional[str] = None
    ) -> List[CurrencyResponse]:
        currencies = self.repo.get_all_currencies(include_inactive=include_inactive, search=search)
        result = []
        for c in currencies:
            latest_rate = self.repo.get_latest_rate(c.currency_id)
            c_resp = CurrencyResponse(
                currency_id=c.currency_id,
                currency_code=c.currency_code,
                currency_name=c.currency_name,
                currency_symbol=c.currency_symbol,
                is_base_currency=c.is_base_currency,
                decimal_places=c.decimal_places,
                is_active=c.is_active,
                created_at=c.created_at,
                updated_at=c.updated_at,
                latest_commercial_rate=float(latest_rate.commercial_rate) if latest_rate else (1.0 if c.is_base_currency else None),
                latest_customs_rate=float(latest_rate.customs_rate) if latest_rate else (1.0 if c.is_base_currency else None),
            )
            result.append(c_resp)
        return result

    def get_currency_by_id(self, currency_id: int) -> CurrencyResponse:
        c = self.validator.validate_currency_exists(currency_id)
        latest_rate = self.repo.get_latest_rate(c.currency_id)
        rates_history = self.repo.get_rates_history(c.currency_id)

        rates_resp = [
            ExchangeRateResponse(
                rate_id=r.rate_id,
                currency_id=r.currency_id,
                commercial_rate=float(r.commercial_rate),
                customs_rate=float(r.customs_rate),
                effective_date=r.effective_date,
                is_active=r.is_active,
                created_at=r.created_at,
            )
            for r in rates_history
        ]

        return CurrencyResponse(
            currency_id=c.currency_id,
            currency_code=c.currency_code,
            currency_name=c.currency_name,
            currency_symbol=c.currency_symbol,
            is_base_currency=c.is_base_currency,
            decimal_places=c.decimal_places,
            is_active=c.is_active,
            created_at=c.created_at,
            updated_at=c.updated_at,
            latest_commercial_rate=float(latest_rate.commercial_rate) if latest_rate else (1.0 if c.is_base_currency else None),
            latest_customs_rate=float(latest_rate.customs_rate) if latest_rate else (1.0 if c.is_base_currency else None),
            exchange_rates=rates_resp,
        )

    def create_currency(self, data: CurrencyCreate) -> Currency:
        self.validator.validate_no_duplicate_code(data.currency_code)
        return self.repo.create_currency(data)

    def update_currency(self, currency_id: int, data: CurrencyUpdate) -> Currency:
        currency = self.validator.validate_currency_exists(currency_id)
        return self.repo.update_currency(currency, data)

    def soft_delete_currency(self, currency_id: int) -> Currency:
        currency = self.validator.validate_currency_exists(currency_id)
        return self.repo.soft_delete_currency(currency)

    def restore_currency(self, currency_id: int) -> Currency:
        currency = self.validator.validate_currency_exists(currency_id)
        return self.repo.restore_currency(currency)

    def add_exchange_rate(self, data: ExchangeRateCreate) -> ExchangeRateResponse:
        self.validator.validate_currency_exists(data.currency_id)
        rate = self.repo.add_exchange_rate(data)
        return ExchangeRateResponse(
            rate_id=rate.rate_id,
            currency_id=rate.currency_id,
            commercial_rate=float(rate.commercial_rate),
            customs_rate=float(rate.customs_rate),
            effective_date=rate.effective_date,
            is_active=rate.is_active,
            created_at=rate.created_at,
        )
