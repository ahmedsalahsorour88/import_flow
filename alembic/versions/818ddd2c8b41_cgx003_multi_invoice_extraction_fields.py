"""cgx003_multi_invoice_extraction_fields

Revision ID: 818ddd2c8b41
Revises: 7a8e9f123456
Create Date: 2026-09-02 12:37:10.771706

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '818ddd2c8b41'
down_revision: Union[str, Sequence[str], None] = '7a8e9f123456'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """CGX-003: Add multi-invoice extraction fields. ADD COLUMN / CREATE TABLE only."""
    with op.batch_alter_table('import_files', schema=None) as batch_op:
        batch_op.add_column(sa.Column('invoices_count', sa.Integer(), nullable=True))
        batch_op.add_column(sa.Column('extraction_preference', sa.String(length=50), nullable=True))

    with op.batch_alter_table('packing_list_items', schema=None) as batch_op:
        batch_op.add_column(sa.Column('invoice_number', sa.String(length=100), nullable=True))
        batch_op.add_column(sa.Column('pallet_number', sa.Integer(), nullable=True))
        batch_op.add_column(sa.Column('carton_numbers', sa.JSON(), nullable=True))
        batch_op.create_index(batch_op.f('ix_packing_list_items_invoice_number'), ['invoice_number'], unique=False)

    with op.batch_alter_table('po_line_items', schema=None) as batch_op:
        batch_op.add_column(sa.Column('invoice_number', sa.String(length=100), nullable=True))
        batch_op.add_column(sa.Column('invoice_line_number', sa.Integer(), nullable=True))
        batch_op.add_column(sa.Column('customs_unit_price', sa.Numeric(precision=14, scale=4), nullable=True))
        batch_op.create_index(batch_op.f('ix_po_line_items_invoice_number'), ['invoice_number'], unique=False)

    op.create_table(
        'cargox_customs_invoice_tracks',
        sa.Column('track_id', sa.Integer(), nullable=False, autoincrement=True),
        sa.Column('track_code', sa.String(length=80), nullable=False),
        sa.Column('import_file_id', sa.Integer(), nullable=False),
        sa.Column('import_file_code', sa.String(length=100), nullable=True),
        sa.Column('source_invoice_numbers', sa.JSON(), nullable=True),
        sa.Column('extraction_mode', sa.String(length=50), nullable=False, server_default='all_consolidated'),
        sa.Column('grouping_mode', sa.String(length=50), nullable=False, server_default='by_hs_code'),
        sa.Column('customs_total_amount', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('customs_gross_weight', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('customs_net_weight', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('customs_packages_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('line_items_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('customs_invoice_data', sa.JSON(), nullable=True),
        sa.Column('customs_packing_list_data', sa.JSON(), nullable=True),
        sa.Column('status', sa.String(length=50), nullable=False, server_default='DRAFT'),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='1'),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('created_by', sa.String(length=100), nullable=False, server_default='SYSTEM'),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('updated_by', sa.String(length=100), nullable=False, server_default='SYSTEM'),
        sa.ForeignKeyConstraint(
            ['import_file_id'], ['import_files.import_file_id'],
            name=op.f('fk_cargox_customs_invoice_tracks_import_file_id_import_files')
        ),
        sa.PrimaryKeyConstraint('track_id', name=op.f('pk_cargox_customs_invoice_tracks')),
    )
    with op.batch_alter_table('cargox_customs_invoice_tracks', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_cargox_customs_invoice_tracks_track_id'), ['track_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_cargox_customs_invoice_tracks_track_code'), ['track_code'], unique=True)
        batch_op.create_index(batch_op.f('ix_cargox_customs_invoice_tracks_import_file_id'), ['import_file_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_cargox_customs_invoice_tracks_is_active'), ['is_active'], unique=False)
        batch_op.create_index(batch_op.f('ix_cargox_customs_invoice_tracks_status'), ['status'], unique=False)


def downgrade() -> None:
    """Reverse CGX-003."""
    with op.batch_alter_table('cargox_customs_invoice_tracks', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_cargox_customs_invoice_tracks_status'))
        batch_op.drop_index(batch_op.f('ix_cargox_customs_invoice_tracks_is_active'))
        batch_op.drop_index(batch_op.f('ix_cargox_customs_invoice_tracks_import_file_id'))
        batch_op.drop_index(batch_op.f('ix_cargox_customs_invoice_tracks_track_code'))
        batch_op.drop_index(batch_op.f('ix_cargox_customs_invoice_tracks_track_id'))
    op.drop_table('cargox_customs_invoice_tracks')

    with op.batch_alter_table('po_line_items', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_po_line_items_invoice_number'))
        batch_op.drop_column('customs_unit_price')
        batch_op.drop_column('invoice_line_number')
        batch_op.drop_column('invoice_number')

    with op.batch_alter_table('packing_list_items', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_packing_list_items_invoice_number'))
        batch_op.drop_column('carton_numbers')
        batch_op.drop_column('pallet_number')
        batch_op.drop_column('invoice_number')

    with op.batch_alter_table('import_files', schema=None) as batch_op:
        batch_op.drop_column('extraction_preference')
        batch_op.drop_column('invoices_count')