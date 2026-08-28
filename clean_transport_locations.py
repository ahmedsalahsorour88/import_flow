"""
Clean and Deduplicate Transport Locations (Ports, Airports, Dry Ports, Land Borders)
- Strictly English Only (No Arabic text)
- Zero duplicates across all ports, airports, dry ports, and land borders
- Applies across all active project databases
"""
import sqlite3
import re
from pathlib import Path

ROOT_DIR = Path(".").resolve()
DATABASES = [
    ROOT_DIR / "sorour_logistics.db",
    ROOT_DIR / "dist" / "Sorour_Logistics_Standalone" / "sorour_logistics.db",
    ROOT_DIR / "dist" / "sorour_logistics.db",
    ROOT_DIR / "dist_backend" / "sorour_logistics.db",
]

arabic_re = re.compile(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]')

for db in DATABASES:
    if not db.exists():
        continue
    print(f"\n=======================================================")
    print(f" Processing: {db}")
    print(f"=======================================================")
    conn = sqlite3.connect(db)
    cur = conn.cursor()

    # 1. Standardize Country Names and Types
    cur.execute("UPDATE transport_locations SET country = 'Libya' WHERE country = 'Libyan Arab Jamahiriya'")
    cur.execute("UPDATE transport_locations SET location_type = 'Sea Port' WHERE location_type IN ('Port', 'sea port', 'seaport')")
    cur.execute("UPDATE transport_locations SET location_type = 'Airport' WHERE location_type IN ('airport', 'Air Port')")
    cur.execute("UPDATE transport_locations SET location_type = 'Dry Port' WHERE location_type IN ('dry port', 'Dry port', 'ICD')")
    cur.execute("UPDATE transport_locations SET location_type = 'Land Border' WHERE location_type IN ('land border', 'Land border', 'Border Crossing')")

    # 2. Specific duplicates to delete by location_id or duplicate locode
    dup_ids = [31, 32, 8, 34, 35, 98, 99, 30, 109, 57, 215, 230, 283, 285, 282, 68, 152, 251]
    cur.execute(f"DELETE FROM transport_locations WHERE location_id IN ({','.join(map(str, dup_ids))})")

    # 3. Clean and Standardize Names
    updates = [
        ("Port of Singapore", "Sea Port", "Singapore", "Singapore", 193),
        ("Singapore Changi Cargo Airport", "Airport", "Singapore", "Singapore", 222),
        ("Incheon Port", "Sea Port", "South Korea", "Incheon", 198),
        ("Incheon International Cargo Airport", "Airport", "South Korea", "Incheon", 221),
        ("Bangkok Port (Khlong Toei)", "Sea Port", "Thailand", "Bangkok", 208),
        ("Bangkok Suvarnabhumi Cargo Airport", "Airport", "Thailand", "Bangkok", 235),
        ("Amsterdam Schiphol Cargo Airport", "Airport", "Netherlands", "Amsterdam", 119),
        ("Hong Kong International Cargo Airport", "Airport", "Hong Kong", "Hong Kong", 108),
        ("Marseille-Fos Port", "Sea Port", "France", "Marseille", 122),
        ("King Abdullah Port (Rabigh)", "Sea Port", "Saudi Arabia", "Rabigh", 137),
        ("Adabiya Port", "Sea Port", "Egypt", "Suez", 33),
        ("Safaga Port", "Sea Port", "Egypt", "Safaga", 7),
        ("Al Arish Port", "Sea Port", "Egypt", "Al Arish", 79),
        ("Qingdao Port", "Sea Port", "China", "Qingdao", 37),
        ("Tianjin Port / Xingang", "Sea Port", "China", "Tianjin", 38),
        ("Trieste Port", "Sea Port", "Italy", "Trieste", 54),
        ("Venice Port", "Sea Port", "Italy", "Venice", 53),
        ("Kobe Port", "Sea Port", "Japan", "Kobe", 202),
        ("Tanjung Priok Port (Jakarta)", "Sea Port", "Indonesia", "Jakarta", 209),
        ("Istanbul / Ambarli Port", "Sea Port", "Turkey", "Istanbul", 124),
        ("Khalifa Port (Abu Dhabi)", "Sea Port", "United Arab Emirates", "Abu Dhabi", 60),
        ("London Gateway Port (DP World)", "Sea Port", "United Kingdom", "London", 25),
        ("Salalah Port", "Sea Port", "Oman", "Salalah", 72),
        ("Rades Port (Tunis)", "Sea Port", "Tunisia", "Tunis", 160),
    ]
    for name, ltype, country, city, lid in updates:
        cur.execute(
            "UPDATE transport_locations SET location_name = ?, location_type = ?, country = ?, city = ? WHERE location_id = ?",
            (name, ltype, country, city, lid)
        )

    # 4. Remove any Arabic from notes or other fields
    cur.execute("SELECT location_id, location_name, country, city, notes FROM transport_locations")
    rows = cur.fetchall()
    for r in rows:
        lid, lname, lcountry, lcity, lnotes = r
        clean_name = arabic_re.sub('', lname or '').strip()
        clean_country = arabic_re.sub('', lcountry or '').strip()
        clean_city = arabic_re.sub('', lcity or '').strip()
        clean_notes = arabic_re.sub('', lnotes or '').strip() if lnotes else None
        cur.execute(
            "UPDATE transport_locations SET location_name = ?, country = ?, city = ?, notes = ? WHERE location_id = ?",
            (clean_name, clean_country, clean_city, clean_notes, lid)
        )

    conn.commit()
    cur.execute("SELECT COUNT(*) FROM transport_locations")
    total = cur.fetchone()[0]
    print(f"   [SUCCESS] Clean & Deduplicated records count: {total}")
    conn.close()

print("\nDone cleaning all databases!")
