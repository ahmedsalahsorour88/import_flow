import unittest
from datetime import datetime, date
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.incoterms.model import Incoterm
from modules.projects.model import Project
from modules.currencies.model import Currency
from modules.customs_tariff.model import CustomsTariff
from modules.external_service_providers.model import ExternalServiceProvider
from modules.transport_locations.model import TransportLocation
from modules.freight_quotations.model import FreightRFQRequest
from modules.purchase_orders.model import PurchaseOrder
from modules.freight_booking.model import ShipmentBooking
from modules.import_files.model import ImportFile
from modules.financial_settlement.model import LandedCostSettlementRecord
from modules.financial_settlement.schemas import (
    FinancialSettlementCreate,
    ExpenseInvoiceSchema,
    ItemLandedCostSchema,
    FinancialSettlementUpdate,
)
from modules.financial_settlement.service import (
    create_settlement_service,
    recalculate_settlement_service,
    get_settlement_service,
    list_settlements_service,
    calculate_landed_cost_engine,
    soft_delete_settlement_service,
    restore_settlement_service,
)

class TestFinancialSettlementModule(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(self.engine)
        TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        self.db = TestingSessionLocal()

        company = ImportCompany(
            company_id=1,
            importer_name="Delta Industrial Co",
            vat_id="999-888-777",
            registration_number="12345",
            address="Cairo, Egypt",
            country="Egypt",
            importer_id="IMP-009",
            importer_id_expiry=date(2028, 1, 1),
            vat_id_expiry=date(2028, 1, 1),
            registration_expiry=date(2028, 1, 1),
        )
        self.db.add(company)
        self.db.commit()

        imp_file = ImportFile(
            import_file_code="IMP-FILE-2026-0009",
            company_id=company.company_id,
            company_name=company.importer_name,
            supplier_name="Global Heavy Equipment Ltd",
            po_number="PO-2026-900",
        )
        self.db.add(imp_file)
        self.db.commit()
        self.db.refresh(imp_file)
        self.import_file_id = imp_file.import_file_id

    def tearDown(self):
        self.db.close()

    def test_landed_cost_engine_allocation_formulas(self):
        expenses = [
            {"invoice_no": "INV-FREIGHT", "category": "Freight", "provider_name": "Maersk", "currency": "USD", "amount_fx": 1000.0, "exchange_rate": 50.0, "amount_egp": 50000.0, "allocation_rule": "Volume-Based"},
            {"invoice_no": "INV-CUSTOMS", "category": "Customs Duty", "provider_name": "Customs Authority", "currency": "EGP", "amount_fx": 20000.0, "exchange_rate": 1.0, "amount_egp": 20000.0, "allocation_rule": "Value-Based"},
        ]

        items = [
            {"item_code": "ITM-01", "item_name": "Pumps", "qty": 100, "gross_weight_kg": 1000.0, "cbm": 10.0, "fob_unit_egp": 1000.0},
            {"item_code": "ITM-02", "item_name": "Valves", "qty": 100, "gross_weight_kg": 500.0, "cbm": 30.0, "fob_unit_egp": 1000.0},
        ]

        res = calculate_landed_cost_engine(expenses, items)

        self.assertEqual(res["total_fob_egp"], 200000.0)
        self.assertEqual(res["total_expenses_egp"], 70000.0)
        self.assertEqual(res["total_landed_cost_egp"], 270000.0)
        self.assertAlmostEqual(res["average_markup_factor"], 1.35, places=2)

        # Check volume-based freight allocation (CBM ratio: 10m³ vs 30m³ -> 1:3 ratio)
        itm1 = res["item_landed_costs"][0]
        itm2 = res["item_landed_costs"][1]
        self.assertEqual(itm1["allocated_freight_egp"], 12500.0) # 25% of 50000
        self.assertEqual(itm2["allocated_freight_egp"], 37500.0) # 75% of 50000

        # Check value-based customs allocation (Equal FOB total -> 50% each)
        self.assertEqual(itm1["allocated_customs_egp"], 10000.0)
        self.assertEqual(itm2["allocated_customs_egp"], 10000.0)

    def test_create_and_recalculate_settlement_service(self):
        schema = FinancialSettlementCreate(
            import_file_id=self.import_file_id,
            expense_invoices=[
                ExpenseInvoiceSchema(
                    invoice_no="INV-TRANS-01",
                    category="Local Transport",
                    provider_name="Cairo Logistics",
                    currency="EGP",
                    amount_fx=10000.0,
                    exchange_rate=1.0,
                    amount_egp=10000.0,
                    allocation_rule="Weight-Based",
                )
            ],
            item_landed_costs=[
                ItemLandedCostSchema(
                    item_code="ITM-99",
                    item_name="Generator",
                    qty=1,
                    gross_weight_kg=2000.0,
                    cbm=5.0,
                    fob_unit_egp=100000.0,
                    fob_total_egp=100000.0,
                )
            ]
        )

        record = create_settlement_service(self.db, schema)
        self.assertIsNotNone(record.settlement_id)
        self.assertTrue(record.settlement_code.startswith("LCS-"))
        self.assertEqual(record.total_fob_egp, 100000.0)
        self.assertEqual(record.total_expenses_egp, 10000.0)
        self.assertEqual(record.total_landed_cost_egp, 110000.0)
        self.assertEqual(record.average_markup_factor, 1.1)

    def test_soft_delete_and_restore(self):
        schema = FinancialSettlementCreate(import_file_id=self.import_file_id)
        record = create_settlement_service(self.db, schema)
        s_id = record.settlement_id

        # Delete
        success = soft_delete_settlement_service(self.db, s_id)
        self.assertTrue(success)

        # Restore
        restored = restore_settlement_service(self.db, s_id)
        self.assertIsNotNone(restored)
        self.assertEqual(restored.settlement_id, s_id)
        self.assertTrue(restored.is_active)

if __name__ == "__main__":
    unittest.main()
