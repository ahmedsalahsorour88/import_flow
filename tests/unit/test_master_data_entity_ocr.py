"""
Unit tests for Master Data Entity Extractor & OCR Line Grouping
"""

import unittest
from modules.smart_document_upload.extractors.master_data_entity import MasterDataEntityExtractor
from modules.import_documentation.service import _group_ocr_boxes_into_lines


class TestMasterDataEntityOCR(unittest.TestCase):

    def test_line_grouping_same_y(self):
        ocr_boxes = [
            ([[10, 40], [50, 40], [50, 60], [10, 60]], "Suzhou", 0.99),
            ([[55, 40], [100, 40], [100, 60], [55, 60]], "Yuheng", 0.99),
            ([[105, 41], [150, 41], [150, 61], [105, 61]], "Textile", 0.99),
            ([[155, 39], [190, 39], [190, 59], [155, 59]], "Co.,", 0.99),
            ([[195, 42], [220, 42], [220, 62], [195, 62]], "Ltd.", 0.99),
        ]
        lines = _group_ocr_boxes_into_lines(ocr_boxes)
        self.assertEqual(len(lines), 1)
        self.assertEqual(lines[0], "Suzhou Yuheng Textile Co., Ltd.")

    def test_supplier_entity_extraction(self):
        raw_text = """Suzhou Yuheng Textile Co., Ltd.
ADD: No.16 Kangsheng Road, Zhitang Town, Changshu City, Suzhou City China, Postcode 215500
TEL: Tel:+86 615962900581 FAX:+86-51252558515
E-mail: rodrigo@yhacoustic.com URL: http://www.yhacoustic.com"""
        extractor = MasterDataEntityExtractor()
        res = extractor.extract(raw_text, module_name="supplier-entity")

        self.assertEqual(res["company_name"], "Suzhou Yuheng Textile Co., Ltd.")
        self.assertEqual(res["country_code"], "CN")
        self.assertEqual(res["email"], "rodrigo@yhacoustic.com")
        self.assertIsNone(res["swift_code"])  # Should not falsely match Changshu as SWIFT

    def test_importer_entity_extraction(self):
        raw_text = """Commercial Invoice No. INV-2026-001
Shipper: Suzhou Yuheng Textile Co., Ltd.
Consignee: ECO ASSOCIATES for Trading and Contracting, Cairo, Egypt
Importer Card: 83086
VAT Registration: 200183044"""
        extractor = MasterDataEntityExtractor()
        res = extractor.extract(raw_text, module_name="importer-entity")

        self.assertEqual(res["company_name"], "ECO ASSOCIATES for Trading and Contracting, Cairo, Egypt")
        self.assertEqual(res["importer_id"], "83086")
        self.assertEqual(res["vat_tax_id"], "200183044")


if __name__ == "__main__":
    unittest.main()
