"""
Sorour Logistics ERP — Clean Production Database Isolator & Wiper
===================================================================
Enforces the mandatory rule:
Every new production release MUST be completely clean and empty of any user/operational records (0 records),
preserving ONLY core master reference tables:
  1. Ports & Transport Locations (transport_locations, countries, cities)
  2. HS Codes & Egyptian Customs Tariffs (customs_tariffs, fee_codes, preferential_agreements)
  3. Incoterms 2020 & Responsibility Matrix & Cost Items (incoterms, cost_items, incoterm_responsibilities)
  4. Currencies & Exchange Rates (currencies, exchange_rates)
  5. System Core & RBAC Users (users, container_specs, package_types, units_of_measure, clearance_expense_types)
"""
import sys
import sqlite3
from pathlib import Path

# Force UTF-8 stdout/stderr on Windows
try:
    if sys.stdout and hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if sys.stderr and hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

ROOT_DIR = Path(__file__).resolve().parent

DATABASES = [
    ROOT_DIR / "sorour_logistics.db",
    ROOT_DIR / "dist" / "Sorour_Logistics_Standalone" / "sorour_logistics.db",
    ROOT_DIR / "dist" / "ImportFlow_Standalone" / "sorour_logistics.db",
    ROOT_DIR / "dist" / "sorour_logistics.db",
    ROOT_DIR / "dist_backend" / "sorour_logistics.db",
]

PRESERVED_TABLES = {
    "transport_locations",
    "countries",
    "cities",
    "customs_tariffs",
    "fee_codes",
    "preferential_agreements",
    "incoterms",
    "cost_items",
    "incoterm_responsibilities",
    "currencies",
    "exchange_rates",
    "users",
    "container_specs",
    "package_types",
    "units_of_measure",
    "clearance_expense_types",
}


def clean_database(db_path: Path) -> bool:
    if not db_path.exists():
        return False
    print(f"\n=======================================================")
    print(f" [CLEAN] Wiping Operational & Demo Data in: {db_path.name}")
    print(f"=======================================================")
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # Disable foreign keys temporarily for clean wipe
    cur.execute("PRAGMA foreign_keys = OFF;")

    cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
    all_tables = [row[0] for row in cur.fetchall()]

    wiped_count = 0
    for tbl in all_tables:
        if tbl not in PRESERVED_TABLES:
            try:
                cur.execute(f'DELETE FROM "{tbl}";')
                wiped_count += 1
            except Exception as e:
                print(f"   [WARN] Could not wipe table {tbl}: {e}")
            try:
                cur.execute(f'DELETE FROM sqlite_sequence WHERE name="{tbl}";')
            except Exception:
                pass

    conn.commit()
    cur.execute("PRAGMA foreign_keys = ON;")
    cur.execute("VACUUM;")
    conn.commit()

    print(f"   [OK] Wiped {wiped_count} operational tables to 0 records.")
    print(f"   [OK] Preserved {len(PRESERVED_TABLES)} master data tables intact.")

    # Integrity verification
    print("   --- Preserved Master Data Counts ---")
    for tbl in sorted(PRESERVED_TABLES):
        if tbl in all_tables:
            try:
                cur.execute(f'SELECT COUNT(*) FROM "{tbl}";')
                cnt = cur.fetchone()[0]
                print(f"   * {tbl:<30}: {cnt:>5} records")
            except Exception:
                pass

    conn.close()
    return True


def clean_all_databases():
    print("\n===============================================================================")
    print("  [RULE] Mandatory Clean Production Database Enforcement")
    print("  All operational data wiped | Ports, HS Codes, Incoterms, Currencies Preserved")
    print("===============================================================================")
    for db in DATABASES:
        clean_database(db)
    print("\n[SUCCESS] Production databases cleansed strictly according to release rules!")


if __name__ == "__main__":
    clean_all_databases()
