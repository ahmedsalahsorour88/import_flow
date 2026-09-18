import pytest
from datetime import date, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

import main
from database.database import Base, get_db
from modules.import_files.model import ImportFile
from modules.demurrage_detention.model import DemurrageTracking, DemurragePolicy
from modules.demurrage_detention.service import get_containers_radar_overview_service

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
    with TestClient(main.app) as c:
        yield c
    main.app.dependency_overrides.clear()


class TestDemurrageRadarServiceAndAPI:

    def test_radar_overview_empty(self, db_session, client):
        """رادار فارغ عند عدم وجود تتبع حاويات"""
        overview = get_containers_radar_overview_service(db_session)
        assert overview.total_containers_tracked == 0
        assert overview.safe_containers_count == 0
        assert overview.warning_containers_count == 0
        assert overview.critical_overdue_count == 0
        assert overview.radar_items == []

        # API Call
        res = client.get("/api/v1/demurrage-detention/radar-overview")
        assert res.status_code == 200
        data = res.json()
        assert data["total_containers_tracked"] == 0
        assert data["safe_containers_count"] == 0

    def test_radar_overview_with_mixed_containers(self, db_session, client):
        """رادار مراقبة يحتوي على مختلف الحالات: آمن، تحذير، متأخر، ومرتجع"""
        # Create import file
        imp_file = ImportFile(
            import_file_code="IMP-2026-0045",
            company_name="Al-Amal Co",
            supplier_name="Global Supplier",
            current_stage="Customs Clearance",
            status="In Progress",
            is_active=True,
        )
        db_session.add(imp_file)
        db_session.commit()
        db_session.refresh(imp_file)

        # Create policy
        policy = DemurragePolicy(
            carrier_name="MSC",
            container_type="40ft High Cube",
            demurrage_free_days=14,
            detention_free_days=7,
            port_storage_free_days=5,
            port_storage_daily_rate_egp=250.0,
            currency="USD",
            is_active=True,
        )
        db_session.add(policy)
        db_session.commit()
        db_session.refresh(policy)

        today = date.today()

        # 1. Safe container (discharged 1 day ago, 14 free days demurrage, 5 storage)
        safe_tracking = DemurrageTracking(
            tracking_code="TRK-SAFE-01",
            import_file_id=imp_file.import_file_id,
            import_file_code=imp_file.import_file_code,
            policy_id=policy.policy_id,
            carrier_name="MSC",
            bill_of_lading_no="MEDU1234567",
            port_name="Alexandria Port",
            discharge_date=today - timedelta(days=1),
            containers=[
                {
                    "container_no": "MSCU1111111",
                    "container_type": "40ft High Cube",
                    "gate_out_date": None,
                    "empty_return_date": None,
                }
            ],
            total_demurrage_fx=0.0,
            total_detention_fx=0.0,
            total_storage_egp=0.0,
            currency="USD",
            exchange_rate=50.0,
            total_cost_egp=0.0,
            status="In Free Period",
            is_active=True,
        )

        # 2. Warning container (discharged 3 days ago -> 2 days remaining storage <= 2)
        warning_tracking = DemurrageTracking(
            tracking_code="TRK-WARN-02",
            import_file_id=imp_file.import_file_id,
            import_file_code=imp_file.import_file_code,
            policy_id=policy.policy_id,
            carrier_name="MSC",
            bill_of_lading_no="MEDU2345678",
            port_name="Alexandria Port",
            discharge_date=today - timedelta(days=3),
            containers=[
                {
                    "container_no": "MSCU2222222",
                    "container_type": "40ft High Cube",
                    "gate_out_date": None,
                    "empty_return_date": None,
                }
            ],
            total_demurrage_fx=0.0,
            total_detention_fx=0.0,
            total_storage_egp=0.0,
            currency="USD",
            exchange_rate=50.0,
            total_cost_egp=0.0,
            status="Warning Imminent",
            is_active=True,
        )

        # 3. Critical Overdue container (discharged 20 days ago -> 6 days overdue demurrage)
        critical_tracking = DemurrageTracking(
            tracking_code="TRK-CRIT-03",
            import_file_id=imp_file.import_file_id,
            import_file_code=imp_file.import_file_code,
            policy_id=policy.policy_id,
            carrier_name="MSC",
            bill_of_lading_no="MEDU3456789",
            port_name="Alexandria Port",
            discharge_date=today - timedelta(days=20),
            containers=[
                {
                    "container_no": "MSCU3333333",
                    "container_type": "40ft High Cube",
                    "gate_out_date": None,
                    "empty_return_date": None,
                }
            ],
            total_demurrage_fx=420.0,
            total_detention_fx=0.0,
            total_storage_egp=3750.0,
            currency="USD",
            exchange_rate=50.0,
            total_cost_egp=24750.0,
            status="Demurrage Incurred",
            is_active=True,
        )

        # 4. Returned Safe container (empty_return_date set)
        returned_tracking = DemurrageTracking(
            tracking_code="TRK-RET-04",
            import_file_id=imp_file.import_file_id,
            import_file_code=imp_file.import_file_code,
            policy_id=policy.policy_id,
            carrier_name="MSC",
            bill_of_lading_no="MEDU4567890",
            port_name="Alexandria Port",
            discharge_date=today - timedelta(days=10),
            containers=[
                {
                    "container_no": "MSCU4444444",
                    "container_type": "40ft High Cube",
                    "gate_out_date": str(today - timedelta(days=5)),
                    "empty_return_date": str(today - timedelta(days=2)),
                }
            ],
            total_demurrage_fx=0.0,
            total_detention_fx=0.0,
            total_storage_egp=0.0,
            currency="USD",
            exchange_rate=50.0,
            total_cost_egp=0.0,
            status="Completed & Returned",
            is_active=True,
        )

        db_session.add_all([safe_tracking, warning_tracking, critical_tracking, returned_tracking])
        db_session.commit()

        # Execute Service
        overview = get_containers_radar_overview_service(db_session)
        assert overview.total_containers_tracked == 4
        assert overview.safe_containers_count == 1
        assert overview.warning_containers_count == 1
        assert overview.critical_overdue_count == 1
        assert overview.returned_containers_count == 1
        assert overview.total_accrued_demurrage_usd > 0
        assert overview.total_accrued_storage_egp > 0
        assert overview.total_estimated_exposure_egp > 0

        # Check radar statuses
        statuses = {item.container_number: item.radar_status for item in overview.radar_items}
        assert statuses["MSCU1111111"] == "SAFE"
        assert statuses["MSCU2222222"] == "WARNING"
        assert statuses["MSCU3333333"] == "CRITICAL_OVERDUE"
        assert statuses["MSCU4444444"] == "RETURNED_SAFE"

        colors = {item.container_number: item.color_code for item in overview.radar_items}
        assert colors["MSCU1111111"] == "#27AE60"
        assert colors["MSCU2222222"] == "#E67E22"
        assert colors["MSCU3333333"] == "#C0392B"
        assert colors["MSCU4444444"] == "#7F8C8D"

        # Execute Endpoint
        res = client.get("/api/v1/demurrage-detention/radar-overview")
        assert res.status_code == 200
        payload = res.json()
        assert payload["total_containers_tracked"] == 4
        assert payload["safe_containers_count"] == 1
        assert payload["warning_containers_count"] == 1
        assert payload["critical_overdue_count"] == 1
        assert payload["returned_containers_count"] == 1
        assert len(payload["radar_items"]) == 4
