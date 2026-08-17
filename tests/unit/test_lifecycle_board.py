"""
Unit Tests for Shipment Stage Activity & 6-Phase Lifecycle Board
"""

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from database.database import Base
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.external_service_providers.model import ExternalServiceProvider
from modules.import_files.model import ImportFile
from modules.lifecycle_board.model import ShipmentStageActivity
import modules.lifecycle_board.service as service
import modules.lifecycle_board.repository as repo
from modules.lifecycle_board.schemas import StepAdvancePayload, MultiStageSetPayload


@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(bind=engine)
    Session = sessionmaker(bind=engine)
    session = Session()

    # Seed an import file
    file1 = ImportFile(
        import_file_code="IMP-2026-0001",
        company_name="Al-Ahram Industrial",
        supplier_name="Global Steel Italy",
        po_number="PO-2026-101",
        shipment_mode="Sea FCL",
        incoterm_code="FOB",
        priority="High",
        estimated_cost=45000.0,
        estimated_cost_currency="USD",
        status="Draft",
        is_active=True,
    )
    session.add(file1)
    session.commit()

    yield session
    session.close()


def test_board_summary_generation(db_session):
    summary = service.get_board_summary_service(db_session)
    assert len(summary.phases) == 6
    assert summary.total_active_files >= 1
    assert summary.phases[0].phase_id == 1
    assert summary.phases[0].title_en == "1. Pre-Planning & Studies"


def test_set_multi_active_stages(db_session):
    payload = MultiStageSetPayload(
        import_file_code="IMP-2026-0001",
        active_step_codes=["STEP_01", "STEP_02", "STEP_03"],
        notes="Multiple studies concurrently",
    )
    res = service.set_multi_active_stages_service(db_session, payload)
    assert len(res["active_steps"]) == 3

    # Check repository
    acts = repo.get_all_activities(db_session, import_file_code="IMP-2026-0001", status="In-Progress")
    assert len(acts) == 3


def test_advance_step_service(db_session):
    # Set step 1
    repo.save_or_update_activity(
        db_session,
        import_file_code="IMP-2026-0001",
        step_code="STEP_01",
        status="In-Progress",
    )

    # Advance to step 4
    advance_payload = StepAdvancePayload(
        import_file_code="IMP-2026-0001",
        current_step_code="STEP_01",
        next_step_codes=["STEP_04"],
        notes="Freight study MSC approved, moving to finance",
    )
    res = service.advance_step_service(db_session, advance_payload)
    assert res["completed_step"] == "STEP_01"
    assert res["activated_steps"] == ["STEP_04"]

    step1 = repo.get_activity(db_session, "IMP-2026-0001", "STEP_01")
    assert step1.status == "Completed"

    step4 = repo.get_activity(db_session, "IMP-2026-0001", "STEP_04")
    assert step4.status == "In-Progress"
