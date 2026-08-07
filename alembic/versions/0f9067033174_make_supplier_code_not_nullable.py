"""make supplier code not nullable

Revision ID: 0f9067033174
Revises: 7b9f96a13954
Create Date: 2026-08-06
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers
revision: str = "0f9067033174"
down_revision: Union[str, Sequence[str], None] = "7b9f96a13954"
branch_labels = None
depends_on = None


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