"""
Freight Quotation Extractor
Extracts freight rate quote fields and multiple carrier/container rate options
from carrier quotation PDFs and operational emails (e.g. WHL, YML, MSC, Maersk, etc.).
"""

from __future__ import annotations

import re
from typing import Any, Dict, List, Optional

from modules.smart_document_upload.extractors.base_extractor import BaseExtractor


KNOWN_CARRIERS = {
    "WHL": "Wan Hai Lines (WHL)",
    "WAN HAI": "Wan Hai Lines (WHL)",
    "YML": "Yang Ming Line (YML)",
    "YANG MING": "Yang Ming Line (YML)",
    "MSC": "Mediterranean Shipping Company (MSC)",
    "MSK": "Maersk Line (MSK)",
    "MAERSK": "Maersk Line (MSK)",
    "CMA": "CMA CGM",
    "CMA CGM": "CMA CGM",
    "COSCO": "COSCO Shipping Lines",
    "EMC": "Evergreen Line (EMC)",
    "EVERGREEN": "Evergreen Line (EMC)",
    "ONE": "Ocean Network Express (ONE)",
    "HAPAG": "Hapag-Lloyd",
    "HAPAG-LLOYD": "Hapag-Lloyd",
    "HMM": "HMM (Hyundai Merchant Marine)",
    "OOCL": "OOCL",
    "ZIM": "ZIM Integrated Shipping",
}

PORT_NAME_MAP = {
    "DEK": "El Dekheila (الدخيلة)",
    "EL DEKHEILA": "El Dekheila (الدخيلة)",
    "DEKHEILA": "El Dekheila (الدخيلة)",
    "ALX": "Alexandria (الإسكندرية)",
    "ALEXANDRIA": "Alexandria (الإسكندرية)",
    "SOKHNA": "Ain Sokhna (العين السخنة)",
    "AIN SOKHNA": "Ain Sokhna (العين السخنة)",
    "PSD": "Port Said (بورسعيد)",
    "PORT SAID": "Port Said (بورسعيد)",
    "DAM": "Damietta (دمياط)",
    "DAMIETTA": "Damietta (دمياط)",
    "SHANGHAI": "Shanghai, China (شنغهاي)",
    "NINGBO": "Ningbo, China (نينغبو)",
    "SHENZHEN": "Shenzhen, China (شنتشن)",
    "QINGDAO": "Qingdao, China (تشينغداو)",
    "GUANGZHOU": "Guangzhou, China (قوانغتشو)",
    "XIAMEN": "Xiamen, China (شيامن)",
    "TIANJIN": "Tianjin, China (تيانجين)",
    "YANTIAN": "Yantian, China (يانتيان)",
}


class FreightQuotationExtractor(BaseExtractor):

    def required_fields(self) -> List[str]:
        return ["carrier_name", "origin_port", "destination_port", "freight_rate"]

    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        text = raw_text or ""

        # 1. Global context extraction
        currency = self.normalize_currency(text) or "USD"
        incoterm = self.normalize_incoterms(text)
        global_origin, global_dest = self._extract_route(text)
        global_carrier = self._extract_carrier(text)
        global_free_time = self._extract_free_time(text)
        global_transit_days, global_is_direct = self._extract_transit_info(text)
        global_etd = self._extract_etd(text)
        cancel_fee = self.find_float([
            r"(?:cancel\s+fee|cancellation\s+fee)[:\s]+\$?([0-9,]+\.?\d*)",
        ], text)

        # 2. Parse multi-option rate matrix from email blocks
        rate_options = self._extract_rate_options(text, currency, global_origin, global_dest, incoterm)

        # 3. Default single-quote representation (fallback / first best option)
        primary_quote = rate_options[0] if rate_options else {}
        primary_carrier = primary_quote.get("carrier_name") or global_carrier
        primary_origin = primary_quote.get("origin_port") or global_origin
        primary_dest = primary_quote.get("destination_port") or global_dest
        primary_rate = primary_quote.get("ocean_freight") or self.find_float([
            r"(?:Freight\s+Rate|Ocean\s+Freight|O/?F\s*(?:rate)?|Rate)[:\s]+(?:USD|EUR|GBP|\$)?\s*([0-9,]+\.?\d*)",
            r"(?:USD|\$)\s*([0-9,]+(?:\.\d+)?)\s*(?:/|\\)\s*(?:20|40)",
        ], text)
        primary_container = primary_quote.get("container_type") or self.normalize_container_type(text) or "40HQ"
        primary_transit = primary_quote.get("transit_days") or global_transit_days
        primary_free_days = primary_quote.get("free_time_days") or global_free_time
        primary_local_charges = primary_quote.get("local_charges")
        primary_exw_charges = primary_quote.get("exw_charges")

        return {
            "carrier_name": primary_carrier,
            "origin_port": primary_origin,
            "destination_port": primary_dest,
            "freight_rate": primary_rate,
            "currency": currency,
            "container_type": primary_container,
            "incoterm": incoterm or primary_quote.get("incoterm"),
            "transit_days": primary_transit,
            "is_direct": primary_quote.get("is_direct", global_is_direct),
            "free_days_demurrage": primary_free_days,
            "free_days_detention": self.find_int([
                r"(?:Free\s+Days?\s+Detention|Detention\s+Free\s+Days?)[:\s]+(\d+)",
            ], text),
            "validity_date": self.find_first([
                r"(?:Valid\s+(?:Until|Till|To)|Validity)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
                r"(?:Expiry\s+Date)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
            ], text),
            "etd_date": primary_quote.get("etd_date") or global_etd,
            "local_charges": primary_local_charges,
            "exw_charges": primary_exw_charges,
            "cancel_fee": cancel_fee,
            "rate_options": rate_options,
            "options_count": len(rate_options),
        }

    # ─── Heuristic Sub-Parsers ────────────────────────────────────────────────

    def _extract_carrier(self, text: str) -> Optional[str]:
        # 1. Check direct "BY <CARRIER>" pattern (e.g. "BY WHL" or "BY YML")
        by_match = re.search(r"\bBY\s+([A-Z]{2,10})\b", text, re.IGNORECASE)
        if by_match:
            c = by_match.group(1).upper()
            return KNOWN_CARRIERS.get(c, c)

        # 2. Check bullet point or line start carrier: e.g. "• WHL: USD 5800"
        bullet_match = re.search(r"(?:[•\-\*]\s*|\b)([A-Z]{2,10})[:\s]+(?:USD|\$)?\s*\d+", text)
        if bullet_match:
            c = bullet_match.group(1).upper()
            if c in KNOWN_CARRIERS:
                return KNOWN_CARRIERS[c]

        # 3. Check explicit carrier labels
        found = self.find_first([
            r"(?:Carrier|Shipping\s+Line|Liner)[:\s]+([A-Za-z0-9\s&.'-]{2,40}?)(?:\n|,|\|)",
        ], text)
        if found:
            c = found.upper().strip()
            return KNOWN_CARRIERS.get(c, found)

        # 4. Keyword presence
        for k, v in KNOWN_CARRIERS.items():
            if re.search(rf"\b{re.escape(k)}\b", text, re.IGNORECASE):
                return v

        return None

    def _extract_route(self, text: str) -> tuple[Optional[str], Optional[str]]:
        origin: Optional[str] = None
        dest: Optional[str] = None

        # Pattern 1: Route: Shanghai – El Dekheila or Route: Shanghai - Alexandria
        route_match = re.search(r"Route[:\s]+([A-Za-z\s]+?)\s*[\-–—to]+\s*([A-Za-z\s]+?)(?:\n|,|\||$)", text, re.IGNORECASE)
        if route_match:
            origin = self._clean_port_name(route_match.group(1))
            dest = self._clean_port_name(route_match.group(2))
            return origin, dest

        # Pattern 2: EXW SHANGHAI-DEK or FOB NINGBO-ALX
        inco_route = re.search(r"\b(?:EXW|FOB|CFR|CIF)\s+([A-Z]+)\s*[\-–—]\s*([A-Z]+)\b", text, re.IGNORECASE)
        if inco_route:
            origin = self._clean_port_name(inco_route.group(1))
            dest = self._clean_port_name(inco_route.group(2))
            return origin, dest

        # Pattern 3: POL / POD lines
        pol = self.find_first([r"(?:Port\s+of\s+Loading|POL|Origin\s+Port|From\s+Port)[:\s]+([A-Za-z\s,]{3,40}?)(?:\n|,|\|)"], text)
        pod = self.find_first([r"(?:Port\s+of\s+Discharge|POD|Destination\s+Port|To\s+Port)[:\s]+([A-Za-z\s,]{3,40}?)(?:\n|,|\|)"], text)
        if pol:
            origin = self._clean_port_name(pol)
        if pod:
            dest = self._clean_port_name(pod)

        # Fallback check port keywords in text
        if not origin:
            for p in ["SHANGHAI", "NINGBO", "SHENZHEN", "QINGDAO", "GUANGZHOU", "XIAMEN", "TIANJIN", "YANTIAN"]:
                if re.search(rf"\b{p}\b", text, re.IGNORECASE):
                    origin = PORT_NAME_MAP[p]
                    break
        if not dest:
            for p in ["EL DEKHEILA", "DEKHEILA", "DEK", "ALEXANDRIA", "ALX", "AIN SOKHNA", "SOKHNA", "PORT SAID", "PSD", "DAMIETTA", "DAM"]:
                if re.search(rf"\b{p}\b", text, re.IGNORECASE):
                    dest = PORT_NAME_MAP[p]
                    break

        return origin, dest

    def _clean_port_name(self, raw: str) -> str:
        s = raw.strip().upper()
        return PORT_NAME_MAP.get(s, raw.strip().title())

    def _extract_free_time(self, text: str) -> Optional[int]:
        # Examples: "21 days FT", "Free time: 21 days", "Free time has 21days", "Free Days: 14", "Free Days Demurrage: 14"
        return self.find_int([
            r"(\d+)\s*(?:days?\s+FT|days?\s+free\s+time|d\s+FT)",
            r"(?:Free\s+Days?\s+Demurrage|Demurrage\s+Free\s+Days?)[:\s]+(\d+)",
            r"(?:Free\s+time(?:\s+has)?|Free\s+Days?)[:\s]+(\d+)\s*(?:days?)?",
            r"(?:Demurrage\s+Free\s+Days?)[:\s]+(\d+)",
        ], text)

    def _extract_transit_info(self, text: str) -> tuple[Optional[int], bool]:
        transit_days = self.find_int([
            r"(?:Transit\s+time|T/?T|TT)[:\s]+(?:direct,?\s*about\s*|about\s*)?(\d+)\s*(?:days?|day)",
            r"(\d+)\s*(?:days?\s+transit|days?\s+TT)",
        ], text)
        is_direct = True
        if re.search(r"\bINDIRECT\b|\bTRANSSHIPMENT\b|\bVIA\b", text, re.IGNORECASE):
            is_direct = False
        elif re.search(r"\bDIRECT\b", text, re.IGNORECASE):
            is_direct = True
        return transit_days, is_direct

    def _extract_etd(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:ETD|1st\s+vessel|Vessel\s+Date)[:\s]+([0-9]{1,2}[\./\-][0-9]{1,2}(?:[\./\-][0-9]{2,4})?|[0-9]{1,2}[\s\-]+[A-Za-z]{3,4})",
            r"(?:ETD)[:\s]+([0-9]{1,2}/[A-Za-z]{3,4})",
        ], text)

    def _extract_rate_options(
        self,
        text: str,
        currency: str,
        origin: Optional[str],
        dest: Optional[str],
        incoterm: Optional[str],
    ) -> List[Dict[str, Any]]:
        options: List[Dict[str, Any]] = []

        # Split text into discrete quotation sections if multiple carrier blocks exist
        raw_blocks = re.split(r"(?=(?:\n\s*EXW\s+[A-Z]+\-[A-Z]+|\n\s*FOB\s+[A-Z]+\-[A-Z]+|\n\s*•\s*[A-Z]{2,6}:))", text, flags=re.IGNORECASE)
        blocks = [b for b in raw_blocks if b.strip()]
        if not blocks:
            blocks = [text]

        # Extract specific local charges mapped per container type across text
        local_charges_map: Dict[str, float] = {}
        for section in re.finditer(r"(?:Local\s+charges|Ex\-work\s+charges|EXW\s+FEE)[^:\n]*?[:\s]+([\s\S]{1,160}?)(?=\n\s*(?:Ocean|O/?F|Free|ETD|TT|1st|Thanks|\Z))", text, re.IGNORECASE):
            sec_text = section.group(1)
            for lm in re.finditer(r"(?:USD|\$)?\s*([0-9,]+(?:\.\d+)?)\s*(?:/|\\)\s*(20['’‘`\s]?(?:GP|DC|ft)?|40['’‘`\s]?(?:HQ|HC|GP|DC|ft)?)", sec_text, re.IGNORECASE):
                amt = self.parse_numeric_str(lm.group(1))
                ct = self._normalize_cntr(lm.group(2))
                local_charges_map[ct] = amt

        for lm in re.finditer(r"(?:Local\s+charges|Ex\-work\s+charges|EXW\s+FEE)[^:\n]*?[:\s]+(?:Approx\.?\s*)?(?:USD|\$)?\s*([0-9,]+(?:\.\d+)?)\s*(?:/|\\)\s*(20['’‘`\s]?(?:GP|DC|ft)?|40['’‘`\s]?(?:HQ|HC|GP|DC|ft)?)", text, re.IGNORECASE):
            amt = self.parse_numeric_str(lm.group(1))
            ct = self._normalize_cntr(lm.group(2))
            local_charges_map[ct] = amt

        # Check itemized EXW fees: TRUCK: USD440/40HQ+LOCAL: USD390/40HQ+CUSTOMS:USD 50/BILL
        itemized_exw_total = 0.0
        truck_match = re.search(r"TRUCK[:\s]+(?:USD|\$)?\s*([0-9,]+)", text, re.IGNORECASE)
        local_fee_match = re.search(r"LOCAL[:\s]+(?:USD|\$)?\s*([0-9,]+)", text, re.IGNORECASE)
        customs_match = re.search(r"CUSTOMS[:\s]+(?:USD|\$)?\s*([0-9,]+)", text, re.IGNORECASE)
        if truck_match or local_fee_match or customs_match:
            truck_val = self.parse_numeric_str(truck_match.group(1)) if truck_match else 0.0
            local_val = self.parse_numeric_str(local_fee_match.group(1)) if local_fee_match else 0.0
            cust_val = self.parse_numeric_str(customs_match.group(1)) if customs_match else 0.0
            itemized_exw_total = truck_val + local_val + cust_val

        # Regex captures rate lines supporting standard and unicode quotes
        rate_pattern = re.compile(
            r"(?:([A-Z]{2,6})[:\s]+)?(?:O/?F(?:\s*rate)?[:\s]*)?(?:USD|\$)?\s*([0-9,]{3,8}(?:\.\d+)?)\s*(?:/|\\)\s*(20['’‘`\s]?(?:GP|DC|ft)?|40['’‘`\s]?(?:HQ|HC|GP|DC|ft)?)(?:\s+BY\s+([A-Z]{2,6}))?",
            re.IGNORECASE,
        )

        seen_keys = set()

        for block in blocks:
            blk_carrier = self._extract_carrier(block)
            blk_transit_days, blk_is_direct = self._extract_transit_info(block)
            blk_free_time = self._extract_free_time(block)
            blk_etd = self._extract_etd(block)
            blk_orig, blk_dest = self._extract_route(block)

            for match in rate_pattern.finditer(block):
                prefix_carrier = match.group(1)
                raw_rate = match.group(2)
                cntr_raw = match.group(3)
                suffix_carrier = match.group(4)

                carrier_code = (suffix_carrier or prefix_carrier or "").upper()
                carrier_name = KNOWN_CARRIERS.get(carrier_code, carrier_code) if carrier_code else (blk_carrier or self._extract_carrier(text))
                cntr_type = self._normalize_cntr(cntr_raw)
                rate_val = self.parse_numeric_str(raw_rate)

                # Avoid capturing local charges as ocean freight if rate is small
                if rate_val < 1000 and "local" in block[max(0, match.start() - 30):match.start()].lower():
                    continue

                unique_key = f"{carrier_name}_{cntr_type}_{rate_val}"
                if unique_key in seen_keys:
                    continue
                seen_keys.add(unique_key)

                # Local / EXW charges for this container type (40HQ / 40GP fallback)
                local_fee = local_charges_map.get(cntr_type, 0.0)
                if local_fee == 0.0:
                    if "40" in cntr_type:
                        local_fee = local_charges_map.get("40HQ") or local_charges_map.get("40GP") or 0.0
                    elif "20" in cntr_type:
                        local_fee = local_charges_map.get("20GP") or local_charges_map.get("20DC") or 0.0

                if local_fee == 0.0 and itemized_exw_total > 0 and "40" in cntr_type:
                    local_fee = itemized_exw_total

                window_text = block[max(0, match.start() - 60):min(len(block), match.end() + 140)]
                total_cost = rate_val + (local_fee if "Included" not in block else 0.0)

                options.append({
                    "option_id": len(options) + 1,
                    "carrier_name": carrier_name or "Shipping Line",
                    "container_type": cntr_type,
                    "ocean_freight": rate_val,
                    "local_charges": local_fee if local_fee > 0 else None,
                    "exw_charges": local_fee if (incoterm == "EXW" or "EXW" in block) and local_fee > 0 else None,
                    "total_estimated_cost": total_cost,
                    "currency": currency,
                    "incoterm": "EXW" if ("EXW" in block or incoterm == "EXW") else (incoterm or "FOB"),
                    "origin_port": blk_orig or origin,
                    "destination_port": blk_dest or dest,
                    "transit_days": blk_transit_days or self._extract_transit_info(text)[0],
                    "is_direct": blk_is_direct,
                    "free_time_days": blk_free_time or self._extract_free_time(text),
                    "etd_date": blk_etd or self._extract_etd(text),
                    "notes": self._extract_option_notes(window_text) or self._extract_option_notes(block),
                })

        return options

    def _normalize_cntr(self, raw: str) -> str:
        s = raw.upper().replace("'", "").replace("’", "").replace("‘", "").replace("`", "").replace(" ", "").replace("FT", "")
        if "40HQ" in s or "40HC" in s:
            return "40HQ"
        if "40DC" in s or "40GP" in s or "40" in s:
            return "40GP"
        if "20DC" in s or "20GP" in s or "20" in s:
            return "20GP"
        return "40HQ"

    def _extract_option_notes(self, window: str) -> Optional[str]:
        notes = []
        if re.search(r"INCL\s+OWS", window, re.IGNORECASE):
            notes.append("Includes Overweight Surcharge (OWS)")
        if re.search(r"Included\s+EXW\s+FEE", window, re.IGNORECASE):
            notes.append("Ocean freight includes EXW fees (Trucking + Local + Customs)")
        if re.search(r"cancel\s+fee", window, re.IGNORECASE):
            m = re.search(r"cancel\s+fee[:\s]+\$?\d+(?:/cntr)?", window, re.IGNORECASE)
            if m:
                notes.append(m.group(0))
        return " | ".join(notes) if notes else None

