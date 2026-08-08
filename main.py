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


# ==================================================
# Create FastAPI Application
# ==================================================

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="ImportFlow ERP",
    version="1.0.0",
    description="ERP System for Import, Customs and Logistics Management",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==================================================
# Include Routers
# ==================================================

app.include_router(import_router)

app.include_router(supplier_router)

app.include_router(provider_router, prefix="/api/v1")

app.include_router(audit_router, prefix="/api/v1")

app.include_router(auth_router, prefix="/api/v1")

app.include_router(incoterms_router, prefix="/api/v1")

app.include_router(customs_tariff_router, prefix="/api/v1")

app.include_router(transport_locations_router, prefix="/api/v1")

app.include_router(currencies_router, prefix="/api/v1")

app.include_router(projects_router, prefix="/api/v1")

app.include_router(purchase_orders_router)

app.include_router(cbm_calculator_router)

app.include_router(shipping_scenarios_router)

app.include_router(customs_consultation_router)


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