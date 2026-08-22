import sqlite3
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent

DATABASES = [
    ROOT_DIR / "sorour_logistics.db",
    ROOT_DIR / "dist" / "ImportFlow_Standalone" / "sorour_logistics.db",
    ROOT_DIR / "dist" / "sorour_logistics.db",
    ROOT_DIR / "dist_backend" / "sorour_logistics.db",
]

for db in DATABASES:
    if not db.exists():
        continue
    conn = sqlite3.connect(db)
    cur = conn.cursor()
    try:
        cur.execute("ALTER TABLE packing_list_items ADD COLUMN weight_unit VARCHAR(30) DEFAULT 'KGM';")
        conn.commit()
        print(f"Successfully added 'weight_unit' column to {db.name}")
    except Exception as e:
        print(f"Notice for {db.name}: {e}")
    conn.close()
