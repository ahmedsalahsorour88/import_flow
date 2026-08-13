from datetime import datetime, date, timezone
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.freight_booking.schemas import (
    ShipmentBookingCreate,
    ShipmentBookingUpdate,
    ContainerAllocationItem,
    BookingChargeItem,
)
from modules.freight_booking.service import (
    create_booking_service,
    get_booking_service,
    list_bookings_service,
    update_booking_service,
    soft_delete_booking_service,
    restore_booking_service,
)
from modules.customs_tariff.model import CustomsTariff
from modules.currencies.model import Currency
from modules.purchase_orders.model import PurchaseOrder
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.external_service_providers.model import ExternalServiceProvider
from modules.transport_locations.model import TransportLocation
from modules.freight_quotations.model import FreightRFQRequest
from modules.incoterms.model import Incoterm
from modules.projects.model import Project
from modules.import_files.model import ImportFile


@pytest.fixture
def db_session():
    """Creates in-memory SQLite DB fixture."""
    engine = create_engine("sqlite:///:memory:", echo=False)
    Base.metadata.create_all(engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = TestingSessionLocal()

    comp1 = ImportCompany(company_id=1, importer_name="Egyptian Import Co", vat_id="100-200-300", registration_number="12345", address="Cairo", country="Egypt", importer_id="IMP-001", importer_id_expiry=date(2028,1,1), vat_id_expiry=date(2028,1,1), registration_expiry=date(2028,1,1))
    sup1 = Supplier(supplier_id=1, company_name="ABC China", supplier_code="SUP-01", supplier_type="Manufacturer", registration_type="Foreign Exporter", foreign_exporter_id="CN-99", foreign_exporter_country="China", foreign_exporter_country_code="CN", address="Shanghai")
    inco1 = Incoterm(incoterm_id=1, incoterm_code="FOB", incoterm_name="Free On Board", description="Seller delivers goods on board vessel")
    proj1 = Project(project_id=1, project_code="PRJ-01", project_name="Textile Expansion", project_owner="Kamal", company_id=1, supplier_id=1, incoterm_id=1, import_type="Direct Commercial")
    file1 = ImportFile(import_file_id=1, import_file_code="IMP-2026-0001", custom_file_number="6701068100", company_name="Egyptian Import Co", supplier_name="ABC China", owner="Kamal")
    
    db.add_all([comp1, sup1, inco1, proj1, file1])
    db.commit()

    try:
        yield db
    finally:
        db.close()


class TestFreightBookingBackend:

    def test_create_shipment_booking_success(self, db_session):
        payload = ShipmentBookingCreate(
            import_file_id=1,
            booking_confirmation_no="MSC-CN-9900",
            freight_forwarder_name="El-Ahram Logistics",
            shipping_line_name="MSC",
            shipment_type="Ocean FCL",
            pol_name="Shanghai Port",
            pod_name="Alexandria Port",
            etd=datetime(2026, 8, 10, 10, 0, tzinfo=timezone.utc),
            eta=datetime(2026, 8, 25, 10, 0, tzinfo=timezone.utc),
            free_demurrage_days=14,
            containers_data=[
                ContainerAllocationItem(container_type="40HC", quantity=2, container_numbers=["MSCU11", "MSCU22"])
            ],
            cost_charges_data=[
                BookingChargeItem(charge_type="Sea Freight", unit="Per Container", quantity=1, rate=2000.0),
                BookingChargeItem(charge_type="BL Fee", unit="Per Shipment", quantity=1, rate=100.0)
            ],
            status="Draft",
            owner="Kamal",
        )

        booking = create_booking_service(db_session, payload)
        assert booking.booking_id is not None
        assert booking.booking_code.startswith("BKG-2026-")
        assert booking.transit_time_days == 15
        # 2 containers * 2000 + 1 * 100 = 4100
        assert booking.total_freight_cost_usd == 4100.0

    def test_transit_time_and_costs_calculation(self, db_session):
        payload = ShipmentBookingCreate(
            shipment_type="Ocean FCL",
            etd=datetime(2026, 9, 1, 0, 0, tzinfo=timezone.utc),
            eta=datetime(2026, 9, 21, 0, 0, tzinfo=timezone.utc),
            containers_data=[
                ContainerAllocationItem(container_type="20GP", quantity=3)
            ],
            cost_charges_data=[
                BookingChargeItem(charge_type="Sea Freight", unit="Per Container", quantity=1, rate=1500.0),
                BookingChargeItem(charge_type="THC", unit="Per Container", quantity=1, rate=300.0)
            ],
        )

        booking = create_booking_service(db_session, payload)
        assert booking.transit_time_days == 20
        # (1500 * 3) + (300 * 3) = 5400
        assert booking.total_freight_cost_usd == 5400.0

    def test_update_booking_status_and_vessel(self, db_session):
        payload = ShipmentBookingCreate(
            shipment_type="Ocean FCL",
            containers_data=[ContainerAllocationItem(container_type="40HC", quantity=1)],
            status="Draft"
        )
        booking = create_booking_service(db_session, payload)

        update_payload = ShipmentBookingUpdate(
            vessel_name="MSC Oscar",
            voyage_number="VY-99",
            status="Confirmed"
        )
        updated = update_booking_service(db_session, booking.booking_id, update_payload)
        assert updated.vessel_name == "MSC Oscar"
        assert updated.status == "Confirmed"

    def test_soft_delete_booking(self, db_session):
        payload = ShipmentBookingCreate(
            shipment_type="Ocean FCL",
            containers_data=[ContainerAllocationItem(container_type="40HC", quantity=1)]
        )
        booking = create_booking_service(db_session, payload)
        b_id = booking.booking_id

        success = soft_delete_booking_service(db_session, b_id)
        assert success is True

        fetched = get_booking_service(db_session, b_id)
        assert fetched is None

        # Restore
        restored = restore_booking_service(db_session, b_id)
        assert restored is not None
        assert restored.booking_id == b_id
        assert restored.is_active is True
