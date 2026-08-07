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

    from modules.audit_logs.service import AuditLogService
    AuditLogService(db).log_activity(
        entity_type="ImportCompany",
        entity_id=company.company_id,
        entity_code=company.importer_id,
        action="CREATE",
        new_data={"importer_name": company.importer_name, "importer_id": company.importer_id, "vat_id": company.vat_id}
    )

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


from sqlalchemy import exists

# ==================================================
# Check Importer ID Exists (Optimized SQL)
# ==================================================

def importer_id_exists(
    db: Session,
    importer_id: str
) -> bool:

    return db.query(
        exists().where(ImportCompany.importer_id == importer_id)
    ).scalar()


# ==================================================
# Check VAT ID Exists (Optimized SQL)
# ==================================================

def vat_id_exists(
    db: Session,
    vat_id: str
) -> bool:

    return db.query(
        exists().where(ImportCompany.vat_id == vat_id)
    ).scalar()


# ==================================================
# Check Registration Number Exists (Optimized SQL)
# ==================================================

def registration_number_exists(
    db: Session,
    registration_number: str
) -> bool:

    return db.query(
        exists().where(ImportCompany.registration_number == registration_number)
    ).scalar()


# ==================================================
# Save Updates
# ==================================================

def update_company_data(
    db: Session,
    company: ImportCompany,
    update_data: dict
) -> ImportCompany:
    old_data = {
        k: getattr(company, k, None)
        for k in update_data.keys()
    }

    for field, value in update_data.items():
        if field == "email" and value is not None:
            value = str(value)
        setattr(company, field, value)

    try:
        db.commit()
        db.refresh(company)
        from modules.audit_logs.service import AuditLogService
        AuditLogService(db).log_activity(
            entity_type="ImportCompany",
            entity_id=company.company_id,
            entity_code=company.importer_id,
            action="UPDATE",
            old_data=old_data,
            new_data=update_data,
        )
    except Exception:
        db.rollback()
        raise

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

    from modules.audit_logs.service import AuditLogService
    AuditLogService(db).log_activity(
        entity_type="ImportCompany",
        entity_id=company.company_id,
        entity_code=company.importer_id,
        action="DELETE",
    )

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

    from modules.audit_logs.service import AuditLogService
    AuditLogService(db).log_activity(
        entity_type="ImportCompany",
        entity_id=company.company_id,
        entity_code=company.importer_id,
        action="RESTORE",
    )

    return company