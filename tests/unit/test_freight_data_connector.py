import pytest
from datetime import datetime, timezone, date, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

import main
from database.database import Base, get_db
from modules.freight_data_connector.model import (
    FreightIndexSnapshot,
    DemurrageRule,
    PortDemurrageTariff,
    ExternalApiQuotaLog,
)
from modules.freight_data_connector.service import FreightDataService
from modules.freight_data_connector.schemas import DualDemurrageCalculateRequest


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


class TestFreightDataConnector:
    """
    INT-DATA-015: Free Freight & Demurrage External Data Connector.
    """

    def test_get_status_and_quota_monitor(self, client, db_session):
        resp = client.get("/api/v1/freight-data/status")
        assert resp.status_code == 200
        data = resp.json()
        assert "shaq_freight_status" in data
        assert "shippingrates_status" in data
        assert data["monthly_quota_limit"] == 25
        assert data["monthly_quota_remaining"] <= 25
        assert len(data["active_port_authorities"]) >= 1

    def test_sfx_freight_index_sync_and_retrieval(self, client, db_session):
        service = FreightDataService(db_session)
        count = service.sync_shaq_freight_index(force_sample_if_unavailable=True)
        assert count >= 3

        snapshots = service.get_latest_freight_index()
        assert len(snapshots) >= 3
        routes = [s.route_name for s in snapshots]
        assert any("Shanghai" in r or "Ningbo" in r for r in routes)

        # Test API endpoint
        resp = client.get("/api/v1/freight-data/snapshots/latest")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data) >= 3
        assert "fcl_40hq_usd" in data[0]

    def test_carrier_detention_local_math(self, db_session):
        service = FreightDataService(db_session)
        rules = service.get_demurrage_rules("maersk")
        assert len(rules) >= 1

        # Test 10 days (within 14 free days) -> $0
        req_safe = DualDemurrageCalculateRequest(
            shipping_line="maersk",
            port_authority="Alexandria",
            container_type="40HC",
            discharge_date=date(2026, 1, 1),
            days_in_port=10,
        )
        res_safe = service.calculate_dual_demurrage(req_safe)
        assert res_safe.detention.total_detention_usd == 0.0
        assert res_safe.detention.chargeable_days == 0

        # Test 18 days (14 free + 4 days in tier 1 @ $40/day) -> $160
        req_overdue = DualDemurrageCalculateRequest(
            shipping_line="maersk",
            port_authority="Alexandria",
            container_type="40HC",
            discharge_date=date(2026, 1, 1),
            days_in_port=18,
        )
        res_overdue = service.calculate_dual_demurrage(req_overdue)
        assert res_overdue.detention.total_detention_usd == 160.0
        assert res_overdue.detention.chargeable_days == 4

    def test_egyptian_port_demurrage_versioned_tariff(self, db_session):
        service = FreightDataService(db_session)

        # Container discharged in 2023 -> must apply Decision-312-2023
        req_2023 = DualDemurrageCalculateRequest(
            shipping_line="msc",
            port_authority="Alexandria",
            container_type="40ft",
            discharge_date=date(2023, 10, 1),
            days_in_port=8, # 4 free + 4 days @ 220 EGP = 880 EGP
        )
        res_2023 = service.calculate_dual_demurrage(req_2023)
        assert res_2023.port_storage.tariff_version_applied == "Decision-312-2023"
        assert res_2023.port_storage.total_storage_egp == 880.0

        # Container discharged in late 2024 / 2025 -> must apply Decision-554-2024
        req_2025 = DualDemurrageCalculateRequest(
            shipping_line="msc",
            port_authority="Alexandria",
            container_type="40ft",
            discharge_date=date(2025, 2, 1),
            days_in_port=8, # 4 free + 4 days @ 280 EGP = 1120 EGP
        )
        res_2025 = service.calculate_dual_demurrage(req_2025)
        assert res_2025.port_storage.tariff_version_applied == "Decision-554-2024"
        assert res_2025.port_storage.total_storage_egp == 1120.0

    def test_dual_demurrage_api_endpoint(self, client, db_session):
        payload = {
            "shipping_line": "cma_cgm",
            "port_authority": "Damietta",
            "container_type": "40HC",
            "discharge_date": "2026-05-01",
            "days_in_port": 16, # 14 free days -> 2 detention days @ $40 = $80
            "exchange_rate_usd_egp": 50.0,
        }
        resp = client.post("/api/v1/freight-data/calculate-dual-demurrage", json=payload)
        assert resp.status_code == 200
        data = resp.json()

        assert data["detention"]["total_detention_usd"] == 80.0
        assert data["detention"]["currency"] == "USD"
        assert data["port_storage"]["currency"] == "EGP"
        assert data["port_storage"]["total_storage_egp"] > 0
        assert data["consolidated_total_egp"] > 0
        assert data["exchange_rate_applied"] == 50.0
        assert "تقرير حساب الغرامات والأرضيات المزدوج" in data["advisory_notice_ar"]

    def test_quota_guard_blocks_excessive_calls(self, client, db_session):
        from modules.freight_data_connector.repository import FreightDataRepository
        repo = FreightDataRepository(db_session)

        now = datetime.now(timezone.utc)
        month_str = now.strftime("%Y-%m")

        # Simulate consuming 10 calls (safety cap)
        for i in range(10):
            repo.log_api_call(
                provider="shippingrates.org",
                endpoint="/api/dd/calculate",
                details=f"Test Call {i+1}",
                success=True,
            )

        # 11th call must trigger Quota Guard 429
        resp = client.post("/api/v1/freight-data/demurrage-rules/sync?shipping_line=hapag_lloyd")
        assert resp.status_code == 429
        assert "Quota Guard triggered" in resp.json()["detail"]

    def test_create_new_port_tariff_decree(self, client, db_session):
        payload = {
            "port_authority": "Sokhna",
            "container_type": "40HC",
            "free_days": 5,
            "rate_slabs": [
                {"from_day": 1, "to_day": 5, "rate_per_day": 0.0},
                {"from_day": 6, "to_day": 12, "rate_per_day": 350.0},
                {"from_day": 13, "to_day": None, "rate_per_day": 700.0},
            ],
            "tariff_version": "Decision-99-2026",
            "effective_from": "2026-06-01",
            "effective_to": None,
            "source_document": "Decree_99_2026.pdf",
            "entered_by": "Customs Auditor",
        }
        resp = client.post("/api/v1/freight-data/port-tariffs", json=payload)
        assert resp.status_code == 201
        data = resp.json()
        assert data["tariff_version"] == "Decision-99-2026"
        assert data["free_days"] == 5
