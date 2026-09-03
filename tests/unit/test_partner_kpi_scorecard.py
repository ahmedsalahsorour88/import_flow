import pytest
from datetime import datetime, timezone, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

import main
from database.database import Base, get_db
from modules.external_service_providers.model import ExternalServiceProvider
from modules.external_service_providers.service import ExternalServiceProviderService
from modules.import_files.model import ImportFile
from modules.customs_clearance.model import CustomsClearanceRecord
from modules.freight_booking.model import ShipmentBooking


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


class TestPartnerKPIScorecard:
    """
    LOG-KPIS-005: Logistics Partner Performance Scorecards.
    """

    def test_customs_broker_scorecard(self, db_session):
        # 1. Create Customs Broker Partner
        broker = ExternalServiceProvider(
            partner_name="Al-Ahram Customs Agency",
            partner_code="PRV-BRK-001",
            partner_type="Customs Broker",
            rating=4.8,
        )
        db_session.add(broker)
        db_session.commit()
        db_session.refresh(broker)

        # 2. Add clearances linked to broker
        now = datetime.now(timezone.utc)
        imp1 = ImportFile(
            import_file_code="IMP-KPI-01",
            company_name="Delta Tech",
            supplier_name="Bologna Hydraulics",
            broker_id=broker.provider_id,
        )
        imp2 = ImportFile(
            import_file_code="IMP-KPI-02",
            company_name="Delta Tech",
            supplier_name="Tokyo Steel",
            broker_id=broker.provider_id,
        )
        db_session.add_all([imp1, imp2])
        db_session.commit()
        db_session.refresh(imp1)
        db_session.refresh(imp2)

        # Clearance 1: Green channel, completed in 2 days
        clr1 = CustomsClearanceRecord(
            clearance_code="CLR-KPI-01",
            import_file_id=imp1.import_file_id,
            channel_type="Green Channel",
            inspection_date=now - timedelta(days=2),
            release_date=now,
            status="Final Release Granted",
        )
        # Clearance 2: Yellow channel, completed in 3 days
        clr2 = CustomsClearanceRecord(
            clearance_code="CLR-KPI-02",
            import_file_id=imp2.import_file_id,
            channel_type="Yellow Channel",
            inspection_date=now - timedelta(days=3),
            release_date=now,
            status="Final Release Granted",
        )
        db_session.add_all([clr1, clr2])
        db_session.commit()

        service = ExternalServiceProviderService(db_session)
        card = service.get_partner_scorecard(broker.provider_id)

        assert card.provider_id == broker.provider_id
        assert card.partner_name == "Al-Ahram Customs Agency"
        assert card.total_jobs_completed == 2
        assert card.green_channel_rate == 50.0
        assert card.average_clearance_days == 2.5
        assert card.on_time_performance_rate == 100.0  # both <= 4 days
        assert card.quality_score_out_of_100 >= 90.0
        assert card.tier_badge == "Platinum A+"
        assert "بطاقة تقييم الشريك" in card.executive_summary_ar

    def test_shipping_line_scorecard(self, db_session):
        line = ExternalServiceProvider(
            partner_name="Mediterranean Shipping Co (MSC)",
            partner_code="PRV-MSC-001",
            partner_type="Shipping Line",
            rating=4.5,
        )
        db_session.add(line)
        db_session.commit()
        db_session.refresh(line)

        # Bookings with delays
        b1 = ShipmentBooking(
            booking_code="BKG-MSC-01",
            shipping_line_id=line.provider_id,
            departure_delay_days=0,
            status="Completed",
        )
        b2 = ShipmentBooking(
            booking_code="BKG-MSC-02",
            shipping_line_id=line.provider_id,
            departure_delay_days=1,
            status="Completed",
        )

        db_session.add_all([b1, b2])
        db_session.commit()

        service = ExternalServiceProviderService(db_session)
        card = service.get_partner_scorecard(line.provider_id)

        assert card.total_jobs_completed == 2
        assert card.average_transit_delay_days == 0.5
        assert card.on_time_performance_rate == 100.0
        assert card.star_rating >= 4.5

    def test_api_scorecard_endpoint(self, client, db_session):
        partner = ExternalServiceProvider(
            partner_name="Cairo Logistics Forwarding",
            partner_code="PRV-FWD-99",
            partner_type="Freight Forwarder",
            rating=4.2,
        )
        db_session.add(partner)
        db_session.commit()
        db_session.refresh(partner)

        resp = client.get(f"/api/v1/external-service-providers/{partner.provider_id}/scorecard")
        assert resp.status_code == 200
        data = resp.json()
        assert data["partner_name"] == "Cairo Logistics Forwarding"
        assert "star_rating" in data
        assert "tier_badge" in data
        assert "executive_summary_ar" in data
