from datetime import date

from .repository import get_companies


def get_all_companies(db):

    companies = get_companies(db)

    today = date.today()

    response = []

    for company in companies:

        response.append({

            "company_id": company.company_id,

            "importer_name": company.importer_name,

            "address": company.address,

            "country": company.country,

            "importer_id": company.importer_id,

            "importer_id_expiry": company.importer_id_expiry,

            "importer_id_days_to_renew":
                (company.importer_id_expiry - today).days,

            "vat_id": company.vat_id,

            "vat_id_expiry": company.vat_id_expiry,

            "vat_id_days_to_renew":
                (company.vat_id_expiry - today).days,

            "registration_number":
                company.registration_number,

            "registration_expiry":
                company.registration_expiry,

            "registration_days_to_renew":
                (company.registration_expiry - today).days,

            "phone": company.phone,

            "email": company.email,

            "is_active": company.is_active

        })

    return response