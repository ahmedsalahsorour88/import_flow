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
            tracking_url="https://www.maersk.com/tracking/",
            country="Denmark",
        )

        created = self.service.create_partner(partner_data)

        self.assertEqual(created.partner_code, "ESP-000001")
        self.assertEqual(created.partner_name, "Maersk Line")
        self.assertEqual(created.scac_code, "MAEU")

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


if __name__ == "__main__":
    unittest.main()
