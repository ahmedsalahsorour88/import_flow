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
    cur.execute("CREATE INDEX IF NOT EXISTS idx_trans_loc_type ON transport_locations(location_type);")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_trans_loc_country ON transport_locations(country);")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_trans_loc_name ON transport_locations(location_name);")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_trans_loc_city ON transport_locations(city);")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_trans_loc_active ON transport_locations(is_active);")
    conn.commit()
    conn.close()
    print(f"Created fast indexes on {db.name}")
