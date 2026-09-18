import time
import uuid
import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from modules.system_observability.service import metrics_buffer

logger = logging.getLogger("system_observability")


class ObservabilityMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # 1. Extract or generate Correlation ID
        req_id = request.headers.get("X-Request-ID")
        if not req_id:
            req_id = f"req_{int(time.time() * 1000)}_{uuid.uuid4().hex[:6]}"

        request.state.request_id = req_id

        # 2. Timing
        t0 = time.perf_counter()
        client_ip = request.client.host if request.client else None

        try:
            response: Response = await call_next(request)
        except Exception as exc:
            duration_ms = (time.perf_counter() - t0) * 1000.0
            metrics_buffer.record_request(
                request_id=req_id,
                method=request.method,
                path=request.url.path,
                status_code=500,
                duration_ms=duration_ms,
                client_ip=client_ip,
            )
            logger.error(
                f"[UNHANDLED_EXCEPTION] {request.method} {request.url.path} "
                f"failed in {duration_ms:.1f}ms (ID: {req_id}): {exc}",
                exc_info=True,
            )
            raise exc

        duration_ms = (time.perf_counter() - t0) * 1000.0

        # 3. Record in metrics buffer
        metrics_buffer.record_request(
            request_id=req_id,
            method=request.method,
            path=request.url.path,
            status_code=response.status_code,
            duration_ms=duration_ms,
            client_ip=client_ip,
        )

        # 4. Inject correlation and timing headers
        response.headers["X-Request-ID"] = req_id
        response.headers["X-Response-Time-Ms"] = f"{duration_ms:.2f}"

        # 5. Log warning for slow requests (> 500ms)
        if duration_ms >= 500.0 and request.url.path not in ("/api/v1/system/health/deep", "/api/v1/system/observability/export-bundle"):
            logger.warning(
                f"[SLOW_REQUEST] {request.method} {request.url.path} "
                f"took {duration_ms:.1f}ms (Status: {response.status_code}, ID: {req_id})"
            )

        return response
