import sqlite3
from database.database import Base, engine
from modules.audit_logs.model import AuditLog
from modules.cbm_calculator.model import CBMCalculation, CBMCalculationItem
from modules.purchase_orders.model import POLineItem, PackingListItem, PurchaseOrder

def migrate_db():
    # 1. Create any missing tables
    Base.metadata.create_all(bind=engine)

    # 2. Migration for columns
    db_path = 'importflow.db'
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='external_service_providers'")
    if cursor.fetchone():
        cursor.execute("PRAGMA table_info(external_service_providers)")
        existing_cols = [info[1] for info in cursor.fetchall()]

        new_columns = [
            ("tax_id", "VARCHAR(50)"),
            ("commercial_register", "VARCHAR(50)"),
            ("clearance_license_number", "VARCHAR(50)"),
            ("scac_code", "VARCHAR(20)"),
            ("tracking_url", "VARCHAR(300)"),
            ("swift_code", "VARCHAR(20)"),
            ("bank_code", "VARCHAR(20)"),
            ("branch_name", "VARCHAR(100)"),
            ("rating", "FLOAT DEFAULT 5.0"),
            ("secondary_email", "VARCHAR(150)"),
            ("fax", "VARCHAR(50)"),
            ("website", "VARCHAR(200)"),
        ]

        for col_name, col_type in new_columns:
            if col_name not in existing_cols:
                try:
                    cursor.execute(f"ALTER TABLE external_service_providers ADD COLUMN {col_name} {col_type};")
                    print(f"Added column '{col_name}' ({col_type}) to external_service_providers table.")
                except Exception as e:
                    print(f"Error adding column {col_name}: {e}")

    # Migration for suppliers table
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='suppliers'")
    if cursor.fetchone():
        cursor.execute("PRAGMA table_info(suppliers)")
        sup_cols = [info[1] for info in cursor.fetchall()]
        sup_new_cols = [
            ("secondary_email", "VARCHAR(150)"),
            ("mobile", "VARCHAR(50)"),
            ("fax", "VARCHAR(50)"),
            ("has_iso", "BOOLEAN DEFAULT 0"),
            ("registered_decree_43", "BOOLEAN DEFAULT 0"),
            ("white_list_registered", "BOOLEAN DEFAULT 0"),
        ]
        for col_name, col_type in sup_new_cols:
            if col_name not in sup_cols:
                try:
                    cursor.execute(f"ALTER TABLE suppliers ADD COLUMN {col_name} {col_type};")
                    print(f"Added column '{col_name}' ({col_type}) to suppliers table.")
                except Exception as e:
                    print(f"Error adding column {col_name} to suppliers: {e}")

    # Migration for projects table
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='projects'")
    if cursor.fetchone():
        cursor.execute("PRAGMA table_info(projects)")
        proj_cols = [info[1] for info in cursor.fetchall()]
        if "additional_company_ids" not in proj_cols:
            try:
                cursor.execute("ALTER TABLE projects ADD COLUMN additional_company_ids VARCHAR(250);")
                print("Added column 'additional_company_ids' to projects table.")
            except Exception as e:
                print(f"Error adding column additional_company_ids: {e}")

    # Migration for import_files table
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='import_files'")
    if cursor.fetchone():
        cursor.execute("PRAGMA table_info(import_files)")
        imp_cols = [info[1] for info in cursor.fetchall()]
        if "closure_reason" not in imp_cols:
            try:
                cursor.execute("ALTER TABLE import_files ADD COLUMN closure_reason TEXT;")
                print("Added column 'closure_reason' to import_files table.")
            except Exception as e:
                print(f"Error adding column closure_reason: {e}")
        if "closed_at_phase" not in imp_cols:
            try:
                cursor.execute("ALTER TABLE import_files ADD COLUMN closed_at_phase VARCHAR(100);")
                print("Added column 'closed_at_phase' to import_files table.")
            except Exception as e:
                print(f"Error adding column closed_at_phase: {e}")

    # Universal import_file_id migration for all operational tables
    target_tables = [
        "purchase_orders",
        "cbm_calculations",
        "shipping_evaluation_sessions",
        "freight_rfq_requests",
        "customs_consultation_sessions",
        "payment_request_sessions",
        "import_budget_approvals",
        "acid_registration_sessions",
        "banking_document_sessions",
        "shipment_document_items",
        "customs_declaration_drafts",
    ]

    for table_name in target_tables:
        cursor.execute(f"SELECT name FROM sqlite_master WHERE type='table' AND name='{table_name}'")
        if cursor.fetchone():
            cursor.execute(f"PRAGMA table_info({table_name})")
            cols = [info[1] for info in cursor.fetchall()]
            if "import_file_id" not in cols:
                try:
                    cursor.execute(f"ALTER TABLE {table_name} ADD COLUMN import_file_id INTEGER REFERENCES import_files(import_file_id);")
                    print(f"Added column 'import_file_id' to '{table_name}' table.")
                except Exception as e:
                    print(f"Error adding column import_file_id to {table_name}: {e}")

    conn.commit()
    conn.close()
    print("Database migration completed successfully.")

if __name__ == "__main__":
    migrate_db()
