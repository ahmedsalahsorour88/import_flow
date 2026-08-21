import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import main
from database.database import Base
from modules.import_documentation.model import (
    CertificateOfOriginReviewSession,
    InspectionCertificateReviewSession,
)
from modules.import_documentation.schemas import (
    CertificateOfOriginReviewCreate,
    InspectionCertificateReviewCreate,
)
from modules.import_documentation.service import (
    create_coo_review_service,
    create_inspection_review_service,
)
from modules.import_files.model import ImportFile


@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    TestingSession = sessionmaker(bind=engine)
    session = TestingSession()

    # Create dummy import file
    imp_file = ImportFile(
        import_file_id=1,
        import_file_code="IMP-2026-001",
        supplier_name="Global Tech",
        company_name="Al Ahly Import",
    )
    session.add(imp_file)
    session.commit()

    yield session
    session.close()


def test_coo_review_discrepancy_requires_override_reason(db_session):
    # Missing override_reason with discrepancies and approved status must raise 400
    schema = CertificateOfOriginReviewCreate(
        import_file_id=1,
        certificate_type="China Certificate of Origin (CCPIT)",
        certificate_number="CCPIT-9988",
        has_discrepancies=True,
        status="Discrepancy_Accepted",
        override_reason="",
        comparison_matrix=[{"field": "exporter_name", "match_status": "Mismatch"}],
    )
    with pytest.raises(HTTPException) as exc:
        create_coo_review_service(db_session, schema)
    assert exc.value.status_code == 400
    assert "سبب ومبررات الموافقة" in exc.value.detail


def test_coo_review_discrepancy_with_valid_reason_saves_and_updates_duplicate(db_session):
    # 1. First save with valid reason
    schema1 = CertificateOfOriginReviewCreate(
        import_file_id=1,
        certificate_type="China Certificate of Origin (CCPIT)",
        certificate_number="CCPIT-9988",
        has_discrepancies=True,
        status="Discrepancy_Accepted",
        override_reason="Approved by General Manager due to CCPIT trade endorsement",
        comparison_matrix=[{"field": "exporter_name", "match_status": "Mismatch"}],
        draft_input_data={"exporter_name": "Shenzhen Electric Co."},
    )
    saved1 = create_coo_review_service(db_session, schema1)
    assert saved1.coo_review_id is not None
    assert saved1.override_reason == "Approved by General Manager due to CCPIT trade endorsement"
    assert saved1.exporter_name == "Shenzhen Electric Co."

    # 2. Second save for same import_file_id should update rather than duplicate
    schema2 = CertificateOfOriginReviewCreate(
        import_file_id=1,
        certificate_type="China Certificate of Origin (CCPIT)",
        certificate_number="CCPIT-9988-V2",
        has_discrepancies=False,
        status="Verified",
        override_reason=None,
        comparison_matrix=[{"field": "exporter_name", "match_status": "Match"}],
    )
    saved2 = create_coo_review_service(db_session, schema2)
    assert saved2.coo_review_id == saved1.coo_review_id
    assert saved2.certificate_number == "CCPIT-9988-V2"

    total_sessions = db_session.query(CertificateOfOriginReviewSession).filter(CertificateOfOriginReviewSession.import_file_id == 1).count()
    assert total_sessions == 1


def test_inspection_review_discrepancy_requires_reason_and_updates_duplicate(db_session):
    # 1. Missing reason raises 400
    schema_err = InspectionCertificateReviewCreate(
        import_file_id=1,
        inspection_type="COC (Certificate of Conformity)",
        inspection_agency="SGS",
        certificate_number="SGS-001",
        has_discrepancies=True,
        status="Verified",
        override_reason=" ",
        comparison_matrix=[{"field": "acid", "match_status": "Mismatch"}],
    )
    with pytest.raises(HTTPException) as exc:
        create_inspection_review_service(db_session, schema_err)
    assert exc.value.status_code == 400

    # 2. Saving with reason succeeds
    schema_ok = InspectionCertificateReviewCreate(
        import_file_id=1,
        inspection_type="COC (Certificate of Conformity)",
        inspection_agency="SGS",
        certificate_number="SGS-001",
        has_discrepancies=True,
        status="Discrepancy_Accepted",
        override_reason="Physical test report verified by GOEIC approved laboratory",
        comparison_matrix=[{"field": "acid", "match_status": "Mismatch"}],
    )
    saved = create_inspection_review_service(db_session, schema_ok)
    assert saved.inspection_review_id is not None
    assert saved.override_reason == "Physical test report verified by GOEIC approved laboratory"

    # 3. Duplicate prevention update
    schema_update = InspectionCertificateReviewCreate(
        import_file_id=1,
        inspection_type="COC (Certificate of Conformity)",
        inspection_agency="TUV",
        certificate_number="TUV-002",
        has_discrepancies=False,
        status="Verified",
        comparison_matrix=[],
    )
    saved_up = create_inspection_review_service(db_session, schema_update)
    assert saved_up.inspection_review_id == saved.inspection_review_id
    assert saved_up.inspection_agency == "TUV"

    total_insp = db_session.query(InspectionCertificateReviewSession).filter(InspectionCertificateReviewSession.import_file_id == 1).count()
    assert total_insp == 1
