"""
ImportFlow ERP — Production Synchronization & Deployment Utility
================================================================
أداة مزامنة ونقل التحديثات بين بيئة التطوير (Dev) والإنتاج (Production).

Features:
- Safe Database Push (Dev -> Prod) with automatic timestamped backup.
- Safe Database Pull (Prod -> Dev) with automatic timestamped backup.
- Table-by-table record count comparison & health check.
- Frontend & Backend Compilation & Production Bundling.
- Standalone Package Updates (ImportFlow_Standalone).
- Release ZIP Packaging & Manifest Generation.
- 1-Click Production App Launcher.
"""

import os
import sys
import shutil
import sqlite3
import argparse
import subprocess
from datetime import datetime
from pathlib import Path

# Force UTF-8 on Windows stdout/stderr
try:
    if sys.stdout and hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if sys.stderr and hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

# Paths
ROOT_DIR = Path(__file__).resolve().parent
DIST_DIR = ROOT_DIR / "dist"
STANDALONE_DIR = DIST_DIR / "ImportFlow_Standalone"
DESKTOP_DIR = DIST_DIR / "ImportFlow_Desktop"
WEB_DIR = DIST_DIR / "ImportFlow_Web"
BACKUPS_DIR = ROOT_DIR / "backups"

DEV_DB = ROOT_DIR / "sorour_logistics.db"
PROD_DB = STANDALONE_DIR / "sorour_logistics.db"
BACKEND_EXE = ROOT_DIR / "dist_backend" / "backend.exe"
FRONTEND_WINDOWS_RELEASE = ROOT_DIR / "frontend" / "build" / "windows" / "x64" / "runner" / "Release"


def create_backup(db_path: Path, tag: str = "backup") -> Path:
    """Creates a timestamped backup of a SQLite database."""
    if not db_path.exists():
        return None
    BACKUPS_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = BACKUPS_DIR / f"{db_path.stem}_{tag}_{timestamp}.db"
    shutil.copy2(db_path, backup_file)
    print(f"   [BACKUP] تم إنشاء نسخة احتياطية آمنة: {backup_file.name} ({backup_file.stat().st_size / 1024:.1f} KB)")
    return backup_file


def get_db_stats(db_path: Path) -> dict:
    """Returns table count, record counts, and file size for a database."""
    if not db_path.exists():
        return {"exists": False}
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
        tables = [row[0] for row in cursor.fetchall()]
        
        counts = {}
        total_records = 0
        for table in tables:
            try:
                cursor.execute(f"SELECT COUNT(*) FROM \"{table}\";")
                c = cursor.fetchone()[0]
                counts[table] = c
                total_records += c
            except Exception:
                counts[table] = 0
        conn.close()
        return {
            "exists": True,
            "size_kb": round(db_path.stat().st_size / 1024, 1),
            "tables_count": len(tables),
            "total_records": total_records,
            "table_counts": counts,
            "mtime": datetime.fromtimestamp(db_path.stat().st_mtime).strftime("%Y-%m-%d %H:%M:%S"),
        }
    except Exception as e:
        return {"exists": True, "error": str(e)}


def compare_databases():
    """Compares Dev and Prod databases table by table."""
    print("\n===============================================================================")
    print(" [CHECK] فحص ومقارنة قاعدة بيانات التطوير (Dev) مع الإنتاج (Production) ")
    print("===============================================================================")
    
    dev_stats = get_db_stats(DEV_DB)
    prod_stats = get_db_stats(PROD_DB)

    print(f"\n[DEV DB]  قاعدة بيانات التطوير: {DEV_DB}")
    if dev_stats.get("exists"):
        print(f"   - الحجم: {dev_stats['size_kb']} KB | الجداول: {dev_stats['tables_count']} | إجمالي السجلات: {dev_stats['total_records']}")
        print(f"   - آخر تعديل: {dev_stats['mtime']}")
    else:
        print("   [!] غير موجودة!")

    print(f"\n[PROD DB] قاعدة بيانات الإنتاج:  {PROD_DB}")
    if prod_stats.get("exists"):
        print(f"   - الحجم: {prod_stats['size_kb']} KB | الجداول: {prod_stats['tables_count']} | إجمالي السجلات: {prod_stats['total_records']}")
        print(f"   - آخر تعديل: {prod_stats['mtime']}")
    else:
        print("   [!] غير موجودة بعد (سيتم إنشاؤها عند أول مزامنة)")

    if dev_stats.get("exists") and prod_stats.get("exists"):
        print("\n[TABLE STATS] مقارنة السجلات في الجداول:")
        print(f"{'اسم الجدول (Table)':<35} | {'التطوير (Dev)':<15} | {'الإنتاج (Prod)':<15} | {'الحالة (Status)':<10}")
        print("-" * 85)
        
        all_tables = sorted(set(list(dev_stats.get("table_counts", {}).keys()) + list(prod_stats.get("table_counts", {}).keys())))
        for tbl in all_tables:
            dev_c = dev_stats.get("table_counts", {}).get(tbl, 0)
            prod_c = prod_stats.get("table_counts", {}).get(tbl, 0)
            status = "MATCH (متطابق)" if dev_c == prod_c else f"DIFF ({dev_c - prod_c:+d})"
            print(f"{tbl:<35} | {dev_c:<15} | {prod_c:<15} | {status}")
    print("===============================================================================\n")


def smart_non_destructive_migrate(src_db: Path, target_db: Path) -> dict:
    """
    Enterprise Non-Destructive Migration:
    1. Creates any missing tables from src in target.
    2. Adds any new columns via ALTER TABLE ADD COLUMN.
    3. Merges rows with INSERT OR IGNORE preserving 100% of target user data.
    """
    if not target_db.exists():
        target_db.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src_db, target_db)
        return {"status": "fresh_copy", "tables_added": 0, "columns_added": 0, "rows_merged": 0}

    conn_src = sqlite3.connect(src_db)
    cur_src = conn_src.cursor()

    conn_tgt = sqlite3.connect(target_db)
    cur_tgt = conn_tgt.cursor()

    cur_src.execute("SELECT name, sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
    src_tables = cur_src.fetchall()

    cur_tgt.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
    tgt_table_names = set(r[0] for r in cur_tgt.fetchall())

    tables_added = 0
    columns_added = 0
    rows_merged = 0

    # 1. Create missing tables
    for tbl_name, tbl_sql in src_tables:
        if tbl_name not in tgt_table_names:
            if tbl_sql:
                cur_tgt.execute(tbl_sql)
                tables_added += 1
                tgt_table_names.add(tbl_name)

    # 2. Add missing columns
    for tbl_name, _ in src_tables:
        if tbl_name in tgt_table_names:
            try:
                cur_src.execute(f'PRAGMA table_info("{tbl_name}");')
                src_cols = {row[1]: row[2] for row in cur_src.fetchall()}

                cur_tgt.execute(f'PRAGMA table_info("{tbl_name}");')
                tgt_cols = set(row[1] for row in cur_tgt.fetchall())

                for col_name, col_type in src_cols.items():
                    if col_name not in tgt_cols:
                        cur_tgt.execute(f'ALTER TABLE "{tbl_name}" ADD COLUMN "{col_name}" {col_type};')
                        columns_added += 1
            except Exception:
                pass

    conn_tgt.commit()

    # 3. Merge new reference & schema rows with INSERT OR IGNORE
    for tbl_name, _ in src_tables:
        try:
            cur_src.execute(f'PRAGMA table_info("{tbl_name}");')
            src_cols = [row[1] for row in cur_src.fetchall()]
            
            cur_tgt.execute(f'PRAGMA table_info("{tbl_name}");')
            tgt_cols = set(row[1] for row in cur_tgt.fetchall())
            
            common_cols = [c for c in src_cols if c in tgt_cols]
            if not common_cols:
                continue

            cols_str = ", ".join([f'"{c}"' for c in common_cols])
            placeholders = ", ".join(["?"] * len(common_cols))

            cur_src.execute(f'SELECT {cols_str} FROM "{tbl_name}";')
            src_rows = cur_src.fetchall()

            for row in src_rows:
                cur_tgt.execute(
                    f'INSERT OR IGNORE INTO "{tbl_name}" ({cols_str}) VALUES ({placeholders});',
                    tuple(row),
                )
                if cur_tgt.rowcount > 0:
                    rows_merged += 1
        except Exception:
            pass

    conn_tgt.commit()
    conn_src.close()
    conn_tgt.close()

    return {
        "status": "migrated_safely",
        "tables_added": tables_added,
        "columns_added": columns_added,
        "rows_merged": rows_merged,
    }


def sync_db_to_prod():
    """Syncs Dev DB -> Prod DB non-destructively with safety backup."""
    print("\n===============================================================================")
    print(" [SYNC] مزامنة وتحديث قاعدة بيانات الإنتاج (Non-Destructive Safe Sync) ")
    print("===============================================================================")
    
    if not DEV_DB.exists():
        print(f"[ERROR] لم يتم العثور على قاعدة بيانات التطوير: {DEV_DB}")
        return False

    # 1. Backup Prod DB if exists
    if PROD_DB.exists():
        create_backup(PROD_DB, "prod_before_sync")
    
    # 2. Backup Dev DB as well
    create_backup(DEV_DB, "dev_snapshot")

    # 3. Ensure Standalone directory exists
    STANDALONE_DIR.mkdir(parents=True, exist_ok=True)

    # 4. Smart Non-Destructive Migration
    res = smart_non_destructive_migrate(DEV_DB, PROD_DB)
    print(f"[SUCCESS] تم تطبيق المزامنة والتحديثات بأمان على البرودكشن: {PROD_DB}")
    print(f"   - الجداول الجديدة المضافة: {res['tables_added']}")
    print(f"   - الحقول الجديدة المضافة: {res['columns_added']}")
    print(f"   - السجلات الجديدة المدمجة: {res['rows_merged']}")

    # Also migrate to root dist if used
    if (DIST_DIR / "sorour_logistics.db").exists() or DIST_DIR.exists():
        try:
            smart_non_destructive_migrate(DEV_DB, DIST_DIR / "sorour_logistics.db")
        except Exception:
            pass

    stats = get_db_stats(PROD_DB)
    print(f"\n[STATS] إحصائيات قاعدة بيانات الإنتاج بعد المزامنة:")
    print(f"   - الحجم: {stats.get('size_kb')} KB")
    print(f"   - عدد الجداول: {stats.get('tables_count')}")
    print(f"   - إجمالي السجلات: {stats.get('total_records')}")
    print("===============================================================================\n")
    return True


def pull_prod_db_to_dev():
    """Pulls Prod DB -> Dev DB non-destructively with safety backup."""
    print("\n===============================================================================")
    print(" [PULL] سحب بيانات الإنتاج الفعلية إلى بيئة التطوير (Safe Pull Prod -> Dev) ")
    print("===============================================================================")
    
    if not PROD_DB.exists():
        print(f"[ERROR] لم يتم العثور على قاعدة بيانات الإنتاج: {PROD_DB}")
        return False

    # 1. Backup Dev DB
    create_backup(DEV_DB, "dev_before_pull")

    # 2. Backup Prod DB
    create_backup(PROD_DB, "prod_snapshot")

    # 3. Smart Non-Destructive Migration Prod -> Dev
    res = smart_non_destructive_migrate(PROD_DB, DEV_DB)
    print(f"[SUCCESS] تم سحب ودمج بيانات البرودكشن بنجاح إلى بيئة التطوير: {DEV_DB}")
    print(f"   - الجداول الجديدة: {res['tables_added']}")
    print(f"   - الحقول الجديدة: {res['columns_added']}")
    print(f"   - السجلات المدمجة: {res['rows_merged']}")

    stats = get_db_stats(DEV_DB)
    print(f"\n[STATS] إحصائيات قاعدة بيانات التطوير بعد السحب:")
    print(f"   - الحجم: {stats.get('size_kb')} KB")
    print(f"   - عدد الجداول: {stats.get('tables_count')}")
    print(f"   - إجمالي السجلات: {stats.get('total_records')}")
    print("===============================================================================\n")
    return True


def full_production_build_and_sync():
    """Executes full tests, compilation, packaging, and sync."""
    print("\n===============================================================================")
    print(" [FULL BUILD] بناء وتحديث الفرونت والباك إند بالكامل للبرودكشن ")
    print("===============================================================================")

    # 1. Backend tests
    print("\n[1/6] [TEST] تشغيل اختبارات الباك إند (pytest)...")
    res = subprocess.run([sys.executable, "-m", "pytest", "-q"], cwd=str(ROOT_DIR))
    if res.returncode != 0:
        print("[ERROR] فشلت اختبارات الباك إند! تم إيقاف عملية البناء.")
        return False
    print("   [PASS] اختبارات الباك إند اجتيزت بنجاح (100% Passing).")

    # 2. Frontend tests
    print("\n[2/6] [TEST] تشغيل اختبارات الفرونت إند (flutter test)...")
    frontend_dir = ROOT_DIR / "frontend"
    res = subprocess.run(["flutter", "test"], cwd=str(frontend_dir), shell=True)
    if res.returncode != 0:
        print("[ERROR] فشلت اختبارات الفرونت إند! تم إيقاف عملية البناء.")
        return False
    print("   [PASS] اختبارات الفرونت إند اجتيزت بنجاح (100% Passing).")

    # 3. Compile Flutter Windows Release
    print("\n[3/6] [BUILD] تجميع تطبيق الويندوز المكتبي (flutter build windows --release)...")
    res = subprocess.run(["flutter", "build", "windows", "--release"], cwd=str(frontend_dir), shell=True)
    if res.returncode != 0:
        print("[ERROR] فشل تجميع تطبيق الويندوز المكتبي!")
        return False
    print("   [SUCCESS] تم تجميع ملفات تطبيق الويندوز المكتبي بنجاح.")

    # 4. Package Production Standalone
    print("\n[4/6] [PACKAGE] تجميع حزمة الإنتاج المستقلة (package_production.py)...")
    res = subprocess.run([sys.executable, str(ROOT_DIR / "package_production.py")], cwd=str(ROOT_DIR))
    if res.returncode != 0:
        print("[ERROR] فشل تجميع حزمة الإنتاج المستقلة!")
        return False
    print("   [SUCCESS] تم تحديث حزمة Standalone وتضمين أحدث قاعدة بيانات.")

    # 5. Sync Database
    print("\n[5/6] [DB SYNC] مزامنة قاعدة البيانات الحالية إلى الإنتاج...")
    sync_db_to_prod()

    # 6. Create Release Bundle ZIP & Manifest
    print("\n[6/6] [ZIP BUNDLE] إنشاء حزمة التوزيع المضغوطة (create_release_bundle.py)...")
    if (ROOT_DIR / "create_release_bundle.py").exists():
        subprocess.run([sys.executable, str(ROOT_DIR / "create_release_bundle.py")], cwd=str(ROOT_DIR))

    print("\n===============================================================================")
    print(" [SUCCESS] تم بناء وتحديث ومزامنة كافة مكونات النظام للبرودكشن بنجاح تام! ")
    print(f" مجلد البرودكشن: {STANDALONE_DIR}")
    print(f" مشغل البرودكشن: {DIST_DIR / 'Start_ImportFlow_Production.bat'}")
    print("===============================================================================\n")
    return True


def export_release_zip():
    """Generates release zip."""
    if (ROOT_DIR / "create_release_bundle.py").exists():
        subprocess.run([sys.executable, str(ROOT_DIR / "create_release_bundle.py")], cwd=str(ROOT_DIR))
    else:
        print("[ERROR] لم يتم العثور على create_release_bundle.py")


def launch_production_app():
    """Launches the production application silently."""
    print("\n[LAUNCH] جاري تشغيل نسخة البرودكشن المستقلة (ImportFlow Standalone)...")
    vbs_launcher = STANDALONE_DIR / "Launch_ImportFlow.vbs"
    bat_launcher = DIST_DIR / "Start_ImportFlow_Production.bat"
    
    if vbs_launcher.exists():
        subprocess.Popen(["wscript.exe", str(vbs_launcher)], cwd=str(STANDALONE_DIR))
        print("[SUCCESS] تم إطلاق التطبيق بنجاح!")
    elif bat_launcher.exists():
        subprocess.Popen([str(bat_launcher)], cwd=str(DIST_DIR), shell=True)
        print("[SUCCESS] تم إطلاق التطبيق بنجاح!")
    else:
        print("[ERROR] لم يتم العثور على مشغل البرودكشن!")


def interactive_menu():
    """Displays interactive CLI menu in Arabic/English."""
    while True:
        print("\n" + "=" * 65)
        print("   ImportFlow ERP - Production Sync Tool (أداة مزامنة التحديثات)   ")
        print("=" * 65)
        print("  [1] مزامنة سريعة لقاعدة البيانات فقط (Sync Database Dev -> Prod)")
        print("  [2] بناء كامل وتحديث الفرونت والباك إند (Full Build & Sync)")
        print("  [3] سحب قاعدة بيانات البرودكشن إلى بيئة التطوير (Pull Prod -> Dev)")
        print("  [4] فحص ومقارنة تطابق البيانات بين التطوير والإنتاج (Compare DBs)")
        print("  [5] تصدير حزمة التوزيع المضغوطة (Export Release ZIP)")
        print("  [6] تشغيل نسخة البرودكشن الآن (Launch Production App)")
        print("  [0] خروج (Exit)")
        print("-" * 65)
        
        choice = input("👉 اختر رقم العملية المطلوبة (0-6): ").strip()
        if choice == "1":
            sync_db_to_prod()
        elif choice == "2":
            full_production_build_and_sync()
        elif choice == "3":
            pull_prod_db_to_dev()
        elif choice == "4":
            compare_databases()
        elif choice == "5":
            export_release_zip()
        elif choice == "6":
            launch_production_app()
        elif choice in ["0", "q", "exit"]:
            print("مع السلامة! 👋")
            break
        else:
            print("[!] اختيار غير صحيح، يرجى إدخال رقم من 0 إلى 6.")


def main():
    parser = argparse.ArgumentParser(description="ImportFlow ERP Production Sync & Deployment Tool")
    parser.add_argument("--db-only", action="store_true", help="Sync Database from Dev to Prod with backup")
    parser.add_argument("--full", action="store_true", help="Full compilation, test, and production packaging")
    parser.add_argument("--pull", action="store_true", help="Pull Database from Prod to Dev with backup")
    parser.add_argument("--compare", action="store_true", help="Compare Dev and Prod databases")
    parser.add_argument("--zip", action="store_true", help="Generate Release ZIP and manifest")
    parser.add_argument("--launch", action="store_true", help="Launch Production App")

    args = parser.parse_args()

    if args.db_only:
        sync_db_to_prod()
    elif args.full:
        full_production_build_and_sync()
    elif args.pull:
        pull_prod_db_to_dev()
    elif args.compare:
        compare_databases()
    elif args.zip:
        export_release_zip()
    elif args.launch:
        launch_production_app()
    else:
        interactive_menu()


if __name__ == "__main__":
    main()
