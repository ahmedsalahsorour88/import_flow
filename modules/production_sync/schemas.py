"""
Production Sync Pydantic Schemas
"""
from typing import List, Dict, Optional, Any
from pydantic import BaseModel, Field


class DatabaseStatsSchema(BaseModel):
    exists: bool = True
    path: Optional[str] = None
    size_kb: float = 0.0
    tables_count: int = 0
    total_records: int = 0
    mtime: Optional[str] = None
    error: Optional[str] = None


class TableComparisonItemSchema(BaseModel):
    table_name: str
    dev_count: int
    prod_count: int
    diff: int
    is_match: bool
    status: str
    # ── Schema comparison fields ─────────────────────────────────────────
    dev_columns_count: int = 0
    prod_columns_count: int = 0
    new_columns: List[str] = Field(default_factory=list)   # cols in Dev missing from Prod
    is_new_table: bool = False                              # table exists in Dev only
    has_schema_diff: bool = False                          # True if schema differs (new cols / new table)
    needs_sync: bool = False                               # True if data OR schema differs


class SyncComparisonResponseSchema(BaseModel):
    dev_stats: DatabaseStatsSchema
    prod_stats: DatabaseStatsSchema
    is_fully_synchronized: bool
    total_tables: int
    matched_tables_count: int
    differing_tables_count: int
    schema_diffs_count: int = 0     # tables with schema differences (new cols / new tables)
    tables: List[TableComparisonItemSchema]


class SyncActionResponseSchema(BaseModel):
    success: bool
    action: str
    message: str
    timestamp: str
    backup_file: Optional[str] = None
    affected_tables_count: int = 0
    total_records_synced: int = 0
    details: Optional[Dict[str, Any]] = None


class BackupItemSchema(BaseModel):
    filename: str
    filepath: str
    size_kb: float
    created_at: str
    tag: str


class BackupsListResponseSchema(BaseModel):
    total_backups: int
    backups: List[BackupItemSchema]


class RestoreBackupResponseSchema(BaseModel):
    success: bool
    message: str
    timestamp: str
    restored_from: str
    safety_backup_created: str
    target: str


class RemoteUpdateCheckResponseSchema(BaseModel):
    current_version: str
    current_build: int
    latest_version: Optional[str] = None
    latest_tag: Optional[str] = None
    update_available: bool = False
    release_name: Optional[str] = None
    release_notes: Optional[str] = None
    published_at: Optional[str] = None
    installer_download_url: Optional[str] = None
    portable_zip_download_url: Optional[str] = None
    html_url: Optional[str] = None
    check_status: str = "success"
    error_message: Optional[str] = None

