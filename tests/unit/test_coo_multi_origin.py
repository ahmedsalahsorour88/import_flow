import pytest
import main
from database.database import SessionLocal
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.projects.model import Project
from modules.incoterms.model import Incoterm
from modules.currencies.model import Currency
from modules.import_files.model import ImportFile
from modules.purchase_orders.model import PurchaseOrder, POLineItem
from modules.customs_tariff.model import CustomsTariff
from modules.import_documentation.service import (
    generate_coo_draft_template_service,
    generate_inspection_draft_template_service,
    _extract_multi_origins_and_hs_codes,
)


@pytest.fixture
def db_session():
    session = SessionLocal()
    yield session
    session.close()


def test_multi_origin_and_multi_hs_code_extraction(db_session):
    # Setup Master Data
    company = db_session.query(ImportCompany).first()
    if not company:
        company = ImportCompany(importer_name="Archi Brands Egypt", tax_id="100200300", is_active=True)
        db_session.add(company)
        db_session.commit()

    supplier = db_session.query(Supplier).first()
    if not supplier:
        supplier = Supplier(company_name="Multi Global Ltd", foreign_exporter_country="Lithuania", is_active=True)
        db_session.add(supplier)
        db_session.commit()

    project = db_session.query(Project).first()
    if not project:
        project = Project(project_name="Central Project", is_active=True)
        db_session.add(project)
        db_session.commit()

    incoterm = db_session.query(Incoterm).first()
    if not incoterm:
        incoterm = Incoterm(incoterm_code="FOB", incoterm_name="Free on Board", is_active=True)
        db_session.add(incoterm)
        db_session.commit()

    currency = db_session.query(Currency).first()
    if not currency:
        currency = Currency(currency_code="EUR", currency_name="Euro", exchange_rate=53.5, is_active=True)
        db_session.add(currency)
        db_session.commit()

    tariff1 = db_session.query(CustomsTariff).filter(CustomsTariff.hs_code == "940130").first()
    if not tariff1:
        tariff1 = CustomsTariff(hs_code="940130", hs_description="كراسي متحركة", is_active=True)
        db_session.add(tariff1)
        db_session.commit()

    tariff2 = db_session.query(CustomsTariff).filter(CustomsTariff.hs_code == "940310").first()
    if not tariff2:
        tariff2 = CustomsTariff(hs_code="940310", hs_description="أثاث مكاتب", is_active=True)
        db_session.add(tariff2)
        db_session.commit()

    imp_file = ImportFile(
        import_file_code="IMP-2026-MULTI-TEST",
        company_id=company.company_id,
        company_name=company.importer_name,
        supplier_id=supplier.supplier_id,
        supplier_name=supplier.company_name,
        acid_number="7595528271020210099",
        is_active=True,
    )
    db_session.add(imp_file)
    db_session.commit()

    # Link Purchase Order with multiple origins and distinct HS codes across line items
    po = PurchaseOrder(
        po_number="PO-MULTI-001-TEST",
        import_file_id=imp_file.import_file_id,
        project_id=project.project_id,
        company_id=company.company_id,
        supplier_id=supplier.supplier_id,
        incoterm_id=incoterm.incoterm_id,
        currency_id=currency.currency_id,
        country_of_origin="Germany, Poland",
        is_active=True,
    )
    db_session.add(po)
    db_session.commit()

    item1 = POLineItem(
        po_id=po.po_id,
        description_en="Acoustic Chairs",
        description_ar="كراسي",
        country_of_origin="Lithuania",
        tariff_id=tariff1.tariff_id,
        quantity=50,
        unit_price=100.0,
        total_price=5000.0,
    )
    item2 = POLineItem(
        po_id=po.po_id,
        description_en="Office Desks",
        description_ar="مكاتب",
        country_of_origin="Germany",
        tariff_id=tariff2.tariff_id,
        quantity=20,
        unit_price=200.0,
        total_price=4000.0,
    )
    db_session.add_all([item1, item2])
    db_session.commit()

    # Test extraction helper directly
    extracted = _extract_multi_origins_and_hs_codes(db_session, imp_file.import_file_id, supplier)
    assert "Germany" in extracted["origins_list"]
    assert "Lithuania" in extracted["origins_list"]
    assert "Poland" in extracted["origins_list"]
    assert "940130" in extracted["hs_codes_list"]
    assert "940310" in extracted["hs_codes_list"]
    assert len(extracted["items_summary"]) >= 2

    # Test COO generation service
    coo_res = generate_coo_draft_template_service(db_session, imp_file.import_file_id, "EUR.1")
    assert "Germany" in coo_res.template_data["country_of_origin"]
    assert "940130" in coo_res.template_data["box_8_description_packages"]

    # Test Inspection generation service
    insp_res = generate_inspection_draft_template_service(db_session, imp_file.import_file_id, "SGS", "COC")
    assert "Germany" in insp_res.template_data["country_of_origin"]
    assert "940130" in insp_res.template_data["hs_code"]

    # Cleanup
    db_session.delete(item1)
    db_session.delete(item2)
    db_session.delete(po)
    db_session.delete(imp_file)
    db_session.commit()


def test_eur1_movement_certificate_full_extraction():
    from modules.smart_document_upload.extractors.other_extractors import COOCertificateExtractor

    sample_eur1_ocr = """MOVEMENT CERTIFICATE
1. Exporter (Name, full address, country)
LT300591314, UAB NARBUTAS INTERNATIONAL
EITMINIU G. 3, LT012113, VILNIUS, LITHUANIA
EUR.1 No A 084188
See notes overleaf before completing this form.
2. Certificate used in preferential trade between
EU
and
EGYPT
(Insert appropriate countries, groups of countries or territories)
3. Consignee (Name, full address, country) (Optional)
ARCHI BRANDS FOR CORPET AND FLOOR
TRADING
STREET 18, BUILDING 44, THIRD FLOOR
CAIRO 11728
EGYPT
4. Country, group of countries
or territory in which the
products are considered as
originating
EU
5. Country, group of
countries or territory
of destination
EGYPT
6. Transport details (Optional)
7. Remarks
REVISED RULES
8. Item number; Marks and numbers; Number and kind of packages(1); Description of goods
OFFICE FURNITURE 141 PACKAGES HS9401; HS9403
9. Gross mass (kg)
or other measure
(litres, m3, etc.)
1774,514KG
10. Invoices
(Optional)
ACID
75955282710
20210010
11. CUSTOMS ENDORSEMENT
Declaration certified
Export document(2)
Form No.
Of
Customs office Vilnius regional customs office
Issuing country or territory Lithuania
Place and date 2026-08-11
(Signature)
Stamp
2026-08-11
A-004
LT VM 0000 LT
12. DECLARATION BY THE EXPORTER
I, the undersigned, declare that the
goods described above meet the
conditions required for the issue
of this certificate.
Place and date VILNIUS 2026-08-11
UAB Narbutas International Dokumentai Vilnius
(Signature)
(1) If goods are not packed, indicate number of articles or state 'in bulk', as appropriate.
(2) Complete only where the regulations of the exporting country or territory require.
2026 UAB LODVILA 00141-A1
"""

    extractor = COOCertificateExtractor()
    result = extractor.extract(sample_eur1_ocr, {})

    assert "084188" in result["certificate_number"]
    assert "UAB NARBUTAS" in result["exporter_name"]
    assert "ARCHI BRANDS" in result["consignee_name"]
    assert "European Union" in result["origin_country"] or "EU" in result["origin_country"]
    assert result["destination_country"] == "EGYPT"
    assert result["remarks"] == "REVISED RULES"
    assert "9401" in result["hs_code"] and "9403" in result["hs_code"]
    assert result["acid_number"] == "7595528271020210010"
    assert "1774" in result["gross_weight"]
    assert "OFFICE FURNITURE" in result["product_description"]
    assert "2026-08-11" in result["issue_date"]
