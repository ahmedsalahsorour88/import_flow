import sqlite3

def run_migration():
    conn = sqlite3.connect("importflow.db")
    cursor = conn.cursor()

    columns_to_add = [
        ("dthc_applicable", "BOOLEAN DEFAULT 0"),
        ("dthc_price", "FLOAT DEFAULT 0.0"),
        ("dthc_currency", "VARCHAR(10) DEFAULT 'USD'"),

        ("storage_per_week_applicable", "BOOLEAN DEFAULT 0"),
        ("storage_per_week_price", "FLOAT DEFAULT 0.0"),
        ("storage_per_week_currency", "VARCHAR(10) DEFAULT 'USD'"),

        ("extra_day_storage_applicable", "BOOLEAN DEFAULT 0"),
        ("extra_day_storage_price", "FLOAT DEFAULT 0.0"),
        ("extra_day_storage_currency", "VARCHAR(10) DEFAULT 'USD'"),
    ]

    for col_name, col_type in columns_to_add:
        try:
            cursor.execute(f"ALTER TABLE shipping_scenario_items ADD COLUMN {col_name} {col_type};")
            print(f"Added column {col_name} ({col_type})")
        except sqlite3.OperationalError as e:
            if "duplicate column name" in str(e).lower():
                print(f"Column {col_name} already exists.")
            else:
                raise e

    conn.commit()
    conn.close()
    print("Database migration for DTHC and Storage columns completed successfully!")

if __name__ == "__main__":
    run_migration()
