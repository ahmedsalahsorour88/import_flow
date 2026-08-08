from datetime import date, datetime
from typing import Optional, List

from pydantic import BaseModel, Field, ConfigDict


# Currency Schemas
class CurrencyBase(BaseModel):
    currency_code: str = Field(..., min_length=3, max_length=3, description="ISO 4217 code e.g. USD, EUR, GBP, EGP, CNY")
    currency_name: str = Field(..., min_length=2, max_length=100)
    currency_symbol: str = Field(..., min_length=1, max_length=10)
    is_base_currency: bool = Field(False)
    decimal_places: int = Field(2, ge=0, le=4)


class CurrencyCreate(CurrencyBase):
    pass


class CurrencyUpdate(BaseModel):
    currency_name: Optional[str] = Field(None, min_length=2, max_length=100)
    currency_symbol: Optional[str] = Field(None, min_length=1, max_length=10)
    is_base_currency: Optional[bool] = None
    decimal_places: Optional[int] = Field(None, ge=0, le=4)
    is_active: Optional[bool] = None


# Exchange Rate Schemas
class ExchangeRateBase(BaseModel):
    currency_id: int
    commercial_rate: float = Field(..., gt=0, description="Commercial Bank Rate to EGP")
    customs_rate: float = Field(..., gt=0, description="Official Egyptian Customs Exchange Rate to EGP")
    effective_date: date


class ExchangeRateCreate(ExchangeRateBase):
    pass


class ExchangeRateResponse(ExchangeRateBase):
    rate_id: int
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CurrencyResponse(CurrencyBase):
    currency_id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime
    latest_commercial_rate: Optional[float] = None
    latest_customs_rate: Optional[float] = None
    exchange_rates: Optional[List[ExchangeRateResponse]] = None

    model_config = ConfigDict(from_attributes=True)
