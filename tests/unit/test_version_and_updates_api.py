"""
Unit Tests for System Version & Updates API Endpoints
"""
import pytest
from fastapi.testclient import TestClient
from main import app
from database.database import get_db

client = TestClient(app)


def test_get_system_version_info():
    """Verifies that GET /api/v1/production-sync/version-info returns valid system and database metadata."""
    response = client.get("/api/v1/production-sync/version-info")
    assert response.status_code == 200
    data = response.json()
    assert "version" in data
    assert "build_number" in data
    assert "tables_count" in data
    assert "total_backups_count" in data
    assert data["system_name"] == "ImportFlow ERP - Sorour Logistics"


def test_check_for_system_updates():
    """Verifies that GET /api/v1/production-sync/check-updates returns a structured status."""
    response = client.get("/api/v1/production-sync/check-updates")
    assert response.status_code == 200
    data = response.json()
    assert "has_update" in data
    assert "current_version" in data
    assert "latest_version" in data
    assert "check_status" in data
    assert isinstance(data["release_notes"], list)
