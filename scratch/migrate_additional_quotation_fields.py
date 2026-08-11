import sqlite3

def run_migration():
    conn = sqlite3.connect("importflow.db")
    cursor = conn.cursor()

    columns_to_add = [
        ("ics2_filing_fee_applicable", "BOOLEAN DEFAULT 0"),
        ("ics2_filing_fee_price", "FLOAT DEFAULT 0.0"),
        ("ics2_filing_fee_currency", "VARCHAR(10) DEFAULT 'USD'"),

        ("others_fee_applicable", "BOOLEAN DEFAULT 0"),
        ("others_fee_price", "FLOAT DEFAULT 0.0"),
        ("others_fee_currency", "VARCHAR(10) DEFAULT 'USD'"),

        ("document_fees_applicable", "BOOLEAN DEFAULT 0"),
        ("document_fees_price", "FLOAT DEFAULT 0.0"),
        ("document_fees_currency", "VARCHAR(10) DEFAULT 'USD'"),

        ("waiver_letter_fee_applicable", "BOOLEAN DEFAULT 0"),
        ("waiver_letter_fee_price", "FLOAT DEFAULT 0.0"),
        ("waiver_letter_fee_currency", "VARCHAR(10) DEFAULT 'USD'"),
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
    print("Database migration for additional columns completed successfully!")

if __name__ == "__main__":
    run_migration()
