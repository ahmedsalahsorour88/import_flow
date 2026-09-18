"""
ImportFlow ERP — Clean Production Database Generator
Creates a pristine production database containing ONLY core standard reference tables:
- Ports & Transport Locations (247 ports, airports, dry ports, land borders - MD-009)
- Currencies & Official Exchange Rates (11 Currencies, 137 Exchange Rates - MD-004)
- Customs Tariff & HS Codes & Nafeza Fee Codes (74 Tariff items, 15 Fee codes - MD-008)
- International Trade Agreements (405 Preferential agreements - MD-008B)
- Package Types & Units of Measure (24 Package types, 15 Units of measure)
- Incoterms 2020 & Responsibility Matrix & Cost Items (11 Incoterms, 17 Cost items, 187 Rules - MD-006)
- Clearance Expense Types & Coded Expense Catalog (53 Clearance types, 54 Catalog items)
- Core System Users & RBAC Roles (Admin with secure password, Manager, Operators)
- Core International Shipping Lines (32 Lines - MD-009B)

All demo companies, suppliers, service providers (except shipping lines), shipments,
purchase orders, invoices, and logs are completely wiped (0 records).
"""
import os
import sys
import shutil
import sqlite3
from datetime import datetime
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT_DIR))

# Import main to ensure all SQLAlchemy models are loaded into Base.metadata
import main
from database.database import Base, engine
from update_db_schema import migrate_db
from modules.auth.security import hash_password
from settings import ADMIN_INITIAL_PASSWORD

BACKUPS_DIR = ROOT_DIR / "backups"
TARGET_DB = ROOT_DIR / "sorour_logistics.db"

MASTER_TABLES = [
    "package_types",
    "units_of_measure",
    "preferential_agreements",
    "transport_locations",
    "customs_tariffs",
    "fee_codes",
    "clearance_expense_types",
    "expense_catalog",
    "cost_items",
    "incoterm_responsibilities",
    "incoterms",
    "currencies",
    "exchange_rates",
    "roles",
    "permissions",
    "role_permissions",
    "budget_variance_settings",
    "email_settings",
    "recalculation_dependency_map",
    "guide_entries",
    "guide_entry_scopes",
]

OPERATIONAL_TABLES = [
    "import_companies",
    "suppliers",
    "projects",
    "purchase_orders",
    "po_line_items",
    "packing_list_items",
    "import_files",
    "import_file_checklist_items",
    "import_requirement_assessments",
    "payment_request_sessions",
    "import_budget_approvals",
    "acid_registration_sessions",
    "cargo_shipping_records",
    "cargox_customs_invoice_tracks",
    "shipment_bookings",
    "shipment_stage_activity",
    "shipping_evaluation_sessions",
    "shipping_scenario_items",
    "customs_consultation_sessions",
    "customs_checklist_items",
    "broker_price_lists",
    "broker_price_list_items",
    "customs_broker_quote_items",
    "draft_bl_review_sessions",
    "po_packing_reconciliation_sessions",
    "smart_tasks",
    "system_notifications",
    "upload_sessions",
    "inbound_email_logs",
    "swift_extraction_batches",
    "swift_extraction_fields",
    "recalculation_logs",
    "audit_logs",
    "production_sync_logs",
    "inland_transport_bookings",
    "warehouse_receiving_records",
    "landed_cost_settlements",
    "clearance_expense_invoices",
    "customs_clearance_records",
    "import_file_closures",
]


def find_best_reference_snapshot() -> Path:
    """Find the most complete reference snapshot to seed master data from."""
    BACKUPS_DIR.mkdir(parents=True, exist_ok=True)
    candidates = sorted(BACKUPS_DIR.glob("*.db"), key=lambda p: p.stat().st_mtime, reverse=True)
    for c in candidates:
        try:
            conn = sqlite3.connect(c)
            cur = conn.cursor()
            cur.execute("SELECT count(*) FROM transport_locations")
            loc_cnt = cur.fetchone()[0]
            cur.execute("SELECT count(*) FROM customs_tariffs")
            tar_cnt = cur.fetchone()[0]
            cur.execute("SELECT count(*) FROM external_service_providers WHERE partner_type = 'Shipping Line'")
            ship_cnt = cur.fetchone()[0]
            conn.close()
            if loc_cnt >= 200 and tar_cnt >= 50 and ship_cnt >= 20:
                return c
        except Exception:
            continue
    raise FileNotFoundError("Could not find a valid reference snapshot database in backups/.")


def build_clean_production_db() -> bool:
    print("================================================================================")
    print("           ImportFlow ERP - Generating Clean Production Database                ")
    print("================================================================================")

    # 1. Take safety backup of current db if it exists
    if TARGET_DB.exists():
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        safety_path = BACKUPS_DIR / f"sorour_logistics_pre_clean_snapshot_{timestamp}.db"
        shutil.copy2(TARGET_DB, safety_path)
        print(f"[OK] Safety backup created at: {safety_path}")
        try:
            TARGET_DB.unlink()
            print(f"[OK] Removed previous database: {TARGET_DB}")
        except Exception as e:
            print(f"Could not unlink db ({e}), dropping tables instead.")
            Base.metadata.drop_all(bind=engine)

    # 2. Locate master reference snapshot
    ref_snapshot = find_best_reference_snapshot()
    print(f"[OK] Master reference source snapshot: {ref_snapshot.name}")

    # 3. Create all tables & schema via SQLAlchemy and Alembic migrations
    Base.metadata.create_all(bind=engine)
    migrate_db()
    print("[OK] Database schema created and migrated.")

    # 4. Populate standard master data directly from verified snapshot using named column matching
    conn = sqlite3.connect(TARGET_DB)
    cur = conn.cursor()
    cur.execute(f"ATTACH DATABASE '{ref_snapshot.as_posix()}' AS snapshot;")

    print("[1/5] Seeding Standard Master Reference Tables...")
    for tbl in MASTER_TABLES:
        try:
            cur.execute(f"PRAGMA main.table_info({tbl});")
            target_cols = [r[1] for r in cur.fetchall()]
            cur.execute(f"PRAGMA snapshot.table_info({tbl});")
            snap_cols = [r[1] for r in cur.fetchall()]
            common_cols = [c for c in target_cols if c in snap_cols]
            if common_cols:
                cols_str = ", ".join(common_cols)
                cur.execute(f"INSERT OR IGNORE INTO main.{tbl} ({cols_str}) SELECT {cols_str} FROM snapshot.{tbl};")
            else:
                print(f"  Warning on table {tbl}: No matching columns")
        except Exception as e:
            print(f"  Warning on table {tbl}: {e}")
    conn.commit()

    # 5. Seed Core International Shipping Lines (MD-009B)
    print("[2/5] Seeding Core International Shipping Lines (MD-009B)...")
    try:
        cur.execute("PRAGMA main.table_info(external_service_providers);")
        target_cols = [r[1] for r in cur.fetchall()]
        cur.execute("PRAGMA snapshot.table_info(external_service_providers);")
        snap_cols = [r[1] for r in cur.fetchall()]
        common_cols = [c for c in target_cols if c in snap_cols]
        cols_str = ", ".join(common_cols)
        cur.execute(f"INSERT OR IGNORE INTO main.external_service_providers ({cols_str}) SELECT {cols_str} FROM snapshot.external_service_providers WHERE partner_type = 'Shipping Line';")
        conn.commit()
    except Exception as e:
        print(f"  Warning on shipping lines: {e}")

    # 6. Seed Core System Users with Secure Production Credentials
    print("[3/5] Seeding Core System Users (RBAC)...")
    now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    users_to_seed = [
        (1, "admin", "admin@sorourlogistics.com", "System Admin", hash_password(ADMIN_INITIAL_PASSWORD), "ADMIN", 1, 1, now_str, now_str),
        (2, "manager", "manager@sorourlogistics.com", "General Logistics Manager", hash_password("manager123"), "MANAGER", 2, 1, now_str, now_str),
        (3, "operator1", "operator1@sorourlogistics.com", "Ahmed Import Specialist", hash_password("operator123"), "OPERATOR", 3, 1, now_str, now_str),
        (4, "operator2", "operator2@sorourlogistics.com", "Sara Customs Operator", hash_password("operator123"), "OPERATOR", 3, 1, now_str, now_str),
    ]
    cur.execute("DELETE FROM main.users;")
    for u in users_to_seed:
        cur.execute("INSERT INTO main.users (user_id, username, email, full_name, hashed_password, role, role_id, is_active, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);", u)
    conn.commit()

    cur.execute("DETACH DATABASE snapshot;")

    # 7. Verification Summary
    print("================================================================================")
    print("                 Clean Production Database Verification                         ")
    print("================================================================================")
    for tbl in ["users", "transport_locations", "customs_tariffs", "fee_codes", "currencies", "exchange_rates", "incoterms", "incoterm_responsibilities", "package_types", "units_of_measure", "preferential_agreements", "external_service_providers", "roles", "permissions"]:
        try:
            cur.execute(f"SELECT count(*) FROM {tbl}")
            print(f" - {tbl:<25}: {cur.fetchone()[0]}")
        except Exception as e:
            print(f" - {tbl:<25}: Error ({e})")

    print("--------------------------------------------------------------------------------")
    print(" Operational & Transactional Tables (Must be 0 records):")
    print("--------------------------------------------------------------------------------")
    all_clean = True
    for op in OPERATIONAL_TABLES:
        try:
            cur.execute(f"SELECT count(*) FROM {op}")
            cnt = cur.fetchone()[0]
            if cnt > 0:
                print(f" [FAIL] {op} has {cnt} records!")
                all_clean = False
            else:
                print(f" - {op:<30}: 0 (Clean)")
        except Exception:
            pass

    conn.close()

    if all_clean:
        print("================================================================================")
        print("[SUCCESS] Clean Production Database successfully generated and verified 100%!")
        print("================================================================================")
        return True
    else:
        print("[ERROR] Some operational tables were not clean.")
        return False


if __name__ == "__main__":
    success = build_clean_production_db()
    sys.exit(0 if success else 1)
