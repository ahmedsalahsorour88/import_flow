"""cgx004_dual_extraction_packing_list_fields

Revision ID: a9c2e4f1b308
Revises: 818ddd2c8b41
Create Date: 2026-09-02 15:00:00.000000
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = 'a9c2e4f1b308'
down_revision: Union[str, Sequence[str], None] = '818ddd2c8b41'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """CGX-004: Add Packing List independent engine fields."""
    with op.batch_alter_table('cargox_customs_invoice_tracks', schema=None) as batch_op:
        batch_op.add_column(sa.Column('packing_list_mode', sa.String(length=50), nullable=True, server_default='all_consolidated'))
        batch_op.add_column(sa.Column('packing_list_structure', sa.String(length=50), nullable=True, server_default='by_hs_code'))
        batch_op.add_column(sa.Column('packing_list_count', sa.Integer(), nullable=True, server_default='1'))
        batch_op.add_column(sa.Column('include_pallets', sa.Boolean(), nullable=False, server_default='0'))
        batch_op.add_column(sa.Column('pallets_data', sa.JSON(), nullable=True))


def downgrade() -> None:
    """Reverse CGX-004."""
    with op.batch_alter_table('cargox_customs_invoice_tracks', schema=None) as batch_op:
        batch_op.drop_column('pallets_data')
        batch_op.drop_column('include_pallets')
        batch_op.drop_column('packing_list_count')
        batch_op.drop_column('packing_list_structure')
        batch_op.drop_column('packing_list_mode')
