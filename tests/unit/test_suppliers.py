import unittest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
import modules.audit_logs.model
from modules.suppliers.schemas import SupplierCreate
from modules.suppliers.service import (
    create_supplier_service,
    get_all_suppliers_service,
    delete_supplier_service,
    restore_supplier_service,
    generate_supplier_code,
)

class TestSuppliersBackend(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
        TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        Base.metadata.create_all(bind=self.engine)
        self.db = TestingSessionLocal()

    def tearDown(self):
        self.db.close()
        Base.metadata.drop_all(bind=self.engine)

    def test_supplier_code_generation(self):
        code1 = generate_supplier_code(self.db)
        self.assertEqual(code1, "SUP-000001")

    def test_create_supplier_service(self):
        supplier_data = SupplierCreate(
            company_name="Zhejiang Industrial Co",
            supplier_type="Manufacturer",
            registration_type="Factory",
            foreign_exporter_id="EXP-CN-8899",
            foreign_exporter_country="China",
            foreign_exporter_country_code="CN",
            address="Hangzhou, Zhejiang, China",
            email="export@zhejiang.cn",
            brands="Zhejiang Tools",
        )

        created = create_supplier_service(self.db, supplier_data)
        self.assertIsNotNone(created)
        self.assertIsNotNone(created.supplier_id)
        self.assertEqual(created.supplier_code, "SUP-000001")
        self.assertEqual(created.company_name, "Zhejiang Industrial Co")
        self.assertTrue(created.is_active)

    def test_duplicate_foreign_exporter_id(self):
        supplier_data = SupplierCreate(
            company_name="Supplier 1",
            supplier_type="Trader",
            registration_type="Company",
            foreign_exporter_id="EXP-DUP-1",
            foreign_exporter_country="Germany",
            foreign_exporter_country_code="DE",
            address="Berlin, Germany",
        )
        create_supplier_service(self.db, supplier_data)

        # Attempt duplicate
        dup = create_supplier_service(self.db, supplier_data)
        self.assertIsNone(dup)

    def test_soft_delete_and_restore_supplier(self):
        supplier_data = SupplierCreate(
            company_name="Milan SRL",
            supplier_type="Manufacturer",
            registration_type="Company",
            foreign_exporter_id="EXP-IT-100",
            foreign_exporter_country="Italy",
            foreign_exporter_country_code="IT",
            address="Milan, Italy",
        )
        created = create_supplier_service(self.db, supplier_data)

        # Delete
        delete_supplier_service(self.db, created.supplier_id)
        active = get_all_suppliers_service(self.db)
        self.assertEqual(len(active), 0)

        # Restore
        restored = restore_supplier_service(self.db, created.supplier_id)
        self.assertTrue(restored.is_active)
        active_after_restore = get_all_suppliers_service(self.db)
        self.assertEqual(len(active_after_restore), 1)

if __name__ == "__main__":
    unittest.main()
