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
from modules.external_service_providers.model import (
    ExternalServiceProvider,
)






# ==================================================
# Import Routers
# ==================================================

from modules.import_companies.router import import_router
from modules.suppliers.router import supplier_router
from modules.external_service_providers.router import router as provider_router


# ==================================================
# Create FastAPI Application
# ==================================================

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="ImportFlow ERP",
    version="1.0.0",
    description="ERP System for Import, Customs and Logistics Management",
)

# Enable CORS for Flutter Web / Desktop
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==================================================
# Register Routers
# ==================================================

app.include_router(import_router)

app.include_router(supplier_router)

app.include_router(provider_router)


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