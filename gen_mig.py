import re

def parse_update_db_schema():
    with open('update_db_schema.py', 'r') as f:
        content = f.read()

    # We will look for cursor.execute(f"ALTER TABLE {table_name} ADD COLUMN {col_name} {col_type};")
    # Actually, we can just extract the lists.
    
    # It's easier to just read the file and write the migration manually, but let's try to extract automatically.
    # Let's extract table names and columns.
    tables = {
        'external_service_providers': [
            ("tax_id", "sa.String(50)"),
            ("commercial_register", "sa.String(50)"),
            ("clearance_license_number", "sa.String(50)"),
            ("scac_code", "sa.String(20)"),
            ("tracking_url", "sa.String(300)"),
            ("swift_code", "sa.String(20)"),
            ("bank_code", "sa.String(20)"),
            ("branch_name", "sa.String(100)"),
            ("rating", "sa.Float(), server_default='5.0'"),
            ("secondary_email", "sa.String(150)"),
            ("fax", "sa.String(50)"),
            ("website", "sa.String(200)"),
        ],
        'suppliers': [
            ("secondary_email", "sa.String(150)"),
            ("mobile", "sa.String(50)"),
            ("fax", "sa.String(50)"),
            ("bank_name", "sa.String(200)"),
            ("swift_code", "sa.String(50)"),
            ("account_number", "sa.String(100)"),
            ("iban", "sa.String(100)"),
            ("has_iso", "sa.Boolean(), server_default='0'"),
            ("registered_decree_43", "sa.Boolean(), server_default='0'"),
            ("white_list_registered", "sa.Boolean(), server_default='0'"),
            ("cargox_platform_id", "sa.String(100)"),
        ],
        'acid_registration_sessions': [
            ("proforma_invoice_date", "sa.Date()"),
            ("po_number", "sa.String(100)"),
            ("po_date", "sa.Date()"),
            ("importer_address", "sa.String(300)"),
            ("exporter_reg_type", "sa.String(100), server_default='VAT Number'"),
            ("exporter_country_code", "sa.String(10)"),
            ("exporter_address", "sa.String(300)"),
            ("exporter_phone", "sa.String(50)"),
            ("cargox_id", "sa.String(100)"),
            ("invoice_date", "sa.Date()"),
            ("invoice_type", "sa.String(50), server_default='Proforma Invoice'"),
            ("invoice_attachment_name", "sa.String(255)"),
            ("customs_broker_id", "sa.Integer()"),
            ("customs_broker_name", "sa.String(200)"),
            ("customs_broker_phone", "sa.String(50)"),
            ("raw_nafeza_text", "sa.Text()"),
            ("requested_data", "sa.JSON()"),
            ("generated_data", "sa.JSON()"),
            ("discrepancies_data", "sa.JSON()"),
            ("discrepancy_override_reason", "sa.Text()"),
            ("has_discrepancies", "sa.Boolean(), server_default='0'"),
            ("execution_days", "sa.Integer()"),
        ],
        'projects': [
            ("additional_company_ids", "sa.String(250)"),
        ],
        'banking_document_sessions': [
            ("request_date", "sa.Date()"),
            ("received_date", "sa.Date()"),
            ("execution_days", "sa.Integer(), server_default='0'"),
        ],
        'import_files': [
            ("form4_request_date", "sa.Date()"),
            ("form4_received_date", "sa.Date()"),
            ("form4_execution_days", "sa.Integer()"),
            ("closure_reason", "sa.Text()"),
            ("closed_at_phase", "sa.String(100)"),
            ("acid_number", "sa.String(50)"),
            ("acid_issue_date", "sa.Date()"),
            ("acid_expiry_date", "sa.Date()"),
            ("is_customs_released", "sa.Boolean(), server_default='0'"),
            ("customs_released_at", "sa.DateTime()"),
            ("acid_request_date", "sa.Date()"),
            ("acid_execution_days", "sa.Integer()"),
        ],
        'customs_tariffs': [
            ("prior_approval_note", "sa.Text()"),
            ("source_url", "sa.String(500)"),
            ("last_verified_date", "sa.Date()"),
            ("verified_by", "sa.String(100)"),
            ("confidence", "sa.String(50)"),
        ],
        'customs_consultation_sessions': [
            ("total_broker_fees_egp", "sa.Float(), server_default='0.0'"),
            ("broker_price_list_id", "sa.Integer()"),
        ],
        'import_budget_approvals': [
            ("invoice_amount_foreign", "sa.Float(), server_default='0.0'"),
            ("invoice_currency", "sa.String(10), server_default='USD'"),
            ("freight_cost_foreign", "sa.Float(), server_default='0.0'"),
            ("freight_currency", "sa.String(10), server_default='USD'"),
            ("exchange_rate", "sa.Float(), server_default='50.0'"),
        ],
        'payment_request_sessions': [
            ("swift_receipt_date", "sa.Date()"),
            ("swift_transferred_amount", "sa.Float()"),
            ("swift_transferred_currency", "sa.String(10)"),
            ("swift_variance_amount", "sa.Float(), server_default='0.0'"),
            ("swift_variance_status", "sa.String(50), server_default='Pending'"),
            ("swift_processing_days", "sa.Integer()"),
            ("swift_reconciliation_notes", "sa.Text()"),
        ],
        'import_requirement_assessments': [
            ("acid_number", "sa.String(50)"),
            ("consultation_id", "sa.Integer()"),
            ("consultation_code", "sa.String(50)"),
            ("confirmation_status", "sa.String(50), server_default='Pending Confirmation'"),
            ("is_post_acid_confirmed", "sa.Boolean(), server_default='0'"),
            ("confirmed_at", "sa.DateTime()"),
            ("confirmed_by", "sa.String(100)"),
        ],
        'purchase_orders': [
            ("country_of_origin", "sa.String(100)"),
        ],
        'po_line_items': [
            ("country_of_origin", "sa.String(100)"),
        ]
    }

    # also import_file_id added to multiple tables
    target_tables = [
        "purchase_orders",
        "cbm_calculations",
        "shipping_evaluation_sessions",
        "freight_rfq_requests",
        "customs_consultation_sessions",
        "payment_request_sessions",
        "import_budget_approvals",
        "acid_registration_sessions",
        "banking_document_sessions",
        "shipment_document_items",
        "customs_declaration_drafts",
    ]
    for t in target_tables:
        if t not in tables:
            tables[t] = []
        tables[t].append(("import_file_id", "sa.Integer()"))

    out = ""
    for table, cols in tables.items():
        out += f"    # {table}\n"
        out += f"    columns = [c['name'] for c in inspector.get_columns('{table}')]\n"
        for col_name, col_type in cols:
            out += f"    if '{col_name}' not in columns:\n"
            out += f"        op.add_column('{table}', sa.Column('{col_name}', {col_type}))\n"
        out += "\n"

    print(out)

if __name__ == '__main__':
    parse_update_db_schema()
