import unittest
from datetime import date, datetime, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
import modules.transport_locations.model as loc_models
import modules.freight_quotations.model as rfq_models
import modules.projects.model as proj_models
import modules.incoterms.model as incoterm_models
import modules.currencies.model as curr_models
import modules.customs_tariff.model as tariff_models
import modules.shipping_scenarios.model as scen_models
import modules.import_files.model as imp_models
import modules.import_companies.model as comp_models
import modules.suppliers.model as supp_models
import modules.external_service_providers.model as partner_models
import modules.purchase_orders.model as po_models
import modules.freight_booking.model as fb_models
import modules.cargo_shipping.model as cs_models
import modules.import_documentation.model as doc_models

from modules.import_documentation.schemas import (
    DocumentExtractRequest,
    ThreeWayCrossMatchRequest,
)
import modules.import_documentation.service as service


class TestCustomsCertificatesEngine(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(cls.engine)
        cls.SessionLocal = sessionmaker(bind=cls.engine)

    def setUp(self):
        Base.metadata.drop_all(self.engine)
        Base.metadata.create_all(self.engine)
        self.db = self.SessionLocal()

        # Seed Company
        self.company = comp_models.ImportCompany(
            importer_name="Archi brands for corpet and floor trading",
            importer_id="IC-11728",
            importer_id_expiry=date.today() + timedelta(days=120),
            vat_id="EG-11728001",
            vat_id_expiry=date.today() + timedelta(days=120),
            registration_number="CR-11728",
            registration_expiry=date.today() + timedelta(days=120),
            country="Egypt",
            address="Maadi, Street 18, Building 44, Third Floor, Cairo 11728 - Egypt",
            is_active=True,
        )
        self.db.add(self.company)
        self.db.commit()

        # Seed Supplier
        self.supplier = supp_models.Supplier(
            supplier_code="SUP-NARBUTAS-001",
            company_name="UAB Narbutas International",
            supplier_type="Manufacturer",
            registration_type="VAT Number",
            foreign_exporter_id="LT300591314",
            foreign_exporter_country="Lithuania",
            foreign_exporter_country_code="LT",
            address="Eitminu g. 3, LT012113, Vilnius, Lithuania",
            is_active=True,
        )
        self.db.add(self.supplier)
        self.db.commit()

        # Seed Import File
        self.file = imp_models.ImportFile(
            import_file_code="IMP-2026-0042",
            custom_file_number="FILE-NARBUTAS-001",
            company_id=self.company.company_id,
            company_name=self.company.importer_name,
            supplier_id=self.supplier.supplier_id,
            supplier_name=self.supplier.company_name,
            pi_number="IN053328",
            estimated_cost=15375.50,
            estimated_cost_currency="EUR",
            acid_number="7595528271020210010",
            incoterm_code="EXW",
            port_of_loading="Vilnius / Klaipeda",
            port_of_discharge="Alexandria",
            is_active=True,
        )
        self.db.add(self.file)
        self.db.commit()

        # Seed ACID Session
        self.acid_session = doc_models.AcidRegistrationSession(
            acid_code="ACID-SESS-0042",
            acid_number="7595528271020210010",
            import_file_id=self.file.import_file_id,
            importer_name=self.company.importer_name,
            importer_tax_id="123456789",
            exporter_name=self.supplier.company_name,
            exporter_reg_id="LT300591314",
            exporter_country="Lithuania",
            proforma_invoice_no="IN053328",
            pol_name="Klaipeda",
            pod_name="Alexandria",
            expiry_date=date.today() + timedelta(days=90),
            status="Verified",
            is_active=True,
        )
        self.db.add(self.acid_session)
        self.db.commit()

    def tearDown(self):
        self.db.close()

    def test_generate_eur1_draft_template(self):
        res = service.generate_coo_draft_template_service(self.db, self.file.import_file_id, cert_type="EUR.1")
        self.assertEqual(res.import_file_id, self.file.import_file_id)
        self.assertEqual(res.certificate_type, "EUR.1 Movement Certificate")
        self.assertIn("REVISED RULES", res.template_data["box_7_remarks"])
        self.assertIn("7595528271020210010", res.template_data["box_10_invoices_and_acid"])
        self.assertIn("141 PACKAGES", res.template_data["box_8_description_packages"])
        self.assertTrue(res.template_data["is_revised_rules_compliant"])
        self.assertIn("0%", res.exemption_notes)

    def test_generate_china_ccpit_draft_template(self):
        res = service.generate_coo_draft_template_service(self.db, self.file.import_file_id, cert_type="China Certificate of Origin (CCPIT)")
        self.assertEqual(res.import_file_id, self.file.import_file_id)
        self.assertEqual(res.certificate_type, "China Certificate of Origin (CCPIT)")
        self.assertIn("CCPIT", res.template_data["box_5_certifying_authority"])
        self.assertIn("check.ecoccpit.net", res.template_data["verification_url"])
        self.assertIn("7595528271020210010", res.template_data["box_7_description_and_acid"])

    def test_generate_inspection_draft_template(self):
        res = service.generate_inspection_draft_template_service(
            self.db, self.file.import_file_id, agency="COTECNA", cert_type="COC (Certificate of Conformity)"
        )
        self.assertEqual(res.import_file_id, self.file.import_file_id)
        self.assertEqual(res.inspection_agency, "COTECNA")
        self.assertTrue(res.template_data["is_draft"])
        self.assertIn("48 HOURS", res.template_data["confirmation_deadline"])
        self.assertIn("7595528271020210010", res.template_data["acid_number"])
        self.assertTrue(len(res.applicable_standards) >= 3)

    def test_extract_china_ccpit_coo_text(self):
        sample_text = """
        ORIGINAL Page 1 of 1
        1.Exporter
        SUZHOU GREENISH IMP&EXP CO.,LTD.
        NO.78 SUNWU ROAD, XUKOU TOWN, WUZHONG DISTRICT, SUZHOU CHINA
        Certificate No. 26C311120218/00004
        CERTIFICATE OF ORIGIN OF THE PEOPLE'S REPUBLIC OF CHINA
        2.Consignee
        SCAS FOR CONSTRUCTION AND FINISHING
        44, RD 81, MAADI SARAYAT CAIRO, EGYPT
        3.Means of transport and route
        FROM SHANGHAI CHINA TO ALEXANDRIA EGYPT BY SEA
        5.For certifying authority use only
        CHINA COUNCIL FOR THE PROMOTION OF INTERNATIONAL TRADE
        VERIFY URL:HTTP://CHECK.ECOCCPIT.NET/
        4.Country of destination EGYPT
        7.Number and kind of packages: ACOUSTIC PANEL ACID:5281534391017110019
        8.H.S.Code 560229
        9.Quantity 810 SHEETS G.WEIGHT 4904 KGS G.W.
        10.Number and date of invoices GRS20260505T9 MAY.05,2026
        SUZHOU,CHINA JUL.30,2026
        """
        req = DocumentExtractRequest(document_type="CHINA_COO", raw_text=sample_text)
        res = service.extract_document_service(req)
        extracted = res.extracted_data
        self.assertEqual(extracted["certificate_number"], "26C311120218/00004")
        self.assertEqual(extracted["acid_number"], "5281534391017110019")
        self.assertEqual(extracted["hs_code"], "560229")
        self.assertEqual(extracted["gross_weight_kg"], 4904.0)
        self.assertEqual(extracted["invoice_number"], "GRS20260505T9")
        self.assertTrue(extracted["is_official_ccpit"])

    def test_extract_eur1_text(self):
        sample_text = """
        MOVEMENT CERTIFICATE EUR.1 No A 084188
        1. Exporter: LT300591314, UAB NARBUTAS INTERNATIONAL, EITMINIU G. 3, VILNIUS, LITHUANIA
        2. Certificate used in preferential trade between EU and EGYPT
        3. Consignee: ARCHI BRANDS FOR CORPET AND FLOOR TRADING, CAIRO 11728, EGYPT
        4. Country of origin: EU
        5. Country of destination: EGYPT
        7. Remarks: REVISED RULES
        8. Description of goods: OFFICE FURNITURE 141 PACKAGES HS9401; HS9403
        9. Gross mass (kg): 1774,514KG
        10. Invoices: ACID 7595528271020210010
        11. Customs endorsement: Vilniaus LT-VM A-004 Date: 2026-08-11
        """
        req = DocumentExtractRequest(document_type="EUR1", raw_text=sample_text)
        res = service.extract_document_service(req)
        extracted = res.extracted_data
        self.assertEqual(extracted["acid_number"], "7595528271020210010")
        self.assertTrue(extracted["is_revised_rules"])
        self.assertEqual(extracted["gross_weight_kg"], 1774.514)
        self.assertEqual(extracted["packages_count"], 141)
        self.assertTrue(extracted["is_preferential_exemption_eligible"])

    def test_extract_inspection_voc_text(self):
        sample_text = """
        COTECNA Certificate of Conformity (COC)
        PLEASE CONFIRM THIS DRAFT WITHIN 48 HOURS AFTER WHICH WE SHALL PROCEED TO ISSUE AS IT IS
        Importer name: Archi brands for corpet and floor trading
        Exporter name: UAB Narbutas International
        Commercial Invoice No.: IN053328 Dated:07-08-2026
        Country of origin: Lithuania
        Value: 15,375.50 EUR EXW
        Acid Number: 7595528271020210010
        Date of Inspection: 03/08/2026
        Standards: ES 4029-1 / 2024 + ES 7321 / 2011 + EN 13501-1:2018
        """
        req = DocumentExtractRequest(document_type="INSPECTION_VOC", raw_text=sample_text)
        res = service.extract_document_service(req)
        extracted = res.extracted_data
        self.assertEqual(extracted["inspection_agency"], "COTECNA")
        self.assertTrue(res.is_draft_detected)
        self.assertEqual(extracted["acid_number"], "7595528271020210010")
        self.assertEqual(extracted["total_invoice_amount"], 15375.50)
        self.assertEqual(extracted["currency"], "EUR")

    def test_three_way_cross_match_success(self):
        coo_data = {
            "certificate_type": "EUR.1 Movement Certificate",
            "acid_number": "7595528271020210010",
            "importer_name": "Archi brands for corpet and floor trading",
            "exporter_name": "UAB Narbutas International",
            "gross_weight_kg": 1774.514,
            "remarks": "REVISED RULES",
            "is_revised_rules": True,
        }
        inspection_data = {
            "acid_number": "7595528271020210010",
            "importer_name": "Archi brands for corpet and floor trading",
            "exporter_name": "UAB Narbutas International",
            "is_draft": False,
        }
        bl_data = {
            "acid_number": "7595528271020210010",
            "consignee": "Archi brands for corpet and floor trading",
            "shipper": "UAB Narbutas International",
            "total_gross_weight": 1774.514,
        }
        req = ThreeWayCrossMatchRequest(
            import_file_id=self.file.import_file_id,
            coo_data=coo_data,
            inspection_data=inspection_data,
            bl_data=bl_data,
        )
        res = service.cross_match_certificates_service(self.db, req)
        self.assertEqual(res.overall_status, "FULLY_MATCHED")
        self.assertTrue(res.is_safe_for_customs)
        self.assertEqual(res.match_score, 100.0)
        self.assertEqual(len(res.critical_discrepancies), 0)


if __name__ == "__main__":
    unittest.main()
