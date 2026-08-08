import unittest

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.incoterms.schemas import (
    CostItemCreate,
    IncotermCreate,
    IncotermResponsibilityCreate,
)
from modules.incoterms.service import (
    create_cost_item_service,
    create_incoterm_service,
    create_responsibility_service,
    delete_cost_item_service,
    delete_incoterm_service,
    get_all_cost_items_service,
    get_all_incoterms_service,
    get_incoterm_by_id_service,
    restore_incoterm_service,
)
from modules.incoterms.validators import (
    validate_no_duplicate_incoterm_code,
    validate_no_duplicate_cost_item_code,
    validate_no_duplicate_responsibility,
)


class TestIncotermsBackend(unittest.TestCase):

    def setUp(self):
        self.engine = create_engine(
            "sqlite:///:memory:", connect_args={"check_same_thread": False}
        )
        TestingSessionLocal = sessionmaker(
            autocommit=False, autoflush=False, bind=self.engine
        )
        Base.metadata.create_all(bind=self.engine)
        self.db = TestingSessionLocal()

    def tearDown(self):
        self.db.close()
        Base.metadata.drop_all(bind=self.engine)

    # ==================================================
    # Incoterm CRUD Tests
    # ==================================================

    def test_create_incoterm(self):
        data = IncotermCreate(
            incoterm_code="FOB",
            incoterm_name="Free On Board",
            version="Incoterms 2020",
            description="Test desc",
        )
        incoterm = create_incoterm_service(self.db, data)
        self.assertEqual(incoterm.incoterm_code, "FOB")
        self.assertEqual(incoterm.incoterm_name, "Free On Board")
        self.assertTrue(incoterm.is_active)

    def test_create_incoterm_code_is_uppercased(self):
        data = IncotermCreate(
            incoterm_code="cif",
            incoterm_name="Cost Insurance Freight",
            version="Incoterms 2020",
        )
        incoterm = create_incoterm_service(self.db, data)
        self.assertEqual(incoterm.incoterm_code, "CIF")

    def test_duplicate_incoterm_code_raises_error(self):
        data = IncotermCreate(
            incoterm_code="EXW",
            incoterm_name="Ex Works",
            version="Incoterms 2020",
        )
        create_incoterm_service(self.db, data)
        with self.assertRaises(ValueError):
            create_incoterm_service(self.db, data)

    def test_get_all_incoterms_active_only(self):
        fob_data = IncotermCreate(
            incoterm_code="FOB",
            incoterm_name="Free On Board",
            version="Incoterms 2020",
        )
        cif_data = IncotermCreate(
            incoterm_code="CIF",
            incoterm_name="Cost Insurance Freight",
            version="Incoterms 2020",
        )
        fob = create_incoterm_service(self.db, fob_data)
        create_incoterm_service(self.db, cif_data)
        delete_incoterm_service(self.db, fob.incoterm_id)

        active = get_all_incoterms_service(self.db, include_inactive=False)
        self.assertEqual(len(active), 1)
        self.assertEqual(active[0].incoterm_code, "CIF")

    def test_get_all_incoterms_include_inactive(self):
        fob_data = IncotermCreate(
            incoterm_code="FOB",
            incoterm_name="Free On Board",
            version="Incoterms 2020",
        )
        cif_data = IncotermCreate(
            incoterm_code="CIF",
            incoterm_name="Cost Insurance Freight",
            version="Incoterms 2020",
        )
        fob = create_incoterm_service(self.db, fob_data)
        create_incoterm_service(self.db, cif_data)
        delete_incoterm_service(self.db, fob.incoterm_id)

        all_items = get_all_incoterms_service(self.db, include_inactive=True)
        self.assertEqual(len(all_items), 2)

    def test_soft_delete_and_restore_incoterm(self):
        data = IncotermCreate(
            incoterm_code="DAP",
            incoterm_name="Delivered at Place",
            version="Incoterms 2020",
        )
        incoterm = create_incoterm_service(self.db, data)
        self.assertTrue(incoterm.is_active)

        deleted = delete_incoterm_service(self.db, incoterm.incoterm_id)
        self.assertFalse(deleted.is_active)

        restored = restore_incoterm_service(self.db, incoterm.incoterm_id)
        self.assertTrue(restored.is_active)

    def test_get_incoterm_by_id_not_found_raises_404(self):
        from fastapi import HTTPException
        with self.assertRaises(HTTPException) as ctx:
            get_incoterm_by_id_service(self.db, 9999)
        self.assertEqual(ctx.exception.status_code, 404)

    # ==================================================
    # Cost Item CRUD Tests
    # ==================================================

    def test_create_cost_item(self):
        data = CostItemCreate(
            cost_item_code="OFR",
            cost_item_name="Ocean Freight",
            cost_category="Freight",
        )
        item = create_cost_item_service(self.db, data)
        self.assertEqual(item.cost_item_code, "OFR")
        self.assertEqual(item.cost_category, "Freight")
        self.assertTrue(item.is_active)

    def test_duplicate_cost_item_code_raises_error(self):
        data = CostItemCreate(
            cost_item_code="INS",
            cost_item_name="Insurance",
            cost_category="Freight",
        )
        create_cost_item_service(self.db, data)
        with self.assertRaises(ValueError):
            create_cost_item_service(self.db, data)

    def test_get_all_cost_items_active_only(self):
        item1_data = CostItemCreate(
            cost_item_code="OFR",
            cost_item_name="Ocean Freight",
            cost_category="Freight",
        )
        item2_data = CostItemCreate(
            cost_item_code="INS",
            cost_item_name="Insurance",
            cost_category="Freight",
        )
        item1 = create_cost_item_service(self.db, item1_data)
        create_cost_item_service(self.db, item2_data)
        delete_cost_item_service(self.db, item1.cost_item_id)

        active = get_all_cost_items_service(self.db, include_inactive=False)
        self.assertEqual(len(active), 1)
        self.assertEqual(active[0].cost_item_code, "INS")

    # ==================================================
    # Responsibility Matrix Tests
    # ==================================================

    def test_create_responsibility(self):
        incoterm = create_incoterm_service(
            self.db,
            IncotermCreate(
                incoterm_code="FOB",
                incoterm_name="Free On Board",
                version="Incoterms 2020",
            ),
        )
        cost_item = create_cost_item_service(
            self.db,
            CostItemCreate(
                cost_item_code="OFR",
                cost_item_name="Ocean Freight",
                cost_category="Freight",
            ),
        )
        data = IncotermResponsibilityCreate(
            incoterm_id=incoterm.incoterm_id,
            cost_item_id=cost_item.cost_item_id,
            responsible_party="Importer",
            included_in_incoterm=False,
        )
        resp = create_responsibility_service(self.db, data)
        self.assertEqual(resp.incoterm_id, incoterm.incoterm_id)
        self.assertEqual(resp.responsible_party, "Importer")
        self.assertFalse(resp.included_in_incoterm)

    def test_duplicate_responsibility_raises_error(self):
        incoterm = create_incoterm_service(
            self.db,
            IncotermCreate(
                incoterm_code="CIF",
                incoterm_name="Cost Insurance Freight",
                version="Incoterms 2020",
            ),
        )
        cost_item = create_cost_item_service(
            self.db,
            CostItemCreate(
                cost_item_code="INS",
                cost_item_name="Insurance",
                cost_category="Freight",
            ),
        )
        data = IncotermResponsibilityCreate(
            incoterm_id=incoterm.incoterm_id,
            cost_item_id=cost_item.cost_item_id,
            responsible_party="Exporter",
            included_in_incoterm=True,
        )
        create_responsibility_service(self.db, data)
        with self.assertRaises(ValueError):
            create_responsibility_service(self.db, data)

    def test_responsibility_invalid_incoterm_raises_error(self):
        cost_item = create_cost_item_service(
            self.db,
            CostItemCreate(
                cost_item_code="OFR",
                cost_item_name="Ocean Freight",
                cost_category="Freight",
            ),
        )
        data = IncotermResponsibilityCreate(
            incoterm_id=9999,
            cost_item_id=cost_item.cost_item_id,
            responsible_party="Importer",
            included_in_incoterm=False,
        )
        with self.assertRaises(ValueError):
            create_responsibility_service(self.db, data)

    def test_responsibility_invalid_cost_item_raises_error(self):
        incoterm = create_incoterm_service(
            self.db,
            IncotermCreate(
                incoterm_code="FOB",
                incoterm_name="Free On Board",
                version="Incoterms 2020",
            ),
        )
        data = IncotermResponsibilityCreate(
            incoterm_id=incoterm.incoterm_id,
            cost_item_id=9999,
            responsible_party="Importer",
            included_in_incoterm=False,
        )
        with self.assertRaises(ValueError):
            create_responsibility_service(self.db, data)

    # ==================================================
    # Validator Unit Tests
    # ==================================================

    def test_validate_no_duplicate_incoterm_code_passes(self):
        """Should not raise when code doesn't exist."""
        validate_no_duplicate_incoterm_code(self.db, "EXW")

    def test_validate_no_duplicate_cost_item_code_passes(self):
        """Should not raise when code doesn't exist."""
        validate_no_duplicate_cost_item_code(self.db, "OFR")

    def test_validate_no_duplicate_responsibility_passes(self):
        """Should not raise when pair doesn't exist."""
        validate_no_duplicate_responsibility(self.db, 1, 1)


if __name__ == "__main__":
    unittest.main()
