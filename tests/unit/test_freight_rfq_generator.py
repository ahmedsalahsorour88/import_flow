import pytest
from datetime import date
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from database.database import Base
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.projects.model import Project
from modules.incoterms.model import Incoterm
from modules.currencies.model import Currency
from modules.import_files.model import ImportFile
from modules.purchase_orders.model import PurchaseOrder, POLineItem, PackingListItem
from modules.import_files.service import generate_freight_rfq_service


@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()

    # Seed basic master data
    comp = ImportCompany(
        company_id=1,
        importer_name="SCAS FOR CONSTRUCTION AND FINISHING",
        address="Cairo, Egypt",
        country="Egypt",
        importer_id="IMP-REG-001",
        importer_id_expiry=date(2030, 1, 1),
        vat_id="EG-VAT-123456",
        vat_id_expiry=date(2030, 1, 1),
        registration_number="REG-987654",
        registration_expiry=date(2030, 1, 1),
    )
    supp1 = Supplier(
        supplier_id=1,
        supplier_code="SUP-001",
        company_name="Suzhou Yuheng Textile Co., Ltd.",
        supplier_type="Manufacturer",
        registration_type="Commercial Registration",
        foreign_exporter_id="CN-REG-1001",
        foreign_exporter_country="China",
        foreign_exporter_country_code="CN",
        address="N0.16, Kangsheng Road, Zhitang Town, Changshu City, Jiangsu Province, China",
    )
    supp2 = Supplier(
        supplier_id=2,
        supplier_code="SUP-002",
        company_name="Shaw Industrial Estate Ltd",
        supplier_type="Manufacturer",
        registration_type="Commercial Registration",
        foreign_exporter_id="UK-REG-2002",
        foreign_exporter_country="United Kingdom",
        foreign_exporter_country_code="GB",
        address="Blackaddie Road, Sanquhar, DG4 6DB, United Kingdom",
    )
    supp3 = Supplier(
        supplier_id=3,
        supplier_code="SUP-003",
        company_name="Saudi Office Furniture Co.",
        supplier_type="Manufacturer",
        registration_type="Commercial Registration",
        foreign_exporter_id="SA-REG-3003",
        foreign_exporter_country="Saudi Arabia",
        foreign_exporter_country_code="SA",
        address="Jeddah Industrial City Phase 3, Saudi Arabia",
    )
    proj = Project(project_id=1, project_code="PRJ-001", project_name="Headquarters Fitout", project_owner="Kamal", company_id=1, supplier_id=1, incoterm_id=1)
    inco_exw = Incoterm(incoterm_id=1, incoterm_code="EXW", incoterm_name="Ex Works")
    inco_fob = Incoterm(incoterm_id=2, incoterm_code="FOB", incoterm_name="Free On Board")
    curr = Currency(currency_id=1, currency_code="USD", currency_name="US Dollar", currency_symbol="$")

    session.add_all([comp, supp1, supp2, supp3, proj, inco_exw, inco_fob, curr])
    session.commit()

    yield session
    session.close()


def test_freight_rfq_example_1_suzhou_acoustic_panels(db_session):
    """
    Test Example 1: EXW Suzhou Yuheng Textile
    Volume: 1 CTNR * 40HC + 1 CTNR * 20GP, Acoustic Panels, Dekhila port, 21 days free time
    """
    imp_file = ImportFile(
        import_file_id=1,
        import_file_code="IMP-2026-0001",
        custom_file_number="6701068101",
        company_id=1,
        company_name="SCAS FOR CONSTRUCTION AND FINISHING",
        supplier_id=1,
        supplier_name="Suzhou Yuheng Textile Co., Ltd.",
        incoterm_code="EXW",
        port_of_loading="Shanghai Port",
        port_of_discharge="El Dekheila Port (non TMT)",
        pickup_address="N0.16, Kangsheng Road, Zhitang Town, Changshu City, Jiangsu Province, China",
        cargo_ready_date=date(2026, 8, 26),
        target_free_days=21,
        service_type_preference="Direct",
        shipping_instructions_notes="Must be 21 days free time, direct service, delivery port El Dekheila not TMT Terminal.",
    )
    db_session.add(imp_file)
    db_session.commit()

    po = PurchaseOrder(
        po_id=1,
        po_number="YH20260730-6",
        import_file_id=1,
        project_id=1,
        company_id=1,
        supplier_id=1,
        incoterm_id=1,
        currency_id=1,
        total_cbm=64.86,
        total_gross_weight_kg=10511.0,
        total_net_weight_kg=9800.0,
        total_packages_count=350,
    )
    db_session.add(po)
    db_session.commit()

    line = POLineItem(po_id=1, description_en="Acoustic Panels", description_ar="ألواح صوتية", total_price=25000.0)
    db_session.add(line)
    db_session.commit()

    rfq = generate_freight_rfq_service(db_session, import_file_id=1, recipient_name="Marian")

    assert rfq["company_name"] == "SCAS FOR CONSTRUCTION AND FINISHING"
    assert "Acoustic Panels" in rfq["commodity"]
    assert "40HC" in rfq["recommended_containers"]
    assert "20GP" in rfq["recommended_containers"]
    assert rfq["total_cbm"] == 64.86
    assert rfq["gross_weight_kg"] == 10511.0
    assert "Suzhou Yuheng Textile" in rfq["pickup_address"] or "Kangsheng Road" in rfq["pickup_address"]
    assert "El Dekheila" in rfq["port_of_discharge"]
    assert rfq["target_free_days"] == 21
    assert "Dear Marian" in rfq["email_body_template"]
    assert "EXW (Ex Works)" in rfq["email_body_template"]
    assert "21 days free time" in rfq["email_body_template"]
    assert "طلب أسعار نولون شحن" in rfq["whatsapp_text_template"]
    # Subject contains File name + Supplier + Importer + Incoterm + Container Fleet
    assert "6701068101" in rfq["email_subject"]
    assert "Suzhou Yuheng Textile" in rfq["email_subject"]
    assert "SCAS FOR CONSTRUCTION AND FINISHING" in rfq["email_subject"]
    assert "EXW" in rfq["email_subject"]
    assert "40HC" in rfq["email_subject"]


def test_freight_rfq_example_2_fob_jeddah_office_chairs(db_session):
    """
    Test Example 2: FOB Jeddah Port
    Commodity: Office Chairs, POL: Jeddah, POD: El Dekheila (TMT avoided)
    """
    imp_file = ImportFile(
        import_file_id=2,
        import_file_code="IMP-2026-0002",
        custom_file_number="6701068102",
        company_id=1,
        company_name="SCAS FOR CONSTRUCTION AND FINISHING",
        supplier_id=3,
        supplier_name="Saudi Office Furniture Co.",
        incoterm_code="FOB",
        port_of_loading="Jeddah Port",
        port_of_discharge="El Dekheila Port (TMT must be avoided)",
        cargo_ready_date=date(2026, 8, 31),
        target_free_days=21,
        service_type_preference="Direct",
        shipping_instructions_notes="POL: Jeddah Port, POD: EL Dekheila (TMT must be avoided).",
    )
    db_session.add(imp_file)
    db_session.commit()

    po = PurchaseOrder(
        po_id=2,
        po_number="PO-JED-002",
        import_file_id=2,
        project_id=1,
        company_id=1,
        supplier_id=3,
        incoterm_id=2,
        currency_id=1,
        total_cbm=45.0,
        total_gross_weight_kg=6200.0,
        total_net_weight_kg=5800.0,
        total_packages_count=120,
    )
    db_session.add(po)
    db_session.commit()

    line = POLineItem(po_id=2, description_en="Office Chairs", description_ar="كراسي مكتبية", total_price=18000.0)
    db_session.add(line)
    db_session.commit()

    rfq = generate_freight_rfq_service(db_session, import_file_id=2, recipient_name="Raafat")

    assert "Dear Raafat" in rfq["email_body_template"]
    assert "Office Chairs" in rfq["commodity"]
    assert "Jeddah Port" in rfq["port_of_loading"]
    assert "El Dekheila" in rfq["port_of_discharge"]
    assert "FOB" in rfq["email_body_template"]
    assert "TMT must be avoided" in rfq["special_requirements"]


def test_freight_rfq_example_3_shaw_carpets_pallets_breakdown(db_session):
    """
    Test Example 3: EXW Shaw Industrial Estate UK (Carpet, 998 boxes, 32 pallets with dims)
    """
    imp_file = ImportFile(
        import_file_id=3,
        import_file_code="IMP-2026-0003",
        custom_file_number="6701068103",
        company_id=1,
        company_name="SCAS FOR CONSTRUCTION AND FINISHING",
        supplier_id=2,
        supplier_name="Shaw Industrial Estate Ltd",
        incoterm_code="EXW",
        port_of_loading="London Gateway",
        port_of_discharge="El Dekheila Port, Egypt (non TMT)",
        pickup_address="Shaw Industrial Estate, Blackaddie Road, Sanquhar, DG4 6DB, United Kingdom",
        cargo_ready_date=date(2026, 8, 24),
        target_free_days=21,
        service_type_preference="Direct",
    )
    db_session.add(imp_file)
    db_session.commit()

    po = PurchaseOrder(
        po_id=3,
        po_number="PO-SHAW-003",
        import_file_id=3,
        project_id=1,
        company_id=1,
        supplier_id=2,
        incoterm_id=1,
        currency_id=1,
        total_cbm=58.5,
        total_gross_weight_kg=22528.5,
        total_net_weight_kg=20890.5,
        total_packages_count=998,
    )
    db_session.add(po)
    db_session.commit()

    line = POLineItem(po_id=3, description_en="Carpet", description_ar="سجاد وموكيت", total_price=48000.0)
    db_session.add(line)

    pl1 = PackingListItem(
        po_id=3,
        hs_code="5703.20",
        item_code="CARPET-01",
        qty_pkg=31,
        package_type="pallets",
        length_cm=120.0,
        width_cm=105.0,
        height_cm=112.5,
        total_gross_weight_kg=21800.0,
    )
    pl2 = PackingListItem(
        po_id=3,
        hs_code="5703.20",
        item_code="CARPET-02",
        qty_pkg=1,
        package_type="pallet",
        length_cm=120.0,
        width_cm=105.0,
        height_cm=37.5,
        total_gross_weight_kg=728.5,
    )
    db_session.add_all([pl1, pl2])
    db_session.commit()

    rfq = generate_freight_rfq_service(db_session, import_file_id=3, recipient_name="Asma")

    assert "Dear Asma" in rfq["email_body_template"]
    assert "Carpet" in rfq["commodity"]
    assert rfq["gross_weight_kg"] == 22528.5
    assert rfq["net_weight_kg"] == 20890.5
    assert "120 x 105 x 112.5 cm" in rfq["email_body_template"]
    assert "London Gateway" in rfq["port_of_loading"]
    assert "Blackaddie Road" in rfq["pickup_address"]
    assert rfq["target_free_days"] == 21
