import pytest
from datetime import datetime, timezone, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.import_files.model import ImportFile
from modules.original_documents_collection.model import OriginalDocumentsCollectionSession
from modules.original_documents_collection.service import OriginalDocumentsCollectionService
from modules.original_documents_collection.schemas import (
    CourierReceiptProofRequest,
    OriginalDocumentsCollectionCreate,
    CourierEntry,
    OriginalDocumentItem,
)
from modules.cargox.schemas import CargoXEnvelopeCreate
from modules.cargox.service import CargoXService


@pytest.fixture
def db():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(bind=engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()


def test_confirm_courier_receipt_updates_courier_and_docs(db):
    # Setup ImportFile
    file = ImportFile(
        import_file_code="IMP-2026-TEST1",
        acid_number="1234567890123456789",
        company_name="Test Importer LLC",
        supplier_name="Test Supplier GmbH",
    )
    db.add(file)
    db.commit()

    # Create Session with 2 couriers and 2 documents
    payload = OriginalDocumentsCollectionCreate(
        import_file_id=file.import_file_id,
        import_file_code=file.import_file_code,
        acid_number=file.acid_number,
        importer_name="Test Importer LLC",
        supplier_name="Test Supplier GmbH",
        status="DRAFT",
        couriers_list=[
            CourierEntry(
                courier_no="DHL-981245",
                courier_company="DHL",
                dispatch_date="2026-09-10",
                is_received=False,
            ),
            CourierEntry(
                courier_no="FDX-112233",
                courier_company="FedEx",
                dispatch_date="2026-09-12",
                is_received=False,
            ),
        ],
        documents_list=[
            OriginalDocumentItem(
                category="Commercial",
                document_name="Commercial Invoice",
                courier_no="DHL-981245",
                is_received=False,
                status="Pending",
            ),
            OriginalDocumentItem(
                category="Shipping",
                document_name="Draft B/L",
                courier_no="FDX-112233",
                is_received=False,
                status="Pending",
            ),
        ],
    )
    session = OriginalDocumentsCollectionService.save_or_upsert_collection_session(db, payload)
    assert session.status == "DRAFT"

    # Confirm Courier Receipt for DHL-981245
    proof_req = CourierReceiptProofRequest(
        import_file_id=file.import_file_id,
        courier_no="DHL-981245",
        received_date="2026-09-15",
        received_time="14:30",
        received_by="Ahmed Sorour",
        pod_reference="POD-EG-0099",
        notes="Envelope delivered in good condition with wax seal intact",
        mark_documents_received=True,
    )
    updated = OriginalDocumentsCollectionService.confirm_courier_receipt(db, proof_req)

    assert updated.status == "PARTIALLY_RECEIVED"
    assert updated.received_documents_count == 1

    # Check the courier details in couriers_list
    dhl = next(c for c in updated.couriers_list if c.courier_no == "DHL-981245")
    assert dhl.is_received is True
    assert dhl.received_date == "2026-09-15"
    assert dhl.received_time == "14:30"
    assert dhl.received_by == "Ahmed Sorour"
    assert dhl.pod_reference == "POD-EG-0099"
    assert "https://www.dhl.com" in (dhl.tracking_url or "")

    # Check that Commercial Invoice was marked received
    inv_doc = next(d for d in updated.documents_list if d.document_name == "Commercial Invoice")
    assert inv_doc.is_received is True
    assert inv_doc.status == "Received"
    assert inv_doc.received_date == "2026-09-15"


def test_courier_alerts_calculation(db):
    # Setup ImportFile
    file = ImportFile(
        import_file_code="IMP-2026-ALERT",
        acid_number="9999999999999999999",
        company_name="Alert Importer",
        supplier_name="Alert Supplier",
    )
    db.add(file)
    db.commit()

    today = datetime.now(timezone.utc).date()
    old_date = (today - timedelta(days=6)).strftime("%Y-%m-%d")
    med_date = (today - timedelta(days=3)).strftime("%Y-%m-%d")
    recent_date = (today - timedelta(days=1)).strftime("%Y-%m-%d")

    payload = OriginalDocumentsCollectionCreate(
        import_file_id=file.import_file_id,
        import_file_code=file.import_file_code,
        couriers_list=[
            CourierEntry(
                courier_no="DHL-CRITICAL",
                courier_company="DHL",
                dispatch_date=old_date,
                is_received=False,
            ),
            CourierEntry(
                courier_no="FDX-WARNING",
                courier_company="FedEx",
                dispatch_date=med_date,
                is_received=False,
            ),
            CourierEntry(
                courier_no="ARX-INFO",
                courier_company="Aramex",
                dispatch_date=recent_date,
                is_received=False,
            ),
            CourierEntry(
                courier_no="UPS-DELIVERED",
                courier_company="UPS",
                dispatch_date=old_date,
                is_received=True,
                received_date=today.strftime("%Y-%m-%d"),
            ),
        ],
    )
    OriginalDocumentsCollectionService.save_or_upsert_collection_session(db, payload)

    alerts_res = OriginalDocumentsCollectionService.get_courier_alerts(db)
    assert alerts_res.total_active_couriers == 4
    assert alerts_res.pending_receipt_count == 3
    assert alerts_res.delayed_count == 2
    assert alerts_res.delivered_count == 1

    # First alert should be CRITICAL
    assert len(alerts_res.alerts) == 3
    assert alerts_res.alerts[0].alert_level == "CRITICAL"
    assert alerts_res.alerts[0].courier_no == "DHL-CRITICAL"
    assert alerts_res.alerts[0].days_in_transit >= 5

    # Second alert should be WARNING
    assert alerts_res.alerts[1].alert_level == "WARNING"
    assert alerts_res.alerts[1].courier_no == "FDX-WARNING"


def test_get_all_couriers_flat(db):
    file = ImportFile(
        import_file_code="IMP-2026-FLAT",
        company_name="Flat Importer",
        supplier_name="Flat Supplier",
    )
    db.add(file)
    db.commit()

    payload = OriginalDocumentsCollectionCreate(
        import_file_id=file.import_file_id,
        import_file_code=file.import_file_code,
        couriers_list=[
            CourierEntry(
                courier_no="DHL-FLAT-01",
                courier_company="DHL",
                dispatch_date="2026-09-12",
                is_received=False,
            ),
        ],
        documents_list=[
            OriginalDocumentItem(
                category="Commercial",
                document_name="Commercial Invoice",
                courier_no="DHL-FLAT-01",
                is_received=False,
            ),
        ],
    )
    OriginalDocumentsCollectionService.save_or_upsert_collection_session(db, payload)

    flat_list = OriginalDocumentsCollectionService.get_all_couriers_flat(db)
    assert len(flat_list) >= 1
    item = next(x for x in flat_list if x.courier_no == "DHL-FLAT-01")
    assert item.courier_company == "DHL"
    assert item.associated_docs_count == 1
    assert "https://www.dhl.com" in (item.tracking_url or "")


def test_cargox_draft_envelope_creation(db):
    # Tests that saving draft envelope doesn't fail on strict 19-digit ACID requirement
    draft_payload = CargoXEnvelopeCreate(
        acid_number="DRAFT-ACID-001",
        importer_company_name="Draft Importer Co",
        supplier_name="Draft Supplier",
        supplier_cargox_id="CX-DRAFT",
        is_draft=True,
        status="DRAFT",
    )
    envelope = CargoXService.create_envelope(db, draft_payload, created_by="TEST")
    assert envelope.status == "DRAFT"
    assert envelope.acid_number == "DRAFT-ACID-001"
    assert envelope.is_acid_verified is False
