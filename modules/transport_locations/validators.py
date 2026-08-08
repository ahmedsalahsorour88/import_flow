from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from modules.transport_locations.repository import TransportLocationRepository


class TransportLocationValidator:

    def __init__(self, db: Session):
        self.repo = TransportLocationRepository(db)

    def validate_no_duplicate_locode(self, un_locode: str, exclude_id: int = None):
        existing = self.repo.get_by_un_locode(un_locode)
        if existing and (exclude_id is None or existing.location_id != exclude_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Transport location with UN/LOCODE '{un_locode.upper()}' already exists.",
            )
