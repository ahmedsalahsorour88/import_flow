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
