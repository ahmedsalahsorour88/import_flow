"""smart_experience_guide_institutional_engine

Revision ID: c2d3e4f5a6b7
Revises: b1c2d3e4f5a6
Create Date: 2026-09-23 14:00:00.000000
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = 'c2d3e4f5a6b7'
down_revision: Union[str, Sequence[str], None] = 'b1c2d3e4f5a6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add department, expires_at, and upvotes to guide_entries table."""
    with op.batch_alter_table('guide_entries', schema=None) as batch_op:
        batch_op.add_column(sa.Column('department', sa.String(length=100), nullable=True))
        batch_op.add_column(sa.Column('expires_at', sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column('upvotes', sa.Integer(), server_default='0', nullable=False))


def downgrade() -> None:
    """Revert department, expires_at, and upvotes from guide_entries table."""
    with op.batch_alter_table('guide_entries', schema=None) as batch_op:
        batch_op.drop_column('upvotes')
        batch_op.drop_column('expires_at')
        batch_op.drop_column('department')
