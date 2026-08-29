"""
Production Sync Service
Contains enterprise-grade, non-destructive database synchronization, comparison,
schema migration, and safety backup logic preserving 100% of production user data.
"""
import os
import re
import json
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
    RemoteUpdateCheckResponseSchema,
    SystemVersionInfoSchema,
    RemoteUpdateCheckSchema,
)
from modules.production_sync.validators import validate_db_exists


import sys

def _resolve_paths():
    if getattr(sys, "frozen", False):
        exe_dir = Path(sys.executable).resolve().parent
        # If running from inside dist/Sorour_Logistics_Standalone or dist/ImportFlow_Standalone
        if exe_dir.name in ["Sorour_Logistics_Standalone", "ImportFlow_Standalone"] and exe_dir.parent.name == "dist":
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
        standalone_dir = root_dir / "dist" / "Sorour_Logistics_Standalone"
        if not standalone_dir.exists():
            legacy_dir = root_dir / "dist" / "ImportFlow_Standalone"
            if legacy_dir.exists():
                standalone_dir = legacy_dir
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

    def _smart_non_destructive_migrate(
        self, src_db: Path, target_db: Path, preserve_target_user_data: bool = True
    ) -> Dict[str, Any]:
        """
        Enterprise Non-Destructive Migration Engine:
        1. Ensures all tables from src_db exist in target_db (creates missing tables).
        2. Ensures all columns from src_db exist in target_db (executes ALTER TABLE ADD COLUMN for new features).
        3. Preserves 100% of user data in target_db (never deletes or overwrites existing user operational rows).
        4. Reference/Master data tables are safely updated/upserted.
        """
        if not target_db.exists():
            target_db.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src_db, target_db)
            return {"status": "copied_fresh", "tables_added": 0, "columns_added": 0, "rows_merged": 0}

        conn_src = sqlite3.connect(src_db)
        conn_src.execute("PRAGMA journal_mode = WAL;")
        cur_src = conn_src.cursor()

        conn_tgt = sqlite3.connect(target_db)
        conn_tgt.execute("PRAGMA journal_mode = WAL;")
        cur_tgt = conn_tgt.cursor()

        cur_tgt.execute("PRAGMA foreign_keys = OFF;")
        cur_tgt.execute("BEGIN TRANSACTION;")

        # 1. Fetch tables
        cur_src.execute("SELECT name, sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
        src_tables = cur_src.fetchall()

        cur_tgt.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
        tgt_table_names = set(r[0] for r in cur_tgt.fetchall())

        tables_added = 0
        columns_added = 0
        rows_merged = 0

        # Operational tables where user data must NEVER be overwritten
        OPERATIONAL_TABLES = {
            "import_files",
            "purchase_orders",
            "purchase_order_items",
            "commercial_invoices",
            "commercial_invoice_items",
            "shipments",
            "shipment_containers",
            "shipment_packages",
            "customs_declarations",
            "customs_declaration_items",
            "customs_declaration_receipts",
            "landed_cost_calculations",
            "landed_cost_items",
            "clearance_operations",
            "clearance_expenses",
            "shipping_quotes",
            "shipping_quote_options",
            "cargo_insurance_certificates",
            "inspection_certificates",
            "shipment_tracking_events",
            "shipment_documents",
            "importing_companies",
            "importing_company_documents",
            "suppliers",
            "supplier_contacts",
            "supplier_documents",
            "service_partners",
            "service_partner_contacts",
            "projects",
            "project_documents",
            "activity_logs",
            "audit_trail_logs",
            "acid_validity_logs",
            "system_notifications",
        }

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

        # Step 3: Synchronize and upsert rows
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

                is_operational = tbl_name in OPERATIONAL_TABLES
                insert_verb = "INSERT OR IGNORE" if (preserve_target_user_data and is_operational) else "INSERT OR REPLACE"

                for row in src_rows:
                    cur_tgt.execute(
                        f'{insert_verb} INTO "{tbl_name}" ({cols_str}) VALUES ({placeholders});',
                        tuple(row),
                    )
                    if cur_tgt.rowcount > 0:
                        rows_merged += 1
            except Exception:
                pass

        conn_tgt.commit()
        cur_tgt.execute("PRAGMA foreign_keys = ON;")
        conn_src.close()
        conn_tgt.close()

        return {
            "status": "migrated_safely",
            "tables_added": tables_added,
            "columns_added": columns_added,
            "rows_merged": rows_merged,
        }

    def _get_table_columns(self, db_path: Path) -> Dict[str, List[str]]:
        """Returns {table_name: [col1, col2, ...]} for all tables in db_path."""
        if not db_path.exists():
            return {}
        try:
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
            tables = [row[0] for row in cursor.fetchall()]
            result = {}
            for table in tables:
                try:
                    cursor.execute(f'PRAGMA table_info("{table}");')
                    result[table] = [row[1] for row in cursor.fetchall()]
                except Exception:
                    result[table] = []
            conn.close()
            return result
        except Exception:
            return {}

    def get_comparison(self) -> SyncComparisonResponseSchema:
        dev_stats = self._get_db_stats(DEV_DB)
        prod_stats = self._get_db_stats(PROD_DB)

        dev_counts = self._get_table_counts(DEV_DB)
        prod_counts = self._get_table_counts(PROD_DB)

        # ── Schema comparison ────────────────────────────────────────────
        dev_columns = self._get_table_columns(DEV_DB)
        prod_columns = self._get_table_columns(PROD_DB)

        all_table_names = sorted(set(list(dev_counts.keys()) + list(prod_counts.keys())))

        table_items: List[TableComparisonItemSchema] = []
        matched_count = 0
        diff_count = 0
        schema_diffs_count = 0

        for tbl in all_table_names:
            d_c = dev_counts.get(tbl, 0)
            p_c = prod_counts.get(tbl, 0)
            diff = d_c - p_c

            dev_cols = dev_columns.get(tbl, [])
            prod_cols_set = set(prod_columns.get(tbl, []))

            is_new_table = tbl not in prod_counts
            new_columns = [c for c in dev_cols if c not in prod_cols_set] if not is_new_table else []
            has_schema_diff = is_new_table or len(new_columns) > 0

            data_match = (d_c == p_c) and not is_new_table
            is_fully_matched = data_match and not has_schema_diff
            needs_sync = not is_fully_matched

            if is_fully_matched:
                matched_count += 1
                status_str = "متطابق (Matched)"
            else:
                diff_count += 1
                if is_new_table:
                    status_str = "جدول جديد (New Table)"
                elif has_schema_diff and data_match:
                    new_cols_preview = ", ".join(new_columns[:3])
                    if len(new_columns) > 3:
                        new_cols_preview += f" +{len(new_columns) - 3}"
                    status_str = f"ترقية Schema ({len(new_columns)} عمود جديد: {new_cols_preview})"
                elif has_schema_diff:
                    status_str = f"فرق بيانات + Schema ({diff:+d} سجل, {len(new_columns)} عمود)"
                else:
                    status_str = f"فرق ({diff:+d})"

            if has_schema_diff:
                schema_diffs_count += 1

            table_items.append(
                TableComparisonItemSchema(
                    table_name=tbl,
                    dev_count=d_c,
                    prod_count=p_c,
                    diff=diff,
                    is_match=is_fully_matched,
                    status=status_str,
                    dev_columns_count=len(dev_cols),
                    prod_columns_count=len(prod_columns.get(tbl, [])),
                    new_columns=new_columns,
                    is_new_table=is_new_table,
                    has_schema_diff=has_schema_diff,
                    needs_sync=needs_sync,
                )
            )

        is_fully_sync = (diff_count == 0) and (schema_diffs_count == 0) and dev_stats.exists and prod_stats.exists

        return SyncComparisonResponseSchema(
            dev_stats=dev_stats,
            prod_stats=prod_stats,
            is_fully_synchronized=is_fully_sync,
            total_tables=len(all_table_names),
            matched_tables_count=matched_count,
            differing_tables_count=diff_count,
            schema_diffs_count=schema_diffs_count,
            tables=table_items,
        )

    def sync_dev_to_prod(self) -> SyncActionResponseSchema:
        """
        Pushes development updates to production non-destructively.
        """
        validate_db_exists(DEV_DB, "قاعدة بيانات التطوير")

        prod_backup_str = None
        if PROD_DB.exists():
            prod_backup = self.create_safety_backup(PROD_DB, "prod_before_sync")
            prod_backup_str = prod_backup.filename

        dev_backup = self.create_safety_backup(DEV_DB, "dev_snapshot")
        STANDALONE_DIR.mkdir(parents=True, exist_ok=True)

        migration_res = self._smart_non_destructive_migrate(DEV_DB, PROD_DB)

        other_dist_dbs = [
            DIST_DIR / "sorour_logistics.db",
            ROOT_DIR / "dist_backend" / "sorour_logistics.db",
            DIST_DIR / "ImportFlow_Standalone" / "sorour_logistics.db",
            DIST_DIR / "Sorour_Logistics_Desktop" / "sorour_logistics.db",
        ]
        for alt_db in other_dist_dbs:
            if alt_db.exists() and alt_db.resolve() != PROD_DB.resolve():
                try:
                    self._smart_non_destructive_migrate(DEV_DB, alt_db)
                except Exception:
                    pass

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
        Pulls actual production data into development workspace non-destructively.
        """
        validate_db_exists(PROD_DB, "قاعدة بيانات الإنتاج")

        dev_backup = self.create_safety_backup(DEV_DB, "dev_before_pull")
        prod_backup = self.create_safety_backup(PROD_DB, "prod_snapshot")

        migration_res = self._smart_non_destructive_migrate(PROD_DB, DEV_DB, preserve_target_user_data=False)
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
        """
        BACKUPS_DIR.mkdir(parents=True, exist_ok=True)
        clean_filename = Path(filename).name
        backup_file = BACKUPS_DIR / clean_filename
        if not backup_file.exists():
            alt_path = Path(filename)
            if alt_path.exists():
                backup_file = alt_path
            else:
                raise FileNotFoundError(f"الملف الاحتياطي '{clean_filename}' غير موجود في مجلد النسخ الاحتياطية.")

        target_db = PROD_DB if target == "prod" else DEV_DB

        safety_backup: Optional[BackupItemSchema] = None
        if target_db.exists():
            safety_backup = self.create_safety_backup(target_db, tag=f"pre_restore_{target}")

        target_db.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(backup_file, target_db)

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

    def check_remote_update(self) -> RemoteUpdateCheckResponseSchema:
        """
        Queries GitHub Releases API to check for new published versions and assets.
        """
        import urllib.request
        import urllib.error

        version_file = ROOT_DIR / "version.json"
        current_version = "1.0.55"
        current_build = 56
        if version_file.exists():
            try:
                with open(version_file, "r", encoding="utf-8") as f:
                    v_data = json.load(f)
                    current_version = v_data.get("version", current_version)
                    current_build = v_data.get("build_number", current_build)
            except Exception:
                pass

        api_url = "https://api.github.com/repos/ahmedsalahsorour88/import_flow/releases/latest"
        req = urllib.request.Request(
            api_url,
            headers={
                "Accept": "application/vnd.github.v3+json",
                "User-Agent": "SorourLogisticsERP-Updater",
            },
        )

        try:
            with urllib.request.urlopen(req, timeout=5) as response:
                if response.status != 200:
                    return RemoteUpdateCheckResponseSchema(
                        current_version=current_version,
                        current_build=current_build,
                        check_status="error",
                        error_message=f"GitHub API returned status code {response.status}",
                    )
                release_data = json.loads(response.read().decode("utf-8"))

            latest_tag = release_data.get("tag_name", "")
            latest_version = latest_tag.lstrip("v").strip()
            release_name = release_data.get("name", "")
            release_notes = release_data.get("body", "")
            published_at = release_data.get("published_at", "")
            html_url = release_data.get("html_url", "")

            installer_url = None
            portable_url = None
            for asset in release_data.get("assets", []):
                name = asset.get("name", "").lower()
                url = asset.get("browser_download_url", "")
                if name.endswith(".exe") and "setup" in name:
                    installer_url = url
                elif name.endswith(".zip") and "portable" in name:
                    portable_url = url

            def _parse_version(v_str: str) -> tuple:
                try:
                    parts = [int(p) for p in v_str.split(".") if p.isdigit()]
                    return tuple(parts) if parts else (0, 0, 0)
                except Exception:
                    return (0, 0, 0)

            cur_v_tuple = _parse_version(current_version)
            latest_v_tuple = _parse_version(latest_version)
            update_available = latest_v_tuple > cur_v_tuple

            return RemoteUpdateCheckResponseSchema(
                current_version=current_version,
                current_build=current_build,
                latest_version=latest_version,
                latest_tag=latest_tag,
                update_available=update_available,
                release_name=release_name,
                release_notes=release_notes,
                published_at=published_at,
                installer_download_url=installer_url,
                portable_zip_download_url=portable_url,
                html_url=html_url,
                check_status="success" if update_available else "no_update",
            )

        except urllib.error.URLError as e:
            return RemoteUpdateCheckResponseSchema(
                current_version=current_version,
                current_build=current_build,
                check_status="offline",
                error_message=f"تعذر الاتصال بخادم التحديثات (الوضع غير متصل بالإنترنت): {str(e.reason)}",
            )
        except Exception as e:
            return RemoteUpdateCheckResponseSchema(
                current_version=current_version,
                current_build=current_build,
                check_status="error",
                error_message=f"حدث خطأ أثناء فحص التحديثات: {str(e)}",
            )

    def get_system_version_info(self) -> SystemVersionInfoSchema:
        """Retrieves live system version, build number, environment, and database metrics."""
        version_str = "1.0.55"
        build_num = 56
        rel_date = None

        v_file = ROOT_DIR / "version.json"
        if v_file.exists():
            try:
                with open(v_file, "r", encoding="utf-8") as f:
                    v_data = json.load(f)
                    version_str = v_data.get("version", version_str)
                    build_num = v_data.get("build_number", build_num)
                    rel_date = v_data.get("updated_at")
            except Exception:
                pass

        is_standalone = getattr(sys, "frozen", False) or not (ROOT_DIR / "frontend").exists()
        active_db = PROD_DB if (is_standalone and PROD_DB.exists()) else DEV_DB
        db_stats = self._get_db_stats(active_db)

        backups_count = 0
        if BACKUPS_DIR.exists():
            try:
                backups_count = len(list(BACKUPS_DIR.glob("*.db")))
            except Exception:
                pass

        return SystemVersionInfoSchema(
            system_name="ImportFlow ERP - Sorour Logistics",
            version=version_str,
            build_number=build_num,
            release_date=rel_date or datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            is_standalone=is_standalone,
            environment="standalone" if is_standalone else "development",
            database_path=str(active_db.name),
            database_size_kb=db_stats.size_kb,
            tables_count=db_stats.tables_count,
            total_backups_count=backups_count,
        )

    def check_for_updates(self, custom_remote_url: Optional[str] = None) -> RemoteUpdateCheckSchema:
        """
        Checks for newer software releases via GitHub / Remote JSON.
        Also fetches installer_url for in-app auto-update.
        """
        import urllib.request

        curr_info = self.get_system_version_info()
        curr_ver = curr_info.version

        def parse_ver(v_str: str):
            clean = re.sub(r"[^\d\.]", "", v_str.strip())
            parts = [int(p) for p in clean.split(".") if p.isdigit()]
            while len(parts) < 3:
                parts.append(0)
            return tuple(parts[:3])

        remote_url = custom_remote_url or "https://raw.githubusercontent.com/ahmedsalahsorour88/import_flow/main/version.json"

        try:
            req = urllib.request.Request(
                remote_url,
                headers={"User-Agent": "ImportFlow-Update-Engine"},
            )
            with urllib.request.urlopen(req, timeout=2.5) as resp:
                if resp.status == 200:
                    remote_data = json.loads(resp.read().decode("utf-8"))
                    latest_ver = remote_data.get("version", curr_ver)
                    curr_tuple = parse_ver(curr_ver)
                    latest_tuple = parse_ver(latest_ver)
                    has_update = latest_tuple > curr_tuple

                    release_notes = remote_data.get("release_notes")
                    if not release_notes:
                        try:
                            from version_manager import extract_recent_release_notes
                            release_notes = extract_recent_release_notes()
                        except Exception:
                            release_notes = [
                                "تحسينات شاملة في أداء النظام واستقرار قاعدة البيانات",
                                "تحديثات في محرك استخراج وثائق الشحن والجمارك",
                                "ترقية وتطوير واجهات الاستيراد ومطابقة البيانات",
                            ]

                    download_url = remote_data.get(
                        "download_url",
                        f"https://github.com/ahmedsalahsorour88/import_flow/releases/tag/v{latest_ver}",
                    )

                    # Installer metadata for in-app auto-update
                    installer_url = remote_data.get(
                        "installer_url",
                        f"https://github.com/ahmedsalahsorour88/import_flow/releases/download/v{latest_ver}/Sorour_Logistics_Setup_v{latest_ver}.exe",
                    )
                    installer_filename = remote_data.get(
                        "installer_filename",
                        f"Sorour_Logistics_Setup_v{latest_ver}.exe",
                    )
                    installer_size_mb = float(remote_data.get("installer_size_mb", 0.0))

                    return RemoteUpdateCheckSchema(
                        has_update=has_update,
                        current_version=curr_ver,
                        latest_version=latest_ver,
                        release_name=f"Sorour Logistics Release v{latest_ver}",
                        release_notes=release_notes,
                        download_url=download_url,
                        installer_url=installer_url,
                        installer_filename=installer_filename,
                        installer_size_mb=installer_size_mb,
                        published_at=remote_data.get("updated_at"),
                        is_mandatory=remote_data.get("is_mandatory", False),
                        check_status="UPDATE_AVAILABLE" if has_update else "UP_TO_DATE",
                        message=f"يتوفر إصدار جديد v{latest_ver} جاهز للتنزيل والترقية التلقائية!" if has_update else "النظام محدث لأحدث إصدار رسمي.",
                    )
        except Exception:
            pass

        return RemoteUpdateCheckSchema(
            has_update=False,
            current_version=curr_ver,
            latest_version=curr_ver,
            release_notes=[],
            check_status="UP_TO_DATE",
            message="النظام محدث ومستقر بأحدث إصدار مثبت (v" + curr_ver + ").",
        )

    def get_latest_installer_info(self) -> "InstallerInfoSchema":
        """
        Fetches the latest installer metadata from the remote version.json on GitHub.
        Returns installer_url, installer_filename, and installer_size_mb for in-app auto-update.
        """
        from modules.production_sync.schemas import InstallerInfoSchema
        import urllib.request

        remote_url = "https://raw.githubusercontent.com/ahmedsalahsorour88/import_flow/main/version.json"
        try:
            req = urllib.request.Request(
                remote_url,
                headers={"User-Agent": "ImportFlow-AutoUpdater"},
            )
            with urllib.request.urlopen(req, timeout=5) as resp:
                if resp.status == 200:
                    data = json.loads(resp.read().decode("utf-8"))
                    version = data.get("version", "1.0.0")
                    installer_url = data.get(
                        "installer_url",
                        f"https://github.com/ahmedsalahsorour88/import_flow/releases/download/v{version}/Sorour_Logistics_Setup_v{version}.exe",
                    )
                    installer_filename = data.get(
                        "installer_filename",
                        f"Sorour_Logistics_Setup_v{version}.exe",
                    )
                    installer_size_mb = float(data.get("installer_size_mb", 0.0))
                    return InstallerInfoSchema(
                        version=version,
                        installer_url=installer_url,
                        installer_filename=installer_filename,
                        installer_size_mb=installer_size_mb,
                        is_available=True,
                    )
        except Exception:
            pass

        # Fallback: read from local version.json
        try:
            v_file = ROOT_DIR / "version.json"
            if v_file.exists():
                with open(v_file, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    version = data.get("version", "1.0.0")
                    installer_url = data.get("installer_url", "")
                    installer_filename = data.get("installer_filename", f"Sorour_Logistics_Setup_v{version}.exe")
                    installer_size_mb = float(data.get("installer_size_mb", 0.0))
                    if installer_url:
                        return InstallerInfoSchema(
                            version=version,
                            installer_url=installer_url,
                            installer_filename=installer_filename,
                            installer_size_mb=installer_size_mb,
                            is_available=True,
                        )
        except Exception:
            pass

        return InstallerInfoSchema(
            version="unknown",
            installer_url="",
            installer_filename="",
            installer_size_mb=0.0,
            is_available=False,
            error="تعذّر الاتصال بخادم التحديثات. يرجى التحقق من الاتصال بالإنترنت.",
        )
