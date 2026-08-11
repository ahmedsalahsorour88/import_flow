import sqlite3

def run_migration():
    conn = sqlite3.connect("importflow.db")
    cursor = conn.cursor()

    columns_to_add = [
        ("free_time_days", "INTEGER DEFAULT 14"),
        ("quotation_currency", "VARCHAR(10) DEFAULT 'USD'"),
        ("total_quotation_amount", "FLOAT DEFAULT 0.0"),
        
        ("container_40ft_applicable", "BOOLEAN DEFAULT 0"),
        ("container_40ft_price", "FLOAT DEFAULT 0.0"),
        ("container_40ft_currency", "VARCHAR(10) DEFAULT 'USD'"),
        ("container_40ft_qty", "INTEGER DEFAULT 0"),
        
        ("container_20ft_applicable", "BOOLEAN DEFAULT 0"),
        ("container_20ft_price", "FLOAT DEFAULT 0.0"),
        ("container_20ft_currency", "VARCHAR(10) DEFAULT 'USD'"),
        ("container_20ft_qty", "INTEGER DEFAULT 0"),
        
        ("lcl_cbm_applicable", "BOOLEAN DEFAULT 0"),
        ("lcl_cbm_price", "FLOAT DEFAULT 0.0"),
        ("lcl_cbm_currency", "VARCHAR(10) DEFAULT 'USD'"),
        ("lcl_cbm_qty", "FLOAT DEFAULT 0.0"),
        
        ("express_courier_applicable", "BOOLEAN DEFAULT 0"),
        ("express_courier_price", "FLOAT DEFAULT 0.0"),
        ("express_courier_currency", "VARCHAR(10) DEFAULT 'USD'"),
        
        ("eur_atr_applicable", "BOOLEAN DEFAULT 0"),
        ("eur_atr_price", "FLOAT DEFAULT 0.0"),
        ("eur_atr_currency", "VARCHAR(10) DEFAULT 'USD'"),
        
        ("solas_vgm_applicable", "BOOLEAN DEFAULT 0"),
        ("solas_vgm_price", "FLOAT DEFAULT 0.0"),
        ("solas_vgm_currency", "VARCHAR(10) DEFAULT 'USD'"),
        
        ("vgm_notification_applicable", "BOOLEAN DEFAULT 0"),
        ("vgm_notification_price", "FLOAT DEFAULT 0.0"),
        ("vgm_notification_currency", "VARCHAR(10) DEFAULT 'USD'"),
        
        ("telex_release_applicable", "BOOLEAN DEFAULT 0"),
        ("telex_release_price", "FLOAT DEFAULT 0.0"),
        ("telex_release_currency", "VARCHAR(10) DEFAULT 'USD'"),
        
        ("insurance_applicable", "BOOLEAN DEFAULT 0"),
        ("insurance_price", "FLOAT DEFAULT 0.0"),
        ("insurance_currency", "VARCHAR(10) DEFAULT 'USD'"),
        
        ("booking_cancellation_applicable", "BOOLEAN DEFAULT 0"),
        ("booking_cancellation_price", "FLOAT DEFAULT 0.0"),
        ("booking_cancellation_currency", "VARCHAR(10) DEFAULT 'USD'"),
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
    print("Database migration completed successfully!")

if __name__ == "__main__":
    run_migration()
