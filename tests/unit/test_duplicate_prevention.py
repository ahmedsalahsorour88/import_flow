import unittest
from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.common.name_normalizer import normalize_master_data_name, check_duplicate_name
from modules.suppliers.schemas import SupplierCreate
from modules.suppliers.service import create_supplier_service
from modules.import_companies.schemas import ImportCompanyCreate
from modules.import_companies.service import create_import_company
from modules.external_service_providers.schemas import PartnerCreate
from modules.external_service_providers.service import ExternalServiceProviderService


class TestMasterDataDuplicatePrevention(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
        TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        Base.metadata.create_all(bind=self.engine)
        self.db = TestingSessionLocal()

    def tearDown(self):
        self.db.close()
        Base.metadata.drop_all(bind=self.engine)

    def test_name_normalizer(self):
        self.assertEqual(normalize_master_data_name("Suzhou Yuheng Textile Co., Ltd."), "suzhouyuhengtextile")
        self.assertEqual(normalize_master_data_name("Suzhou Yuheng Textile Co., Ltd"), "suzhouyuhengtextile")
        self.assertEqual(normalize_master_data_name("Suzhou Yuheng Textile Co."), "suzhouyuhengtextile")
        self.assertEqual(normalize_master_data_name("Shaw Europe Limited"), "shaweurope")
        self.assertEqual(normalize_master_data_name("Shaw Europe Ltd."), "shaweurope")

    def test_prevent_duplicate_supplier(self):
        supplier1 = SupplierCreate(
            company_name="Suzhou Yuheng Textile Co., Ltd.",
            supplier_type="Manufacturer",
            registration_type="Foreign Exporter",
            foreign_exporter_id="EXP-CN-001",
            foreign_exporter_country="China",
            foreign_exporter_country_code="CN",
            address="No. 16 Kangsheng Road, Changshu, China",
        )
        created = create_supplier_service(self.db, supplier1)
        self.assertIsNotNone(created)

        # Attempt duplicate with slight variation: "Suzhou Yuheng Textile Co., Ltd"
        supplier_dup = SupplierCreate(
            company_name="Suzhou Yuheng Textile Co., Ltd",
            supplier_type="Manufacturer",
            registration_type="Foreign Exporter",
            foreign_exporter_id="EXP-CN-002",
            foreign_exporter_country="China",
            foreign_exporter_country_code="CN",
            address="No. 16 Kangsheng Road, Changshu, China",
        )
        with self.assertRaises(HTTPException) as ctx:
            create_supplier_service(self.db, supplier_dup)

        self.assertEqual(ctx.exception.status_code, 400)
        self.assertIn("مسجل بالفعل بالنظام", ctx.exception.detail)

    def test_prevent_duplicate_import_company(self):
        comp1 = ImportCompanyCreate(
            importer_name="المصرية للاستيراد والتصدير ش.م.م",
            address="القاهرة - مصر",
            country="Egypt",
            importer_id="IMP-REG-100",
            vat_id="123456789",
            registration_number="554433",
        )
        create_import_company(self.db, comp1)

        # Attempt duplicate with variation
        comp_dup = ImportCompanyCreate(
            importer_name="المصرية للاستيراد والتصدير",
            address="القاهرة - مصر",
            country="Egypt",
            importer_id="IMP-REG-101",
            vat_id="987654321",
            registration_number="998877",
        )
        with self.assertRaises(HTTPException) as ctx:
            create_import_company(self.db, comp_dup)

        self.assertEqual(ctx.exception.status_code, 400)
        self.assertIn("مسجلة بالفعل بالنظام", ctx.exception.detail)

    def test_prevent_duplicate_partner(self):
        service = ExternalServiceProviderService(self.db)
        partner1 = PartnerCreate(
            partner_name="Shaw Logistics Europe Ltd.",
            partner_type="Freight Forwarder",
            contact_person="John Doe",
            email="info@shawlogistics.co.uk",
        )
        service.create_partner(partner1)

        # Attempt duplicate with variation
        partner_dup = PartnerCreate(
            partner_name="Shaw Logistics Europe Limited",
            partner_type="Freight Forwarder",
            contact_person="Jane Doe",
            email="contact@shawlogistics.co.uk",
        )
        with self.assertRaises(HTTPException) as ctx:
            service.create_partner(partner_dup)

        self.assertEqual(ctx.exception.status_code, 400)
        self.assertIn("مسجل بالفعل بالنظام", ctx.exception.detail)


if __name__ == "__main__":
    unittest.main()
