import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
import main # Import main to register all SQLAlchemy models in Base.metadata
from database.database import Base, get_db
from main import app

engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.create_all(bind=engine)
    app.dependency_overrides[get_db] = override_get_db
    yield
    Base.metadata.drop_all(bind=engine)
    app.dependency_overrides.clear()

client = TestClient(app)


def test_create_assessment_success():
    payload = {
        "shipment_value_usd": 1000.5,
        "coo_required": True,
        "coo_status": "Pending",
        "overall_status": "Draft",
        "risk_level": "Low"
    }
    response = client.post("/api/v1/import-requirements", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["assessment_code"].startswith("BP011-")
    assert data["shipment_value_usd"] == 1000.5
    assert data["coo_required"] is True
    assert data["coo_status"] == "Pending"
    assert data["risk_level"] == "Low"


def test_update_coo_status():
    payload = {
        "shipment_value_usd": 500,
        "overall_status": "Draft",
        "risk_level": "Medium"
    }
    response = client.post("/api/v1/import-requirements", json=payload)
    assert response.status_code == 201
    assessment_id = response.json()["assessment_id"]

    update_payload = {
        "coo_status": "Obtained"
    }
    update_res = client.put(f"/api/v1/import-requirements/{assessment_id}", json=update_payload)
    assert update_res.status_code == 200
    assert update_res.json()["coo_status"] == "Obtained"


def test_invalid_risk_level_raises_error():
    payload = {
        "shipment_value_usd": 100,
        "risk_level": "InvalidRisk"
    }
    response = client.post("/api/v1/import-requirements", json=payload)
    assert response.status_code == 422


def test_soft_delete_assessment():
    payload = {
        "shipment_value_usd": 200,
        "overall_status": "Draft",
        "risk_level": "Low"
    }
    response = client.post("/api/v1/import-requirements", json=payload)
    assert response.status_code == 201
    assessment_id = response.json()["assessment_id"]

    delete_res = client.delete(f"/api/v1/import-requirements/{assessment_id}")
    assert delete_res.status_code == 204

    get_res = client.get(f"/api/v1/import-requirements/{assessment_id}")
    assert get_res.status_code == 404


def test_create_full_5_pillars_assessment():
    payload = {
        "hs_code": "8415820010",
        "commodity_description": "Air Conditioning Units",
        "country_of_origin": "China",
        "shipment_value_usd": 65000.0,
        # Pillar 1
        "decree_43_applicable": True,
        "white_list_required": True,
        "white_list_verified": True,
        "factory_registration_no": "GOEIC-REG-12345",
        "supplier_name": "Gree Electric Appliances",
        # Pillar 2
        "coo_required": True,
        "coo_type": "EUR.1",
        "coo_status": "Obtained",
        "coo_notes": "100% duty reduction under agreement",
        # Pillar 3
        "inspection_required": True,
        "inspection_body": "SGS",
        "inspection_status": "Completed",
        "inspection_report_no": "SGS-2026-9900",
        # Pillar 4
        "import_permit_required": True,
        "permit_issuing_authority": "EEAA",
        "permit_number": "EEAA-9988",
        "permit_status": "Approved",
        # Pillar 5
        "msds_required": True,
        "msds_status": "Obtained",
        "coa_required": True,
        "coa_status": "Obtained",
        # Summary
        "overall_status": "Complete",
        "risk_level": "Low",
        "assessed_by": "Kamal"
    }
    response = client.post("/api/v1/import-requirements", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["factory_registration_no"] == "GOEIC-REG-12345"
    assert data["inspection_report_no"] == "SGS-2026-9900"
    assert data["permit_number"] == "EEAA-9988"
    assert data["decree_43_applicable"] is True
    assert data["white_list_verified"] is True
    assert data["coa_required"] is True
    assert data["overall_status"] == "Complete"

