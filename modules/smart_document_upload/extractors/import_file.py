"""
Import File Extractor
Extracts fields from Commercial Invoices to pre-fill Import File data.
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional

from modules.smart_document_upload.extractors.base_extractor import BaseExtractor


class ImportFileExtractor(BaseExtractor):

    def required_fields(self) -> List[str]:
        return ["commodity_description", "origin_country", "currency", "invoice_value"]

    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        text = raw_text or ""

        result: Dict[str, Any] = {
            "invoice_number": self.find_first([
                r"(?:Invoice\s+No\.?|Invoice\s+#|INV)[:\s]*([A-Z0-9/\-]{3,25})",
                r"(?:Commercial\s+Invoice)[:\s#]*([A-Z0-9/\-]{3,25})",
            ], text),
            "invoice_date": self.find_first([
                r"(?:Invoice\s+Date|Issue\s+Date|Date)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
                r"(?:Date)[:\s]+(\d{4}-\d{2}-\d{2})",
            ], text),
            "supplier_name": self.find_first([
                r"(?:Seller|Supplier|Exporter|From|Beneficiary)[:\s]+([A-Za-z0-9\s&,.'-]{3,60}?)(?:\n|,|\|)",
                r"(?:Issued\s+by)[:\s]+([A-Za-z0-9\s&,.'-]{3,60}?)(?:\n|,|\|)",
            ], text),
            "commodity_description": self.find_first([
                r"(?:Description\s+of\s+Goods?|Commodity|Goods?)[:\s]+([^\n]{10,120})",
                r"(?:Product\s+Description)[:\s]+([^\n]{10,120})",
            ], text),
            "hs_code": self.find_first([
                r"(?:HS\s*Code|Tariff\s*Code|H\.S\.)[:\s]*([0-9]{4,10}\.?[0-9]*)",
            ], text),
            "origin_country": self.find_first([
                r"(?:Country\s+of\s+Origin|Origin)[:\s]+([A-Za-z\s]{3,40}?)(?:\n|,|\|)",
                r"(?:Made\s+in)[:\s]+([A-Za-z\s]{3,30})",
            ], text),
            "loading_port": self.find_first([
                r"(?:Port\s+of\s+Loading|POL|Departure\s+Port)[:\s]+([A-Za-z\s,]{3,50}?)(?:\n|,|\|)",
            ], text),
            "discharge_port": self.find_first([
                r"(?:Port\s+of\s+Discharge|POD|Destination\s+Port)[:\s]+([A-Za-z\s,]{3,50}?)(?:\n|,|\|)",
            ], text),
            "incoterms": self.normalize_incoterms(text),
            "currency": self.normalize_currency(text),
            "invoice_value": self.find_float([
                r"(?:Total\s+Amount|Grand\s+Total|Invoice\s+Total|Total\s+Value)[:\s]+([0-9,]+\.?\d*)",
                r"(?:Amount\s+Due)[:\s]+([0-9,]+\.?\d*)",
            ], text),
        }
        return result
