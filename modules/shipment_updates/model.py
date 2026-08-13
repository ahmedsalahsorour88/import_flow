"""
SQLAlchemy Models for Operational & Daily Shipment Update Engine
"""

from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, Float, ForeignKey, Index
from database.database import Base


class ShipmentUpdateLog(Base):
    __tablename__ = "shipment_update_logs"

    update_id = Column(Integer, primary_key=True, index=True)
    update_code = Column(String(50), unique=True, index=True, nullable=False)
    import_file_id = Column(Integer, ForeignKey("import_files.import_file_id", ondelete="CASCADE"), nullable=False, index=True)
    import_file_code = Column(String(100), nullable=False)
    
    update_category = Column(String(50), default="Follow-up & Notes", nullable=False)
    # Categories: 'Follow-up & Notes', 'Phase Cost Adjustment', 'Future Phase Alert', 'Daily Check-in'

    target_phase = Column(String(100), nullable=False)  # Phase 1 -> Phase 10
    phase_status = Column(String(50), default="Completed", nullable=False)  # 'Completed', 'Current', 'Future'

    log_date = Column(String(50), nullable=False)  # YYYY-MM-DD
    note = Column(Text, nullable=False)
    
    # Financial / Cost adjustment fields (optional for Type B)
    adjusted_cost_item = Column(String(100), nullable=True)
    previous_cost = Column(Float, default=0.0)
    new_cost = Column(Float, default=0.0)
    
    # Future Alert / Priority fields (optional for Type C)
    alert_priority = Column(String(50), default="Normal", nullable=False)  # Normal, High, Critical
    assigned_user = Column(String(100), default="Kamal", nullable=False)
    
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    created_by = Column(String(100), default="System")
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    updated_by = Column(String(100), default="System")

    __table_args__ = (
        Index("idx_shipment_update_file", "import_file_id"),
        Index("idx_shipment_update_category", "update_category"),
        Index("idx_shipment_update_phase", "target_phase"),
    )
