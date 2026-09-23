import pytest
from modules.import_documentation.schemas import DocumentExtractRequest
import modules.import_documentation.service as service
from modules.import_documentation.ai_document_parser import (
    extract_agadir_gafta_form_a_coo_text,
    extract_psi_certificate_text,
    extract_coa_certificate_text,
    extract_inspection_voc_certificate_text,
)


class TestInspectionAndCertExtractors:
    def test_extract_psi_certificate(self):
        sample_psi = """
        SGS PRE-SHIPMENT INSPECTION CERTIFICATE
        PSI Report No: SGS-PSI-EG-2026-9912
        Date of Inspection: 15/08/2026
        Inspected By: Zhang Wei (Senior Inspector)
        Place of Inspection: Suzhou Industrial Park, China
        Importer: SCAS FOR CONSTRUCTION AND FINISHING
        Exporter: Suzhou Yuheng Textile Co.,Ltd
        ACID Number: 5281534391023010013
        Commercial Invoice No.: YH20260730-6
        Quantity Inspected: 720
        Inspection Result: PASSED / CONFORMING
        Seal No: EG998877
        """
        data = extract_psi_certificate_text(sample_psi)
        assert data["inspection_agency"] == "SGS"
        assert data["certificate_number"] == "SGS-PSI-EG-2026-9912"
        assert data["acid_number"] == "5281534391023010013"
        assert data["invoice_number"] == "YH20260730-6"
        assert data["is_passed"] is True
        assert data["quantity_inspected"] == 720
        assert "SCAS" in data["importer_name"]
        assert "Suzhou" in data["exporter_name"]

    def test_extract_coa_certificate(self):
        sample_coa = """
        CERTIFICATE OF ANALYSIS (COA)
        Laboratory: Eurofins Central Testing Services
        COA No: COA-2026-PET-8841
        Test Date: 12/08/2026
        Product Name: Acoustic Panels PET 24mm
        Batch No: BATCH-YH2026-08
        ACID: 5281534391023010013
        Invoice No: YH20260730-6
        Test Result: CONFORMING TO SPECIFICATIONS
        """
        data = extract_coa_certificate_text(sample_coa)
        assert "Eurofins" in data["laboratory_name"]
        assert data["certificate_number"] == "COA-2026-PET-8841"
        assert data["product_name"] == "Acoustic Panels PET 24mm"
        assert data["batch_lot_number"] == "BATCH-YH2026-08"
        assert data["is_conforming"] is True
        assert data["acid_number"] == "5281534391023010013"

    def test_extract_agadir_agreement_coo(self):
        sample_agadir = """
        AGADIR AGREEMENT CERTIFICATE OF ORIGIN
        رقم الشهادة: AG-MA-2026-0044
        المصدر: Casablanca Textile Industries SA
        المستورد: Egyptian Trading Company LLC
        بلد المنشأ: Morocco
        ACID: 1987654321098765432
        رقم الفاتورة: INV-MA-9921
        البند الجمركي: 56022900
        الوزن الإجمالي: 4,500.00 KG
        """
        data = extract_agadir_gafta_form_a_coo_text(sample_agadir, "AGADIR")
        assert data["certificate_number"] == "AG-MA-2026-0044"
        assert data["country_of_origin"] == "Morocco"
        assert data["acid_number"] == "1987654321098765432"
        assert data["is_preferential_exemption_eligible"] is True

    def test_extract_gafta_coo(self):
        sample_gafta = """
        شهادة منشأ اتفاقية تيسير وتنمية التبادل التجاري بين الدول العربية (منطقة التجارة الحرة العربية الكبرى GAFTA)
        Certificate No: GAFTA-JO-2026-118
        المصدر: Amman Modern Manufacturing Co.
        المستورد: SCAS For Construction
        بلد المنشأ: Jordan
        ACID: 1987654321098765432
        رقم الفاتورة: JO-8812
        """
        data = extract_agadir_gafta_form_a_coo_text(sample_gafta, "GAFTA")
        assert data["certificate_number"] == "GAFTA-JO-2026-118"
        assert data["country_of_origin"] == "Jordan"
        assert data["preferential_agreement"] == "GAFTA"

    def test_extract_document_service_routing(self):
        req_psi = DocumentExtractRequest(
            document_type="PSI",
            raw_text="PSI Report No: PSI-TEST-01 ACID: 1234567890123456789 Inspection Result: PASSED",
        )
        res_psi = service.extract_document_service(req_psi)
        assert res_psi.extracted_data["certificate_number"] == "PSI-TEST-01"
        assert res_psi.extracted_data["acid_number"] == "1234567890123456789"

        req_coa = DocumentExtractRequest(
            document_type="COA",
            raw_text="Certificate of Analysis No: COA-TEST-02 ACID: 1234567890123456789 Result: CONFORMING",
        )
        res_coa = service.extract_document_service(req_coa)
        assert res_coa.extracted_data["certificate_number"] == "COA-TEST-02"
        assert res_coa.extracted_data["is_conforming"] is True
