"""
Unit tests for duplicate prevention & validation in ACID and Form 4 workflows.
Rule: Cannot create a duplicate active session/document for an import file that already has one saved in the registry.
Directs user to edit the existing session instead.
"""

import pytest
from datetime import date
from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.import_files.model import ImportFile
from modules.import_documentation.model import AcidRegistrationSession, BankingDocumentSession
from modules.import_documentation.schemas import AcidRegistrationCreate, BankingDocumentCreate
from modules.import_documentation.service import (
    create_acid_session_service,
    create_banking_document_service,
)
from modules.import_documentation.validators import (
    validate_no_duplicate_acid_session,
    validate_no_duplicate_form4_session,
)


@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()

    # Create dummy import file
    imp = ImportFile(
        import_file_id=1,
        import_file_code="IMP-2026-0001",
        custom_file_number="SHIP-001",
        company_name="Al-Amal Import",
        supplier_name="Global Tech Ltd",
        po_number="PO-2026-001",
        estimated_cost=50000.0,
        current_stage="Customs Clearance",
        is_active=True,
    )
    session.add(imp)
    session.commit()

    yield session
    session.close()


def test_duplicate_acid_session_prevention(db_session):
    """
    Ensures that creating a second active ACID registration session for the same import_file_id raises HTTP 400.
    """
    # 1. Create first ACID session
    schema1 = AcidRegistrationCreate(
        import_file_id=1,
        importer_name="Al-Amal Import",
        importer_tax_id="123456789",
        exporter_name="Global Tech Ltd",
        exporter_reg_id="VAT-998877",
        exporter_country="Germany",
        proforma_invoice_no="PI-2026-001",
        pol_name="Hamburg Port",
        pod_name="Alexandria Port",
        acid_number="PENDING",
        requested_date=date(2026, 8, 1),
    )
    res1 = create_acid_session_service(db_session, schema1)
    assert res1.acid_id is not None
    assert res1.acid_code is not None

    # 2. Attempt to create second ACID session for the same import_file_id
    schema2 = AcidRegistrationCreate(
        import_file_id=1,
        importer_name="Al-Amal Import",
        importer_tax_id="123456789",
        exporter_name="Global Tech Ltd",
        exporter_reg_id="VAT-998877",
        exporter_country="Germany",
        proforma_invoice_no="PI-2026-002",
        pol_name="Hamburg Port",
        pod_name="Alexandria Port",
        acid_number="PENDING",
        requested_date=date(2026, 8, 2),
    )
    with pytest.raises(HTTPException) as exc_info:
        create_acid_session_service(db_session, schema2)

    assert exc_info.value.status_code == 400
    assert "لا يمكن حفظ طلب ACID جديد" in exc_info.value.detail
    assert "سجل الطلبات والإصدار للتعديل" in exc_info.value.detail


def test_duplicate_form4_session_prevention(db_session):
    """
    Ensures that creating a second active Form 4 document for the same import_file_id raises HTTP 400.
    """
    # 1. Create first Form 4 document
    doc1 = BankingDocumentCreate(
        import_file_id=1,
        doc_type="Form 4",
        bank_name="National Bank of Egypt (NBE)",
        amount=50000.0,
        currency_code="USD",
        request_date=date(2026, 8, 1),
        doc_reference_number="PENDING",
    )
    res1 = create_banking_document_service(db_session, doc1)
    assert res1.bank_doc_id is not None

    # 2. Attempt to create second Form 4 document for the same import_file_id
    doc2 = BankingDocumentCreate(
        import_file_id=1,
        doc_type="Form 4",
        bank_name="Banque Misr",
        amount=50000.0,
        currency_code="USD",
        request_date=date(2026, 8, 2),
        doc_reference_number="PENDING",
    )
    with pytest.raises(HTTPException) as exc_info:
        create_banking_document_service(db_session, doc2)

    assert exc_info.value.status_code == 400
    assert "لا يمكن حفظ طلب نموذج 4 جديد" in exc_info.value.detail
    assert "سجل النماذج للتعديل" in exc_info.value.detail
