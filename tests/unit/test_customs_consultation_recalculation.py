import pytest
from datetime import date, timedelta
from fastapi.testclient import TestClient
from database.database import get_db, Base
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from main import app
from modules.import_files.model import ImportFile
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.incoterms.model import Incoterm
from modules.currencies.model import Currency
from modules.projects.model import Project
from modules.customs_tariff.model import CustomsTariff
from modules.purchase_orders.model import PurchaseOrder, POLineItem
from modules.import_documentation.model import POPackingReconciliationSession
from modules.customs_consultation.service import CustomsConsultationService


SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture
def db_session():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        # Create master data
        comp = ImportCompany(
            importer_name="الشركة النموذجية",
            address="Cairo",
            country="Egypt",
            importer_id="IMP-001",
            importer_id_expiry=date.today() + timedelta(days=120),
            vat_id="VAT-001",
            vat_id_expiry=date.today() + timedelta(days=90),
            registration_number="REG-001",
            registration_expiry=date.today() + timedelta(days=180),
            phone="+2010000000",
            email="info@model.com",
        )
        db.add(comp)
        sup = Supplier(
            supplier_code="SUP-9901",
            company_name="Test China Supplier",
            supplier_type="Manufacturer",
            registration_type="Commercial Registry",
            foreign_exporter_id="EX-9901",
            foreign_exporter_country="China",
            foreign_exporter_country_code="CN",
            address="Hangzhou, China",
            phone="+8612345",
            email="supplier@china.com",
        )
        db.add(sup)
        incoterm = Incoterm(incoterm_code="FOB", incoterm_name="Free On Board", is_active=True)
        currency = Currency(currency_code="USD", currency_name="US Dollar", currency_symbol="$", is_active=True)
        db.add_all([incoterm, currency])
        db.commit()

        proj = Project(
            project_code="PRJ-2026-99",
            project_name="Marble Import Project",
            project_owner="Eng. Ali",
            company_id=comp.company_id,
            supplier_id=sup.supplier_id,
            incoterm_id=incoterm.incoterm_id,
            is_active=True,
        )
        db.add(proj)
        db.commit()

        tariff = CustomsTariff(
            hs_code="6802.99",
            hs_description="جرانيت ورخام",
            customs_duty_rate=10.0,
            vat_rate=14.0,
            schedule_tax_rate=0.0,
            development_fee_rate=0.0,
            customs_service_fee_rate=1.0,
            effective_from=date(2020, 1, 1),
        )
        db.add(tariff)
        db.commit()

        imp_file = ImportFile(
            import_file_code="IMP-2026-TEST",
            company_id=comp.company_id,
            company_name=comp.importer_name,
            supplier_id=sup.supplier_id,
            supplier_name=sup.company_name,
            pi_number="PI-9901",
            status="In Progress",
        )
        db.add(imp_file)
        db.commit()

        # Preliminary PO
        po = PurchaseOrder(
            po_number="PO-2026-99",
            import_file_id=imp_file.import_file_id,
            project_id=proj.project_id,
            company_id=comp.company_id,
            supplier_id=sup.supplier_id,
            incoterm_id=incoterm.incoterm_id,
            currency_id=currency.currency_id,
            total_amount_fob=10000.0,
        )
        db.add(po)
        db.commit()

        item = POLineItem(
            po_id=po.po_id,
            description_ar="Raw Granite Slabs",
            tariff_id=tariff.tariff_id,
            quantity=100.0,
            unit_price=100.0,
            total_price=10000.0,
        )
        db.add(item)
        db.commit()

        # Reconciled Final Invoice Session with 120 units at $110
        reconcil = POPackingReconciliationSession(
            session_code="REC-2026-001",
            import_file_id=imp_file.import_file_id,
            final_invoice_number="INV-FINAL-2026-01",
            currency="USD",
            total_invoice_amount=13200.0,
            is_safe_for_certification=True,
            overall_status="FULLY_MATCHED",
            reconciled_invoice_items=[
                {
                    "item_name": "Raw Granite Slabs Reconciled",
                    "hs_code": "6802.99",
                    "quantity": 120.0,
                    "unit_price": 110.0,
                    "total_price": 13200.0,
                    "country_of_origin": "CN",
                }
            ],
        )
        db.add(reconcil)
        db.commit()

        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)


def test_customs_consultation_recalculation(db_session):
    imp_file = db_session.query(ImportFile).first()
    res = CustomsConsultationService.recalculate_from_reconciliation_service(
        db_session,
        import_file_id=imp_file.import_file_id,
        exchange_rate=50.0,
        freight_egp=5000.0,
        insurance_egp=1000.0,
    )

    assert res.import_file_id == imp_file.import_file_id
    assert res.is_reconciled is True
    assert res.final_invoice_number == "INV-FINAL-2026-01"
    assert res.preliminary_fob_egp == 500000.0  # 10,000 * 50
    assert res.final_fob_egp == 660000.0        # 13,200 * 50
    assert res.fob_variance_egp == 160000.0
    assert res.forecast_status == "Increased Cost"
    assert len(res.comparison_lines) == 1
    assert res.comparison_lines[0].qty_variance == 20.0
    assert res.comparison_lines[0].unit_price_variance == 10.0
    assert res.total_taxes_variance_egp > 0


def test_customs_recalculation_api_endpoint(db_session):
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    client = TestClient(app)

    imp_file = db_session.query(ImportFile).first()
    payload = {
        "import_file_id": imp_file.import_file_id,
        "exchange_rate": 52.0,
        "freight_egp": 6000.0,
        "insurance_egp": 1200.0,
    }

    response = client.post("/api/v1/customs-consultations/recalculate-from-reconciliation", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["import_file_id"] == imp_file.import_file_id
    assert data["exchange_rate"] == 52.0
    assert data["is_reconciled"] is True
    assert "comparison_lines" in data

    app.dependency_overrides.clear()
