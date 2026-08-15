import pytest
from decimal import Decimal
from datetime import date
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from database.database import Base
import modules.purchase_orders.model as po_model
import modules.purchase_orders.schemas as po_schemas
import modules.purchase_orders.service as po_service
import modules.customs_tariff.model as ct_model
import modules.customs_tariff.schemas as ct_schemas
import modules.customs_tariff.service as ct_service
import modules.customs_tariff.repository as ct_repo
import modules.import_companies.model as comp_model
import modules.suppliers.model as supp_model
import modules.projects.model as prj_model
import modules.incoterms.model as inco_model
import modules.currencies.model as curr_model


@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


def test_po_creation_and_update_with_country_of_origin(db_session):
    # Setup master data
    from modules.import_companies.schemas import ImportCompanyCreate
    from modules.import_companies.service import create_import_company

    comp_data = ImportCompanyCreate(
        importer_name="Al-Amal Importing",
        address="Cairo, Egypt",
        country="Egypt",
        importer_id="IMP-100200",
        importer_id_expiry=date(2030, 1, 1),
        vat_id="VAT-998877",
        vat_id_expiry=date(2030, 1, 1),
        registration_number="REG-554433",
        registration_expiry=date(2030, 1, 1),
    )
    comp = create_import_company(db_session, comp_data)

    supp = supp_model.Supplier(
        supplier_code="SUP-DE-001",
        company_name="Siemens AG Germany",
        supplier_type="Manufacturer",
        registration_type="VAT Number",
        foreign_exporter_id="EXP-123",
        foreign_exporter_country="Germany",
        foreign_exporter_country_code="DE",
        address="Berlin, Germany",
        is_active=True,
    )
    db_session.add(supp)
    inco = inco_model.Incoterm(incoterm_code="FOB", incoterm_name="Free on Board")
    db_session.add(inco)
    curr = curr_model.Currency(currency_code="EUR", currency_name="Euro", currency_symbol="€", is_active=True)
    db_session.add(curr)
    db_session.commit()

    prj = prj_model.Project(
        project_code="PRJ-2026-001",
        project_name="Cairo Factory Project",
        project_owner="Eng. Ahmed",
        company_id=comp.company_id,
        supplier_id=supp.supplier_id,
        incoterm_id=inco.incoterm_id,
        is_active=True,
    )
    db_session.add(prj)
    db_session.commit()

    po_data = po_schemas.PurchaseOrderCreate(
        proforma_invoice_number="PI-EUR-2026-001",
        country_of_origin="DE - ألمانيا (Germany)",
        project_id=prj.project_id,
        company_id=comp.company_id,
        supplier_id=supp.supplier_id,
        incoterm_id=inco.incoterm_id,
        currency_id=curr.currency_id,
        order_date=date.today(),
        exchange_rate=55.0,
        payment_terms="Cash in Advance / SWIFT",
        status="Draft",
        notes="Testing origin country propagation",
        items=[
            po_schemas.POLineItemCreate(
                item_code="SIEM-001",
                description_ar="محرك كهربائي صناعي",
                country_of_origin="DE - ألمانيا (Germany)",
                quantity=10,
                unit_price=500.0,
                cbm_per_unit=0.2,
                gross_weight_kg=50.0,
            )
        ]
    )

    service = po_service.PurchaseOrderService(db_session)
    created_po = service.create(po_data)
    assert created_po.country_of_origin == "DE - ألمانيا (Germany)"
    assert len(created_po.items) == 1
    assert created_po.items[0].country_of_origin == "DE - ألمانيا (Germany)"

    # Update PO country of origin
    update_data = po_schemas.PurchaseOrderUpdate(
        country_of_origin="IT - إيطاليا (Italy)",
        items=[
            po_schemas.POLineItemCreate(
                item_code="SIEM-001",
                description_ar="محرك كهربائي صناعي إيطالي",
                country_of_origin="IT - إيطاليا (Italy)",
                quantity=10,
                unit_price=520.0,
            )
        ]
    )
    updated_po = service.update(created_po.po_id, update_data)
    assert updated_po.country_of_origin == "IT - إيطاليا (Italy)"
    assert updated_po.items[0].country_of_origin == "IT - إيطاليا (Italy)"


def test_customs_origin_exemption_evaluation(db_session):
    # Setup HS Code with standard 10% duty and 14% VAT
    tariff_data = {
        "hs_code": "8415820010",
        "hs_description": "أجهزة تكييف الهواء ذات التبريد الذاتي",
        "customs_duty_rate": 10.0,
        "vat_rate": 14.0,
        "schedule_tax_rate": 0.0,
        "development_fee_rate": 0.0,
        "requires_coo": True,
        "requires_inspection": False,
        "requires_acid": True,
        "effective_from": date(2026, 1, 1),
    }
    agreements_data = [
        {
            "hs_code": "8415820010",
            "agreement_name": "اتفاقية الشراكة المصرية الأوروبية (EUR.1)",
            "reduction_type": "full_duty_exemption",
            "reduction_percentage": 1.0,
            "preferential_duty_rate": 0.0,
            "origin_countries": "DE,FR,IT,ES,NL,BE,AT,PL,SE",
            "required_document": "شهادة EUR.1 أصلية",
            "conditions_note": "إعفاء كامل من ضريبة الوارد للسلع الصناعية الأوروبية",
            "effective_from": date(2026, 1, 1),
        },
        {
            "hs_code": "8415820010",
            "agreement_name": "اتفاقية التجارة الحرة مع دول الميركسور",
            "reduction_type": "full_duty_exemption",
            "reduction_percentage": 1.0,
            "preferential_duty_rate": 0.0,
            "origin_countries": "BR,AR,UY,PY",
            "required_document": "شهادة منشأ ميركسور أصلية",
            "conditions_note": "إعفاء كامل بموجب اتفاقية الميركسور",
            "effective_from": date(2026, 1, 1),
        }
    ]

    ct_repo.bulk_create_or_update_tariff_with_agreements(
        db=db_session, tariff_data=tariff_data, agreements_data=agreements_data
    )

    # 1. Test Germany (DE) with EUR.1 -> 0% duty
    req_de = ct_schemas.OriginDutyCheckRequest(
        hs_code="8415820010",
        origin_country="DE",
        has_preferential_document=True,
    )
    res_de = ct_service.evaluate_duty_by_origin_and_document_service(db_session, req_de)
    assert res_de.has_matching_agreement is True
    assert res_de.effective_duty_rate == Decimal("0.00")
    assert res_de.base_duty_rate == Decimal("10")
    assert "EUR.1" in res_de.applied_agreement_name

    # 2. Test Brazil (BR) with Mercosur doc -> 0% duty
    req_br = ct_schemas.OriginDutyCheckRequest(
        hs_code="8415820010",
        origin_country="BR",
        has_preferential_document=True,
    )
    res_br = ct_service.evaluate_duty_by_origin_and_document_service(db_session, req_br)
    assert res_br.has_matching_agreement is True
    assert res_br.effective_duty_rate == Decimal("0.00")
    assert "الميركسور" in res_br.applied_agreement_name

    # 3. Test China (CN) -> No agreement -> Standard 10% duty
    req_cn = ct_schemas.OriginDutyCheckRequest(
        hs_code="8415820010",
        origin_country="CN",
        has_preferential_document=False,
    )
    res_cn = ct_service.evaluate_duty_by_origin_and_document_service(db_session, req_cn)
    assert res_cn.has_matching_agreement is False
    assert res_cn.effective_duty_rate == Decimal("10")
