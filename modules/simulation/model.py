"""
SQLAlchemy Model for Simulation Scenarios (محاكي السيناريوهات والأزمات الاستيرادية)
"""

from datetime import datetime, timezone
from sqlalchemy import (
    Column,
    Integer,
    String,
    Float,
    DateTime,
    JSON,
    Text,
)

from database.database import Base


class SavedSimulationScenario(Base):
    __tablename__ = "saved_simulation_scenarios"

    scenario_id = Column(Integer, primary_key=True, autoincrement=True)
    scenario_name = Column(String(200), nullable=False)
    import_file_id = Column(Integer, nullable=True)
    base_currency = Column(String(10), default="USD")
    base_exchange_rate = Column(Float, nullable=False, default=50.0)
    simulated_exchange_rate = Column(Float, nullable=False, default=50.0)
    rate_change_pct = Column(Float, nullable=False, default=0.0)
    shipping_route = Column(String(50), default="RED_SEA")
    transit_delay_days = Column(Integer, default=0)
    port_storage_delay_days = Column(Integer, default=0)
    baseline_landed_cost = Column(Float, default=0.0)
    simulated_landed_cost = Column(Float, default=0.0)
    cost_variance_amount = Column(Float, default=0.0)
    cost_variance_pct = Column(Float, default=0.0)
    acid_risk_status = Column(String(50), default="SAFE")
    risk_level = Column(String(50), default="LOW")
    recommendations = Column(JSON, nullable=True)
    scenario_data = Column(JSON, nullable=True)
    created_by = Column(String(100), default="System User")
    created_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
