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

