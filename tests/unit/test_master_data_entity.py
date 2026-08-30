"""
Unit tests for MasterDataEntityExtractor
Verifies accurate extraction from raw text blocks (business cards, signatures, headers).
"""

from modules.smart_document_upload.extractors.master_data_entity import MasterDataEntityExtractor


def test_suzhou_yuheng_extraction():
    raw_text = """
    Factory owner M:0086 15962900581 W:www.yhacoustic.com
    Suzhou Yuheng Textile Co.,Ltd
    Factory Address:N0.16,Kangsheng Road,Zhitang Town,Changshu City,Jiangsu Province,China
    PET Felt Acoustic Panel Manufacturer
    """
    extractor = MasterDataEntityExtractor()
    extracted = extractor.extract(raw_text, {})

    assert extracted["company_name"] == "Suzhou Yuheng Textile Co.,Ltd"
    assert extracted["mobile_number"] == "0086 15962900581"
    assert extracted["website"] == "www.yhacoustic.com"
    assert "Kangsheng Road" in extracted["address"]
    assert extracted["country_code"] == "CN"
    assert extracted["industry_description"] == "PET Felt Acoustic Panel Manufacturer"


def test_shaw_europe_extraction():
    raw_text = """
    Shaw Europe Limited
    Blackaddie Road
    Sanquhar, United Kingdom, DG4 6DB United Kingdom
    VAT Number 428102677
    Phone +44 1659 50497
    """
    extractor = MasterDataEntityExtractor()
    extracted = extractor.extract(raw_text, {})

    assert extracted["company_name"] == "Shaw Europe Limited"
    assert extracted["phone_number"] == "+44 1659 50497"
    assert extracted["vat_tax_id"] == "428102677"
    assert "Blackaddie Road" in extracted["address"]
    assert extracted["country_code"] == "GB"
    assert extracted["postcode"] == "DG4 6DB"


def test_egyptian_importer_extraction():
    raw_text = """
    شركة النور للاستيراد والتصدير ش.م.م
    العنوان: 15 شارع طلعت حرب - القاهرة
    Country: Egypt
    البطاقة الاستيرادية: 759552827 (تنتهي في 2029-03-31)
    البطاقة الضريبية: 759552827 (تنتهي في 2029-03-31)
    السجل التجاري: 228795 (ينتهي في 2029-03-04)
    الهاتف: +20 100 000 0000
    Email: info@alnoor-import.com
    """
    extractor = MasterDataEntityExtractor()
    extracted = extractor.extract(raw_text, {})

    assert "شركة النور للاستيراد" in extracted["arabic_name"]
    assert extracted["importer_id"] == "759552827"
    assert extracted["importer_id_expiry"] == "2029-03-31"
    assert extracted["vat_tax_id"] == "759552827"
    assert extracted["vat_id_expiry"] == "2029-03-31"
    assert extracted["commercial_register"] == "228795"
    assert extracted["registration_expiry"] == "2029-03-04"
    assert extracted["email"] == "info@alnoor-import.com"
    assert extracted["country_code"] == "EG"


def test_shaw_europe_user_case():
    raw_text = """
    SHAW EUROPE LTD
    BUILDING E
    BLACKADDIE RD SANQUHAR
    DG4 6DB. UNITED KINGDOM
    SHIPPER REGISTRATION TYPE: VAT NUMBER
    SHIPPER ID: GB428102677
    SHIPPER COUNTRY: UNITED KINGDOM
    SHIPPER COUNTRY CODE: GB
    """
    extractor = MasterDataEntityExtractor()
    extracted = extractor.extract(raw_text, {}, module_name="supplier-entity")

    assert extracted["company_name"] == "SHAW EUROPE LTD"
    assert extracted["country_code"] == "GB"
    assert extracted["foreign_exporter_id"] == "GB428102677"
    assert extracted["vat_tax_id"] == "GB428102677"
    assert extracted["registration_type"] == "VAT Number"
    assert extracted["postcode"] == "DG4 6DB"
    assert "BUILDING E" in extracted["address"]
    assert "BLACKADDIE RD SANQUHAR" in extracted["address"]
    assert "SHIPPER REGISTRATION" not in extracted["address"]
    assert "SHIPPER ID" not in extracted["address"]
    assert "SHIPPER COUNTRY" not in extracted["address"]


def test_narbutas_lithuania_case():
    raw_text = """
    NARBUTAS INTERNATIONAL, UAB
    Ukmerges st. 308, LT-12110 Vilnius, Lithuania
    Company code: 300591244
    VAT code: LT100002821114
    Tel. +370 5 210 5000
    Email: info@narbutas.lt
    """
    extractor = MasterDataEntityExtractor()
    extracted = extractor.extract(raw_text, {}, module_name="supplier-entity")

    assert extracted["company_name"] == "NARBUTAS INTERNATIONAL, UAB"
    assert extracted["country_code"] == "LT"
    assert extracted["commercial_register"] == "300591244"
    assert extracted["vat_tax_id"] == "LT100002821114"
    assert extracted["registration_type"] == "VAT Number"
    assert extracted["phone_number"] == "+370 5 210 5000"
    assert extracted["email"] == "info@narbutas.lt"
    assert "Ukmerges st. 308" in extracted["address"]


def test_bank_and_cargox_case():
    raw_text = """
    NATIONAL BANK OF EGYPT
    SWIFT Code: NBEGEGCX001
    IBAN: EG123456789012345678901234567
    CargoX Blockchain ID: 0x71C66332e3D3D362aBC5B4F09a8570395c860000
    """
    extractor = MasterDataEntityExtractor()
    extracted = extractor.extract(raw_text, {}, module_name="bank-entity")

    assert extracted["company_name"] == "NATIONAL BANK OF EGYPT"
    assert extracted["swift_code"] == "NBEGEGCX001"
    assert extracted["iban"] == "EG123456789012345678901234567"
    assert extracted["cargox_id"] == "0x71C66332e3D3D362aBC5B4F09a8570395c860000"


def test_archi_brands_egyptian_importer():
    raw_text = """
    ARCHI Brands for Corpet and Floor Trading
    St.81 with st.18 building 44, 3rd floor
    SARAYAT EL MAADI, Cairo- Egypt
    VAT No: 759-552-827
    EGYPTIAN IMPORTER TAX ID: 759552827
    """
    extractor = MasterDataEntityExtractor()
    extracted = extractor.extract(raw_text, {}, module_name="importer-entity")

    assert extracted["company_name"] == "ARCHI Brands for Corpet and Floor Trading"
    assert extracted["country_code"] == "EG"
    assert "St.81 with st.18 building 44" in extracted["address"]
    assert "SARAYAT EL MAADI, Cairo- Egypt" in extracted["address"]
    assert "EGYPTIAN IMPORTER TAX ID" not in extracted["address"]
    assert "VAT No" not in extracted["address"]
    assert extracted["importer_id"] in ["759552827", "759-552-827"]
    assert extracted["vat_tax_id"] in ["759-552-827", "759552827"]


def test_foreign_supplier_with_bank_details():
    raw_text = """
    Supplier Name: G.I. Industrial Holding S.p.A.
    Supplier Type: Manufacturer
    Registration Type: Factory Registration
    Foreign Exporter ID: IT03456789012
    CargoX Platform ID: 0x9876543210abcdef9876543210abcdef98765432
    Country: Italy
    Country Code: IT
    Address: Via Max Piccini 11, 33050 Rivignano Teor (UD), Italy
    Email: export@gi-industrial.it
    Bank Name: Intesa Sanpaolo S.p.A.
    SWIFT Code: BCITITMM
    IBAN: IT60X0542811101000000123456
    Brands: Clint, Montair, Novair
    Notes: Leading Italian manufacturer of HVAC chillers
    """
    extractor = MasterDataEntityExtractor()
    extracted = extractor.extract(raw_text, {}, module_name="supplier-entity")

    assert extracted["company_name"] == "G.I. Industrial Holding S.p.A."
    assert extracted["supplier_type"] == "Manufacturer"
    assert extracted["registration_type"] == "Factory Registration"
    assert extracted["foreign_exporter_id"] == "IT03456789012"
    assert extracted["cargox_id"] == "0x9876543210abcdef9876543210abcdef98765432"
    assert extracted["country_code"] == "IT"
    assert "Via Max Piccini 11" in extracted["address"]
    assert extracted["email"] == "export@gi-industrial.it"
    assert extracted["bank_name"] == "Intesa Sanpaolo S.p.A."
    assert extracted["swift_code"] == "BCITITMM"
    assert "IT60X0542811101000000123456" in extracted["iban"]
    assert "Clint" in extracted["brands"]
    assert "chillers" in extracted["notes"]




