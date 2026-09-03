"""
Cargo Shipping / Bill of Lading Extractor
Extracts B/L and Air Waybill (AWB) fields from PDFs, Word, Excel, and text.
Reuses and extends the existing ai_document_parser engine from import_documentation.
"""

from __future__ import annotations

import re
from typing import Any, Dict, List, Optional

from modules.smart_document_upload.extractors.base_extractor import BaseExtractor


class CargoShippingExtractor(BaseExtractor):
    """
    Enhanced Bill of Lading & Air Waybill Extractor.
    Extracts BL/AWB number, ACID, vessel/flight, voyage, carrier, ports,
    freight terms (Prepaid/Collect), packages, weights, parties, and container lists.
    """

    def required_fields(self) -> List[str]:
        return ["bl_number", "vessel_name", "carrier_name", "loading_port", "discharge_port"]


    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        text = (raw_text or "").replace("\r", "\n")

        # 1. Detect Ocean B/L vs Air Waybill
        is_air = bool(re.search(r"\b(?:AIR\s*WAYBILL|AWB|AIR\s*CARGO|FLIGHT\s*(?:NO|NUMBER)?|AIRPORT)\b", text, re.IGNORECASE))
        bl_type = "AIR_WAYBILL" if is_air else "OCEAN_BL"

        # 2. Delegate to the comprehensive ai_document_parser B/L extraction engine
        bl_fields: Dict[str, Any] = {}
        try:
            from modules.import_documentation.ai_document_parser import (
                _heuristic_multi_carrier_extractor,
            )
            bl_fields = _heuristic_multi_carrier_extractor(text, spatial_boxes=spatial_boxes)
        except Exception:
            pass

        if not bl_fields or not bl_fields.get("bl_number"):
            bl_fields = self._fallback_extract(text, is_air=is_air)

        # Remove internal guardrail keys
        bl_fields.pop("_guardrails", None)

        # 3. 19-digit ACID Number
        acid_number = bl_fields.get("acid_number") or self.find_first([
            r"(?:ACID|ACI\s+NO|ADVANCE\s+CARGO\s+INFO|ACID:\s*|ACID\s+#)[:\s#,-]*([0-9a-zA-Z]{19})",
            r"\b(\d{19})\b",
        ], text)
        if acid_number:
            acid_clean = re.sub(r"[^0-9]", "", str(acid_number))
            if len(acid_clean) == 19:
                acid_number = acid_clean

        # 4. Freight Payment Term (Prepaid vs Collect)
        freight_term = "FREIGHT_COLLECT"
        if re.search(r"\bFREIGHT\s+PREPAID\b", text, re.IGNORECASE):
            freight_term = "FREIGHT_PREPAID"
        elif re.search(r"\bFREIGHT\s+COLLECT\b", text, re.IGNORECASE):
            freight_term = "FREIGHT_COLLECT"

        # 5. Total packages count and package type
        packages_count = self.find_float([
            r"(?:Total\s+No\.?\s+of\s+Packages|Total\s+Packages|No\.?\s+of\s+Pkgs)[:\s]+([0-9,]+)",
            r"(\d+)\s+(?:PACKAGES|PKGS|CARTONS|PALLETS|COLLIS|BOXES)\b",
        ], text)

        package_type = self.find_first([
            r"(?:Package\s+Type|Type\s+of\s+Packages)[:\s]+([A-Za-z\s]{3,25})",
            r"\b\d+\s+(PACKAGES|PKGS|CARTONS|PALLETS|COLLIS|BOXES|CRATES)\b",
        ], text) or "Packages"

        # 6. Flight Number if Air Waybill
        flight_number = None
        if is_air:
            flight_number = self.find_first([
                r"(?:Flight\s+No\.?|Flight\s+#|Flight)[:\s]*([A-Za-z0-9\-]{3,12})",
            ], text)


        # Re-map to cargo_shipping / bill-of-lading standard schema
        result: Dict[str, Any] = {
            "bl_type": bl_type,
            "bl_number": bl_fields.get("bl_number") or self.find_first([
                r"B/?L\s*(?:No\.?|Number|#)[:\s]*([A-Z0-9]{6,25})",
                r"Bill\s+of\s+Lading\s+(?:No\.?|#)[:\s]*([A-Z0-9]{6,25})",
                r"AWB\s*(?:No\.?|#)[:\s]*([0-9]{3}[-\s]?[0-9]{8}|[A-Z0-9]{8,15})",
            ], text),
            "acid_number": acid_number,
            "carrier_name": bl_fields.get("carrier_name") or bl_fields.get("carrier_scac") or self.find_first([
                r"(?:Carrier|Shipping\s+Line|Airline)[:\s]+([A-Za-z0-9\s&,.'-]{3,40}?)(?:\n|,|\|)",
            ], text),
            "vessel_name": bl_fields.get("vessel_name") or self.find_first([
                r"(?:Vessel|Ship|MV|Ocean\s+Vessel)[:\s]+([A-Za-z0-9\s.-]+?)(?:\n|/|VOY|\bVOYAGE\b)",
            ], text),
            "voyage_number": bl_fields.get("voyage_number") or self.find_first([
                r"(?:Voyage\s+No\.?|Voyage|Voy\.?)[:\s]*([A-Z0-9/_-]{2,15})",
            ], text),
            "flight_number": flight_number,
            "loading_port": bl_fields.get("port_of_loading") or bl_fields.get("loading_port") or self.find_first([
                r"(?:Port\s+of\s+Loading|POL|Airport\s+of\s+Departure)[:\s]+([A-Za-z\s,]{3,50}?)(?:\n|,|\|)",
            ], text),
            "discharge_port": bl_fields.get("port_of_discharge") or bl_fields.get("discharge_port") or self.find_first([
                r"(?:Port\s+of\s+Discharge|POD|Airport\s+of\s+Destination)[:\s]+([A-Za-z\s,]{3,50}?)(?:\n|,|\|)",
            ], text),
            "place_of_delivery": bl_fields.get("place_of_delivery") or self.find_first([
                r"(?:Place\s+of\s+Delivery|Final\s+Destination)[:\s]+([A-Za-z\s,]{3,50}?)(?:\n|,|\|)",
            ], text),
            "etd": bl_fields.get("etd") or bl_fields.get("departure_date") or self.find_first([
                r"(?:ETD|Departure\s+Date|Sailing\s+Date)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}-\d{2}-\d{2})",
            ], text),
            "eta": bl_fields.get("eta") or bl_fields.get("arrival_date") or self.find_first([
                r"(?:ETA|Arrival\s+Date)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}-\d{2}-\d{2})",
            ], text),
            "issue_date": bl_fields.get("issue_date") or bl_fields.get("bl_date") or self.find_first([
                r"(?:Date\s+of\s+Issue|B/?L\s+Date|Issued\s+on)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}-\d{2}-\d{2})",
            ], text),
            "total_gross_weight_kg": self._parse_float(bl_fields.get("gross_weight")) or self.find_float([
                r"(?:Total\s+Gross\s+Weight|Gross\s+Weight|G\.W\.)[:\s]+([0-9,]+\.?\d*)\s*(?:KGS?|KG)?",
            ], text),
            "total_net_weight_kg": self._parse_float(bl_fields.get("net_weight")) or self.find_float([
                r"(?:Total\s+Net\s+Weight|Net\s+Weight|N\.W\.)[:\s]+([0-9,]+\.?\d*)\s*(?:KGS?|KG)?",
            ], text),
            "total_cbm": self._parse_float(bl_fields.get("cbm") or bl_fields.get("measurement")) or self.find_float([
                r"(?:Total\s+Measurement|Total\s+CBM|Volume|CBM)[:\s]+([0-9,]+\.?\d*)",
            ], text),
            "total_packages_count": int(packages_count) if packages_count else None,
            "package_type": package_type,
            "freight_payment_term": freight_term,
            "shipper": bl_fields.get("shipper") or self.find_first([
                r"(?:Shipper|Exporter|From)[:\s]+([A-Za-z0-9\s&,.'-]{3,60}?)(?:\n|,|\|)",
            ], text),
            "consignee": bl_fields.get("consignee") or self.find_first([
                r"(?:Consignee|To)[:\s]+([A-Za-z0-9\s&,.'-]{3,60}?)(?:\n|,|\|)",
            ], text),
            "notify_party": bl_fields.get("notify_party") or self.find_first([
                r"(?:Notify\s+Party|Also\s+Notify)[:\s]+([A-Za-z0-9\s&,.'-]{3,60}?)(?:\n|,|\|)",
            ], text),
            "containers": self._extract_containers(bl_fields, text),
        }
        return result

    def _fallback_extract(self, text: str, is_air: bool = False) -> Dict[str, Any]:
        """Simple regex fallback if the main parser is unavailable."""
        return {
            "bl_number": self.find_first([
                r"B/?L\s*(?:No\.?|Number|#)[:\s]*([A-Z0-9]{6,25})",
                r"Bill\s+of\s+Lading\s+(?:No\.?|#)[:\s]*([A-Z0-9]{6,25})",
                r"AWB\s*(?:No\.?|#)[:\s]*([0-9]{3}[-\s]?[0-9]{8}|[A-Z0-9]{8,15})",
            ], text),
            "vessel_name": self.find_first([
                r"(?:Vessel|Ship|MV)[:\s]+([A-Za-z0-9\s.-]+?)(?:\n|/|VOY)",
            ], text),
            "port_of_loading": self.find_first([
                r"(?:Port\s+of\s+Loading|POL)[:\s]+([A-Za-z\s,]+?)(?:\n|,|\|)",
            ], text),
            "port_of_discharge": self.find_first([
                r"(?:Port\s+of\s+Discharge|POD)[:\s]+([A-Za-z\s,]+?)(?:\n|,|\|)",
            ], text),
        }

    def _parse_float(self, val: Any) -> Optional[float]:
        if val is None:
            return None
        try:
            return float(str(val).replace(",", "").strip())
        except ValueError:
            return None

    def _extract_containers(self, bl_fields: dict, text: str = "") -> List[Dict[str, Any]]:
        """Extract container list from parsed B/L fields or regex from raw text."""
        containers_raw = bl_fields.get("containers") or []
        result = []
        if isinstance(containers_raw, list) and containers_raw:
            for c in containers_raw:
                if isinstance(c, dict):
                    result.append({
                        "container_no": c.get("container_no") or c.get("number"),
                        "seal_no": c.get("seal_no") or c.get("seal"),
                        "container_type": c.get("type") or c.get("size") or "40HC",
                        "gross_weight_kg": self._parse_float(c.get("gross_weight")),
                        "cbm": self._parse_float(c.get("cbm") or c.get("measurement")),
                    })

        # Regex fallback for ISO Container numbers (e.g. MSCU1234567, MEDU7654321, CMAU9876543)
        if not result:
            cont_matches = re.findall(r"\b([A-Z]{4}\d{7})\b", text)
            for cnt in set(cont_matches):
                # Search for seal near the container number
                seal_match = re.search(rf"{cnt}[^\n]*?(?:SEAL|ML-EG|NO)[:\s]*([A-Z0-9-]{5,15})", text, re.IGNORECASE)
                seal_no = seal_match.group(1) if seal_match else None
                result.append({
                    "container_no": cnt,
                    "seal_no": seal_no,
                    "container_type": "40HC" if "40" in text else "20GP",
                    "gross_weight_kg": None,
                    "cbm": None,
                })

        return result

