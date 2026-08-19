"""
Unit Tests — Smart Document Upload Module
Tests parsers, extractors, validators, and service logic.
"""

import pytest
from unittest.mock import MagicMock, patch
from modules.smart_document_upload.extractors.purchase_order import PurchaseOrderExtractor
from modules.smart_document_upload.extractors.cargo_shipping import CargoShippingExtractor
from modules.smart_document_upload.extractors.customs_clearance import CustomsClearanceExtractor
from modules.smart_document_upload.extractors.import_file import ImportFileExtractor
from modules.smart_document_upload.extractors.freight_quotation import FreightQuotationExtractor
from modules.smart_document_upload.extractors.freight_booking import FreightBookingExtractor
from modules.smart_document_upload.validators import (
    validate_module_name,
    validate_file_size,
    SUPPORTED_MODULES,
)
from fastapi import HTTPException


# ─────────────────────────────────────────────────────────────────────────────
# Purchase Order Extractor Tests
# ─────────────────────────────────────────────────────────────────────────────

class TestPurchaseOrderExtractor:
    extractor = PurchaseOrderExtractor()

    SAMPLE_PO_TEXT = """
    Purchase Order No: PO-2024-00123
    Date: 15/01/2024
    Supplier: ABC Trading Co. Ltd
    Payment Terms: T/T 30 days after BL date
    Incoterms: FOB Shanghai
    Port of Loading: Shanghai
    Currency: USD

    Description                     | Qty  | Unit | Unit Price | Total
    Steel Pipes 2 inch               | 500  | PCS  | 45.00      | 22,500.00
    Steel Fittings                   | 200  | PCS  | 12.50      | 2,500.00

    Grand Total: USD 25,000.00
    """

    def test_po_number_extraction(self):
        result = self.extractor.extract(self.SAMPLE_PO_TEXT, {})
        assert result["po_number"] == "PO-2024-00123"

    def test_supplier_extraction(self):
        result = self.extractor.extract(self.SAMPLE_PO_TEXT, {})
        assert result["supplier_name"] is not None
        assert "ABC" in result["supplier_name"]

    def test_currency_extraction(self):
        result = self.extractor.extract(self.SAMPLE_PO_TEXT, {})
        assert result["currency"] == "USD"

    def test_incoterms_extraction(self):
        result = self.extractor.extract(self.SAMPLE_PO_TEXT, {})
        assert result["incoterms"] == "FOB"

    def test_total_amount_extraction(self):
        result = self.extractor.extract(self.SAMPLE_PO_TEXT, {})
        assert result["total_amount"] == 25000.0

    def test_line_items_extraction(self):
        result = self.extractor.extract(self.SAMPLE_PO_TEXT, {})
        items = result.get("items", [])
        assert len(items) >= 1

    def test_confidence_score(self):
        result = self.extractor.extract(self.SAMPLE_PO_TEXT, {})
        confidence = self.extractor.compute_confidence(result)
        assert 0.0 <= confidence <= 1.0
        assert confidence > 0.5  # should find most required fields

    def test_empty_text_returns_dict(self):
        result = self.extractor.extract("", {})
        assert isinstance(result, dict)

    def test_required_fields_defined(self):
        assert len(self.extractor.required_fields()) > 0

    def test_missing_fields_for_empty_doc(self):
        result = self.extractor.extract("", {})
        missing = self.extractor.missing_required(result)
        assert len(missing) > 0


# ─────────────────────────────────────────────────────────────────────────────
# Cargo Shipping Extractor Tests
# ─────────────────────────────────────────────────────────────────────────────

class TestCargoShippingExtractor:
    extractor = CargoShippingExtractor()

    SAMPLE_BL_TEXT = """
    Bill of Lading No: MSC1234567
    Vessel: MSC MAGNIFICA
    Voyage: 001W
    Port of Loading: Shanghai, China
    Port of Discharge: Alexandria, Egypt
    ETD: 20/01/2024
    ETA: 15/02/2024
    Shipper: ABC Factory Ltd
    Consignee: Egyptian Import Co.
    Gross Weight: 25,000 KG
    Measurement: 45.5 CBM
    Container: MSCU1234567 / Seal: EG123456 / 40HC
    """

    def test_fallback_extraction_bl_number(self):
        # Test the fallback extraction when ai_document_parser is not available
        result = self.extractor._fallback_extract(self.SAMPLE_BL_TEXT)
        assert result.get("bl_number") is not None

    def test_required_fields_defined(self):
        assert "bl_number" in self.extractor.required_fields()
        assert "vessel_name" in self.extractor.required_fields()

    def test_parse_float_helper(self):
        assert self.extractor._parse_float("25,000") == 25000.0
        assert self.extractor._parse_float(None) is None
        assert self.extractor._parse_float("N/A") is None

    def test_containers_extraction_from_dict(self):
        bl_fields = {
            "containers": [
                {"container_no": "MSCU1234567", "seal_no": "EG123456", "type": "40HC", "gross_weight": "10000"}
            ]
        }
        containers = self.extractor._extract_containers(bl_fields)
        assert len(containers) == 1
        assert containers[0]["container_no"] == "MSCU1234567"
        assert containers[0]["gross_weight_kg"] == 10000.0


# ─────────────────────────────────────────────────────────────────────────────
# Customs Clearance Extractor Tests
# ─────────────────────────────────────────────────────────────────────────────

class TestCustomsClearanceExtractor:
    extractor = CustomsClearanceExtractor()

    SAMPLE_CUSTOMS_TEXT = """
    بيان رقم: 2024001234
    تاريخ الإقرار: 20/02/2024
    HS Code: 7304.19.00
    بلد المنشأ: China
    القيمة الجمركية: 623,000
    سعر الصرف: 30.95
    ضريبة الوارد: 62,300
    ضريبة القيمة المضافة: 95,942
    إجمالي: 165,801.50
    """

    def test_declaration_no_extraction(self):
        result = self.extractor.extract(self.SAMPLE_CUSTOMS_TEXT, {})
        assert result["declaration_no"] == "2024001234"

    def test_hs_code_extraction(self):
        result = self.extractor.extract(self.SAMPLE_CUSTOMS_TEXT, {})
        assert result["hs_code"] is not None
        assert "7304" in result["hs_code"]

    def test_customs_value_extraction(self):
        result = self.extractor.extract(self.SAMPLE_CUSTOMS_TEXT, {})
        assert result["customs_value_egp"] == 623000.0

    def test_vat_extraction(self):
        result = self.extractor.extract(self.SAMPLE_CUSTOMS_TEXT, {})
        assert result["vat_amount"] == 95942.0

    def test_total_taxes_extraction(self):
        result = self.extractor.extract(self.SAMPLE_CUSTOMS_TEXT, {})
        assert result["total_taxes"] == 165801.50

    def test_required_fields(self):
        assert "declaration_no" in self.extractor.required_fields()
        assert "total_taxes" in self.extractor.required_fields()


# ─────────────────────────────────────────────────────────────────────────────
# Import File Extractor Tests
# ─────────────────────────────────────────────────────────────────────────────

class TestImportFileExtractor:
    extractor = ImportFileExtractor()

    SAMPLE_INVOICE_TEXT = """
    Commercial Invoice No: INV-2024-0099
    Invoice Date: 10/01/2024
    Seller: Shanghai Steel Corp Ltd
    Country of Origin: China
    Port of Loading: Shanghai
    Port of Discharge: Alexandria
    Incoterms: FOB
    Currency: USD
    Description of Goods: Steel Pipes and Fittings
    HS Code: 7304.19
    Total Amount: 25,000.00
    """

    def test_invoice_number(self):
        result = self.extractor.extract(self.SAMPLE_INVOICE_TEXT, {})
        assert result["invoice_number"] == "INV-2024-0099"

    def test_origin_country(self):
        result = self.extractor.extract(self.SAMPLE_INVOICE_TEXT, {})
        assert result["origin_country"] is not None

    def test_hs_code(self):
        result = self.extractor.extract(self.SAMPLE_INVOICE_TEXT, {})
        assert result["hs_code"] is not None
        assert "7304" in result["hs_code"]

    def test_invoice_value(self):
        result = self.extractor.extract(self.SAMPLE_INVOICE_TEXT, {})
        assert result["invoice_value"] == 25000.0

    def test_incoterms(self):
        result = self.extractor.extract(self.SAMPLE_INVOICE_TEXT, {})
        assert result["incoterms"] == "FOB"


# ─────────────────────────────────────────────────────────────────────────────
# Freight Quotation Extractor Tests
# ─────────────────────────────────────────────────────────────────────────────

class TestFreightQuotationExtractor:
    extractor = FreightQuotationExtractor()

    SAMPLE_QUOTE_TEXT = """
    Freight Rate Quote
    Carrier: MSC Mediterranean Shipping
    Origin: Shanghai
    Destination: Alexandria
    Container: 40HC
    Freight Rate: USD 2,500
    Transit Time: 28 days
    Valid Until: 28/02/2024
    Free Days Demurrage: 14
    Free Days Detention: 7
    """

    def test_carrier_extraction(self):
        result = self.extractor.extract(self.SAMPLE_QUOTE_TEXT, {})
        assert result["carrier_name"] is not None

    def test_freight_rate_extraction(self):
        result = self.extractor.extract(self.SAMPLE_QUOTE_TEXT, {})
        assert result["freight_rate"] == 2500.0

    def test_transit_days_extraction(self):
        result = self.extractor.extract(self.SAMPLE_QUOTE_TEXT, {})
        assert result["transit_days"] == 28

    def test_free_days_demurrage(self):
        result = self.extractor.extract(self.SAMPLE_QUOTE_TEXT, {})
        assert result["free_days_demurrage"] == 14

    def test_container_type(self):
        result = self.extractor.extract(self.SAMPLE_QUOTE_TEXT, {})
        assert result["container_type"] == "40HC"

    def test_real_world_example_1_whl_multi_container(self):
        example_1_text = """
        Dear  Ahmed ,
        Please kindly find the estimated cost as below:
        Local charges: Approx. USD 820/20GP
        Ocean freight:
        •	WHL: USD 5800/20GP  ETD:8.28 
        o	Route: Shanghai – El Dekheila 
        o	Service: Direct 
        o	Transit time: 29 days 
        o	Free time: 21 days
        Local charges: Approx. USD 880/40HQ
        Ocean freight:
        •	WHL: USD 6,700/40HQ  ETD:8.28 
        o	Route: Shanghai – El Dekheila 
        o	Service: Direct 
        o	Transit time: 29 days 
        o	Free time: 21 days
        """
        result = self.extractor.extract(example_1_text, {})
        assert "Wan Hai" in result["carrier_name"] or "WHL" in result["carrier_name"]
        assert "Shanghai" in result["origin_port"]
        assert "Dekheila" in result["destination_port"]
        assert result["free_days_demurrage"] == 21
        assert result["transit_days"] == 29
        assert result["is_direct"] is True
        assert len(result["rate_options"]) >= 2

        # Check 20GP option
        opt20 = next(o for o in result["rate_options"] if o["container_type"] == "20GP")
        assert opt20["ocean_freight"] == 5800.0
        assert opt20["local_charges"] == 820.0
        assert opt20["total_estimated_cost"] == 6620.0
        assert opt20["free_time_days"] == 21

        # Check 40HQ option
        opt40 = next(o for o in result["rate_options"] if o["container_type"] == "40HQ")
        assert opt40["ocean_freight"] == 6700.0
        assert opt40["local_charges"] == 880.0
        assert opt40["total_estimated_cost"] == 7580.0
        assert opt40["free_time_days"] == 21

    def test_real_world_example_2_surcharges_and_exw(self):
        example_2_text = """
        Dear Ahmed, 

        Please find below our best rate based on your below request : 

        O/F rate: USD 6195/20’DC (INCL OWS ) 
                          USD 7560/40’HQ
        21 days FT
        1st vessel : 1-SEP
        TT: direct, about 28 days
        cancel fee: $100/cntr

        Ex-work charges : USD 630\\20’DC
                                         USD 770\\40’DC

        Thanks with my best regards.
        """
        result = self.extractor.extract(example_2_text, {})
        assert result["free_days_demurrage"] == 21
        assert result["transit_days"] == 28
        assert result["is_direct"] is True
        assert result["cancel_fee"] == 100.0
        assert len(result["rate_options"]) >= 2

        opt20 = next(o for o in result["rate_options"] if o["container_type"] == "20GP")
        assert opt20["ocean_freight"] == 6195.0
        assert opt20["local_charges"] == 630.0
        assert opt20["total_estimated_cost"] == 6825.0
        assert "OWS" in (opt20["notes"] or "")

        opt40 = next(o for o in result["rate_options"] if o["container_type"] == "40HQ")
        assert opt40["ocean_freight"] == 7560.0
        assert opt40["local_charges"] == 770.0
        assert opt40["total_estimated_cost"] == 8330.0

    def test_real_world_example_3_multi_carrier_whl_and_yml(self):
        example_3_text = """
        Dear Ahmed,
        Good day,

        Kindly check the rates below :

        EXW SHANGHAI-DEK
        O/F: USD8280/40HQ BY WHL
        Included EXW FEE
        Included TRUCK: USD440/40HQ+LOCAL: USD390/40HQ+CUSTOMS:USD 50/BILL(BASE EXPORT LICENSE
        Free time has 21days
        ETD:28/AUG
        T/T: About 27 day, DIRECT
         


        EXW SHANGHAI-DEK
        O/F: USD6180/40HQ BY YML
        EXW FEE:(
        TRUCK: USD440/40HQ+LOCAL: USD390/40HQ+CUSTOMS:USD 50/BILL(BASE EXPORT LICENSE
        Free time has 21days
        ETD:27/AUG
        T/T: About 48 day, INDIRECT
        """
        result = self.extractor.extract(example_3_text, {})
        assert result["incoterm"] == "EXW"
        assert len(result["rate_options"]) >= 2

        whl_opt = next(o for o in result["rate_options"] if "WHL" in o["carrier_name"])
        assert whl_opt["ocean_freight"] == 8280.0
        assert whl_opt["transit_days"] == 27
        assert whl_opt["is_direct"] is True
        assert whl_opt["free_time_days"] == 21

        yml_opt = next(o for o in result["rate_options"] if "YML" in o["carrier_name"])
        assert yml_opt["ocean_freight"] == 6180.0
        assert yml_opt["transit_days"] == 48
        assert yml_opt["is_direct"] is False
        assert yml_opt["free_time_days"] == 21



# ─────────────────────────────────────────────────────────────────────────────
# Freight Booking Extractor Tests
# ─────────────────────────────────────────────────────────────────────────────

class TestFreightBookingExtractor:
    extractor = FreightBookingExtractor()

    SAMPLE_BOOKING_TEXT = """
    Booking Confirmation
    Booking No: MSC123456789
    Carrier: MSC
    Vessel: MSC MAGNIFICA
    Voyage: 001W
    Port of Loading: Shanghai
    Port of Discharge: Alexandria
    ETD: 20/01/2024
    ETA: 15/02/2024
    SI Cut-Off: 15/01/2024
    VGM Cut-Off: 14/01/2024
    Container: 1 x 40HC
    """

    def test_booking_number(self):
        result = self.extractor.extract(self.SAMPLE_BOOKING_TEXT, {})
        assert result["booking_number"] == "MSC123456789"

    def test_vessel_name(self):
        result = self.extractor.extract(self.SAMPLE_BOOKING_TEXT, {})
        assert result["vessel_name"] is not None

    def test_etd(self):
        result = self.extractor.extract(self.SAMPLE_BOOKING_TEXT, {})
        assert result["etd"] is not None

    def test_containers_count(self):
        result = self.extractor.extract(self.SAMPLE_BOOKING_TEXT, {})
        assert result["containers_count"] == 1


# ─────────────────────────────────────────────────────────────────────────────
# Validators Tests
# ─────────────────────────────────────────────────────────────────────────────

class TestValidators:

    def test_valid_module_passes(self):
        for module in SUPPORTED_MODULES:
            validate_module_name(module)  # should not raise

    def test_invalid_module_raises(self):
        with pytest.raises(HTTPException) as exc_info:
            validate_module_name("nonexistent-module")
        assert exc_info.value.status_code == 422

    def test_file_size_within_limit(self):
        content = b"x" * (5 * 1024 * 1024)  # 5 MB
        validate_file_size(content, "test.pdf")  # should not raise

    def test_file_size_exceeds_limit(self):
        content = b"x" * (21 * 1024 * 1024)  # 21 MB
        with pytest.raises(HTTPException) as exc_info:
            validate_file_size(content, "large_file.pdf")
        assert exc_info.value.status_code == 413


# ─────────────────────────────────────────────────────────────────────────────
# Base Extractor Helper Tests
# ─────────────────────────────────────────────────────────────────────────────

class TestBaseExtractorHelpers:
    extractor = ImportFileExtractor()  # concrete instance for testing base methods

    def test_find_first_returns_match(self):
        text = "Invoice No: INV-123"
        result = self.extractor.find_first([r"Invoice\s+No[:\s]+([A-Z0-9\-]+)"], text)
        assert result == "INV-123"

    def test_find_first_returns_none_on_no_match(self):
        result = self.extractor.find_first([r"NOPATTERN(\d+)"], "nothing here")
        assert result is None

    def test_find_float_with_comma(self):
        result = self.extractor.find_float([r"Total[:\s]+([0-9,]+\.?\d*)"], "Total: 25,000.50")
        assert result == 25000.50

    def test_normalize_currency(self):
        assert self.extractor.normalize_currency("Amount: USD 5000") == "USD"
        assert self.extractor.normalize_currency("العملة: EGP") == "EGP"
        assert self.extractor.normalize_currency("no currency here") is None

    def test_normalize_incoterms(self):
        assert self.extractor.normalize_incoterms("Terms: FOB Shanghai") == "FOB"
        assert self.extractor.normalize_incoterms("CIF Alexandria") == "CIF"
        assert self.extractor.normalize_incoterms("no terms") is None

    def test_normalize_container_type_40hc(self):
        assert self.extractor.normalize_container_type("40HC container") == "40HC"
        assert self.extractor.normalize_container_type("40'HQ") == "40HC"

    def test_normalize_container_type_20gp(self):
        assert self.extractor.normalize_container_type("20ft container") == "20GP"
