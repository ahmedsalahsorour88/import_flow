from sqlalchemy.orm import Session

from .model import ImportCompany
from .repository import (
    create_company,
    get_companies,
    get_all_companies_admin,
    get_company_by_id as repo_get_company_by_id,
    update_company_data,
    delete_company as repo_delete_company,
    restore_company as repo_restore_company,
)
from .schemas import ImportCompanyCreate, ImportCompanyUpdate
from .utils import calculate_days_to_renew
from .validators import validate_company


# ==================================================
# Add Days To Renew Calculations
# ==================================================

def add_days_to_renew(company: ImportCompany) -> ImportCompany:
    """Calculates remaining days for importer ID, VAT, and Commercial registration."""
    if company.importer_id_expiry:
        company.importer_id_days_to_renew = calculate_days_to_renew(company.importer_id_expiry)

    if company.vat_id_expiry:
        company.vat_id_days_to_renew = calculate_days_to_renew(company.vat_id_expiry)

    if company.registration_expiry:
        company.registration_days_to_renew = calculate_days_to_renew(company.registration_expiry)

    return company


# ==================================================
# Create Company Service
# ==================================================

def create_import_company(
    db: Session,
    company_data: ImportCompanyCreate
) -> ImportCompany:
    """Validates domain business rules and creates a new ImportCompany record."""
    validate_company(db, company_data)
    result = create_company(db, company_data)
    return add_days_to_renew(result)


# ==================================================
# Get All Active Companies Service
# ==================================================

def get_all_companies(db: Session) -> list[ImportCompany]:
    """Retrieves all active import companies with renewal day metrics."""
    companies = get_companies(db)
    for company in companies:
        add_days_to_renew(company)
    return companies


# ==================================================
# Get All Companies (Admin - Including Inactive)
# ==================================================

def get_all_companies_admin_service(db: Session) -> list[ImportCompany]:
    """Retrieves all import companies (active and deactivated) for admin view."""
    companies = get_all_companies_admin(db)
    for company in companies:
        add_days_to_renew(company)
    return companies


# ==================================================
# Get Company By ID Service
# ==================================================

def get_company_by_id(db: Session, company_id: int) -> ImportCompany | None:
    """Retrieves a single company by primary key ID."""
    company = repo_get_company_by_id(db, company_id)
    if company:
        add_days_to_renew(company)
    return company


# ==================================================
# Update Company Service
# ==================================================

def update_import_company(
    db: Session,
    company_id: int,
    company_data: ImportCompanyUpdate
) -> ImportCompany | None:
    """Updates an existing company's attributes via repository pattern."""
    company = repo_get_company_by_id(db, company_id)
    if company is None:
        return None

    update_dict = company_data.model_dump(
        exclude_unset=True,
        exclude_none=True
    )

    updated_company = update_company_data(db, company, update_dict)
    return add_days_to_renew(updated_company)


# ==================================================
# Soft Delete Company Service
# ==================================================

def delete_import_company(db: Session, company_id: int) -> ImportCompany | None:
    """Soft deletes a company by setting is_active = False."""
    company = repo_get_company_by_id(db, company_id)
    if not company:
        return None

    if not company.is_active:
        return add_days_to_renew(company)

    deleted_company = repo_delete_company(db, company)
    return add_days_to_renew(deleted_company)


# ==================================================
# Restore Company Service
# ==================================================

def restore_import_company(db: Session, company_id: int) -> ImportCompany | None:
    """Restores a soft-deleted company back to active state."""
    company = repo_get_company_by_id(db, company_id)
    if not company:
        return None

    restored_company = repo_restore_company(db, company)
    return add_days_to_renew(restored_company)