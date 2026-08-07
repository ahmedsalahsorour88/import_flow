from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, Integer, String, Text
from database.database import Base


class AuditLog(Base):
    __tablename__ = "audit_logs"

    log_id = Column(Integer, primary_key=True, autoincrement=True, index=True)
    entity_type = Column(String(100), nullable=False, index=True)  # ImportCompany, Supplier, ExternalServiceProvider
    entity_id = Column(Integer, nullable=False, index=True)
    entity_code = Column(String(100), index=True)
    action = Column(String(50), nullable=False)  # CREATE, UPDATE, DELETE, RESTORE
    changes_summary = Column(Text)
    old_values = Column(Text)  # JSON string
    new_values = Column(Text)  # JSON string
    performed_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    performed_by = Column(String(100), default="System Admin")
