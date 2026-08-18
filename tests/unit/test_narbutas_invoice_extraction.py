"""
Unit Test: Narbutas Commercial Invoice Extraction & Tariff Compliance
Verifies 100% extraction accuracy on real-world multi-page EU Commercial Invoice
with strict entity boundaries, currency weights, and per-item HS Code tariff registration alerts.
"""

import pytest
from modules.smart_document_upload.extractors.purchase_order import PurchaseOrderExtractor


def test_narbutas_commercial_invoice_extraction():
    sample_ocr_text = """
UAB Narbutas 
International
Eitminų g. 3
Vilnius, 12113
LTU
Telephone +370 5 243 1407
Enterprise code 300591314
VAT LT100002632414
OUR BANK INFORMATION BANK DETAILS FOR USD PAYMENTS INVOICE
Bank account number Bank account number Nr. IN053328
LT957044060008321570 8960563579
Routing No.: 231372691 Packing slip SPS0034141
AB SEB Bankas EUR Santander Bank, N.A. USD Load ID LOAD072811
CBVILT2XXXX SVRNUS33 Date 2026-08-07
Bank address: Bank address: Sales responsible Vitalij Karpov
Konstitucijos pr. 24 601 Penn Street
Vilnius 08105 Reading PA 19601
LTU USA
Delivery terms EXW
Terms of payment Prepayment
Country of origin Lithuania
Customer Delivery address
Archi Brands for Corpet and Floor Trading
Maadi, Street 18, Building 44, Third Floor
Cairo 11728
EGY
Enterprise code - ND
VAT - ND
Contact Contact information
Hana Bayoumi +201009688553
Hana Bayoumi h.bayoumi@archi-brands.com

Item number Configuration Item name Quantity Unit Sales price Amount VAT
Sales order SO6094737 / Quotation Q086860
Customer requisition Informa REV.8
PSHD041 .PA01.MA03 Mobile table with metal base, W=400, D=500, H=620 MOBI 4.00 Pcs 124.00 496.00 0.00 %
PSHD041 .PA01.MA03 Mobile table with metal base, W=400, D=500, H=620 MOBI 2.00 Pcs 124.00 248.00 0.00 %
PCOM080 .PA01.MA03 Meeting table (3 seats), Ø 800, H=740 FSC Mix 70% * FORUM 2.00 Pcs 235.50 471.00 0.00 %
PDNA124-U .PA01.MA03 Desk, 1200x600, H=740 FSC Mix 70% * NOVA U 1.00 Pcs 86.50 86.50 0.00 %

G6F0443 .MA03.F.EU.0 Telescopic frame with adjustable electric legs 1.00 Pcs 187.00 187.00 0.00 %
G2A0B30 .PA01.0 Desktop, 1600x700, H=25 1.00 Pcs 35.00 35.00 0.00 %

PLEASE PROVIDE FOLLOWING INVOICE NUMBER IN053328 TO ENSURE A SMOOTH PAYMENT CONFIRMATION
If payment is late for 3 or more days The Buyer's account will be temporarily suspended in the Seller's system, which means: future Orders from the Buyer will not be processed.

Total of sales order SO6094737 / Quotation Q086860
15,375.50 EUR
Amount excl. sales tax 15,375.50 EUR
Discount 0.00 EUR
Taxable amount 0.00 % VAT 15,375.50 EUR
Invoice amount 15,375.50 EUR
Payment amount 15,375.50 EUR

Logistics manager Karolis Zajančkauskas
Volume 26.059
Weight netto 1,362.314
Weight brutto 1,789.511
Number of packages 142
Number of pallets 13
Acid Number: 7595528271020210010
"""
    extractor = PurchaseOrderExtractor()
    result = extractor.extract(sample_ocr_text, {})

    # 1. Supplier Name & Details (Should NOT be footer disclaimer)
    assert "NARBUTAS" in result["supplier_name"].upper()
    assert "PROCESSED" not in result["supplier_name"].upper()
    assert result["supplier_phone"] == "+370 5 243 1407"
    assert result["supplier_tax_id"] == "300591314"
    assert "Eitminų g. 3" in result["supplier_address"]

    # 2. Importer Name & Details (Should NOT be 'Customer requisition...')
    assert "ARCHI BRANDS" in result["importer_name"].upper()
    assert "REQUISITION" not in result["importer_name"].upper()
    assert result["importer_phone"] == "+201009688553"
    assert result["importer_email"] == "h.bayoumi@archi-brands.com"
    assert "Maadi" in result["importer_address"]

    # 3. Financial & Customs Metadata
    assert result["po_number"] == "IN053328"
    assert result["currency"] == "EUR"  # Must NOT be USD from bank details!
    assert result["incoterms"] == "EXW"
    assert result["country_of_origin"] == "Lithuania"
    assert result["total_amount"] == 15375.50
    assert result["order_date"] == "2026-08-07"

    # 4. HS Code verification - Tax ID must NOT be assigned as HS Code!
    assert result["hs_code"] != "300591314"

    # 5. Line items & HS code compliance warnings
    assert len(result["items"]) >= 6
    assert result["unregistered_hs_items_count"] > 0
    assert result["hs_code_compliance_warning"] is not None
    for item in result["items"]:
        # Each item should have HS code warning if unregistered
        assert "hs_code_status" in item
        assert item["hs_code_status"] == "missing"
        assert item["hs_code_warning"] is not None

    # 6. Logistics & Packing List CBM Extraction
    assert len(result["packing_list_items"]) == 1
    pack = result["packing_list_items"][0]
    assert pack["total_cbm"] == 26.059
    assert pack["total_gross_weight_kg"] == 1789.511
    assert pack["total_net_weight_kg"] == 1362.314
    assert pack["qty_pkg"] == 13.0
    assert pack["qty_pcs"] == 142.0
