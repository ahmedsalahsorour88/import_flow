from fastapi import FastAPI

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
from modules.financial_approval.model import PaymentRequestSession, ImportBudgetApproval
from modules.import_documentation.model import (
    AcidRegistrationSession,
    BankingDocumentSession,
    ShipmentDocumentItem,
    CustomsDeclarationDraft,
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
from modules.financial_approval.router import router as financial_approval_router
from modules.import_documentation.router import router as import_documentation_router
from modules.import_files.router import router as import_files_router
from modules.freight_booking.router import router as freight_booking_router
from modules.cargo_shipping.router import router as cargo_shipping_router
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


# ==================================================
# Create FastAPI Application
# ==================================================

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="ImportFlow ERP API",
    description="Enterprise API for Import Management & Customs Clearance",
    version="1.0.0",
)

# CORS Middleware Setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_origin_regex=r".*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
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
app.include_router(financial_approval_router)
app.include_router(import_documentation_router)
app.include_router(import_files_router)
app.include_router(freight_booking_router)
app.include_router(cargo_shipping_router)
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


# ==================================================
# Create Database Tables
# ==================================================

Base.metadata.create_all(
    bind=engine
)

from update_db_schema import migrate_db
migrate_db()

from seed import seed_data
seed_data()




# ==================================================
# Dashboard
# ==================================================

@app.get("/")
def dashboard():

    return {
        "system": "ImportFlow ERP",
        "version": "1.0.0",
        "status": "running",
    }


# ==================================================
# Health Check
# ==================================================

@app.get("/health")
def health_check():

    return {
        "status": "OK",
    }