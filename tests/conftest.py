import os
import tempfile
import pytest

# Create a temporary test database file for the test session
test_db_file = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
test_db_path = test_db_file.name
test_db_file.close()

os.environ["DATABASE_PATH"] = test_db_path

from database.database import Base, engine, SessionLocal, get_db

# Import all SQLAlchemy models to register them in Base.metadata
import modules.import_companies.model
import modules.suppliers.model
import modules.external_service_providers.model
import modules.users.model
import modules.audit_logs.model
import modules.incoterms.model
import modules.customs_tariff.model
import modules.transport_locations.model
import modules.currencies.model
import modules.projects.model
import modules.purchase_orders.model
import modules.cbm_calculator.model
import modules.shipping_scenarios.model
import modules.customs_consultation.model
import modules.freight_quotations.model
import modules.customs_clearance_quotations.model
import modules.financial_approval.model
import modules.import_documentation.model
import modules.import_files.model
import modules.freight_booking.model
import modules.cargo_shipping.model
import modules.customs_clearance.model
import modules.warehouse_receiving.model
import modules.financial_settlement.model
import modules.file_closure.model
import modules.notifications.model
import modules.smart_tasks.model
import modules.shipment_updates.model
import modules.demurrage_detention.model
import modules.smart_document_upload.model
import modules.docs_customs_approval.model
import modules.cargox.model
import modules.original_documents_collection.model

@pytest.fixture(scope="session", autouse=True)
def setup_test_database():
    # Build all tables in the temporary database
    Base.metadata.create_all(bind=engine)
    yield
    # Cleanup after test session
    try:
        if os.path.exists(test_db_path):
            os.remove(test_db_path)
    except Exception:
        pass
