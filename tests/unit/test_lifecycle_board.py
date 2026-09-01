"""
Unit Tests for Shipment Stage Activity & 6-Phase Lifecycle Board
"""

import main
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
from modules.lifecycle_board.schemas import StepAdvancePayload, SkipStepPayload, MultiStageSetPayload


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


def test_skip_step_service(db_session):
    # Set step 6 (Freight booking)
    repo.save_or_update_activity(
        db_session,
        import_file_code="IMP-2026-0001",
        step_code="STEP_06",
        status="In-Progress",
    )

    # Skip step 6 because terms are CIF (freight handled by supplier) and advance to STEP_08 (Draft Docs Review)
    skip_payload = SkipStepPayload(
        import_file_code="IMP-2026-0001",
        current_step_code="STEP_06",
        skip_reason="شحنة بنظام CIF - النولون مسدد ومحجوز من المورد الأجنبي",
        next_step_codes=["STEP_08"],
    )
    res = service.skip_step_service(db_session, skip_payload)
    assert res["skipped_step"] == "STEP_06"
    assert res["activated_steps"] == ["STEP_08"]

    step6 = repo.get_activity(db_session, "IMP-2026-0001", "STEP_06")
    assert step6.status == "Skipped"
    assert "CIF" in step6.notes

    step8 = repo.get_activity(db_session, "IMP-2026-0001", "STEP_08")
    assert step8.status == "In-Progress"

    # Check that ImportFile has STEP_06 in skipped_stages
    file1 = db_session.query(ImportFile).filter(ImportFile.import_file_code == "IMP-2026-0001").first()
    assert "STEP_06" in file1.skipped_stages


def test_initialize_file_lifecycle_service_from_custom_step(db_session):
    # Initialize a new shipment file starting from STEP_13 (Customs Clearance Declaration 46)
    service.initialize_file_lifecycle_service(db_session, "IMP-2026-0001", starting_step="STEP_13")

    # Verify that prior steps 1..12 are marked Completed
    for i in range(1, 13):
        code = f"STEP_{str(i).zfill(2)}"
        act = repo.get_activity(db_session, "IMP-2026-0001", code)
        assert act is not None
        assert act.status == "Completed"

    # Verify that STEP_13 is In-Progress
    step13 = repo.get_activity(db_session, "IMP-2026-0001", "STEP_13")
    assert step13 is not None
    assert step13.status == "In-Progress"


def test_hold_and_resume_activities(db_session):
    # Set step 13 In-Progress
    repo.save_or_update_activity(
        db_session,
        import_file_code="IMP-2026-0001",
        step_code="STEP_13",
        status="In-Progress",
    )

    # Hold shipment
    service.hold_shipment_activities_service(db_session, "IMP-2026-0001", "في انتظار موافقة هيئة الرقابة على الصادرات والواردات")
    step13 = repo.get_activity(db_session, "IMP-2026-0001", "STEP_13")
    assert step13.status == "On-Hold"
    assert "في انتظار موافقة" in step13.notes

    # Resume shipment
    service.resume_shipment_activities_service(db_session, "IMP-2026-0001", "تم صدور الموافقة الرقابية")
    step13_resumed = repo.get_activity(db_session, "IMP-2026-0001", "STEP_13")
    assert step13_resumed.status == "In-Progress"
    assert "تم صدور الموافقة" in step13_resumed.notes


def test_previous_and_next_step_tracking(db_session):
    # Set STEP_02 as current active step for IMP-2026-0001
    repo.save_or_update_activity(
        db_session,
        import_file_code="IMP-2026-0001",
        step_code="STEP_01",
        status="Completed",
        completed_at="2026-08-31 10:00:00",
    )
    repo.save_or_update_activity(
        db_session,
        import_file_code="IMP-2026-0001",
        step_code="STEP_02",
        status="In-Progress",
        started_at="2026-08-31 10:05:00",
    )

    summary = service.get_board_summary_service(db_session)
    matching = [s for s in summary.all_shipments if s.import_file_code == "IMP-2026-0001"]
    assert len(matching) == 1
    card = matching[0]

    # Verify Previous, Current, and Next steps
    assert card.step_code == "STEP_02"
    assert card.step_name_ar == "الدراسات والاستشارات الجمركية"
    assert card.previous_step_code == "STEP_01"
    assert card.previous_step_name_ar == "دراسات ومفاضلة نولون الشحن"
    assert card.next_step_code == "STEP_03"
    assert card.next_step_name_ar == "متطلبات واشتراطات الاستيراد للشحنة"


def test_sync_consultation_lifecycle_stage(db_session):
    file1 = db_session.query(ImportFile).filter(ImportFile.import_file_code == "IMP-2026-0001").first()
    assert file1 is not None

    # Call sync
    service.sync_consultation_lifecycle_stage(db_session, file1.import_file_id)

    # Check that STEP_01 is Completed and STEP_02 is In-Progress
    step1 = repo.get_activity(db_session, "IMP-2026-0001", "STEP_01")
    assert step1.status == "Completed"

    step2 = repo.get_activity(db_session, "IMP-2026-0001", "STEP_02")
    assert step2.status == "In-Progress"

    # Check that ImportFile next action points to STEP_03
    db_session.refresh(file1)
    assert "STEP_02" in file1.current_module
    assert "STEP_03" in file1.next_action
