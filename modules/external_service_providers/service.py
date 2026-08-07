from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from .repository import ExternalServiceProviderRepository
from .schemas import PartnerCreate, PartnerResponse, PartnerUpdate
from .validators import ExternalServiceProviderValidator


class ExternalServiceProviderService:
    def __init__(self, db: Session):
        self.repository = ExternalServiceProviderRepository(db)
        self.validator = ExternalServiceProviderValidator(db)

    def generate_partner_code(self) -> str:
        last_id = self.repository.get_last_partner_id()
        next_num = last_id + 1
        return f"ESP-{next_num:06d}"

    def get_all_partners(self, partner_type: Optional[str] = None, include_inactive: bool = False) -> List[PartnerResponse]:
        return self.repository.get_all(partner_type=partner_type, include_inactive=include_inactive)

    def get_partner_by_id(self, provider_id: int) -> PartnerResponse:
        partner = self.repository.get_by_id(provider_id)
        if not partner:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Partner not found")
        return partner

    def create_partner(self, data: PartnerCreate) -> PartnerResponse:
        self.validator.validate_create(data)
        partner_code = self.generate_partner_code()
        return self.repository.create(data, partner_code=partner_code)

    def update_partner(self, provider_id: int, data: PartnerUpdate) -> PartnerResponse:
        partner = self.repository.update(provider_id, data)
        if not partner:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Partner not found")
        return partner

    def soft_delete_partner(self, provider_id: int) -> dict:
        success = self.repository.soft_delete(provider_id)
        if not success:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Partner not found")
        return {"detail": "Partner deactivated successfully"}

    def restore_partner(self, provider_id: int) -> dict:
        success = self.repository.restore(provider_id)
        if not success:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Partner not found")
        return {"detail": "Partner reactivated successfully"}