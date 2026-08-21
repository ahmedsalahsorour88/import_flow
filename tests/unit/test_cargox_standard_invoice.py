"""
Unit tests for CargoX Standard Excel Commercial Invoice Generator, Parser, Comparison, and Session Upsert (BP-025 / CGX-002).
"""

import pytest
from datetime import datetime, timezone
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

from database.database import Base, get_db
from main import app
from modules.import_files.model import ImportFile
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.purchase_orders.model import PurchaseOrder, POLineItem
from modules.cargox.schemas import (
    StandardInvoicePayload,
    StandardInvoiceLineItem,
    StandardInvoiceSessionCreate,
    StandardInvoiceStatusUpdateRequest,
)
from modules.cargox.service import CargoXStandardInvoiceService
from modules.cargox.excel_invoice_service import (
    generate_standard_invoice_excel_bytes,
    parse_standard_invoice_excel_bytes,
    compare_standard_invoice_data,
)


@pytest.fixture
def test_db():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()

    # Seed Company
    company = ImportCompany(
        company_id=1,
        importer_name="الشركة المصرية للاستيراد والتوريدات",
        address="10 El-Bostan St, Cairo",
        country="Egypt",
        importer_id="IMP-001-REG",
        importer_id_expiry=datetime(2030, 1, 1).date(),
        vat_id="123456789",
        vat_id_expiry=datetime(2030, 1, 1).date(),
        registration_number="CR-987654",
        registration_expiry=datetime(2030, 1, 1).date(),
    )
    db.add(company)

    # Seed Supplier
    supplier = Supplier(
        supplier_id=1,
        supplier_code="SUP-001",
        company_name="Narbutas International UAB",
        supplier_type="Manufacturer",
        registration_type="Commercial Registration",
        foreign_exporter_id="LT300591314",
        foreign_exporter_country="Lithuania",
        foreign_exporter_country_code="LT",
        address="Ukmerges g. 308, Vilnius",
        phone="+37052100000",
        email="sales@narbutas.lt",
        website="www.narbutas.com",
    )
    db.add(supplier)

    # Seed Import File
    file = ImportFile(
        import_file_id=1,
        import_file_code="IMP-2026-009",
        company_id=1,
        company_name="Egyptian Import & Supply Co.",
        supplier_id=1,
        supplier_name="Narbutas International UAB",
        acid_number="7595528271020210010",
        estimated_cost_currency="EUR",
        incoterm_code="EXW",
        port_of_loading="Klaipeda Port",
        port_of_discharge="Alexandria Port",
        estimated_cost=5000.0,
    )
    db.add(file)

    # Seed PO & Items
    po = PurchaseOrder(
        po_id=1,
        po_number="PO-2026-001",
        import_file_id=1,
        project_id=1,
        company_id=1,
        supplier_id=1,
        incoterm_id=1,
        currency_id=1,
        total_amount_fob=5000.0,
    )
    db.add(po)
    db.flush()

    item1 = POLineItem(
        po_id=1,
        item_code="DSK-001",
        description_ar="مكتب تنفيذي",
        description_en="Executive Office Desk",
        quantity=10.0,
        unit_price=300.0,
        total_price=3000.0,
        unit_of_measure="SET",
        gross_weight_kg=250.0,
        net_weight_kg=220.0,
        country_of_origin="LT",
    )
    item2 = POLineItem(
        po_id=1,
        item_code="CHR-002",
        description_ar="كرسي مريح",
        description_en="Ergonomic Mesh Chair",
        quantity=20.0,
        unit_price=100.0,
        total_price=2000.0,
        unit_of_measure="PCE",
        gross_weight_kg=200.0,
        net_weight_kg=180.0,
        country_of_origin="LT",
    )
    db.add(item1)
    db.add(item2)
    db.commit()

    yield db
    db.close()



def test_standard_invoice_excel_generation_and_parsing(test_db):
    """Test generating .xlsx with openpyxl Named Ranges & Table and parsing it back cleanly."""
    snapshot = CargoXStandardInvoiceService.build_system_snapshot(test_db, 1)
    assert snapshot.acid_number == "7595528271020210010"
    assert snapshot.seller_tax_id == "LT300591314"
    assert snapshot.buyer_tax_id == "123456789"
    assert len(snapshot.items) == 2
    assert snapshot.subtotal == 5000.0
    assert snapshot.total_amount == 5000.0

    # Generate Excel Bytes
    excel_bytes = generate_standard_invoice_excel_bytes(snapshot)
    assert len(excel_bytes) > 1000

    # Parse Excel Bytes back
    parsed = parse_standard_invoice_excel_bytes(excel_bytes)
    assert parsed.acid_number == "7595528271020210010"
    assert parsed.seller_name == "Narbutas International UAB"
    assert parsed.buyer_tax_id == "123456789"
    assert parsed.currency_code == "EUR"
    assert parsed.incoterm == "EXW"
    assert len(parsed.items) == 2
    assert parsed.items[0].hs_code == "940310"
    assert parsed.items[0].quantity == 10.0
    assert parsed.items[1].hs_code == "940310"
    assert parsed.subtotal == 5000.0


def test_standard_invoice_comparison_perfect_and_discrepancy(test_db):
    """Test comparison matrix for matching vs modified supplier data."""
    snapshot = CargoXStandardInvoiceService.build_system_snapshot(test_db, 1)
    
    # 1. Perfect Match
    comp_res = CargoXStandardInvoiceService.compare_invoices(test_db, 1, snapshot)
    assert comp_res.has_discrepancies is False
    assert comp_res.has_critical_mismatch is False
    assert comp_res.total_discrepancies_count == 0

    # 2. Supplier Data with Discrepancies
    modified_sup = snapshot.model_copy(deep=True)
    modified_sup.acid_number = "9999999999999999999"  # Mismatch
    modified_sup.items[0].unit_price = 350.0  # Price difference
    modified_sup.items[0].total_amount = 3500.0
    modified_sup.subtotal = 5500.0
    modified_sup.total_amount = 5850.0

    comp_diff = CargoXStandardInvoiceService.compare_invoices(test_db, 1, modified_sup)
    assert comp_diff.has_discrepancies is True
    assert comp_diff.has_critical_mismatch is True
    assert comp_diff.critical_mismatches_count >= 1
    assert comp_diff.rectification_notice_en is not None
    assert "ACID Number" in comp_diff.rectification_notice_en


def test_standard_invoice_session_upsert_and_override_justification(test_db):
    """Test Anti-duplicate upsert logic and mandatory discrepancy override justification."""
    snapshot = CargoXStandardInvoiceService.build_system_snapshot(test_db, 1)

    # 1. Create Initial Session as DRAFT
    create_schema = StandardInvoiceSessionCreate(
        import_file_id=1,
        import_file_code="IMP-2026-009",
        acid_number="7595528271020210010",
        invoice_number="INV-2026-009",
        subtotal_amount=5000.0,
        total_amount=5350.0,
        line_items_count=2,
        has_discrepancies=True,
        has_critical_mismatch=False,
        status="DRAFT",
    )
    session1 = CargoXStandardInvoiceService.save_or_upsert_session(test_db, create_schema)
    assert session1.session_id is not None
    assert session1.session_code.startswith("CX-INV-")
    assert session1.status == "DRAFT"

    # 2. Try Approving with Discrepancies without Override Reason -> Should Raise 400
    create_schema.status = "APPROVED"
    create_schema.discrepancy_override_reason = ""
    with pytest.raises(Exception) as exc_info:
        CargoXStandardInvoiceService.save_or_upsert_session(test_db, create_schema)
    assert "يجب كتابة مبرر" in str(exc_info.value)

    # 3. Approve with Valid Justification -> Should Update Same Record (Anti-Duplicate)
    create_schema.discrepancy_override_reason = "تم اعتماد الفرق البسيط في السعر بموافقة الإدارة المالية."
    session2 = CargoXStandardInvoiceService.save_or_upsert_session(test_db, create_schema)
    assert session2.session_id == session1.session_id  # Same session updated!
    assert session2.session_code == session1.session_code
    assert session2.status == "APPROVED"
    assert session2.discrepancy_override_reason == "تم اعتماد الفرق البسيط في السعر بموافقة الإدارة المالية."


def test_standard_invoice_api_endpoints(test_db):
    """Test REST API endpoints for Standard Invoice Hub."""
    app.dependency_overrides[get_db] = lambda: test_db
    client = TestClient(app)

    # Test Download Excel
    res_gen = client.get("/api/v1/cargox/standard-invoice/generate/1")
    assert res_gen.status_code == 200
    assert "application/vnd.openxmlformats-officedocument" in res_gen.headers["content-type"]
    excel_bytes = res_gen.content

    # Test Upload & Parse Excel
    res_parse = client.post(
        "/api/v1/cargox/standard-invoice/parse",
        files={"file": ("test_invoice.xlsx", excel_bytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")},
    )
    assert res_parse.status_code == 200
    parsed_json = res_parse.json()
    assert parsed_json["acid_number"] == "7595528271020210010"
    assert len(parsed_json["items"]) == 2

    # Test Compare Endpoint
    res_comp = client.post(
        "/api/v1/cargox/standard-invoice/compare/1",
        json=parsed_json,
    )
    assert res_comp.status_code == 200
    comp_json = res_comp.json()
    assert comp_json["has_discrepancies"] is False

    # Test Save Session
    session_payload = {
        "import_file_id": 1,
        "import_file_code": "IMP-2026-009",
        "acid_number": "7595528271020210010",
        "invoice_number": "INV-2026-009",
        "currency_code": "EUR",
        "subtotal_amount": 5000.0,
        "total_amount": 5350.0,
        "line_items_count": 2,
        "status": "APPROVED",
        "has_discrepancies": False,
    }
    res_save = client.post("/api/v1/cargox/standard-invoice/session", json=session_payload)
    assert res_save.status_code == 200
    assert res_save.json()["status"] == "APPROVED"

    # Test Get by file
    res_by_file = client.get("/api/v1/cargox/standard-invoice/session/by-file/1")
    assert res_by_file.status_code == 200
    assert res_by_file.json()["session_code"].startswith("CX-INV-")

    app.dependency_overrides.clear()
