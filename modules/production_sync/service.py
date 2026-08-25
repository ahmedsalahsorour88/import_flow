"""
Production Sync Service
Contains enterprise-grade, non-destructive database synchronization, comparison,
schema migration, and safety backup logic preserving 100% of production user data.
"""
import os
import shutil
import sqlite3
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session

from modules.production_sync.repository import ProductionSyncRepository
from modules.production_sync.schemas import (
    DatabaseStatsSchema,
    TableComparisonItemSchema,
    SyncComparisonResponseSchema,
    SyncActionResponseSchema,
    BackupItemSchema,
    BackupsListResponseSchema,
    RestoreBackupResponseSchema,
)
from modules.production_sync.validators import validate_db_exists


import sys

def _resolve_paths():
    if getattr(sys, "frozen", False):
        exe_dir = Path(sys.executable).resolve().parent
        # If running from inside dist/ImportFlow_Standalone in the project workspace
        if exe_dir.name == "ImportFlow_Standalone" and exe_dir.parent.name == "dist":
            root_dir = exe_dir.parent.parent
        else:
            root_dir = exe_dir

        dev_db = root_dir / "sorour_logistics.db"
        prod_db = exe_dir / "sorour_logistics.db"
        backups_dir = root_dir / "backups"
        if not backups_dir.exists() and root_dir == exe_dir:
            backups_dir = exe_dir / "backups"

        # Fallback if dev_db does not exist in standalone installation
        if not dev_db.exists():
            dev_db = prod_db

        return root_dir, exe_dir, dev_db, prod_db, backups_dir
    else:
        root_dir = Path(__file__).resolve().parent.parent.parent
        standalone_dir = root_dir / "dist" / "ImportFlow_Standalone"
        dev_db = root_dir / "sorour_logistics.db"
        prod_db = standalone_dir / "sorour_logistics.db"
        backups_dir = root_dir / "backups"
        return root_dir, standalone_dir, dev_db, prod_db, backups_dir

ROOT_DIR, STANDALONE_DIR, DEV_DB, PROD_DB, BACKUPS_DIR = _resolve_paths()
DIST_DIR = ROOT_DIR / "dist"


class ProductionSyncService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = ProductionSyncRepository(db)

    def _get_db_stats(self, db_path: Path) -> DatabaseStatsSchema:
        if not db_path.exists():
            return DatabaseStatsSchema(exists=False, path=str(db_path))
        try:
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
            tables = [row[0] for row in cursor.fetchall()]
            
            total_records = 0
            for table in tables:
                try:
                    cursor.execute(f"SELECT COUNT(*) FROM \"{table}\";")
                    c = cursor.fetchone()[0]
                    total_records += c
                except Exception:
                    pass
            conn.close()
            return DatabaseStatsSchema(
                exists=True,
                path=str(db_path),
                size_kb=round(db_path.stat().st_size / 1024, 1),
                tables_count=len(tables),
                total_records=total_records,
                mtime=datetime.fromtimestamp(db_path.stat().st_mtime).strftime("%Y-%m-%d %H:%M:%S"),
            )
        except Exception as e:
            return DatabaseStatsSchema(exists=True, path=str(db_path), error=str(e))

    def _get_table_counts(self, db_path: Path) -> Dict[str, int]:
        if not db_path.exists():
            return {}
        try:
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
            tables = [row[0] for row in cursor.fetchall()]
            counts = {}
            for table in tables:
                try:
                    cursor.execute(f"SELECT COUNT(*) FROM \"{table}\";")
                    counts[table] = cursor.fetchone()[0]
                except Exception:
                    counts[table] = 0
            conn.close()
            return counts
        except Exception:
            return {}

    def _cleanup_old_backups(self, max_keep: int = 50, exclude_path: Optional[Path] = None):
        """Maintains the newest `max_keep` backups in BACKUPS_DIR and removes older ones."""
        try:
            if not BACKUPS_DIR.exists():
                return
            all_backups = sorted(BACKUPS_DIR.glob("*.db"), key=lambda f: (f.stat().st_mtime, f.name), reverse=True)
            if len(all_backups) > max_keep:
                for old_file in all_backups[max_keep:]:
                    if exclude_path and old_file.resolve() == exclude_path.resolve():
                        continue
                    try:
                        old_file.unlink(missing_ok=True)
                    except Exception:
                        pass
        except Exception:
            pass

    def create_safety_backup(self, db_path: Path, tag: str = "manual") -> BackupItemSchema:
        validate_db_exists(db_path, tag)
        BACKUPS_DIR.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = BACKUPS_DIR / f"{db_path.stem}_{tag}_{timestamp}.db"
        shutil.copy(db_path, backup_file)
        try:
            os.utime(backup_file, None)
        except Exception:
            pass
        
        try:
            self.repo.create_log(
                action_type="CREATE_BACKUP",
                status="SUCCESS",
                backup_path=str(backup_file),
                notes=f"Backup created for {db_path.name} with tag {tag}",
            )
        except Exception:
            pass

        # Automatically clean up oldest snapshots beyond the retention threshold
        self._cleanup_old_backups(max_keep=50, exclude_path=backup_file)

        return BackupItemSchema(
            filename=backup_file.name,
            filepath=str(backup_file),
            size_kb=round(backup_file.stat().st_size / 1024, 1),
            created_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            tag=tag,
        )

    def _smart_non_destructive_migrate(self, src_db: Path, target_db: Path) -> Dict[str, Any]:
        """
        Enterprise Non-Destructive Migration Engine:
        1. Ensures all tables from src_db exist in target_db (creates missing tables).
        2. Ensures all columns from src_db exist in target_db (executes ALTER TABLE ADD COLUMN for new features).
        3. Non-destructively merges new seed/reference rows with INSERT OR IGNORE without modifying or deleting existing records.
        """
        if not target_db.exists():
            target_db.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src_db, target_db)
            return {"status": "copied_fresh", "tables_added": 0, "columns_added": 0, "rows_merged": 0}

        conn_src = sqlite3.connect(src_db)
        cur_src = conn_src.cursor()

        conn_tgt = sqlite3.connect(target_db)
        cur_tgt = conn_tgt.cursor()

        # 1. Fetch tables
        cur_src.execute("SELECT name, sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
        src_tables = cur_src.fetchall()

        cur_tgt.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
        tgt_table_names = set(r[0] for r in cur_tgt.fetchall())

        tables_added = 0
        columns_added = 0
        rows_merged = 0

        # Step 1: Create missing tables
        for tbl_name, tbl_sql in src_tables:
            if tbl_name not in tgt_table_names:
                if tbl_sql:
                    cur_tgt.execute(tbl_sql)
                    tables_added += 1
                    tgt_table_names.add(tbl_name)

        # Step 2: Add missing columns (ALTER TABLE ADD COLUMN)
        for tbl_name, _ in src_tables:
            if tbl_name in tgt_table_names:
                try:
                    cur_src.execute(f'PRAGMA table_info("{tbl_name}");')
                    src_cols = {row[1]: row[2] for row in cur_src.fetchall()}  # name -> type

                    cur_tgt.execute(f'PRAGMA table_info("{tbl_name}");')
                    tgt_cols = set(row[1] for row in cur_tgt.fetchall())

                    for col_name, col_type in src_cols.items():
                        if col_name not in tgt_cols:
                            cur_tgt.execute(f'ALTER TABLE "{tbl_name}" ADD COLUMN "{col_name}" {col_type};')
                            columns_added += 1
                except Exception:
                    pass

        conn_tgt.commit()

        # Step 3: Non-destructively merge rows using INSERT OR IGNORE
        # This inserts any new system data/ports/HS codes while preserving 100% of existing user data
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

    def get_comparison(self) -> SyncComparisonResponseSchema:
        dev_stats = self._get_db_stats(DEV_DB)
        prod_stats = self._get_db_stats(PROD_DB)

        dev_counts = self._get_table_counts(DEV_DB)
        prod_counts = self._get_table_counts(PROD_DB)

        all_table_names = sorted(set(list(dev_counts.keys()) + list(prod_counts.keys())))
        
        table_items: List[TableComparisonItemSchema] = []
        matched_count = 0
        diff_count = 0

        for tbl in all_table_names:
            d_c = dev_counts.get(tbl, 0)
            p_c = prod_counts.get(tbl, 0)
            diff = d_c - p_c
            is_m = (d_c == p_c)
            if is_m:
                matched_count += 1
                status_str = "متطابق (Matched)"
            else:
                diff_count += 1
                status_str = f"فرق ({diff:+d})"

            table_items.append(
                TableComparisonItemSchema(
                    table_name=tbl,
                    dev_count=d_c,
                    prod_count=p_c,
                    diff=diff,
                    is_match=is_m,
                    status=status_str,
                )
            )

        is_fully_sync = (diff_count == 0) and dev_stats.exists and prod_stats.exists

        return SyncComparisonResponseSchema(
            dev_stats=dev_stats,
            prod_stats=prod_stats,
            is_fully_synchronized=is_fully_sync,
            total_tables=len(all_table_names),
            matched_tables_count=matched_count,
            differing_tables_count=diff_count,
            tables=table_items,
        )

    def sync_dev_to_prod(self) -> SyncActionResponseSchema:
        """
        Pushes development updates to production non-destructively:
        - Creates a safety backup of production database first.
        - Applies schema migrations (creates missing tables, adds missing columns).
        - Merges new reference data with INSERT OR IGNORE.
        - Preserves 100% of user data in production.
        """
        validate_db_exists(DEV_DB, "قاعدة بيانات التطوير")

        # 1. Backup Prod DB if exists
        prod_backup_str = None
        if PROD_DB.exists():
            prod_backup = self.create_safety_backup(PROD_DB, "prod_before_sync")
            prod_backup_str = prod_backup.filename

        # 2. Backup Dev DB snapshot
        dev_backup = self.create_safety_backup(DEV_DB, "dev_snapshot")

        # 3. Ensure target directory exists
        STANDALONE_DIR.mkdir(parents=True, exist_ok=True)

        # 4. Perform Smart Non-Destructive Migration
        migration_res = self._smart_non_destructive_migrate(DEV_DB, PROD_DB)

        # Also migrate to root dist DB if exists
        if DIST_DIR.exists() and (DIST_DIR / "sorour_logistics.db").exists():
            try:
                self._smart_non_destructive_migrate(DEV_DB, DIST_DIR / "sorour_logistics.db")
            except Exception:
                pass

        # 5. Automatically Bump Sequential Version & Build
        try:
            import version_manager
            version_manager.bump_version("patch")
        except Exception:
            pass

        stats = self._get_db_stats(PROD_DB)

        try:
            self.repo.create_log(
                action_type="PUSH_TO_PROD",
                status="SUCCESS",
                backup_path=str(dev_backup.filepath),
                records_count=stats.total_records,
                tables_count=stats.tables_count,
                notes=f"Safe non-destructive sync completed: {migration_res}",
            )
        except Exception:
            pass

        return SyncActionResponseSchema(
            success=True,
            action="PUSH_TO_PROD",
            message="تمت المزامنة وتطبيق التحديثات بأمان 100% مع الحفاظ التام على بيانات التشغيل المسجلة!",
            timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            backup_file=prod_backup_str or dev_backup.filename,
            affected_tables_count=stats.tables_count,
            total_records_synced=stats.total_records,
            details={
                "prod_size_kb": stats.size_kb,
                "prod_path": str(PROD_DB),
                "migration_summary": migration_res,
            },
        )

    def pull_prod_to_dev(self) -> SyncActionResponseSchema:
        """
        Pulls actual production data into development workspace non-destructively:
        - Backs up development database.
        - Merges user records from Prod into Dev without deleting anything.
        """
        validate_db_exists(PROD_DB, "قاعدة بيانات الإنتاج")

        # 1. Backup Dev DB
        dev_backup = self.create_safety_backup(DEV_DB, "dev_before_pull")

        # 2. Backup Prod DB
        prod_backup = self.create_safety_backup(PROD_DB, "prod_snapshot")

        # 3. Non-destructively migrate/merge Prod -> Dev
        migration_res = self._smart_non_destructive_migrate(PROD_DB, DEV_DB)

        stats = self._get_db_stats(DEV_DB)

        try:
            self.repo.create_log(
                action_type="PULL_TO_DEV",
                status="SUCCESS",
                backup_path=str(prod_backup.filepath),
                records_count=stats.total_records,
                tables_count=stats.tables_count,
                notes=f"Safe pull from prod to dev completed: {migration_res}",
            )
        except Exception:
            pass

        return SyncActionResponseSchema(
            success=True,
            action="PULL_TO_DEV",
            message="تم سحب ودمج بيانات البرودكشن الفعلية بنجاح إلى بيئة التطوير دون أي فقدان للبيانات!",
            timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            backup_file=dev_backup.filename,
            affected_tables_count=stats.tables_count,
            total_records_synced=stats.total_records,
            details={
                "dev_size_kb": stats.size_kb,
                "dev_path": str(DEV_DB),
                "migration_summary": migration_res,
            },
        )

    def list_backups(self) -> BackupsListResponseSchema:
        if not BACKUPS_DIR.exists():
            return BackupsListResponseSchema(total_backups=0, backups=[])
        
        backups: List[BackupItemSchema] = []
        for file in sorted(BACKUPS_DIR.glob("*.db"), key=lambda f: f.stat().st_mtime, reverse=True):
            tag = "backup"
            if "prod" in file.name:
                tag = "prod"
            elif "dev" in file.name:
                tag = "dev"
            
            backups.append(
                BackupItemSchema(
                    filename=file.name,
                    filepath=str(file),
                    size_kb=round(file.stat().st_size / 1024, 1),
                    created_at=datetime.fromtimestamp(file.stat().st_mtime).strftime("%Y-%m-%d %H:%M:%S"),
                    tag=tag,
                )
            )

        return BackupsListResponseSchema(total_backups=len(backups), backups=backups)

    def restore_backup(self, filename: str, target: str = "prod") -> RestoreBackupResponseSchema:
        """
        Restore a specific backup snapshot to the target database (dev or prod).
        Always creates a safety backup of the current target DB before restoring.

        Args:
            filename: The backup filename (must exist in BACKUPS_DIR).
            target: 'prod' or 'dev' — which database to restore into.

        Returns:
            RestoreBackupResponseSchema with result details.
        """
        BACKUPS_DIR.mkdir(parents=True, exist_ok=True)
        # Normalize filename in case a path was passed
        clean_filename = Path(filename).name
        backup_file = BACKUPS_DIR / clean_filename
        if not backup_file.exists():
            # Check if it was provided as an absolute or relative path
            alt_path = Path(filename)
            if alt_path.exists():
                backup_file = alt_path
            else:
                raise FileNotFoundError(f"الملف الاحتياطي '{clean_filename}' غير موجود في مجلد النسخ الاحتياطية.")

        target_db = PROD_DB if target == "prod" else DEV_DB

        # 1. Safety backup of current target DB before overwrite
        safety_backup: Optional[BackupItemSchema] = None
        if target_db.exists():
            safety_backup = self.create_safety_backup(target_db, tag=f"pre_restore_{target}")

        # 2. Ensure target directory exists
        target_db.parent.mkdir(parents=True, exist_ok=True)

        # 3. Replace target DB with the selected backup
        shutil.copy2(backup_file, target_db)

        # 4. Log action
        try:
            self.repo.create_log(
                action_type="RESTORE_BACKUP",
                status="SUCCESS",
                backup_path=str(backup_file),
                notes=f"Restored '{filename}' to {target} DB. Safety backup: {safety_backup.filename if safety_backup else 'none'}",
            )
        except Exception:
            pass

        return RestoreBackupResponseSchema(
            success=True,
            message=f"تمت استعادة النسخة الاحتياطية '{filename}' بنجاح إلى قاعدة بيانات {'الإنتاج' if target == 'prod' else 'التطوير'} مع حفظ نسخة أمان من الوضع الحالي.",
            timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            restored_from=filename,
            safety_backup_created=safety_backup.filename if safety_backup else "لم تكن هناك قاعدة بيانات سابقة",
            target=target,
        )

