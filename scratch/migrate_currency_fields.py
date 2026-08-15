import sqlite3

def migrate_currency_fields():
    conn = sqlite3.connect("importflow.db")
    cursor = conn.cursor()

    columns_to_add = [
        ("currency", "VARCHAR(10) DEFAULT 'USD'"),
        ("shipment_value", "FLOAT DEFAULT 0.0"),
    ]

    cursor.execute("PRAGMA table_info(import_requirement_assessments);")
    existing_cols = [col[1] for col in cursor.fetchall()]

    for col_name, col_type in columns_to_add:
        if col_name not in existing_cols:
            cursor.execute(f"ALTER TABLE import_requirement_assessments ADD COLUMN {col_name} {col_type};")
            print(f"Added column {col_name} to import_requirement_assessments.")

    conn.commit()
    conn.close()
    print("Migration for currency fields completed successfully.")

if __name__ == "__main__":
    migrate_currency_fields()
