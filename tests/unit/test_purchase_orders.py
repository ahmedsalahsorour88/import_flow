from decimal import Decimal
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.currencies.model import Currency
from modules.customs_tariff.model import CustomsTariff
from modules.customs_tariff.schemas import CustomsTariffCreate
from modules.customs_tariff.service import create_tariff_service
from modules.import_companies.model import ImportCompany
from modules.incoterms.model import Incoterm
from modules.projects.model import Project
from modules.purchase_orders.schemas import POLineItemCreate, PurchaseOrderCreate, PurchaseOrderUpdate
from modules.purchase_orders.service import PurchaseOrderService
from modules.suppliers.model import Supplier


from datetime import date, timedelta
from modules.import_companies.schemas import ImportCompanyCreate
from modules.import_companies.service import create_import_company

@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = TestingSessionLocal()

    # Seed prerequisites
    company_data = ImportCompanyCreate(
        importer_name="Test Importer",
        address="Cairo",
        country="Egypt",
        importer_id="IMP-100200",
        importer_id_expiry=date.today() + timedelta(days=120),
        vat_id="VAT-998877",
        vat_id_expiry=date.today() + timedelta(days=90),
        registration_number="REG-554433",
        registration_expiry=date.today() + timedelta(days=60),
    )
    company = create_import_company(session, company_data)
    supplier = Supplier(
        supplier_code="SUP-001",
        company_name="Test Supplier",
        supplier_type="Manufacturer",
        registration_type="CargoX",
        foreign_exporter_id="EXP-123",
        foreign_exporter_country="Germany",
        foreign_exporter_country_code="DE",
        address="Berlin",
        is_active=True,
    )
    incoterm = Incoterm(incoterm_code="FOB", incoterm_name="Free On Board", is_active=True)
    currency = Currency(currency_code="USD", currency_name="US Dollar", currency_symbol="$", is_active=True)

    session.add_all([company, supplier, incoterm, currency])
    session.commit()

    project = Project(
        project_code="PRJ-2026-001",
        project_name="Test Project",
        project_owner="Eng. Test",
        company_id=company.company_id,
        supplier_id=supplier.supplier_id,
        incoterm_id=incoterm.incoterm_id,
        is_active=True,
    )
    session.add(project)
    session.commit()

    tariff_data = CustomsTariffCreate(
        hs_code="85414000",
        hs_description="Solar Panels",
        customs_duty_rate=Decimal("5.00"),
        vat_rate=Decimal("14.00"),
    )
    tariff = create_tariff_service(session, tariff_data)

    yield session
    session.close()


class TestPurchaseOrdersBackend:

    def test_create_purchase_order_with_line_items(self, db_session):
        service = PurchaseOrderService(db_session)
        comp = db_session.query(ImportCompany).first()
        supp = db_session.query(Supplier).first()
        inco = db_session.query(Incoterm).first()
        curr = db_session.query(Currency).first()
        proj = db_session.query(Project).first()
        tariff = db_session.query(CustomsTariff).first()

        item1 = POLineItemCreate(
            item_code="SOLAR-550",
            description_ar="ألواح شمسية 550 واط",
            description_en="Solar Panel 550W",
            tariff_id=tariff.tariff_id,
            quantity=100.0,
            unit_of_measure="PCS",
            unit_price=200.00,
            cbm_per_unit=0.2,
            gross_weight_kg=5000.0,
            net_weight_kg=4800.0,
        )

        create_data = PurchaseOrderCreate(
            proforma_invoice_number="PI-99001",
            project_id=proj.project_id,
            company_id=comp.company_id,
            supplier_id=supp.supplier_id,
            incoterm_id=inco.incoterm_id,
            currency_id=curr.currency_id,
            exchange_rate=50.0,
            payment_terms="LC at Sight",
            items=[item1],
        )

        po_resp = service.create(create_data)

        assert po_resp.po_id is not None
        assert po_resp.po_number.startswith("PO-")
        assert po_resp.total_amount_fob == 20000.00  # 100 * 200
        assert po_resp.total_cbm == 20.0  # 100 * 0.2
        assert po_resp.total_gross_weight_kg == 5000.0
        assert len(po_resp.items) == 1
        assert po_resp.items[0].hs_code == "85414000"

    def test_update_and_soft_delete_purchase_order(self, db_session):
        service = PurchaseOrderService(db_session)
        comp = db_session.query(ImportCompany).first()
        supp = db_session.query(Supplier).first()
        inco = db_session.query(Incoterm).first()
        curr = db_session.query(Currency).first()
        proj = db_session.query(Project).first()

        po_resp = service.create(
            PurchaseOrderCreate(
                project_id=proj.project_id,
                company_id=comp.company_id,
                supplier_id=supp.supplier_id,
                incoterm_id=inco.incoterm_id,
                currency_id=curr.currency_id,
                items=[],
            )
        )

        updated = service.update(po_resp.po_id, PurchaseOrderUpdate(status="Approved", notes="Approved for shipment"))
        assert updated.status == "Approved"
        assert updated.notes == "Approved for shipment"

        deleted = service.soft_delete(po_resp.po_id)
        assert deleted.is_active is False

        restored = service.restore(po_resp.po_id)
        assert restored.is_active is True
