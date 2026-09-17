import os
import sys
import unittest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from database.database import Base
import modules.audit_logs.model
import modules.transport_locations.model
import modules.import_companies.model
import modules.suppliers.model
import modules.incoterms.model
import modules.currencies.model
import modules.customs_tariff.model
import modules.projects.model
import modules.purchase_orders.model
import modules.import_files.model
import modules.shipping_scenarios.model
import modules.freight_quotations.model
import modules.customs_consultation.model
import modules.financial_approval.model
import modules.import_documentation.model
import modules.freight_booking.model
import modules.cargo_shipping.model
import modules.customs_clearance.model
import modules.warehouse_receiving.model
import modules.financial_settlement.model
import modules.file_closure.model
from modules.external_service_providers.model import ExternalServiceProvider
from modules.external_service_providers.schemas import PartnerCreate
from modules.external_service_providers.service import ExternalServiceProviderService


class TestExternalServiceProviderService(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:")
        TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        Base.metadata.create_all(bind=self.engine)
        self.db = TestingSessionLocal()
        self.service = ExternalServiceProviderService(self.db)

    def tearDown(self):
        self.db.close()
        Base.metadata.drop_all(bind=self.engine)

    def test_create_partner_bank(self):
        partner_data = PartnerCreate(
            partner_name="National Bank of Egypt",
            partner_type="Bank",
            swift_code="NBEGEGXCAXXX",
            bank_code="NBE",
            branch_name="Main Cairo Branch",
            country="Egypt",
        )

        created = self.service.create_partner(partner_data)

        self.assertIsNotNone(created.provider_id)
        self.assertEqual(created.partner_code, "ESP-000001")
        self.assertEqual(created.partner_name, "National Bank of Egypt")
        self.assertEqual(created.swift_code, "NBEGEGXCAXXX")
        self.assertTrue(created.is_active)

    def test_create_partner_shipping_line(self):
        partner_data = PartnerCreate(
            partner_name="Maersk Line",
            partner_type="Shipping Line",
            scac_code="MAEU",
            default_free_days=14,
            tracking_url="https://www.maersk.com/tracking/",
            country="Denmark",
        )

        created = self.service.create_partner(partner_data)

        self.assertEqual(created.partner_code, "ESP-000001")
        self.assertEqual(created.partner_name, "Maersk Line")
        self.assertEqual(created.scac_code, "MAEU")
        self.assertEqual(created.default_free_days, 14)

    def test_create_shipping_line_scac_and_free_days_validation(self):
        # MD-04: Test creation with custom free days agreement
        cma_data = PartnerCreate(
            partner_name="CMA CGM Shipping",
            partner_type="Shipping Line",
            scac_code="CMDU",
            default_free_days=21,
            tracking_url="https://www.cma-cgm.com/ebusiness/tracking",
            country="France",
        )
        created = self.service.create_partner(cma_data)
        self.assertEqual(created.scac_code, "CMDU")
        self.assertEqual(created.default_free_days, 21)

        # Duplicate SCAC prevention
        dup_scac_data = PartnerCreate(
            partner_name="CMA CGM Egypt Agency",
            partner_type="Shipping Line",
            scac_code="cmdu",  # Case-insensitive duplicate test
            country="Egypt",
        )
        with self.assertRaises(Exception) as ctx:
            self.service.create_partner(dup_scac_data)
        self.assertIn("مسجل بالفعل للخط الملاحي", str(ctx.exception))

        # Negative free days validation
        with self.assertRaises(Exception) as ctx2:
            PartnerCreate(
                partner_name="Evergreen Marine",
                partner_type="Shipping Line",
                scac_code="EGLV",
                default_free_days=-3,
            )
        self.assertTrue(
            "greater_than_equal" in str(ctx2.exception) or "فترة السماح الافتراضية" in str(ctx2.exception)
        )

    def test_filter_by_partner_type(self):
        self.service.create_partner(PartnerCreate(partner_name="Bank 1", partner_type="Bank", swift_code="BNK1"))
        self.service.create_partner(PartnerCreate(partner_name="Shipping Line 1", partner_type="Shipping Line", scac_code="LINE1"))
        self.service.create_partner(PartnerCreate(partner_name="Combined Provider", partner_type="Customs Broker, Freight Forwarder"))

        all_partners = self.service.get_all_partners()
        banks_only = self.service.get_all_partners(partner_type="Bank")
        shipping_only = self.service.get_all_partners(partner_type="Shipping Line")
        broker_only = self.service.get_all_partners(partner_type="Customs Broker")
        freight_only = self.service.get_all_partners(partner_type="Freight Forwarder")

        self.assertEqual(len(all_partners), 3)
        self.assertEqual(len(banks_only), 1)
        self.assertEqual(banks_only[0].partner_name, "Bank 1")
        self.assertEqual(len(shipping_only), 1)
        self.assertEqual(len(broker_only), 1)
        self.assertEqual(broker_only[0].partner_name, "Combined Provider")
        self.assertEqual(len(freight_only), 1)
        self.assertEqual(freight_only[0].partner_name, "Combined Provider")
        self.assertEqual(shipping_only[0].partner_name, "Shipping Line 1")

    def test_soft_delete_and_restore_partner(self):
        created = self.service.create_partner(PartnerCreate(partner_name="Customs Broker Inc", partner_type="Customs Broker"))

        # Soft Delete
        self.service.soft_delete_partner(created.provider_id)
        active_list = self.service.get_all_partners(include_inactive=False)
        self.assertEqual(len(active_list), 0)

        # Restore
        self.service.restore_partner(created.provider_id)
        restored_list = self.service.get_all_partners(include_inactive=False)
        self.assertEqual(len(restored_list), 1)

    def test_partner_statement_of_account(self):
        created = self.service.create_partner(PartnerCreate(partner_name="Alexandria Customs Clearing Co", partner_type="Customs Broker"))
        soa = self.service.get_partner_statement_of_account(created.provider_id)

        self.assertEqual(soa["provider_id"], created.provider_id)
        self.assertEqual(soa["partner_name"], "Alexandria Customs Clearing Co")
        self.assertIn("currency_balances", soa)
        self.assertIn("ledger_entries", soa)

    def test_create_bank_partner_with_swift_and_duplicate_prevention(self):
        # MD-03 Bank Creation
        bank_data = PartnerCreate(
            partner_name="National Bank of Egypt (NBE)",
            partner_type="Bank",
            swift_code="NBEGEGCX",
            bank_code="NBE-01",
            branch_name="Mohandessin Branch",
            country="Egypt",
        )
        created = self.service.create_partner(bank_data)
        self.assertIsNotNone(created.provider_id)
        self.assertEqual(created.partner_type, "Bank")
        self.assertEqual(created.swift_code, "NBEGEGCX")
        self.assertEqual(created.bank_code, "NBE-01")

        # Duplicate SWIFT prevention
        dup_swift_data = PartnerCreate(
            partner_name="NBE Alternative Branch",
            partner_type="Bank",
            swift_code="nbegegcx",  # lower case test
            country="Egypt",
        )
        with self.assertRaises(Exception) as ctx:
            self.service.create_partner(dup_swift_data)
        self.assertIn("مسجل بالفعل للبنك", str(ctx.exception))

    def test_create_freight_forwarder_with_modes_and_currencies(self):
        # MD-05 Freight Forwarder Registration
        ff_data = PartnerCreate(
            partner_name="Apex Global Freight Logistics Ltd",
            partner_type="Freight Forwarder",
            fiata_id="FIATA-EG-7721",
            shipping_modes="Sea FCL, Sea LCL, Air Freight",
            supported_currencies="USD, EUR, EGP",
            contact_person="Tamer Salem",
            email="pricing@apexfreight.com",
            phone="+20 122 345 6789",
            country="Egypt",
        )
        created = self.service.create_partner(ff_data)
        self.assertIsNotNone(created.provider_id)
        self.assertEqual(created.partner_type, "Freight Forwarder")
        self.assertEqual(created.fiata_id, "FIATA-EG-7721")
        self.assertEqual(created.shipping_modes, "Sea FCL, Sea LCL, Air Freight")
        self.assertEqual(created.supported_currencies, "USD, EUR, EGP")
        self.assertEqual(created.email, "pricing@apexfreight.com")

        # Duplicate FIATA ID prevention
        dup_fiata_data = PartnerCreate(
            partner_name="Apex Regional Logistics Branch",
            partner_type="Freight Forwarder",
            fiata_id="fiata-eg-7721",  # case-insensitive test
            country="Egypt",
        )
        with self.assertRaises(Exception) as ctx:
            self.service.create_partner(dup_fiata_data)
        self.assertIn("مسجل بالفعل لوكيل الشحن", str(ctx.exception))

    def test_create_inspection_agency_with_accreditation_and_scope(self):
        # MD-06 Inspection Agency Registration
        insp_data = PartnerCreate(
            partner_name="SGS Egypt - International Inspection Services",
            partner_type="Inspection Agency",
            inspection_accreditation_number="GOIEC-EG-9001",
            inspection_scope="Pre-shipment Inspection, CoC/VOC Conformity Assessment",
            contact_person="Eng. Karim Adel",
            email="karim.adel@sgs.com",
            phone="+20 2 2770 1200",
            country="Egypt",
        )
        created = self.service.create_partner(insp_data)
        self.assertIsNotNone(created.provider_id)
        self.assertEqual(created.partner_type, "Inspection Agency")
        self.assertEqual(created.inspection_accreditation_number, "GOIEC-EG-9001")
        self.assertEqual(created.inspection_scope, "Pre-shipment Inspection, CoC/VOC Conformity Assessment")
        self.assertEqual(created.contact_person, "Eng. Karim Adel")

        # Duplicate accreditation number prevention
        dup_insp_data = PartnerCreate(
            partner_name="SGS Alexandria Testing Labs",
            partner_type="Inspection Agency",
            inspection_accreditation_number="goiec-eg-9001",  # case-insensitive test
            country="Egypt",
        )
        with self.assertRaises(Exception) as ctx:
            self.service.create_partner(dup_insp_data)
        self.assertIn("مسجل بالفعل لشركة الفحص", str(ctx.exception))

    def test_create_customs_broker_with_license_and_ports(self):
        # MD-07 Customs Broker Registration
        broker_data = PartnerCreate(
            partner_name="Pharaohs Logistics & Customs Clearance Services",
            partner_type="Customs Broker",
            clearance_license_number="LIC-ALX-8899",
            authorized_ports="Alexandria Port, Ain Sokhna, Port Said West, Cairo Cargo Terminal",
            contact_person="Moustafa El-Nagar",
            email="moustafa@pharaohsclearance.com",
            phone="+20 3 487 1122",
            country="Egypt",
        )
        created = self.service.create_partner(broker_data)
        self.assertIsNotNone(created.provider_id)
        self.assertEqual(created.partner_type, "Customs Broker")
        self.assertEqual(created.clearance_license_number, "LIC-ALX-8899")
        self.assertEqual(created.authorized_ports, "Alexandria Port, Ain Sokhna, Port Said West, Cairo Cargo Terminal")
        self.assertEqual(created.contact_person, "Moustafa El-Nagar")

        # Duplicate clearance license number prevention
        dup_broker_data = PartnerCreate(
            partner_name="Pharaohs Clearance Cairo Branch",
            partner_type="Customs Broker",
            clearance_license_number="lic-alx-8899",  # case-insensitive check
            country="Egypt",
        )
        with self.assertRaises(Exception) as ctx:
            self.service.create_partner(dup_broker_data)
        self.assertIn("مسجل بالفعل للمخلص الجمركي", str(ctx.exception))

    def test_create_inland_transport_partner(self):
        # MD-08 Inland Transport Registration
        transport_data = PartnerCreate(
            partner_name="Al-Ahram Heavy Transport & Logistics",
            partner_type="Inland Transport",
            transport_license_number="MOT-EG-7744",
            fleet_types="20/40ft Container Chassis, Lowbed, Reefer, Flatbed Jumbo",
            coverage_areas="Alexandria Port, Ain Sokhna Port, Damietta, Greater Cairo, 10th of Ramadan",
            contact_person="Eng. Ahmed El-Banna",
            email="dispatch@alahram-transport.com",
            phone="+20 12 8844 5511",
            country="Egypt",
        )
        created = self.service.create_partner(transport_data)
        self.assertIsNotNone(created.provider_id)
        self.assertEqual(created.partner_type, "Inland Transport")
        self.assertEqual(created.transport_license_number, "MOT-EG-7744")
        self.assertEqual(created.fleet_types, "20/40ft Container Chassis, Lowbed, Reefer, Flatbed Jumbo")
        self.assertEqual(created.coverage_areas, "Alexandria Port, Ain Sokhna Port, Damietta, Greater Cairo, 10th of Ramadan")

        # Duplicate transport license prevention
        dup_transport_data = PartnerCreate(
            partner_name="Al-Ahram Transport Branch 2",
            partner_type="Inland Transport",
            transport_license_number="mot-eg-7744",  # case-insensitive check
            country="Egypt",
        )
        with self.assertRaises(Exception) as ctx:
            self.service.create_partner(dup_transport_data)
        self.assertIn("مسجل بالفعل لشركة النقل", str(ctx.exception))

    def test_create_insurance_company_partner(self):
        # MD-08 Marine Cargo Insurance Registration
        insurance_data = PartnerCreate(
            partner_name="Misr Marine & Cargo Insurance Company",
            partner_type="Insurance Company",
            insurance_license_number="FRA-INS-808",
            insurance_coverage_types="Institute Cargo Clauses (A/B/C), War & Strikes, All Risks",
            contact_person="Dr. Tarek Hegazy",
            email="marine.claims@misrinsure.eg",
            phone="+20 2 3344 5566",
            country="Egypt",
        )
        created = self.service.create_partner(insurance_data)
        self.assertIsNotNone(created.provider_id)
        self.assertEqual(created.partner_type, "Insurance Company")
        self.assertEqual(created.insurance_license_number, "FRA-INS-808")
        self.assertEqual(created.insurance_coverage_types, "Institute Cargo Clauses (A/B/C), War & Strikes, All Risks")

        # Duplicate insurance license prevention
        dup_ins_data = PartnerCreate(
            partner_name="Misr Marine Brokerage Agency",
            partner_type="Insurance Company",
            insurance_license_number="fra-ins-808",  # case-insensitive check
            country="Egypt",
        )
        with self.assertRaises(Exception) as ctx:
            self.service.create_partner(dup_ins_data)
        self.assertIn("مسجل بالفعل لشركة التأمين", str(ctx.exception))


if __name__ == "__main__":
    unittest.main()
