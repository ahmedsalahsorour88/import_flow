from sqlalchemy.orm import Session

from .model import ImportCompany
from .schemas import ImportCompanyCreate


# ==================================================
# Create Company
# ==================================================

def create_company(
    db: Session,
    company_data: ImportCompanyCreate
) -> ImportCompany:

    company = ImportCompany(
        importer_name=company_data.importer_name,
        address=company_data.address,
        country=company_data.country,
        foreign_exporter_registration_type=company_data.foreign_exporter_registration_type,
        importer_id=company_data.importer_id,
        importer_id_expiry=company_data.importer_id_expiry,
        vat_id=company_data.vat_id,
        vat_id_expiry=company_data.vat_id_expiry,
        registration_number=company_data.registration_number,
        registration_expiry=company_data.registration_expiry,
        phone=company_data.phone,
        email=str(company_data.email) if company_data.email else None,
        notes=company_data.notes,
        created_by=company_data.created_by
    )

    db.add(company)
    db.commit()
    db.refresh(company)

    return company


# ==================================================
# Get Active Companies
# ==================================================

def get_companies(
    db: Session
) -> list[ImportCompany]:

    return (
        db.query(ImportCompany)
        .filter(ImportCompany.is_active == True)
        .order_by(ImportCompany.company_id)
        .all()
    )


# ==================================================
# Get All Companies
# ==================================================

def get_all_companies_admin(
    db: Session
) -> list[ImportCompany]:

    return (
        db.query(ImportCompany)
        .order_by(ImportCompany.company_id)
        .all()
    )


# ==================================================
# Get Company By ID
# ==================================================

def get_company_by_id(
    db: Session,
    company_id: int
) -> ImportCompany | None:

    return (
        db.query(ImportCompany)
        .filter(ImportCompany.company_id == company_id)
        .first()
    )


# ==================================================
# Get Company By Importer ID
# ==================================================

def get_company_by_importer_id(
    db: Session,
    importer_id: str
) -> ImportCompany | None:

    return (
        db.query(ImportCompany)
        .filter(ImportCompany.importer_id == importer_id)
        .first()
    )


# ==================================================
# Check Importer ID Exists
# ==================================================

def importer_id_exists(
    db: Session,
    importer_id: str
) -> bool:

    return (
        db.query(ImportCompany)
        .filter(ImportCompany.importer_id == importer_id)
        .first()
        is not None
    )


# ==================================================
# Check VAT ID Exists
# ==================================================

def vat_id_exists(
    db: Session,
    vat_id: str
) -> bool:

    return (
        db.query(ImportCompany)
        .filter(ImportCompany.vat_id == vat_id)
        .first()
        is not None
    )


# ==================================================
# Check Registration Number Exists
# ==================================================

def registration_number_exists(
    db: Session,
    registration_number: str
) -> bool:

    return (
        db.query(ImportCompany)
        .filter(
            ImportCompany.registration_number == registration_number
        )
        .first()
        is not None
    )


# ==================================================
# Save Updates
# ==================================================

def update_company(
    db: Session,
    company: ImportCompany
) -> ImportCompany:

    db.commit()
    db.refresh(company)

    return company


# ==================================================
# Soft Delete Company
# ==================================================

def delete_company(
    db: Session,
    company: ImportCompany
) -> ImportCompany:

    company.is_active = False

    db.commit()
    db.refresh(company)

    return company


# ==================================================
# Restore Company
# ==================================================

def restore_company(
    db: Session,
    company: ImportCompany
) -> ImportCompany:

    company.is_active = True

    db.commit()
    db.refresh(company)

    return company