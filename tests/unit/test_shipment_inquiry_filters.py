import pytest
from datetime import date
from sqlalchemy.orm import Session

from database.database import get_db, SessionLocal
from modules.import_files.model import ImportFile
import modules.import_files.repository as repo
import modules.import_files.service as service


@pytest.fixture
def db_session():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def test_import_file_advanced_filters(db_session: Session):
    # Ensure at least one test shipment exists with known parameters
    test_code = "IMP-TEST-INQ-001"
    existing = db_session.query(ImportFile).filter(ImportFile.import_file_code == test_code).first()
    if not existing:
        test_file = ImportFile(
            import_file_code=test_code,
            company_name="SCAS Test Company",
            supplier_name="Vendor A (Italy)",
            shipment_mode="Sea FCL",
            incoterm_code="EXW",
            hs_code="680299",
            product_category="Wall Cladding",
            port_of_loading="Venice",
            port_of_discharge="Alexandria",
            selected_scenario="MSC Line",
            estimated_cost=2450.0,
            estimated_cost_currency="EUR",
            file_opening_date=date(2026, 5, 1),
            required_eta=date(2026, 6, 15),
            status="In Progress",
            owner="Kamal",
            notes="شحنة تجريبية لاختبار شاشة الاستعلام والتصفية",
            is_active=True,
        )
        db_session.add(test_file)
        db_session.commit()

    # 1. Filter by HS Code
    res_hs = repo.get_all_import_files(db_session, hs_code="6802")
    assert any(f.import_file_code == test_code for f in res_hs)

    # 2. Filter by Incoterm
    res_inco = repo.get_all_import_files(db_session, incoterm_code="EXW")
    assert any(f.import_file_code == test_code for f in res_inco)

    # 3. Filter by Ports
    res_ports = repo.get_all_import_files(
        db_session, port_of_loading="Venice", port_of_discharge="Alexandria"
    )
    assert any(f.import_file_code == test_code for f in res_ports)

    # 4. Filter by Carrier (selected_scenario)
    res_carrier = repo.get_all_import_files(db_session, carrier="MSC")
    assert any(f.import_file_code == test_code for f in res_carrier)

    # 5. Combined cumulative filter
    res_combined = repo.get_all_import_files(
        db_session,
        hs_code="6802",
        incoterm_code="EXW",
        port_of_loading="Venice",
        carrier="MSC",
    )
    assert any(f.import_file_code == test_code for f in res_combined)

    # 6. Negative match
    res_none = repo.get_all_import_files(db_session, hs_code="99999999")
    assert not any(f.import_file_code == test_code for f in res_none)
