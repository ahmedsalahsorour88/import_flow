from datetime import datetime
from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    ForeignKey,
    Float,
    JSON,
    Text,
)
from sqlalchemy.orm import relationship
from database.database import Base

class LandedCostSettlementRecord(Base):
    """
    Phase 9 Financial Settlement & Landed Cost Engine Model (BP-036 to BP-039)
    Tracks expense invoices (freight, customs duties, brokerage, local transport, storage),
    allocates costs by Value/Weight/Volume/Equal, and calculates unit landed cost and markup factor per item line.
    """
    __tablename__ = "financial_settlement_records"

    settlement_id = Column(Integer, primary_key=True, index=True)
    settlement_code = Column(String(50), unique=True, index=True, nullable=False) # e.g. LCS-2026-0001

    import_file_id = Column(Integer, ForeignKey("import_files.import_file_id"), nullable=False)
    
    # BP-036 & BP-037 Expense Invoices JSON
    # Schema: [{"invoice_no": "INV-100", "category": "Freight", "provider_name": "Maersk", "currency": "USD", "amount_fx": 1000.0, "exchange_rate": 50.0, "amount_egp": 50000.0, "allocation_rule": "Volume-Based"}]
    expense_invoices = Column(JSON, default=list, nullable=False)
    
    total_fob_egp = Column(Float, default=0.0, nullable=False)
    total_expenses_egp = Column(Float, default=0.0, nullable=False)
    total_landed_cost_egp = Column(Float, default=0.0, nullable=False)
    average_markup_factor = Column(Float, default=1.0, nullable=False)

    # BP-038 & BP-039 Item Landed Cost Breakdown JSON
    # Schema: [{"item_code": "ITM-001", "item_name": "Steel Valves", "qty": 100, "fob_unit_egp": 100.0, "fob_total_egp": 10000.0, "allocated_freight_egp": 2000.0, "allocated_customs_egp": 1400.0, "allocated_clearance_egp": 500.0, "allocated_transport_egp": 300.0, "allocated_other_egp": 100.0, "total_landed_cost_egp": 14300.0, "unit_landed_cost_egp": 143.0, "markup_factor": 1.43}]
    item_landed_costs = Column(JSON, default=list, nullable=False)

    status = Column(String(50), default="Draft", index=True) # Draft, Expenses Logged, Calculated, Approved, Closed
    accountant_name = Column(String(100), default="Kamal", nullable=False)
    notes = Column(Text, nullable=True)

    is_active = Column(Boolean, default=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    created_by = Column(String(100), default="System")
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    updated_by = Column(String(100), default="System")

    # Relationships
    import_file = relationship("ImportFile", backref="financial_settlement_records")
