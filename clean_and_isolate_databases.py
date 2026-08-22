import sqlite3
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent

DATABASES = [
    ROOT_DIR / "sorour_logistics.db",
    ROOT_DIR / "dist" / "ImportFlow_Standalone" / "sorour_logistics.db",
    ROOT_DIR / "dist" / "sorour_logistics.db",
    ROOT_DIR / "dist_backend" / "sorour_logistics.db",
]

# Operational & Demo Tables to clean completely (0 records)
WIPE_TABLES = [
    "import_companies",
    "suppliers",
    "external_service_providers",
    "cargox_envelopes",
    "cargox_envelope_documents",
    "cargox_sessions",
    "projects",
    "purchase_orders",
    "po_line_items",
    "packing_list_items",
    "import_files",
    "customs_clearance_operations",
    "freight_bookings",
    "freight_quotations",
    "original_documents_archive",
    "bank_form4_records",
    "notifications",
    "audit_logs",
    "stage_discrepancies",
    "step_action_logs",
]

for db in DATABASES:
    if not db.exists():
        continue
    print(f"\n=======================================================")
    print(f" Wiping demo tables in: {db}")
    print(f"=======================================================")
    conn = sqlite3.connect(db)
    cur = conn.cursor()
    
    # Disable foreign keys temporarily for clean wipe
    cur.execute("PRAGMA foreign_keys = OFF;")
    
    for tbl in WIPE_TABLES:
        try:
            cur.execute(f"DELETE FROM {tbl};")
            cur.execute(f"DELETE FROM sqlite_sequence WHERE name='{tbl}';")
            print(f"   ✓ Wiped table '{tbl}' -> 0 records")
        except Exception as e:
            # Table might not exist in some DB versions
            pass
            
    conn.commit()
    cur.execute("PRAGMA foreign_keys = ON;")
    
    # Verification
    print("\n   --- Verified Cleansed Tables Status ---")
    for tbl in ["import_companies", "suppliers", "external_service_providers", "cargox_envelopes", "projects", "purchase_orders", "import_files"]:
        try:
            cur.execute(f"SELECT count(*) FROM {tbl};")
            cnt = cur.fetchone()[0]
            print(f"   * {tbl}: {cnt} records")
        except Exception as e:
            print(f"   * {tbl}: N/A")
            
    # Also verify Master Data is preserved
    print("   --- Preserved Master Data ---")
    for tbl in ["countries", "currencies", "cities", "transport_locations", "package_types", "units_of_measure"]:
        try:
            cur.execute(f"SELECT count(*) FROM {tbl};")
            cnt = cur.fetchone()[0]
            print(f"   * {tbl}: {cnt} records")
        except Exception as e:
            print(f"   * {tbl}: N/A")
            
    conn.close()

print("\n[SUCCESS] All operational tables wiped to 0 records across all database locations!")
