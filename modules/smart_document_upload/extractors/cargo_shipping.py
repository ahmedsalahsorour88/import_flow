"""
Cargo Shipping Extractor
Extracts B/L fields from Bill of Lading PDFs/Word documents.
Reuses the existing ai_document_parser spatial engine from import_documentation.
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional

from modules.smart_document_upload.extractors.base_extractor import BaseExtractor


class CargoShippingExtractor(BaseExtractor):

    def required_fields(self) -> List[str]:
        return ["bl_number", "vessel_name", "loading_port", "discharge_port"]

    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        """
        Delegates to the existing ai_document_parser B/L extraction engine,
        then re-maps the result to CargoShipping field names.
        """
        try:
            from modules.import_documentation.ai_document_parser import (
                extract_draft_bl_fields_heuristic,
            )
            bl_fields = extract_draft_bl_fields_heuristic(raw_text, spatial_boxes=spatial_boxes)
        except Exception:
            bl_fields = self._fallback_extract(raw_text)

        # Remove internal guardrail keys
        bl_fields.pop("_guardrails", None)

        # Re-map to cargo_shipping field names
        result: Dict[str, Any] = {
            "bl_number": bl_fields.get("bl_number"),
            "vessel_name": bl_fields.get("vessel_name"),
            "voyage_number": bl_fields.get("voyage_number"),
            "carrier_name": bl_fields.get("carrier_name") or bl_fields.get("carrier_scac"),
            "loading_port": bl_fields.get("port_of_loading"),
            "discharge_port": bl_fields.get("port_of_discharge"),
            "place_of_delivery": bl_fields.get("place_of_delivery"),
            "etd": bl_fields.get("etd") or bl_fields.get("departure_date"),
            "eta": bl_fields.get("eta") or bl_fields.get("arrival_date"),
            "total_gross_weight_kg": self._parse_float(bl_fields.get("gross_weight")),
            "total_cbm": self._parse_float(bl_fields.get("cbm") or bl_fields.get("measurement")),
            "shipper": bl_fields.get("shipper"),
            "consignee": bl_fields.get("consignee"),
            "notify_party": bl_fields.get("notify_party"),
            "containers": self._extract_containers(bl_fields),
        }
        return result

    def _fallback_extract(self, text: str) -> Dict[str, Any]:
        """Simple regex fallback if the main parser is unavailable."""
        return {
            "bl_number": self.find_first([
                r"B/?L\s*(?:No\.?|Number|#)[:\s]*([A-Z0-9]{6,25})",
                r"Bill\s+of\s+Lading\s+(?:No\.?|#)[:\s]*([A-Z0-9]{6,25})",
            ], text),
            "vessel_name": self.find_first([
                r"(?:Vessel|Ship|MV)[:\s]+([A-Z][A-Z0-9\s]+?)(?:\n|/|VOY)",
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

    def _extract_containers(self, bl_fields: dict) -> List[Dict[str, Any]]:
        """Extract container list from parsed B/L fields."""
        containers_raw = bl_fields.get("containers") or []
        if not isinstance(containers_raw, list):
            return []
        result = []
        for c in containers_raw:
            if isinstance(c, dict):
                result.append({
                    "container_no": c.get("container_no") or c.get("number"),
                    "seal_no": c.get("seal_no") or c.get("seal"),
                    "container_type": c.get("type") or c.get("size"),
                    "gross_weight_kg": self._parse_float(c.get("gross_weight")),
                    "cbm": self._parse_float(c.get("cbm") or c.get("measurement")),
                })
        return result
