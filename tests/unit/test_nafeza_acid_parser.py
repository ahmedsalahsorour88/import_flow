import pytest
from modules.import_documentation.nafeza_acid_parser import (
    parse_nafeza_acid_text,
    compare_acid_data,
    generate_whatsapp_request_text,
    generate_email_request_template,
    parse_date_flexible,
)

SAMPLE_MTS_TEXT = """
MTS Notification
Dear Impact Acoustic Spa,

Kindly be informed that an Advance Cargo Information request (ACI) has been approved for shipping:
[ACID: 7595528271015010011]
Requested: 31-May-2026 10:40:55 AM   Generated: 31-May-2026 10:41:01 AM   Expires: 30-Nov-2026 10:41:01 AM 
Egyptian Importer
Egyptian Importer Name: Arki Brands for Carpet and Flooring Trading
Egyptian Importer Tax ID: 759552827
Address: القاهره المعادى 44 ش 18 المعادى

Foreign Exporter
Foreign Exporter Name: Impact Acoustic Spa
Registration Type: VAT Number
Foreign Exporter ID: IT04462890981
Country: ITALY
Country Code: IT 
Address: Via Caldera 21
20153
Tel. No.: 0

Shipment
Proforma Invoice No.: IT-DN26-0031496
Proforma Invoice Date: 5/27/2026 12:00:00 AM
Invoice Date: 5/31/2026 10:38:19 AM
Type of invoice: Proforma Invoice
Shipping Port: Genoa
Destination Port: Alexandria
Note that any modifications for shipping or destination port for a shipment will not impact the customs clearance procedure in Egypt. 


ACID: 7595528271015010011 
Egyptian Importer Tax ID: 759552827 
Foreign Exporter Registration Type: VAT Number 
Foreign Exporter ID: IT04462890981 
Foreign Exporter Country: ITALY 
Foreign Exporter Country Code: IT 

Please make sure to print ACID on all shipping documents (commercial invoice, bill of lading, packing list, certificate of origin,...etc) as well as the tax ID of the Egyptian importer and the identity of the foreign exporter on the commercial invoice and bill of lading. 

Egyptian Customs Authority (ECA) will not accept any document not matching the above requirement starting as of the 1 of October 2021 


Warning 
Please note that the required documents for the mentioned shipment must be uploaded from the exporter who registered with ID: 67a645ce-62e8-4850-a09e-a20b8ea1d917 on the CargoX platform.

Note: delegations cases already covered
If this CargoX ID is not correct please contact the ACID issuer 
"""


def test_parse_sample_mts_text():
    parsed = parse_nafeza_acid_text(SAMPLE_MTS_TEXT)
    assert parsed["acid_number"] == "7595528271015010011"
    assert parsed["importer_name"] == "Arki Brands for Carpet and Flooring Trading"
    assert parsed["importer_tax_id"] == "759552827"
    assert "المعادى" in parsed["importer_address"]
    assert parsed["exporter_name"] == "Impact Acoustic Spa"
    assert parsed["exporter_reg_type"] == "VAT Number"
    assert parsed["exporter_reg_id"] == "IT04462890981"
    assert parsed["exporter_country"] == "ITALY"
    assert parsed["exporter_country_code"] == "IT"
    assert "Via Caldera 21" in parsed["exporter_address"]
    assert parsed["proforma_invoice_no"] == "IT-DN26-0031496"
    assert parsed["proforma_invoice_date"] == "2026-05-27"
    assert parsed["invoice_date"] == "2026-05-31"
    assert parsed["pol_name"] == "Genoa"
    assert parsed["pod_name"] == "Alexandria"
    assert parsed["cargox_id"] == "67a645ce-62e8-4850-a09e-a20b8ea1d917"
    assert parsed["requested_date"] == "2026-05-31"
    assert parsed["generated_date"] == "2026-05-31"
    assert parsed["expiry_date"] == "2026-11-30"


def test_parse_date_flexible():
    assert parse_date_flexible("31-May-2026 10:40:55 AM") == "2026-05-31"
    assert parse_date_flexible("5/27/2026 12:00:00 AM") == "2026-05-27"
    assert parse_date_flexible("2026-08-15") == "2026-08-15"
    assert parse_date_flexible("15/08/2026") == "2026-08-15"
    assert parse_date_flexible(None) is None


def test_compare_acid_data_matching():
    requested = {
        "importer_name": "Arki Brands for Carpet and Flooring Trading",
        "importer_tax_id": "759-552-827",
        "exporter_name": "Impact Acoustic Spa",
        "exporter_reg_type": "VAT Number",
        "exporter_reg_id": "IT04462890981",
        "exporter_country": "ITALY",
        "exporter_country_code": "IT",
        "proforma_invoice_no": "IT-DN26-0031496",
        "pol_name": "Genoa Port",
        "pod_name": "Alexandria Port",
        "cargox_id": "67a645ce-62e8-4850-a09e-a20b8ea1d917",
    }
    generated = {
        "importer_name": "Arki Brands for Carpet and Flooring Trading",
        "importer_tax_id": "759552827",
        "exporter_name": "Impact Acoustic Spa",
        "exporter_reg_type": "VAT Number",
        "exporter_reg_id": "IT04462890981",
        "exporter_country": "ITALY",
        "exporter_country_code": "IT",
        "proforma_invoice_no": "IT-DN26-0031496",
        "pol_name": "Genoa",
        "pod_name": "Alexandria",
        "cargox_id": "67a645ce-62e8-4850-a09e-a20b8ea1d917",
    }
    comparison = compare_acid_data(requested, generated)
    assert comparison["all_matched"] is True
    assert comparison["match_percentage"] == 100.0
    assert comparison["has_critical_error"] is False


def test_compare_acid_data_with_discrepancy():
    requested = {
        "importer_name": "Arki Brands for Carpet and Flooring Trading",
        "importer_tax_id": "759552827",
        "exporter_name": "Impact Acoustic Spa",
        "exporter_reg_id": "IT04462890981",
        "proforma_invoice_no": "IT-DN26-0031496",
        "pol_name": "Shanghai Port",
        "pod_name": "Alexandria Port",
    }
    generated = {
        "importer_name": "Arki Brands for Carpet and Flooring Trading",
        "importer_tax_id": "759552827",
        "exporter_name": "Impact Acoustic Spa",
        "exporter_reg_id": "IT04462890981",
        "proforma_invoice_no": "IT-DN26-0031496",
        "pol_name": "Genoa Port",  # Different port!
        "pod_name": "Alexandria Port",
    }
    comparison = compare_acid_data(requested, generated)
    assert comparison["all_matched"] is False
    assert comparison["discrepant_count"] >= 1
    port_item = next(item for item in comparison["items"] if item["field"] == "pol_name")
    assert port_item["is_matched"] is False


def test_templates_generation():
    req = {
        "importer_name": "Arki Brands",
        "importer_tax_id": "759552827",
        "exporter_name": "Impact Acoustic",
        "proforma_invoice_no": "PI-1234",
    }
    wa_msg = generate_whatsapp_request_text(req)
    assert "طلب استخراج رقم ACID جديد" in wa_msg
    assert "Arki Brands" in wa_msg
    assert "PI-1234" in wa_msg

    email_tmpl = generate_email_request_template(req)
    assert "Arki Brands" in email_tmpl["subject"]
    assert "PI-1234" in email_tmpl["body"]
