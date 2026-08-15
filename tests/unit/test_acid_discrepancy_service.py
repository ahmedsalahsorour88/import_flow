import pytest
from datetime import date
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from database.database import Base
from modules.import_documentation.schemas import (
    AcidRegistrationCreate,
    AcidRegistrationUpdate,
)
from modules.import_documentation.service import (
    create_acid_session_service,
    update_acid_session_service,
    parse_acid_text_service,
)
from modules.import_documentation.repository import get_acid_session_by_id


from modules.external_service_providers.model import ExternalServiceProvider
from modules.transport_locations.model import TransportLocation
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.projects.model import Project
from modules.incoterms.model import Incoterm
from modules.currencies.model import Currency
from modules.purchase_orders.model import PurchaseOrder
from modules.import_files.model import ImportFile
from modules.import_documentation.model import (
    AcidRegistrationSession,
    BankingDocumentSession,
    ShipmentDocumentItem,
    CustomsDeclarationDraft,
)


@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(bind=engine)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def test_create_and_update_acid_session(db_session):
    schema = AcidRegistrationCreate(
        acid_number="PENDING",
        importer_name="Arki Brands",
        importer_tax_id="759552827",
        exporter_name="Impact Acoustic Spa",
        exporter_reg_type="VAT Number",
        exporter_reg_id="IT04462890981",
        exporter_country="ITALY",
        exporter_country_code="IT",
        proforma_invoice_no="IT-DN26-0031496",
        pol_name="Genoa",
        pod_name="Alexandria",
        requested_date=date(2026, 5, 31),
        expiry_date=date(2026, 11, 30),
    )
    created = create_acid_session_service(db_session, schema)
    assert created.acid_id is not None
    assert created.status == "Requested"
    assert created.acid_code.startswith("ACID-")

    # Update with issued ACID and acceptance
    update_schema = AcidRegistrationUpdate(
        acid_number="7595528271015010011",
        generated_date=date(2026, 5, 31),
        status="Verified",
        discrepancy_override_reason="Ports matched after amendment",
    )
    updated = update_acid_session_service(db_session, created.acid_id, update_schema)
    assert updated.acid_number == "7595528271015010011"
    assert updated.status == "Verified"
    assert updated.discrepancy_override_reason == "Ports matched after amendment"
