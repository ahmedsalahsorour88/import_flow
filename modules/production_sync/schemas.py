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


class SyncComparisonResponseSchema(BaseModel):
    dev_stats: DatabaseStatsSchema
    prod_stats: DatabaseStatsSchema
    is_fully_synchronized: bool
    total_tables: int
    matched_tables_count: int
    differing_tables_count: int
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
