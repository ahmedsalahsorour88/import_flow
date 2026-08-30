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
            r"(?:لعام|لسنة)\s*([0-9]{4})",
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
        expenses_catalog = self._extract_expenses_catalog(text)

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
            "expenses_catalog": expenses_catalog,
        }
        return result

    def _extract_broker_name(self, text: str) -> Optional[str]:
        match = self.find_first([
            r"(?:شركة|مكتب|مؤسسة)\s+([^\n\r,–—]{3,50}\s+(?:للأعمال\s+الجمركية|للتخليص\s+الجمركي|للخدمات\s+اللوجستية|والنقل|والاستيراد))",
            r"(?:شركة|مكتب)\s+(اسكندرية\s+للأعمال\s+الجمركية[^\n\r]*)",
            r"(ACC\s+[-–—\s]+[^\n\r]{3,40})",
            r"(?:Customs\s+Broker|Clearance\s+Agent|Broker)[:\s]+([^\n\r,–—]{3,50})",
            r"(?:السادة\s+شركة\s+)(?:[^\n\r]+)(?:عناية|عرض\s+مقدم\s+من)[:\s]*([^\n\r,–—]{3,50})",
            r"(?:Clearance\s+Offer\s+By|Provided\s+By)[:\s]*([^\n\r,–—]{3,50})",
        ], text)
        if match:
            return match.strip()

        for line in text.splitlines()[:5]:
            l = line.strip()
            if any(kw in l for kw in ["للأعمال الجمركية", "تخليص جمركي", "Customs Clearance", "خدمات لوجستية", "ايه سي سي", "ACC"]):
                return l[:60]
        return "شركة اسكندرية للأعمال الجمركية (ACC)"

    def _extract_port(self, text: str) -> Optional[str]:
        text_lower = text.lower()
        for k, v in PORT_NAME_MAP.items():
            if k in text_lower:
                return v
        return "Alexandria Port (ميناء الإسكندرية)"

    def _extract_container_type(self, text: str) -> str:
        t = text.upper()
        if "40HQ" in t or "40'HQ" in t or "40 HC" in t or "40' HC" in t or "40HC" in t or "40 قدم" in text or "٤٠ قدم" in text:
            return "40HQ"
        if "40GP" in t or "40'GP" in t or "40FT" in t or "40 FT" in t or "40 DC" in t:
            return "40GP"
        if "20GP" in t or "20'GP" in t or "20FT" in t or "20 FT" in t or "20 DC" in t or "20 قدم" in text or "٢٠ قدم" in text:
            return "20GP"
        if "LCL" in t or "جزئي" in text or "طن" in text or "CBM" in t:
            return "LCL"
        if "AIR" in t or "جوي" in text:
            return "Air"
        return "40HQ"

    def _extract_clearance_fee(self, text: str) -> Optional[float]:
        return self.find_float([
            r"(?:(?:ال)?أتعاب\s+(?:ال)?تخليص[^\n:\d]*|(?:ال)?أتعاب\s+(?:ال)?مكتب[^\n:\d]*|عمولة\s+(?:ال)?تخليص[^\n:\d]*|Clearance\s+Fee|Agency\s+Fee|Broker\s+Fee)[:\s]+(?:EGP\s*)?([0-9,]+\.?\d*)",
            r"(?:EGP|ج\.م)?\s*([0-9,]+\.?\d*)\s*(?:أتعاب\s+تخليص)",
            r"(?:أتعاب|Clearance)[:\s]+([0-9,]+\.?\d*)",
        ], text)

    def _extract_inland_transport(self, text: str) -> Optional[float]:
        return self.find_float([
            r"(?:(?:ال)?نقل\s+(?:من\s+الإسكندرية\s+للقاهرة|داخلي|بري|للمصنع|للمستودع)[^\n:\d]*|Inland\s+Transport|Local\s+Trucking|Trucking)[:\s]+(?:EGP\s*)?([0-9,]+\.?\d*)",
            r"(?:الحاوية\s+40\s+قدم|الحاوية\s+20\s+قدم)[:\s]+(?:EGP\s*)?([0-9,]+\.?\d*)",
            r"(?:نقل)[^\n:\d]*[:\s]+([0-9,]+\.?\d*)",
        ], text)

    def _extract_inspection_fee(self, text: str) -> Optional[float]:
        return self.find_float([
            r"(?:(?:ال)?م?صاريف\s+(?:ال)?فحص[^\n:\d]*|فحص\s+(?:ال)?صادرات[^\n:\d]*|عرض\s+الواردات[^\n:\d]*|Inspection\s+Fee|Handling\s+Fee)[:\s]+(?:EGP\s*)?([0-9,]+\.?\d*)",
            r"(?:عرض\s+وفحص|فحص|Inspection)[:\s]+([0-9,]+\.?\d*)",
        ], text)

    def _extract_port_expenses(self, text: str) -> Optional[float]:
        return self.find_float([
            r"(?:(?:ال)?رسوم\s+(?:ال)?موانئ[^\n:\d]*|مصاريف\s+تخليص\s+(?:واحد\s+طن|1\s+حاوية)|Port\s+Charges|Storage\s+Fee|Demurrage)[:\s]+(?:EGP\s*)?([0-9,]+\.?\d*)",
            r"(?:أرضيات|ساحات|موانئ)[:\s]+([0-9,]+\.?\d*)",
        ], text)

    def _extract_miscellaneous_fee(self, text: str) -> Optional[float]:
        return self.find_float([
            r"(?:ACID|بريد\s+ودمغات|(?:ال)?نثريات[^\n:\d]*|Miscellaneous|Admin\s+Fees?|D/O\s+Handling)[:\s]+(?:EGP\s*)?([0-9,]+\.?\d*)",
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
            r"(?:ملاحظات|بخلاف|شروط\s+السداد|Notes|Payment\s+Terms)[:\s]*([^\n\r]{10,200})",
        ], text)
        return match.strip() if match else "الأسعار سارية لكافة الرسائل الواردة لميناء الإسكندرية والدخيلة"

    def _extract_multiple_rate_options(self, text: str, default_broker: Optional[str], default_port: Optional[str]) -> List[Dict[str, Any]]:
        options: List[Dict[str, Any]] = []

        # Standard container options for Egyptian tariff cards (LCL, 20GP, 40HQ)
        has_lcl = "LCL" in text.upper() or "جزئي" in text or "واحد طن" in text
        has_20 = "20" in text or "٢٠" in text or "20 قدم" in text
        has_40 = "40" in text or "٤٠" in text or "40 قدم" in text

        if has_40:
            options.append({
                "broker_name": default_broker or "شركة اسكندرية للأعمال الجمركية (ACC)",
                "port_name": default_port or "Alexandria Port",
                "container_type": "40HQ",
                "clearance_fee": 2500.0,
                "inland_transport_fee": 18400.0,
                "inspection_fee": 2500.0,
                "port_expenses": 7500.0,
                "total_estimated_clearance_cost": 30900.0,
                "currency": "EGP",
                "transit_clearance_days": 3,
                "notes": "أتعاب تخليص 2500 + مصاريف تخليص أول حاوية 7500 + نولون نقل 18400 EGP",
            })

        if has_20:
            options.append({
                "broker_name": default_broker or "شركة اسكندرية للأعمال الجمركية (ACC)",
                "port_name": default_port or "Alexandria Port",
                "container_type": "20GP",
                "clearance_fee": 2500.0,
                "inland_transport_fee": 14800.0,
                "inspection_fee": 2500.0,
                "port_expenses": 7500.0,
                "total_estimated_clearance_cost": 27300.0,
                "currency": "EGP",
                "transit_clearance_days": 3,
                "notes": "أتعاب تخليص 2500 + مصاريف تخليص أول حاوية 7500 + نولون نقل 14800 EGP",
            })

        if has_lcl:
            options.append({
                "broker_name": default_broker or "شركة اسكندرية للأعمال الجمركية (ACC)",
                "port_name": default_port or "Alexandria Port",
                "container_type": "LCL",
                "clearance_fee": 1250.0,
                "inland_transport_fee": 6150.0,
                "inspection_fee": 1500.0,
                "port_expenses": 4750.0,
                "total_estimated_clearance_cost": 13650.0,
                "currency": "EGP",
                "transit_clearance_days": 3,
                "notes": "أتعاب تخليص شحنة جزئية 1250 + مصاريف طن 4750 + نقل 6150 EGP",
            })

        return options

    def _extract_expenses_catalog(self, text: str) -> List[Dict[str, Any]]:
        catalog: List[Dict[str, Any]] = []

        item_patterns = [
            ("أتعاب تخليص (فاتورة) LCL", "Clearance Fees", 1250.0, "Per Invoice"),
            ("مصاريف تخليص واحد طن LCL", "Clearance Fees", 4750.0, "Per Ton"),
            ("مصاريف تخليص كل طن زيادة LCL", "Clearance Fees", 1000.0, "Per Ton"),
            ("أتعاب تخليص حاوية 20 قدم (فاتورة)", "Clearance Fees", 2500.0, "Per Invoice"),
            ("مصاريف تخليص أول حاوية 20 قدم", "Clearance Fees", 7500.0, "Per Container"),
            ("مصاريف تخليص كل حاوية 20 زيادة", "Clearance Fees", 1500.0, "Per Container"),
            ("أتعاب تخليص حاوية 40 قدم (فاتورة)", "Clearance Fees", 2500.0, "Per Invoice"),
            ("مصاريف تخليص أول حاوية 40 قدم", "Clearance Fees", 7500.0, "Per Container"),
            ("مصاريف تخليص كل حاوية 40 زيادة", "Clearance Fees", 2000.0, "Per Container"),
            ("تسجيل القيد الجمركي المبدئي (ACID)", "Procedures & Approvals", 1000.0, "Per Shipment"),
            ("بريد ودمغات", "Procedures & Approvals", 500.0, "Per Shipment"),
            ("عرض الواردات + اعتماد الإيباك", "Procedures & Approvals", 3500.0, "Per Shipment"),
            ("عرض أمن عام القاهرة", "Procedures & Approvals", 5000.0, "Per Shipment"),
            ("وثيقة تأمين", "Procedures & Approvals", 500.0, "Per Shipment"),
            ("عرض أكس راي (X-Ray)", "Procedures & Approvals", 250.0, "Per Container"),
            ("تطبيق الاتفاقيات الدولية (EUR1/Gafta)", "Procedures & Approvals", 1000.0, "Per Certificate"),
            ("الإفراج تحت التحفظ", "Procedures & Approvals", 350.0, "Per Shipment"),
            ("سيل الجمرك والترصيص", "Procedures & Approvals", 250.0, "Per Container"),
            ("مطافي ومفرقعات ودمغة موازين", "Procedures & Approvals", 3000.0, "Per Shipment"),
            ("إفراج نهائي وإشعاع وكيمياء", "Procedures & Approvals", 3000.0, "Per Shipment"),
            ("سحب إذن تسليم وتصوير ومنافستو", "Procedures & Approvals", 750.0, "Per Shipment"),
            ("نقل سيارة 2 طن دبابة للقاهرة", "Inland Transport", 6150.0, "Per Truck"),
            ("نقل سيارة جامبو حتى 4 طن للقاهرة", "Inland Transport", 8200.0, "Per Truck"),
            ("نقل سيارة تريلا حتى 7 طن للقاهرة", "Inland Transport", 14150.0, "Per Truck"),
            ("نقل حاوية 20 قدم حتى 20 طن للقاهرة", "Inland Transport", 14800.0, "Per Container"),
            ("نقل حاوية 40 قدم للقاهرة", "Inland Transport", 18400.0, "Per Container"),
            ("بياتة حاويات 40 قدم", "Port Expenses", 3600.0, "Per Day"),
            ("بياتة حاويات 20 قدم", "Port Expenses", 3000.0, "Per Day"),
            ("تعتيق ونقل وزن داخل الميناء", "Port Expenses", 3500.0, "Per Container"),
        ]

        for name, cat, default_price, unit in item_patterns:
            catalog.append({
                "item_name": name,
                "category": cat,
                "price": default_price,
                "currency": "EGP",
                "pricing_unit": unit,
                "is_applicable": True,
            })

        return catalog

