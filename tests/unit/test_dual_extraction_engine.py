"""
Unit tests for CargoX Dual Extraction Engine (CGX-004).
Tests:
- PackingListExtractionEngine (all 4 modes & 4 physical structures)
- CargoXDualExtractionEngine (Independent Invoice + Packing List engines)
- Cross-Matrix combinations (A, B, C, D)
- Dual ZIP Generation with folder tree (Invoice/ + PackingList/)
- Dual Customs Track Creation & Persistence
- Export Packing List Excel with custom physical structures
"""

import pytest
import io
import zipfile
from datetime import datetime
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
    DualExtractionRequest,
    DualExtractionResponse,
    DualCustomsTrackCreate,
    PalletInput,
    PalletItemInput,
    PackingListPayload,
)
from modules.cargox.dual_extraction_service import (
    PackingListExtractionEngine,
    CargoXDualExtractionEngine,
)
from modules.cargox.excel_packing_list_service import generate_packing_list_excel_bytes


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

    # 1. Company
    company = ImportCompany(
        company_id=1,
        importer_name="شركة النور للاستيراد والتصدير",
        address="10 El-Tahrir Square, Cairo",
        country="Egypt",
        importer_id="IMP-EG-12345",
        importer_id_expiry=datetime(2030, 1, 1).date(),
        vat_id="100200300",
        vat_id_expiry=datetime(2030, 1, 1).date(),
        registration_number="CR-100200",
        registration_expiry=datetime(2030, 1, 1).date(),
    )
    db.add(company)

    # 2. Supplier
    supplier = Supplier(
        supplier_id=1,
        supplier_code="SUP-001",
        company_name="Suzhou Yuheng Textile Co.,Ltd",
        supplier_type="Manufacturer",
        registration_type="Commercial Registration",
        address="Industrial Park, Suzhou, China",
        foreign_exporter_country="China",
        foreign_exporter_country_code="CN",
        foreign_exporter_id="CN-987654321",
        cargox_platform_id="CX-SUZHOU-001",
    )
    db.add(supplier)

    # 3. Import File
    import_file = ImportFile(
        import_file_id=1,
        import_file_code="IMP-2026-0004",
        acid_number="5281520261220000000",
        company_id=1,
        company_name="شركة النور للاستيراد والتصدير",
        supplier_id=1,
        supplier_name="Suzhou Yuheng Textile Co.,Ltd",
        port_of_loading="CNSHA",
        port_of_discharge="EGALY",
        incoterm_code="FOB",
        estimated_cost=25000.0,
        estimated_cost_currency="USD",
    )
    db.add(import_file)

    # 4. Multi-invoice POs
    # PO 1: Invoice INV-2026-01
    po1 = PurchaseOrder(
        po_id=1,
        po_number="PO-2026-001",
        proforma_invoice_number="INV-2026-01",
        import_file_id=1,
        project_id=1,
        company_id=1,
        supplier_id=1,
        incoterm_id=1,
        currency_id=1,
        total_amount_fob=15000.0,
        total_gross_weight_kg=700.0,
        total_net_weight_kg=600.0,
        is_active=True,
    )
    db.add(po1)
    db.flush()

    line1 = POLineItem(
        po_id=1,
        item_code="CURT-001",
        description_ar="ستائر جاكار بوليستر",
        description_en="Polyester Curtains Jacquard",
        quantity=500.0,
        unit_of_measure="PCS",
        unit_price=20.0,
        total_price=10000.0,
        gross_weight_kg=400.0,
        net_weight_kg=350.0,
        invoice_number="INV-2026-01",
    )
    line2 = POLineItem(
        po_id=1,
        item_code="CURT-002",
        description_ar="ستائر سادة بوليستر",
        description_en="Polyester Curtains Plain",
        quantity=250.0,
        unit_of_measure="PCS",
        unit_price=20.0,
        total_price=5000.0,
        gross_weight_kg=300.0,
        net_weight_kg=250.0,
        invoice_number="INV-2026-01",
    )
    db.add_all([line1, line2])

    # PO 2: Invoice INV-2026-02
    po2 = PurchaseOrder(
        po_id=2,
        po_number="PO-2026-002",
        proforma_invoice_number="INV-2026-02",
        import_file_id=1,
        project_id=1,
        company_id=1,
        supplier_id=1,
        incoterm_id=1,
        currency_id=1,
        total_amount_fob=10000.0,
        total_gross_weight_kg=500.0,
        total_net_weight_kg=450.0,
        is_active=True,
    )
    db.add(po2)
    db.flush()

    line3 = POLineItem(
        po_id=2,
        item_code="CUSH-001",
        description_ar="أغطية وسائد قطيفة",
        description_en="Cushion Velvet Covers",
        quantity=1000.0,
        unit_of_measure="PCS",
        unit_price=10.0,
        total_price=10000.0,
        gross_weight_kg=500.0,
        net_weight_kg=450.0,
        invoice_number="INV-2026-02",
    )
    db.add(line3)

    db.commit()
    return db


def test_packing_list_engine_all_consolidated_by_hs_code(test_db):
    """
    Test 1: الباكينج ليست في نمط all_consolidated و by_hs_code (تجميع كامل ببنود التعريفة).
    """
    req = DualExtractionRequest(
        invoice_mode="all_consolidated",
        packing_list_mode="all_consolidated",
        packing_list_structure="by_hs_code",
    )
    res = CargoXDualExtractionEngine.extract_dual(test_db, 1, req)

    assert isinstance(res, DualExtractionResponse)
    assert res.import_file_id == 1
    assert res.packing_list_mode == "all_consolidated"
    assert res.packing_list_structure == "by_hs_code"
    assert res.packing_list_count == 1
    assert len(res.packing_list_results) == 1

    pl = res.packing_list_results[0].payload
    assert pl.acid_number == "5281520261220000000"
    assert pl.total_gross_weight_kg > 0
    assert pl.total_net_weight_kg > 0
    assert len(pl.items) > 0
    for itm in pl.items:
        assert itm.package_ref.startswith("PKG-")
        assert itm.quantity > 0


def test_packing_list_engine_flat_structure(test_db):
    """
    Test 2: الباكينج ليست في نمط flat (كل بند في سطر مستقل).
    """
    req = DualExtractionRequest(
        invoice_mode="all_detailed",
        packing_list_mode="all_detailed",
        packing_list_structure="flat",
    )
    res = CargoXDualExtractionEngine.extract_dual(test_db, 1, req)

    assert res.packing_list_count == 1
    pl = res.packing_list_results[0].payload
    assert pl.structure == "flat"
    # 3 total line items from the two POs
    assert len(pl.items) == 3


def test_packing_list_engine_by_pallet_structure(test_db):
    """
    Test 3: الباكينج ليست المنظم بالبالتات (by_pallet مع إدخال تفاصيل البالتات).
    """
    pallets = [
        PalletInput(
            pallet_number="PLT-001",
            pallet_type="EURO",
            dimensions_cm="120x80x150",
            gross_weight_kg=600.0,
            net_weight_kg=520.0,
            items=[
                PalletItemInput(
                    hs_code="6303.92.9000",
                    description="Polyester Curtains Jacquard",
                    quantity=500.0,
                    qty_unit="PCS",
                    net_weight_kg=350.0,
                    gross_weight_kg=400.0,
                    carton_numbers="1-20",
                ),
                PalletItemInput(
                    hs_code="6303.92.9000",
                    description="Polyester Curtains Plain",
                    quantity=250.0,
                    qty_unit="PCS",
                    net_weight_kg=170.0,
                    gross_weight_kg=200.0,
                    carton_numbers="21-30",
                ),
            ],
        ),
        PalletInput(
            pallet_number="PLT-002",
            pallet_type="EURO",
            dimensions_cm="120x80x160",
            gross_weight_kg=550.0,
            net_weight_kg=480.0,
            items=[
                PalletItemInput(
                    hs_code="6304.19.1000",
                    description="Cushion Velvet Covers",
                    quantity=1000.0,
                    qty_unit="PCS",
                    net_weight_kg=450.0,
                    gross_weight_kg=500.0,
                    carton_numbers="31-50",
                ),
            ],
        ),
    ]

    req = DualExtractionRequest(
        invoice_mode="all_consolidated",
        packing_list_mode="all_consolidated",
        packing_list_structure="by_pallet",
        include_pallets=True,
        pallet_details=pallets,
    )
    res = CargoXDualExtractionEngine.extract_dual(test_db, 1, req)

    assert res.packing_list_structure == "by_pallet"
    pl = res.packing_list_results[0].payload
    assert pl.pallets is not None
    assert len(pl.pallets) == 2
    assert len(pl.items) == 3
    assert pl.items[0].pallet_number == "PLT-001"
    assert pl.items[0].carton_numbers == "1-20"
    assert pl.items[2].pallet_number == "PLT-002"


def test_cross_matrix_combinations(test_db):
    """
    Test 4: اختبار مصفوفة التوليفات المتقاطعة (Cross-Matrix):
    A: فاتورة مجمعة + باكينج مجمع
    B: فاتورة مفصلة + باكينج مجمع
    C: فاتورة مجمعة + باكينج مفصل
    D: فاتورة مفصلة + باكينج مفصل
    """
    # Combo A: Con + Con
    res_a = CargoXDualExtractionEngine.extract_dual(
        test_db, 1, DualExtractionRequest(invoice_mode="all_consolidated", packing_list_mode="all_consolidated")
    )
    assert res_a.invoice_mode == "all_consolidated"
    assert res_a.packing_list_mode == "all_consolidated"

    # Combo B: Det + Con
    res_b = CargoXDualExtractionEngine.extract_dual(
        test_db, 1, DualExtractionRequest(invoice_mode="all_detailed", packing_list_mode="all_consolidated")
    )
    assert res_b.invoice_mode == "all_detailed"
    assert res_b.packing_list_mode == "all_consolidated"
    assert res_b.invoice_total_line_items == 3
    assert len(res_b.packing_list_results[0].payload.items) > 0

    # Combo C: Con + Det
    res_c = CargoXDualExtractionEngine.extract_dual(
        test_db, 1, DualExtractionRequest(invoice_mode="all_consolidated", packing_list_mode="all_detailed")
    )
    assert res_c.invoice_mode == "all_consolidated"
    assert res_c.packing_list_mode == "all_detailed"

    # Combo D: Det + Det (Per Invoice ZIP)
    res_d = CargoXDualExtractionEngine.extract_dual(
        test_db, 1, DualExtractionRequest(invoice_mode="per_invoice_detailed", packing_list_mode="per_invoice_detailed")
    )
    assert res_d.invoice_invoices_count == 2
    assert res_d.packing_list_count == 2


def test_dual_zip_generation_api(test_db):
    """
    Test 5: اختبار توليد ZIP مزدوج عبر API والتأكد من وجود مجلدي Invoice/ و PackingList/.
    """
    app.dependency_overrides[get_db] = lambda: test_db
    client = TestClient(app)

    req_payload = {
        "invoice_mode": "per_invoice_detailed",
        "invoice_grouping": "flat",
        "packing_list_mode": "per_invoice_detailed",
        "packing_list_structure": "flat",
        "include_pallets": False,
    }

    res = client.post("/api/v1/cargox/standard-invoice/generate-dual-zip/1", json=req_payload)
    assert res.status_code == 200
    assert res.headers["content-type"] == "application/zip"

    # Inspect zip contents
    zf_buf = io.BytesIO(res.content)
    with zipfile.ZipFile(zf_buf, "r") as zf:
        names = zf.namelist()
        assert any(n.startswith("Invoice/") for n in names)
        assert any(n.startswith("PackingList/") for n in names)
        assert all(n.endswith(".xlsx") for n in names)


def test_dual_customs_track_create_and_export_excel(test_db):
    """
    Test 6: اختبار حفظ المسار الجمركي المزدوج وتصدير Excel الباكينج ليست بهياكل متعددة.
    """
    app.dependency_overrides[get_db] = lambda: test_db
    client = TestClient(app)

    create_payload = {
        "import_file_id": 1,
        "invoice_mode": "all_consolidated",
        "invoice_grouping": "by_hs_code",
        "packing_list_mode": "all_consolidated",
        "packing_list_structure": "by_hs_code",
        "include_pallets": False,
        "notes": "مسار مزدوج تجريبي",
    }

    res = client.post("/api/v1/cargox/customs-track/create-dual", json=create_payload)
    assert res.status_code == 200
    track_data = res.json()
    assert track_data["track_id"] > 0
    assert track_data["packing_list_mode"] == "all_consolidated"
    assert track_data["packing_list_structure"] == "by_hs_code"
    assert track_data["customs_packages_count"] > 0

    track_id = track_data["track_id"]

    # Export Packing list Excel with default structure
    res_pl = client.get(f"/api/v1/cargox/customs-track/{track_id}/export-packing-list-excel")
    assert res_pl.status_code == 200
    assert len(res_pl.content) > 1000
    assert res_pl.content[:2] == b"PK"

    # Export Packing list Excel with by_pallet structure query param
    res_pl_pallet = client.get(f"/api/v1/cargox/customs-track/{track_id}/export-packing-list-excel?structure=by_pallet")
    assert res_pl_pallet.status_code == 200
    assert len(res_pl_pallet.content) > 1000
