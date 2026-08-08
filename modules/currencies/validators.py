from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from modules.currencies.repository import CurrencyRepository


class CurrencyValidator:

    def __init__(self, db: Session):
        self.repo = CurrencyRepository(db)

    def validate_no_duplicate_code(self, currency_code: str, exclude_id: int = None):
        existing = self.repo.get_currency_by_code(currency_code)
        if existing and (exclude_id is None or existing.currency_id != exclude_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Currency with ISO code '{currency_code.upper()}' already exists.",
            )

    def validate_currency_exists(self, currency_id: int):
        currency = self.repo.get_currency_by_id(currency_id)
        if not currency:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Currency with ID {currency_id} not found.",
            )
        return currency
