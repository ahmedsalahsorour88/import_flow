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

