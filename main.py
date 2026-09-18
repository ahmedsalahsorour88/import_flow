import sys
import asyncio

if sys.platform == "win32" and sys.version_info < (3, 8):
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

from fastapi import FastAPI, Request, Response, Depends
from starlette.middleware.base import BaseHTTPMiddleware

# ==================================================
# Database
# ==================================================

from database.database import Base
from database.database import engine


# ==================================================
# Import Models
# ==================================================

from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.external_service_providers.model import ExternalServiceProvider
from modules.users.model import User, Role, Permission, RolePermission, UserPermission
from modules.auth.revoked_token_model import RevokedToken
from modules.audit_logs.model import AuditLog
from modules.incoterms.model import Incoterm, CostItem, IncotermResponsibility
from modules.customs_tariff.model import CustomsTariff
from modules.transport_locations.model import TransportLocation
from modules.currencies.model import Currency, ExchangeRate
from modules.projects.model import Project
from modules.purchase_orders.model import POLineItem, PurchaseOrder
from modules.cbm_calculator.model import CBMCalculation, CBMCalculationItem
from modules.shipping_scenarios.model import ShippingEvaluationSession, ShippingScenarioItem
from modules.customs_consultation.model import CustomsConsultationSession, CustomsChecklistItem
from modules.freight_quotations.model import FreightRFQRequest, FreightQuotationItem
from modules.customs_clearance_quotations.model import CustomsClearanceRFQ, CustomsClearanceQuotationItem, ClearanceServicePriceListItem
from modules.financial_approval.model import (
    PaymentRequestSession,
    ImportBudgetApproval,
    SwiftExtractionBatch,
    SwiftExtractionField,
    OcrCorrectionsLog,
)
from modules.import_documentation.model import (
    AcidRegistrationSession,
    BankingDocumentSession,
    ShipmentDocumentItem,
    CustomsDeclarationDraft,
    POPackingReconciliationSession,
    InvoiceBLMatchSession,
)

from modules.import_files.model import ImportFile
from modules.freight_booking.model import ShipmentBooking
from modules.cargo_shipping.model import CargoShippingRecord
from modules.customs_clearance.model import CustomsClearanceRecord
from modules.warehouse_receiving.model import WarehouseReceivingRecord
from modules.inland_transport.model import InlandTransportBooking
from modules.financial_settlement.model import LandedCostSettlementRecord
from modules.file_closure.model import ImportFileClosureRecord
from modules.notifications.model import SystemNotification
from modules.smart_tasks.model import SmartTask
from modules.shipment_updates.model import ShipmentUpdateLog
from modules.demurrage_detention.model import DemurragePolicy, DemurrageTracking
from modules.smart_document_upload.model import UploadSession
from modules.docs_customs_approval.model import (
    CustomsDocumentApproval,
    DiscrepancyRectificationTicket,
    DocsCustomsApprovalSession,
)
from modules.cargox.model import CargoXEnvelope, CargoXEnvelopeDocument, CargoXStandardInvoiceReviewSession
from modules.original_documents_collection.model import OriginalDocumentsCollectionSession
from modules.cargo_insurance.model import CargoInsuranceCertificate
from modules.route_intelligence.model import RouteOperationalNote
from modules.simulation.model import SavedSimulationScenario
from modules.lifecycle_board.model import (
    ShipmentStageActivity,
    StepConfig,
    StepConfigAuditLog,
    PendingReferenceRecord,
)
from modules.smart_email_listener.model import InboundEmailLog, EmailSettings
from modules.formal_letters.model import FormalLetterRecord
from modules.freight_data_connector.model import (
    FreightIndexSnapshot,
    DemurrageRule,
    PortDemurrageTariff,
    ExternalApiQuotaLog,
)
from modules.expense_catalog.model import ExpenseCatalog
from modules.experience_guide.model import GuideEntry, GuideEntryScope
from modules.smart_checklists.model import ImportFileChecklistItem
from modules.recalculation.model import RecalculationDependencyMap, RecalculationLog



# ==================================================
# Import Routers
# ==================================================

from modules.import_companies.router import import_router
from modules.suppliers.router import supplier_router
from modules.external_service_providers.router import router as provider_router
from modules.audit_logs.router import router as audit_router
from modules.auth.router import router as auth_router, get_current_user
from modules.incoterms.router import incoterms_router
from modules.customs_tariff.router import customs_tariff_router
from modules.transport_locations.router import router as transport_locations_router
from modules.currencies.router import router as currencies_router
from modules.projects.router import router as projects_router
from modules.purchase_orders.router import router as purchase_orders_router
from modules.cbm_calculator.router import router as cbm_calculator_router
from modules.shipping_scenarios.router import router as shipping_scenarios_router
from modules.customs_consultation.router import router as customs_consultation_router
from modules.freight_quotations.router import router as freight_quotations_router
from modules.customs_clearance_quotations.router import router as customs_clearance_quotations_router
from modules.financial_approval.router import router as financial_approval_router
from modules.import_documentation.router import router as import_documentation_router
from modules.import_files.router import router as import_files_router
from modules.freight_booking.router import router as freight_booking_router
from modules.cargo_shipping.router import router as cargo_shipping_router
from modules.cargo_insurance.router import router as cargo_insurance_router
from modules.customs_clearance.router import router as customs_clearance_router
from modules.warehouse_receiving.router import router as warehouse_receiving_router
from modules.inland_transport.router import router as inland_transport_router
from modules.financial_settlement.router import router as financial_settlement_router
from modules.file_closure.router import router as file_closure_router
from modules.notifications.router import router as notifications_router
from modules.integrations.router import router as integrations_router
from modules.container_loader.router import container_loader_router
from modules.smart_tasks.router import router as smart_tasks_router
from modules.shipment_updates.router import router as shipment_updates_router
from modules.import_requirements.router import router as import_requirements_router
from modules.demurrage_detention.router import router as demurrage_detention_router
from modules.lifecycle_board.router import router as lifecycle_board_router
from modules.smart_document_upload.router import router as smart_document_upload_router
from modules.docs_customs_approval.router import router as docs_customs_approval_router
from modules.cargox.router import router as cargox_router
from modules.original_documents_collection.router import router as original_documents_collection_router
from modules.production_sync.router import router as production_sync_router
from modules.route_intelligence.router import router as route_intelligence_router
from modules.simulation.router import router as simulation_router
from modules.smart_email_listener.router import router as smart_email_listener_router, compat_router as smart_email_compat_router
from modules.formal_letters.router import router as formal_letters_router
from modules.freight_data_connector.router import freight_data_router
from modules.expense_catalog.router import router as expense_catalog_router
from modules.experience_guide.router import router as experience_guide_router
from modules.smart_checklists.router import router as smart_checklists_router
from modules.recalculation.router import router as recalculation_router
from modules.system_observability.router import router as system_observability_router
from modules.system_observability.middleware import ObservabilityMiddleware
from modules.system_observability.service import setup_query_listener

# Setup query execution timing on SQLAlchemy engine
setup_query_listener(engine)

# ==================================================
# Create FastAPI Application
# ==================================================

app = FastAPI(
    title="Sorour Logistics ERP API",
    version="1.0.198",
)

# ==================================================
# Observability & Request Correlation Middleware
# ==================================================
app.add_middleware(ObservabilityMiddleware)

# ==================================================
# Response Compression Middleware (GZip)
# ==================================================
from fastapi.middleware.gzip import GZipMiddleware

app.add_middleware(GZipMiddleware, minimum_size=1000)

# ==================================================
# CORS & Private Network Access (PNA) Middleware
# ==================================================
# NOTE: We use a single unified custom middleware instead of FastAPI's built-in
# CORSMiddleware to avoid conflicts. In Starlette, middlewares execute LIFO
# (Last In, First Out), so two separate CORS handlers conflict — the http
# middleware intercepts OPTIONS before CORSMiddleware can add its headers.
# This unified handler covers both preflight (OPTIONS) and actual requests.

import re as _re

CORS_ALLOWED_METHODS = "GET, POST, PUT, DELETE, PATCH, OPTIONS, HEAD"
CORS_ALLOWED_ORIGIN_REGEX = r"^https?://(localhost|127\.0\.0\.1|0\.0\.0\.0|192\.168\.\d+\.\d+|10\.\d+\.\d+\.\d+|172\.(1[6-9]|2[0-9]|3[0-1])\.\d+\.\d+)(:[0-9]+)?$"

# Keep LOCAL_ORIGIN_REGEX as alias used in the global exception handler below
LOCAL_ORIGIN_REGEX = CORS_ALLOWED_ORIGIN_REGEX


@app.middleware("http")
async def cors_and_pna_middleware(request: Request, call_next):
    raw_origin = request.headers.get("origin", "")
    is_allowed = bool(raw_origin and _re.match(CORS_ALLOWED_ORIGIN_REGEX, raw_origin))

    # Security headers applied system-wide
    sec_headers = {
        "X-Content-Type-Options": "nosniff",
        "X-Frame-Options": "DENY",
        "Referrer-Policy": "strict-origin-when-cross-origin",
        "Content-Security-Policy": "default-src 'self'; frame-ancestors 'none'; object-src 'none';",
        "Permissions-Policy": "geolocation=(), camera=(), microphone=()",
    }
    proto = request.headers.get("x-forwarded-proto", request.url.scheme)
    if proto == "https":
        sec_headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"

    # Handle CORS preflight (OPTIONS) immediately
    if request.method == "OPTIONS":
        req_headers = request.headers.get("access-control-request-headers", "*")
        response = Response(status_code=204)
        for k, v in sec_headers.items():
            response.headers[k] = v
        if is_allowed:
            response.headers["Access-Control-Allow-Origin"] = raw_origin
            response.headers["Access-Control-Allow-Methods"] = CORS_ALLOWED_METHODS
            response.headers["Access-Control-Allow-Headers"] = req_headers
            response.headers["Access-Control-Allow-Credentials"] = "true"
            response.headers["Access-Control-Allow-Private-Network"] = "true"
            response.headers["Access-Control-Max-Age"] = "86400"
            response.headers["Vary"] = "Origin"
        return response

    response = await call_next(request)

    # Inject security headers on every response
    for k, v in sec_headers.items():
        response.headers[k] = v

    # Inject CORS + PNA headers strictly if origin is authorized
    if is_allowed:
        response.headers["Access-Control-Allow-Origin"] = raw_origin
        response.headers["Access-Control-Allow-Credentials"] = "true"
        response.headers["Access-Control-Allow-Private-Network"] = "true"
        response.headers["Vary"] = "Origin"

    return response


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    import logging
    import os
    import re
    from fastapi.responses import JSONResponse

    logging.getLogger("main").error(f"Unhandled server error: {exc}", exc_info=True)
    raw_origin = request.headers.get("origin", "")
    is_allowed = bool(raw_origin and re.match(LOCAL_ORIGIN_REGEX, raw_origin))
    headers = {
        "X-Content-Type-Options": "nosniff",
        "X-Frame-Options": "DENY",
        "Referrer-Policy": "strict-origin-when-cross-origin",
    }
    if is_allowed:
        headers["Access-Control-Allow-Origin"] = raw_origin
        headers["Access-Control-Allow-Credentials"] = "true"
        headers["Access-Control-Allow-Private-Network"] = "true"
        headers["Vary"] = "Origin"

    is_debug = os.getenv("DEBUG", "false").lower() in ("true", "1")
    detail = f"Internal Server Error: {str(exc)}" if is_debug else "Internal Server Error"
    return JSONResponse(
        status_code=500,
        content={"detail": detail},
        headers=headers,
    )



# ==================================================
# Include Routers
# ==================================================

app.include_router(auth_router)
app.include_router(import_router)
app.include_router(supplier_router)
app.include_router(provider_router)
app.include_router(audit_router)
app.include_router(incoterms_router)
app.include_router(customs_tariff_router)
app.include_router(transport_locations_router)
app.include_router(currencies_router)
app.include_router(projects_router)
app.include_router(purchase_orders_router)
app.include_router(cbm_calculator_router)
app.include_router(container_loader_router)
app.include_router(shipping_scenarios_router)
app.include_router(customs_consultation_router)
app.include_router(freight_quotations_router)
app.include_router(customs_clearance_quotations_router)
app.include_router(financial_approval_router)
app.include_router(import_documentation_router)
app.include_router(import_files_router)
app.include_router(freight_booking_router)
app.include_router(cargo_shipping_router)
app.include_router(cargo_insurance_router)
app.include_router(customs_clearance_router)
app.include_router(inland_transport_router)
app.include_router(warehouse_receiving_router)
app.include_router(financial_settlement_router)
app.include_router(file_closure_router)
app.include_router(notifications_router)
app.include_router(integrations_router)
app.include_router(smart_tasks_router)
app.include_router(shipment_updates_router)
app.include_router(import_requirements_router)
app.include_router(demurrage_detention_router)
app.include_router(lifecycle_board_router)
app.include_router(smart_document_upload_router)
app.include_router(docs_customs_approval_router)
app.include_router(cargox_router)
app.include_router(original_documents_collection_router)
app.include_router(production_sync_router)
app.include_router(route_intelligence_router)
app.include_router(simulation_router)
app.include_router(smart_email_listener_router)
app.include_router(smart_email_compat_router)
app.include_router(formal_letters_router)
app.include_router(freight_data_router)
app.include_router(expense_catalog_router)
app.include_router(experience_guide_router)
app.include_router(smart_checklists_router)
app.include_router(recalculation_router)
app.include_router(system_observability_router)



# ==================================================
# Create & Incrementally Upgrade Database Tables Safely
# ==================================================

from database.schema_upgrade_service import SchemaUpgradeService

# Automated Safe In-Place Schema Upgrade and Master Data Synchronization
SchemaUpgradeService.execute_safe_startup_upgrade(
    target_engine=engine,
    metadata=Base.metadata,
)




# ==================================================
# Dashboard
# ==================================================

@app.get("/")
def dashboard():
    return {
        "system": "Sorour Logistics ERP",
        "version": "1.0.198",
        "status": "running",
    }


# ==================================================
# Health Check
# ==================================================

@app.get("/health")
@app.get("/api/v1/health")
def health_check():
    import sqlite3
    import os
    db_path = "sorour_logistics.db"
    db_exists = os.path.exists(db_path)
    db_size_kb = round(os.path.getsize(db_path) / 1024, 1) if db_exists else 0
    tables_count = 0
    if db_exists:
        try:
            conn = sqlite3.connect(db_path)
            cur = conn.cursor()
            cur.execute("SELECT count(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
            tables_count = cur.fetchone()[0]
            conn.close()
        except Exception:
            pass

    return {
        "status": "OK",
        "system": "Sorour Logistics ERP",
        "version": "1.0.198",
        "database": {
            "connected": db_exists,
            "size_kb": db_size_kb,
            "tables_count": tables_count,
        },
    }


# ==================================================
# System Version & Client Update Check
# ==================================================

@app.get("/api/v1/system/version-check")
@app.get("/api/v1/system/version")
def system_version_check():
    import json
    from pathlib import Path

    version_file = Path(__file__).resolve().parent / "version.json"
    ver_data = {}
    if version_file.exists():
        try:
            with open(version_file, "r", encoding="utf-8") as f:
                ver_data = json.load(f)
        except Exception:
            pass

    ver_str = ver_data.get("version", "1.0.188")
    build_num = ver_data.get("build_number", 189)

    return {
        "status": "OK",
        "system_name": "Sorour Logistics ERP",
        "current_version": ver_str,
        "latest_version": ver_str,
        "build_number": build_num,
        "has_update": False,
        "check_status": "up_to_date",
        "installer_url": ver_data.get("installer_url", f"https://github.com/ahmedsalahsorour88/import_flow/releases/download/v{ver_str}/Sorour_Logistics_Setup_v{ver_str}.exe"),
        "installer_filename": ver_data.get("installer_filename", f"Sorour_Logistics_Setup_v{ver_str}.exe"),
        "installer_size_mb": ver_data.get("installer_size_mb", 198.04),
        "release_notes": ver_data.get("release_notes", [
            "Sorour Logistics ERP Production Release",
            "Full enterprise import workflow, customs calculation, and landed cost modules",
        ]),
        "updated_at": ver_data.get("updated_at", ""),
    }


# ==================================================
# Graceful System Shutdown
# ==================================================

@app.post("/shutdown")
@app.post("/api/v1/shutdown")
def shutdown_system(current_user: User = Depends(get_current_user)):
    import os
    import threading
    import time

    def _delayed_exit():
        time.sleep(0.3)
        os._exit(0)

    threading.Thread(target=_delayed_exit, daemon=True).start()
    return {
        "status": "shutting down",
        "message": "Sorour Logistics backend is shutting down gracefully...",
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=28080, log_config=None, access_log=False)
