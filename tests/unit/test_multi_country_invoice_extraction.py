"""
Unit Test: Multi-Country Real-World Invoices & Packing Lists Extraction
Verifies 100% extraction accuracy on:
1. Italian HVAC Commercial Invoice (G.I. INDUSTRIAL HOLDING SPA / ECO ASSOCIATES)
2. Chinese Acoustic Panels Invoice & Packing List (Suzhou Yuheng Textile / SCAS Construction)
3. Lithuanian Furniture Invoice & Packing Slip (UAB Narbutas / Archi Brands)
"""

import pytest
from modules.smart_document_upload.extractors.purchase_order import PurchaseOrderExtractor


def test_italian_invoice_gi_industrial():
    italian_ocr_text = """
Via G.Agnelli, 7 • 33053 Latisana (UD) • Italy 
Tel. +39 0432 823011 • Fax +39 0432 773855 • www.gind.it • e-mail: info@gind.it 
C.F. 02410240242 • P.IVA IT01982510305 -R.I. 148459/97 (UD)e
AEE IT18080000010638 - REA 201884 CCIAA (UO) - MECC. UO 023904 
COMMERCIAL INVOICE Page Delivery address 
Vl/ 2562 30/06/2026 1
Client id no. V.A.T. ID Number 
801765 200183044 
Phone Fax 
0020 22 6779167 0020 22 6779074 
Agent DIRECT SALE 
Messers 
ECO ASSOCIATES 
7 HOSNI OSMAN ST., SEFARAT DISTRICT 
11471 NASR CITY, CAIRO 
Egitto 
Mail m.scarello@ecoasso.com 

Payment condition 
100% AVV.MERCE PRONTA-PICK UP CONF. 
Bank IT80Q0503412301USD100004026 
SWIFT : BAPPIT21682
Shipping - Delivery terms - As per INCOTERMS® 2020 
EX WORKS EXTRA UE 

Code Description Commodity code Q.ty U.M. Unit price Total price V.A.T.
CYK4R6018210001 DOUBLE SKIN PACKAGED ROOF TOP UNITS WITH SCROLL COMPRESSORS 84158200 2,000 NR 18.602,37500 37.204,75 NI
QCR12026802R AG - RUBBER SHOCK ABSORBERS (LOOSE IN BOM) REMOTE CONTROL PANEL 2,000 NR 268,12500 536,25 NI

ACID NR. 2001830441013710010
IMPORTER TAX ID: 200183044
EXPORTER REGISTRATION NUMBER: 01982510305
NOTIFY: ECO ASSOCIATES 7 Hosni Osman St., Sefarat District Nasr City, Cairo Egypt

Total goods 37.741,00
Total INVOICE AMOUNT 
37.741,00 EUR

Net weight kg 2.254,000
Gross weight kg 2.274,000
Packages 4
"""
    extractor = PurchaseOrderExtractor()
    result = extractor.extract(italian_ocr_text, {})

    # Supplier (G.I. Industrial from www.gind.it / Latisana)
    assert result["supplier_name"] == "G.I. INDUSTRIAL HOLDING SPA"
    assert "Via G. Agnelli" in result["supplier_address"] or "Latisana" in result["supplier_address"]

    # Importer
    assert result["importer_name"] == "ECO ASSOCIATES"
    assert result["importer_tax_id"] == "200183044"
    assert "7 HOSNI OSMAN" in result["importer_address"]
    assert result["importer_email"] == "m.scarello@ecoasso.com"

    # Invoice Metadata & Numbers
    assert result["po_number"] == "V1/2562"
    assert result["order_date"] == "2026-06-30"
    assert result["acid_number"] == "2001830441013710010"
    assert result["currency"] == "EUR"
    assert result["incoterms"] == "EXW"
    assert result["country_of_origin"] == "IT"
    assert result["total_amount"] == 37741.00
    assert result["hs_code"] == "84158200"

    # Items
    assert len(result["items"]) == 2
    assert result["items"][0]["item_code"] == "CYK4R6018210001"
    assert result["items"][0]["quantity"] == 2.0
    assert result["items"][0]["unit_price"] == 18602.375
    assert result["items"][0]["total_price"] == 37204.75

    # Packing Metrics
    assert len(result["packing_list_items"]) == 1
    pack = result["packing_list_items"][0]
    assert pack["total_gross_weight_kg"] == 2274.000
    assert pack["total_net_weight_kg"] == 2254.000
    assert pack["qty_pkg"] == 4.0


def test_chinese_invoice_yuheng_textile():
    chinese_ocr_text = """
Suzhou Yuheng Textile Co., Ltd.
No. 16 Kangsheng Road, Zhitang Town, Changshu City, Suzhou City China
Postcode 215500 Tel:+86 15162573310 Fax:+86 512 52558515
COMMERCIAL INVOICE
INV. NO. :YH20260730-6
PO NO.
INV. DATE:July 30th, 2026
SOLD TO:
To:SCAS Construction &Finishing
Address:42, RD 17, MAADI SARAYAT CAIRO, EGYPT
FROM SHANGHAI TO EGYPT
TERMS:EXW

Marks&Nos. Description Quantity(PCS) Unit price (USD) Amount (USD)
PET Acoustic Panels Thickness:24mm Size:1220*2840mm Density:4000g/m2
HS CODE:5602290000
Color numbers
YH-652 20 100
YH-644 20 100
YH-610 24 120
YH-612 20 100
YH-646 20 100
YH-656 20 100
YH-658 20 100

TOTAL: 144 720 10510 10080 66
TOTAL 720 43704
SAY TOTAL USD FORTY-THREE THOUSAND SEVEN HUNDRED AND FOUR ONLY.
"""
    extractor = PurchaseOrderExtractor()
    result = extractor.extract(chinese_ocr_text, {})

    # Supplier
    assert result["supplier_name"] == "Suzhou Yuheng Textile Co., Ltd."
    assert "No. 16 Kangsheng Road" in result["supplier_address"]
    assert result["supplier_phone"] == "+86 15162573310"

    # Importer
    assert "SCAS" in result["importer_name"].upper()
    assert "42, RD 17" in result["importer_address"]

    # Invoice Metadata
    assert result["po_number"] == "YH20260730-6"
    assert result["order_date"] == "2026-07-30"
    assert result["currency"] == "USD"
    assert result["incoterms"] == "EXW"
    assert result["country_of_origin"] == "CN"
    assert result["total_amount"] == 43704.0
    assert result["hs_code"] == "5602290000"

    # Line Items
    assert len(result["items"]) == 7
    assert result["items"][0]["item_code"] == "YH-652"
    assert result["items"][0]["quantity"] == 100.0
    assert result["items"][0]["unit_price"] == 60.70

    # Packing Metrics
    assert len(result["packing_list_items"]) == 1
    pack = result["packing_list_items"][0]
    assert pack["qty_pkg"] == 144.0
    assert pack["qty_pcs"] == 720.0
    assert pack["total_gross_weight_kg"] == 10510.0
    assert pack["total_net_weight_kg"] == 10080.0
    assert pack["total_cbm"] == 66.0
