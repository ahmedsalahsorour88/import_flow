"""
Unit Tests for Production Sync Module
Tests comparison, backup creation, and push/pull sync logic.
"""
import unittest
from pathlib import Path
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.production_sync.service import ProductionSyncService, DEV_DB, PROD_DB
from modules.production_sync.schemas import (
    SyncComparisonResponseSchema,
    SyncActionResponseSchema,
    BackupsListResponseSchema,
)


class TestProductionSyncBackend(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
        TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        Base.metadata.create_all(bind=self.engine)
        self.db = TestingSessionLocal()
        self.service = ProductionSyncService(self.db)

        # Ensure DEV_DB has tables created for comparison tests in CI environments
        import sqlite3
        DEV_DB.parent.mkdir(parents=True, exist_ok=True)
        dev_conn = sqlite3.connect(DEV_DB)
        dev_conn.execute("CREATE TABLE IF NOT EXISTS _test_sync_tbl (id INTEGER PRIMARY KEY, name TEXT);")
        dev_conn.execute("INSERT OR IGNORE INTO _test_sync_tbl VALUES (1, 'initial');")
        dev_conn.commit()
        dev_conn.close()

    def tearDown(self):
        self.db.close()
        Base.metadata.drop_all(bind=self.engine)

    def test_get_comparison(self):
        comp = self.service.get_comparison()
        self.assertIsInstance(comp, SyncComparisonResponseSchema)
        self.assertTrue(comp.dev_stats.exists)
        self.assertGreaterEqual(comp.total_tables, 1)
        self.assertIsInstance(comp.tables, list)

    def test_create_safety_backup(self):
        backup = self.service.create_safety_backup(DEV_DB, tag="test_unit")
        self.assertTrue(backup.filename.endswith(".db"))
        self.assertGreaterEqual(backup.size_kb, 0.0)
        self.assertTrue(Path(backup.filepath).exists())

    def test_list_backups(self):
        backups_resp = self.service.list_backups()
        self.assertIsInstance(backups_resp, BackupsListResponseSchema)
        self.assertGreaterEqual(backups_resp.total_backups, 1)

    def test_sync_dev_to_prod(self):
        res = self.service.sync_dev_to_prod()
        self.assertIsInstance(res, SyncActionResponseSchema)
        self.assertTrue(res.success)
        self.assertEqual(res.action, "PUSH_TO_PROD")
        self.assertTrue(PROD_DB.exists())

    def test_restore_backup_success(self):
        """Create a backup, then restore it — verify restore response is correct and safety backup is created."""
        # Create a backup first
        backup = self.service.create_safety_backup(DEV_DB, tag="test_restore_source")
        self.assertTrue(Path(backup.filepath).exists())

        # Restore it to dev
        from modules.production_sync.schemas import RestoreBackupResponseSchema
        result = self.service.restore_backup(filename=backup.filename, target="dev")
        self.assertIsInstance(result, RestoreBackupResponseSchema)
        self.assertTrue(result.success)
        self.assertEqual(result.restored_from, backup.filename)
        self.assertEqual(result.target, "dev")
        # Safety backup should have been created (not empty)
        self.assertNotEqual(result.safety_backup_created, "")

    def test_restore_backup_nonexistent_raises(self):
        """Attempting to restore a nonexistent backup should raise FileNotFoundError."""
        with self.assertRaises(FileNotFoundError):
            self.service.restore_backup(filename="nonexistent_backup_99999.db", target="dev")

    def test_smart_non_destructive_migrate_upsert_edits(self):
        """Verify that edits to existing rows in src_db are updated in target_db (UPSERT)."""
        import sqlite3
        import tempfile
        with tempfile.TemporaryDirectory() as tmpdir:
            src_path = Path(tmpdir) / "src.db"
            tgt_path = Path(tmpdir) / "tgt.db"

            # Create src
            conn_src = sqlite3.connect(src_path)
            conn_src.execute("CREATE TABLE test_items (id INTEGER PRIMARY KEY, name TEXT, value INTEGER);")
            conn_src.execute("INSERT INTO test_items VALUES (1, 'Updated Name', 999);")
            conn_src.execute("INSERT INTO test_items VALUES (2, 'New Item', 200);")
            conn_src.commit()
            conn_src.close()

            # Create tgt with old value for id=1
            conn_tgt = sqlite3.connect(tgt_path)
            conn_tgt.execute("CREATE TABLE test_items (id INTEGER PRIMARY KEY, name TEXT, value INTEGER);")
            conn_tgt.execute("INSERT INTO test_items VALUES (1, 'Old Name', 100);")
            conn_tgt.commit()
            conn_tgt.close()

            # Run migration
            res = self.service._smart_non_destructive_migrate(src_path, tgt_path)
            self.assertEqual(res["status"], "migrated_safely")

            # Check target has updated row
            conn_tgt = sqlite3.connect(tgt_path)
            rows = conn_tgt.execute("SELECT id, name, value FROM test_items ORDER BY id;").fetchall()
            conn_tgt.close()

            self.assertEqual(len(rows), 2)
            self.assertEqual(rows[0], (1, 'Updated Name', 999))
            self.assertEqual(rows[1], (2, 'New Item', 200))

    def test_smart_non_destructive_migrate_protects_operational_user_data(self):
        """Verify that user-entered operational data in target is NOT overwritten by Dev test data."""
        import sqlite3
        import tempfile
        with tempfile.TemporaryDirectory() as tmpdir:
            src_path = Path(tmpdir) / "dev.db"
            tgt_path = Path(tmpdir) / "prod.db"

            # Create src (Dev) with dummy test import file
            conn_src = sqlite3.connect(src_path)
            conn_src.execute("CREATE TABLE import_files (id INTEGER PRIMARY KEY, file_number TEXT, notes TEXT);")
            conn_src.execute("INSERT INTO import_files VALUES (1, 'DEV-DUMMY-001', 'Test note from Dev');")
            conn_src.execute("INSERT INTO import_files VALUES (2, 'DEV-NEW-002', 'Newly added in Dev');")
            conn_src.commit()
            conn_src.close()

            # Create tgt (Prod) with REAL user data for id=1
            conn_tgt = sqlite3.connect(tgt_path)
            conn_tgt.execute("CREATE TABLE import_files (id INTEGER PRIMARY KEY, file_number TEXT, notes TEXT);")
            conn_tgt.execute("INSERT INTO import_files VALUES (1, 'REAL-PROD-USER-FILE-001', 'Important Client Data');")
            conn_tgt.commit()
            conn_tgt.close()

            # Run migration with preserve_target_user_data=True
            res = self.service._smart_non_destructive_migrate(src_path, tgt_path, preserve_target_user_data=True)
            self.assertEqual(res["status"], "migrated_safely")

            # Check target: id=1 MUST remain 'REAL-PROD-USER-FILE-001' (Protected!) and id=2 is inserted
            conn_tgt = sqlite3.connect(tgt_path)
            rows = conn_tgt.execute("SELECT id, file_number, notes FROM import_files ORDER BY id;").fetchall()
            conn_tgt.close()

            self.assertEqual(len(rows), 2)
            self.assertEqual(rows[0], (1, 'REAL-PROD-USER-FILE-001', 'Important Client Data'))
            self.assertEqual(rows[1], (2, 'DEV-NEW-002', 'Newly added in Dev'))

    def test_get_comparison_detects_new_column_in_dev(self):
        """
        When Dev DB has a new column in an existing table that Prod DB doesn't have,
        get_comparison() must flag it as has_schema_diff=True and is_fully_synchronized=False.
        """
        import sqlite3, tempfile
        from modules.production_sync import service as sync_service

        with tempfile.TemporaryDirectory() as tmpdir:
            dev_path = Path(tmpdir) / "dev.db"
            prod_path = Path(tmpdir) / "prod.db"

            # Dev DB: table with extra column 'notes'
            conn_dev = sqlite3.connect(dev_path)
            conn_dev.execute("CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT, notes TEXT);")
            conn_dev.execute("INSERT INTO products VALUES (1, 'Apple', 'fresh');")
            conn_dev.commit()
            conn_dev.close()

            # Prod DB: same table WITHOUT 'notes' column, same row count
            conn_prod = sqlite3.connect(prod_path)
            conn_prod.execute("CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT);")
            conn_prod.execute("INSERT INTO products VALUES (1, 'Apple');")
            conn_prod.commit()
            conn_prod.close()

            # Monkey-patch service paths
            original_dev = sync_service.DEV_DB
            original_prod = sync_service.PROD_DB
            sync_service.DEV_DB = dev_path
            sync_service.PROD_DB = prod_path
            try:
                comp = self.service.get_comparison()
                # Must NOT be fully synchronized — schema differs
                self.assertFalse(comp.is_fully_synchronized,
                    "Should NOT be fully synchronized when Dev has new column Prod lacks")
                self.assertGreater(comp.schema_diffs_count, 0,
                    "schema_diffs_count must be > 0 when Dev has new columns")

                # Find the 'products' table item
                tbl = next((t for t in comp.tables if t.table_name == "products"), None)
                self.assertIsNotNone(tbl)
                self.assertTrue(tbl.has_schema_diff, "products table must have has_schema_diff=True")
                self.assertIn("notes", tbl.new_columns, "'notes' must appear in new_columns")
                self.assertTrue(tbl.needs_sync, "products table must need sync")
            finally:
                sync_service.DEV_DB = original_dev
                sync_service.PROD_DB = original_prod

    def test_get_comparison_detects_new_table_in_dev(self):
        """
        When Dev DB has a table that doesn't exist in Prod DB,
        get_comparison() must flag it as is_new_table=True and is_fully_synchronized=False.
        """
        import sqlite3, tempfile
        from modules.production_sync import service as sync_service

        with tempfile.TemporaryDirectory() as tmpdir:
            dev_path = Path(tmpdir) / "dev.db"
            prod_path = Path(tmpdir) / "prod.db"

            # Dev DB: two tables
            conn_dev = sqlite3.connect(dev_path)
            conn_dev.execute("CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT);")
            conn_dev.execute("CREATE TABLE new_feature_table (id INTEGER PRIMARY KEY, data TEXT);")
            conn_dev.execute("INSERT INTO products VALUES (1, 'Apple');")
            conn_dev.commit()
            conn_dev.close()

            # Prod DB: only one table (missing new_feature_table)
            conn_prod = sqlite3.connect(prod_path)
            conn_prod.execute("CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT);")
            conn_prod.execute("INSERT INTO products VALUES (1, 'Apple');")
            conn_prod.commit()
            conn_prod.close()

            # Monkey-patch service paths
            original_dev = sync_service.DEV_DB
            original_prod = sync_service.PROD_DB
            sync_service.DEV_DB = dev_path
            sync_service.PROD_DB = prod_path
            try:
                comp = self.service.get_comparison()
                self.assertFalse(comp.is_fully_synchronized,
                    "Should NOT be fully synchronized when Dev has a new table")
                self.assertGreater(comp.schema_diffs_count, 0)

                new_tbl = next((t for t in comp.tables if t.table_name == "new_feature_table"), None)
                self.assertIsNotNone(new_tbl)
                self.assertTrue(new_tbl.is_new_table)
                self.assertTrue(new_tbl.has_schema_diff)
                self.assertTrue(new_tbl.needs_sync)
            finally:
                sync_service.DEV_DB = original_dev
                sync_service.PROD_DB = original_prod

    def test_get_comparison_fully_synced_when_schema_identical(self):
        """
        When Dev and Prod have identical tables, columns, and row counts,
        get_comparison() must report is_fully_synchronized=True.
        """
        import sqlite3, tempfile
        from modules.production_sync import service as sync_service

        with tempfile.TemporaryDirectory() as tmpdir:
            dev_path = Path(tmpdir) / "dev.db"
            prod_path = Path(tmpdir) / "prod.db"

            for db_path in [dev_path, prod_path]:
                conn = sqlite3.connect(db_path)
                conn.execute("CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT);")
                conn.execute("INSERT INTO products VALUES (1, 'Apple');")
                conn.commit()
                conn.close()

            original_dev = sync_service.DEV_DB
            original_prod = sync_service.PROD_DB
            sync_service.DEV_DB = dev_path
            sync_service.PROD_DB = prod_path
            try:
                comp = self.service.get_comparison()
                self.assertTrue(comp.is_fully_synchronized,
                    "Should be fully synchronized when schema and data are identical")
                self.assertEqual(comp.schema_diffs_count, 0)
                self.assertEqual(comp.differing_tables_count, 0)
            finally:
                sync_service.DEV_DB = original_dev
                sync_service.PROD_DB = original_prod

    def test_check_remote_update_returns_schema(self):
        """
        Verify check_remote_update() executes safely, handles offline/online states,
        and returns a valid RemoteUpdateCheckResponseSchema instance.
        """
        from modules.production_sync.schemas import RemoteUpdateCheckResponseSchema
        result = self.service.check_remote_update()
        self.assertIsInstance(result, RemoteUpdateCheckResponseSchema)
        self.assertIsNotNone(result.current_version)
        self.assertGreaterEqual(result.current_build, 1)
        self.assertIn(result.check_status, ["success", "no_update", "offline", "error"])



