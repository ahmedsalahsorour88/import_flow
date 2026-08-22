"""
Customs Clearance & Nafeza Duty Assessment Extractor
Extracts fields from Egyptian Customs Declaration (إقرار جمركي 46 ك.م) and Nafeza Duty Payment Bills (إذن سداد نافذة).
Handles Arabic + English mixed documents.
"""

from __future__ import annotations

import re
from typing import Any, Dict, List, Optional

from modules.smart_document_upload.extractors.base_extractor import BaseExtractor


class CustomsClearanceExtractor(BaseExtractor):

    def required_fields(self) -> List[str]:
        return ["declaration_no", "import_duty", "vat_amount", "total_taxes"]

    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        text = raw_text or ""

        import_duty = self._extract_tax_line(text, [
            r"(?:ضريبة\s+الوارد|ضريبة\s+الجمارك|Customs\s+Duty|Import\s+Duty)[:\s]+([0-9,]+\.?\d*)",
            r"(?:Import\s+Duty\s*%?)[:\s]+([0-9,]+\.?\d*)",
            r"(?:وارد|جمارك)[:\s]+([0-9,]+\.?\d*)",
        ])

        vat_amount = self._extract_tax_line(text, [
            r"(?:ضريبة\s+القيمة\s+المضافة|قيمة\s+مضافة|VAT|Value\s+Added\s+Tax)[:\s]+([0-9,]+\.?\d*)",
            r"(?:Q\.?V\.?A|Tax\s+Amount|ض\.ق\.م)[:\s]+([0-9,]+\.?\d*)",
        ])

        schedule_tax = self._extract_tax_line(text, [
            r"(?:ضريبة\s+الجدول|ضريبة\s+جدول|Schedule\s+Tax|Table\s+Tax)[:\s]+([0-9,]+\.?\d*)",
        ])

        wht_amount = self._extract_tax_line(text, [
            r"(?:أرباح\s+تجارية\s+وصناعية|أرباح\s+تجارية|WHT|Withholding\s+Tax)[:\s]+([0-9,]+\.?\d*)",
            r"(?:خصم\s+تحت\s+حساب\s+الضريبة|ضريبة\s+الخصم)[:\s]+([0-9,]+\.?\d*)",
        ])

        development_fee = self._extract_tax_line(text, [
            r"(?:رسم\s+تنمية|رسم\s+التنمية|Development\s+Fee)[:\s]+([0-9,]+\.?\d*)",
        ])

        lab_service_fees = self._extract_tax_line(text, [
            r"(?:رسوم\s+الخدمات\s+الجمركية|رسوم\s+المعامل\s+والخدمات|Customs\s+Service\s+Fees?|Service\s+Fees?)[:\s]+([0-9,]+\.?\d*)",
            r"(?:مصاريف\s+نافذة|خدمات\s+نافذة|مصروفات\s+إدارية)[:\s]+([0-9,]+\.?\d*)",
        ])

        total_taxes = self._extract_tax_line(text, [
            r"(?:إجمالي\s+الرسوم\s+والضرائب|إجمالي\s+المطلوب\s+سداده|Total\s+Taxes?|Grand\s+Total|Total\s+Payable)[:\s]+([0-9,]+\.?\d*)",
            r"(?:Total\s+Due|المبلغ\s+الإجمالي)[:\s]+([0-9,]+\.?\d*)",
            r"(?:إجمالي)[:\s]+([0-9,]+\.?\d*)",
        ])

        # If total_taxes is missing but individual components exist, sum them up
        calc_total = (import_duty or 0.0) + (vat_amount or 0.0) + (schedule_tax or 0.0) + (wht_amount or 0.0) + (development_fee or 0.0) + (lab_service_fees or 0.0)
        if (total_taxes is None or total_taxes == 0.0) and calc_total > 0:
            total_taxes = calc_total

        result: Dict[str, Any] = {
            "declaration_no": self._extract_declaration_no(text),
            "assessment_reference": self._extract_assessment_ref(text),
            "declaration_date": self._extract_date(text),
            "customs_office_name": self._extract_customs_office(text),
            "channel_type": self._extract_channel(text),
            "hs_code": self._extract_hs_code(text),
            "commodity_description": self._extract_description(text),
            "origin_country": self._extract_country(text),
            "customs_value_egp": self._extract_customs_value(text),
            "exchange_rate": self.find_float([
                r"(?:سعر\s+الصرف|سعر\s+الدولار\s+الجمركي|Exchange\s+Rate|Rate)[:\s]+([0-9]+\.?\d*)",
            ], text),
            "import_duty": import_duty,
            "vat_amount": vat_amount,
            "schedule_tax": schedule_tax,
            "wht_amount": wht_amount,
            "development_fee": development_fee,
            "lab_service_fees": lab_service_fees,
            "total_taxes": total_taxes,
            "total_duty_payable": total_taxes,
        }
        return result

    def _extract_declaration_no(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:بيان\s+رقم|رقم\s+الشهادة\s+الجمركية|Declaration\s+No\.?|Decl\.?\s+#|نموذج\s+46|46\s*ك\.?م?)[:\s]*([0-9]{4,20})",
            r"(?:Customs\s+Declaration)[:\s]*([0-9/\-]{4,20})",
            r"(?:بيان)[:\s]*([0-9]{4,15})",
        ], text)

    def _extract_assessment_ref(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:رقم\s+إذن\s+السداد|إذن\s+سداد\s+رقم|Payment\s+Order\s+No\.?|Assessment\s+Ref\.?)[:\s]*([0-9A-Za-z\-_]{4,25})",
            r"(?:مطالبة\s+رقم|رقم\s+المطالبة)[:\s]*([0-9A-Za-z\-_]{4,25})",
        ], text)

    def _extract_customs_office(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:المركز\s+اللوجستي|جمرك|ميناء|Customs\s+Office|Port)[:\s]+([^\n,]{3,50})",
        ], text)

    def _extract_channel(self, text: str) -> str:
        if re.search(r"(?:مسار\s+أخضر|Green\s+Channel)", text, re.IGNORECASE):
            return "Green Channel"
        if re.search(r"(?:مسار\s+أصفر|Yellow\s+Channel)", text, re.IGNORECASE):
            return "Yellow Channel"
        return "Red Channel"

    def _extract_date(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:تاريخ\s+الإقرار|تاريخ\s+الشهادة|Declaration\s+Date|Date)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
            r"(?:تاريخ)[:\s]+(\d{4}-\d{2}-\d{2})",
        ], text)

    def _extract_hs_code(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:HS\s*Code|Tariff\s*Code|بند\s+التعريفة|بند)[:\s]*([0-9]{4,10}\.?[0-9]*)",
            r"(?:H\.S\.)[:\s]*([0-9]{4,10}\.?[0-9]*)",
        ], text)

    def _extract_description(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:Commodity|Description|البضاعة|وصف\s+البضاعة)[:\s]+([^\n]{10,100})",
        ], text)

    def _extract_country(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:Country\s+of\s+Origin|Origin|بلد\s+المنشأ)[:\s]+([A-Za-z\u0600-\u06ff\s]{3,40}?)(?:\n|,|\|)",
        ], text)

    def _extract_customs_value(self, text: str) -> Optional[float]:
        return self.find_float([
            r"(?:القيمة\s+الجمركية|القيمة\s+CIF|Customs\s+Value|CIF\s+Value)[:\s]+([0-9,]+\.?\d*)",
            r"(?:Dutiable\s+Value)[:\s]+([0-9,]+\.?\d*)",
        ], text)

    def _extract_tax_line(self, text: str, patterns: list) -> Optional[float]:
        return self.find_float(patterns, text)
