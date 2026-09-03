import pytest
from datetime import date, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

import main
from database.database import Base, get_db
from datetime import datetime, timezone
from modules.suppliers.model import Supplier
from modules.import_companies.model import ImportCompany
from modules.projects.model import Project
from modules.incoterms.model import Incoterm
from modules.currencies.model import Currency
from modules.import_files.model import ImportFile
from modules.purchase_orders.model import PurchaseOrder, POLineItem
from modules.freight_booking.model import ShipmentBooking
from modules.customs_clearance.model import CustomsClearanceRecord
from modules.route_intelligence.schemas import RouteOperationalNoteCreate
from modules.route_intelligence.service import (
    get_supplier_route_intelligence_service,
    add_route_operational_note_service,
)



SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="function")
def db_session():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def client(db_session):
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    main.app.dependency_overrides[get_db] = override_get_db
    test_client = TestClient(main.app)
    yield test_client
    main.app.dependency_overrides.clear()


class TestRouteAndSupplierIntelligence:
    """
    Tests for AI-ROUTE-006: Route & Supplier Intelligence Card.
    """

    def test_supplier_route_intelligence_flow(self, db_session):
        # 1. Master Data
        company = ImportCompany(
            importer_name="El-Sorour Co",
            country="Egypt",
            address="Cairo",
            importer_id="IMP-001",
            importer_id_expiry=date(2030, 1, 1),
            vat_id="100200300",
            vat_id_expiry=date(2030, 1, 1),
            registration_number="REG-001",
            registration_expiry=date(2030, 1, 1),
        )
        db_session.add(company)

        supplier = Supplier(
            company_name="Ningbo Smart Tools Ltd",
            supplier_code="SUP-NB-001",
            supplier_type="Manufacturer",
            registration_type="Commercial Registration",
            foreign_exporter_id="CN-998877",
            foreign_exporter_country="China",
            foreign_exporter_country_code="CN",
            address="Ningbo Industrial Zone, China",
        )
        db_session.add(supplier)

        incoterm = Incoterm(incoterm_code="FOB", incoterm_name="Free On Board")
        db_session.add(incoterm)

        currency = Currency(currency_code="USD", currency_name="US Dollar", currency_symbol="$")
        db_session.add(currency)

        db_session.commit()
        db_session.refresh(company)
        db_session.refresh(supplier)
        db_session.refresh(incoterm)
        db_session.refresh(currency)

        project = Project(
            project_name="Expansion Proj",
            project_code="PRJ-01",
            project_owner="Ahmed Sorour",
            company_id=company.company_id,
            supplier_id=supplier.supplier_id,
            incoterm_id=incoterm.incoterm_id,
        )
        db_session.add(project)
        db_session.commit()
        db_session.refresh(project)



        # 2. Add PO with items
        po = PurchaseOrder(
            po_number="PO-2026-9901",
            project_id=project.project_id,
            company_id=company.company_id,
            supplier_id=supplier.supplier_id,
            incoterm_id=incoterm.incoterm_id,
            currency_id=currency.currency_id,
            order_date=datetime.now(timezone.utc) - timedelta(days=40),
            total_amount_fob=50000.0,
        )
        db_session.add(po)
        db_session.commit()
        db_session.refresh(po)

        item = POLineItem(
            po_id=po.po_id,
            item_code="TOOL-CUTTER-01",
            description_ar="قاطع ليزر صناعي",
            quantity=10,
            unit_price=5000.0,
            total_price=50000.0,
        )
        db_session.add(item)
        db_session.commit()

        # 3. Add Import File
        import_file = ImportFile(
            import_file_code="IMP-2026-9901",
            company_id=company.company_id,
            company_name=company.importer_name,
            supplier_id=supplier.supplier_id,
            supplier_name=supplier.company_name,
            port_of_loading="Ningbo Port",
            port_of_discharge="Alexandria Port",
            broker_name="مكتب الحاج كمال للتخليص",
        )
        db_session.add(import_file)
        db_session.commit()
        db_session.refresh(import_file)


        # 4. Add Freight Booking
        booking = ShipmentBooking(
            booking_code="BKG-9901",
            import_file_id=import_file.import_file_id,
            shipping_line_name="CMA CGM",
            freight_forwarder_name="Panalpina Egypt",
            total_freight_cost_usd=3200.0,
            free_demurrage_days=21,
        )
        db_session.add(booking)
        db_session.commit()


        # 5. Add Customs Clearance Record
        clearance = CustomsClearanceRecord(
            clearance_code="CLR-9901",
            import_file_id=import_file.import_file_id,
            declaration_46_no="DEC-46-9901",
            inspection_date=datetime.now(timezone.utc) - timedelta(days=10),
            release_date=datetime.now(timezone.utc) - timedelta(days=6),
            import_duty_amount=65000.0,
            vat_amount=95000.0,
            total_duty_payable=160000.0,
        )
        db_session.add(clearance)
        db_session.commit()


        # 6. Add Operational Note
        add_route_operational_note_service(
            db_session,
            RouteOperationalNoteCreate(
                supplier_id=supplier.supplier_id,
                route_name="Ningbo to Alexandria",
                note_category="Documentation",
                note_text="المورد يحتاج تذكير مسبق بإرسال أصول شهادة المنشأ قبل الإبحار بـ 3 أيام.",
            ),
        )

        # 7. Generate Intelligence Card
        intel = get_supplier_route_intelligence_service(db_session, supplier.supplier_id)
        assert intel.supplier_id == supplier.supplier_id
        assert intel.company_name == "Ningbo Smart Tools Ltd"
        assert len(intel.items_price_history) == 1
        assert intel.items_price_history[0].item_code == "TOOL-CUTTER-01"
        assert intel.items_price_history[0].last_unit_price == 5000.0

        # Verify Shipping Memory
        assert intel.shipping_memory.last_ocean_freight_cost == 3200.0
        assert intel.shipping_memory.last_shipping_line == "CMA CGM"
        assert intel.shipping_memory.last_freight_forwarder == "Panalpina Egypt"
        assert intel.shipping_memory.last_pol == "Ningbo Port"
        assert intel.shipping_memory.last_pod == "Alexandria Port"
        assert intel.shipping_memory.last_free_days_granted == 21

        # Verify Customs Memory
        assert intel.customs_memory.last_duty_payable_egp == 65000.0
        assert intel.customs_memory.last_vat_payable_egp == 95000.0
        assert intel.customs_memory.last_clearance_days == 4

        # Verify Notes and Advisory
        assert len(intel.operational_notes) == 1
        assert "أصول شهادة المنشأ" in intel.operational_notes[0].note_text
        assert "تقرير استشاري ذكي" in intel.advisory_recommendation_ar
        assert "Ningbo Smart Tools Ltd" in intel.advisory_recommendation_ar

    def test_api_route_intelligence(self, client, db_session):
        # Create Supplier
        supplier = Supplier(
            company_name="Milan Leather SpA",
            supplier_code="SUP-MIL-002",
            supplier_type="Manufacturer",
            registration_type="Commercial Registration",
            foreign_exporter_id="IT-443322",
            foreign_exporter_country="Italy",
            foreign_exporter_country_code="IT",
            address="Via Roma 12, Milan, Italy",
        )
        db_session.add(supplier)
        db_session.commit()

        db_session.refresh(supplier)


        # 1. Post Note via API
        note_resp = client.post(
            "/api/v1/route-intelligence/notes",
            json={
                "supplier_id": supplier.supplier_id,
                "note_category": "Inspection",
                "note_text": "فحص معملي إلزامي للجلود الطبيعية لدى هيئة الرقابة.",
            },
        )
        assert note_resp.status_code == 201
        assert note_resp.json()["note_category"] == "Inspection"

        # 2. Get Intelligence Card via API
        get_resp = client.get(f"/api/v1/route-intelligence/supplier/{supplier.supplier_id}")
        assert get_resp.status_code == 200
        data = get_resp.json()
        assert data["company_name"] == "Milan Leather SpA"
        assert len(data["operational_notes"]) == 1
        assert "فحص معملي" in data["operational_notes"][0]["note_text"]

