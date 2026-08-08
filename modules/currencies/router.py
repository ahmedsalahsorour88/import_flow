from typing import List, Optional

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from database.database import get_db
from modules.currencies.schemas import (
    CurrencyCreate,
    CurrencyResponse,
    CurrencyUpdate,
    ExchangeRateCreate,
    ExchangeRateResponse,
)
from modules.currencies.service import CurrencyService

router = APIRouter(prefix="/currencies", tags=["Currencies & Exchange Rates (MD-004)"])


@router.get("", response_model=List[CurrencyResponse])
def get_all_currencies(
    include_inactive: bool = Query(False, description="Include inactive currencies"),
    search: Optional[str] = Query(None, description="Search by currency code or name"),
    db: Session = Depends(get_db),
):
    service = CurrencyService(db)
    return service.get_all_currencies(include_inactive=include_inactive, search=search)


@router.get("/{currency_id}", response_model=CurrencyResponse)
def get_currency_by_id(
    currency_id: int,
    db: Session = Depends(get_db),
):
    service = CurrencyService(db)
    return service.get_currency_by_id(currency_id)


@router.post("", response_model=CurrencyResponse, status_code=status.HTTP_201_CREATED)
def create_currency(
    data: CurrencyCreate,
    db: Session = Depends(get_db),
):
    service = CurrencyService(db)
    return service.create_currency(data)


@router.put("/{currency_id}", response_model=CurrencyResponse)
def update_currency(
    currency_id: int,
    data: CurrencyUpdate,
    db: Session = Depends(get_db),
):
    service = CurrencyService(db)
    return service.update_currency(currency_id, data)


@router.delete("/{currency_id}", response_model=CurrencyResponse)
def soft_delete_currency(
    currency_id: int,
    db: Session = Depends(get_db),
):
    service = CurrencyService(db)
    return service.soft_delete_currency(currency_id)


@router.post("/{currency_id}/restore", response_model=CurrencyResponse)
def restore_currency(
    currency_id: int,
    db: Session = Depends(get_db),
):
    service = CurrencyService(db)
    return service.restore_currency(currency_id)


@router.post("/rates", response_model=ExchangeRateResponse, status_code=status.HTTP_201_CREATED)
def add_exchange_rate(
    data: ExchangeRateCreate,
    db: Session = Depends(get_db),
):
    service = CurrencyService(db)
    return service.add_exchange_rate(data)
