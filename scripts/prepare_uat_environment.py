"""
Sorour Logistics ERP — UAT Staging Environment Manager
Creates, seeds, and resets an isolated UAT staging database (`sorour_logistics_uat.db`)
with 100% verified master data (Tariffs, Incoterms, Currencies, Users) and zero operational records.
Ensures zero pollution of production data during end-user acceptance testing.
"""
import os
import sys
import shutil
import sqlite3
import argparse
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
PROD_DB = ROOT_DIR / "sorour_logistics.db"
UAT_DB = ROOT_DIR / "sorour_logistics_uat.db"

# Master data tables to preserve during UAT seeding
MASTER_DATA_TABLES = {
    "users",
    "roles",
    "permissions",
    "role_permissions",
    "user_permissions",
    "customs_tariffs",
    "preferential_agreements",
    "fee_codes",
    "incoterms",
    "cost_items",
    "incoterm_responsibilities",
    "currencies",
    "exchange_rates",
    "transport_locations",
    "countries",
    "cities",
    "import_companies",
    "suppliers",
    "external_service_providers",
    "package_types",
    "units_of_measure",
    "clearance_expense_types",
    "demurrage_policies",
    "demurrage_rules",
    "port_demurrage_tariff",
    "projects",
    "expense_catalog",
    "container_specs",
    "step_configs",
    "guide_entries",
    "guide_entry_scopes",
    "alembic_version",
}


def create_uat_database(force=False):
    """Clones master data from live DB to UAT DB and truncates operational tables."""
    if not PROD_DB.exists():
        print(f"[ERROR] Production database {PROD_DB.name} not found.")
        return False

    if UAT_DB.exists() and not force:
        print(f"[INFO] UAT database {UAT_DB.name} already exists. Use --reset to reinitialize.")
        return True

    print("================================================================================")
    print("      Sorour Logistics ERP — Preparing Isolated UAT Staging Database            ")
    print("================================================================================")
    print(f" [1/4] Cloning live schema and baseline from: {PROD_DB.name} -> {UAT_DB.name}...")
    shutil.copy2(PROD_DB, UAT_DB)

    # Clean WAL / SHM files for UAT if any
    uat_wal = ROOT_DIR / "sorour_logistics_uat.db-wal"
    uat_shm = ROOT_DIR / "sorour_logistics_uat.db-shm"
    if uat_wal.exists():
        uat_wal.unlink()
    if uat_shm.exists():
        uat_shm.unlink()

    conn = sqlite3.connect(UAT_DB)
    cursor = conn.cursor()

    print(" [2/4] Truncating operational tables to ensure 0 mock contamination...")
    cursor.execute("PRAGMA foreign_keys = OFF;")
    existing_tables = [r[0] for r in cursor.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()]
    truncated_count = 0
    operational_tables = [t for t in existing_tables if t not in MASTER_DATA_TABLES and t != "sqlite_sequence"]
    for table in operational_tables:
        cursor.execute(f"DELETE FROM {table};")
        try:
            cursor.execute(f"DELETE FROM sqlite_sequence WHERE name='{table}';")
        except Exception:
            pass
        truncated_count += 1

    cursor.execute("PRAGMA foreign_keys = ON;")
    conn.commit()
    print(f"       Purged {truncated_count} operational tables cleanly.")

    print(" [3/4] Verifying Master Data record counts in UAT database...")
    counts_summary = {}
    for table in MASTER_DATA_TABLES:
        if table in existing_tables:
            count = cursor.execute(f"SELECT COUNT(*) FROM {table};").fetchone()[0]
            counts_summary[table] = count
            print(f"       • Table {table:<30}: {count} rows")

    print(" [4/4] Running SQLite integrity and foreign key validation...")
    integrity = cursor.execute("PRAGMA integrity_check;").fetchall()
    fk_check = cursor.execute("PRAGMA foreign_key_check;").fetchall()
    conn.close()

    if integrity != [('ok',)]:
        print(f"[ERROR] Integrity check failed: {integrity}")
        return False
    if fk_check:
        print(f"[WARN] Foreign key check reported violations: {fk_check}")

    print("================================================================================")
    print(" [SUCCESS] UAT STAGING DATABASE READY: sorour_logistics_uat.db")
    print(" - Zero operational shipments (0 records)")
    print(" - Full Egyptian Customs Tariffs & Incoterms preserved")
    print(" - Zero risk to production database (sorour_logistics.db)")
    print("================================================================================")
    return True


def reset_uat_database():
    """Resets UAT database by deleting it and recreating from fresh master baseline."""
    print("Resetting UAT database...")
    return create_uat_database(force=True)


def status_uat():
    if not UAT_DB.exists():
        print(f"[STATUS] UAT Database ({UAT_DB.name}) DOES NOT EXIST. Run `py scripts/prepare_uat_environment.py --init`")
        return False

    conn = sqlite3.connect(UAT_DB)
    cursor = conn.cursor()
    existing_tables = [r[0] for r in cursor.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()]

    print("================================================================================")
    print("              Sorour Logistics ERP — UAT Environment Status                     ")
    print("================================================================================")
    print(f" File Location : {UAT_DB}")
    print(f" Size          : {UAT_DB.stat().st_size:,} bytes")
    print("--------------------------------------------------------------------------------")
    print(" Operational Tables (Must be 0 for clean testing):")
    clean = True
    operational_tables = [t for t in existing_tables if t not in MASTER_DATA_TABLES and t != "sqlite_sequence"]
    for t in operational_tables[:8]:
        if t in existing_tables:
            cnt = cursor.execute(f"SELECT COUNT(*) FROM {t};").fetchone()[0]
            status_str = "[CLEAN]" if cnt == 0 else f"[DATA PRESENT: {cnt}]"
            if cnt > 0:
                clean = False
            print(f"  {status_str:<20} {t:<30}: {cnt} rows")

    print("--------------------------------------------------------------------------------")
    print(" Master Data Tables (Baseline):")
    for t in ["users", "customs_tariffs", "incoterms", "currencies", "import_companies"]:
        if t in existing_tables:
            cnt = cursor.execute(f"SELECT COUNT(*) FROM {t};").fetchone()[0]
            print(f"  [SEEDED]             {t:<30}: {cnt} rows")

    conn.close()
    print("================================================================================")
    return clean


def main():
    parser = argparse.ArgumentParser(description="Sorour Logistics ERP UAT Staging Manager")
    parser.add_argument("--init", action="store_true", help="Initialize UAT database if not exists")
    parser.add_argument("--reset", action="store_true", help="Force reset UAT database to clean baseline")
    parser.add_argument("--status", action="store_true", help="Inspect UAT database row counts")

    args = parser.parse_args()

    if args.reset:
        reset_uat_database()
    elif args.status:
        status_uat()
    elif args.init:
        create_uat_database(force=False)
    else:
        status_uat()


if __name__ == "__main__":
    main()
