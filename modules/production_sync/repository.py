"""
Production Sync Repository
"""
from typing import List, Optional
from sqlalchemy.orm import Session
from modules.production_sync.model import ProductionSyncLog


class ProductionSyncRepository:
    def __init__(self, db: Session):
        self.db = db

    def create_log(
        self,
        action_type: str,
        status: str = "SUCCESS",
        performed_by: str = "System User",
        backup_path: Optional[str] = None,
        records_count: int = 0,
        tables_count: int = 0,
        notes: Optional[str] = None,
    ) -> ProductionSyncLog:
        log = ProductionSyncLog(
            action_type=action_type,
            status=status,
            performed_by=performed_by,
            backup_path=backup_path,
            records_count=records_count,
            tables_count=tables_count,
            notes=notes,
        )
        self.db.add(log)
        self.db.commit()
        self.db.refresh(log)
        return log

    def get_recent_logs(self, limit: int = 20) -> List[ProductionSyncLog]:
        return (
            self.db.query(ProductionSyncLog)
            .order_by(ProductionSyncLog.created_at.desc())
            .limit(limit)
            .all()
        )
