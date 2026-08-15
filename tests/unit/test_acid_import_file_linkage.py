"""
Unit tests for ACID number linkage to ImportFile with execution days and validity dates (BP-014 / Import Documentation).
Verifies:
1. Linking issued 19-digit ACID Number with its corresponding ImportFile.
2. Automated calculation of execution days (requested_date to generated_date).
3. Two-way synchronization of acid_number, acid_request_date, acid_issue_date, acid_expiry_date, and acid_execution_days.
4. ACID Tracker reflects linked files with correct execution days and remaining validity days.
"""

import pytest
from datetime import date, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.external_service_providers.model import ExternalServiceProvider
from modules.transport_locations.model import TransportLocation
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.projects.model import Project
from modules.incoterms.model import Incoterm
from modules.currencies.model import Currency
from modules.customs_tariff.model import CustomsTariff
from modules.purchase_orders.model import PurchaseOrder
from modules.customs_clearance.model import CustomsClearanceRecord
from modules.import_files.model import ImportFile
from modules.import_documentation.model import AcidRegistrationSession, BankingDocumentSession
from modules.import_documentation.schemas import AcidRegistrationCreate, AcidRegistrationUpdate
from modules.import_documentation.service import (
    create_acid_session_service,
    update_acid_session_service,
    get_acid_tracker_service,
)


@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()

    # Create dummy import files
    imp1 = ImportFile(
        import_file_id=1,
        import_file_code="IMP-2026-0001",
        custom_file_number="SHIP-001",
        company_name="El-Nasr Trading Co.",
        supplier_name="Shenzhen Electronics Ltd",
        po_number="PO-2026-101",
        pi_number="PI-9901",
        shipment_mode="Sea FCL",
        estimated_cost=65000.0,
        current_stage="Phase 3 - Import Documentation",
        is_active=True,
    )
    session.add(imp1)
    session.commit()

    yield session
    session.close()


def test_acid_linkage_and_execution_days_calculation(db_session):
    """
    Test creating an ACID session linked to an ImportFile:
    - Verifies execution_days is calculated: (generated_date - requested_date).days
    - Verifies ImportFile fields are synchronized automatically.
    """
    req_date = date(2026, 8, 1)
    gen_date = date(2026, 8, 4) # 3 days execution
    exp_date = date(2026, 11, 29) # ~120 days validity

    schema = AcidRegistrationCreate(
        import_file_id=1,
        acid_number="2001830441013710010",
        importer_name="El-Nasr Trading Co.",
        importer_tax_id="100200300",
        exporter_name="Shenzhen Electronics Ltd",
        exporter_reg_id="CN-998877",
        exporter_country="China",
        proforma_invoice_no="PI-9901",
        pol_name="Shanghai Port",
        pod_name="Alexandria Port",
        requested_date=req_date,
        generated_date=gen_date,
        expiry_date=exp_date,
    )

    response = create_acid_session_service(db_session, schema)

    # 1. Check Acid Session Response
    assert response.acid_number == "2001830441013710010"
    assert response.execution_days == 3
    assert response.expiry_date == exp_date
    assert response.import_file_code == "IMP-2026-0001"

    # 2. Check ImportFile synchronization
    imp = db_session.query(ImportFile).filter(ImportFile.import_file_id == 1).first()
    assert imp is not None
    assert imp.acid_number == "2001830441013710010"
    assert imp.acid_request_date == req_date
    assert imp.acid_issue_date == gen_date
    assert imp.acid_expiry_date == exp_date
    assert imp.acid_execution_days == 3


def test_acid_update_recalculates_and_resyncs(db_session):
    """
    Test updating an ACID session (e.g. from PENDING to issued with generated date):
    - Recalculates execution_days.
    - Synchronizes updated dates to the ImportFile.
    """
    # Start as pending request
    req_date = date(2026, 8, 1)
    exp_date = date(2026, 11, 29)

    schema = AcidRegistrationCreate(
        import_file_id=1,
        acid_number="PENDING",
        importer_name="El-Nasr Trading Co.",
        importer_tax_id="100200300",
        exporter_name="Shenzhen Electronics Ltd",
        exporter_reg_id="CN-998877",
        exporter_country="China",
        proforma_invoice_no="PI-9901",
        pol_name="Shanghai Port",
        pod_name="Alexandria Port",
        requested_date=req_date,
        generated_date=None,
        expiry_date=exp_date,
    )
    initial_res = create_acid_session_service(db_session, schema)
    assert initial_res.acid_number == "PENDING"
    assert initial_res.execution_days is None

    # Now update with issued 19-digit ACID and generated_date
    gen_date = date(2026, 8, 6) # 5 days execution
    new_exp_date = date(2026, 12, 1)

    update_schema = AcidRegistrationUpdate(
        acid_number="2001830441013710010",
        generated_date=gen_date,
        expiry_date=new_exp_date,
    )
    updated_res = update_acid_session_service(db_session, initial_res.acid_id, update_schema)

    assert updated_res.acid_number == "2001830441013710010"
    assert updated_res.execution_days == 5

    # Check ImportFile synchronization
    imp = db_session.query(ImportFile).filter(ImportFile.import_file_id == 1).first()
    assert imp.acid_number == "2001830441013710010"
    assert imp.acid_request_date == req_date
    assert imp.acid_issue_date == gen_date
    assert imp.acid_expiry_date == new_exp_date
    assert imp.acid_execution_days == 5


def test_acid_tracker_service_reports_linked_file_and_execution_days(db_session):
    """
    Test that get_acid_tracker_service returns the linked import file, execution days, and expiry dates.
    """
    req_date = date(2026, 8, 1)
    gen_date = date(2026, 8, 3) # 2 days execution
    exp_date = date(2026, 11, 29)

    schema = AcidRegistrationCreate(
        import_file_id=1,
        acid_number="2001830441013710010",
        importer_name="El-Nasr Trading Co.",
        importer_tax_id="100200300",
        exporter_name="Shenzhen Electronics Ltd",
        exporter_reg_id="CN-998877",
        exporter_country="China",
        proforma_invoice_no="PI-9901",
        pol_name="Shanghai Port",
        pod_name="Alexandria Port",
        requested_date=req_date,
        generated_date=gen_date,
        expiry_date=exp_date,
    )
    create_acid_session_service(db_session, schema)

    tracker = get_acid_tracker_service(db_session)
    assert tracker.total_acids_count >= 1
    item = next((i for i in tracker.items if i.acid_number == "2001830441013710010"), None)
    assert item is not None
    assert item.import_file_id == 1
    assert item.execution_days == 2
    assert item.acid_expiry_date == exp_date
    assert item.status == "Valid"
