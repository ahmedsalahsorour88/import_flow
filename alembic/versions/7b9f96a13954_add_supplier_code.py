"""add supplier code

Revision ID: 7b9f96a13954
Revises: 5cb3e798dae5
Create Date: 2026-08-06 14:16:41.495516

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '7b9f96a13954'
down_revision: Union[str, Sequence[str], None] = '5cb3e798dae5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""

    with op.batch_alter_table("suppliers") as batch_op:
        batch_op.alter_column(
            "supplier_code",
            existing_type=sa.String(length=50),
            nullable=False
        )


def downgrade() -> None:
    """Downgrade schema."""

    with op.batch_alter_table("suppliers") as batch_op:
        batch_op.alter_column(
            "supplier_code",
            existing_type=sa.String(length=50),
            nullable=True
        )