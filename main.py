import sys
import asyncio

if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
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
from modules.users.model import User
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
from modules.financial_approval.model import PaymentRequestSession, ImportBudgetApproval
from modules.import_documentation.model import (
    AcidRegistrationSession,
    BankingDocumentSession,
    ShipmentDocumentItem,
    CustomsDeclarationDraft,
    POPackingReconciliationSession,
)

from modules.import_files.model import ImportFile
from modules.freight_booking.model import ShipmentBooking
from modules.cargo_shipping.model import CargoShippingRecord
from modules.customs_clearance.model import CustomsClearanceRecord
from modules.warehouse_receiving.model import WarehouseReceivingRecord
from modules.financial_settlement.model import LandedCostSettlementRecord
from modules.file_closure.model import ImportFileClosureRecord
from modules.notifications.model import SystemNotification
from modules.smart_tasks.model import SmartTask
from modules.shipment_updates.model import ShipmentUpdateLog
from modules.demurrage_detention.model import DemurragePolicy, DemurrageTracking
from modules.smart_document_upload.model import UploadSession
from modules.docs_customs_approval.model import CustomsDocumentApproval, DiscrepancyRectificationTicket
from modules.cargox.model import CargoXEnvelope, CargoXEnvelopeDocument, CargoXStandardInvoiceReviewSession
from modules.original_documents_collection.model import OriginalDocumentsCollectionSession
from modules.cargo_insurance.model import CargoInsuranceCertificate


# ==================================================
# Import Routers
# ==================================================

from modules.import_companies.router import import_router
from modules.suppliers.router import supplier_router
from modules.external_service_providers.router import router as provider_router
from modules.audit_logs.router import router as audit_router
from modules.auth.router import router as auth_router
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


# ==================================================
# Create FastAPI Application
# ==================================================

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="ImportFlow ERP API",
    version="1.0.81",
)

# ==================================================
# Custom CORS & Private Network Access (PNA) Middleware
# ==================================================

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r".*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)


@app.middleware("http")
async def add_pna_and_security_headers(request: Request, call_next):
    origin = request.headers.get("origin") or "*"
    if request.method == "OPTIONS":
        response = Response(status_code=204)
        req_headers = request.headers.get("access-control-request-headers", "*")
        response.headers["Access-Control-Allow-Origin"] = origin
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, PATCH, OPTIONS, HEAD"
        response.headers["Access-Control-Allow-Headers"] = req_headers
        response.headers["Access-Control-Allow-Credentials"] = "true"
        response.headers["Access-Control-Allow-Private-Network"] = "true"
        response.headers["Access-Control-Max-Age"] = "86400"
        return response

    response = await call_next(request)
    if origin != "*":
        response.headers["Access-Control-Allow-Origin"] = origin
        response.headers["Access-Control-Allow-Credentials"] = "true"
    response.headers["Access-Control-Allow-Private-Network"] = "true"
    return response


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    from fastapi.responses import JSONResponse
    origin = request.headers.get("origin") or "*"
    headers = {
        "Access-Control-Allow-Origin": origin,
        "Access-Control-Allow-Credentials": "true",
        "Access-Control-Allow-Private-Network": "true",
    }
    return JSONResponse(
        status_code=500,
        content={"detail": f"Internal Server Error: {str(exc)}"},
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
        "system": "ImportFlow ERP",
        "version": "1.0.81",
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
        "system": "ImportFlow ERP",
        "version": "1.0.81",
        "database": {
            "connected": db_exists,
            "path": db_path,
            "size_kb": db_size_kb,
            "tables_count": tables_count,
        },
    }


# ==================================================
# Graceful System Shutdown
# ==================================================

@app.post("/shutdown")
@app.post("/api/v1/shutdown")
def shutdown_system():
    import os
    import threading
    import time

    def _delayed_exit():
        time.sleep(0.3)
        os._exit(0)

    threading.Thread(target=_delayed_exit, daemon=True).start()
    return {
        "status": "shutting down",
        "message": "ImportFlow backend is shutting down gracefully...",
    }