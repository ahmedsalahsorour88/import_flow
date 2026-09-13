"""
Unit Tests for Smart Import Checklist Engine & Gatekeeper Service (modules/smart_checklists)
"""

import unittest
from datetime import datetime, date
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi import HTTPException

import main
from database.database import Base
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.import_files.model import ImportFile
from modules.customs_tariff.model import CustomsTariff
from modules.smart_checklists.model import ImportFileChecklistItem
import modules.smart_checklists.service as service
import modules.smart_checklists.repository as repo


class TestSmartChecklistsModule(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(self.engine)
        TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        self.db = TestingSessionLocal()

        # Seed Company & Supplier
        self.company = ImportCompany(
            company_id=1,
            importer_id="IMP-001",
            importer_name="Sorour Logistics Trading Co",
            vat_id="123-456-789",
            registration_number="98765",
            address="Alexandria, Egypt",
            country="Egypt",
            importer_id_expiry=date(2028, 1, 1),
            vat_id_expiry=date(2028, 1, 1),
            registration_expiry=date(2028, 1, 1),
        )
        self.supplier = Supplier(
            supplier_id=1,
            supplier_code="SUP-2026-001",
            company_name="Siemens AG",
            supplier_type="Manufacturer",
            registration_type="VAT",
            foreign_exporter_id="DE123456789",
            foreign_exporter_country="Germany",
            foreign_exporter_country_code="DE",
            address="Munich, Germany",
            email="export@siemens.de",
            cargox_platform_id="CX-DE-99120",
        )
        self.db.add_all([self.company, self.supplier])
        self.db.commit()

        # Seed Import File
        self.import_file = ImportFile(
            import_file_id=101,
            import_file_code="IMP-2026-0042",
            company_id=self.company.company_id,
            company_name=self.company.importer_name,
            supplier_id=self.supplier.supplier_id,
            supplier_name=self.supplier.company_name,
            incoterm_code="FOB",
            hs_code="853641",
            cargo_ready_date=date(2026, 9, 20),
            status="Open",
        )
        self.db.add(self.import_file)
        self.db.commit()

    def tearDown(self):
        self.db.close()

    def test_seed_checklist_questions(self):
        """Verify that opening checklist seeds master questions across all 5 phases."""
        summary = service.get_checklist_summary(self.db, file_id=101)
        self.assertEqual(summary.import_file_id, 101)
        self.assertGreaterEqual(summary.total_items, 20)
        self.assertTrue(summary.is_gate_blocked)

        phases = {i.phase_code for i in summary.items}
        expected_phases = {"PRE_SHIPMENT", "IN_TRANSIT", "PORT_ARRIVAL", "CLEARANCE", "POST_CLEARANCE"}
        self.assertTrue(expected_phases.issubset(phases))

    def test_auto_sync_database_matching(self):
        """Verify that auto_sync detects incoterm, cargo ready date, and HS code from DB."""
        # Add matching tariff
        tariff = CustomsTariff(
            hs_code="853641",
            hs_description="Electrical Apparatus",
            customs_duty_rate=5.0,
            vat_rate=14.0,
            is_active=True,
        )
        self.db.add(tariff)
        self.db.commit()

        sync_res = service.auto_sync_checklist(self.db, file_id=101)
        self.assertGreater(len(sync_res.newly_passed_codes), 0)
        self.assertIn("CHK_PRE_01", sync_res.newly_passed_codes)  # Incoterm
        self.assertIn("CHK_PRE_03", sync_res.newly_passed_codes)  # Tariff
        self.assertIn("CHK_PRE_08", sync_res.newly_passed_codes)  # Cargo ready date

        # Verify summary reflects passed items
        summary = service.get_checklist_summary(self.db, file_id=101)
        self.assertGreaterEqual(summary.passed_items, 3)
        self.assertGreater(summary.readiness_score_pct, 10)

    def test_manual_toggle_status(self):
        """Verify manual toggle by coordinator/broker."""
        items = repo.seed_checklist_for_file(self.db, file_id=101)
        item = items[0]

        updated = service.toggle_item(
            db=self.db,
            file_id=101,
            item_id=item.item_id,
            new_status="PASSED",
            notes="Manually confirmed with supplier",
            verified_by="Ahmed Kamal",
        )
        self.assertEqual(updated.status, "PASSED")
        self.assertEqual(updated.verified_by, "Ahmed Kamal")
        self.assertIn("Manually confirmed", updated.notes)

    def test_override_mandatory_gatekeeper_item(self):
        """Verify granting conditional waiver / override with mandatory justification."""
        items = repo.seed_checklist_for_file(self.db, file_id=101)
        mandatory_item = next(i for i in items if i.is_mandatory)

        # Empty reason should raise 400
        with self.assertRaises(HTTPException):
            service.override_item(
                db=self.db,
                file_id=101,
                item_id=mandatory_item.item_id,
                reason="",
                authorized_by="General Manager",
            )

        # Valid reason should waive and log audit
        waived = service.override_item(
            db=self.db,
            file_id=101,
            item_id=mandatory_item.item_id,
            reason="Supplier pledged to dispatch EUR.1 original via DHL",
            authorized_by="General Manager",
        )
        self.assertEqual(waived.status, "WAIVED")
        self.assertEqual(waived.override_reason, "Supplier pledged to dispatch EUR.1 original via DHL")

    def test_gatekeeper_phase_transition(self):
        """Verify gatekeeper blocks transition when mandatory questions in preceding phase are pending."""
        items = repo.seed_checklist_for_file(self.db, file_id=101)

        # Initially, pre-shipment mandatory items are pending -> transition to IN_TRANSIT blocked
        gate = service.check_gatekeeper(self.db, file_id=101, target_phase="IN_TRANSIT")
        self.assertFalse(gate.can_advance)
        self.assertGreater(gate.blocking_count, 0)

        # Waive or pass all pre-shipment mandatory items
        for itm in items:
            if itm.phase_code == "PRE_SHIPMENT" and itm.is_mandatory:
                repo.update_item_status(self.db, itm.item_id, status="PASSED", verified_by="Test")

        # Now transition to IN_TRANSIT must be clear
        gate_clear = service.check_gatekeeper(self.db, file_id=101, target_phase="IN_TRANSIT")
        self.assertTrue(gate_clear.can_advance)
        self.assertEqual(gate_clear.blocking_count, 0)
