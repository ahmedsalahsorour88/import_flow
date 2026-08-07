from sqlalchemy.orm import Session

from .model import ImportCompany

from .repository import create_company
from .repository import get_companies
from .repository import restore_company

from .schemas import ImportCompanyCreate
from .schemas import ImportCompanyUpdate

from .utils import calculate_days_to_renew
from .validators import validate_company


# ==================================================
# Add Days To Renew
# ==================================================

def add_days_to_renew(
    company: ImportCompany
) -> ImportCompany:

    if company.importer_id_expiry:

        company.importer_id_days_to_renew = (
            calculate_days_to_renew(
                company.importer_id_expiry
            )
        )

    if company.vat_id_expiry:

        company.vat_id_days_to_renew = (
            calculate_days_to_renew(
                company.vat_id_expiry
            )
        )

    if company.registration_expiry:

        company.registration_days_to_renew = (
            calculate_days_to_renew(
                company.registration_expiry
            )
        )

    return company


# ==================================================
# Create Company
# ==================================================

def create_import_company(
    db: Session,
    company_data: ImportCompanyCreate
) -> ImportCompany:

    validate_company(
        db,
        company_data
    )

    result = create_company(
        db,
        company_data
    )

    return add_days_to_renew(
        result
    )


# ==================================================
# Get All Companies
# ==================================================

def get_all_companies(
    db: Session
) -> list[ImportCompany]:

    companies = get_companies(
        db
    )

    for company in companies:

        add_days_to_renew(
            company
        )

    return companies


# ==================================================
# Get Company By ID
# ==================================================

def get_company_by_id(
    db: Session,
    company_id: int
) -> ImportCompany | None:

    company = (

        db.query(ImportCompany)

        .filter(
            ImportCompany.company_id == company_id
        )

        .first()
    )

    if company:

        add_days_to_renew(
            company
        )

    return company


# ==================================================
# Update Company
# ==================================================

def update_import_company(
    db: Session,
    company_id: int,
    company_data: ImportCompanyUpdate
) -> ImportCompany | None:

    company = (
        db.query(ImportCompany)
        .filter(
            ImportCompany.company_id == company_id
        )
        .first()
    )

    if company is None:
        return None

    update_data = company_data.model_dump(
        exclude_unset=True,
        exclude_none=True
    )

    for field, value in update_data.items():

        if field == "email":
            value = str(value)

        setattr(
            company,
            field,
            value
        )

    try:
        db.commit()
        db.refresh(company)

    except Exception as e:
        db.rollback()
        print("UPDATE ERROR:", e)
        raise

    return add_days_to_renew(company)


# ==================================================
# Soft Delete Company
# ==================================================

def delete_import_company(
    db: Session,
    company_id: int
) -> ImportCompany | None:

    company = (

        db.query(ImportCompany)

        .filter(
            ImportCompany.company_id == company_id
        )

        .first()
    )

    if not company:

        return None

    if not company.is_active:

        return add_days_to_renew(
            company
        )

    company.is_active = False

    company.updated_by = "admin"

    db.commit()

    db.refresh(
        company
    )

    return add_days_to_renew(
        company
    )


# ==================================================
# Restore Company
# ==================================================

def restore_import_company(
    db: Session,
    company_id: int
) -> ImportCompany | None:

    company = (

        db.query(ImportCompany)

        .filter(
            ImportCompany.company_id == company_id
        )

        .first()
    )

    if not company:

        return None

    company = restore_company(
        db,
        company
    )

    company = add_days_to_renew(
        company
    )

    return company