from fastapi import HTTPException
from sqlalchemy.orm import Session

from .repository import importer_id_exists
from .repository import registration_number_exists
from .repository import vat_id_exists

from .schemas import ImportCompanyCreate


# ==================================================
# Validate Company
# ==================================================

def validate_company(
    db: Session,
    company_data: ImportCompanyCreate
) -> None:

    if importer_id_exists(
        db,
        company_data.importer_id
    ):
        raise HTTPException(
            status_code=400,
            detail="Importer ID already exists."
        )

    if vat_id_exists(
        db,
        company_data.vat_id
    ):
        raise HTTPException(
            status_code=400,
            detail="VAT ID already exists."
        )

    if registration_number_exists(
        db,
        company_data.registration_number
    ):
        raise HTTPException(
            status_code=400,
            detail="Registration Number already exists."
        )