"""
Customs Clearance Extractor
Extracts fields from Egyptian Customs Declaration (بيان جمركي) documents.
Handles Arabic + English mixed documents.
"""

from __future__ import annotations

import re
from typing import Any, Dict, List, Optional

from modules.smart_document_upload.extractors.base_extractor import BaseExtractor


class CustomsClearanceExtractor(BaseExtractor):

    def required_fields(self) -> List[str]:
        return ["declaration_no", "hs_code", "customs_value_egp", "total_taxes"]

    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        text = raw_text or ""

        result: Dict[str, Any] = {
            "declaration_no": self._extract_declaration_no(text),
            "declaration_date": self._extract_date(text),
            "hs_code": self._extract_hs_code(text),
            "commodity_description": self._extract_description(text),
            "origin_country": self._extract_country(text),
            "customs_value_egp": self._extract_customs_value(text),
            "exchange_rate": self.find_float([
                r"(?:سعر\s+الصرف|Exchange\s+Rate|Rate)[:\s]+([0-9]+\.?\d*)",
            ], text),
            "import_duty": self._extract_tax_line(text, [
                r"(?:ضريبة\s+الوارد|Import\s+Duty|Customs\s+Duty)[:\s]+([0-9,]+\.?\d*)",
                r"(?:Import\s+Duty\s*%?)[:\s]+([0-9,]+\.?\d*)",
            ]),
            "vat_amount": self._extract_tax_line(text, [
                r"(?:ضريبة\s+القيمة\s+المضافة|VAT|Value\s+Added\s+Tax)[:\s]+([0-9,]+\.?\d*)",
                r"(?:Q\.?V\.?A|Tax\s+Amount)[:\s]+([0-9,]+\.?\d*)",
            ]),
            "schedule_tax": self._extract_tax_line(text, [
                r"(?:ضريبة\s+الجدول|Schedule\s+Tax|Table\s+Tax)[:\s]+([0-9,]+\.?\d*)",
            ]),
            "customs_service_fees": self._extract_tax_line(text, [
                r"(?:رسوم\s+الخدمات\s+الجمركية|Customs\s+Service\s+Fees?)[:\s]+([0-9,]+\.?\d*)",
            ]),
            "total_taxes": self._extract_tax_line(text, [
                r"(?:إجمالي|Total\s+Taxes?|Grand\s+Total\s+Taxes?)[:\s]+([0-9,]+\.?\d*)",
                r"(?:Total\s+Due)[:\s]+([0-9,]+\.?\d*)",
            ]),
        }
        return result

    def _extract_declaration_no(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:بيان\s+رقم|Declaration\s+No\.?|Decl\.?\s+#)[:\s]*([0-9]{4,20})",
            r"(?:Customs\s+Declaration)[:\s]*([0-9/\-]{4,20})",
            r"(?:بيان)[:\s]*([0-9]{4,15})",
        ], text)

    def _extract_date(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:تاريخ\s+الإقرار|Declaration\s+Date|Date)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
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
            r"(?:القيمة\s+الجمركية|Customs\s+Value|CIF\s+Value)[:\s]+([0-9,]+\.?\d*)",
            r"(?:Dutiable\s+Value)[:\s]+([0-9,]+\.?\d*)",
        ], text)

    def _extract_tax_line(self, text: str, patterns: list) -> Optional[float]:
        return self.find_float(patterns, text)
