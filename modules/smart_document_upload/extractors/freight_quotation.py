"""
Freight Quotation Extractor
Extracts freight rate quote fields from carrier quotation PDFs/emails.
"""

from __future__ import annotations

from typing import Any, Dict, List

from modules.smart_document_upload.extractors.base_extractor import BaseExtractor


class FreightQuotationExtractor(BaseExtractor):

    def required_fields(self) -> List[str]:
        return ["carrier_name", "origin_port", "destination_port", "freight_rate"]

    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        text = raw_text or ""
        return {
            "carrier_name": self.find_first([
                r"(?:Carrier|Shipping\s+Line|Liner)[:\s]+([A-Za-z0-9\s&.'-]{3,60}?)(?:\n|,|\|)",
                r"(?:From)[:\s]+([A-Za-z0-9\s&.'-]{3,60}?)(?:\n|,|\|)",
            ], text),
            "origin_port": self.find_first([
                r"(?:Origin|Port\s+of\s+Loading|From\s+Port|POL)[:\s]+([A-Za-z\s,]{3,50}?)(?:\n|,|\|)",
            ], text),
            "destination_port": self.find_first([
                r"(?:Destination|Port\s+of\s+Discharge|To\s+Port|POD)[:\s]+([A-Za-z\s,]{3,50}?)(?:\n|,|\|)",
            ], text),
            "freight_rate": self.find_float([
                r"(?:Freight\s+Rate|Ocean\s+Freight|Rate)[:\s]+(?:USD|EUR|GBP)?\s*([0-9,]+\.?\d*)",
            ], text),
            "currency": self.normalize_currency(text),
            "container_type": self.normalize_container_type(text),
            "transit_days": self.find_int([
                r"(?:Transit\s+Time|Transit)[:\s]+(\d+)\s*(?:days?|Days?)",
            ], text),
            "validity_date": self.find_first([
                r"(?:Valid\s+(?:Until|Till|To)|Validity)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
                r"(?:Expiry\s+Date)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
            ], text),
            "free_days_demurrage": self.find_int([
                r"(?:Free\s+Days?\s+Demurrage|Demurrage\s+Free\s+Days?)[:\s]+(\d+)",
                r"(?:Free\s+Days?)[:\s]+(\d+)",
            ], text),
            "free_days_detention": self.find_int([
                r"(?:Free\s+Days?\s+Detention|Detention\s+Free\s+Days?)[:\s]+(\d+)",
            ], text),
        }
