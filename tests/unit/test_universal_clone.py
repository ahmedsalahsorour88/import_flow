import pytest
from datetime import date
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi import HTTPException

from database.database import Base
from modules.import_files.model import ImportFile
from modules.import_files.schemas import CloneImportFileRequest
from modules.import_files.service import clone_import_file_service
from modules.customs_consultation.model import (
    BrokerPriceList,
    BrokerPriceListItem,
    CustomsConsultationSession,
    CustomsChecklistItem,
    CustomsBrokerQuoteItem,
)
from modules.customs_consultation.schemas import (
    CloneBrokerPriceListRequest,
    CloneConsultationRequest,
)
from modules.customs_consultation.service import (
    BrokerPriceListService,
    CustomsConsultationService,
)

@pytest.fixture(scope='function')
def db_session():
    engine = create_engine('sqlite:///:memory:')
    Base.metadata.create_all(engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = TestingSessionLocal()
    yield session
    session.close()


def test_clone_import_file_service(db_session):
    # 1. Create original shipment
    original = ImportFile(
        import_file_code='IMP-2026-TEST-ORIG',
        custom_file_number='6701068001',
        company_id=1,
        company_name='Egyptian Import Co',
        supplier_id=10,
        supplier_name='Global Machinery Ltd',
        broker_id=5,
        broker_name='Cairo Logistics Broker',
        port_of_loading='Shanghai Port',
        port_of_discharge='Alexandria Port',
        shipment_mode='Sea FCL',
        incoterm_code='FOB',
        invoices_data=[{'invoice_no': 'INV-001', 'amount': 15000.0, 'currency': 'USD'}],
        packing_lists_data=[{'pl_no': 'PL-001', 'total_packages': 100}],
        acid_number='9876543210123456789',
        is_customs_released=True,
        status='Closed',
    )
    db_session.add(original)
    db_session.commit()
    db_session.refresh(original)

    # 2. Clone shipment
    clone_req = CloneImportFileRequest(
        target_import_file_code='IMP-2026-TEST-CLONE',
        target_custom_file_number='6701068002',
        copy_invoices_data=True,
        copy_packing_lists=True,
        copy_attachments=False,
        notes='Cloned for testing UX-CLONE-011',
    )

    cloned = clone_import_file_service(db_session, original.import_file_id, clone_req, current_user='Tester')

    # Verify what is copied
    assert cloned.import_file_code == 'IMP-2026-TEST-CLONE'
    assert cloned.company_name == 'Egyptian Import Co'
    assert cloned.supplier_name == 'Global Machinery Ltd'
    assert cloned.port_of_loading == 'Shanghai Port'
    assert len(cloned.invoices_data) == 1
    assert cloned.invoices_data[0]['invoice_no'] == 'INV-001'

    # Verify mandatory resets
    assert cloned.status == 'Draft'
    assert cloned.acid_number is None
    assert cloned.is_customs_released is False
    assert cloned.form4_no is None
    assert cloned.po_number is None

    # Verify Traceability
    assert cloned.cloned_from_id == original.import_file_id
    assert cloned.cloned_from_code == 'IMP-2026-TEST-ORIG'
    assert cloned.created_by == 'Tester'

    # Test Duplicate code conflict
    with pytest.raises(HTTPException) as exc:
        clone_import_file_service(db_session, original.import_file_id, clone_req)
    assert exc.value.status_code == 409


def test_clone_broker_price_list(db_session):
    # Create original price list with items
    original_pl = BrokerPriceList(
        price_list_code='PL-BROKER-001',
        title='Tariff 2026 Q1',
        broker_id=5,
        broker_name='Al-Fursan Brokerage',
        port_name='Alexandria Port',
        effective_from=date(2026, 1, 1),
        version=1,
        is_active=True,
    )
    db_session.add(original_pl)
    db_session.commit()
    db_session.refresh(original_pl)

    item1 = BrokerPriceListItem(
        price_list_id=original_pl.price_list_id,
        expense_name='LCL Clearance Fee',
        category='Clearance Fees',
        unit_type='Per Invoice',
        standard_price=1200.0,
        currency='EGP',
    )
    item2 = BrokerPriceListItem(
        price_list_id=original_pl.price_list_id,
        expense_name='Import Agency Approval',
        category='Inspection & Regulatory',
        unit_type='Per Container',
        standard_price=1500.0,
        currency='EGP',
    )
    db_session.add_all([item1, item2])
    db_session.commit()

    # Clone price list
    clone_req = CloneBrokerPriceListRequest(
        new_price_list_code='PL-BROKER-002',
        new_title='Tariff 2026 Q2 (Cloned)',
        effective_from=date(2026, 4, 1),
    )

    cloned_pl = BrokerPriceListService.clone_price_list(db_session, original_pl.price_list_id, clone_req)

    assert cloned_pl.price_list_code == 'PL-BROKER-002'
    assert cloned_pl.title == 'Tariff 2026 Q2 (Cloned)'
    assert cloned_pl.version == 2
    assert cloned_pl.cloned_from_id == original_pl.price_list_id
    assert cloned_pl.cloned_from_code == 'PL-BROKER-001'
    assert len(cloned_pl.items) == 2
    assert cloned_pl.items[0].standard_price == 1200.0


def test_clone_customs_consultation(db_session):
    original_cst = CustomsConsultationSession(
        consultation_code='CST-2026-001',
        title='Customs Review for Machinery',
        broker_id=5,
        broker_name='Al-Fursan Brokerage',
        overall_status='Clearance Ready',
        estimated_duties_egp=50000.0,
        total_broker_fees_egp=6500.0,
    )
    db_session.add(original_cst)
    db_session.commit()
    db_session.refresh(original_cst)

    chk = CustomsChecklistItem(
        consultation_id=original_cst.consultation_id,
        document_type='Commercial Invoice',
        hs_code='8471.30',
        responsible_party='Supplier',
        is_blocking_shipment=True,
    )
    db_session.add(chk)
    db_session.commit()

    clone_req = CloneConsultationRequest(
        new_consultation_code='CST-2026-002',
        new_title='Cloned Review for Machine Batch 2',
        copy_checklist_items=True,
        copy_broker_quote_items=True,
    )

    cloned_cst = CustomsConsultationService.clone_consultation(db_session, original_cst.consultation_id, clone_req)

    assert cloned_cst.consultation_code == 'CST-2026-002'
    assert cloned_cst.overall_status == 'Draft'
    assert cloned_cst.cloned_from_id == original_cst.consultation_id
    assert cloned_cst.cloned_from_code == 'CST-2026-001'
    assert len(cloned_cst.checklist_items) == 1
    assert cloned_cst.checklist_items[0].document_type == 'Commercial Invoice'
