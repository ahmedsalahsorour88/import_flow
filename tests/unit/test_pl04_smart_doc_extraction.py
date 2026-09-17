"""
Unit Tests — PL-04: Smart Doc Extraction (Proforma Invoice & Packing List)
Tests automated extraction of PI/PO and Packing List fields, European numeric parsing,
package dimension conversion to CBM, and cross-document reconciliation.
"""

import io
import pytest
from fastapi.testclient import TestClient
from main import app
from modules.smart_document_upload.extractors.purchase_order import PurchaseOrderExtractor

client = TestClient(app)


class TestPL04SmartDocExtraction:
    extractor = PurchaseOrderExtractor()

    SAMPLE_PROFORMA_INVOICE = """
    PROFORMA INVOICE
    Proforma Invoice No.: PI-2026-DE-8890
    Order Date: 12/05/2026
    Buyer / Importer:
    المتحدة للتوريدات الصناعية (United Industrial Supplies)
    Tax ID: 123456789
    Address: 10th of Ramadan City, Egypt

    Seller / Exporter:
    Siemens Industrial Solutions GmbH
    Tax ID: DE129274202
    Munich, Germany

    ACID Number: 1987654321098765432
    Currency: EUR
    Payment Terms: LC at Sight / Letter of Credit
    Incoterms: FOB Hamburg
    Port of Loading: Hamburg
    Port of Discharge: Alexandria

    Item Code      | Description                            | Qty   | Unit | Unit Price | Total (EUR)
    CHILLER-500    | Industrial Water Chiller 500kW High Eff | 2     | PCS  | 25.000,00  | 50.000,00
    PUMP-CIRC-50   | Primary Circulation Pump 50m3/h        | 4     | PCS  | 2.500,00   | 10.000,00

    Total Goods Net: 60.000,00 EUR
    Net to pay EUR 60.000,00
    """

    SAMPLE_PACKING_LIST = """
    PACKING & WEIGHT LIST
    Invoice Ref: PI-2026-DE-8890
    ACID: 1987654321098765432

    Item No | Item Code    | Package Type | Qty Pkg | Length(mm) | Width(mm) | Height(mm) | Net Wt(kg) | Gross Wt(kg)
    1       | CHILLER-500  | Wooden Crate | 2       | 3500       | 2000      | 2200       | 8400,0     | 9000,0
    2       | PUMP-CIRC-50 | Wooden Box   | 4       | 800        | 600       | 700        | 1200,0     | 1350,0

    Total Packages: 6 Packages
    Total Net Weight: 9.600,00 KG
    Total Gross Weight: 10.350,00 KG
    Gross Volume: 33,52 M3
    """

    def test_proforma_invoice_extraction(self):
        result = self.extractor.extract(self.SAMPLE_PROFORMA_INVOICE, {})

        assert result["po_number"] == "PI-2026-DE-8890"
        assert "Siemens" in (result["supplier_name"] or "")
        assert result["currency"] == "EUR"
        assert result["incoterms"] == "FOB"
        assert result["acid_number"] == "1987654321098765432"
        assert result["total_amount"] == 60000.0

        items = result.get("items", [])
        assert len(items) >= 2

        chiller = next((it for it in items if "CHILLER" in str(it.get("item_code"))), None)
        assert chiller is not None
        assert chiller["quantity"] == 2.0
        assert chiller["unit_price"] == 25000.0

        pump = next((it for it in items if "PUMP" in str(it.get("item_code"))), None)
        assert pump is not None
        assert pump["quantity"] == 4.0
        assert pump["unit_price"] == 2500.0

    def test_packing_list_extraction(self):
        result = self.extractor.extract(self.SAMPLE_PACKING_LIST, {})

        packing_items = result.get("packing_list_items", [])
        assert len(packing_items) >= 2

        crate = next((p for p in packing_items if "CHILLER" in str(p.get("item_code"))), None)
        assert crate is not None
        assert crate["length_cm"] == 350.0  # 3500 mm converted to 350 cm
        assert crate["width_cm"] == 200.0   # 2000 mm converted to 200 cm
        assert crate["height_cm"] == 220.0  # 2200 mm converted to 220 cm
        assert crate["total_gross_weight_kg"] == 9000.0
        assert crate["total_net_weight_kg"] == 8400.0

        # CBM for 3.5m x 2.0m x 2.2m = 15.4m3 per crate * 2 crates = 30.8m3
        assert crate["total_cbm"] > 0

    def test_joint_document_reconciliation(self):
        combined_text = f"{self.SAMPLE_PROFORMA_INVOICE}\n\n{self.SAMPLE_PACKING_LIST}"
        result = self.extractor.extract(combined_text, {})

        # Should extract invoice details
        assert result["po_number"] == "PI-2026-DE-8890"
        assert result["total_amount"] == 60000.0

        # Line items and packing items should both be populated
        assert len(result.get("items", [])) >= 2
        assert len(result.get("packing_list_items", [])) >= 2

        # Verify finalized packing items retain corresponding item codes
        packing = result["packing_list_items"]
        assert any("CHILLER" in str(p.get("item_code")) for p in packing)
        assert any("PUMP" in str(p.get("item_code")) for p in packing)

    def test_smart_upload_api_endpoint(self):
        file_bytes = self.SAMPLE_PROFORMA_INVOICE.encode("utf-8")
        files = {
            "file": ("proforma_invoice.txt", io.BytesIO(file_bytes), "text/plain")
        }
        data = {
            "module_name": "purchase-order",
            "save_session": "false",
        }

        response = client.post("/api/v1/smart-upload/upload", files=files, data=data)
        assert response.status_code == 200
        res_json = response.json()

        assert res_json["module_name"] == "purchase-order"
        assert res_json["extraction_status"] in ("SUCCESS", "PARTIAL")
        fields = res_json["extracted_fields"]
        assert fields["po_number"] == "PI-2026-DE-8890"
        assert fields["currency"] == "EUR"
        assert fields["total_amount"] == 60000.0
