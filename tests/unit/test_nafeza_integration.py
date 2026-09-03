import pytest
from decimal import Decimal
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from database.database import Base, get_db
from main import app
from modules.integrations.nafeza_client import NafezaIntegrationClient
from modules.customs_tariff.model import CustomsTariff, PreferentialAgreement
from modules.currencies.model import Currency, ExchangeRate

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


RAW_NAFEZA_TEXT_SAMPLE = """رقم البند :
8415820010
نص البند :
آلات وأجهزة تكييف أخر متضمنة وحدة تبريد ، وحدات كاملة .
الضرائب :
ضريبة الوارد (النظام الاساسي) :
60.000 %
ضريبة الجدول :
8.000 %
ضريبة قيمه مضافه :
14.000 %
رسم التنمية :
0.000 %
رسم الوارد :
0.000 %
المستندات والأعمال :
ر6722 - اتفاقية صربيا تخفيض 10%
ق4518 - لايصرح باستيراد صنف الا بموافقة مختومة بخاتم شعارجمهوريةمن هـ .ع.ص.وطبقا لملحق8 وتعديلاته
ر6668 - تخفض ض .ج ورسوم بنسبة100%علىسلع صناعيةواردةفى ظل اتفاقية الشراكةالمصرية والمملكة المتحدة
ق9994 - لايفرج عن صنف بضاعة مرشدةللمنطقة الحرة الابحصص لكل مستورد يحددهاجهاز تنفيذى للمنطقةالحرة
ر6704 - فى ظل اتفاق التجارة الحرة بين مصر وتجمع الميركسور تحصل ضريبة جمركية بنسبة 3%
ر6631 - يعفى من الضريبة الجمركية والرسوم ذات الاثر المماثل الأصناف الواردة من دول الافتا بنسبة100%
"""


class TestNafezaIntegration:
    def test_parse_and_sync_nafeza_tariff_engine(self, db_session):
        client = NafezaIntegrationClient(mode="MOCK")
        res = client.parse_and_sync_tariff(db_session, RAW_NAFEZA_TEXT_SAMPLE)

        assert res.hs_code == "8415820010"
        assert "تكييف" in res.hs_description
        assert res.customs_duty_rate == 60.0
        assert res.vat_rate == 14.0
        assert res.schedule_tax_rate == 8.0
        assert res.requires_inspection is True
        assert res.agreements_count >= 3

        # Verify database record
        saved_tariff = db_session.query(CustomsTariff).filter(CustomsTariff.hs_code == "8415820010").first()
        assert saved_tariff is not None
        assert saved_tariff.customs_duty_rate == Decimal("60.0")

        # Verify agreements saved in DB
        saved_agreements = db_session.query(PreferentialAgreement).filter(PreferentialAgreement.hs_code == "8415820010").all()
        assert len(saved_agreements) >= 3

    def test_sync_customs_exchange_rates_engine(self, db_session):
        client = NafezaIntegrationClient(mode="MOCK")
        res = client.sync_official_customs_exchange_rates(db_session)

        assert res.status == "SUCCESS"
        assert res.synced_count >= 7

        usd_item = next((r for r in res.rates if r.currency_code == "USD"), None)
        assert usd_item is not None
        assert usd_item.exchange_rate == 48.65

        # Check in DB
        usd_curr = db_session.query(Currency).filter(Currency.currency_code == "USD").first()
        assert usd_curr is not None

        rates = client.get_latest_customs_exchange_rates(db_session)
        assert len(rates) >= 7

    def test_nafeza_api_endpoints(self, client):
        # 1. Parse and sync via API
        response = client.post(
            "/api/v1/integrations/nafeza/tariffs/parse-and-sync",
            json={"raw_text": RAW_NAFEZA_TEXT_SAMPLE, "mode": "MOCK"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["hs_code"] == "8415820010"
        assert data["customs_duty_rate"] == 60.0

        # 2. Get details via API
        get_res = client.get("/api/v1/integrations/nafeza/tariffs/8415820010")
        assert get_res.status_code == 200
        assert get_res.json()["hs_code"] == "8415820010"

        # 3. Sync exchange rates via API
        sync_res = client.post("/api/v1/integrations/nafeza/exchange-rates/sync")
        assert sync_res.status_code == 200
        assert sync_res.json()["synced_count"] >= 7

        # 4. Get latest customs exchange rates via API
        rates_res = client.get("/api/v1/integrations/nafeza/exchange-rates/latest")
        assert rates_res.status_code == 200
        rates_list = rates_res.json()
        assert any(r["currency_code"] == "USD" for r in rates_list)
