from typing import List, Optional
from sqlalchemy import exists, func
from sqlalchemy.orm import Session
from .model import ExternalServiceProvider
from .schemas import PartnerCreate, PartnerUpdate


class ExternalServiceProviderRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_all(self, partner_type: Optional[str] = None, include_inactive: bool = False) -> List[ExternalServiceProvider]:
        query = self.db.query(ExternalServiceProvider)
        if not include_inactive:
            query = query.filter(ExternalServiceProvider.is_active.is_(True))
        if partner_type and partner_type.strip().lower() != 'all':
            query = query.filter(func.lower(ExternalServiceProvider.partner_type) == partner_type.strip().lower())
        return query.order_by(ExternalServiceProvider.provider_id.desc()).all()

    def get_by_id(self, provider_id: int) -> Optional[ExternalServiceProvider]:
        return self.db.query(ExternalServiceProvider).filter(ExternalServiceProvider.provider_id == provider_id).first()

    def get_by_code(self, partner_code: str) -> Optional[ExternalServiceProvider]:
        return self.db.query(ExternalServiceProvider).filter(ExternalServiceProvider.partner_code == partner_code).first()

    def exists_by_code(self, partner_code: str) -> bool:
        return self.db.query(exists().where(ExternalServiceProvider.partner_code == partner_code)).scalar()

    def exists_by_swift_code(self, swift_code: str, exclude_id: Optional[int] = None) -> bool:
        if not swift_code or not swift_code.strip():
            return False
        stmt = exists().where(func.lower(ExternalServiceProvider.swift_code) == swift_code.strip().lower())
        if exclude_id:
            stmt = stmt.where(ExternalServiceProvider.provider_id != exclude_id)
        return self.db.query(stmt).scalar()

    def get_last_partner_id(self) -> int:
        last = self.db.query(ExternalServiceProvider.provider_id).order_by(ExternalServiceProvider.provider_id.desc()).first()
        return last[0] if last else 0

    def create(self, partner_data: PartnerCreate, partner_code: str) -> ExternalServiceProvider:
        db_obj = ExternalServiceProvider(
            partner_code=partner_code,
            **partner_data.model_dump()
        )
        self.db.add(db_obj)
        self.db.commit()
        self.db.refresh(db_obj)
        return db_obj

    def update(self, provider_id: int, partner_data: PartnerUpdate) -> Optional[ExternalServiceProvider]:
        db_obj = self.get_by_id(provider_id)
        if not db_obj:
            return None
        update_data = partner_data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_obj, key, value)
        self.db.commit()
        self.db.refresh(db_obj)
        return db_obj

    def soft_delete(self, provider_id: int) -> bool:
        db_obj = self.get_by_id(provider_id)
        if not db_obj:
            return False
        db_obj.is_active = False
        self.db.commit()
        return True

    def restore(self, provider_id: int) -> bool:
        db_obj = self.get_by_id(provider_id)
        if not db_obj:
            return False
        db_obj.is_active = True
        self.db.commit()
        return True