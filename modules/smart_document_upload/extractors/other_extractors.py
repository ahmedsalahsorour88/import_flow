"""
COO Certificate Extractor
Extracts Certificate of Origin fields from COO / EUR.1 PDFs.
"""

from __future__ import annotations

from typing import Any, Dict, List

from modules.smart_document_upload.extractors.base_extractor import BaseExtractor


class COOCertificateExtractor(BaseExtractor):

    def required_fields(self) -> List[str]:
        return ["certificate_number", "origin_country", "product_description"]

    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        text = raw_text or ""
        return {
            "certificate_number": self.find_first([
                r"(?:Certificate\s+(?:No\.?|Number|#)|Cert\.?\s*No\.?)[:\s]*([A-Z0-9/\-]{4,25})",
                r"(?:CO\s+No\.?)[:\s]*([A-Z0-9/\-]{4,25})",
            ], text),
            "issue_date": self.find_first([
                r"(?:Date\s+of\s+Issue|Issue\s+Date|Date\s+Issued)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
                r"(?:Dated?)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
            ], text),
            "origin_country": self.find_first([
                r"(?:Country\s+of\s+Origin|Origin\s+Country)[:\s]+([A-Za-z\s]{3,40}?)(?:\n|,|\|)",
                r"(?:This\s+is\s+to\s+certify\s+that\s+the\s+goods?\s+originated?\s+(?:from|in))[:\s]+([A-Za-z\s]{3,40}?)(?:\n|,|\.|;)",
            ], text),
            "exporter_name": self.find_first([
                r"(?:Exporter|Shipper|Consignor|Producer)[:\s]+([A-Za-z0-9\s&,.'-]{3,80}?)(?:\n|,|\|)",
            ], text),
            "consignee_name": self.find_first([
                r"(?:Consignee|Importer|Buyer)[:\s]+([A-Za-z0-9\s&,.'-]{3,80}?)(?:\n|,|\|)",
            ], text),
            "product_description": self.find_first([
                r"(?:Description\s+of\s+Goods?|Goods?|Products?|Merchandise)[:\s]+([^\n]{10,150})",
            ], text),
            "hs_code": self.find_first([
                r"(?:HS\s*Code|Tariff\s*(?:Code|No\.?))[:\s]*([0-9]{4,10}\.?[0-9]*)",
            ], text),
            "gross_weight": self.find_first([
                r"(?:Gross\s+Weight)[:\s]+([0-9,\.]+\s*(?:kg|KG|MT|lbs?)?)",
            ], text),
            "invoice_number": self.find_first([
                r"(?:Invoice\s+(?:No\.?|#))[:\s]*([A-Z0-9/\-]{3,25})",
            ], text),
        }


class InspectionCertificateExtractor(BaseExtractor):
    """Extracts Inspection Certificate / Quality Certificate fields."""

    def required_fields(self) -> List[str]:
        return ["certificate_number", "inspection_date", "result"]

    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        text = raw_text or ""
        return {
            "certificate_number": self.find_first([
                r"(?:Certificate\s+(?:No\.?|Number|#)|Cert\.?\s*No\.?|Report\s+No\.?)[:\s]*([A-Z0-9/\-]{4,30})",
            ], text),
            "inspection_date": self.find_first([
                r"(?:Date\s+of\s+Inspection|Inspection\s+Date|Date)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
            ], text),
            "inspector_name": self.find_first([
                r"(?:Inspector|Surveyor|Inspected\s+By)[:\s]+([A-Za-z\s,.'-]{3,60}?)(?:\n|,|\|)",
            ], text),
            "inspection_company": self.find_first([
                r"(?:Inspection\s+Company|Surveying\s+Company|Issued\s+By)[:\s]+([A-Za-z0-9\s&,.'-]{3,80}?)(?:\n|,|\|)",
            ], text),
            "product_description": self.find_first([
                r"(?:Description\s+of\s+Goods?|Product|Commodity)[:\s]+([^\n]{10,150})",
            ], text),
            "quantity_inspected": self.find_first([
                r"(?:Quantity\s+Inspected|Quantity|Qty)[:\s]+([0-9,\.]+\s*(?:PCS|SETS?|MT|KG|units?)?)",
            ], text),
            "result": self.find_first([
                r"(?:Result|Conclusion|Finding|Status)[:\s]+(\b(?:PASS(?:ED)?|FAIL(?:ED)?|CONDITIONAL|APPROVED?|REJECTED?)\b)",
            ], text),
            "defects_found": self.find_first([
                r"(?:Defects?|Non[- ]?Conformanc(?:y|ies?)|Remarks?)[:\s]+([^\n]{5,200})",
            ], text),
            "remarks": self.find_first([
                r"(?:Remarks?|Notes?|Comments?)[:\s]+([^\n]{5,200})",
            ], text),
        }


class FinancialDocumentExtractor(BaseExtractor):
    """Extracts Financial Invoice / Payment document fields."""

    def required_fields(self) -> List[str]:
        return ["invoice_number", "amount", "currency"]

    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        text = raw_text or ""
        return {
            "invoice_number": self.find_first([
                r"(?:Invoice\s+(?:No\.?|#|Number))[:\s]*([A-Z0-9/\-]{3,25})",
            ], text),
            "invoice_date": self.find_first([
                r"(?:Invoice\s+Date|Date)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
            ], text),
            "supplier_name": self.find_first([
                r"(?:Supplier|Vendor|From|Beneficiary)[:\s]+([A-Za-z0-9\s&,.'-]{3,80}?)(?:\n|,|\|)",
            ], text),
            "amount": self.find_float([
                r"(?:Total\s+Amount|Grand\s+Total|Amount\s+Due|Total)[:\s]+(?:USD|EUR|EGP|GBP)?\s*([0-9,]+\.?\d*)",
            ], text),
            "currency": self.normalize_currency(text),
            "payment_terms": self.find_first([
                r"(?:Payment\s+Terms?)[:\s]+([^\n]{3,60})",
                r"\b(Net\s+\d+|T/T|L/C|CAD|Advance)\b",
            ], text),
            "bank_name": self.find_first([
                r"(?:Bank\s+Name|Bank)[:\s]+([A-Za-z0-9\s&,.'-]{3,60}?)(?:\n|,|\|)",
            ], text),
            "swift_code": self.find_first([
                r"(?:SWIFT|BIC)[:\s]*([A-Z]{4}[A-Z]{2}[A-Z0-9]{2}(?:[A-Z0-9]{3})?)",
            ], text),
            "iban": self.find_first([
                r"(?:IBAN)[:\s]*([A-Z]{2}[0-9]{2}[A-Z0-9]{4,34})",
            ], text),
            "due_date": self.find_first([
                r"(?:Due\s+Date|Payment\s+Due)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
            ], text),
        }
