import unittest
from datetime import date, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.import_companies.schemas import ImportCompanyCreate
from modules.import_companies.service import (
    create_import_company,
    get_all_companies,
    delete_import_company,
    restore_import_company,
)
from modules.import_companies.utils import calculate_days_to_renew

class TestImportCompaniesBackend(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
        TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        Base.metadata.create_all(bind=self.engine)
        self.db = TestingSessionLocal()

    def tearDown(self):
        self.db.close()
        Base.metadata.drop_all(bind=self.engine)

    def test_calculate_days_to_renew(self):
        future_date = date.today() + timedelta(days=45)
        days = calculate_days_to_renew(future_date)
        self.assertEqual(days, 45)

    def test_create_import_company_service(self):
        company_data = ImportCompanyCreate(
            importer_name="Pharaohs Trading Co",
            address="12 Ramses St, Cairo",
            country="Egypt",
            importer_id="IMP-100200",
            importer_id_expiry=date.today() + timedelta(days=120),
            vat_id="VAT-998877",
            vat_id_expiry=date.today() + timedelta(days=90),
            registration_number="REG-554433",
            registration_expiry=date.today() + timedelta(days=60),
        )
        
        created = create_import_company(self.db, company_data)
        self.assertIsNotNone(created.company_id)
        self.assertEqual(created.importer_name, "Pharaohs Trading Co")
        self.assertTrue(created.is_active)

    def test_get_active_companies_filtering(self):
        c1 = create_import_company(self.db, ImportCompanyCreate(
            importer_name="Company A",
            address="Address A",
            country="Egypt",
            importer_id="IMP-A",
            importer_id_expiry=date.today(),
            vat_id="VAT-A",
            vat_id_expiry=date.today(),
            registration_number="REG-A",
            registration_expiry=date.today(),
        ))
        
        companies = get_all_companies(self.db)
        self.assertEqual(len(companies), 1)
        
        # Soft Delete
        delete_import_company(self.db, c1.company_id)
        
        active_companies = get_all_companies(self.db)
        self.assertEqual(len(active_companies), 0)

    def test_restore_company(self):
        c1 = create_import_company(self.db, ImportCompanyCreate(
            importer_name="Company B",
            address="Address B",
            country="Egypt",
            importer_id="IMP-B",
            importer_id_expiry=date.today(),
            vat_id="VAT-B",
            vat_id_expiry=date.today(),
            registration_number="REG-B",
            registration_expiry=date.today(),
        ))
        
        delete_import_company(self.db, c1.company_id)
        restored = restore_import_company(self.db, c1.company_id)
        self.assertTrue(restored.is_active)
        
        active = get_all_companies(self.db)
        self.assertEqual(len(active), 1)

if __name__ == "__main__":
    unittest.main()
