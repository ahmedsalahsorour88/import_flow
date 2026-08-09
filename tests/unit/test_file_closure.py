import unittest
from datetime import datetime, date
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi import HTTPException

from database.database import Base
from modules.import_companies.model import ImportCompany
from modules.import_files.model import ImportFile
from modules.file_closure.model import ImportFileClosureRecord
from modules.file_closure.schemas import (
    FileClosureCreate,
    ClosureChecklistSchema,
    FileClosureUpdate,
)
from modules.file_closure.service import (
    close_import_file_service,
    get_closure_service,
    list_closures_service,
)

class TestFileClosureModule(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(self.engine)
        TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        self.db = TestingSessionLocal()

        company = ImportCompany(
            company_id=1,
            importer_name="Universal Trade Corp",
            vat_id="111-222-333",
            registration_number="54321",
            address="Alexandria, Egypt",
            country="Egypt",
            importer_id="IMP-010",
            importer_id_expiry=date(2028, 1, 1),
            vat_id_expiry=date(2028, 1, 1),
            registration_expiry=date(2028, 1, 1),
        )
        self.db.add(company)
        self.db.commit()

        imp_file = ImportFile(
            import_file_code="IMP-FILE-2026-0010",
            company_id=company.company_id,
            company_name=company.importer_name,
            supplier_name="Global Heavy Industries",
            po_number="PO-2026-1000",
            status="In Progress",
            progress_percent=95.0,
        )
        self.db.add(imp_file)
        self.db.commit()
        self.db.refresh(imp_file)
        self.import_file_id = imp_file.import_file_id

    def tearDown(self):
        self.db.close()

    def test_close_import_file_checklist_validation_failure(self):
        # Checklist with unmet condition
        schema = FileClosureCreate(
            import_file_id=self.import_file_id,
            closure_checklist=ClosureChecklistSchema(
                docs_verified=True,
                customs_cleared=True,
                warehouse_received=False, # Unmet!
                landed_cost_settled=True,
                tasks_closed=True,
            ),
            auditor_name="Adel Auditor",
            archive_location="Vault A",
        )

        with self.assertRaises(HTTPException) as ctx:
            close_import_file_service(self.db, schema)
        self.assertEqual(ctx.exception.status_code, 400)

    def test_close_import_file_success(self):
        schema = FileClosureCreate(
            import_file_id=self.import_file_id,
            closure_checklist=ClosureChecklistSchema(
                docs_verified=True,
                customs_cleared=True,
                warehouse_received=True,
                landed_cost_settled=True,
                tasks_closed=True,
            ),
            auditor_name="Adel Auditor",
            archive_location="Vault A - Digital 2026",
            archival_notes="All customs duties paid, landed cost calculated, GRN received.",
        )

        record = close_import_file_service(self.db, schema)
        self.assertIsNotNone(record.closure_id)
        self.assertTrue(record.closure_code.startswith("CLR-"))
        self.assertEqual(record.status, "Closed")

        # Verify ImportFile state updated to Closed and 100%
        imp_file = self.db.query(ImportFile).filter(ImportFile.import_file_id == self.import_file_id).first()
        self.assertEqual(imp_file.status, "Closed")
        self.assertEqual(imp_file.progress_percent, 100.0)
        self.assertEqual(imp_file.current_module, "Phase 10 - Import File Closure & Historical Archive")

if __name__ == "__main__":
    unittest.main()
