import sqlite3

def run_migration():
    conn = sqlite3.connect("importflow.db")
    cursor = conn.cursor()

    columns_to_add = [
        ("atd", "DATETIME"),
        ("departure_delay_days", "INTEGER DEFAULT 0"),
        ("expected_warehouse_days", "INTEGER DEFAULT 7"),
        ("expected_warehouse_arrival_date", "DATETIME"),
        ("container_mismatch_reason", "TEXT"),
        ("quotation_details_data", "JSON"),
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
    print("Database migration for shipment_bookings tracking fields completed successfully!")

if __name__ == "__main__":
    run_migration()
