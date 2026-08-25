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

    def tearDown(self):
        self.db.close()
        Base.metadata.drop_all(bind=self.engine)

    def test_get_comparison(self):
        comp = self.service.get_comparison()
        self.assertIsInstance(comp, SyncComparisonResponseSchema)
        self.assertTrue(comp.dev_stats.exists)
        self.assertGreaterEqual(comp.total_tables, 50)
        self.assertGreaterEqual(len(comp.tables), 50)

    def test_create_safety_backup(self):
        backup = self.service.create_safety_backup(DEV_DB, tag="test_unit")
        self.assertTrue(backup.filename.endswith(".db"))
        self.assertGreater(backup.size_kb, 0)
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

