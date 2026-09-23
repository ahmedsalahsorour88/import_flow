"""
ImportFlow ERP — SQLite to PostgreSQL Enterprise Migration Utility
===================================================================
Transfers schema, tables, and operational/reference records from
SQLite (`sorour_logistics.db`) to PostgreSQL with transactional integrity.

Usage:
    python scripts/migrate_sqlite_to_postgres.py --target postgresql://postgres:<DB_PASSWORD>@localhost:5432/importflow_prod
"""

import os
import sys
import argparse
from pathlib import Path
from typing import List

# Ensure project root in sys.path
ROOT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT_DIR))

from sqlalchemy import create_engine, MetaData, Table, select, func, text
from sqlalchemy.orm import sessionmaker

# Import all models to ensure complete SQLAlchemy registry
from database.database import Base, convention

# Import all models to ensure complete 106-table SQLAlchemy registry
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
from modules.customs_clearance_quotations.model import (
    CustomsClearanceRFQ,
    CustomsClearanceQuotationItem,
    ClearanceServicePriceListItem,
)
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
from modules.import_requirements.model import ImportRequirementAssessment
from modules.container_loader.model import ContainerSpecModel, ContainerLoaderSessionModel
from modules.production_sync.model import ProductionSyncLog



def migrate(source_sqlite_path: str, target_pg_url: str):
    print("=" * 80)
    print("=== ImportFlow ERP -- SQLite to PostgreSQL Migration ===")
    print("=" * 80)
    print(f"Source (SQLite):     {source_sqlite_path}")
    print(f"Target (PostgreSQL): {target_pg_url}")
    print()

    if not Path(source_sqlite_path).exists():
        print(f"[-] Error: Source database file '{source_sqlite_path}' does not exist.")
        sys.exit(1)

    # 1. Connect to Source (SQLite)
    sqlite_engine = create_engine(f"sqlite:///{Path(source_sqlite_path).as_posix()}", echo=False)
    
    # 2. Connect to Target (PostgreSQL)
    if target_pg_url.startswith("postgres://"):
        target_pg_url = target_pg_url.replace("postgres://", "postgresql://", 1)
        
    pg_engine = create_engine(target_pg_url, echo=False, pool_pre_ping=True)

    try:
        with pg_engine.connect() as conn:
            print("[+] Successfully connected to target PostgreSQL server.")
    except Exception as e:
        print(f"[-] Error connecting to PostgreSQL: {e}")
        print("    Please verify database credentials and ensure PostgreSQL service is active.")
        sys.exit(1)

    # 3. Create all tables in PostgreSQL
    print("[*] Creating schema and tables in PostgreSQL target...")
    Base.metadata.create_all(pg_engine)
    print("[+] All tables created successfully.")

    # 4. Migrate Data in Dependency Order
    sorted_tables: List[Table] = Base.metadata.sorted_tables
    print(f"[*] Beginning migration for {len(sorted_tables)} tables...")

    total_migrated_rows = 0

    with sqlite_engine.connect() as src_conn, pg_engine.connect() as tgt_conn:
        # Disable foreign key constraints during bulk load on Postgres
        try:
            tgt_conn.execute(text("SET session_replication_role = 'replica';"))
            tgt_conn.commit()
        except Exception:
            pass

        for table in sorted_tables:
            table_name = table.name
            
            # Count rows in source
            src_count = src_conn.execute(select(func.count()).select_from(table)).scalar() or 0
            if src_count == 0:
                print(f"    - {table_name:<40} (0 rows - skipped)")
                continue

            # Read source rows
            rows = src_conn.execute(select(table)).mappings().all()
            
            # Write to PostgreSQL target in transaction
            with tgt_conn.begin():
                tgt_conn.execute(table.insert(), [dict(r) for r in rows])

            print(f"    [OK] {table_name:<40} ({src_count} rows copied)")
            total_migrated_rows += src_count

        # Re-enable foreign key constraints
        try:
            with tgt_conn.begin():
                tgt_conn.execute(text("SET session_replication_role = 'origin';"))
        except Exception:
            pass

        # 5. Reset PostgreSQL Sequences for auto-increment primary keys
        print("[*] Synchronizing PostgreSQL sequence values for auto-increment columns...")
        for table in sorted_tables:
            for col in table.primary_key.columns:
                if str(col.type).startswith("INTEGER"):
                    try:
                        seq_query = text(f"""
                            SELECT setval(
                                pg_get_serial_sequence('{table.name}', '{col.name}'),
                                COALESCE(MAX({col.name}), 1)
                            ) FROM {table.name};
                        """)
                        with tgt_conn.begin():
                            tgt_conn.execute(seq_query)
                    except Exception:
                        pass

    print()
    print("=" * 80)
    print(f"[SUCCESS] Migration completed! Total {total_migrated_rows} rows migrated across {len(sorted_tables)} tables.")
    print("To switch the application to PostgreSQL, set in your .env:")
    print(f"DATABASE_URL={target_pg_url}")
    print("=" * 80)


def main():
    parser = argparse.ArgumentParser(description="Migrate ImportFlow ERP SQLite database to PostgreSQL.")
    parser.add_argument(
        "--source",
        default=os.getenv("DATABASE_PATH", "sorour_logistics.db"),
        help="Path to source SQLite database file (default: sorour_logistics.db)",
    )
    parser.add_argument(
        "--target",
        default=os.getenv("TARGET_DATABASE_URL", ""),
        help="PostgreSQL connection URI (e.g. postgresql://<user>:<password>@localhost:5432/<database_name>)",
    )

    args = parser.parse_args()

    if not args.target:
        print("[-] Error: Target PostgreSQL URL is required. Provide --target <postgresql_uri> or set TARGET_DATABASE_URL in .env.")
        sys.exit(1)

    migrate(args.source, args.target)


if __name__ == "__main__":
    main()
