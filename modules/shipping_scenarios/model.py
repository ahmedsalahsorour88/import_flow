from datetime import datetime, timezone, date
from sqlalchemy import (
    Column,
    Integer,
    String,
    Float,
    Text,
    Boolean,
    Date,
    DateTime,
    ForeignKey,
)
from sqlalchemy.orm import relationship

from database.database import Base


class ShippingEvaluationSession(Base):
    """
    BP-007 Shipping Scenarios Evaluation Session Model
    Stores multi-carrier evaluation studies for estimated transit time and warehouse arrival calculation.
    """

    __tablename__ = "shipping_evaluation_sessions"

    session_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    session_code = Column(String(50), unique=True, index=True, nullable=False)
    title = Column(String(200), nullable=True)

    cargo_ready_date = Column(Date, nullable=False, default=date.today)
    port_of_loading_id = Column(Integer, ForeignKey("transport_locations.location_id"), nullable=True)
    port_of_discharge_id = Column(Integer, ForeignKey("transport_locations.location_id"), nullable=True)

    avg_form4_days = Column(Integer, default=5, nullable=False)
    avg_clearance_days = Column(Integer, default=7, nullable=False)

    po_id = Column(Integer, ForeignKey("purchase_orders.po_id"), nullable=True)
    project_id = Column(Integer, ForeignKey("projects.project_id"), nullable=True)

    notes = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)

    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    items = relationship(
        "ShippingScenarioItem",
        back_populates="session",
        cascade="all, delete-orphan",
    )


class ShippingScenarioItem(Base):
    """
    BP-007 Shipping Scenario Item Model
    Stores individual carrier voyage options for a shipping evaluation session.
    """

    __tablename__ = "shipping_scenario_items"

    item_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    session_id = Column(Integer, ForeignKey("shipping_evaluation_sessions.session_id"), nullable=False)

    provider_id = Column(Integer, ForeignKey("external_service_providers.provider_id"), nullable=True)
    provider_name = Column(String(150), nullable=False)
    vessel_name = Column(String(150), nullable=False)
    voyage_number = Column(String(50), nullable=True)

    sailing_date = Column(Date, nullable=False)
    estimated_arrival_date = Column(Date, nullable=False)
    expected_line_delay_days = Column(Integer, default=0, nullable=False)

    is_excluded_from_average = Column(Boolean, default=False, nullable=False)
    is_recommended = Column(Boolean, default=False, nullable=False)
    is_selected = Column(Boolean, default=False, nullable=False)

    risk_level = Column(String(50), default="Low", nullable=False)  # Low, Medium, High
    notes = Column(Text, nullable=True)

    session = relationship("ShippingEvaluationSession", back_populates="items")
