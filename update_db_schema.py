import sqlite3

def migrate_db():
    db_path = 'importflow.db'
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Check if external_service_providers table exists
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='external_service_providers'")
    table_exists = cursor.fetchone()

    if table_exists:
        # Get existing columns
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
        ]

        for col_name, col_type in new_columns:
            if col_name not in existing_cols:
                try:
                    cursor.execute(f"ALTER TABLE external_service_providers ADD COLUMN {col_name} {col_type};")
                    print(f"Added column '{col_name}' ({col_type}) to external_service_providers table.")
                except Exception as e:
                    print(f"Error adding column {col_name}: {e}")

    conn.commit()
    conn.close()
    print("Database migration completed successfully.")

if __name__ == "__main__":
    migrate_db()
