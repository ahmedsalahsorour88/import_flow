import sqlite3

def migrate_import_requirements():
    conn = sqlite3.connect("importflow.db")
    cursor = conn.cursor()

    columns_to_add = [
        ("supplier_id", "INTEGER"),
        ("supplier_name", "VARCHAR(200)"),
        ("white_list_verified", "BOOLEAN DEFAULT 0"),
        ("factory_registration_no", "VARCHAR(100)"),
        ("inspection_report_no", "VARCHAR(100)"),
        ("permit_number", "VARCHAR(100)"),
        ("coa_required", "BOOLEAN DEFAULT 0"),
        ("coa_status", "VARCHAR(50) DEFAULT 'Not Required'"),
        ("coa_notes", "TEXT"),
    ]

    cursor.execute("PRAGMA table_info(import_requirement_assessments);")
    existing_cols = [col[1] for col in cursor.fetchall()]

    for col_name, col_type in columns_to_add:
        if col_name not in existing_cols:
            cursor.execute(f"ALTER TABLE import_requirement_assessments ADD COLUMN {col_name} {col_type};")
            print(f"Added column {col_name} to import_requirement_assessments.")

    conn.commit()
    conn.close()
    print("Migration completed successfully.")

if __name__ == "__main__":
    migrate_import_requirements()
