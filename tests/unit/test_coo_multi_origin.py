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


from datetime import datetime, timezone, timedelta

def test_multi_origin_and_multi_hs_code_extraction(db_session):
    # Setup Master Data
    company = db_session.query(ImportCompany).first()
    if not company:
        now = datetime.now(timezone.utc)
        company = ImportCompany(
            importer_name="Archi Brands Egypt",
            importer_id="IMP-ARCHI-001",
            importer_id_expiry=now + timedelta(days=365),
            vat_id="VAT-100200300",
            vat_id_expiry=now + timedelta(days=365),
            registration_number="REG-100200",
            registration_expiry=now + timedelta(days=365),
            address="12 Ramses St, Cairo",
            country="Egypt",
            phone="+20 2 2577 8899",
            is_active=True,
        )
        db_session.add(company)
        db_session.commit()

    supplier = db_session.query(Supplier).first()
    if not supplier:
        supplier = Supplier(
            supplier_code="SUP-TEST-001",
            company_name="Multi Global Ltd",
            supplier_type="Manufacturer",
            registration_type="Factory",
            foreign_exporter_id="EXP-LT-001",
            foreign_exporter_country="Lithuania",
            foreign_exporter_country_code="LT",
            address="Vilnius, Lithuania",
            is_active=True,
        )
        db_session.add(supplier)
        db_session.commit()

    incoterm = db_session.query(Incoterm).first()
    if not incoterm:
        incoterm = Incoterm(incoterm_code="FOB", incoterm_name="Free on Board", is_active=True)
        db_session.add(incoterm)
        db_session.commit()

    project = db_session.query(Project).first()
    if not project:
        project = Project(
            project_code="PRJ-TEST-001",
            project_name="Central Project",
            project_owner="Logistics Specialist",
            company_id=company.company_id,
            supplier_id=supplier.supplier_id,
            incoterm_id=incoterm.incoterm_id,
            is_active=True,
        )
        db_session.add(project)
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


def test_china_ccpit_certificate_full_extraction():
    from modules.smart_document_upload.extractors.other_extractors import COOCertificateExtractor
    from modules.import_documentation.ai_document_parser import extract_coo_china_ccpit_text

    sample_china_ocr = """ORIGINAL
Page 1 of 1
1.Exporter
SUZHOU GREENISH IMP&EXP CO.,LTD.
NO.78 SUNWU ROAD, XUKOU TOWN, WUZHONG DISTRICTSUZHOU 215100 
CHINA
***
Serial No.
Certificate No. 26C311120218/00004
CERTIFICATE OF ORIGIN
OF
THE PEOPLE'S REPUBLIC OF CHINA
2.Consignee
SCAS FOR CONSTRUCTION AND FINISHING
44, RD 81, MAADI SARAYAT CAIRO, EGYPT
3.Means of transport and route
FROM SHANGHAI CHINA TO ALEXANDRIA EGYPT BY SEA
5.For certifying authority use only
VERIFY URL:HTTP://CHECK.ECOCCPIT.NET/
4.Country / region of destination
EGYPT
6.Marks and numbers 7.Number and kind of packages;description of goods 8.H.S.Code 9.Quantity 10.Number
and date of
invoices
Acoustic Panel ACOUSTIC PANEL ACID:5281534391017110019 560229 810 SHEETS
G.WEIGHT
4904 KGS G.W.
GRS20260505T9
MAY.05,2026
***
11.Declaration by the exporter
The undersigned hereby declares that the above details and statements are 
correct, that all the goods were produced in China and that they comply with the 
Rules of Origin of the People's Republic of China.
SUZHOU,CHINA JUL.30,2026
Place and date,signature and stamp of authorized signatory
12.Certification
It is hereby certified that the declaration by the exporter is correct.
ADDRESS:DONGWU NORTH ROAD GUOYU BUILDING 15A FLOOR 
WUZHONG DISTRICT SUZHOU CITY
FAX:0512-65252957 TEL:0512-65252453
SUZHOU,CHINA JUL.30,2026
Place and date,signature and stamp of certifying authority
"""

    extractor = COOCertificateExtractor()
    result = extractor.extract(sample_china_ocr, {})
    ai_result = extract_coo_china_ccpit_text(sample_china_ocr)

    assert result["certificate_number"] == "26C311120218/00004"
    assert "SUZHOU GREENISH" in result["exporter_name"]
    assert "SCAS FOR CONSTRUCTION" in result["importer_name"]
    assert "OF " not in result["importer_name"]
    assert result["origin_country"] == "China"
    assert result["destination_country"] == "EGYPT"
    assert result["acid_number"] == "5281534391017110019"
    assert result["hs_code"] == "560229"
    assert "4904" in result["gross_weight"]
    assert result["invoice_number"] == "GRS20260505T9"
    assert ai_result["certificate_number"] == "26C311120218/00004"
    assert "SUZHOU GREENISH" in ai_result["exporter_name"]
    assert "SCAS FOR CONSTRUCTION" in ai_result["importer_name"]
    assert ai_result["verification_url"] == "HTTP://CHECK.ECOCCPIT.NET/"


def test_china_ccpit_coo_box_6_and_7_formatting_and_english_words(db_session):
    from modules.import_documentation.service import int_to_english_words, format_total_packages_line

    # Test int_to_english_words
    assert int_to_english_words(82) == "EIGHTY TWO"
    assert int_to_english_words(144) == "ONE HUNDRED FORTY FOUR"
    assert int_to_english_words(1) == "ONE"
    assert int_to_english_words(1000) == "ONE THOUSAND"
    assert int_to_english_words(0) == "ZERO"

    # Test format_total_packages_line
    line82 = format_total_packages_line(82, "Carton")
    assert line82 == "TOTAL PACKED IN EIGHTY TWO (82) CARTONS ONLY"

    line1 = format_total_packages_line(1, "Pallet")
    assert line1 == "TOTAL PACKED IN ONE (1) PALLET ONLY"

    line5 = format_total_packages_line(5, "Containers")
    assert line5 == "TOTAL PACKED IN FIVE (5) CONTAINERS ONLY"

    # Test draft generation for China CCPIT
    china_supplier = Supplier(
        supplier_code="SUP-CHINA-TEST-001",
        company_name="Suzhou Greenish Imp&Exp Co., Ltd.",
        supplier_type="Manufacturer",
        registration_type="Factory",
        foreign_exporter_id="EXP-CN-001",
        foreign_exporter_country="China",
        foreign_exporter_country_code="CN",
        address="Suzhou, China",
        is_active=True,
    )
    db_session.add(china_supplier)
    db_session.commit()

    company = db_session.query(ImportCompany).first()
    project = db_session.query(Project).first()
    incoterm = db_session.query(Incoterm).first()
    currency = db_session.query(Currency).first()

    imp_file = ImportFile(
        import_file_code="IMP-2026-CCPIT-TEST",
        company_id=company.company_id if company else None,
        company_name=company.importer_name if company else "Test Importer",
        supplier_id=china_supplier.supplier_id,
        supplier_name=china_supplier.company_name,
        acid_number="5281534391006810017",
        is_active=True,
    )
    db_session.add(imp_file)
    db_session.commit()

    po_china = PurchaseOrder(
        po_number="PO-CHINA-001-TEST",
        import_file_id=imp_file.import_file_id,
        project_id=project.project_id if project else 1,
        company_id=company.company_id if company else 1,
        supplier_id=china_supplier.supplier_id,
        incoterm_id=incoterm.incoterm_id if incoterm else 1,
        currency_id=currency.currency_id if currency else 1,
        country_of_origin="China",
        total_packages_count=82,
        total_gross_weight_kg=4756.0,
        is_active=True,
    )
    db_session.add(po_china)
    db_session.commit()

    item_china = POLineItem(
        po_id=po_china.po_id,
        description_en="Acoustic Panel",
        description_ar="لوحات صوتية",
        main_description="Acoustic Panel",
        country_of_origin="China",
        quantity=810,
        unit_of_measure="SHEETS",
        unit_price=10.0,
        total_price=8100.0,
        gross_weight_kg=4756.0,
    )
    db_session.add(item_china)
    db_session.commit()

    coo_res = generate_coo_draft_template_service(db_session, imp_file.import_file_id, "China Certificate of Origin (CCPIT)")
    template = coo_res.template_data

    # Check Box 6 is always N/M
    assert template["box_6_marks_and_numbers"] == "N/M"

    # Check Box 7 has main description, total packed line, stars line, and ACID line
    box_7 = template["box_7_description_and_acid"]
    assert "Acoustic Panel" in box_7
    assert "TOTAL PACKED IN EIGHTY TWO (82) CARTONS ONLY" in box_7
    assert "*** *** *** *** ***" in box_7
    assert "ACID:5281534391006810017" in box_7
    assert "N/M" not in box_7

    # Check Box 8 is formatted as 4-digit heading with dot for Chinese COO
    assert template["box_8_hs_code"] == "56.02"

    # Check table rows Box 6 is N/M and Box 8 is 56.02
    assert len(template["table_rows"]) >= 1
    assert template["table_rows"][0]["marks_and_numbers"] == "N/M"
    assert template["table_rows"][0]["hs_code"] == "56.02"
    assert "TOTAL PACKED IN EIGHTY TWO (82) CARTONS ONLY" in template["table_rows"][0]["description_and_acid"]
    assert "N/M" not in template["table_rows"][0]["description_and_acid"]

    # Cleanup
    db_session.delete(item_china)
    db_session.delete(po_china)
    db_session.delete(imp_file)
    db_session.delete(china_supplier)
    db_session.commit()


def test_extract_clean_main_description_and_anti_duplicate_models():
    from modules.import_documentation.service import extract_clean_main_description, format_coo_hs_code
    
    # Verify stripping of model numbers, codes, and material qualifiers (e.g. PET)
    assert extract_clean_main_description("PET Acoustic Panels (YH-652)") == "Acoustic Panels"
    assert extract_clean_main_description("PET Acoustic Panels (YH-644)") == "Acoustic Panels"
    assert extract_clean_main_description("Acoustic Panel YH-652") == "Acoustic Panel"
    assert extract_clean_main_description("Acoustic Panel (Model A-123)") == "Acoustic Panel"
    assert extract_clean_main_description("PET Acoustic Panels (YH-652) / PET Acoustic Panels (YH-644)") == "Acoustic Panels"
    assert extract_clean_main_description("N/M Acoustic Panels") == "Acoustic Panels"
    assert extract_clean_main_description("PET Acoustic Panels") == "Acoustic Panels"

    # Verify Chinese COO 4-digit Box 8 formatting (XX.XX)
    assert format_coo_hs_code("5602290000", is_china=True) == "56.02"
    assert format_coo_hs_code("560229", is_china=True) == "56.02"
    assert format_coo_hs_code("5602", is_china=True) == "56.02"
    assert format_coo_hs_code("3921900000", is_china=True) == "39.21"
    assert format_coo_hs_code("5602290000, 3921900000", is_china=True) == "56.02, 39.21"
    assert format_coo_hs_code("5602290000", is_china=False) == "5602290000"



