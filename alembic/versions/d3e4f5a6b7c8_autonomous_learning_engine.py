"""autonomous_learning_engine

Revision ID: d3e4f5a6b7c8
Revises: c2d3e4f5a6b7
Create Date: 2026-09-23 15:00:00.000000
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = 'd3e4f5a6b7c8'
down_revision: Union[str, Sequence[str], None] = 'c2d3e4f5a6b7'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add autonomous learning engine fields and audit log table."""
    with op.batch_alter_table('guide_entries', schema=None) as batch_op:
        batch_op.add_column(sa.Column('source_type', sa.String(length=30), server_default='HUMAN_AUTHORED', nullable=False))
        batch_op.add_column(sa.Column('status', sa.String(length=30), server_default='ACTIVE', nullable=False))
        batch_op.add_column(sa.Column('pattern_category', sa.String(length=50), nullable=True))
        batch_op.add_column(sa.Column('confidence_score', sa.Float(), nullable=True))
        batch_op.add_column(sa.Column('confidence_level', sa.String(length=20), nullable=True))
        batch_op.add_column(sa.Column('sample_size', sa.Integer(), nullable=True))
        batch_op.add_column(sa.Column('evidence_summary', sa.Text(), nullable=True))
        batch_op.add_column(sa.Column('contributing_files_json', sa.Text(), nullable=True))
        batch_op.add_column(sa.Column('reason_why', sa.Text(), nullable=True))
        batch_op.add_column(sa.Column('first_detected_at', sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column('last_recalculated_at', sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column('confirmed_by', sa.String(length=100), nullable=True))
        batch_op.add_column(sa.Column('confirmed_at', sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column('rejected_by', sa.String(length=100), nullable=True))
        batch_op.add_column(sa.Column('rejected_at', sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column('rejection_reason', sa.Text(), nullable=True))
        batch_op.create_index('idx_guide_entries_source_status', ['source_type', 'status'])
        batch_op.create_index('idx_guide_entries_pattern_category', ['pattern_category'])

    op.create_table(
        'autonomous_pattern_audit_logs',
        sa.Column('log_id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('entry_id', sa.Integer(), nullable=True),
        sa.Column('pattern_key', sa.String(length=150), nullable=False),
        sa.Column('trigger_import_file_id', sa.Integer(), nullable=True),
        sa.Column('action', sa.String(length=50), nullable=False),
        sa.Column('previous_confidence', sa.Float(), nullable=True),
        sa.Column('new_confidence', sa.Float(), nullable=True),
        sa.Column('sample_size', sa.Integer(), server_default='0', nullable=False),
        sa.Column('change_summary', sa.Text(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['entry_id'], ['guide_entries.entry_id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('log_id')
    )
    op.create_index('idx_pattern_audit_logs_pattern_key', 'autonomous_pattern_audit_logs', ['pattern_key'])


def downgrade() -> None:
    """Revert autonomous learning engine fields and audit log table."""
    op.drop_index('idx_pattern_audit_logs_pattern_key', table_name='autonomous_pattern_audit_logs')
    op.drop_table('autonomous_pattern_audit_logs')

    with op.batch_alter_table('guide_entries', schema=None) as batch_op:
        batch_op.drop_index('idx_guide_entries_pattern_category')
        batch_op.drop_index('idx_guide_entries_source_status')
        batch_op.drop_column('rejection_reason')
        batch_op.drop_column('rejected_at')
        batch_op.drop_column('rejected_by')
        batch_op.drop_column('confirmed_at')
        batch_op.drop_column('confirmed_by')
        batch_op.drop_column('last_recalculated_at')
        batch_op.drop_column('first_detected_at')
        batch_op.drop_column('reason_why')
        batch_op.drop_column('contributing_files_json')
        batch_op.drop_column('evidence_summary')
        batch_op.drop_column('sample_size')
        batch_op.drop_column('confidence_level')
        batch_op.drop_column('confidence_score')
        batch_op.drop_column('pattern_category')
        batch_op.drop_column('status')
        batch_op.drop_column('source_type')
