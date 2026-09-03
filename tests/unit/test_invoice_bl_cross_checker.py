import pytest
from modules.smart_document_upload.cross_checker import cross_check_invoice_vs_bl
from modules.smart_document_upload.service import cross_check_invoice_and_bl_service


class TestInvoiceBLCrossChecker:
    def test_compliant_match(self):
        invoice = {
            "invoice_number": "INV-1001",
            "acid_number": "1987654321098765432",
            "importer_tax_id": "200345678",
            "supplier_name": "Shanghai Machinery Co., Ltd.",
            "importer_name": "Egyptian National Industrial Supply LLC",
            "loading_port": "Shanghai Port",
            "discharge_port": "Alexandria Port",
            "incoterms": "FOB",
            "currency": "USD",
            "total_gross_weight_kg": 5000.0,
            "total_packages_count": 100,
        }
        bl = {
            "bl_number": "MEDU998877",
            "carrier_name": "MSC",
            "acid_number": "1987654321098765432",
            "importer_tax_id": "200345678",
            "shipper": "Shanghai Machinery Co., Ltd.",
            "consignee": "Egyptian National Industrial Supply LLC",
            "loading_port": "Shanghai Port",
            "discharge_port": "Alexandria Port",
            "freight_payment_term": "FREIGHT_COLLECT",
            "total_gross_weight_kg": 5050.0,  # 1% variance, within 3% tolerance
            "total_packages_count": 100,
            "package_type": "Pallets",
            "containers": [{"container_no": "MSCU1234567", "seal_no": "EG999"}],
        }

        result = cross_check_invoice_vs_bl(invoice, bl, weight_tolerance_pct=3.0)

        assert result["verdict"] in ["COMPLIANT", "WARNINGS_DETECTED"]
        assert result["critical_errors_count"] == 0
        assert result["compliance_score"] >= 90.0
        assert "URGENT" in result["correction_notice_en"]
        assert "عاجل" in result["correction_notice_ar"]

    def test_critical_acid_mismatch(self):
        invoice = {
            "invoice_number": "INV-1002",
            "acid_number": "1987654321098765432",
        }
        bl = {
            "bl_number": "MEDU112233",
            "acid_number": "1987654321098765000",  # Mismatch in last 3 digits
        }

        result = cross_check_invoice_vs_bl(invoice, bl)

        assert result["verdict"] == "CRITICAL_MISMATCH"
        assert result["critical_errors_count"] >= 1
        assert any("ACID" in err for err in result["critical_errors"])

    def test_weight_variance_exceeded(self):
        invoice = {
            "invoice_number": "INV-1003",
            "acid_number": "1987654321098765432",
            "total_gross_weight_kg": 10000.0,
            "incoterms": "CIF",
        }
        bl = {
            "bl_number": "CMAU445566",
            "acid_number": "1987654321098765432",
            "total_gross_weight_kg": 11500.0,  # 15% variance! Exceeds 3%
            "freight_payment_term": "FREIGHT_PREPAID",
        }

        result = cross_check_invoice_vs_bl(invoice, bl, weight_tolerance_pct=3.0)

        assert result["verdict"] == "CRITICAL_MISMATCH"
        assert any("الوزن" in err for err in result["critical_errors"])

    def test_incoterm_freight_conflict(self):
        invoice = {
            "invoice_number": "INV-1004",
            "acid_number": "1987654321098765432",
            "incoterms": "FOB",  # FOB must be Freight Collect
        }
        bl = {
            "bl_number": "HAPAG778899",
            "acid_number": "1987654321098765432",
            "freight_payment_term": "FREIGHT_PREPAID",  # Conflict!
        }

        result = cross_check_invoice_vs_bl(invoice, bl)

        assert result["verdict"] == "CRITICAL_MISMATCH"
        assert any("النولون" in err or "Incoterm" in err or "شروط الشحن" in err for err in result["critical_errors"])
