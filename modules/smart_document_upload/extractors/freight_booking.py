"""
Freight Booking Extractor
Extracts booking confirmation fields from shipping line booking confirmations.
"""

from __future__ import annotations

from typing import Any, Dict, List

from modules.smart_document_upload.extractors.base_extractor import BaseExtractor


class FreightBookingExtractor(BaseExtractor):

    def required_fields(self) -> List[str]:
        return ["booking_number", "vessel_name", "loading_port", "discharge_port"]

    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        text = raw_text or ""
        return {
            "booking_number": self.find_first([
                r"(?:Booking\s+(?:No\.?|Number|Ref\.?|Reference|#))[:\s]*([A-Z0-9]{6,25})",
                r"(?:BKG)[:\s#]*([A-Z0-9]{6,25})",
            ], text),
            "carrier_name": self.find_first([
                r"(?:Carrier|Shipping\s+Line)[:\s]+([A-Za-z0-9\s&.'-]{3,60}?)(?:\n|,|\|)",
            ], text),
            "vessel_name": self.find_first([
                r"(?:Vessel|Ship|MV)[:\s]+([A-Z][A-Z0-9\s]+?)(?:\n|/|VOY|\|)",
                r"(?:Vessel\s+Name)[:\s]+([A-Za-z0-9\s]+?)(?:\n|,|\|)",
            ], text),
            "voyage_number": self.find_first([
                r"(?:Voyage|VOY)[:\s#.]*([A-Z0-9]{2,15})",
                r"(?:Voy\.?\s*No\.?)[:\s]*([A-Z0-9]{2,15})",
            ], text),
            "loading_port": self.find_first([
                r"(?:Port\s+of\s+Loading|POL|Loading\s+Port)[:\s]+([A-Za-z\s,]{3,50}?)(?:\n|,|\|)",
            ], text),
            "discharge_port": self.find_first([
                r"(?:Port\s+of\s+Discharge|POD|Discharge\s+Port)[:\s]+([A-Za-z\s,]{3,50}?)(?:\n|,|\|)",
            ], text),
            "etd": self.find_first([
                r"(?:ETD|Departure|Sail\s+Date|Estimated\s+Time\s+of\s+Departure)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
                r"(?:ETD)[:\s]+(\d{4}-\d{2}-\d{2})",
            ], text),
            "eta": self.find_first([
                r"(?:ETA|Arrival|Estimated\s+Time\s+of\s+Arrival)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
                r"(?:ETA)[:\s]+(\d{4}-\d{2}-\d{2})",
            ], text),
            "si_cutoff": self.find_first([
                r"(?:SI\s+Cut[-\s]Off|Shipping\s+Instructions?\s+Cut[-\s]Off)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
                r"(?:SI\s+Cutoff)[:\s]+(\d{4}-\d{2}-\d{2})",
            ], text),
            "vgm_cutoff": self.find_first([
                r"(?:VGM\s+Cut[-\s]Off|VGM\s+Deadline)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
            ], text),
            "container_type": self.normalize_container_type(text),
            "containers_count": self.find_int([
                r"(\d+)\s*[xX\*]\s*(?:40|20)['\s]?(?:HC|GP|HQ|ft|foot)?",
                r"(?:Number\s+of\s+Containers?)[:\s]+(\d+)",
            ], text),
        }
