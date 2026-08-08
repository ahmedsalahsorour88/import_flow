import pytest
from datetime import datetime, timedelta, timezone
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.external_service_providers.model import ExternalServiceProvider
from modules.transport_locations.model import TransportLocation
from modules.currencies.model import Currency
from modules.customs_tariff.model import CustomsTariff
from modules.purchase_orders.model import PurchaseOrder
from modules.incoterms.model import Incoterm
from modules.projects.model import Project
from modules.import_files.model import ImportFile
from modules.freight_quotations.model import FreightRFQRequest
from modules.freight_booking.model import ShipmentBooking
from modules.cargo_shipping.model import CargoShippingRecord
from modules.cargo_shipping.schemas import (
    CargoShippingCreate,
    CargoShippingUpdate,
    ContainerLoadingItem,
    CourierTrackingItem,
    CargoXExchangeItem,
    DualApprovalLevel1Submit,
    DualApprovalLevel2Submit,
)
from modules.cargo_shipping.service import (
    create_cargo_shipping_service,
    get_cargo_shipping_service,
    list_cargo_shippings_service,
    submit_level1_approval_service,
    submit_level2_approval_service,
    execute_cargox_checklist_service,
    advance_cargox_stage_service,
    update_cargo_shipping_service,
    soft_delete_cargo_shipping_service,
)
from fastapi import HTTPException

@pytest.fixture
def db_session():
    """Creates in-memory SQLite DB fixture."""
    engine = create_engine("sqlite:///:memory:", echo=False)
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()

    today = datetime.now(timezone.utc).date()
    company = ImportCompany(
        importer_name="El-Nasr Import Co.",
        address="Cairo",
        country="Egypt",
        importer_id="EMP-001",
        importer_id_expiry=today + timedelta(days=365),
        vat_id="VAT-001",
        vat_id_expiry=today + timedelta(days=365),
        registration_number="REG-001",
        registration_expiry=today + timedelta(days=365),
    )
    supplier = Supplier(
        supplier_code="SUP-0001",
        company_name="China Industrial Corp",
        supplier_type="Manufacturer",
        registration_type="Factory",
        foreign_exporter_id="FEX-001",
        foreign_exporter_country="China",
        foreign_exporter_country_code="CHN",
        address="Shanghai, China",
    )
    file_record = ImportFile(import_file_code="IMP-2026-0001", company_id=1, company_name="El-Nasr Import Co.", supplier_id=1, supplier_name="China Industrial Corp")
    session.add_all([company, supplier, file_record])
    session.commit()

    yield session
    session.close()


class TestCargoShippingBackend:

    def test_create_cargo_shipping_success(self, db_session):
        crd = datetime.now(timezone.utc) + timedelta(days=2)
        cutoff = datetime.now(timezone.utc) + timedelta(days=5)

        schema = CargoShippingCreate(
            import_file_id=1,
            crd_date=crd,
            cargo_cutoff_date=cutoff,
            containers_loading_data=[
                ContainerLoadingItem(
                    container_no="MSCU1234567",
                    seal_no="SL-99001",
                    tare_weight_kg=3800.0,
                    net_weight_kg=20700.0,
                    gross_weight_kg=24500.0,
                )
            ],
            status="Cargo Ready",
            owner="Kamal",
        )

        record = create_cargo_shipping_service(db_session, schema)

        assert record.cargo_shipping_id is not None
        assert record.cargo_shipping_code.startswith("SHP-2026-")
        assert record.is_crd_validated is True
        assert len(record.containers_loading_data) == 1
        assert record.containers_loading_data[0]["container_no"] == "MSCU1234567"

    def test_crd_exceeds_cutoff_validation(self, db_session):
        crd = datetime.now(timezone.utc) + timedelta(days=10)
        cutoff = datetime.now(timezone.utc) + timedelta(days=5)

        schema = CargoShippingCreate(
            import_file_id=1,
            crd_date=crd,
            cargo_cutoff_date=cutoff,
        )

        record = create_cargo_shipping_service(db_session, schema)
        assert record.is_crd_validated is False

    def test_dual_approval_workflow(self, db_session):
        schema = CargoShippingCreate(import_file_id=1, status="Cargo Ready")
        record = create_cargo_shipping_service(db_session, schema)

        # Level 2 approval should fail before Level 1 approval
        with pytest.raises(HTTPException) as exc_info:
            submit_level2_approval_service(
                db_session,
                record.cargo_shipping_id,
                DualApprovalLevel2Submit(approved_by="Manager", approved=True, notes="Premature Level 2"),
            )
        assert exc_info.value.status_code == 400

        # Submit Level 1 Approval
        lvl1 = submit_level1_approval_service(
            db_session,
            record.cargo_shipping_id,
            DualApprovalLevel1Submit(approved_by="Inspector", approved=True, notes="Tech Passed"),
        )
        assert lvl1.level1_approval_status == "Approved"
        assert lvl1.dual_approval_status == "In Progress"

        # Submit Level 2 Approval
        lvl2 = submit_level2_approval_service(
            db_session,
            record.cargo_shipping_id,
            DualApprovalLevel2Submit(approved_by="Manager", approved=True, notes="Final Approved"),
        )
        assert lvl2.level2_approval_status == "Approved"
        assert lvl2.dual_approval_status == "Dual Approved"
        assert lvl2.status == "Dual Approved"

    def test_cargox_checklist_and_stage_advance(self, db_session):
        schema = CargoShippingCreate(
            import_file_id=1,
            containers_loading_data=[
                ContainerLoadingItem(container_no="MSCU1234567", seal_no="SL-99001")
            ]
        )
        record = create_cargo_shipping_service(db_session, schema)
        submit_level1_approval_service(db_session, record.cargo_shipping_id, DualApprovalLevel1Submit(approved_by="Inspector", approved=True))
        submit_level2_approval_service(db_session, record.cargo_shipping_id, DualApprovalLevel2Submit(approved_by="Manager", approved=True))

        # Run Checklist
        checked = execute_cargox_checklist_service(db_session, record.cargo_shipping_id)
        assert checked.cargox_exchange_data["envelope_status"] == "Checklist Passed"

        # Advance Stage to Uploaded
        uploaded = advance_cargox_stage_service(db_session, record.cargo_shipping_id, "Uploaded")
        assert uploaded.cargox_exchange_data["envelope_status"] == "Uploaded"
        assert uploaded.cargox_exchange_data["blockchain_tx_hash"].startswith("0xBC7789A99")
        assert uploaded.status == "CargoX Transfer Completed"

    def test_soft_delete_cargo_shipping(self, db_session):
        schema = CargoShippingCreate(import_file_id=1)
        record = create_cargo_shipping_service(db_session, schema)
        rec_id = record.cargo_shipping_id

        assert soft_delete_cargo_shipping_service(db_session, rec_id) is True
        assert len(list_cargo_shippings_service(db_session, include_inactive=False)) == 0
        assert len(list_cargo_shippings_service(db_session, include_inactive=True)) == 1
