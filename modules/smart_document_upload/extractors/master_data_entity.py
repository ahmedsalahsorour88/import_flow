"""
Universal Master Data Entity Extractor
Extracts company name, contact person, mobile, phone, email, website, VAT/Tax ID, address, country, postcode, and industry description
from raw pasted text, image OCR, PDF, or Excel files for coding Suppliers, Importing Companies, Partners, and Banks.
"""

from __future__ import annotations

import re
from typing import Any, Dict, List, Optional

from modules.smart_document_upload.extractors.base_extractor import BaseExtractor


class MasterDataEntityExtractor(BaseExtractor):

    def required_fields(self) -> List[str]:
        return ["company_name", "phone_number", "country_code"]

    def extract(self, raw_text: str, spatial_boxes: dict = None) -> Dict[str, Any]:
        text = raw_text or ""

        result: Dict[str, Any] = {
            "company_name": self._extract_company_name(text),
            "arabic_name": self._extract_arabic_name(text),
            "contact_person": self._extract_contact_person(text),
            "mobile_number": self._extract_mobile(text),
            "phone_number": self._extract_phone(text),
            "fax_number": self._extract_fax(text),
            "website": self._extract_website(text),
            "email": self._extract_email(text),
            "vat_tax_id": self._extract_tax_id(text),
            "address": self._extract_address(text),
            "country_code": self._extract_country(text),
            "postcode": self._extract_postcode(text),
            "industry_description": self._extract_industry(text),
            "commercial_register": self._extract_commercial_register(text),
            "registration_expiry": self._extract_registration_expiry(text),
            "importer_id": self._extract_importer_id(text),
            "importer_id_expiry": self._extract_importer_expiry(text),
            "vat_id_expiry": self._extract_vat_expiry(text),
            "cargox_id": self._extract_cargox_id(text),
            "license_number": self._extract_broker_license(text),
            "swift_code": self._extract_swift(text),
            "bank_account": self._extract_iban(text),
            "iban": self._extract_iban(text),
        }
        return result

    def _extract_importer_expiry(self, text: str) -> Optional[str]:
        for line in text.splitlines():
            if any(kw in line.lower() for kw in ["importer", "import card", "استيرادية"]):
                m = re.search(r"(\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{4})", line)
                if m:
                    return m.group(1)
        return self.find_first([
            r"(?:Importer\s+Card\s+Expiry|Import\s+Card\s+Expiry|انتهاء\s+البطاقة\s+الاستيرادية)[:\s]*([0-9]{4}[-/][0-9]{1,2}[-/][0-9]{1,2}|[0-9]{1,2}[-/][0-9]{1,2}[-/][0-9]{4})",
        ], text)

    def _extract_vat_expiry(self, text: str) -> Optional[str]:
        for line in text.splitlines():
            if any(kw in line.lower() for kw in ["vat", "tax", "الضريبية", "ضريبية"]):
                m = re.search(r"(\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{4})", line)
                if m:
                    return m.group(1)
        return self.find_first([
            r"(?:VAT\s+Expiry|VAT\s+Registration\s+Expiry|Tax\s+Card\s+Expiry|انتهاء\s+البطاقة\s+الضريبية)[:\s]*([0-9]{4}[-/][0-9]{1,2}[-/][0-9]{1,2}|[0-9]{1,2}[-/][0-9]{1,2}[-/][0-9]{4})",
        ], text)

    def _extract_registration_expiry(self, text: str) -> Optional[str]:
        for line in text.splitlines():
            if any(kw in line.lower() for kw in ["cr", "commercial", "السجل", "سجل"]):
                m = re.search(r"(\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{4})", line)
                if m:
                    return m.group(1)
        return self.find_first([
            r"(?:CR\s+Expiry|Commercial\s+Reg\s+Expiry|انتهاء\s+السجل\s+التجاري)[:\s]*([0-9]{4}[-/][0-9]{1,2}[-/][0-9]{1,2}|[0-9]{1,2}[-/][0-9]{1,2}[-/][0-9]{4})",
        ], text)

    def _extract_cargox_id(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:CargoX\s+ID|CargoX|Blockchain\s+ID|CargoX\s+Account)[:\s]*([A-Za-z0-9\-_]{5,42})",
            r"\b(0x[a-fA-F0-9]{40})\b",
            r"\b(CX-[A-Za-z0-9]{6,16})\b",
        ], text)

    def _extract_importer_id(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:Importer\s+Card|Import\s+Card|البطاقة\s+الاستيرادية|بطاقة\s+استيرادية|كود\s+المستورد)[:\s]*([0-9]{4,15})",
            r"\b(IMP-[0-9]{4,10})\b",
        ], text)

    def _extract_broker_license(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:Broker\s+License|License\s+No\.?|رخصة\s+التخليص|رقم\s+القيد)[:\s]*([A-Za-z0-9\-_/]{3,20})",
        ], text)

    def _extract_arabic_name(self, text: str) -> Optional[str]:
        # Look for Arabic company names
        lines = [l.strip() for l in text.splitlines() if l.strip()]
        for l in lines:
            if re.search(r"[\u0600-\u06FF]{3,}", l) and any(kw in l for kw in ["شركة", "مؤسسة", "مكتب", "للاستيراد", "للتجارة", "ش.م.م", "ذ.م.م"]):
                return l
        return None

    def _extract_company_name(self, text: str) -> Optional[str]:
        # 1. Look for explicit company lines with legal suffixes
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        for line in lines:
            upper = line.upper()
            if any(kw in upper for kw in ["LIMITED", "LTD", "INC", "CORP", "CO.,LTD", "CO., LTD", "S.P.A", "GMBH", "LLC", "PLC", "HOLDING", "SHAWCONTRACT"]):
                if not any(stop in upper for stop in ["ADDRESS:", "VAT NUMBER", "PHONE", "TEL:", "FACTORY ADDRESS"]):
                    return line.strip()

        # 2. Look for labeled Company Name
        labeled = self.find_first([
            r"(?:Company\s+Name|Company|Supplier|Exporter|Name)[:\s]+([A-Za-z0-9\s&,.'-]{3,60}?)(?:\n|,|\|)",
        ], text)
        if labeled:
            return labeled.strip()

        return lines[0] if lines else None

    def _extract_contact_person(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:Contact\s+Person|Contact|Owner|Factory\s+owner|Manager|Attn|Attention|المسؤول|المدير)[:\s]*([A-Za-z0-9\s.\u0600-\u06FF]{3,40})",
            r"\b(Factory\s+owner)\b",
        ], text)

    def _extract_mobile(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:M|Mob|Mobile|Cell|محمول|موبايل)[:\s]*(\+?[0-9\s\-]{8,20})",
            r"(0086\s*1[3-9]\d{9}|\+86\s*1[3-9]\d{9})",
            r"(\+20\s*1[0-5]\d{8})",
        ], text)

    def _extract_phone(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:Phone|Tel\.?|Telephone|الهاتف|هاتف|تليفون)[:\s]*(\+?[0-9\s\-\(\)]{8,20})",
            r"(\+44\s*1\d{3}\s*\d{5,6})",
            r"(\+39\s*0\d{2,4}\s*\d{5,8})",
            r"(\+86\s*\d{2,4}\s*\d{7,8})",
            r"(\+370\s*5\s*\d{3}\s*\d{4})",
        ], text)

    def _extract_fax(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:Fax|فاكس)[:\s]*(\+?[0-9\s\-\(\)]{8,20})",
        ], text)

    def _extract_website(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:W|Web|Website|الموقع)[:\s]*(www\.[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})",
            r"\b(www\.[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})\b",
        ], text)

    def _extract_email(self, text: str) -> Optional[str]:
        m = re.search(r"\b([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})\b", text)
        return m.group(1) if m else None

    def _extract_tax_id(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:VAT\s+Number|VAT\s+No\.?|P\.IVA|Tax\s+ID|C\.F\.|Registration\s+No\.?|البطاقة\s+الضريبية|بطاقة\s+ضريبية|التسجيل\s+الضريبي|الرقم\s+الضريبي)[:\s]*([A-Za-z0-9\-]+)",
            r"VAT\s+Number\s+([0-9]+)",
            r"P\.IVA\s+([A-Za-z0-9]+)",
        ], text)

    def _extract_address(self, text: str) -> Optional[str]:
        labeled = self.find_first([
            r"(?:Factory\s+Address|Address|Location|العنوان|المقر)[:\s]*([^\n]{10,120})",
        ], text)
        if labeled:
            return labeled.strip()

        # Look for multi-line address clues (Road, Street, Town, City, Province, District)
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        addr_lines = []
        for line in lines:
            upper = line.upper()
            if any(kw in upper for kw in ["ROAD", "STREET", "TOWN", "CITY", "PROVINCE", "KINGDOM", "ITALY", "CHINA", "GERMANY", "DISTRICT", "NO.16", "BLACKADDIE", "VIA G.", "شارع", "القاهرة", "الإسكندرية"]):
                if not any(stop in upper for stop in ["PHONE", "VAT NUMBER", "OWNER", "WEBSITE", "FAX", "البطاقة"]):
                    addr_lines.append(line)
        return ", ".join(addr_lines) if addr_lines else None

    def _extract_country(self, text: str) -> Optional[str]:
        found = self.find_first([
            r"\b(China|United\s+Kingdom|UK|Italy|Lithuania|Germany|Egypt|USA|Spain|France|Jiangsu|United Kingdom|مصر)\b",
        ], text)
        if not found:
            return None
        c = found.strip().upper()
        if c in ["CHINA", "JIANGSU", "CN"]:
            return "CN"
        if c in ["UNITED KINGDOM", "UK", "GREAT BRITAIN"]:
            return "GB"
        if c in ["ITALY", "IT"]:
            return "IT"
        if c in ["LITHUANIA", "LT"]:
            return "LT"
        if c in ["EGYPT", "EG", "مصر"]:
            return "EG"
        if c in ["GERMANY", "DE"]:
            return "DE"
        if c in ["USA", "US"]:
            return "US"
        return c

    def _extract_postcode(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:Postcode|Zip|Postal\s+Code)[:\s]*([A-Za-z0-9\s]{4,10})",
            r"\b(\d{6})\b",  # Chinese 6-digit postal code e.g. 215500
            r"\b([A-Z]{1,2}\d[A-Z0-9]?\s*\d[A-Z]{2})\b",  # UK postcode e.g. DG4 6DB
            r"\b(\d{5})\b",  # Italian 5-digit postal code e.g. 33053
        ], text)

    def _extract_industry(self, text: str) -> Optional[str]:
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        for line in lines:
            upper = line.upper()
            if any(kw in upper for kw in ["MANUFACTURER", "TRADING", "SUPPLIER", "INDUSTRIES", "CARPET", "ACOUSTIC", "TEXTILE", "HVAC", "FURNITURE"]):
                if not any(stop in upper for stop in ["ADDRESS:", "FACTORY ADDRESS", "FACTORY OWNER", "PHONE", "VAT NUMBER", "LIMITED", "LTD"]):
                    return line
        return None

    def _extract_commercial_register(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:Commercial\s+Register|C\.R\.|CR\s+No\.?|Sijil|Enterprise\s+code|السجل\s+التجاري|سجل\s+تجاري)[:\s]*([A-Za-z0-9]+)",
            r"Enterprise\s+code\s+([0-9]+)",
            r"C\.R\.\s*([0-9]+)",
        ], text)

    def _extract_swift(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:SWIFT|Swift\s+Code|BIC|SWIFT/BIC)[:\s]*([A-Z0-9]{8,11})",
            r"\b([A-Z]{4}[A-Z]{2}[A-Z0-9]{2}(?:[A-Z0-9]{3})?)\b",
        ], text)

    def _extract_iban(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:IBAN|Account\s+No\.?|Account|الآيبان|الحساب)[:\s]*([A-Z0-9\s]{10,34})",
            r"\b(EG\d{27})\b",
        ], text)
