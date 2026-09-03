"""
Route & Supplier Intelligence Engine Model (AI-ROUTE-006)
"""

from datetime import datetime, timezone
from sqlalchemy import String, Integer, DateTime, ForeignKey, Boolean, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from database.database import Base


class RouteOperationalNote(Base):
    """
    Operational observations, caveats, and memory notes associated with a supplier and shipping route.
    """

    __tablename__ = "route_operational_notes"

    note_id: Mapped[int] = mapped_column(
        Integer, primary_key=True, index=True, autoincrement=True
    )
    supplier_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("suppliers.supplier_id"), nullable=False, index=True
    )
    route_name: Mapped[str] = mapped_column(String(200), nullable=True, index=True)
    note_category: Mapped[str] = mapped_column(String(50), default="General", nullable=False)
    note_text: Mapped[str] = mapped_column(Text, nullable=False)
    
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc), nullable=False
    )
    created_by: Mapped[str] = mapped_column(String(100), default="System", nullable=False)
