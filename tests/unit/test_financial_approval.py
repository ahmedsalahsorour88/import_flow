"""
Unit Tests for Phase 2 Financial & Management Approval Module (BP-012 & BP-013)
"""

import pytest
from datetime import date
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.external_service_providers.model import ExternalServiceProvider
from modules.transport_locations.model import TransportLocation
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.projects.model import Project
from modules.incoterms.model import Incoterm
from modules.currencies.model import Currency
from modules.customs_tariff.model import CustomsTariff
from modules.purchase_orders.model import PurchaseOrder
from modules.import_files.model import ImportFile
from modules.shipping_scenarios.model import ShippingEvaluationSession
from modules.customs_consultation.model import CustomsConsultationSession
from modules.financial_approval.model import PaymentRequestSession, ImportBudgetApproval
from modules.financial_approval.schemas import (
    PaymentRequestCreate,
    PaymentRequestUpdate,
    ImportBudgetCreate,
    ImportBudgetUpdate,
)
import modules.financial_approval.service as service
import modules.financial_approval.repository as repo
from fastapi import HTTPException


@pytest.fixture
def db_session():
    """Creates in-memory SQLite DB fixture."""
    engine = create_engine("sqlite:///:memory:", echo=False)
    Base.metadata.create_all(engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


class TestFinancialApprovalBackend:
    def test_create_payment_request_service(self, db_session):
        payload = PaymentRequestCreate(
            title="Advance Payment for Equipment",
            supplier_name="Shanghai Industrial Co.",
            payment_type="Advance Payment",
            requested_amount=15000.0,
            currency_code="USD",
            exchange_rate=50.0,
            due_date=date(2026, 9, 1),
            bank_name="Bank of China",
            swift_code="BKCHCN2S",
            iban_account_no="CN123456789",
        )
        item = service.create_payment_request_service(db_session, payload)

        assert item.payment_id is not None
        assert item.payment_code.startswith("PAY-2026-")
        assert item.requested_amount == 15000.0
        assert item.requested_amount_egp == 750000.0
        assert item.status == "Draft"

    def test_negative_requested_amount_raises_error(self, db_session):
        from pydantic import ValidationError

        with pytest.raises((ValidationError, HTTPException)):
            PaymentRequestCreate(
                title="Invalid Payment Amount",
                supplier_name="Test Supplier",
                requested_amount=-500.0,
                due_date=date(2026, 9, 1),
            )

    def test_approve_and_pay_payment_request(self, db_session):
        payload = PaymentRequestCreate(
            title="Final Settlement",
            supplier_name="Germany Heavy Duty Machinery GMBH",
            payment_type="Final Settlement",
            requested_amount=10000.0,
            due_date=date(2026, 9, 15),
        )
        created = service.create_payment_request_service(db_session, payload)

        # Approve
        approved = service.approve_payment_request_service(db_session, created.payment_id)
        assert approved.status == "Approved"

        # Pay with SWIFT copy
        paid = service.execute_payment_service(
            db_session, created.payment_id, swift_reference_no="SWIFT-998877"
        )
        assert paid.status == "Paid"
        assert paid.swift_reference_no == "SWIFT-998877"

    def test_create_and_approve_import_budget(self, db_session):
        payload = ImportBudgetCreate(
            title="Total Import Budget for Textile Machines Project",
            invoice_amount_egp=3000000.0,
            freight_cost_egp=200000.0,
            customs_duties_egp=800000.0,
            clearance_inland_egp=50000.0,
        )
        budget = service.create_import_budget_service(db_session, payload)

        assert budget.budget_id is not None
        assert budget.budget_code.startswith("BGT-2026-")
        assert budget.total_budget_egp == 4050000.0
        assert budget.budget_status == "Pending Review"

        approved_budget = service.approve_import_budget_service(
            db_session, budget.budget_id, approved_by="CFO"
        )
        assert approved_budget.budget_status == "Budget Approved"
        assert approved_budget.approved_by == "CFO"
        assert approved_budget.approved_date == date.today()

    def test_soft_delete_and_restore_payment_request(self, db_session):
        payload = PaymentRequestCreate(
            title="Draft Payment to be deleted",
            supplier_name="Test Supplier",
            requested_amount=1000.0,
            due_date=date(2026, 9, 1),
        )
        created = service.create_payment_request_service(db_session, payload)
        payment_id = created.payment_id

        # Delete
        success = repo.soft_delete_payment_request(db_session, payment_id)
        assert success is True
        assert repo.get_payment_request_by_id(db_session, payment_id) is None

        # Restore
        restore_success = repo.restore_payment_request(db_session, payment_id)
        assert restore_success is True
        restored = repo.get_payment_request_by_id(db_session, payment_id)
        assert restored is not None
        assert restored.is_active is True

    def test_duplicate_payment_request_prevention(self, db_session):
        from modules.import_companies.model import ImportCompany
        from modules.suppliers.model import Supplier
        from modules.import_files.model import ImportFile

        comp = ImportCompany(
            importer_name="Egyptian Import Co",
            address="Cairo, Egypt",
            country="Egypt",
            importer_id="IMP-ID-001",
            importer_id_expiry=date(2030, 1, 1),
            vat_id="VAT-001",
            vat_id_expiry=date(2030, 1, 1),
            registration_number="CR-001",
            registration_expiry=date(2030, 1, 1),
        )
        db_session.add(comp)
        db_session.commit()
        db_session.refresh(comp)

        sup = Supplier(
            supplier_code="SUP-TEST-001",
            company_name="Shanghai Super Machinery Ltd",
            supplier_type="Manufacturer",
            registration_type="Factory",
            foreign_exporter_id="EXP-CN-001",
            foreign_exporter_country="China",
            foreign_exporter_country_code="CN",
            address="Shanghai, China",
        )
        db_session.add(sup)
        db_session.commit()
        db_session.refresh(sup)

        imp = ImportFile(
            import_file_code="IMP-2026-099",
            custom_file_number="FILE-099",
            company_id=comp.company_id,
            company_name=comp.importer_name,
            supplier_id=sup.supplier_id,
            supplier_name=sup.company_name,
        )
        db_session.add(imp)
        db_session.commit()
        db_session.refresh(imp)

        payload1 = PaymentRequestCreate(
            title="First Payment Request",
            import_file_id=imp.import_file_id,
            supplier_name="Shanghai Super Machinery Ltd",
            requested_amount=5000.0,
            due_date=date(2026, 9, 1),
        )
        service.create_payment_request_service(db_session, payload1)

        payload2 = PaymentRequestCreate(
            title="Duplicate Payment Request",
            import_file_id=imp.import_file_id,
            supplier_name="Shanghai Super Machinery Ltd",
            requested_amount=7000.0,
            due_date=date(2026, 9, 1),
        )
        with pytest.raises(HTTPException) as exc_info:
            service.create_payment_request_service(db_session, payload2)
        assert exc_info.value.status_code == 400
        assert "يوجد بالفعل طلب سداد مالي قيد الإجراء" in exc_info.value.detail

    def test_duplicate_budget_approval_prevention(self, db_session):
        from modules.import_companies.model import ImportCompany
        from modules.import_files.model import ImportFile

        comp = ImportCompany(
            importer_name="Nile Trading Co",
            address="Alexandria, Egypt",
            country="Egypt",
            importer_id="IMP-ID-002",
            importer_id_expiry=date(2030, 1, 1),
            vat_id="VAT-002",
            vat_id_expiry=date(2030, 1, 1),
            registration_number="CR-002",
            registration_expiry=date(2030, 1, 1),
        )
        db_session.add(comp)
        db_session.commit()
        db_session.refresh(comp)

        imp = ImportFile(
            import_file_code="IMP-2026-088",
            custom_file_number="FILE-088",
            company_id=comp.company_id,
            company_name=comp.importer_name,
            supplier_name="Generic Supplier",
        )
        db_session.add(imp)
        db_session.commit()
        db_session.refresh(imp)

        bgt1 = ImportBudgetCreate(
            title="First Budget Approval",
            import_file_id=imp.import_file_id,
            invoice_amount_egp=100000.0,
        )
        service.create_import_budget_service(db_session, bgt1)

        bgt2 = ImportBudgetCreate(
            title="Duplicate Budget Approval",
            import_file_id=imp.import_file_id,
            invoice_amount_egp=200000.0,
        )
        with pytest.raises(HTTPException) as exc_info:
            service.create_import_budget_service(db_session, bgt2)
        assert exc_info.value.status_code == 400
        assert "يوجد بالفعل اعتماد ميزانية محفوظ" in exc_info.value.detail

    def test_budget_prefill_service_aggregation(self, db_session):
        from modules.import_companies.model import ImportCompany
        from modules.import_files.model import ImportFile
        from modules.purchase_orders.model import PurchaseOrder
        from modules.suppliers.model import Supplier

        comp = ImportCompany(
            importer_name="General Agencies Co",
            address="Giza, Egypt",
            country="Egypt",
            importer_id="IMP-ID-003",
            importer_id_expiry=date(2030, 1, 1),
            vat_id="VAT-003",
            vat_id_expiry=date(2030, 1, 1),
            registration_number="CR-003",
            registration_expiry=date(2030, 1, 1),
        )
        db_session.add(comp)
        db_session.commit()
        db_session.refresh(comp)

        sup = Supplier(
            supplier_code="SUP-TEST-003",
            company_name="Shanghai Super Machinery Ltd",
            supplier_type="Manufacturer",
            registration_type="Factory",
            foreign_exporter_id="EXP-CN-003",
            foreign_exporter_country="China",
            foreign_exporter_country_code="CN",
            address="Shanghai, China",
            bank_name="Industrial and Commercial Bank of China",
            swift_code="ICBKCNBJ",
            account_number="6222000011112222",
            iban="CN99ICBK6222000011112222",
        )
        db_session.add(sup)
        db_session.commit()
        db_session.refresh(sup)

        imp = ImportFile(
            import_file_code="IMP-2026-777",
            custom_file_number="FILE-777",
            incoterm_code="FOB",
            supplier_id=sup.supplier_id,
            supplier_name=sup.company_name,
            company_id=comp.company_id,
            company_name=comp.importer_name,
        )
        db_session.add(imp)
        db_session.commit()
        db_session.refresh(imp)

        inc = Incoterm(incoterm_code="FOB", incoterm_name="Free on Board")
        curr = Currency(currency_code="USD", currency_name="US Dollar", currency_symbol="$")
        db_session.add_all([inc, curr])
        db_session.commit()
        db_session.refresh(inc)
        db_session.refresh(curr)

        prj = Project(
            project_code="PRJ-001",
            project_name="Factory Project",
            project_owner="Project Manager",
            company_id=comp.company_id,
            supplier_id=sup.supplier_id,
            incoterm_id=inc.incoterm_id,
        )
        db_session.add(prj)
        db_session.commit()
        db_session.refresh(prj)

        po1 = PurchaseOrder(
            po_number="PO-2026-777-1",
            import_file_id=imp.import_file_id,
            company_id=comp.company_id,
            supplier_id=sup.supplier_id,
            project_id=prj.project_id,
            incoterm_id=inc.incoterm_id,
            currency_id=curr.currency_id,
            payment_terms="Advance 30%",
            total_amount_fob=20000.0,
        )
        po2 = PurchaseOrder(
            po_number="PO-2026-777-2",
            import_file_id=imp.import_file_id,
            company_id=comp.company_id,
            supplier_id=sup.supplier_id,
            project_id=prj.project_id,
            incoterm_id=inc.incoterm_id,
            currency_id=curr.currency_id,
            payment_terms="CAD 70%",
            total_amount_fob=30000.0,
        )
        db_session.add_all([po1, po2])
        db_session.commit()

        prefill = service.get_budget_prefill_service(db_session, imp.import_file_id)

        assert prefill.import_file_id == imp.import_file_id
        assert prefill.total_invoice_amount == 50000.0
        assert prefill.total_invoice_amount_egp == 2500000.0
        assert prefill.bank_name == "Industrial and Commercial Bank of China"
        assert prefill.swift_code == "ICBKCNBJ"
        assert "متعدد" in prefill.payment_terms_summary
        assert len(prefill.linked_pos) == 2

    def test_swift_reconciliation_matched_and_syncs_import_file(self, db_session):
        from modules.import_companies.model import ImportCompany
        from modules.import_files.model import ImportFile
        from modules.suppliers.model import Supplier
        from modules.financial_approval.schemas import SwiftReconciliationRequest

        comp = ImportCompany(
            importer_name="Swift Test Importer",
            address="Cairo, Egypt",
            country="Egypt",
            importer_id="IMP-SWIFT-01",
            importer_id_expiry=date(2030, 1, 1),
            vat_id="VAT-SWIFT-01",
            vat_id_expiry=date(2030, 1, 1),
            registration_number="CR-SWIFT-01",
            registration_expiry=date(2030, 1, 1),
        )
        sup = Supplier(
            supplier_code="SUP-SWIFT-01",
            company_name="Global Steel Exporter",
            supplier_type="Exporter",
            registration_type="Factory",
            foreign_exporter_id="EXP-GS-01",
            foreign_exporter_country="Germany",
            foreign_exporter_country_code="DE",
            address="Hamburg, Germany",
        )
        db_session.add_all([comp, sup])
        db_session.commit()
        db_session.refresh(comp)
        db_session.refresh(sup)

        imp = ImportFile(
            import_file_code="IMP-2026-SWIFT-01",
            custom_file_number="FILE-SWIFT-01",
            company_id=comp.company_id,
            company_name=comp.importer_name,
            supplier_id=sup.supplier_id,
            supplier_name=sup.company_name,
        )
        db_session.add(imp)
        db_session.commit()
        db_session.refresh(imp)

        pay = PaymentRequestCreate(
            title="Advance 30% Payment for Steel",
            import_file_id=imp.import_file_id,
            supplier_name="Global Steel Exporter",
            requested_amount=15000.0,
            currency_code="USD",
            due_date=date(2026, 8, 20),
            request_date=date(2026, 8, 10),
        )
        created_pay = service.create_payment_request_service(db_session, pay)

        # Reconcile SWIFT received on 2026-08-14 (4 days later), exactly 15000.0 USD
        swift_payload = SwiftReconciliationRequest(
            swift_reference_no="SWIFT-MT103-99887766",
            swift_receipt_date=date(2026, 8, 14),
            swift_transferred_amount=15000.0,
            swift_transferred_currency="USD",
            swift_reconciliation_notes="Full payment executed seamlessly by NBE Bank",
        )
        reconciled = service.reconcile_swift_service(db_session, created_pay.payment_id, swift_payload)

        assert reconciled.status == "Paid"
        assert reconciled.swift_reference_no == "SWIFT-MT103-99887766"
        assert reconciled.swift_processing_days == 4
        assert reconciled.swift_variance_amount == 0.0
        assert reconciled.swift_variance_status == "Matched"

        # Verify automatic update of import_files.swift_no
        db_session.refresh(imp)
        assert imp.swift_no == "SWIFT-MT103-99887766"

    def test_swift_reconciliation_deficit_and_surplus(self, db_session):
        from modules.financial_approval.schemas import SwiftReconciliationRequest

        pay = PaymentRequestCreate(
            title="Final Payment Test",
            supplier_name="Tech Parts Co",
            requested_amount=10000.0,
            currency_code="USD",
            due_date=date(2026, 8, 25),
            request_date=date(2026, 8, 10),
        )
        created_pay = service.create_payment_request_service(db_session, pay)

        # Deficit test (e.g. 9950 USD due to bank fee deduction)
        swift_deficit = SwiftReconciliationRequest(
            swift_reference_no="SWIFT-DEFICIT-01",
            swift_receipt_date=date(2026, 8, 12),
            swift_transferred_amount=9950.0,
            swift_transferred_currency="USD",
            swift_reconciliation_notes="50 USD intermediary bank fee deducted",
        )
        res_deficit = service.reconcile_swift_service(db_session, created_pay.payment_id, swift_deficit)
        assert res_deficit.swift_variance_amount == -50.0
        assert res_deficit.swift_variance_status == "Deficit"
        assert res_deficit.swift_processing_days == 2

    def test_multi_payment_requests_for_same_file_different_types(self, db_session):
        from modules.import_files.model import ImportFile

        imp = ImportFile(
            import_file_code="IMP-2026-MULTI-01",
            custom_file_number="FILE-MULTI-01",
            company_name="Test Company",
            supplier_name="Global Supplier A",
        )
        db_session.add(imp)
        db_session.commit()
        db_session.refresh(imp)

        # 1. Advance Payment
        pay1 = PaymentRequestCreate(
            title="30% Advance Payment",
            import_file_id=imp.import_file_id,
            supplier_name="Global Supplier A",
            payment_type="Advance Payment",
            requested_amount=3000.0,
            due_date=date(2026, 9, 1),
        )
        created1 = service.create_payment_request_service(db_session, pay1)
        assert created1.payment_id is not None

        # 2. Final Settlement for same file should succeed because it's a different payment_type
        pay2 = PaymentRequestCreate(
            title="70% Final Settlement Against B/L",
            import_file_id=imp.import_file_id,
            supplier_name="Global Supplier A",
            payment_type="Against B/L",
            requested_amount=7000.0,
            due_date=date(2026, 10, 1),
        )
        created2 = service.create_payment_request_service(db_session, pay2)
        assert created2.payment_id is not None
        assert created2.payment_id != created1.payment_id

    def test_payment_status_transition_validation(self, db_session):
        pay = PaymentRequestCreate(
            title="Status Transition Test",
            supplier_name="Transition Supplier",
            requested_amount=1000.0,
            due_date=date(2026, 9, 1),
        )
        created = service.create_payment_request_service(db_session, pay)
        assert created.status == "Draft"

        # Valid: Draft -> Pending Approval
        up1 = PaymentRequestUpdate(status="Pending Approval")
        service.update_payment_request_service(db_session, created.payment_id, up1)
        db_session.refresh(created)
        assert created.status == "Pending Approval"

        # Valid: Pending Approval -> Approved
        up2 = PaymentRequestUpdate(status="Approved")
        service.update_payment_request_service(db_session, created.payment_id, up2)
        db_session.refresh(created)
        assert created.status == "Approved"

        # Valid: Approved -> Paid
        up3 = PaymentRequestUpdate(status="Paid")
        service.update_payment_request_service(db_session, created.payment_id, up3)
        db_session.refresh(created)
        assert created.status == "Paid"

        # Invalid: Paid -> Draft (Terminal state cannot move backwards)
        up_invalid = PaymentRequestUpdate(status="Draft")
        with pytest.raises(HTTPException) as exc_info:
            service.update_payment_request_service(db_session, created.payment_id, up_invalid)
        assert exc_info.value.status_code == 400
        assert "Cannot transition payment request status" in exc_info.value.detail

    def test_smart_reconcile_swift_service_matched_status(self, db_session):
        from modules.financial_approval.schemas import SmartSwiftReconcileRequest

        pay = PaymentRequestCreate(
            title="Smart Reconcile Test",
            supplier_name="Smart Beneficiary Co",
            requested_amount=5000.0,
            currency_code="USD",
            due_date=date(2026, 9, 10),
            request_date=date(2026, 9, 1),
        )
        created = service.create_payment_request_service(db_session, pay)

        smart_req = SmartSwiftReconcileRequest(
            payment_id=created.payment_id,
            swift_reference_no="SMART-SWIFT-12345",
            swift_receipt_date=date(2026, 9, 5),
            swift_transferred_amount=5000.0,
            swift_transferred_currency="USD",
            bank_name="Test Partner Bank",
            swift_code="TPBKUS33",
            iban_account_no="US1234567890",
            auto_execute=True,
        )
        reconciled = service.smart_reconcile_swift_service(db_session, smart_req)

        assert reconciled.status == "Paid"
        assert reconciled.swift_variance_amount == 0.0
        assert reconciled.swift_variance_status == "Matched"
        assert reconciled.swift_processing_days == 4
        assert reconciled.bank_name == "Test Partner Bank"
        assert reconciled.swift_code == "TPBKUS33"

    def test_import_budget_update_and_soft_delete_restore(self, db_session):
        payload = ImportBudgetCreate(
            title="Initial Budget",
            invoice_amount_egp=1000000.0,
            freight_cost_egp=100000.0,
            customs_duties_egp=200000.0,
            clearance_inland_egp=50000.0,
        )
        budget = service.create_import_budget_service(db_session, payload)
        assert budget.total_budget_egp == 1350000.0

        # Update budget
        up_payload = ImportBudgetUpdate(
            title="Updated Budget Title",
            freight_cost_egp=150000.0,
        )
        updated = service.update_import_budget_service(db_session, budget.budget_id, up_payload)
        assert updated.title == "Updated Budget Title"
        assert updated.freight_cost_egp == 150000.0
        assert updated.total_budget_egp == 1400000.0

        # Soft Delete
        del_success = service.soft_delete_import_budget_service(db_session, budget.budget_id)
        assert del_success is True
        assert service.get_import_budget_by_id_service(db_session, budget.budget_id) is None

        # Restore
        res_success = service.restore_import_budget_service(db_session, budget.budget_id)
        assert res_success is True
        restored = service.get_import_budget_by_id_service(db_session, budget.budget_id)
        assert restored is not None
        assert restored.is_active is True
