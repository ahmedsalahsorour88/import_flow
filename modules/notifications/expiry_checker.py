from datetime import date, datetime, timezone
from typing import List
from sqlalchemy.orm import Session

from modules.import_companies.model import ImportCompany
from modules.import_documentation.model import AcidRegistrationSession
from .repository import NotificationRepository
from .schemas import NotificationCreate


class ExpiryCheckerService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = NotificationRepository(db)

    def check_all_expiries(self) -> List[NotificationCreate]:
        new_notifications = []
        today = date.today()

        # 1. Check Import Companies Expiries (Importer ID, VAT ID, Reg Number)
        companies = self.db.query(ImportCompany).filter(ImportCompany.is_active == True).all()
        for company in companies:
            # Importer ID Expiry
            if company.importer_id_expiry:
                days_left = (company.importer_id_expiry - today).days
                if days_left <= 30:
                    severity = "CRITICAL" if days_left <= 7 else "WARNING"
                    category = "COMPANY_EXPIRY"
                    if not self.repo.exists_active_for_entity("ImportCompany", company.company_id, f"{category}_IMP_ID"):
                        schema = NotificationCreate(
                            title=f"تنبيه انتهاء البطاقة الاستيرادية: {company.importer_name}",
                            message=f"البطاقة الاستيرادية (رقم {company.importer_id}) متبقي عليها {days_left} يوماً وتنتهي في {company.importer_id_expiry}. يرجى التجديد فوراً.",
                            severity=severity,
                            category=f"{category}_IMP_ID",
                            entity_type="ImportCompany",
                            entity_id=company.company_id,
                            target_role="ALL",
                        )
                        created = self.repo.create(schema)
                        new_notifications.append(created)

            # Commercial Registration Expiry
            if company.registration_expiry:
                days_left = (company.registration_expiry - today).days
                if days_left <= 30:
                    severity = "CRITICAL" if days_left <= 7 else "WARNING"
                    category = "COMPANY_EXPIRY"
                    if not self.repo.exists_active_for_entity("ImportCompany", company.company_id, f"{category}_REG"):
                        schema = NotificationCreate(
                            title=f"تنبيه انتهاء السجل التجاري: {company.importer_name}",
                            message=f"السجل التجاري (رقم {company.registration_number}) متبقي عليه {days_left} يوماً وينتهي في {company.registration_expiry}.",
                            severity=severity,
                            category=f"{category}_REG",
                            entity_type="ImportCompany",
                            entity_id=company.company_id,
                            target_role="ALL",
                        )
                        created = self.repo.create(schema)
                        new_notifications.append(created)

        # 2. Check ACID Sessions Expiry (30-day validity window)
        acid_sessions = self.db.query(AcidRegistrationSession).filter(
            AcidRegistrationSession.is_active == True,
            AcidRegistrationSession.status == "ACID Issued"
        ).all()

        for acid in acid_sessions:
            if acid.expiry_date:
                days_left = (acid.expiry_date - today).days
                if days_left <= 10:
                    severity = "CRITICAL" if days_left <= 3 else "WARNING"
                    if not self.repo.exists_active_for_entity("AcidRegistrationSession", acid.acid_session_id, "ACID_EXPIRY"):
                        schema = NotificationCreate(
                            title=f"تنبيه قرب انتهاء الرقم المبدئي ACID: {acid.acid_number}",
                            message=f"رقم الـ ACID ({acid.acid_number}) للشحنة متبقي عليه {days_left} أيام فقط قبل الشحن وتنتهي صلاحيته في {acid.expiry_date}.",
                            severity=severity,
                            category="ACID_EXPIRY",
                            entity_type="AcidRegistrationSession",
                            entity_id=acid.acid_session_id,
                            target_role="ALL",
                        )
                        created = self.repo.create(schema)
                        new_notifications.append(created)

        return new_notifications
