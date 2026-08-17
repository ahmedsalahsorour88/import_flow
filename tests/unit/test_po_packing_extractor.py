import pytest
from fastapi.testclient import TestClient
from main import app
from modules.import_documentation.ai_document_parser import (
    extract_commercial_invoice_data,
    extract_packing_list_data,
    reconcile_po_documents_with_system,
)

SAMPLE_GI_INDUSTRIAL_INVOICE = """
G.I. INDUSTRIAL HOLDING SPA
Via G. Agnelli, 7 - 33053 Latisana (UD) - Italy
P.IVA IT01982510305
COMMERCIAL INVOICE Date 30/06/2026 Page 1
V1/ 2562
Client id. no. 801765
V.A.T. ID Number 200183044
Messrs
ECO ASSOCIATES
7 HOSNI OSMAN ST., SEFARAT DISTRICT
11471 NASR CITY, CAIRO
Egitto
Payment condition 100% AVV. MERCE PRONTA-PICK UP CONF.
Bank IT80Q0503412301USD100004026
SWIFT BAPPIT21682
Shipping - Delivery terms - As per INCOTERMS 2020
EX WORKS EXTRA UE

Your order ECO/049/2026/REV00
Our order confirmation M26 413 date 5/03/26
Commessa 27/360012
CYK4R6018210001 RTAXT/K/EC/MS 182 IM/RFM/RFL/PF/NS DOUBLE SKIN PACKAGED ROOF TOP 84158200 2,000 NR 18.602,37500 37.204,75 NI
QCR12026802R AG - RUBBER SHOCK ABSORBERS 2,000 NR 268,12500 536,25 NI

ACID NR. 2001830441013710010
IMPORTER TAX ID: 200183044
EXPORTER REGISTRATION NUMBER: 01982510305

Total goods 37.741,00
TOTAL INVOICE AMOUNT 37.741,00 EUR
Net weight kg 2.254,000
Gross weight kg 2.274,000
Packages 4
"""

SAMPLE_GI_INDUSTRIAL_PACKING_LIST = """
Latisana, 30/06/2026
ECO ASSOCIATES
7 HOSNI OSMAN ST. SEFARAT DISTRICT
11471 NASR CITY, CAIRO
EGYPT

NOSTRO ORDINE / OUR ORDER M26 413
COMMESSA 27/360012
VOSTRO ORDINE / YOUR ORDER ECO/049/2026/REV00
ACID NUMBER 2001830441013710010

PACKING AND WEIGHT LIST
DESCRIZIONE / DESCRIPTION Q.TY (NO) LENGTH (mm.) WIDTH (mm.) HEIGHT (mm.) NET (KG) GROSS (KG) (NO) (TYPE)
RTAXT/K/EC/MS 182 IM/RFM/RFL/PF/NS 2 3950 2250 2250 2250 2270 2 PACKAGE
QCR12026802R 1 275 265 160 4 4 2 BOX
KG / COLLI 2254,0 2274,0 4,0 TOTAL
"""


def test_extract_gi_industrial_invoice():
    parsed = extract_commercial_invoice_data(SAMPLE_GI_INDUSTRIAL_INVOICE)
    assert parsed["acid_number"] == "2001830441013710010"
    assert parsed["importer_tax_id"] == "200183044"
    assert parsed["exporter_registration_no"] == "01982510305"
    assert "2562" in parsed["invoice_number"]
    assert parsed["currency"] == "EUR"
    assert parsed["total_amount"] == 37741.0
    assert parsed["total_gross_weight_kg"] == 2274.0
    assert parsed["total_net_weight_kg"] == 2254.0
    assert parsed["qty_pkg"] == 4
    assert parsed["incoterm"] == "EXW"
    assert len(parsed["items"]) >= 2
    assert parsed["items"][0]["item_code"] == "CYK4R6018210001"
    assert parsed["items"][0]["quantity"] == 2.0
    assert parsed["items"][0]["unit_price"] == 18602.375


def test_extract_gi_industrial_packing_list():
    parsed = extract_packing_list_data(SAMPLE_GI_INDUSTRIAL_PACKING_LIST)
    assert parsed["acid_number"] == "2001830441013710010"
    assert "ECO ASSOCIATES" in parsed["customer_name"].upper()
    assert parsed["total_gross_weight_kg"] == 2274.0
    assert parsed["total_net_weight_kg"] == 2254.0
    assert parsed["total_packages"] == 4
    assert len(parsed["items"]) >= 2
    assert parsed["items"][0]["length_mm"] == 3950.0
    assert parsed["items"][0]["width_mm"] == 2250.0
    assert parsed["items"][0]["height_mm"] == 2250.0
    assert parsed["items"][0]["packages_count"] == 2.0
    assert parsed["total_cbm"] > 35.0


def test_reconcile_po_documents_with_system():
    inv_data = extract_commercial_invoice_data(SAMPLE_GI_INDUSTRIAL_INVOICE)
    pl_data = extract_packing_list_data(SAMPLE_GI_INDUSTRIAL_PACKING_LIST)
    
    system_items = [
        {
            "po_item_id": 1,
            "item_code": "CYK4R6018210001",
            "description": "Double Skin Packaged Roof Top Units",
            "initial_quantity": 2.0,
            "initial_unit_price": 18602.375,
            "initial_packages_count": 2.0,
            "initial_gross_weight_kg": 2270.0,
            "initial_net_weight_kg": 2250.0,
            "initial_cbm": 39.99,
        },
        {
            "po_item_id": 2,
            "item_code": "QCR12026802R",
            "description": "Rubber Shock Absorbers",
            "initial_quantity": 2.0,
            "initial_unit_price": 268.125,
            "initial_packages_count": 2.0,
            "initial_gross_weight_kg": 4.0,
            "initial_net_weight_kg": 4.0,
            "initial_cbm": 0.012,
        }
    ]
    file_meta = {
        "acid_number": "2001830441013710010",
        "importer_tax_id": "200183044",
        "total_amount": 37741.0,
        "currency": "EUR",
        "total_packages": 4,
        "total_gross_weight_kg": 2274.0,
    }

    result = reconcile_po_documents_with_system(inv_data, pl_data, system_items, file_meta)
    assert result["is_safe_for_certification"] is True
    assert result["critical_discrepancies_count"] == 0
    assert len(result["reconciled_invoice_items"]) == 2
    assert len(result["reconciled_packing_items"]) == 2
    assert result["reconciled_invoice_items"][0]["final_quantity"] == 2.0
    assert result["reconciled_invoice_items"][0]["final_unit_price"] == 18602.375


def test_api_extract_and_compare_po_endpoint():
    client = TestClient(app)
    response = client.post(
        "/api/v1/import-documentation/po-reconciliation/extract-and-compare",
        json={
            "invoice_raw_text": SAMPLE_GI_INDUSTRIAL_INVOICE,
            "packing_list_raw_text": SAMPLE_GI_INDUSTRIAL_PACKING_LIST,
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["is_safe_for_certification"] is True
    assert data["extracted_invoice_data"]["acid_number"] == "2001830441013710010"
    assert data["extracted_packing_data"]["total_packages"] == 4
    assert len(data["reconciled_invoice_items"]) >= 2
