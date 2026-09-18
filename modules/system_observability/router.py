from typing import List
from fastapi import APIRouter, Depends, Response, Header
from sqlalchemy.orm import Session
from database.database import get_db
from modules.users.model import User
from modules.auth.router import get_current_user

from modules.system_observability.schemas import (
    SystemMetricsResponse,
    DatabaseHealthResponse,
    DomainObservabilityResponse,
    DeepHealthCheckResponse,
    RecentRequestItem,
)
from modules.system_observability.service import (
    metrics_buffer,
    DatabaseHealthService,
    DomainRadarService,
    DeepHealthProbeService,
    DiagnosticsBundleService,
)

router = APIRouter(
    prefix="/api/v1/system",
    tags=["System Observability, Telemetry & Health Monitoring"],
)


@router.get("/observability/metrics", response_model=SystemMetricsResponse)
def get_system_metrics(
    current_user: User = Depends(get_current_user),
):
    """Returns live aggregated system metrics, RPS, percentiles, and top endpoints."""
    return metrics_buffer.get_metrics_summary()


@router.get("/observability/database", response_model=DatabaseHealthResponse)
def get_database_health(
    current_user: User = Depends(get_current_user),
):
    """Returns database size, WAL status, busy timeout, and slow query log."""
    return DatabaseHealthService.get_health()


@router.get("/observability/domain-radar", response_model=DomainObservabilityResponse)
def get_domain_radar(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Returns logistics domain operational risks: expiring ACIDs, demurrage, stuck files."""
    return DomainRadarService.get_radar(db)


@router.get("/health/deep", response_model=DeepHealthCheckResponse)
def run_deep_health_check(
    db: Session = Depends(get_db),
):
    """Executes an active write probe, database quick check, disk space, and backup freshness verification."""
    return DeepHealthProbeService.run_probe(db)


@router.get("/observability/recent-traffic", response_model=List[RecentRequestItem])
def get_recent_traffic(
    limit: int = 50,
    current_user: User = Depends(get_current_user),
):
    """Returns recent requests with their correlation ID, status code, and latency."""
    return metrics_buffer.get_recent_requests(limit=limit)


@router.get("/observability/export-bundle")
def export_diagnostics_bundle(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Generates and downloads a complete, sanitized system diagnostics and health archive (ZIP)."""
    zip_bytes = DiagnosticsBundleService.generate_zip_bundle(db)
    filename = "sorour_logistics_diagnostics_bundle.zip"
    return Response(
        content=zip_bytes,
        media_type="application/zip",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
        },
    )
