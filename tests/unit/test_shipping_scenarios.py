from datetime import date, timedelta
import pytest
from fastapi import HTTPException
from sqlalchemy.orm import Session

from database.database import SessionLocal, Base, engine
from seed import seed_data
from modules.shipping_scenarios.schemas import (
    ShippingEvaluationCreate,
    ShippingEvaluationUpdate,
    ShippingScenarioItemCreate,
)
from modules.shipping_scenarios.service import ShippingScenarioService


from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

@pytest.fixture(scope="module")
def db():
    test_engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=test_engine)
    TestingSession = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)
    session = TestingSession()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=test_engine)


class TestShippingScenariosBackend:
    """
    Unit tests for BP-007 Shipping Scenarios Evaluation Engine
    """

    def test_create_shipping_evaluation_service(self, db: Session):
        crd = date.today() + timedelta(days=5)
        item1 = ShippingScenarioItemCreate(
            provider_name="COSCO Shipping",
            vessel_name="COSCO UNIVERSE",
            voyage_number="101E",
            sailing_date=crd + timedelta(days=2),
            estimated_arrival_date=crd + timedelta(days=22),
            expected_line_delay_days=2,
            is_recommended=True,
            risk_level="Low",
        )
        item2 = ShippingScenarioItemCreate(
            provider_name="Maersk Line",
            vessel_name="MAERSK MC-KINNEY",
            voyage_number="202W",
            sailing_date=crd + timedelta(days=4),
            estimated_arrival_date=crd + timedelta(days=28),
            expected_line_delay_days=3,
            is_recommended=False,
            risk_level="Medium",
        )

        payload = ShippingEvaluationCreate(
            title="Shanghai to Alexandria Transit Study",
            cargo_ready_date=crd,
            avg_form4_days=5,
            avg_clearance_days=7,
            items=[item1, item2],
        )

        res = ShippingScenarioService.create_session_service(db, payload)

        assert res.session_id is not None
        assert res.session_code.startswith("SCE-")
        assert len(res.items) == 2

        # Item 1 calculations check:
        # Lead time = 20 days (sailing +2 -> arrival +22)
        # Ready days = 2 days
        # Total warehouse days = 20 (vessel) + 2 (ready) + 5 (form4) + 7 (clearance) + 2 (delay) = 36 days
        assert res.items[0].vessel_lead_time_days == 20
        assert res.items[0].ready_for_shipping_days == 2
        assert res.items[0].expected_total_days_to_warehouse == 36
        assert res.items[0].expected_warehouse_arrival_date == crd + timedelta(days=36)

        # Item 2 calculations check:
        # Lead time = 24 days (sailing +4 -> arrival +28)
        # Ready days = 4 days
        # Total warehouse days = 24 + 4 + 5 + 7 + 3 = 43 days
        assert res.items[1].vessel_lead_time_days == 24
        assert res.items[1].ready_for_shipping_days == 4
        assert res.items[1].expected_total_days_to_warehouse == 43

        # Summary averages check:
        # Avg transit days = (36 + 43) / 2 = 39.5 days
        assert res.avg_expected_transit_days == 39.5
        assert res.earliest_arrival_scenario_provider == "COSCO Shipping"
        assert res.latest_arrival_scenario_provider == "Maersk Line"
        assert res.recommended_scenario_provider == "COSCO Shipping (COSCO UNIVERSE)"

    def test_exclusion_of_outlier_scenarios_from_average(self, db: Session):
        crd = date.today()
        item1 = ShippingScenarioItemCreate(
            provider_name="Fast Carrier",
            vessel_name="FAST-01",
            sailing_date=crd,
            estimated_arrival_date=crd + timedelta(days=10),
            expected_line_delay_days=0,
            is_excluded_from_average=False,
        )
        item2 = ShippingScenarioItemCreate(
            provider_name="Outlier Delayed Carrier",
            vessel_name="SLOW-99",
            sailing_date=crd + timedelta(days=20),
            estimated_arrival_date=crd + timedelta(days=100),
            expected_line_delay_days=15,
            is_excluded_from_average=True,  # Excluded from average calculation
        )

        payload = ShippingEvaluationCreate(
            title="Outlier Exclusion Test",
            cargo_ready_date=crd,
            avg_form4_days=5,
            avg_clearance_days=5,
            items=[item1, item2],
        )

        res = ShippingScenarioService.create_session_service(db, payload)

        assert len(res.items) == 2
        # Only item1 total days (10 + 0 + 5 + 5 + 0 = 20) should be included in average
        assert res.avg_expected_transit_days == 20.0

    def test_invalid_sailing_date_before_crd_raises_error(self, db: Session):
        crd = date.today() + timedelta(days=10)
        invalid_item = ShippingScenarioItemCreate(
            provider_name="Invalid Carrier",
            vessel_name="PAST-01",
            sailing_date=crd - timedelta(days=2),  # Before CRD!
            estimated_arrival_date=crd + timedelta(days=15),
        )

        payload = ShippingEvaluationCreate(
            title="Invalid Date Study",
            cargo_ready_date=crd,
            items=[invalid_item],
        )

        with pytest.raises(HTTPException) as exc_info:
            ShippingScenarioService.create_session_service(db, payload)

        assert exc_info.value.status_code == 400
        assert "cannot be before Cargo Ready Date" in exc_info.value.detail

    def test_invalid_eta_before_sailing_date_raises_error(self, db: Session):
        crd = date.today()
        invalid_item = ShippingScenarioItemCreate(
            provider_name="Time Travel Line",
            vessel_name="TIME-01",
            sailing_date=crd + timedelta(days=5),
            estimated_arrival_date=crd + timedelta(days=3),  # ETA before sailing!
        )

        payload = ShippingEvaluationCreate(
            title="Time Travel Study",
            cargo_ready_date=crd,
            items=[invalid_item],
        )

        with pytest.raises(HTTPException) as exc_info:
            ShippingScenarioService.create_session_service(db, payload)

        assert exc_info.value.status_code == 400
        assert "Estimated Arrival Date (ETA) must be after Sailing Date" in exc_info.value.detail

    def test_duplicate_carrier_option_raises_error(self, db: Session):
        crd = date.today()
        sailing = crd + timedelta(days=2)
        eta = crd + timedelta(days=20)
        item1 = ShippingScenarioItemCreate(
            provider_name="COSCO",
            vessel_name="VESSEL A",
            sailing_date=sailing,
            estimated_arrival_date=eta,
        )
        item2 = ShippingScenarioItemCreate(
            provider_name="COSCO",
            vessel_name="VESSEL A",
            sailing_date=sailing,
            estimated_arrival_date=eta,
        )

        payload = ShippingEvaluationCreate(
            title="Duplicate Option Study",
            cargo_ready_date=crd,
            items=[item1, item2],
        )

        with pytest.raises(HTTPException) as exc_info:
            ShippingScenarioService.create_session_service(db, payload)

        assert exc_info.value.status_code == 400
        assert "Duplicate shipping option found" in exc_info.value.detail

    def test_list_and_update_shipping_evaluation(self, db: Session):
        crd = date.today()
        payload = ShippingEvaluationCreate(
            title="Initial Study",
            cargo_ready_date=crd,
            items=[
                ShippingScenarioItemCreate(
                    provider_name="Line A",
                    vessel_name="Vessel 1",
                    sailing_date=crd + timedelta(days=1),
                    estimated_arrival_date=crd + timedelta(days=15),
                )
            ],
        )
        created = ShippingScenarioService.create_session_service(db, payload)

        # List check
        sessions = ShippingScenarioService.list_sessions_service(db, search="Initial")
        assert len(sessions) == 1
        assert sessions[0].session_id == created.session_id

        # Update check
        update_payload = ShippingEvaluationUpdate(
            title="Updated Study Title",
            avg_form4_days=8,
        )
        updated = ShippingScenarioService.update_session_service(
            db, created.session_id, update_payload
        )
        assert updated.title == "Updated Study Title"
        assert updated.avg_form4_days == 8

    def test_soft_delete_and_restore_shipping_evaluation(self, db: Session):
        crd = date.today()
        payload = ShippingEvaluationCreate(
            title="Delete Restore Study",
            cargo_ready_date=crd,
        )
        created = ShippingScenarioService.create_session_service(db, payload)

        # Soft delete
        del_res = ShippingScenarioService.soft_delete_service(db, created.session_id)
        assert "deactivated successfully" in del_res["message"]

        # Listed active only should not return it
        active_list = ShippingScenarioService.list_sessions_service(db, include_inactive=False)
        assert not any(s.session_id == created.session_id for s in active_list)

        # Restore
        restored = ShippingScenarioService.restore_service(db, created.session_id)
        assert restored.is_active is True
