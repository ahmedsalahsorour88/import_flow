"""
Unit Test: Packing List Multi-Row Tabular Extraction & Description Mapping
Verifies extraction of Item Number, Item Name (Description), Delivered Qty, Net/Gross Weights, and Volume (CBM)
"""

import pytest
from modules.smart_document_upload.extractors.purchase_order import PurchaseOrderExtractor


def test_narbutas_packing_list_tabular_extraction():
    packing_ocr_text = """
UAB Narbutas International
PACKING LIST
Delivery terms EXW
Customer: Archi Brands for Corpet and Floor Trading

Item number Configuration Item name Delivered Unit Weight netto Weight brutto Volume
PSHD041 .PA01.MA03 Mobile table with metal base, W=400, D=500, H=620 MOBI 4.00 Pcs 46.000 51.950 0.086
G2A0913 .PA01.0 Desktop, 500x400x16 4.00 vnt 8.800 10.279 0.031
G3B0079 .MA03.0 Metal base, 450x300, H=604 4.00 vnt 37.200 41.671 0.056
PSHD041 .PA01.MA03 Mobile table with metal base, W=400, D=500, H=620 MOBI 2.00 Pcs 23.000 25.975 0.043
G2A0913 .PA01.0 Desktop, 500x400x16 2.00 vnt 4.400 5.140 0.015

TOTAL:
Volume 26.059
Weight netto 1,362.314
Weight brutto 1,789.511
Number of packages 142
Number of pallets 13
"""
    extractor = PurchaseOrderExtractor()
    result = extractor.extract(packing_ocr_text, {})

    assert len(result["packing_list_items"]) == 5

    first_item = result["packing_list_items"][0]
    assert first_item["item_code"] == "PSHD041"
    assert "Mobile table with metal base" in first_item["description"]
    assert first_item["qty_pcs"] == 4.0
    assert first_item["total_net_weight_kg"] == 46.0
    assert first_item["total_gross_weight_kg"] == 51.95
    assert first_item["total_cbm"] == 0.086

    second_item = result["packing_list_items"][1]
    assert second_item["item_code"] == "G2A0913"
    assert "Desktop, 500x400x16" in second_item["description"]
    assert second_item["qty_pcs"] == 4.0
    assert second_item["total_cbm"] == 0.031

    third_item = result["packing_list_items"][2]
    assert third_item["item_code"] == "G3B0079"
    assert "Metal base" in third_item["description"]
    assert third_item["total_cbm"] == 0.056


def test_italian_gi_industrial_lista_dei_colli_extraction():
    packing_ocr_text = """
NOSTRO ORDINE / OUR ORDER R26 717
COMMESSA 24/166332
VOSTRO ORDINE / YOUR ORDER EFS/16/2026/REV0
(TYPE) (NO)
TOTAL GROSS
(KG)
TOTAL NET
(KG)
Pallet nr 1 498 208
TOTAL 1 498,0 208,0
(*) LATO DI CARICO MULETTO / FORKLIFT LOADING SIDE
(**) IMBALLO GABBIA LEGNO / WOODEN CAGE PACKAGE
LISTA DEI COLLI E DEI PESI
ECO ASSOCIATES
7 HOSNI OSMAN ST. SEFARAT DISTRICT
11471 NASR CITY, CAIRO 
EG Egitto
PACKING AND WEIGHT LIST
DESCRIZIONE
DESCRIPTION
IMBALLO / PACKING
DIMENSIONI / DIMENSIONS (mm)
4600x800x2270
"""
    extractor = PurchaseOrderExtractor()
    result = extractor.extract(packing_ocr_text, {})

    assert len(result["packing_list_items"]) == 1
    item = result["packing_list_items"][0]
    assert item["package_type"] in ("Crate", "Pallet")
    assert item["qty_pkg"] == 1.0
    assert item["length_cm"] == 460.0
    assert item["width_cm"] == 80.0
    assert item["height_cm"] == 227.0
    assert item["total_gross_weight_kg"] == 498.0
    assert item["total_net_weight_kg"] == 208.0
    assert round(item["total_cbm"], 3) == 8.354


def test_italian_gi_industrial_packing_list_800x800x460():
    packing_ocr_text = """
NOSTRO ORDINE / OUR ORDER R26 1248
COMMESSA 24/166635
VOSTRO ORDINE / YOUR ORDER ECO/57/26
(TYPE) (NO)
TOTAL GROSS
(KG)
TOTAL NET
(KG)
Pallet nr 1 37 25
0 0
0 0
0 0
0 0
0 0
0 0
0 0
0 0
0 0
0 0
0 0
TOTAL 1 37,0 25,0
(*) LATO DI CARICO MULETTO / FORKLIFT LOADING SIDE
(**) IMBALLO GABBIA LEGNO / WOODEN CAGE PACKAGE
LISTA DEI COLLI E DEI PESI
ECO ASSOCIATES
STREET 17, SARAYAT AL GHARBEYAH
 CAIRO 
EG Egitto
PACKING AND WEIGHT LIST
0
DESCRIZIONE
DESCRIPTION
IMBALLO / PACKING
DIMENSIONI / DIMENSIONS (mm)
800x800x460
0
0
0
0
0
0
0
0
0
0"""
    extractor = PurchaseOrderExtractor()
    result = extractor.extract(packing_ocr_text, {})

    assert len(result["packing_list_items"]) == 1
    item = result["packing_list_items"][0]
    assert item["package_type"] in ("Crate", "Pallet")
    assert item["qty_pkg"] == 1.0
    assert item["length_cm"] == 80.0
    assert item["width_cm"] == 80.0
    assert item["height_cm"] == 46.0
    assert item["total_gross_weight_kg"] == 37.0
    assert item["total_net_weight_kg"] == 25.0
    assert round(item["total_cbm"], 3) == 0.294


