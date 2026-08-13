import unittest
from datetime import datetime
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.incoterms.model import Incoterm
from modules.projects.model import Project
from modules.currencies.model import Currency
from modules.customs_tariff.model import CustomsTariff
from modules.external_service_providers.model import ExternalServiceProvider
from modules.transport_locations.model import TransportLocation
from modules.freight_quotations.model import FreightRFQRequest
from modules.purchase_orders.model import PurchaseOrder
from modules.freight_booking.model import ShipmentBooking
from modules.import_files.model import ImportFile
from modules.cargo_shipping.model import CargoShippingRecord
from modules.cargo_shipping.schemas import (
    CargoShippingCreate,
    CargoShippingUpdate,
    DualApprovalLevel1Submit,
    DualApprovalLevel2Submit,
    ContainerLoadingItem,
    CourierTrackingItem,
    CargoXExchangeItem,
)
from modules.cargo_shipping.service import (
    create_cargo_shipping_service,
    get_cargo_shipping_service,
    list_cargo_shippings_service,
    submit_level1_approval_service,
    submit_level2_approval_service,
    execute_cargox_checklist_service,
    advance_cargox_stage_service,
    soft_delete_cargo_shipping_service,
)
from modules.cargo_shipping.validators import (
    validate_crd_against_cutoff,
    validate_dual_approval_sequence,
    validate_cargox_ready_for_upload,
)
from fastapi import HTTPException

class TestCargoShippingModule(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(self.engine)
        TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        self.db = TestingSessionLocal()

        # Seed import company & import file
        from datetime import date
        company = ImportCompany(
            company_id=1,
            importer_name="Alpha Import Ltd",
            vat_id="100-200-300",
            registration_number="12345",
            address="Cairo, Egypt",
            country="Egypt",
            importer_id="IMP-001",
            importer_id_expiry=date(2028, 1, 1),
            vat_id_expiry=date(2028, 1, 1),
            registration_expiry=date(2028, 1, 1),
        )
        self.db.add(company)
        self.db.commit()
        self.db.refresh(company)

        imp_file = ImportFile(
            import_file_code="IMP-FILE-2026-0001",
            company_id=company.company_id,
            company_name=company.importer_name,
            supplier_name="Global Supplier Inc",
            po_number="PO-2026-88",
        )
        self.db.add(imp_file)
        self.db.commit()
        self.db.refresh(imp_file)
        self.import_file_id = imp_file.import_file_id

    def tearDown(self):
        self.db.close()

    def test_crd_validator(self):
        crd = datetime(2026, 8, 15)
        cutoff = datetime(2026, 8, 20)
        self.assertTrue(validate_crd_against_cutoff(crd, cutoff))

        late_crd = datetime(2026, 8, 25)
        self.assertFalse(validate_crd_against_cutoff(late_crd, cutoff))

    def test_create_cargo_shipping(self):
        schema = CargoShippingCreate(
            import_file_id=self.import_file_id,
            crd_date=datetime(2026, 8, 10),
            cargo_cutoff_date=datetime(2026, 8, 15),
            containers_loading_data=[
                ContainerLoadingItem(
                    container_no="MSKU9988776",
                    seal_no="SL-9001",
                    tare_weight_kg=2200.0,
                    net_weight_kg=18500.0,
                    gross_weight_kg=20700.0,
                    vgm_status="Submitted",
                    vgm_ref_no="VGM-REF-100",
                )
            ],
            courier_tracking_data=CourierTrackingItem(
                courier_provider="DHL Express",
                tracking_number="DHL-992211",
                receipt_status="Dispatched",
            ),
            cargox_exchange_data=CargoXExchangeItem(
                platform_provider="CargoX Platform",
                envelope_status="Created",
            ),
        )

        record = create_cargo_shipping_service(self.db, schema)
        self.assertIsNotNone(record.cargo_shipping_id)
        self.assertTrue(record.cargo_shipping_code.startswith("SHP-"))
        self.assertEqual(len(record.containers_loading_data), 1)
        self.assertEqual(record.containers_loading_data[0]["container_no"], "MSKU9988776")
        self.assertTrue(record.is_crd_validated)

    def test_dual_approval_workflow(self):
        schema = CargoShippingCreate(import_file_id=self.import_file_id)
        record = create_cargo_shipping_service(self.db, schema)

        # Level 1 Approval
        l1_payload = DualApprovalLevel1Submit(approved_by="Operational Manager Kamal", approved=True, notes="Verified containers and ACID")
        record = submit_level1_approval_service(self.db, record.cargo_shipping_id, l1_payload)
        self.assertEqual(record.level1_approval_status, "Approved")
        self.assertEqual(record.dual_approval_status, "In Progress")

        # Level 2 Approval
        l2_payload = DualApprovalLevel2Submit(approved_by="Customs Director Ahmed", approved=True, notes="Verified legal documents")
        record = submit_level2_approval_service(self.db, record.cargo_shipping_id, l2_payload)
        self.assertEqual(record.level2_approval_status, "Approved")
        self.assertEqual(record.dual_approval_status, "Dual Approved")

    def test_cargox_checklist_and_stage_advance(self):
        schema = CargoShippingCreate(
            import_file_id=self.import_file_id,
            containers_loading_data=[
                ContainerLoadingItem(container_no="COSU1234567", seal_no="SL-100")
            ]
        )
        record = create_cargo_shipping_service(self.db, schema)

        # Run Level 1 and Level 2 approvals
        submit_level1_approval_service(self.db, record.cargo_shipping_id, DualApprovalLevel1Submit(approved_by="Op User", approved=True))
        submit_level2_approval_service(self.db, record.cargo_shipping_id, DualApprovalLevel2Submit(approved_by="Mgr User", approved=True))

        # Run CargoX verification checklist
        record = execute_cargox_checklist_service(self.db, record.cargo_shipping_id)
        self.assertEqual(record.cargox_exchange_data["envelope_status"], "Checklist Passed")

        # Advance to Ready for Upload
        record = advance_cargox_stage_service(self.db, record.cargo_shipping_id, "Ready for Upload")
        self.assertEqual(record.cargox_exchange_data["envelope_status"], "Ready for Upload")

        # Advance to Uploaded
        record = advance_cargox_stage_service(self.db, record.cargo_shipping_id, "Uploaded")
        self.assertEqual(record.cargox_exchange_data["envelope_status"], "Uploaded")
        self.assertIsNotNone(record.cargox_exchange_data["blockchain_tx_hash"])
        self.assertEqual(record.status, "CargoX Transfer Completed")

    def test_soft_delete_and_restore(self):
        schema = CargoShippingCreate(import_file_id=self.import_file_id)
        record = create_cargo_shipping_service(self.db, schema)
        rec_id = record.cargo_shipping_id

        # Delete
        success = soft_delete_cargo_shipping_service(self.db, rec_id)
        self.assertTrue(success)

        # Restore
        from modules.cargo_shipping.service import restore_cargo_shipping_service
        restored = restore_cargo_shipping_service(self.db, rec_id)
        self.assertIsNotNone(restored)
        self.assertEqual(restored.cargo_shipping_id, rec_id)
        self.assertTrue(restored.is_active)

if __name__ == "__main__":
    unittest.main()
