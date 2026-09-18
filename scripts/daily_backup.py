"""
Sorour Logistics ERP — Automated Daily Database Backup Utility
=============================================================
- Executes zero-downtime, non-blocking online SQLite backup.
- Manages 30-day retention policy (prunes older daily backups).
- Verifies database integrity after backup (PRAGMA integrity_check).
- Computes SHA-256 checksum and writes metadata log.
- Supports one-click registration in Windows Task Scheduler.
"""
import os
import sys
import time
import shutil
import hashlib
import sqlite3
import argparse
import subprocess
from datetime import datetime, timezone, timedelta
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
DB_PATH = ROOT_DIR / "sorour_logistics.db"
BACKUPS_DIR = ROOT_DIR / "backups"
DEFAULT_RETENTION_DAYS = 30
TASK_NAME = "SorourLogistics_DailyBackup"


def compute_sha256(file_path: Path) -> str:
    sha256 = hashlib.sha256()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            sha256.update(chunk)
    return sha256.hexdigest()


def prune_old_backups(retention_days: int = DEFAULT_RETENTION_DAYS):
    cutoff = datetime.now(timezone.utc) - timedelta(days=retention_days)
    pruned_count = 0

    for f in BACKUPS_DIR.glob("daily_backup_*.db"):
        try:
            mtime = datetime.fromtimestamp(f.stat().st_mtime, tz=timezone.utc)
            if mtime < cutoff:
                f.unlink(missing_ok=True)
                # Also delete associated metadata json if exists
                meta_json = f.with_suffix(".json")
                meta_json.unlink(missing_ok=True)
                pruned_count += 1
                print(f"  [PRUNED] Removed backup older than {retention_days} days: {f.name}")
        except Exception as e:
            print(f"  [WARN] Failed to evaluate/prune {f.name}: {e}")

    if pruned_count > 0:
        print(f"[OK] Pruned {pruned_count} old backup file(s) exceeding {retention_days} days retention.")
    else:
        print(f"[OK] Retention check passed: All daily backups are within the {retention_days}-day window.")


def perform_backup(retention_days: int = DEFAULT_RETENTION_DAYS) -> Path:
    print("================================================================================")
    print("           Sorour Logistics ERP — Automated Daily Online Backup                 ")
    print("================================================================================")

    if not DB_PATH.exists():
        raise FileNotFoundError(f"Source database not found at {DB_PATH}")

    BACKUPS_DIR.mkdir(parents=True, exist_ok=True)

    timestamp_str = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_filename = f"daily_backup_{timestamp_str}.db"
    backup_path = BACKUPS_DIR / backup_filename

    start_time = time.time()
    print(f"[1/4] Performing zero-downtime online backup to: {backup_filename}...")

    # 1. Native Online Backup API
    src_conn = sqlite3.connect(DB_PATH)
    dst_conn = sqlite3.connect(backup_path)
    src_conn.backup(dst_conn)
    dst_conn.close()
    src_conn.close()
    elapsed = time.time() - start_time
    print(f"      Completed in {elapsed:.2f} seconds.")

    # 2. Integrity check on the backup copy
    print("[2/4] Verifying backup database integrity...")
    check_conn = sqlite3.connect(backup_path)
    cur = check_conn.cursor()
    cur.execute("PRAGMA integrity_check;")
    integrity_result = cur.fetchone()[0]
    check_conn.close()

    if integrity_result != "ok":
        backup_path.unlink(missing_ok=True)
        raise RuntimeError(f"Database backup integrity check failed: {integrity_result}")
    print(f"      Integrity check: PASS ({integrity_result})")

    # 3. Checksum & Metadata
    print("[3/4] Generating SHA-256 Checksum and metadata...")
    checksum = compute_sha256(backup_path)
    file_size = backup_path.stat().st_size

    meta = {
        "system": "Sorour Logistics ERP",
        "backup_type": "Daily Automated",
        "created_at_utc": datetime.now(timezone.utc).isoformat(),
        "backup_file": backup_filename,
        "size_bytes": file_size,
        "sha256": checksum,
        "integrity": "PASS",
        "retention_days": retention_days
    }
    meta_path = backup_path.with_suffix(".json")
    import json
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)
    print(f"      SHA-256: {checksum}")
    print(f"      Size: {file_size:,} bytes")

    # 4. Retention policy enforcement
    print(f"[4/4] Enforcing {retention_days}-day backup retention policy...")
    prune_old_backups(retention_days)

    print("================================================================================")
    print(f"[SUCCESS] Daily backup successfully finished: {backup_path.name}")
    print("================================================================================")
    return backup_path


def register_windows_task():
    """Register daily backup in Windows Task Scheduler at 23:00 (11 PM)."""
    python_exe = sys.executable
    script_path = ROOT_DIR / "scripts" / "daily_backup.py"
    cmd = f'schtasks /create /tn "{TASK_NAME}" /tr "\"{python_exe}\" \"{script_path}\"" /sc daily /st 23:00 /f'
    print(f"Registering Windows Task: {TASK_NAME} at 23:00 daily...")
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if res.returncode == 0:
            print("================================================================================")
            print("[SUCCESS] Windows Scheduled Task registered successfully!")
            print(f" Task Name: {TASK_NAME}")
            print(" Schedule: Daily at 23:00 (11:00 PM)")
            print(" Action: Python daily_backup.py")
            print("================================================================================")
            return True
        else:
            print(f"[ERROR] Failed to register task: {res.stderr.strip() or res.stdout.strip()}")
            return False
    except Exception as e:
        print(f"[ERROR] Exception during task registration: {e}")
        return False


def unregister_windows_task():
    cmd = f'schtasks /delete /tn "{TASK_NAME}" /f'
    print(f"Unregistering Windows Task: {TASK_NAME}...")
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if res.returncode == 0:
            print(f"[SUCCESS] Windows Task '{TASK_NAME}' deleted successfully.")
            return True
        else:
            print(f"[INFO] Task was not registered or could not be removed: {res.stderr.strip()}")
            return False
    except Exception as e:
        print(f"[ERROR] {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description="Sorour Logistics ERP Automated Daily Backup")
    parser.add_argument("--retention", type=int, default=DEFAULT_RETENTION_DAYS, help="Number of days to keep backups (default: 30)")
    parser.add_argument("--test", action="store_true", help="Run backup immediately in test mode")
    parser.add_argument("--register-task", action="store_true", help="Register backup in Windows Task Scheduler at 23:00 daily")
    parser.add_argument("--unregister-task", action="store_true", help="Delete Windows Scheduled Task")
    args = parser.parse_args()

    if args.register_task:
        register_windows_task()
    elif args.unregister_task:
        unregister_windows_task()
    else:
        perform_backup(retention_days=args.retention)


if __name__ == "__main__":
    main()
