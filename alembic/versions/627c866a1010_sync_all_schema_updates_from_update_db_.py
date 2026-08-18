"""sync_all_schema_updates_from_update_db_schema

Revision ID: 627c866a1010
Revises: 0f9067033174
Create Date: 2026-08-18 17:30:44.820742

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '627c866a1010'
down_revision: Union[str, Sequence[str], None] = '0f9067033174'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    from sqlalchemy.engine.reflection import Inspector
    conn = op.get_bind()
    inspector = Inspector.from_engine(conn)

    # external_service_providers
    columns = [c['name'] for c in inspector.get_columns('external_service_providers')]
    if 'tax_id' not in columns:
        op.add_column('external_service_providers', sa.Column('tax_id', sa.String(50)))
    if 'commercial_register' not in columns:
        op.add_column('external_service_providers', sa.Column('commercial_register', sa.String(50)))
    if 'clearance_license_number' not in columns:
        op.add_column('external_service_providers', sa.Column('clearance_license_number', sa.String(50)))
    if 'scac_code' not in columns:
        op.add_column('external_service_providers', sa.Column('scac_code', sa.String(20)))
    if 'tracking_url' not in columns:
        op.add_column('external_service_providers', sa.Column('tracking_url', sa.String(300)))
    if 'swift_code' not in columns:
        op.add_column('external_service_providers', sa.Column('swift_code', sa.String(20)))
    if 'bank_code' not in columns:
        op.add_column('external_service_providers', sa.Column('bank_code', sa.String(20)))
    if 'branch_name' not in columns:
        op.add_column('external_service_providers', sa.Column('branch_name', sa.String(100)))
    if 'rating' not in columns:
        op.add_column('external_service_providers', sa.Column('rating', sa.Float(), server_default='5.0'))
    if 'secondary_email' not in columns:
        op.add_column('external_service_providers', sa.Column('secondary_email', sa.String(150)))
    if 'fax' not in columns:
        op.add_column('external_service_providers', sa.Column('fax', sa.String(50)))
    if 'website' not in columns:
        op.add_column('external_service_providers', sa.Column('website', sa.String(200)))

    # suppliers
    columns = [c['name'] for c in inspector.get_columns('suppliers')]
    if 'secondary_email' not in columns:
        op.add_column('suppliers', sa.Column('secondary_email', sa.String(150)))
    if 'mobile' not in columns:
        op.add_column('suppliers', sa.Column('mobile', sa.String(50)))
    if 'fax' not in columns:
        op.add_column('suppliers', sa.Column('fax', sa.String(50)))
    if 'bank_name' not in columns:
        op.add_column('suppliers', sa.Column('bank_name', sa.String(200)))
    if 'swift_code' not in columns:
        op.add_column('suppliers', sa.Column('swift_code', sa.String(50)))
    if 'account_number' not in columns:
        op.add_column('suppliers', sa.Column('account_number', sa.String(100)))
    if 'iban' not in columns:
        op.add_column('suppliers', sa.Column('iban', sa.String(100)))
    if 'has_iso' not in columns:
        op.add_column('suppliers', sa.Column('has_iso', sa.Boolean(), server_default='0'))
    if 'registered_decree_43' not in columns:
        op.add_column('suppliers', sa.Column('registered_decree_43', sa.Boolean(), server_default='0'))
    if 'white_list_registered' not in columns:
        op.add_column('suppliers', sa.Column('white_list_registered', sa.Boolean(), server_default='0'))
    if 'cargox_platform_id' not in columns:
        op.add_column('suppliers', sa.Column('cargox_platform_id', sa.String(100)))

    # acid_registration_sessions
    columns = [c['name'] for c in inspector.get_columns('acid_registration_sessions')]
    if 'proforma_invoice_date' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('proforma_invoice_date', sa.Date()))
    if 'po_number' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('po_number', sa.String(100)))
    if 'po_date' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('po_date', sa.Date()))
    if 'importer_address' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('importer_address', sa.String(300)))
    if 'exporter_reg_type' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('exporter_reg_type', sa.String(100), server_default='VAT Number'))
    if 'exporter_country_code' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('exporter_country_code', sa.String(10)))
    if 'exporter_address' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('exporter_address', sa.String(300)))
    if 'exporter_phone' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('exporter_phone', sa.String(50)))
    if 'cargox_id' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('cargox_id', sa.String(100)))
    if 'invoice_date' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('invoice_date', sa.Date()))
    if 'invoice_type' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('invoice_type', sa.String(50), server_default='Proforma Invoice'))
    if 'invoice_attachment_name' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('invoice_attachment_name', sa.String(255)))
    if 'customs_broker_id' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('customs_broker_id', sa.Integer()))
    if 'customs_broker_name' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('customs_broker_name', sa.String(200)))
    if 'customs_broker_phone' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('customs_broker_phone', sa.String(50)))
    if 'raw_nafeza_text' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('raw_nafeza_text', sa.Text()))
    if 'requested_data' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('requested_data', sa.JSON()))
    if 'generated_data' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('generated_data', sa.JSON()))
    if 'discrepancies_data' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('discrepancies_data', sa.JSON()))
    if 'discrepancy_override_reason' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('discrepancy_override_reason', sa.Text()))
    if 'has_discrepancies' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('has_discrepancies', sa.Boolean(), server_default='0'))
    if 'execution_days' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('execution_days', sa.Integer()))
    if 'import_file_id' not in columns:
        op.add_column('acid_registration_sessions', sa.Column('import_file_id', sa.Integer()))

    # projects
    columns = [c['name'] for c in inspector.get_columns('projects')]
    if 'additional_company_ids' not in columns:
        op.add_column('projects', sa.Column('additional_company_ids', sa.String(250)))

    # banking_document_sessions
    columns = [c['name'] for c in inspector.get_columns('banking_document_sessions')]
    if 'request_date' not in columns:
        op.add_column('banking_document_sessions', sa.Column('request_date', sa.Date()))
    if 'received_date' not in columns:
        op.add_column('banking_document_sessions', sa.Column('received_date', sa.Date()))
    if 'execution_days' not in columns:
        op.add_column('banking_document_sessions', sa.Column('execution_days', sa.Integer(), server_default='0'))
    if 'import_file_id' not in columns:
        op.add_column('banking_document_sessions', sa.Column('import_file_id', sa.Integer()))

    # import_files
    columns = [c['name'] for c in inspector.get_columns('import_files')]
    if 'form4_request_date' not in columns:
        op.add_column('import_files', sa.Column('form4_request_date', sa.Date()))
    if 'form4_received_date' not in columns:
        op.add_column('import_files', sa.Column('form4_received_date', sa.Date()))
    if 'form4_execution_days' not in columns:
        op.add_column('import_files', sa.Column('form4_execution_days', sa.Integer()))
    if 'closure_reason' not in columns:
        op.add_column('import_files', sa.Column('closure_reason', sa.Text()))
    if 'closed_at_phase' not in columns:
        op.add_column('import_files', sa.Column('closed_at_phase', sa.String(100)))
    if 'acid_number' not in columns:
        op.add_column('import_files', sa.Column('acid_number', sa.String(50)))
    if 'acid_issue_date' not in columns:
        op.add_column('import_files', sa.Column('acid_issue_date', sa.Date()))
    if 'acid_expiry_date' not in columns:
        op.add_column('import_files', sa.Column('acid_expiry_date', sa.Date()))
    if 'is_customs_released' not in columns:
        op.add_column('import_files', sa.Column('is_customs_released', sa.Boolean(), server_default='0'))
    if 'customs_released_at' not in columns:
        op.add_column('import_files', sa.Column('customs_released_at', sa.DateTime()))
    if 'acid_request_date' not in columns:
        op.add_column('import_files', sa.Column('acid_request_date', sa.Date()))
    if 'acid_execution_days' not in columns:
        op.add_column('import_files', sa.Column('acid_execution_days', sa.Integer()))

    # customs_tariffs
    columns = [c['name'] for c in inspector.get_columns('customs_tariffs')]
    if 'prior_approval_note' not in columns:
        op.add_column('customs_tariffs', sa.Column('prior_approval_note', sa.Text()))
    if 'source_url' not in columns:
        op.add_column('customs_tariffs', sa.Column('source_url', sa.String(500)))
    if 'last_verified_date' not in columns:
        op.add_column('customs_tariffs', sa.Column('last_verified_date', sa.Date()))
    if 'verified_by' not in columns:
        op.add_column('customs_tariffs', sa.Column('verified_by', sa.String(100)))
    if 'confidence' not in columns:
        op.add_column('customs_tariffs', sa.Column('confidence', sa.String(50)))

    # customs_consultation_sessions
    columns = [c['name'] for c in inspector.get_columns('customs_consultation_sessions')]
    if 'total_broker_fees_egp' not in columns:
        op.add_column('customs_consultation_sessions', sa.Column('total_broker_fees_egp', sa.Float(), server_default='0.0'))
    if 'broker_price_list_id' not in columns:
        op.add_column('customs_consultation_sessions', sa.Column('broker_price_list_id', sa.Integer()))
    if 'import_file_id' not in columns:
        op.add_column('customs_consultation_sessions', sa.Column('import_file_id', sa.Integer()))

    # import_budget_approvals
    columns = [c['name'] for c in inspector.get_columns('import_budget_approvals')]
    if 'invoice_amount_foreign' not in columns:
        op.add_column('import_budget_approvals', sa.Column('invoice_amount_foreign', sa.Float(), server_default='0.0'))
    if 'invoice_currency' not in columns:
        op.add_column('import_budget_approvals', sa.Column('invoice_currency', sa.String(10), server_default='USD'))
    if 'freight_cost_foreign' not in columns:
        op.add_column('import_budget_approvals', sa.Column('freight_cost_foreign', sa.Float(), server_default='0.0'))
    if 'freight_currency' not in columns:
        op.add_column('import_budget_approvals', sa.Column('freight_currency', sa.String(10), server_default='USD'))
    if 'exchange_rate' not in columns:
        op.add_column('import_budget_approvals', sa.Column('exchange_rate', sa.Float(), server_default='50.0'))
    if 'import_file_id' not in columns:
        op.add_column('import_budget_approvals', sa.Column('import_file_id', sa.Integer()))

    # payment_request_sessions
    columns = [c['name'] for c in inspector.get_columns('payment_request_sessions')]
    if 'swift_receipt_date' not in columns:
        op.add_column('payment_request_sessions', sa.Column('swift_receipt_date', sa.Date()))
    if 'swift_transferred_amount' not in columns:
        op.add_column('payment_request_sessions', sa.Column('swift_transferred_amount', sa.Float()))
    if 'swift_transferred_currency' not in columns:
        op.add_column('payment_request_sessions', sa.Column('swift_transferred_currency', sa.String(10)))
    if 'swift_variance_amount' not in columns:
        op.add_column('payment_request_sessions', sa.Column('swift_variance_amount', sa.Float(), server_default='0.0'))
    if 'swift_variance_status' not in columns:
        op.add_column('payment_request_sessions', sa.Column('swift_variance_status', sa.String(50), server_default='Pending'))
    if 'swift_processing_days' not in columns:
        op.add_column('payment_request_sessions', sa.Column('swift_processing_days', sa.Integer()))
    if 'swift_reconciliation_notes' not in columns:
        op.add_column('payment_request_sessions', sa.Column('swift_reconciliation_notes', sa.Text()))
    if 'import_file_id' not in columns:
        op.add_column('payment_request_sessions', sa.Column('import_file_id', sa.Integer()))

    # import_requirement_assessments
    columns = [c['name'] for c in inspector.get_columns('import_requirement_assessments')]
    if 'acid_number' not in columns:
        op.add_column('import_requirement_assessments', sa.Column('acid_number', sa.String(50)))
    if 'consultation_id' not in columns:
        op.add_column('import_requirement_assessments', sa.Column('consultation_id', sa.Integer()))
    if 'consultation_code' not in columns:
        op.add_column('import_requirement_assessments', sa.Column('consultation_code', sa.String(50)))
    if 'confirmation_status' not in columns:
        op.add_column('import_requirement_assessments', sa.Column('confirmation_status', sa.String(50), server_default='Pending Confirmation'))
    if 'is_post_acid_confirmed' not in columns:
        op.add_column('import_requirement_assessments', sa.Column('is_post_acid_confirmed', sa.Boolean(), server_default='0'))
    if 'confirmed_at' not in columns:
        op.add_column('import_requirement_assessments', sa.Column('confirmed_at', sa.DateTime()))
    if 'confirmed_by' not in columns:
        op.add_column('import_requirement_assessments', sa.Column('confirmed_by', sa.String(100)))

    # purchase_orders
    columns = [c['name'] for c in inspector.get_columns('purchase_orders')]
    if 'country_of_origin' not in columns:
        op.add_column('purchase_orders', sa.Column('country_of_origin', sa.String(100)))
    if 'import_file_id' not in columns:
        op.add_column('purchase_orders', sa.Column('import_file_id', sa.Integer()))

    # po_line_items
    columns = [c['name'] for c in inspector.get_columns('po_line_items')]
    if 'country_of_origin' not in columns:
        op.add_column('po_line_items', sa.Column('country_of_origin', sa.String(100)))

    # cbm_calculations
    columns = [c['name'] for c in inspector.get_columns('cbm_calculations')]
    if 'import_file_id' not in columns:
        op.add_column('cbm_calculations', sa.Column('import_file_id', sa.Integer()))

    # shipping_evaluation_sessions
    columns = [c['name'] for c in inspector.get_columns('shipping_evaluation_sessions')]
    if 'import_file_id' not in columns:
        op.add_column('shipping_evaluation_sessions', sa.Column('import_file_id', sa.Integer()))

    # freight_rfq_requests
    columns = [c['name'] for c in inspector.get_columns('freight_rfq_requests')]
    if 'import_file_id' not in columns:
        op.add_column('freight_rfq_requests', sa.Column('import_file_id', sa.Integer()))

    # shipment_document_items
    columns = [c['name'] for c in inspector.get_columns('shipment_document_items')]
    if 'import_file_id' not in columns:
        op.add_column('shipment_document_items', sa.Column('import_file_id', sa.Integer()))

    # customs_declaration_drafts
    columns = [c['name'] for c in inspector.get_columns('customs_declaration_drafts')]
    if 'import_file_id' not in columns:
        op.add_column('customs_declaration_drafts', sa.Column('import_file_id', sa.Integer()))





def downgrade() -> None:
    """Downgrade schema."""
    pass

