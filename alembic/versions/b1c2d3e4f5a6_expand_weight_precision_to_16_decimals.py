"""expand_weight_precision_to_16_decimals

Revision ID: b1c2d3e4f5a6
Revises: a9c2e4f1b308
Create Date: 2026-09-22 20:00:00.000000
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = 'b1c2d3e4f5a6'
down_revision: Union[str, Sequence[str], None] = 'a9c2e4f1b308'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Expand weights precision from Numeric(12, 2) to Numeric(26, 16)."""
    with op.batch_alter_table('purchase_orders', schema=None) as batch_op:
        batch_op.alter_column('total_gross_weight_kg', existing_type=sa.Numeric(12, 2), type_=sa.Numeric(26, 16))
        batch_op.alter_column('total_net_weight_kg', existing_type=sa.Numeric(12, 2), type_=sa.Numeric(26, 16))

    with op.batch_alter_table('po_line_items', schema=None) as batch_op:
        batch_op.alter_column('gross_weight_kg', existing_type=sa.Numeric(12, 2), type_=sa.Numeric(26, 16))
        batch_op.alter_column('net_weight_kg', existing_type=sa.Numeric(12, 2), type_=sa.Numeric(26, 16))

    with op.batch_alter_table('packing_list_items', schema=None) as batch_op:
        batch_op.alter_column('net_weight_unit_kg', existing_type=sa.Numeric(12, 2), type_=sa.Numeric(26, 16))
        batch_op.alter_column('gross_weight_unit_kg', existing_type=sa.Numeric(12, 2), type_=sa.Numeric(26, 16))
        batch_op.alter_column('total_net_weight_kg', existing_type=sa.Numeric(12, 2), type_=sa.Numeric(26, 16))
        batch_op.alter_column('total_gross_weight_kg', existing_type=sa.Numeric(12, 2), type_=sa.Numeric(26, 16))
        batch_op.alter_column('chargeable_weight_kg', existing_type=sa.Numeric(12, 2), type_=sa.Numeric(26, 16))


def downgrade() -> None:
    """Revert weights precision back to Numeric(12, 2)."""
    with op.batch_alter_table('packing_list_items', schema=None) as batch_op:
        batch_op.alter_column('chargeable_weight_kg', existing_type=sa.Numeric(26, 16), type_=sa.Numeric(12, 2))
        batch_op.alter_column('total_gross_weight_kg', existing_type=sa.Numeric(26, 16), type_=sa.Numeric(12, 2))
        batch_op.alter_column('total_net_weight_kg', existing_type=sa.Numeric(26, 16), type_=sa.Numeric(12, 2))
        batch_op.alter_column('gross_weight_unit_kg', existing_type=sa.Numeric(26, 16), type_=sa.Numeric(12, 2))
        batch_op.alter_column('net_weight_unit_kg', existing_type=sa.Numeric(26, 16), type_=sa.Numeric(12, 2))

    with op.batch_alter_table('po_line_items', schema=None) as batch_op:
        batch_op.alter_column('net_weight_kg', existing_type=sa.Numeric(26, 16), type_=sa.Numeric(12, 2))
        batch_op.alter_column('gross_weight_kg', existing_type=sa.Numeric(26, 16), type_=sa.Numeric(12, 2))

    with op.batch_alter_table('purchase_orders', schema=None) as batch_op:
        batch_op.alter_column('total_net_weight_kg', existing_type=sa.Numeric(26, 16), type_=sa.Numeric(12, 2))
        batch_op.alter_column('total_gross_weight_kg', existing_type=sa.Numeric(26, 16), type_=sa.Numeric(12, 2))
