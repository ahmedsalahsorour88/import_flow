import io
import zipfile
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from main import app
from database.database import get_db, SessionLocal
from modules.system_observability.service import (
    ObservabilityMetricsBuffer,
    SlowQueryTracker,
    DeepHealthProbeService,
    DatabaseHealthService,
    DomainRadarService,
    DiagnosticsBundleService,
)


@pytest.fixture
def db_session():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture
def client():
    return TestClient(app)


def test_metrics_buffer_recording():
    buf = ObservabilityMetricsBuffer(max_history=100)
    buf.record_request("req_1", "GET", "/api/v1/currencies", 200, 15.0)
    buf.record_request("req_2", "POST", "/api/v1/auth/login", 200, 45.0)
    buf.record_request("req_3", "GET", "/api/v1/unknown", 404, 8.0)
    buf.record_request("req_4", "POST", "/api/v1/calculate", 500, 120.0)

    summary = buf.get_metrics_summary()
    assert summary.total_requests == 4
    assert summary.status_2xx == 2
    assert summary.status_4xx == 1
    assert summary.status_5xx == 1
    assert summary.p50_latency_ms > 0
    assert summary.p95_latency_ms >= summary.p50_latency_ms
    assert len(summary.top_endpoints) >= 3

    recent = buf.get_recent_requests(limit=10)
    assert len(recent) == 4
    assert recent[0].request_id == "req_4"  # Most recent first


def test_slow_query_tracker():
    tracker = SlowQueryTracker(max_queries=50, threshold_ms=150.0)
    tracker.record(50.0, "SELECT 1")  # Below threshold -> ignored
    tracker.record(160.0, "SELECT * FROM large_table", {"limit": 100})  # Above threshold -> recorded
    tracker.record(250.0, "SELECT id FROM items WHERE active = 1")

    slow_list = tracker.get_recent_slow_queries()
    assert len(slow_list) == 2
    assert slow_list[0].duration_ms == 250.0
    assert "large_table" in slow_list[1].statement


def test_database_health_service():
    health = DatabaseHealthService.get_health()
    assert health.connected is True
    assert health.database_size_mb >= 0.0
    assert health.engine_type.startswith("SQLite")


def test_deep_health_check_probe(db_session: Session):
    probe = DeepHealthProbeService.run_probe(db_session)
    assert probe.verdict in ("HEALTHY", "DEGRADED", "CRITICAL")
    assert probe.database_write_probe is True
    assert probe.database_integrity == "ok"
    assert probe.free_disk_space_gb > 0.0


def test_domain_radar_service(db_session: Session):
    radar = DomainRadarService.get_radar(db_session)
    assert hasattr(radar, "expiring_acids_count")
    assert hasattr(radar, "demurrage_risks_count")
    assert hasattr(radar, "stuck_shipments_count")
    assert hasattr(radar, "last_backup_status")


def test_diagnostics_bundle_generation(db_session: Session):
    zip_bytes = DiagnosticsBundleService.generate_zip_bundle(db_session)
    assert len(zip_bytes) > 100

    with zipfile.ZipFile(io.BytesIO(zip_bytes), "r") as zf:
        namelist = zf.namelist()
        assert "system_metrics.json" in namelist
        assert "database_health.json" in namelist
        assert "domain_radar.json" in namelist
        assert "deep_health_check.json" in namelist
        assert "system_environment.json" in namelist


def test_api_endpoints_and_telemetry_headers(client: TestClient):
    # 1. Deep health check endpoint (public probe)
    res = client.get("/api/v1/system/health/deep")
    assert res.status_code == 200
    data = res.json()
    assert "verdict" in data
    assert "database_write_probe" in data
    # Verify X-Request-ID and X-Response-Time-Ms headers
    assert "X-Request-ID" in res.headers
    assert "X-Response-Time-Ms" in res.headers

    # 2. System metrics endpoint
    res_metrics = client.get(
        "/api/v1/system/observability/metrics",
        headers={"x-user-role": "ADMIN", "x-user-name": "admin"},
    )
    assert res_metrics.status_code == 200
    m_data = res_metrics.json()
    assert "status" in m_data
    assert "requests_per_second" in m_data
    assert "p50_latency_ms" in m_data

    # 3. Database health endpoint
    res_db = client.get(
        "/api/v1/system/observability/database",
        headers={"x-user-role": "ADMIN", "x-user-name": "admin"},
    )
    assert res_db.status_code == 200
    db_data = res_db.json()
    assert db_data["connected"] is True

    # 4. Domain radar endpoint
    res_radar = client.get(
        "/api/v1/system/observability/domain-radar",
        headers={"x-user-role": "ADMIN", "x-user-name": "admin"},
    )
    assert res_radar.status_code == 200
    radar_data = res_radar.json()
    assert "expiring_acids_count" in radar_data

    # 5. Export diagnostics bundle
    res_bundle = client.get(
        "/api/v1/system/observability/export-bundle",
        headers={"x-user-role": "ADMIN", "x-user-name": "admin"},
    )
    assert res_bundle.status_code == 200
    assert res_bundle.headers["content-type"] == "application/zip"
    assert len(res_bundle.content) > 100
