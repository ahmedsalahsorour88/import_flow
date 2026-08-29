"""
Unit Tests — Auto-Update Engine (BP-009)
Tests: installer info fetching, check_for_updates installer fields, InstallerInfoSchema
"""
import json
import sys
import os
import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock, mock_open

# Add root to path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from modules.production_sync.schemas import InstallerInfoSchema, RemoteUpdateCheckSchema


class TestInstallerInfoSchema(unittest.TestCase):
    """Tests for InstallerInfoSchema Pydantic model."""

    def test_valid_installer_info(self):
        info = InstallerInfoSchema(
            version="1.0.89",
            installer_url="https://github.com/ahmedsalahsorour88/import_flow/releases/download/v1.0.89/Sorour_Logistics_Setup_v1.0.89.exe",
            installer_filename="Sorour_Logistics_Setup_v1.0.89.exe",
            installer_size_mb=210.5,
            is_available=True,
        )
        self.assertEqual(info.version, "1.0.89")
        self.assertTrue(info.is_available)
        self.assertAlmostEqual(info.installer_size_mb, 210.5)
        self.assertIsNone(info.error)

    def test_unavailable_installer_info(self):
        info = InstallerInfoSchema(
            version="unknown",
            installer_url="",
            installer_filename="",
            is_available=False,
            error="Connection failed",
        )
        self.assertFalse(info.is_available)
        self.assertEqual(info.error, "Connection failed")
        self.assertEqual(info.installer_url, "")

    def test_installer_size_mb_defaults_to_zero(self):
        info = InstallerInfoSchema(
            version="1.0.88",
            installer_url="https://example.com/setup.exe",
            installer_filename="setup.exe",
        )
        self.assertEqual(info.installer_size_mb, 0.0)


class TestRemoteUpdateCheckSchemaInstallerFields(unittest.TestCase):
    """Tests for RemoteUpdateCheckSchema with installer fields."""

    def test_has_installer_url_fields(self):
        schema = RemoteUpdateCheckSchema(
            has_update=True,
            current_version="1.0.88",
            latest_version="1.0.89",
            installer_url="https://github.com/ahmedsalahsorour88/import_flow/releases/download/v1.0.89/Sorour_Logistics_Setup_v1.0.89.exe",
            installer_filename="Sorour_Logistics_Setup_v1.0.89.exe",
            installer_size_mb=210.5,
            check_status="UPDATE_AVAILABLE",
            message="Update available",
        )
        self.assertTrue(schema.has_update)
        self.assertEqual(schema.installer_url, "https://github.com/ahmedsalahsorour88/import_flow/releases/download/v1.0.89/Sorour_Logistics_Setup_v1.0.89.exe")
        self.assertEqual(schema.installer_filename, "Sorour_Logistics_Setup_v1.0.89.exe")
        self.assertAlmostEqual(schema.installer_size_mb, 210.5)

    def test_installer_fields_optional(self):
        schema = RemoteUpdateCheckSchema(
            has_update=False,
            current_version="1.0.88",
            latest_version="1.0.88",
            check_status="UP_TO_DATE",
            message="System is up to date",
        )
        self.assertIsNone(schema.installer_url)
        self.assertIsNone(schema.installer_filename)
        self.assertEqual(schema.installer_size_mb, 0.0)


class TestGetLatestInstallerInfo(unittest.TestCase):
    """Tests for ProductionSyncService.get_latest_installer_info()."""

    def _get_service(self):
        from modules.production_sync.service import ProductionSyncService
        mock_db = MagicMock()
        return ProductionSyncService(mock_db)

    def test_returns_installer_info_from_remote(self):
        """When GitHub responds, installer info is returned correctly."""
        remote_data = json.dumps({
            "version": "1.0.89",
            "installer_url": "https://github.com/ahmedsalahsorour88/import_flow/releases/download/v1.0.89/Sorour_Logistics_Setup_v1.0.89.exe",
            "installer_filename": "Sorour_Logistics_Setup_v1.0.89.exe",
            "installer_size_mb": 210.5,
        }).encode("utf-8")

        mock_response = MagicMock()
        mock_response.status = 200
        mock_response.read.return_value = remote_data
        mock_response.__enter__ = lambda s: s
        mock_response.__exit__ = MagicMock(return_value=False)

        with patch("urllib.request.urlopen", return_value=mock_response):
            service = self._get_service()
            result = service.get_latest_installer_info()

        self.assertTrue(result.is_available)
        self.assertEqual(result.version, "1.0.89")
        self.assertIn("v1.0.89", result.installer_url)
        self.assertAlmostEqual(result.installer_size_mb, 210.5)

    def test_returns_error_when_offline(self):
        """When network is unavailable and local version.json has no installer_url, returns is_available=False."""
        with patch("urllib.request.urlopen", side_effect=Exception("Network error")):
            # Also ensure local version.json has no installer_url
            with patch("builtins.open", mock_open(read_data='{"version": "1.0.88"}')):
                service = self._get_service()
                result = service.get_latest_installer_info()
        self.assertFalse(result.is_available)

    def test_fallback_to_local_version_json(self):
        """When GitHub fails but local version.json has installer_url, it uses it."""
        local_data = json.dumps({
            "version": "1.0.88",
            "installer_url": "https://github.com/ahmedsalahsorour88/import_flow/releases/download/v1.0.88/Sorour_Logistics_Setup_v1.0.88.exe",
            "installer_filename": "Sorour_Logistics_Setup_v1.0.88.exe",
            "installer_size_mb": 202.14,
        })

        with patch("urllib.request.urlopen", side_effect=Exception("Network error")):
            service = self._get_service()
            # Patch ROOT_DIR / version.json to exist
            import modules.production_sync.service as svc_module
            mock_path = MagicMock()
            mock_path.exists.return_value = True
            with patch.object(svc_module, "ROOT_DIR", MagicMock(__truediv__=lambda s, x: mock_path)):
                m = mock_open(read_data=local_data)
                with patch("builtins.open", m):
                    result = service.get_latest_installer_info()

        self.assertTrue(result.is_available)
        self.assertEqual(result.version, "1.0.88")
        self.assertAlmostEqual(result.installer_size_mb, 202.14)


class TestCheckForUpdatesInstallerFields(unittest.TestCase):
    """Tests that check_for_updates populates installer fields correctly."""

    def _get_service(self):
        from modules.production_sync.service import ProductionSyncService
        mock_db = MagicMock()
        return ProductionSyncService(mock_db)

    def test_check_for_updates_includes_installer_url_when_update_available(self):
        remote_data = json.dumps({
            "version": "1.0.89",
            "installer_url": "https://github.com/ahmedsalahsorour88/import_flow/releases/download/v1.0.89/Sorour_Logistics_Setup_v1.0.89.exe",
            "installer_filename": "Sorour_Logistics_Setup_v1.0.89.exe",
            "installer_size_mb": 210.5,
            "release_notes": ["Improved document extraction"],
        }).encode("utf-8")

        mock_response = MagicMock()
        mock_response.status = 200
        mock_response.read.return_value = remote_data
        mock_response.__enter__ = lambda s: s
        mock_response.__exit__ = MagicMock(return_value=False)

        with patch("urllib.request.urlopen", return_value=mock_response):
            service = self._get_service()
            # Mock current version to be lower
            with patch.object(service, "get_system_version_info") as mock_version:
                mock_version.return_value = MagicMock(version="1.0.88")
                result = service.check_for_updates()

        self.assertTrue(result.has_update)
        self.assertIsNotNone(result.installer_url)
        self.assertIn("v1.0.89", result.installer_url)
        self.assertEqual(result.installer_filename, "Sorour_Logistics_Setup_v1.0.89.exe")
        self.assertAlmostEqual(result.installer_size_mb, 210.5)


if __name__ == "__main__":
    unittest.main()
