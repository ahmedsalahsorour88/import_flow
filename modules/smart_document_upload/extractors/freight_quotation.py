"""
Freight Quotation Extractor
Extracts freight rate quote fields and multiple carrier/container rate options
from carrier quotation PDFs, scanned OCR documents/images, and operational emails
(e.g. WHL, YML, MSC, Maersk, CMA CGM, COSCO, Hapag-Lloyd, Evergreen, ONE, etc.).
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
    "HYUNDAI": "HMM (Hyundai Merchant Marine)",
    "OOCL": "OOCL",
    "ZIM": "ZIM Integrated Shipping",
    "PIL": "Pacific International Lines (PIL)",
    "ARKAS": "Arkas Line",
    "TURKON": "Turkon Line",
    "GRIMALDI": "Grimaldi Lines",
    "SINOKOR": "Sinokor Merchant Marine",
    "SITC": "SITC Container Lines",
    "SAFMARINE": "Safmarine",
    "SEALAND": "Sealand - A Maersk Company",
    "KUEHNE": "Kuehne + Nagel (Freight Forwarder)",
    "KN": "Kuehne + Nagel (Freight Forwarder)",
    "SCHENKER": "DB Schenker (Freight Forwarder)",
    "DHL": "DHL Global Forwarding",
    "DSV": "DSV Global Transport and Logistics",
    "CEVA": "CEVA Logistics",
    "EXPEDITORS": "Expeditors International",
    "HELLMANN": "Hellmann Worldwide Logistics",
    "AGILITY": "Agility Logistics",
}

PORT_NAME_MAP = {
    # Egyptian Seaports & Dry Ports
    "DEK": "El Dekheila (الدخيلة)",
    "EL DEKHEILA": "El Dekheila (الدخيلة)",
    "DEKHEILA": "El Dekheila (الدخيلة)",
    "الدخيلة": "El Dekheila (الدخيلة)",
    "ميناء الدخيلة": "El Dekheila (الدخيلة)",
    "ALX": "Alexandria (الإسكندرية)",
    "ALEXANDRIA": "Alexandria (الإسكندرية)",
    "ALEX": "Alexandria (الإسكندرية)",
    "الإسكندرية": "Alexandria (الإسكندرية)",
    "ميناء الإسكندرية": "Alexandria (الإسكندرية)",
    "SOKHNA": "Ain Sokhna (العين السخنة)",
    "AIN SOKHNA": "Ain Sokhna (العين السخنة)",
    "العين السخنة": "Ain Sokhna (العين السخنة)",
    "السخنة": "Ain Sokhna (العين السخنة)",
    "PSD": "Port Said (بورسعيد)",
    "PORT SAID": "Port Said (بورسعيد)",
    "بورسعيد": "Port Said (بورسعيد)",
    "EAST PORT SAID": "East Port Said (شرق بورسعيد)",
    "WEST PORT SAID": "West Port Said (غرب بورسعيد)",
    "DAM": "Damietta (دمياط)",
    "DAMIETTA": "Damietta (دمياط)",
    "دمياط": "Damietta (دمياط)",
    "ADABIYA": "Adabiya (الأدبية)",
    "الأدبية": "Adabiya (الأدبية)",
    "PORT TAWFIQ": "Port Tawfiq (بور توفيق)",
    "CAIRO AIRPORT": "Cairo Int Airport (مطار القاهرة الدولي)",
    "CAI": "Cairo Int Airport (مطار القاهرة الدولي)",
    "مطار القاهرة": "Cairo Int Airport (مطار القاهرة الدولي)",
    # Chinese & Asian Ports
    "SHANGHAI": "Shanghai, China (شنغهاي)",
    "SHA": "Shanghai, China (شنغهاي)",
    "شنغهاي": "Shanghai, China (شنغهاي)",
    "NINGBO": "Ningbo, China (نينغبو)",
    "NBO": "Ningbo, China (نينغبو)",
    "نينغبو": "Ningbo, China (نينغبو)",
    "SHENZHEN": "Shenzhen, China (شنتشن)",
    "SZX": "Shenzhen, China (شنتشن)",
    "شنتشن": "Shenzhen, China (شنتشن)",
    "QINGDAO": "Qingdao, China (تشينغداو)",
    "TAO": "Qingdao, China (تشينغداو)",
    "تشينغداو": "Qingdao, China (تشينغداو)",
    "GUANGZHOU": "Guangzhou, China (قوانغتشو)",
    "CAN": "Guangzhou, China (قوانغتشو)",
    "قوانغتشو": "Guangzhou, China (قوانغتشو)",
    "XIAMEN": "Xiamen, China (شيامن)",
    "XMN": "Xiamen, China (شيامن)",
    "شيامن": "Xiamen, China (شيامن)",
    "TIANJIN": "Tianjin, China (تيانجين)",
    "TSN": "Tianjin, China (تيانجين)",
    "تيانجين": "Tianjin, China (تيانجين)",
    "YANTIAN": "Yantian, China (يانتيان)",
    "يانتيان": "Yantian, China (يانتيان)",
    "BUSAN": "Busan, South Korea (بوسان)",
    "PUS": "Busan, South Korea (بوسان)",
    "NHAVA SHEVA": "Nhava Sheva, India (نهافا شيفا)",
    "NSA": "Nhava Sheva, India (نهافا شيفا)",
    # European Ports
    "GENOA": "Genoa, Italy (جنوة)",
    "GOA": "Genoa, Italy (جنوة)",
    "HAMBURG": "Hamburg, Germany (هامبورغ)",
    "HAM": "Hamburg, Germany (هامبورغ)",
    "ROTTERDAM": "Rotterdam, Netherlands (روتردام)",
    "RTM": "Rotterdam, Netherlands (روتردام)",
    "ANTWERP": "Antwerp, Belgium (أنتويرب)",
    "ANR": "Antwerp, Belgium (أنتويرب)",
    "VALENCIA": "Valencia, Spain (فالنسيا)",
    "VLC": "Valencia, Spain (فالنسيا)",
    "BARCELONA": "Barcelona, Spain (برشلونة)",
    "BCN": "Barcelona, Spain (برشلونة)",
    "ISTANBUL": "Istanbul, Turkey (إسطنبول)",
    "IST": "Istanbul, Turkey (إسطنبول)",
    "MERSIN": "Mersin, Turkey (مرسين)",
    "JEBEL ALI": "Jebel Ali, UAE (جبل علي)",
    "JEA": "Jebel Ali, UAE (جبل علي)",
    "JEDDAH": "Jeddah, Saudi Arabia (جدة)",
    "JED": "Jeddah, Saudi Arabia (جدة)",
}


class FreightQuotationExtractor(BaseExtractor):

    def required_fields(self) -> List[str]:
        return ["carrier_name", "origin_port", "destination_port", "freight_rate"]

    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        text = raw_text or ""
        clean_ocr_text = self._pre_clean_ocr_text(text)

        # 1. Global context extraction
        currency = self.normalize_currency(clean_ocr_text) or "USD"
        incoterm = self.normalize_incoterms(clean_ocr_text)
        global_origin, global_dest = self._extract_route(clean_ocr_text)
        global_carrier = self._extract_carrier(clean_ocr_text)
        global_free_time = self._extract_free_time(clean_ocr_text)
        global_transit_days, global_is_direct = self._extract_transit_info(clean_ocr_text)
        global_etd = self._extract_etd(clean_ocr_text)
        global_forwarder = self._extract_forwarder_name(clean_ocr_text)
        global_quote_ref = self._extract_quotation_ref(clean_ocr_text)
        global_validity = self._extract_validity_date(clean_ocr_text)
        cancel_fee = self.find_float([
            r"(?:cancel\s+fee|cancellation\s+fee|رسوم\s+الإلغاء)[:\s]+\$?([0-9,]+\.?\d*)",
        ], clean_ocr_text)

        # 2. Parse multi-option rate matrix from text & OCR tables
        rate_options = self._extract_rate_options(clean_ocr_text, currency, global_origin, global_dest, incoterm)

        # 3. Default single-quote representation (fallback / first best option)
        primary_quote = rate_options[0] if rate_options else {}
        primary_carrier = primary_quote.get("carrier_name") or global_carrier or global_forwarder
        primary_origin = primary_quote.get("origin_port") or global_origin
        primary_dest = primary_quote.get("destination_port") or global_dest
        primary_rate = primary_quote.get("ocean_freight") or self.find_float([
            r"(?:Freight\s+Rate|Ocean\s+Freight|O/?F\s*(?:rate)?|Rate|النولون|نولون\s+بحري)[:\s]+(?:USD|EUR|GBP|EGP|\$)?\s*([0-9,]+\.?\d*)",
        ], clean_ocr_text)
        primary_container = primary_quote.get("container_type") or self.normalize_container_type(clean_ocr_text) or "40HQ"
        primary_transit = primary_quote.get("transit_days") or global_transit_days
        primary_free_days = primary_quote.get("free_time_days") or global_free_time
        primary_local_charges = primary_quote.get("local_charges")
        primary_exw_charges = primary_quote.get("exw_charges")

        if not rate_options and primary_rate:
            rate_options.append({
                "option_id": 1,
                "carrier_name": primary_carrier or "Shipping Line",
                "container_type": primary_container,
                "ocean_freight": primary_rate,
                "local_charges": primary_local_charges,
                "exw_charges": primary_exw_charges,
                "total_estimated_cost": primary_rate + (primary_local_charges or 0.0),
                "currency": currency,
                "incoterm": incoterm or "FOB",
                "origin_port": primary_origin,
                "destination_port": primary_dest,
                "transit_days": primary_transit,
                "is_direct": global_is_direct,
                "free_time_days": primary_free_days,
                "etd_date": global_etd,
                "notes": None,
            })

        return {
            "carrier_name": primary_carrier,
            "forwarder_name": global_forwarder,
            "quotation_ref": global_quote_ref,
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
                r"(?:Free\s+Days?\s+Detention|Detention\s+Free\s+Days?|فترة\s+سماح\s+الغرامات)[:\s]+(\d+)",
            ], clean_ocr_text),
            "validity_date": global_validity,
            "etd_date": primary_quote.get("etd_date") or global_etd,
            "local_charges": primary_local_charges,
            "exw_charges": primary_exw_charges,
            "cancel_fee": cancel_fee,
            "rate_options": rate_options,
            "options_count": len(rate_options),
        }

    # ─── OCR Pre-Cleaning & Normalization ─────────────────────────────────────

    def _pre_clean_ocr_text(self, text: str) -> str:
        """Fixes common OCR glitches in numbers, currency symbols, and container codes."""
        t = text
        # Normalize smart quotes and unicode dashes
        t = t.replace("’", "'").replace("‘", "'").replace("`", "'").replace("“", '"').replace("”", '"')
        t = t.replace("–", "-").replace("—", "-").replace("−", "-")
        # Fix spaced decimals/commas inside numbers: e.g. "3 , 400" or "3200 . 00"
        t = re.sub(r"(\d)\s*,\s*(\d{3})\b", r"\1,\2", t)
        t = re.sub(r"(\d)\s*\.\s*(\d{1,2})\b", r"\1.\2", t)
        # Fix spaced container types: e.g. "40 ' HQ" -> "40'HQ", "40 HC" -> "40HC", "20 GP" -> "20GP"
        t = re.sub(r"\b(20|40)\s*['\"]?\s*(HQ|HC|GP|DC|ST)\b", r"\1\2", t, flags=re.IGNORECASE)
        # Fix spaced slash rates ONLY when followed by known container codes or units:
        t = re.sub(r"([0-9])\s*/\s*(20(?:HQ|HC|GP|DC)?|40(?:HQ|HC|GP|DC)?|CBM|KG|WM|W/M|cntr|container)\b", r"\1/\2", t, flags=re.IGNORECASE)
        return t

    # ─── Heuristic Sub-Parsers ────────────────────────────────────────────────

    def _extract_carrier(self, text: str) -> Optional[str]:
        # 1. Check direct "BY <CARRIER>" pattern (e.g. "BY WHL" or "BY YML" or "BY MAERSK")
        by_match = re.search(r"\bBY\s+([A-Z0-9\-\s]{2,15})\b", text, re.IGNORECASE)
        if by_match:
            c = by_match.group(1).strip().upper()
            if c in KNOWN_CARRIERS:
                return KNOWN_CARRIERS[c]

        # 2. Check bullet point or line start carrier: e.g. "• WHL: USD 5800" or "WHL: 3200/40HQ"
        bullet_match = re.search(r"(?:[•\-\*]\s*|\b)([A-Z]{2,10})[:\s]+(?:USD|\$|EUR)?\s*\d+", text)
        if bullet_match:
            c = bullet_match.group(1).upper()
            if c in KNOWN_CARRIERS:
                return KNOWN_CARRIERS[c]

        # 3. Check explicit carrier / liner labels (Arabic & English)
        found = self.find_first([
            r"(?:Carrier|Shipping\s+Line|Liner|الخط\s+الملاحي|الناقل\s+البحري|الخط)[:\s]+([A-Za-z0-9\s&.'-]{2,40}?)(?:\n|,|\||$)",
        ], text)
        if found:
            c = found.upper().strip()
            return KNOWN_CARRIERS.get(c, found)

        # 4. Keyword presence in text
        for k, v in KNOWN_CARRIERS.items():
            if re.search(rf"\b{re.escape(k)}\b", text, re.IGNORECASE):
                return v

        return None

    def _extract_forwarder_name(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:Freight\s+Forwarder|Forwarder|Agent|شركة\s+الشحن|وكيل\s+الشحن|الوسيط)[:\s]+([A-Za-z0-9\s&.'-]{3,50}?)(?:\n|,|\||$)",
            r"(?:From|Sender|من)[:\s]+([A-Za-z0-9\s&.'-]{3,40}?)(?:<|\n|,)",
        ], text)

    def _extract_quotation_ref(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:Quotation\s+No|Quote\s+Ref|RFQ\s+Ref|Ref\s+No|رقم\s+عرض\s+السعر|رقم\s+المرجع)[:\s]+([A-Za-z0-9\-_/]{4,30})",
            r"(?:Quote\s+#|Ref\s+#)[:\s]+([A-Za-z0-9\-_/]{4,30})",
        ], text)

    def _extract_validity_date(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:Valid\s+(?:Until|Till|To)|Validity|صالح\s+حتى|تاريخ\s+الصلاحية|ساري\s+حتى)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{1,2}\s+[A-Za-z]{3,9}\s+\d{2,4})",
            r"(?:Expiry\s+Date|تاريخ\s+الانتهاء)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
        ], text)

    def _extract_route(self, text: str) -> tuple[Optional[str], Optional[str]]:
        origin: Optional[str] = None
        dest: Optional[str] = None

        # Pattern 1: Route: Shanghai – El Dekheila or Route: Shanghai - Alexandria
        route_match = re.search(r"(?:Route|المسار|خط\s+السير)[:\s]+([A-Za-z\u0600-\u06FF\s]+?)\s*[\-–—toإلى]+\s*([A-Za-z\u0600-\u06FF\s]+?)(?:\n|,|\||$)", text, re.IGNORECASE)
        if route_match:
            origin = self._clean_port_name(route_match.group(1))
            dest = self._clean_port_name(route_match.group(2))
            return origin, dest

        # Pattern 2: EXW SHANGHAI-DEK or FOB NINGBO-ALX
        inco_route = re.search(r"\b(?:EXW|FOB|CFR|CIF)\s+([A-Z\u0600-\u06FF]+)\s*[\-–—]\s*([A-Z\u0600-\u06FF]+)\b", text, re.IGNORECASE)
        if inco_route:
            origin = self._clean_port_name(inco_route.group(1))
            dest = self._clean_port_name(inco_route.group(2))
            return origin, dest

        # Pattern 3: POL / POD lines
        pol = self.find_first([
            r"(?:Port\s+of\s+Loading|POL|Origin\s+Port|From\s+Port|ميناء\s+الشحن|ميناء\s+التحميل)[:\s]+([A-Za-z\u0600-\u06FF\s,]{3,40}?)(?:\n|,|\||$)",
        ], text)
        pod = self.find_first([
            r"(?:Port\s+of\s+Discharge|POD|Destination\s+Port|To\s+Port|ميناء\s+الوصول|ميناء\s+التفريغ)[:\s]+([A-Za-z\u0600-\u06FF\s,]{3,40}?)(?:\n|,|\||$)",
        ], text)
        if pol:
            origin = self._clean_port_name(pol)
        if pod:
            dest = self._clean_port_name(pod)

        # Fallback check port keywords in text
        if not origin:
            for p in ["SHANGHAI", "NINGBO", "SHENZHEN", "QINGDAO", "GUANGZHOU", "XIAMEN", "TIANJIN", "YANTIAN", "GENOA", "HAMBURG", "ROTTERDAM", "ANTWERP", "VALENCIA", "ISTANBUL", "MERSIN", "JEBEL ALI", "JEDDAH"]:
                if re.search(rf"\b{p}\b", text, re.IGNORECASE):
                    origin = PORT_NAME_MAP.get(p, p.title())
                    break
        if not dest:
            for p in ["EL DEKHEILA", "DEKHEILA", "DEK", "ALEXANDRIA", "ALX", "AIN SOKHNA", "SOKHNA", "PORT SAID", "PSD", "DAMIETTA", "DAM", "ADABIYA"]:
                if re.search(rf"\b{p}\b", text, re.IGNORECASE):
                    dest = PORT_NAME_MAP.get(p, p.title())
                    break

        return origin, dest

    def _clean_port_name(self, raw: str) -> str:
        s = raw.strip().upper()
        return PORT_NAME_MAP.get(s, raw.strip().title())

    def _extract_free_time(self, text: str) -> Optional[int]:
        # Examples: "21 days FT", "Free time: 21 days", "Free time has 21days", "Free Days: 14", "فترة السماح 21 يوم"
        return self.find_int([
            r"(\d+)\s*(?:days?\s+FT|days?\s+free\s+time|d\s+FT|أيام?\s+سماح|يوم\s+سماح)",
            r"(?:Free\s+Days?\s+Demurrage|Demurrage\s+Free\s+Days?|فترة\s+سماح\s+الديمريج)[:\s]+(\d+)",
            r"(?:Free\s+time(?:\s+has)?|Free\s+Days?|فترة\s+السماح|أيام\s+السماح)[:\s]+(\d+)\s*(?:days?|أيام|يوم)?",
            r"(?:Demurrage\s+Free\s+Days?)[:\s]+(\d+)",
        ], text)

    def _extract_transit_info(self, text: str) -> tuple[Optional[int], bool]:
        transit_days = self.find_int([
            r"(?:Transit\s+time|T/?T|TT|مدة\s+الترانزيت|مدة\s+الإبحار|وقت\s+العبور)[:\s]+(?:direct,?\s*about\s*|about\s*|حوالي\s*)?(\d+)\s*(?:days?|day|أيام|يوم)",
            r"(\d+)\s*(?:days?\s+transit|days?\s+TT|يوم\s+إبحار|يوم\s+ترانزيت)",
        ], text)
        is_direct = True
        if re.search(r"\bINDIRECT\b|\bTRANSSHIPMENT\b|\bVIA\b|غير\s+مباشر|ترانزيت", text, re.IGNORECASE):
            is_direct = False
        elif re.search(r"\bDIRECT\b|مباشر", text, re.IGNORECASE):
            is_direct = True
        return transit_days, is_direct

    def _extract_etd(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:ETD|1st\s+vessel|Vessel\s+Date|تاريخ\s+الإبحار|موعد\s+المغادرة)[:\s]+([0-9]{1,2}[\./\-][0-9]{1,2}(?:[\./\-][0-9]{2,4})?|[0-9]{1,2}[\s\-]+[A-Za-z]{3,4})",
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

        IGNORED_CARRIER_WORDS = {
            "APPROX", "APPROX.", "LOCAL", "OCEAN", "FREIGHT", "RATE", "FEES", "CHARGE", "CHARGES",
            "FEE", "TOTAL", "EXW", "FOB", "CFR", "CIF", "USD", "EUR", "EGP", "GBP", "OF", "O/F",
            "TRANSIT", "FREE", "SERVICE", "ROUTE", "VALID", "VALIDITY", "QUOTE", "RATES", "PRICE",
        }

        # Split text into discrete quotation sections if multiple carrier blocks exist
        raw_blocks = re.split(r"(?=(?:\n\s*EXW\s+[A-Z\u0600-\u06FF]+\-[A-Z\u0600-\u06FF]+|\n\s*FOB\s+[A-Z\u0600-\u06FF]+\-[A-Z\u0600-\u06FF]+|\n\s*•\s*[A-Z]{2,6}:))", text, flags=re.IGNORECASE)
        blocks = [b for b in raw_blocks if b.strip()]
        if not blocks:
            blocks = [text]

        # Extract specific local charges mapped per container type across text
        local_charges_map: Dict[str, float] = {}
        for section in re.finditer(r"(?:Local\s+charges|Ex\-work\s+charges|EXW\s+FEE|المصاريف\s+المحلية|رسوم\s+محلية)[^:\n]*?[:\s]+([\s\S]{1,160}?)(?=\n\s*(?:Ocean|O/?F|Free|ETD|TT|1st|Thanks|\Z))", text, re.IGNORECASE):
            sec_text = section.group(1)
            for lm in re.finditer(r"(?:USD|\$|EUR|EGP)?\s*([0-9,]+(?:\.\d+)?)\s*(?:/|\\)\s*(20(?:GP|DC|ft)?|40(?:HQ|HC|GP|DC|ft)?|CBM|KG)", sec_text, re.IGNORECASE):
                amt = self.parse_numeric_str(lm.group(1))
                ct = self._normalize_cntr(lm.group(2))
                local_charges_map[ct] = amt

        for lm in re.finditer(r"(?:Local\s+charges|Ex\-work\s+charges|EXW\s+FEE|المصاريف\s+المحلية)[^:\n]*?[:\s]+(?:Approx\.?\s*)?(?:USD|\$|EUR|EGP)?\s*([0-9,]+(?:\.\d+)?)\s*(?:/|\\)\s*(20(?:GP|DC|ft)?|40(?:HQ|HC|GP|DC|ft)?|CBM|KG)", text, re.IGNORECASE):
            amt = self.parse_numeric_str(lm.group(1))
            ct = self._normalize_cntr(lm.group(2))
            local_charges_map[ct] = amt

        # Check itemized EXW fees: TRUCK: USD440/40HQ+LOCAL: USD390/40HQ+CUSTOMS:USD 50/BILL
        itemized_exw_total = 0.0
        truck_match = re.search(r"TRUCK[:\s]+(?:USD|\$|EUR)?\s*([0-9,]+)", text, re.IGNORECASE)
        local_fee_match = re.search(r"LOCAL[:\s]+(?:USD|\$|EUR)?\s*([0-9,]+)", text, re.IGNORECASE)
        customs_match = re.search(r"CUSTOMS[:\s]+(?:USD|\$|EUR)?\s*([0-9,]+)", text, re.IGNORECASE)
        if truck_match or local_fee_match or customs_match:
            truck_val = self.parse_numeric_str(truck_match.group(1)) if truck_match else 0.0
            local_val = self.parse_numeric_str(local_fee_match.group(1)) if local_fee_match else 0.0
            cust_val = self.parse_numeric_str(customs_match.group(1)) if customs_match else 0.0
            itemized_exw_total = truck_val + local_val + cust_val

        # Regex captures rate lines supporting standard, unicode quotes, LCL, Air, and OCR formats
        # Notice: container suffix (20|40) must be followed by GP/DC/HQ/HC or word boundary NOT followed by slash or more digits
        rate_pattern = re.compile(
            r"(?:([A-Z0-9\-\.]{2,10})[:\s]+)?(?:O/?F(?:\s*rate)?[:\s]*|نولون(?:\s*بحري)?[:\s]*)?(?:USD|\$|EUR|EGP)?\s*([0-9,]{2,8}(?:\.\d+)?)\s*(?:/|\\)\s*(20\s*(?:GP|DC|ft\b)?|40\s*(?:HQ|HC|GP|DC|ft\b)?|CBM|KG|W/?M)(?!\d)(?:\s+BY\s+([A-Z0-9\-\.\s]{2,15}))?",
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

                # Filter out words like APPROX, LOCAL, RATE from carrier code
                if prefix_carrier and prefix_carrier.upper() in IGNORED_CARRIER_WORDS:
                    prefix_carrier = None

                carrier_code = (suffix_carrier or prefix_carrier or "").strip().upper()
                if carrier_code in IGNORED_CARRIER_WORDS:
                    carrier_code = ""

                carrier_name = KNOWN_CARRIERS.get(carrier_code, carrier_code) if carrier_code else (blk_carrier or self._extract_carrier(text))
                cntr_type = self._normalize_cntr(cntr_raw)
                rate_val = self.parse_numeric_str(raw_rate)

                # Avoid capturing local charges as ocean freight
                pre_text = block[max(0, match.start() - 50):match.start()].lower()
                is_local_line = any(w in pre_text for w in ["local", "محلية", "ex-work", "exw fee", "مصاريف المصنع", "truck"])
                has_freight_keyword = any(w in pre_text for w in ["ocean", "o/f", "freight", "نولون"])
                if is_local_line and not has_freight_keyword:
                    continue

                # Filter out date digits captured as rate (e.g. rate_val < 35 for 20GP/40HQ)
                if rate_val <= 31 and ("20" in cntr_type or "40" in cntr_type):
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
                total_cost = rate_val + (local_fee if "Included" not in block and "شامل" not in block else 0.0)

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
        if "CBM" in s or "W/M" in s or "WM" in s:
            return "LCL (CBM)"
        if "KG" in s:
            return "Air (KG)"
        return "40HQ"

    def _extract_option_notes(self, window: str) -> Optional[str]:
        notes = []
        if re.search(r"INCL\s+OWS|شامل\s+الوزن\s+الزائد", window, re.IGNORECASE):
            notes.append("Includes Overweight Surcharge (OWS)")
        if re.search(r"Included\s+EXW\s+FEE|شامل\s+مصاريف\s+المصنع", window, re.IGNORECASE):
            notes.append("Ocean freight includes EXW fees (Trucking + Local + Customs)")
        if re.search(r"cancel\s+fee|رسوم\s+إلغاء", window, re.IGNORECASE):
            m = re.search(r"(?:cancel\s+fee|رسوم\s+إلغاء)[:\s]+\$?\d+(?:/cntr)?", window, re.IGNORECASE)
            if m:
                notes.append(m.group(0))
        return " | ".join(notes) if notes else None


