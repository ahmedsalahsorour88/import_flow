import sqlite3

def run_migration():
    conn = sqlite3.connect("importflow.db")
    cursor = conn.cursor()

    columns_to_add = [
        ("scenario_session_id", "INTEGER"),
        ("scenario_item_id", "INTEGER"),
        ("scenario_provider_name", "VARCHAR(150)"),
    ]

    for col_name, col_type in columns_to_add:
        try:
            cursor.execute(f"ALTER TABLE shipment_bookings ADD COLUMN {col_name} {col_type};")
            print(f"Added column {col_name} ({col_type})")
        except sqlite3.OperationalError as e:
            if "duplicate column name" in str(e).lower():
                print(f"Column {col_name} already exists.")
            else:
                raise e

    conn.commit()
    conn.close()
    print("Database migration for shipment_bookings scenario linkage completed successfully!")

if __name__ == "__main__":
    run_migration()
