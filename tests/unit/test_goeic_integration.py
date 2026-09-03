import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from database.database import Base, get_db
from main import app
from modules.integrations.goeic_client import GOEICIntegrationClient
from modules.integrations.schemas import GOEICComplianceCheckRequest
from modules.suppliers.model import Supplier
from modules.customs_tariff.model import CustomsTariff

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

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture(scope="function")
def seed_data(db_session):
    # 1. Supplier not registered in Decree 43
    unreg_supplier = Supplier(
        supplier_code="SUP-UNREG-001",
        company_name="Shenzhen NonReg Electronics Ltd",
        supplier_type="Manufacturer",
        registration_type="Tax Registered",
        foreign_exporter_id="EXP-CN-00123",
        foreign_exporter_country="China",
        foreign_exporter_country_code="CN",
        address="Shenzhen Industrial Zone",
        registered_decree_43=False,
        white_list_registered=False,
    )
    db_session.add(unreg_supplier)

    # 2. Supplier registered in Decree 43 White List
    reg_supplier = Supplier(
        supplier_code="SUP-REG-002",
        company_name="Guangdong Midea Electric Appliances",
        supplier_type="Manufacturer",
        registration_type="Tax Registered",
        foreign_exporter_id="GOEIC-REG-98741",
        foreign_exporter_country="China",
        foreign_exporter_country_code="CN",
        address="Foshan City, Guangdong",
        registered_decree_43=True,
        white_list_registered=True,
    )
    db_session.add(reg_supplier)

    # 3. Tariff for AC (Decree 43 mandated)
    ac_tariff = CustomsTariff(
        hs_code="8415820010",
        hs_description="وحدات تكييف هواء وتبريد متكاملة",
        customs_category="أجهزة",
        customs_duty_rate=60.0,
        vat_rate=14.0,
        requires_inspection=True,
        regulatory_authority="الهيئة العامة للرقابة على الصادرات والواردات (GOEIC)",
        prior_approval_note="ق4518 - يخضع لقرار 43 لسنة 2016 وتسجيل المصانع المؤهلة",
    )
    db_session.add(ac_tariff)

    # 4. Tariff for generic raw material (Not Decree 43)
    raw_tariff = CustomsTariff(
        hs_code="2804290000",
        hs_description="غازات نادرة - أرغون",
        customs_category="كيماويات",
        customs_duty_rate=5.0,
        vat_rate=14.0,
        requires_inspection=False,
        regulatory_authority=None,
        prior_approval_note=None,
    )
    db_session.add(raw_tariff)

    db_session.commit()
    db_session.refresh(unreg_supplier)
    db_session.refresh(reg_supplier)
    return unreg_supplier, reg_supplier


class TestGOEICIntegration:
    def test_unregistered_factory_decree_43_blocked(self, db_session, seed_data):
        unreg_sup, _ = seed_data
        client = GOEICIntegrationClient(mode="MOCK")

        req = GOEICComplianceCheckRequest(
            supplier_id=unreg_sup.supplier_id,
            hs_code="8415820010",
        )
        res = client.check_compliance(db_session, req)

        assert res.is_decree_43_mandated is True
        assert res.is_factory_registered is False
        assert res.overall_compliance_verdict == "BLOCKED_DECREE_43_VIOLATION"
        assert "تحذير رقابي حاسم" in res.warning_message_ar
        assert "43" in res.warning_message_ar

    def test_registered_factory_pending_coi(self, db_session, seed_data):
        _, reg_sup = seed_data
        client = GOEICIntegrationClient(mode="MOCK")

        req = GOEICComplianceCheckRequest(
            supplier_id=reg_sup.supplier_id,
            hs_code="8415820010",
            has_coi_certificate=False,
        )
        res = client.check_compliance(db_session, req)

        assert res.is_decree_43_mandated is True
        assert res.is_factory_registered is True
        assert res.overall_compliance_verdict == "PENDING_COI_CERTIFICATE"
        assert "شهادة فحص ما قبل الشحن" in res.warning_message_ar

    def test_registered_factory_with_valid_coi_cleared(self, db_session, seed_data):
        _, reg_sup = seed_data
        client = GOEICIntegrationClient(mode="MOCK")

        req = GOEICComplianceCheckRequest(
            supplier_id=reg_sup.supplier_id,
            hs_code="8415820010",
            has_coi_certificate=True,
            coi_agency="SGS Inspection Services",
            coi_number="SGS-CN-2026-88491",
        )
        res = client.check_compliance(db_session, req)

        assert res.is_decree_43_mandated is True
        assert res.is_factory_registered is True
        assert res.coi_valid is True
        assert res.overall_compliance_verdict == "CLEARED_FOR_IMPORT"
        assert res.warning_message_ar is None

    def test_accredited_inspection_bodies_list(self):
        client = GOEICIntegrationClient(mode="MOCK")
        bodies = client.get_accredited_inspection_bodies()

        assert len(bodies) >= 6
        names = [b.name_en for b in bodies]
        assert any("SGS" in n for n in names)
        assert any("Bureau Veritas" in n for n in names)
        assert any("TÜV" in n or "TUV" in n for n in names)

    def test_goeic_api_endpoints(self, client, seed_data):
        unreg_sup, reg_sup = seed_data

        # 1. Verify compliance via API (Unregistered -> Blocked)
        block_res = client.post(
            "/api/v1/integrations/goeic/verify-compliance",
            json={
                "supplier_id": unreg_sup.supplier_id,
                "hs_code": "8415820010",
            },
        )
        assert block_res.status_code == 200
        assert block_res.json()["overall_compliance_verdict"] == "BLOCKED_DECREE_43_VIOLATION"

        # 2. Verify compliance via API (Registered + SGS -> Cleared)
        clear_res = client.post(
            "/api/v1/integrations/goeic/verify-compliance",
            json={
                "supplier_id": reg_sup.supplier_id,
                "hs_code": "8415820010",
                "has_coi_certificate": True,
                "coi_agency": "Bureau Veritas",
                "coi_number": "BV-EGY-2026-0012",
            },
        )
        assert clear_res.status_code == 200
        assert clear_res.json()["overall_compliance_verdict"] == "CLEARED_FOR_IMPORT"

        # 3. Get accredited bodies via API
        bodies_res = client.get("/api/v1/integrations/goeic/accredited-inspection-bodies")
        assert bodies_res.status_code == 200
        assert len(bodies_res.json()) >= 6
