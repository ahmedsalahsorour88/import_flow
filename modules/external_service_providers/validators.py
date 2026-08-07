from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from .repository import ExternalServiceProviderRepository
from .schemas import PartnerCreate


class ExternalServiceProviderValidator:
    def __init__(self, db: Session):
        self.repository = ExternalServiceProviderRepository(db)

    def validate_create(self, data: PartnerCreate) -> None:
        # If partner is a Commercial Bank and SWIFT Code is provided, ensure unique SWIFT Code
        if data.partner_type.lower() == 'bank' and data.swift_code:
            if self.repository.exists_by_swift_code(data.swift_code):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"A bank with SWIFT Code '{data.swift_code}' already exists."
                )