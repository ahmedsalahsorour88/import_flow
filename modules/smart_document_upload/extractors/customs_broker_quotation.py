"""
Customs Broker & Clearance Quotation Extractor
Extracts clearance agency fees, local transportation, inspection handling, port expenses,
and multi-container pricing options from Egyptian customs broker offers and rate cards.
"""

from __future__ import annotations

import re
from typing import Any, Dict, List, Optional

from modules.smart_document_upload.extractors.base_extractor import BaseExtractor


PORT_NAME_MAP: Dict[str, str] = {
    "alexandria": "Alexandria Port",
    "alex": "Alexandria Port",
    "اسكندرية": "Alexandria Port",
    "الإسكندرية": "Alexandria Port",
    "dekheila": "El Dekheila Port",
    "الدخيلة": "El Dekheila Port",
    "sokhna": "Sokhna Port",
    "السخنة": "Sokhna Port",
    "عين السخنة": "Sokhna Port",
    "port said": "Port Said",
    "بورسعيد": "Port Said",
    "شرق بورسعيد": "East Port Said",
    "غرب بورسعيد": "West Port Said",
    "damietta": "Damietta Port",
    "دمياط": "Damietta Port",
    "adabiya": "Adabiya Port",
    "الأدبية": "Adabiya Port",
    "cairo airport": "Cairo Airport",
    "مطار القاهرة": "Cairo Airport",
    "6th of october": "6th of October Dry Port",
    "أكتوبر الجاف": "6th of October Dry Port",
}


class CustomsBrokerQuotationExtractor(BaseExtractor):

    def required_fields(self) -> List[str]:
        return ["broker_name", "port_name", "clearance_fee", "total_estimated_clearance_cost"]

    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        text = raw_text or ""

        broker_name = self._extract_broker_name(text)
        port_name = self._extract_port(text)
        container_type = self._extract_container_type(text)
        clearance_fee = self._extract_clearance_fee(text)
        inland_transport_fee = self._extract_inland_transport(text)
        inspection_fee = self._extract_inspection_fee(text)
        port_expenses = self._extract_port_expenses(text)
        miscellaneous_fee = self._extract_miscellaneous_fee(text)
        transit_days = self._extract_clearance_days(text)
        validity_date = self.find_first([
            r"(?:ساري\s+حتى|صلاحية\s+العرض|Valid\s+Until|Validity)[:\s]+([0-9]{4}[-/][0-9]{1,2}[-/][0-9]{1,2})",
            r"(?:Valid\s+to|Expiry)[:\s]+([0-9]{1,2}[-/][0-9]{1,2}[-/][0-9]{4})",
        ], text)

        curr_match = self.find_first([
            r"(?:العملة|Currency)[:\s]*([A-Z]{3}|جنيه|EGP|USD|EUR)",
        ], text)
        currency = curr_match if curr_match else "EGP"
        if "جنيه" in (currency or ""):
            currency = "EGP"

        # Calculate or extract total cost
        extracted_total = self.find_float([
            r"(?:إجمالي\s+عرض\s+الأسعار|إجمالي\s+المقايسة|Total\s+Clearance\s+Cost|Grand\s+Total)[:\s]+([0-9,]+\.?\d*)",
            r"(?:الإجمالي\s+التقديري|Total\s+Estimate)[:\s]+([0-9,]+\.?\d*)",
        ], text)

        calculated_total = (clearance_fee or 0.0) + (inland_transport_fee or 0.0) + (inspection_fee or 0.0) + (port_expenses or 0.0) + (miscellaneous_fee or 0.0)
        total_cost = extracted_total if (extracted_total and extracted_total > 0) else (calculated_total if calculated_total > 0 else (clearance_fee or 0.0))

        rate_options = self._extract_multiple_rate_options(text, default_broker=broker_name, default_port=port_name)

        result: Dict[str, Any] = {
            "broker_name": broker_name,
            "port_name": port_name,
            "container_type": container_type,
            "clearance_fee": clearance_fee,
            "inland_transport_fee": inland_transport_fee,
            "inspection_fee": inspection_fee,
            "port_expenses": port_expenses,
            "miscellaneous_fee": miscellaneous_fee,
            "total_estimated_clearance_cost": total_cost,
            "currency": currency or "EGP",
            "transit_clearance_days": transit_days,
            "validity_date": validity_date,
            "notes": self._extract_notes(text),
            "rate_options": rate_options,
        }
        return result

    def _extract_broker_name(self, text: str) -> Optional[str]:
        match = self.find_first([
            r"(?:مكتب|شركة|مؤسسة)\s+([^\n\r,–—]{3,50}\s+(?:للتخليص\s+الجمركي|للخدمات\s+اللوجستية|والنقل|والاستيراد))",
            r"(?:Customs\s+Broker|Clearance\s+Agent|Broker)[:\s]+([^\n\r,–—]{3,50})",
            r"(?:السادة\s+شركة\s+)(?:[^\n\r]+)(?:عناية|عرض\s+مقدم\s+من)[:\s]*([^\n\r,–—]{3,50})",
            r"(?:Clearance\s+Offer\s+By|Provided\s+By)[:\s]*([^\n\r,–—]{3,50})",
        ], text)
        if match:
            return match.strip()

        for line in text.splitlines()[:5]:
            l = line.strip()
            if any(kw in l for kw in ["تخليص جمركي", "Customs Clearance", "خدمات لوجستية", "مكتب", "Clearance Broker"]):
                return l[:60]
        return "مكتب تخليص جمركي معتمد"

    def _extract_port(self, text: str) -> Optional[str]:
        text_lower = text.lower()
        for k, v in PORT_NAME_MAP.items():
            if k in text_lower:
                return v
        return "Alexandria Port (ميناء الإسكندرية)"

    def _extract_container_type(self, text: str) -> str:
        t = text.upper()
        if "40HQ" in t or "40'HQ" in t or "40 HC" in t or "40' HC" in t or "40HC" in t:
            return "40HQ"
        if "40GP" in t or "40'GP" in t or "40FT" in t or "40 FT" in t or "40 DC" in t:
            return "40GP"
        if "20GP" in t or "20'GP" in t or "20FT" in t or "20 FT" in t or "20 DC" in t:
            return "20GP"
        if "LCL" in t or "جزئي" in text or "طن" in text or "CBM" in t:
            return "LCL"
        if "AIR" in t or "جوي" in text:
            return "Air"
        return "40HQ"

    def _extract_clearance_fee(self, text: str) -> Optional[float]:
        return self.find_float([
            r"(?:(?:ال)?أتعاب\s+(?:ال)?تخليص(?:\s+(?:ال)?جمركي)?|(?:ال)?أتعاب\s+(?:ال)?مكتب|عمولة\s+(?:ال)?تخليص|(?:ال)?أتعاب\s+(?:ال)?جمركية|Clearance\s+Fee|Agency\s+Fee|Broker\s+Fee)[:\s]+([0-9,]+\.?\d*)",
            r"(?:أتعاب|Clearance)[:\s]+([0-9,]+\.?\d*)",
        ], text)

    def _extract_inland_transport(self, text: str) -> Optional[float]:
        return self.find_float([
            r"(?:(?:ال)?نقل\s+(?:ال)?داخلي(?:\s+لمصنع\s+(?:ال)?عميل)?|(?:ال)?نولون\s+(?:ال)?بري|(?:ال)?نقل\s+(?:ال)?بري|(?:ال)?نقل\s+للمصنع|(?:ال)?نقل\s+للمستودع|Inland\s+Transport|Local\s+Trucking|Trucking)[:\s]+([0-9,]+\.?\d*)",
            r"(?:نقل)[:\s]+([0-9,]+\.?\d*)",
        ], text)

    def _extract_inspection_fee(self, text: str) -> Optional[float]:
        return self.find_float([
            r"(?:(?:ال)?م?صاريف\s+(?:ال)?فحص\s+و(?:ال)?عرض(?:\s+هيئة\s+(?:ال)?رقابة)?|(?:ال)?رسوم\s+فحص\s+رقابة|فحص\s+(?:ال)?صادرات\s+و(?:ال)?واردات|(?:ال)?م?صاريف\s+عرض\s+وفحص|Inspection\s+Fee|Handling\s+Fee)[:\s]+([0-9,]+\.?\d*)",
            r"(?:عرض\s+وفحص|فحص|Inspection)[:\s]+([0-9,]+\.?\d*)",
        ], text)

    def _extract_port_expenses(self, text: str) -> Optional[float]:
        return self.find_float([
            r"(?:(?:ال)?رسوم\s+(?:ال)?موانئ\s+و(?:ال)?خدمات\s+(?:ال)?ساحات|(?:ال)?رسوم\s+(?:ال)?موانئ|(?:ال)?م?صاريف\s+تخزين\s+وساحات|تعتيق\s+وتفريغ|أرضيات\s+وميناء|Port\s+Charges|Storage\s+Fee|Demurrage)[:\s]+([0-9,]+\.?\d*)",
            r"(?:أرضيات|ساحات|موانئ)[:\s]+([0-9,]+\.?\d*)",
        ], text)

    def _extract_miscellaneous_fee(self, text: str) -> Optional[float]:
        return self.find_float([
            r"(?:(?:ال)?نثريات\s+و(?:ال)?م?صروفات\s+إدارية|(?:ال)?نثريات|(?:ال)?م?صروفات\s+إدارية|رسوم\s+سحب\s+إذن\s+تسليم|Miscellaneous|Admin\s+Fees?|D/O\s+Handling)[:\s]+([0-9,]+\.?\d*)",
            r"(?:نثريات|مصاريف\s+إدارية)[:\s]+([0-9,]+\.?\d*)",
        ], text)

    def _extract_clearance_days(self, text: str) -> Optional[int]:
        val = self.find_first([
            r"(?:مدة\s+التخليص|التخليص\s+خلال|Clearance\s+Time|Turnaround)[:\s]*([0-9]{1,2})\s*(?:أيام|يوم|days|d)?",
            r"([0-9]{1,2})\s*(?:أيام|يوم)\s*عمل",
        ], text)
        if val:
            try:
                return int(val)
            except ValueError:
                pass
        return 3

    def _extract_notes(self, text: str) -> Optional[str]:
        match = self.find_first([
            r"(?:ملاحظات|شروط\s+السداد|Notes|Payment\s+Terms)[:\s]*([^\n\r]{10,200})",
        ], text)
        return match.strip() if match else None

    def _extract_multiple_rate_options(self, text: str, default_broker: Optional[str], default_port: Optional[str]) -> List[Dict[str, Any]]:
        options: List[Dict[str, Any]] = []

        cntr_pattern = re.compile(
            r"(?:^|\n|\s*)([24][05](?:'|FT|HQ|HC|GP)?|LCL|Air|حاوية\s+[24]0)\s*[:\-–]\s*(?:أتعاب|Clearance)?\s*([0-9,]+(?:\.\d+)?)\s*(?:EGP|جنيه|USD)?",
            re.IGNORECASE
        )
        for m in cntr_pattern.finditer(text):
            cntr_raw = m.group(1).upper()
            fee = float(m.group(2).replace(",", ""))
            normalized_cntr = "40HQ" if ("40" in cntr_raw and ("HQ" in cntr_raw or "HC" in cntr_raw)) else ("40GP" if "40" in cntr_raw else ("20GP" if "20" in cntr_raw else "LCL"))
            options.append({
                "broker_name": default_broker or "Customs Broker",
                "port_name": default_port or "Alexandria Port",
                "container_type": normalized_cntr,
                "clearance_fee": fee,
                "inland_transport_fee": None,
                "inspection_fee": None,
                "port_expenses": None,
                "total_estimated_clearance_cost": fee,
                "currency": "EGP",
                "transit_clearance_days": 3,
                "notes": f"مستخرج تلقائياً لبند {normalized_cntr}",
            })

        return options
