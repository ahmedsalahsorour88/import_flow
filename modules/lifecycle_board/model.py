"""
SQLAlchemy Model for Shipment Stage Activity & Lifecycle Board
"""

from sqlalchemy import Column, Integer, String, Text
from database.database import Base


class ShipmentStageActivity(Base):
    __tablename__ = "shipment_stage_activity"

    id = Column(Integer, primary_key=True, index=True)
    import_file_code = Column(String(50), nullable=False, index=True)
    step_code = Column(String(50), nullable=False, index=True) # e.g. STEP_01 to STEP_21
    status = Column(String(50), nullable=False, default="In-Progress") # In-Progress, Completed, On-Hold, Pending
    started_at = Column(String(50), nullable=True)
    completed_at = Column(String(50), nullable=True)
    assigned_user = Column(String(100), nullable=True)
    action_data = Column(Text, nullable=True) # JSON String with step parameters
    notes = Column(Text, nullable=True)
