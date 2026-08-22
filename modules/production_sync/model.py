"""
Production Sync Model (SQLAlchemy Models)
"""
from sqlalchemy import Column, Integer, String, Float, DateTime, Text
from datetime import datetime
from database.database import Base


class ProductionSyncLog(Base):
    """Audit log record for in-app production sync operations."""
    __tablename__ = "production_sync_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    action_type = Column(String(50), nullable=False)  # PUSH_TO_PROD, PULL_TO_DEV, CREATE_BACKUP, COMPARE
    status = Column(String(20), nullable=False, default="SUCCESS")  # SUCCESS, FAILED
    performed_by = Column(String(100), nullable=True, default="System User")
    backup_path = Column(String(255), nullable=True)
    records_count = Column(Integer, default=0)
    tables_count = Column(Integer, default=0)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
