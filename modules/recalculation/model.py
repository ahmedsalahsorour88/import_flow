"""
Centralized Recalculation Engine - Data Models (CRE-001)

Two tables:
1. recalculation_dependency_map  — Single Source of Truth for all inter-entity relationships.
2. recalculation_logs            — Unified audit log for every preview/apply action across all pages.

These two tables together mean:
  - Any NEW entity relationship is added as ONE ROW in recalculation_dependency_map.
  - Any NEW page using the engine only needs: RecalculateButton(entityType, entityId).
  - No new business logic code is written per page.
"""

import json
from datetime import datetime, timezone
from sqlalchemy import String, Integer, Boolean, DateTime, Text, Float, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from database.database import Base


class RecalculationDependencyMap(Base):
    """
    Single Source of Truth for all upstream → downstream data dependencies.

    Each row defines ONE dependency edge:
      source_entity_type / source_field ──► target_entity_type / target_field

    The engine reads this table at runtime to discover what data to fetch,
    compare, and optionally apply — without any hardcoded per-page logic.

    Example rows:
      (customs_consultation, total_broker_fees_egp) → (import_budget, clearance_inland_egp)
      (shipping_scenarios,   freight_amount_egp)    → (import_budget, freight_cost_egp)
      (purchase_orders,      total_amount_fob_egp)  → (import_budget, invoice_amount_egp)
    """
    __tablename__ = "recalculation_dependency_map"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True, index=True)

    # ── Target (entity being updated) ──────────────────────────────────────────
    target_entity_type: Mapped[str] = mapped_column(
        String(100), nullable=False, index=True,
        comment="e.g. 'import_budget', 'payment_request', 'acid_registration'"
    )
    target_field: Mapped[str] = mapped_column(
        String(100), nullable=False,
        comment="DB column name in the target entity, e.g. 'clearance_inland_egp'"
    )

    # ── Source (entity providing the live value) ────────────────────────────────
    source_entity_type: Mapped[str] = mapped_column(
        String(100), nullable=False, index=True,
        comment="e.g. 'customs_consultation', 'shipping_scenarios', 'purchase_orders'"
    )
    source_field: Mapped[str] = mapped_column(
        String(100), nullable=False,
        comment="DB column or computed field in the source, e.g. 'total_broker_fees_egp'"
    )

    # ── Join Logic ──────────────────────────────────────────────────────────────
    join_key: Mapped[str] = mapped_column(
        String(100), nullable=False, default="import_file_id",
        comment="Common FK column shared between source and target (e.g. 'import_file_id')"
    )
    aggregation_function: Mapped[str] = mapped_column(
        String(20), nullable=False, default="max",
        comment="How to aggregate multiple source rows: 'max', 'sum', 'latest', 'min'"
    )

    # ── Business Rules (evaluated centrally, NEVER in page code) ────────────────
    blocked_statuses: Mapped[str] = mapped_column(
        Text, nullable=True, default="[]",
        comment="JSON array of entity statuses where apply() is blocked, e.g. [\"Budget Approved\", \"Superseded\"]"
    )
    required_permission: Mapped[str] = mapped_column(
        String(100), nullable=True, default=None,
        comment="Permission code required to call apply(), e.g. 'budget.sync_variance'"
    )

    # ── Display ──────────────────────────────────────────────────────────────────
    label_ar: Mapped[str] = mapped_column(
        String(255), nullable=True,
        comment="Human-readable Arabic description, e.g. 'مصاريف التخليص من دراسة الجمارك'"
    )
    label_en: Mapped[str] = mapped_column(
        String(255), nullable=True,
        comment="Human-readable English description"
    )
    display_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc), nullable=False
    )

    # ── Helpers ────────────────────────────────────────────────────────────────
    @property
    def blocked_statuses_list(self) -> list:
        """Parses the JSON string into a Python list."""
        try:
            return json.loads(self.blocked_statuses or "[]")
        except (json.JSONDecodeError, TypeError):
            return []


class RecalculationLog(Base):
    """
    Unified audit log for every preview and apply action from any page.

    Rules enforced:
    - Every call to preview() or apply() from any page must produce a log entry.
    - source_page field records which UI page triggered the action.
    - No separate log table per page is allowed.
    """
    __tablename__ = "recalculation_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True, index=True)

    # ── What was recalculated ────────────────────────────────────────────────────
    target_entity_type: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    target_entity_id: Mapped[int] = mapped_column(Integer, nullable=False, index=True)

    # ── Action type ─────────────────────────────────────────────────────────────
    action: Mapped[str] = mapped_column(
        String(20), nullable=False,
        comment="'preview' or 'apply'"
    )

    # ── Who / Where ─────────────────────────────────────────────────────────────
    performed_by: Mapped[str] = mapped_column(String(100), nullable=True)
    source_page: Mapped[str] = mapped_column(
        String(200), nullable=True,
        comment="Which UI page triggered this, e.g. 'BudgetRegistryScreen', 'BudgetFormSync'"
    )

    # ── Payload ────────────────────────────────────────────────────────────────
    preview_data: Mapped[str] = mapped_column(
        Text, nullable=True,
        comment="JSON: list of {field, old_value, new_value, variance_amount, variance_pct, is_hard_block}"
    )
    changes_applied: Mapped[str] = mapped_column(
        Text, nullable=True,
        comment="JSON: list of {field, old_value, new_value} actually applied (null if preview only)"
    )
    justification: Mapped[str] = mapped_column(
        Text, nullable=True,
        comment="Written justification provided by user to override Hard Block"
    )

    # ── Outcome ────────────────────────────────────────────────────────────────
    result_status: Mapped[str] = mapped_column(
        String(50), nullable=True,
        comment="'success', 'blocked_permission', 'blocked_status', 'hard_block_no_justification', 'no_changes'"
    )
    new_entity_id: Mapped[int] = mapped_column(
        Integer, nullable=True,
        comment="If a revision was created (e.g. Budget REV2), the new entity ID"
    )
    action_taken: Mapped[str] = mapped_column(
        String(50), nullable=True,
        comment="'auto_updated', 'revalidation_required', 'revision_created', 'no_op'"
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc), nullable=False, index=True
    )
