from datetime import datetime
from sqlalchemy import Boolean, Column, DateTime, Float, Integer, String, Text

from database.database import Base


class ContainerSpecModel(Base):
    __tablename__ = "container_specs"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(20), unique=True, index=True, nullable=False)  # 20GP, 40GP, 40HC, 45HC
    name = Column(String(100), nullable=False)
    internal_length = Column(Float, nullable=False)
    internal_width = Column(Float, nullable=False)
    internal_height = Column(Float, nullable=False)
    door_width = Column(Float, nullable=False)
    door_height = Column(Float, nullable=False)
    max_payload = Column(Float, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class ContainerLoaderSessionModel(Base):
    __tablename__ = "container_loader_sessions"

    id = Column(Integer, primary_key=True, index=True)
    session_code = Column(String(50), unique=True, index=True, nullable=False)
    total_packages_count = Column(Integer, nullable=False, default=0)
    total_cbm = Column(Float, nullable=False, default=0.0)
    total_weight_kg = Column(Float, nullable=False, default=0.0)
    is_stackable = Column(Boolean, default=False)
    recommended_container = Column(String(20), nullable=False)
    recommended_count = Column(Integer, default=1)
    floor_utilization_pct = Column(Float, default=0.0)
    evaluation_json = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
