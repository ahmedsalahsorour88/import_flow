"""add_po_reference_to_purchase_orders

Revision ID: 7a8e9f123456
Revises: 4e8d5e046be7
Create Date: 2026-08-30 14:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.engine.reflection import Inspector


# revision identifiers, used by Alembic.
revision: str = '7a8e9f123456'
down_revision: Union[str, Sequence[str], None] = '4e8d5e046be7'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = Inspector.from_engine(conn)
    columns = [c['name'] for c in inspector.get_columns('purchase_orders')]
    if 'po_reference' not in columns:
        with op.batch_alter_table('purchase_orders', schema=None) as batch_op:
            batch_op.add_column(sa.Column('po_reference', sa.String(length=200), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table('purchase_orders', schema=None) as batch_op:
        batch_op.drop_column('po_reference')
