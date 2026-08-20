"""
COO Certificate Extractor
Extracts Certificate of Origin fields from COO / EUR.1 PDFs.
"""

from __future__ import annotations

from typing import Any, Dict, List

from modules.smart_document_upload.extractors.base_extractor import BaseExtractor


import re


class COOCertificateExtractor(BaseExtractor):
    """
    Enhanced Certificate of Origin Extractor.
    Extracts structured fields from China CCPIT, EUR.1, and Standard COO documents.
    """

    def required_fields(self) -> List[str]:
        return ["certificate_number", "origin_country", "product_description"]

    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        text = (raw_text or "").replace('\r', '\n')

        # 1. Certificate Number
        cert_no = self.find_first([
            r"(?:Certificate\s+(?:No\.?|Number|#)|Cert\.?\s*No\.?)[:\s]*([0-9A-Z/_-]{6,35})",
            r"Serial\s*No\.?\s*\n?\s*(?:Certificate\s*No\.?\s*)?([0-9A-Z/_-]{6,35})",
            r"(?:CO\s+No\.?|No\.)[:\s]*([0-9A-Z/_-]{6,35})",
        ], text)

        # 2. Exporter (Box 1)
        exporter_name = None
        exp_m = re.search(r'(?:1\.?\s*Exporter|Shipper|Consignor)[:\s]*\n?([^\n]+(?:\n[^\n]+){1,4}?)(?=\n\s*(?:\*\*\*|Serial|Certificate|2\.|\bConsignee\b|\bImporter\b))', text, re.I)
        if exp_m:
            lines = [l.strip() for l in exp_m.group(1).splitlines() if l.strip() and not l.strip().startswith('***')]
            exporter_name = lines[0] if lines else None
        if not exporter_name:
            exp_m2 = re.search(r'([A-Z0-9\s,\.\-&]+(?:IMP&EXP|CO\.,\s*LTD|COMPANY|CORP|MANUFACTURING|GMBH|LLC|LTD)[^\n]*)', text)
            if exp_m2:
                exporter_name = exp_m2.group(1).strip()
        if not exporter_name:
            exporter_name = self.find_first([
                r"(?:Exporter|Shipper|Consignor|Producer)[:\s]+([A-Za-z0-9\s&,.'-]{3,80}?)(?:\n|,|\|)",
            ], text)

        # 3. Consignee / Importer (Box 2)
        consignee_name = None
        cons_m = re.search(r'(?:2\.?\s*Consignee|Importer|Buyer)[:\s]*\n?([^\n]+(?:\n[^\n]+){1,4}?)(?=\n\s*(?:3\.|Means|4\.|Country|5\.|\bFor certifying\b))', text, re.I)
        if cons_m:
            lines = [l.strip() for l in cons_m.group(1).splitlines() if l.strip() and l.strip() not in ('OF', 'ORIGINAL')]
            consignee_name = lines[0] if lines else None
        if not consignee_name:
            cons_m2 = re.search(r'(?:CONSIGNEE|IMPORTER)[:\s]+([A-Za-z0-9\s&,.\'-]{3,80})', text, re.I)
            if cons_m2 and cons_m2.group(1).strip() not in ('OF', 'ORIGINAL'):
                consignee_name = cons_m2.group(1).strip()
        if not consignee_name:
            consignee_name = self.find_first([
                r"(?:Consignee|Importer|Buyer)[:\s]+([A-Za-z0-9\s&,.'-]{3,80}?)(?:\n|,|\|)",
            ], text)

        # 4. Origin Country
        origin_country = None
        if re.search(r'THE\s+PEOPLE\'?S\s+REPUBLIC\s+OF\s+CHINA|produced\s+in\s+China|Origin\s+of\s+the\s+People\'?s\s+Republic\s+of\s+China|CCPIT', text, re.I):
            origin_country = 'China'
        elif re.search(r'EUROPEAN\s+COMMUNITY|EUR\.?1', text, re.I):
            m_eur = re.search(r'(?:produced\s+in|originated\s+in|Country\s+of\s+origin)[:\s]+([A-Za-z\s]{3,40})', text, re.I)
            origin_country = m_eur.group(1).strip() if m_eur else 'European Union'
        else:
            origin_country = self.find_first([
                r"(?:Country\s+of\s+Origin|Origin\s+Country)[:\s]+([A-Za-z\s]{3,40}?)(?:\n|,|\|)",
                r"(?:This\s+is\s+to\s+certify\s+that\s+the\s+goods?\s+originated?\s+(?:from|in))[:\s]+([A-Za-z\s]{3,40}?)(?:\n|,|\.|;)",
                r"(?:produced\s+in)[:\s]+([A-Za-z\s]{3,40}?)(?:\n|,|\.|;)",
            ], text)

        # 5. Destination Country
        destination_country = self.find_first([
            r"(?:4\.?\s*Country\s*(?:/\s*region)?\s*of\s*destination)[:\s]*([A-Za-z\s]{3,40}?)(?:\n|,|\|)",
            r"(?:Destination\s+Country|Destination)[:\s]+([A-Za-z\s]{3,40}?)(?:\n|,|\|)",
        ], text) or "Egypt"

        # Table block text between items description and declaration
        table_m = re.search(r'(?:6\.Marks|7\.Number|description\s+of\s+goods)(.*?)(?=11\.Declaration|12\.Certification|\Z)', text, re.S | re.I)
        table_text = table_m.group(1) if table_m else text

        # 6. HS Code
        hs_code = None
        hs_m = re.search(r'\b(5602\d{2}|9401\d{2}|9403\d{2}|[0-9]{6,8})\b', table_text)
        if hs_m:
            hs_code = hs_m.group(1).strip()
        if not hs_code:
            hs_code = self.find_first([
                r"(?:8\.?\s*H\.?S\.?\s*Code|HS\s*Code|Tariff\s*(?:Code|No\.?))[:\s]*([0-9]{4,10}\.?[0-9]*)",
            ], text)

        # 7. ACID Number
        acid_number = self.find_first([
            r"ACID[:\s\-_]*([0-9]{19})",
            r"\b([0-9]{19})\b",
        ], text)

        # 8. Product Description
        clean_table = re.sub(r'6\.Marks[^\n]*|7\.Number[^\n]*|8\.H\.S\.Code[^\n]*|9\.Quantity[^\n]*|10\.Number[^\n]*|and\s+date\s+of[^\n]*|\binvoices\b|\*\*\*|and\s+numbers|\bG\.WEIGHT\b|\bGROSS\s+WEIGHT\b', '', table_text, flags=re.I)
        clean_lines = [l.strip() for l in clean_table.splitlines() if l.strip()]
        goods_lines = []
        for l in clean_lines:
            if not re.search(r'^\d+\s*KGS|GRS|INV-|MAY\.|JUL\.|JAN\.|FEB\.|MAR\.|APR\.|JUN\.|AUG\.|SEP\.|OCT\.|NOV\.|DEC\.', l, re.I):
                l_clean = re.sub(r'ACID[:\s]*\d{19}', '', l, flags=re.I).strip()
                l_clean = re.sub(r'\b5602\d{2}\b|\b\d{6,8}\b|\b\d+\s*SHEETS\b|\b\d+\s*KGS(?:\s*G\.?W\.?)?\b', '', l_clean).strip()
                if l_clean and len(l_clean) > 3 and not re.search(r'description\s+of\s+goods|^and\s+numbers$', l_clean, re.I):
                    goods_lines.append(l_clean)
        product_description = ' / '.join(goods_lines) if goods_lines else self.find_first([
            r"(?:Description\s+of\s+Goods?|Goods?|Products?|Merchandise)[:\s]+([^\n]{10,150})",
        ], text)

        # 9. Invoice Number & Date
        invoice_number = None
        inv_m = re.search(r'\b(GRS[0-9A-Z]+|INV[-0-9A-Z]+|YH[0-9A-Z\-]+|[A-Z]{2,4}[0-9]{6,14}[A-Z0-9\-]*)\b', table_text)
        if inv_m:
            invoice_number = inv_m.group(1).strip()
        if not invoice_number:
            inv_m2 = re.search(r'(?:invoices?|invoice\s*no\.?)\s*\n?.*?([A-Z0-9/\-]{5,25})', table_text, re.I | re.S)
            if inv_m2 and inv_m2.group(1).lower() not in ('invoices', 'number', 'declaration', 'original'):
                invoice_number = inv_m2.group(1).strip()
        if not invoice_number:
            invoice_number = self.find_first([
                r"(?:Invoice\s+(?:No\.?|#))[:\s]*([A-Z0-9/\-]{3,25})",
            ], text)

        # 10. Gross Weight & Quantity
        gross_weight = None
        gw_m = re.search(r'([\d\.,]+)\s*(?:KGS|KG)\s*G\.?W\.?', table_text, re.I)
        if not gw_m:
            gw_m = re.search(r'(?:G\.?\s*WEIGHT|GROSS\s*WEIGHT)[:\s]*([\d\.,]+)\s*(?:KGS|KG)', table_text, re.I)
        if gw_m:
            gross_weight = gw_m.group(1).strip() + ' KGS G.W.'
        if not gross_weight:
            gross_weight = self.find_first([
                r"(?:Gross\s+Weight)[:\s]+([0-9,\.]+\s*(?:kg|KG|MT|lbs?)?)",
            ], text)

        # 11. Issue Date
        issue_date = self.find_first([
            r"(?:SUZHOU,CHINA|SHANGHAI,CHINA|CAIRO,EGYPT)?\s*((?:JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\.?\s*\d{1,2},?\s*\d{4})",
            r"(?:Date\s+of\s+Issue|Issue\s+Date|Date\s+Issued)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
            r"(?:Dated?)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
        ], text)

        return {
            "certificate_number": cert_no,
            "issue_date": issue_date,
            "origin_country": origin_country,
            "destination_country": destination_country,
            "exporter_name": exporter_name,
            "consignee_name": consignee_name,
            "product_description": product_description,
            "hs_code": hs_code,
            "acid_number": acid_number,
            "gross_weight": gross_weight,
            "invoice_number": invoice_number,
        }


class InspectionCertificateExtractor(BaseExtractor):
    """Extracts Inspection Certificate / Quality Certificate fields."""

    def required_fields(self) -> List[str]:
        return ["certificate_number", "inspection_date", "result"]

    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        text = raw_text or ""
        return {
            "certificate_number": self.find_first([
                r"(?:Certificate\s+(?:No\.?|Number|#)|Cert\.?\s*No\.?|Report\s+No\.?)[:\s]*([A-Z0-9/\-]{4,30})",
            ], text),
            "inspection_date": self.find_first([
                r"(?:Date\s+of\s+Inspection|Inspection\s+Date|Date)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
            ], text),
            "inspector_name": self.find_first([
                r"(?:Inspector|Surveyor|Inspected\s+By)[:\s]+([A-Za-z\s,.'-]{3,60}?)(?:\n|,|\|)",
            ], text),
            "inspection_company": self.find_first([
                r"(?:Inspection\s+Company|Surveying\s+Company|Issued\s+By)[:\s]+([A-Za-z0-9\s&,.'-]{3,80}?)(?:\n|,|\|)",
            ], text),
            "product_description": self.find_first([
                r"(?:Description\s+of\s+Goods?|Product|Commodity)[:\s]+([^\n]{10,150})",
            ], text),
            "quantity_inspected": self.find_first([
                r"(?:Quantity\s+Inspected|Quantity|Qty)[:\s]+([0-9,\.]+\s*(?:PCS|SETS?|MT|KG|units?)?)",
            ], text),
            "result": self.find_first([
                r"(?:Result|Conclusion|Finding|Status)[:\s]+(\b(?:PASS(?:ED)?|FAIL(?:ED)?|CONDITIONAL|APPROVED?|REJECTED?)\b)",
            ], text),
            "defects_found": self.find_first([
                r"(?:Defects?|Non[- ]?Conformanc(?:y|ies?)|Remarks?)[:\s]+([^\n]{5,200})",
            ], text),
            "remarks": self.find_first([
                r"(?:Remarks?|Notes?|Comments?)[:\s]+([^\n]{5,200})",
            ], text),
        }


class FinancialDocumentExtractor(BaseExtractor):
    """Extracts Financial Invoice / Payment document fields."""

    def required_fields(self) -> List[str]:
        return ["invoice_number", "amount", "currency"]

    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        text = raw_text or ""
        return {
            "invoice_number": self.find_first([
                r"(?:Invoice\s+(?:No\.?|#|Number))[:\s]*([A-Z0-9/\-]{3,25})",
            ], text),
            "invoice_date": self.find_first([
                r"(?:Invoice\s+Date|Date)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
            ], text),
            "supplier_name": self.find_first([
                r"(?:Supplier|Vendor|From|Beneficiary)[:\s]+([A-Za-z0-9\s&,.'-]{3,80}?)(?:\n|,|\|)",
            ], text),
            "amount": self.find_float([
                r"(?:Total\s+Amount|Grand\s+Total|Amount\s+Due|Total)[:\s]+(?:USD|EUR|EGP|GBP)?\s*([0-9,]+\.?\d*)",
            ], text),
            "currency": self.normalize_currency(text),
            "payment_terms": self.find_first([
                r"(?:Payment\s+Terms?)[:\s]+([^\n]{3,60})",
                r"\b(Net\s+\d+|T/T|L/C|CAD|Advance)\b",
            ], text),
            "bank_name": self.find_first([
                r"(?:Bank\s+Name|Bank)[:\s]+([A-Za-z0-9\s&,.'-]{3,60}?)(?:\n|,|\|)",
            ], text),
            "swift_code": self.find_first([
                r"(?:SWIFT|BIC)[:\s]*([A-Z]{4}[A-Z]{2}[A-Z0-9]{2}(?:[A-Z0-9]{3})?)",
            ], text),
            "iban": self.find_first([
                r"(?:IBAN)[:\s]*([A-Z]{2}[0-9]{2}[A-Z0-9]{4,34})",
            ], text),
            "due_date": self.find_first([
                r"(?:Due\s+Date|Payment\s+Due)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
            ], text),
        }
