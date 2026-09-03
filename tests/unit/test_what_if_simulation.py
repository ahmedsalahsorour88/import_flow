"""
Unit Tests for Logistics What-If Simulator & FX Exposure Radar (SIM-WHATIF-013 & FIN-HEDGE-011)
"""

import pytest
from datetime import datetime, date, timedelta
from fastapi.testclient import TestClient

from main import app
from database.database import get_db, Base, engine, SessionLocal
from modules.simulation.schemas import WhatIfSimulationRequest, SavedScenarioCreate
from modules.simulation import service, repository
from modules.import_files.model import ImportFile


@pytest.fixture(scope="module")
def client():
    # Ensure tables created
    Base.metadata.create_all(bind=engine)
    with TestClient(app) as c:
        yield c


@pytest.fixture(scope="module")
def db_session():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


class TestWhatIfSimulation:
    def test_fx_rate_devaluation_scenario(self, db_session):
        """Test +20% USD devaluation shock on CIF, Customs Duty, VAT, and Landed Cost."""
        req = WhatIfSimulationRequest(
            invoice_amount=10000.0,
            currency="USD",
            base_exchange_rate=50.0,
            exchange_rate_change_pct=20.0,  # 50 -> 60 EGP
            freight_fcy=1000.0,
            insurance_fcy=200.0,
            shipping_route="RED_SEA",
            duty_rate_pct=10.0,
            vat_rate_pct=14.0,
        )

        res = service.run_what_if_simulation_service(db=db_session, request=req)

        # Baseline CIF = (10000 + 1000 + 200) * 50 = 11,200 * 50 = 560,000 EGP
        assert res["baseline_summary"]["cif_egp"] == 560000.0
        # Simulated rate = 60.0 EGP -> Simulated CIF = 11,200 * 60 = 672,000 EGP
        assert res["simulated_summary"]["exchange_rate"] == 60.0
        assert res["simulated_summary"]["cif_egp"] == 672000.0

        # Baseline Duty = 560,000 * 10% = 56,000 EGP
        assert res["customs_breakdown"]["baseline_duty_egp"] == 56000.0
        # Simulated Duty = 672,000 * 10% = 67,200 EGP
        assert res["customs_breakdown"]["simulated_duty_egp"] == 67200.0

        # Variance
        assert res["variances"]["cif_variance_egp"] == 112000.0
        assert res["variances"]["customs_duty_variance_egp"] == 11200.0
        assert res["variances"]["landed_cost_variance_pct"] > 15.0
        assert res["risk_level"] in ["MEDIUM", "HIGH", "CRITICAL"]
        assert len(res["hedging_recommendations"]) > 0

    def test_cape_of_good_hope_and_acid_expiry(self, db_session):
        """Test Cape of Good Hope reroute (+18 days & +25% freight) and ACID expiry check."""
        today = date.today()
        # ACID issued 170 days ago (only 10 days left on 180-day window)
        acid_issuance = (today - timedelta(days=170)).isoformat()
        current_eta = (today + timedelta(days=5)).isoformat()

        # Cape reroute adds 18 days -> Arrival in 23 days -> Exceeds 180 days!
        req = WhatIfSimulationRequest(
            invoice_amount=20000.0,
            currency="USD",
            base_exchange_rate=50.0,
            exchange_rate_change_pct=0.0,
            freight_fcy=2000.0,
            shipping_route="CAPE_OF_GOOD_HOPE",
            acid_issuance_date=acid_issuance,
            current_eta=current_eta,
        )

        res = service.run_what_if_simulation_service(db=db_session, request=req)

        # Extra transit days
        assert res["simulated_summary"]["total_extra_transit_days"] == 18
        # Freight Bunker Adjustment Factor (+25% on $2,000 = $2,500)
        assert res["simulated_summary"]["cif_fcy"] == 22500.0

        # ACID status must be EXPIRED_RISK
        acid_eval = res["acid_risk_analysis"]
        assert acid_eval["status"] == "EXPIRED_RISK"
        assert "خطر جسيم" in acid_eval["message_ar"]
        assert res["risk_level"] == "CRITICAL"

        # Safe scenario
        req_safe = WhatIfSimulationRequest(
            invoice_amount=20000.0,
            currency="USD",
            base_exchange_rate=50.0,
            acid_issuance_date=(today - timedelta(days=20)).isoformat(),
            current_eta=(today + timedelta(days=30)).isoformat(),
            shipping_route="RED_SEA",
        )
        res_safe = service.run_what_if_simulation_service(db=db_session, request=req_safe)
        assert res_safe["acid_risk_analysis"]["status"] == "SAFE"

    def test_dual_clock_demurrage_and_port_storage(self, db_session):
        """Test dual-clock calculations for 20 days port delay with 2 containers."""
        req = WhatIfSimulationRequest(
            invoice_amount=50000.0,
            currency="USD",
            base_exchange_rate=50.0,
            port_storage_delay_days=20,
            container_count=2,
        )

        res = service.run_what_if_simulation_service(db=db_session, request=req)

        dem_info = res["demurrage_and_storage"]
        # Demurrage: free 14 days -> 6 days extra * $50 * 2 ctrs = $600 USD
        assert dem_info["extra_demurrage_days"] == 6
        assert dem_info["demurrage_cost_usd"] == 600.0

        # Port storage: free 4 days -> 16 days extra
        # Tier 1 (days 1-7 = 7 days): 7 * 350 * 2 = 4,900
        # Tier 2 (days 8-15 = 8 days): 8 * 750 * 2 = 12,000
        # Tier 3 (day 16 = 1 day): 1 * 1400 * 2 = 2,800
        # Total = 4,900 + 12,000 + 2,800 = 19,700 EGP
        assert dem_info["extra_port_storage_days"] == 16
        assert dem_info["port_storage_cost_egp"] == 19700.0

    def test_calculate_open_fx_exposure(self, db_session):
        """Test open foreign currency exposure and 10%/25% Value-at-Risk."""
        # Create a test active import file
        test_file = ImportFile(
            import_file_code="SIM-TEST-001",
            company_name="Test Importer LLC",
            supplier_name="Test Foreign Supplier",
            estimated_cost=25000.0,
            estimated_cost_currency="USD",
            status="In Progress",
            is_active=True,
        )
        db_session.add(test_file)
        db_session.commit()
        db_session.refresh(test_file)

        res = service.calculate_open_fx_exposure_service(db=db_session)
        assert res["total_open_usd"] >= 25000.0
        assert res["total_open_egp_baseline"] > 0
        assert res["total_open_egp_plus_10_pct"] > res["total_open_egp_baseline"]
        assert res["var_at_risk_10_pct"] > 0
        assert len(res["strategic_advice"]) > 0

    def test_simulation_api_endpoints(self, client):
        """Test FastAPI endpoints for simulation and saved scenarios."""
        # 1. POST /api/v1/simulation/what-if
        payload = {
            "invoice_amount": 15000.0,
            "currency": "EUR",
            "base_exchange_rate": 54.0,
            "exchange_rate_change_pct": 10.0,
            "freight_fcy": 1200.0,
            "shipping_route": "RED_SEA",
            "port_storage_delay_days": 5,
            "container_count": 1,
            "duty_rate_pct": 5.0,
            "vat_rate_pct": 14.0,
        }
        resp = client.post("/api/v1/simulation/what-if", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["simulated_summary"]["exchange_rate"] == 59.4
        assert data["risk_level"] in ["LOW", "MEDIUM", "HIGH", "CRITICAL"]

        # Validation error test: extreme rate change
        invalid_payload = {**payload, "exchange_rate_change_pct": 300.0}
        bad_resp = client.post("/api/v1/simulation/what-if", json=invalid_payload)
        assert bad_resp.status_code == 400

        # 2. GET /api/v1/simulation/fx-exposure
        exp_resp = client.get("/api/v1/simulation/fx-exposure")
        assert exp_resp.status_code == 200
        exp_data = exp_resp.json()
        assert "total_open_usd" in exp_data

        # 3. POST /api/v1/simulation/saved-scenarios
        save_payload = {
            "scenario_name": "Executive EUR What-If Scenario Q4",
            "simulation_request": payload,
            "simulation_result": data,
        }
        save_resp = client.post("/api/v1/simulation/saved-scenarios", json=save_payload)
        assert save_resp.status_code == 201
        saved_data = save_resp.json()
        assert saved_data["scenario_id"] > 0
        assert saved_data["scenario_name"] == "Executive EUR What-If Scenario Q4"

        # 4. GET /api/v1/simulation/saved-scenarios
        list_resp = client.get("/api/v1/simulation/saved-scenarios")
        assert list_resp.status_code == 200
        items = list_resp.json()
        assert len(items) >= 1
        assert items[0]["scenario_name"] == "Executive EUR What-If Scenario Q4"
