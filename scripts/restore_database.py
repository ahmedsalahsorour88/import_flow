"""
Sorour Logistics ERP — Automated Database Restore Utility
=========================================================
- Restores database from an authentic backup file.
- Verifies integrity of backup (PRAGMA integrity_check) before proceeding.
- Uses SQLite Online Backup API to safely restore data without file-lock collisions.
- Validates restored database integrity post-restoration.
"""
import sys
import os
import time
import argparse
import sqlite3
from pathlib import Path
from datetime import datetime

ROOT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT_DIR))
from utils.crypto_utils import (
    is_encrypted_backup,
    decrypt_backup_file,
    get_backup_encryption_key,
)

DEFAULT_DB_PATH = ROOT_DIR / "sorour_logistics.db"
BACKUPS_DIR = ROOT_DIR / "backups"


def verify_sqlite_integrity(db_path: Path) -> bool:
    if not db_path.exists():
        return False
    try:
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
        cur.execute("PRAGMA integrity_check;")
        res = cur.fetchone()[0]
        conn.close()
        return res == "ok"
    except Exception as e:
        print(f"[ERROR] Integrity check exception: {e}")
        return False


def restore_database(backup_file: Path, target_db: Path = DEFAULT_DB_PATH) -> bool:
    print("================================================================================")
    print("           Sorour Logistics ERP — Database Disaster Recovery Restore            ")
    print("================================================================================")
    print(f" Source Backup : {backup_file}")
    print(f" Target DB     : {target_db}")

    if not backup_file.exists():
        print(f"[FAIL] Backup file does not exist: {backup_file}")
        return False

    temp_decrypted_path = None
    try:
        source_to_restore = backup_file
        # 0. Detect and decrypt if AES-256-GCM sealed backup
        if is_encrypted_backup(backup_file) or backup_file.name.endswith(".enc"):
            print("[0/3] Authenticated AES-256-GCM encrypted backup detected.")
            print("      Decrypting using local encryption key...")
            temp_decrypted_path = backup_file.parent / f".tmp_restore_{backup_file.stem}_{int(time.time())}.db"
            try:
                decrypt_backup_file(backup_file, temp_decrypted_path)
                source_to_restore = temp_decrypted_path
                print("      Decryption: SUCCESS (authenticated signature valid)")
            except Exception as e:
                print(f"[FAIL] Decryption failed: {e}")
                return False

        # 1. Pre-restore backup verification
        print("[1/3] Verifying source backup file integrity...")
        if not verify_sqlite_integrity(source_to_restore):
            print(f"[FAIL] Source backup integrity check failed or file is corrupted.")
            return False
        print("      Integrity: PASS (ok)")

        # 2. Perform online restoration
        print(f"[2/3] Performing online restoration to {target_db.name}...")
        try:
            src_conn = sqlite3.connect(source_to_restore)
            dst_conn = sqlite3.connect(target_db)
            src_conn.backup(dst_conn)
            dst_conn.close()
            src_conn.close()
            print("      Restoration completed successfully.")
        except Exception as e:
            print(f"[FAIL] Error during restore operation: {e}")
            return False

        # 3. Post-restore target database verification
        print("[3/3] Verifying restored target database...")
        if not verify_sqlite_integrity(target_db):
            print("[FAIL] Post-restoration target integrity check failed.")
            return False
        print("      Post-restore Integrity: PASS (ok)")

        print("================================================================================")
        print("[SUCCESS] Database successfully restored and verified 100% healthy.")
        print("================================================================================")
        return True
    finally:
        # Secure cleanup of temporary decrypted database copy
        if temp_decrypted_path and temp_decrypted_path.exists():
            temp_decrypted_path.unlink(missing_ok=True)


def list_available_backups():
    print("Available backups in backups directory:")
    if not BACKUPS_DIR.exists():
        print("  No backups directory found.")
        return
    seen = set()
    all_files = []
    for f in list(BACKUPS_DIR.glob("*.db")) + list(BACKUPS_DIR.glob("*.enc")):
        if f.name not in seen:
            seen.add(f.name)
            all_files.append(f)

    files = sorted(all_files, key=lambda f: f.stat().st_mtime, reverse=True)
    if not files:
        print("  No backup files found.")
        return
    for f in files:
        size_mb = f.stat().st_size / (1024 * 1024)
        mtime = datetime.fromtimestamp(f.stat().st_mtime).strftime("%Y-%m-%d %H:%M:%S")
        enc_label = " [ENCRYPTED - AES-256-GCM]" if (f.name.endswith(".enc") or is_encrypted_backup(f)) else ""
        print(f"  - {f.name} ({size_mb:.2f} MB){enc_label} - {mtime}")


def main():
    parser = argparse.ArgumentParser(description="Sorour Logistics ERP Database Restore Utility")
    parser.add_argument("--backup", type=str, help="Path to the backup file (.db or .db.enc) to restore from")
    parser.add_argument("--target", type=str, default=str(DEFAULT_DB_PATH), help="Target database path (default: sorour_logistics.db)")
    parser.add_argument("--list", action="store_true", help="List all available backups")
    args = parser.parse_args()

    if args.list:
        list_available_backups()
        return

    if not args.backup:
        print("[ERROR] Please provide --backup <path> or use --list to view available backups.")
        sys.exit(1)

    backup_path = Path(args.backup)
    target_path = Path(args.target)
    success = restore_database(backup_path, target_path)
    if not success:
        sys.exit(1)


if __name__ == "__main__":
    main()
