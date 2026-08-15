from datetime import date, timedelta, datetime, timezone
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from main import app
from database.database import Base, get_db
from modules.import_files.model import ImportFile
from modules.import_documentation.model import AcidRegistrationSession
from modules.customs_clearance.model import CustomsClearanceRecord
from modules.import_documentation.service import get_acid_tracker_service


from sqlalchemy.pool import StaticPool

@pytest.fixture
def db_session():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
        echo=False,
    )
    Base.metadata.create_all(engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


def test_acid_tracker_statuses_and_release_alert_suppression(db_session):
    today = date.today()

    # 1. Active & Valid File
    file_valid = ImportFile(
        import_file_code="IMP-ACID-VALID-01",
        company_name="El-Araby Group",
        supplier_name="Samsung Korea",
        acid_number="1234567890123456789",
        acid_issue_date=today - timedelta(days=10),
        acid_expiry_date=today + timedelta(days=80),
        is_customs_released=False,
    )

    # 2. Expiring Soon File (<= 14 days)
    file_expiring = ImportFile(
        import_file_code="IMP-ACID-SOON-02",
        company_name="El-Araby Group",
        supplier_name="LG Electronics",
        acid_number="9876543210987654321",
        acid_issue_date=today - timedelta(days=80),
        acid_expiry_date=today + timedelta(days=10),
        is_customs_released=False,
    )

    # 3. Expired File (0 or negative days)
    file_expired = ImportFile(
        import_file_code="IMP-ACID-EXP-03",
        company_name="Fresh Electric",
        supplier_name="Media China",
        acid_number="1122334455667788990",
        acid_issue_date=today - timedelta(days=100),
        acid_expiry_date=today - timedelta(days=10),
        is_customs_released=False,
    )

    # 4. Customs Released File (Alert Suppressed even if expired/expiring)
    file_released = ImportFile(
        import_file_code="IMP-ACID-REL-04",
        company_name="Universal Group",
        supplier_name="Haier China",
        acid_number="9988776655443322110",
        acid_issue_date=today - timedelta(days=95),
        acid_expiry_date=today - timedelta(days=5),
        is_customs_released=True,
        customs_released_at=datetime.now(timezone.utc),
    )

    db_session.add_all([file_valid, file_expiring, file_expired, file_released])
    db_session.commit()

    summary = get_acid_tracker_service(db_session)
    items_by_code = {i.import_file_code: i for i in summary.items if i.import_file_code}

    # Check Valid item
    item_val = items_by_code.get("IMP-ACID-VALID-01")
    assert item_val is not None
    assert item_val.status == "Valid"
    assert item_val.alert_required is False
    assert item_val.days_remaining > 14

    # Check Expiring Soon item
    item_soon = items_by_code.get("IMP-ACID-SOON-02")
    assert item_soon is not None
    assert item_soon.status == "Expiring Soon"
    assert item_soon.alert_required is True
    assert item_soon.days_remaining == 10

    # Check Expired item
    item_exp = items_by_code.get("IMP-ACID-EXP-03")
    assert item_exp is not None
    assert item_exp.status == "Expired"
    assert item_exp.alert_required is True
    assert item_exp.days_remaining < 0

    # Check Customs Released item (Crucial business rule: Alert removed once released!)
    item_rel = items_by_code.get("IMP-ACID-REL-04")
    assert item_rel is not None
    assert item_rel.status == "Customs Released"
    assert item_rel.is_customs_released is True
    assert item_rel.alert_required is False


def test_acid_tracker_endpoint(db_session):
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    client = TestClient(app)

    file_valid = ImportFile(
        import_file_code="IMP-TRACKER-01",
        company_name="El-Araby Group",
        supplier_name="Samsung Korea",
        acid_number="1234567890123456789",
        acid_issue_date=date.today() - timedelta(days=10),
        acid_expiry_date=date.today() + timedelta(days=80),
        is_customs_released=False,
    )
    db_session.add(file_valid)
    db_session.commit()

    response = client.get("/api/v1/import-documentation/acid/tracker")
    assert response.status_code == 200
    data = response.json()
    assert "total_acids_count" in data
    assert "valid_count" in data
    assert "expiring_soon_count" in data
    assert "expired_count" in data
    assert "customs_released_count" in data
    assert len(data["items"]) >= 1

    app.dependency_overrides.clear()
