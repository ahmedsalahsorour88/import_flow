"""
Unit Tests for Task DC-02: ACID Expiry Radar Tracking & Release Hard-Block
(رادار تتبع صلاحية ACID وتنبيه الـ 14 يوماً وحظر الإفراج)
Stage 3: Documentation, Nafeza & ACID Operations (BP-014 / ACID-002)
"""

import pytest
from datetime import date, timedelta, datetime, timezone
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient
from fastapi import HTTPException

from database.database import Base, get_db
from main import app

from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.projects.model import Project
from modules.incoterms.model import Incoterm
from modules.import_files.model import ImportFile
from modules.customs_clearance.model import CustomsClearanceRecord
from modules.customs_clearance.schemas import CompleteReleaseSubmit
from modules.customs_clearance.service import complete_customs_release_service
from modules.import_documentation.model import AcidRegistrationSession
from modules.import_documentation.service import get_acid_tracker_service
from modules.notifications.expiry_checker import ExpiryCheckerService
from modules.notifications.model import SystemNotification
from sqlalchemy.pool import StaticPool


@pytest.fixture
def db_session():
    """Sets up an isolated SQLite in-memory database."""
    engine = create_engine(
        "sqlite:///:memory:",
        echo=False,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    TestingSession = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = TestingSession()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture
def seed_radar_data(db_session):
    """Seeds baseline data for radar testing across all 4 operational states."""
    today = date.today()

    # 1. Valid (> 14 days)
    file_valid = ImportFile(
        import_file_id=1,
        import_file_code="IMP-2026-VAL-01",
        custom_file_number="RADAR-01",
        company_name="Delta Industrial Manufacturing SAE",
        supplier_name="Shanghai Extrusion Machinery",
        acid_number="1000000000000000001",
        acid_issue_date=today - timedelta(days=20),
        acid_expiry_date=today + timedelta(days=70),
        acid_execution_days=3,
        is_customs_released=False,
        is_active=True,
    )

    # 2. Expiring Soon (<= 14 days)
    file_expiring = ImportFile(
        import_file_id=2,
        import_file_code="IMP-2026-SOON-02",
        custom_file_number="RADAR-02",
        company_name="Delta Industrial Manufacturing SAE",
        supplier_name="Bavaria Chemical Supplies",
        acid_number="2000000000000000002",
        acid_issue_date=today - timedelta(days=80),
        acid_expiry_date=today + timedelta(days=10),
        acid_execution_days=4,
        is_customs_released=False,
        is_active=True,
    )

    # 3. Expired (<= 0 days)
    file_expired = ImportFile(
        import_file_id=3,
        import_file_code="IMP-2026-EXP-03",
        custom_file_number="RADAR-03",
        company_name="Delta Industrial Manufacturing SAE",
        supplier_name="Tokyo High Precision Tools",
        acid_number="3000000000000000003",
        acid_issue_date=today - timedelta(days=110),
        acid_expiry_date=today - timedelta(days=10),
        acid_execution_days=5,
        is_customs_released=False,
        is_active=True,
    )

    # 4. Customs Released (Auto-Suppressed)
    file_released = ImportFile(
        import_file_id=4,
        import_file_code="IMP-2026-REL-04",
        custom_file_number="RADAR-04",
        company_name="Delta Industrial Manufacturing SAE",
        supplier_name="Milan Packaging Group",
        acid_number="4000000000000000004",
        acid_issue_date=today - timedelta(days=100),
        acid_expiry_date=today - timedelta(days=10),
        acid_execution_days=2,
        is_customs_released=True,
        customs_released_at=datetime.now(timezone.utc),
        is_active=True,
    )

    db_session.add_all([file_valid, file_expiring, file_expired, file_released])
    db_session.commit()

    return {
        "valid": file_valid,
        "expiring": file_expiring,
        "expired": file_expired,
        "released": file_released,
    }


def test_acid_tracker_status_classification_and_kpis(db_session, seed_radar_data):
    """
    Rule ACID-001 & ACID-002:
    Verifies that the ACID tracker correctly categorizes:
    - Valid (> 14 days)
    - Expiring Soon (<= 14 days, alert=True)
    - Expired (<= 0 days, alert=True)
    - Customs Released (alert=False)
    """
    summary = get_acid_tracker_service(db_session)
    assert summary.total_acids_count == 4
    assert summary.valid_count == 1
    assert summary.expiring_soon_count == 1
    assert summary.expired_count == 1
    assert summary.customs_released_count == 1

    items_map = {item.import_file_code: item for item in summary.items if item.import_file_code}

    # 1. Valid Check
    item_val = items_map["IMP-2026-VAL-01"]
    assert item_val.status == "Valid"
    assert item_val.alert_required is False
    assert item_val.days_remaining > 14

    # 2. Expiring Soon Check
    item_soon = items_map["IMP-2026-SOON-02"]
    assert item_soon.status == "Expiring Soon"
    assert item_soon.alert_required is True
    assert item_soon.days_remaining == 10

    # 3. Expired Check
    item_exp = items_map["IMP-2026-EXP-03"]
    assert item_exp.status == "Expired"
    assert item_exp.alert_required is True
    assert item_exp.days_remaining < 0

    # 4. Customs Released Check (Auto-Suppression)
    item_rel = items_map["IMP-2026-REL-04"]
    assert item_rel.status == "Customs Released"
    assert item_rel.alert_required is False
    assert item_rel.is_customs_released is True


def test_customs_release_hard_block_on_expired_acid(db_session, seed_radar_data):
    """
    DC-02 Business Rule:
    Strictly blocks final customs release (HTTP 400) if the shipment's ACID is expired.
    """
    expired_file = seed_radar_data["expired"]

    # Create customs clearance record for expired file
    clearance_rec = CustomsClearanceRecord(
        customs_clearance_id=1,
        clearance_code="CLR-2026-001",
        import_file_id=expired_file.import_file_id,
        declaration_46_no="DECL46-990011",
        payment_status="Paid & Verified",
        status="Under Inspection",
        is_active=True,
    )
    db_session.add(clearance_rec)
    db_session.commit()

    payload = CompleteReleaseSubmit(
        release_permit_no="PERMIT-EG-7788",
        release_date=datetime.now(timezone.utc),
        dispatch_authorized=True,
    )

    # Attempting release on expired ACID must raise HTTPException with status 400
    with pytest.raises(HTTPException) as exc_info:
        complete_customs_release_service(db_session, 1, payload)

    assert exc_info.value.status_code == 400
    assert "حظر الإفراج الجمركي" in exc_info.value.detail
    assert "منتهي الصلاحية" in exc_info.value.detail


def test_customs_release_allowed_with_valid_acid(db_session, seed_radar_data):
    """
    Verifies that shipments with a valid ACID are permitted to complete customs release.
    """
    valid_file = seed_radar_data["valid"]

    clearance_rec = CustomsClearanceRecord(
        customs_clearance_id=2,
        clearance_code="CLR-2026-002",
        import_file_id=valid_file.import_file_id,
        declaration_46_no="DECL46-990022",
        payment_status="Paid & Verified",
        status="Under Inspection",
        is_active=True,
    )
    db_session.add(clearance_rec)
    db_session.commit()

    payload = CompleteReleaseSubmit(
        release_permit_no="PERMIT-EG-9955",
        release_date=datetime.now(timezone.utc),
        dispatch_authorized=True,
    )

    updated = complete_customs_release_service(db_session, 2, payload)
    assert updated.status == "Final Release Granted"
    assert updated.release_permit_no == "PERMIT-EG-9955"

    # Verify import file release synchronization
    db_session.refresh(valid_file)
    assert valid_file.is_customs_released is True


def test_expiry_checker_proactive_notifications(db_session, seed_radar_data):
    """
    Verifies ExpiryCheckerService automatically creates notifications for files approaching expiry:
    - Generates alert for Expiring Soon file (<= 14 days).
    - Generates critical alert for Expired file.
    - Suppresses alert for Customs Released file.
    """
    checker = ExpiryCheckerService(db_session)
    notifs = checker.check_all_expiries()

    acid_notifs = [n for n in notifs if n.category == "ACID_EXPIRY"]
    assert len(acid_notifs) >= 2

    # Check that released file did NOT get an expiry alert
    released_notifs = [n for n in acid_notifs if n.entity_id == 4]
    assert len(released_notifs) == 0


def test_api_acid_tracker_endpoint(db_session, seed_radar_data):
    """Verifies GET /api/v1/import-documentation/acid/tracker endpoint."""
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    client = TestClient(app)

    res = client.get("/api/v1/import-documentation/acid/tracker")
    assert res.status_code == 200
    data = res.json()
    assert "total_acids_count" in data
    assert data["total_acids_count"] == 4
    assert data["valid_count"] == 1
    assert data["expiring_soon_count"] == 1
    assert data["expired_count"] == 1
    assert data["customs_released_count"] == 1
    assert len(data["items"]) == 4

    app.dependency_overrides.clear()
