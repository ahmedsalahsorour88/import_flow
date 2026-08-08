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
