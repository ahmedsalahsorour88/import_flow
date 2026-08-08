import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.currencies.model import Currency
from modules.customs_tariff.model import CustomsTariff
from modules.import_companies.model import ImportCompany

from modules.incoterms.model import Incoterm
from modules.projects.model import Project
from modules.purchase_orders.schemas import PackingListItemCreate, PurchaseOrderCreate
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

    # Seed required Master Data
    comp = create_import_company(session, ImportCompanyCreate(
        importer_name="Test Company",
        address="Cairo",
        country="Egypt",
        importer_id="IMP-001",
        importer_id_expiry=date.today() + timedelta(days=120),
        vat_id="VAT-001",
        vat_id_expiry=date.today() + timedelta(days=90),
        registration_number="REG-001",
        registration_expiry=date.today() + timedelta(days=60),
    ))

    supp = Supplier(
        supplier_code="SUP-001",
        company_name="Test Supplier",
        supplier_type="Manufacturer",
        registration_type="VAT",
        foreign_exporter_id="F-123",
        foreign_exporter_country="Italy",
        foreign_exporter_country_code="IT",
        address="Rome",
        is_active=True,
    )
    inc = Incoterm(incoterm_code="FOB", incoterm_name="Free On Board", is_active=True)
    curr = Currency(currency_code="USD", currency_name="US Dollar", currency_symbol="$", is_active=True)

    session.add_all([supp, inc, curr])
    session.commit()

    proj = Project(
        project_code="PRJ-001",
        project_name="Test Project",
        project_owner="Eng. Test",
        company_id=comp.company_id,
        supplier_id=supp.supplier_id,
        incoterm_id=inc.incoterm_id,
        is_active=True,
    )

    session.add(proj)
    session.commit()

    yield session
    session.close()



class TestPackingListBackend:

    def test_create_po_with_packing_list(self, db_session):
        service = PurchaseOrderService(db_session)

        packing_items = [
            PackingListItemCreate(
                hs_code="8471.30.00",
                item_code="SOLAR-550W",
                qty_pcs=100.0,
                qty_pkg=10.0,
                package_type="Pallet",
                length_cm=120.0,
                width_cm=100.0,
                height_cm=160.0,
                net_weight_unit_kg=22.0,
                gross_weight_unit_kg=25.0,
            ),
            PackingListItemCreate(
                hs_code="8504.40.90",
                item_code="INVERTER-100KW",
                qty_pcs=5.0,
                qty_pkg=5.0,
                package_type="Wooden Crate",
                length_cm=150.0,
                width_cm=110.0,
                height_cm=90.0,
                net_weight_unit_kg=140.0,
                gross_weight_unit_kg=150.0,
            ),
        ]

        po_create = PurchaseOrderCreate(
            proforma_invoice_number="PI-2026-TEST",
            project_id=1,
            company_id=1,
            supplier_id=1,
            incoterm_id=1,
            currency_id=1,
            packing_list_items=packing_items,
        )

        resp = service.create(po_create)

        assert resp.po_id is not None
        assert len(resp.packing_list_items) == 2

        item1 = resp.packing_list_items[0]
        assert item1.total_net_weight_kg == 2200.0  # 100 * 22
        assert item1.total_gross_weight_kg == 2500.0  # 100 * 25
        assert item1.total_cbm == pytest.approx(19.2, rel=1e-2)  # 10 * (120*100*160 / 1e6) = 19.2

        item2 = resp.packing_list_items[1]
        assert item2.total_net_weight_kg == 700.0   # 5 * 140
        assert item2.total_gross_weight_kg == 750.0   # 5 * 150

    def test_packing_list_validation_report(self, db_session):
        service = PurchaseOrderService(db_session)

        # Create PO with valid packing list
        po_create = PurchaseOrderCreate(
            proforma_invoice_number="PI-VALIDATE",
            project_id=1,
            company_id=1,
            supplier_id=1,
            incoterm_id=1,
            currency_id=1,
            packing_list_items=[
                PackingListItemCreate(
                    hs_code="8471.30.00",
                    item_code="ITEM-A",
                    qty_pcs=50.0,
                    qty_pkg=5.0,
                    package_type="Carton",
                    length_cm=50.0,
                    width_cm=40.0,
                    height_cm=30.0,
                    net_weight_unit_kg=10.0,
                    gross_weight_unit_kg=12.0,
                )
            ],
        )
        po_resp = service.create(po_create)

        report = service.get_packing_list_report(po_resp.po_id)
        assert report.is_valid is True
        assert len(report.errors) == 0
        assert report.total_items == 1
        assert report.total_pcs == 50.0
        assert report.total_net_weight_kg == 500.0
        assert report.total_gross_weight_kg == 600.0
        assert len(report.hs_code_summary) == 1
        assert report.hs_code_summary[0].hs_code == "8471.30.00"

    def test_packing_list_gross_less_than_net_validation_error(self, db_session):
        service = PurchaseOrderService(db_session)

        # Invalid: gross weight < net weight
        po_create = PurchaseOrderCreate(
            proforma_invoice_number="PI-ERR",
            project_id=1,
            company_id=1,
            supplier_id=1,
            incoterm_id=1,
            currency_id=1,
            packing_list_items=[
                PackingListItemCreate(
                    hs_code="8471.30.00",
                    item_code="BAD-WEIGHT-ITEM",
                    qty_pcs=10.0,
                    qty_pkg=1.0,
                    package_type="Carton",
                    length_cm=10.0,
                    width_cm=10.0,
                    height_cm=10.0,
                    net_weight_unit_kg=20.0,
                    gross_weight_unit_kg=15.0,  # Invalid: Gross < Net
                )
            ],
        )
        po_resp = service.create(po_create)

        report = service.get_packing_list_report(po_resp.po_id)
        assert report.is_valid is False
        assert len(report.errors) > 0
        assert "cannot be less than Net weight" in report.errors[0]
