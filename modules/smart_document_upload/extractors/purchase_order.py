"""
Purchase Order Extractor
Extracts PO fields from Commercial Invoices, PO PDFs, Excel POs, and Word PO documents.
"""

from __future__ import annotations

import re
from typing import Any, Dict, List, Optional

from modules.smart_document_upload.extractors.base_extractor import BaseExtractor


class PurchaseOrderExtractor(BaseExtractor):

    def required_fields(self) -> List[str]:
        return ["po_number", "supplier_name", "currency", "total_amount"]

    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        text = raw_text or ""

        result: Dict[str, Any] = {
            "po_number": self._extract_po_number(text),
            "supplier_name": self._extract_supplier(text),
            "order_date": self._extract_date(text),
            "currency": self.normalize_currency(text),
            "incoterms": self.normalize_incoterms(text),
            "country_of_origin": self._extract_country(text),
            "delivery_port": self._extract_port(text),
            "payment_terms": self._extract_payment_terms(text),
            "total_amount": self.find_float([
                r"(?:Order\s+Total|Line\s+Total|grand\s+total|total\s+amount|total\s+value|amount\s+due|invoice\s+total|net\s+amount)[:\s]+(?:[A-Z]{3}\s*|\$\s*)?([0-9,]+\.?\d*)",
                r"(?:total)[:\s]+(?:[A-Z]{3}\s*|\$\s*)?([0-9,]+\.?\d*)",
                r"[A-Z]{3}\s+([0-9,]+\.?\d*)\s*$",
            ], text),
            "items": self._extract_line_items(text),
            "packing_list_items": self._extract_packing_list_items(text),
        }
        return result

    def _extract_po_number(self, text: str) -> Optional[str]:
        return self.find_first([
            r"P\.?O\.?\s*(?:No\.?|Number|#|Num)[:\s]*([A-Z0-9/\-]+(?:\s+Ever)?)",
            r"Purchase\s+Order\s+(?:No\.?|Number|#)?[:\s]*([A-Z0-9/\-]+(?:\s+Ever)?)",
            r"Order\s+Number[:\s]*([A-Z0-9/\-]+)",
            r"(?:Commercial\s+)?Invoice\s*(?:No\.?|Number|#|Num)[:\s]*([A-Z0-9/\-]+)",
            r"Inv(?:oice)?\s*(?:No\.?|#)[:\s]*([A-Z0-9/\-]+)",
            r"Order\s+(?:No\.?|#)[:\s]*([A-Z0-9/\-]+)",
            r"(?:PO)[:\s]*([A-Z0-9/\-]{4,})",
        ], text)

    def _extract_supplier(self, text: str) -> Optional[str]:
        # 1. Explicit label matching
        labeled = self.find_first([
            r"(?:Supplier|Vendor|Seller|Exporter|Shipper|From|Sold By|Beneficiary|Shipped By)[:\s]+([A-Za-z0-9\s&,.'-]{3,60}?)(?:\n|,|\|)",
            r"(?:Company|Messrs|M/S|Messers)[:\s]+([A-Za-z0-9\s&,.'-]{3,60}?)(?:\n|,|\|)",
        ], text)
        if labeled:
            return labeled.strip()

        # 2. Header scan: top lines matching corporate name
        lines = [line.strip() for line in text.splitlines() if line.strip()][:25]
        for line in lines:
            upper = line.upper()
            if any(kw in upper for kw in ["LIMITED", "LTD", "INC", "CORP", "CORPORATION", "GMBH", "LLC", "PLC", "S.P.A", "SHAWCONTRACT", "SHAW"]):
                if not any(stop in upper for stop in ["COMMERCIAL INVOICE", "PURCHASE ORDER", "ORDER DATE", "BILL TO", "SHIP TO", "TAX ID", "VAT NUMBER"]):
                    return line
        return lines[0] if lines else None

    def _extract_date(self, text: str) -> Optional[str]:
        raw_date = self.find_first([
            r"(?:Order\s+Date|Invoice\s+Date|Date|Issue\s+Date)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
            r"(?:Order\s+Date|Invoice\s+Date|Date|Issue\s+Date)[:\s]+(\d{4}-\d{2}-\d{2})",
            r"(?:Dated?)[:\s]+(\d{1,2}\s+\w+\s+\d{4})",
        ], text)

        if not raw_date:
            return None

        # Normalize DD-MM-YYYY or DD/MM/YYYY to YYYY-MM-DD for ISO standard
        parts = re.split(r"[/-]", raw_date.strip())
        if len(parts) == 3:
            if len(parts[0]) == 4:  # YYYY-MM-DD
                return f"{parts[0]}-{int(parts[1]):02d}-{int(parts[2]):02d}"
            elif len(parts[2]) == 4:  # DD-MM-YYYY
                day, month, year = int(parts[0]), int(parts[1]), int(parts[2])
                if month > 12:  # Swap if MM-DD-YYYY
                    day, month = month, day
                return f"{year:04d}-{month:02d}-{day:02d}"
        return raw_date

    def _extract_country(self, text: str) -> Optional[str]:
        found = self.find_first([
            r"(?:Country\s+Of\s+Origin|Incoterms\s+Location|Origin)[:\s]+([A-Za-z\s]{2,30})",
            r"\b(United\s+Kingdom|China|Germany|Italy|Turkey|France|Spain|USA|UK|CN|DE|IT|TR|FR|ES|GB)\b",
        ], text)
        if not found:
            return None
        c = found.strip().upper()
        if c in ["UK", "UNITED KINGDOM", "GREAT BRITAIN"]:
            return "GB"
        if c in ["USA", "UNITED STATES", "UNITED STATES OF AMERICA"]:
            return "US"
        if c in ["CHINA"]:
            return "CN"
        if c in ["GERMANY"]:
            return "DE"
        if c in ["ITALY"]:
            return "IT"
        if c in ["TURKEY"]:
            return "TR"
        return c

    def _extract_port(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:Port\s+of\s+(?:Loading|Shipment|Discharge|Destination))[:\s]+([A-Za-z\s,]+?)(?:\n|,|\|)",
            r"(?:Destination|Ship\s+To)[:\s]+([A-Za-z\s,]+?)(?:\n|,|\|)",
        ], text)

    def _extract_payment_terms(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:Payment\s+Terms?|Terms?\s+of\s+Payment)[:\s]+([^\n]{3,60})",
            r"\b(T/T|L/C|CAD|D/P|D/A|Open\s+Account|Advance\s+Payment|PBS\s+CHK/CR/DBT|SWIFT)\b",
        ], text)

    def _extract_line_items(self, text: str) -> List[Dict[str, Any]]:
        """
        Extracts tabular line items from commercial invoices and POs.
        """
        items: List[Dict[str, Any]] = []

        # 1. Commercial Invoice Table Row Regex (e.g. 1 5T22926100 NOOK TASKWORX... 335 ... 13.93 ... 4666.55)
        for line in text.splitlines():
            line_str = line.strip()
            # Look for lines starting with line number 1..99
            m = re.match(
                r"^(\d{1,2})\s+([A-Z0-9\-]{3,20})\s+(.+?)\s+(?:(\d{8,10})\s+)?(?:Square\s+Meter|Boxes|Each|PCS|CTNS)?\s*(\d+(?:\.\d+)?)\s+.*?\s+([0-9,]+\.\d{2})\s+.*?\s+([0-9,]+\.\d{2})$",
                line_str,
                re.IGNORECASE,
            )
            if m:
                try:
                    items.append({
                        "item_code": m.group(2).strip(),
                        "description": m.group(3).strip(),
                        "hs_code": m.group(4) if m.group(4) else "",
                        "quantity": float(m.group(5).replace(",", "")),
                        "unit_price": float(m.group(6).replace(",", "")),
                        "total_price": float(m.group(7).replace(",", "")),
                    })
                except ValueError:
                    continue

        # 2. Pipe-separated rows fallback (from Excel/openpyxl extraction)
        if not items:
            pipe_pattern = re.compile(
                r"([A-Za-z0-9][^|]{2,60})\s*\|\s*(\d+(?:\.\d+)?)\s*\|\s*([A-Za-z]{2,10})\s*\|\s*([0-9,]+\.?\d*)\s*\|\s*([0-9,]+\.?\d*)",
                re.IGNORECASE,
            )
            for m in pipe_pattern.finditer(text):
                try:
                    items.append({
                        "item_code": "ITEM-001",
                        "description": m.group(1).strip(),
                        "quantity": float(m.group(2).replace(",", "")),
                        "unit": m.group(3).strip(),
                        "unit_price": float(m.group(4).replace(",", "")),
                        "total_price": float(m.group(5).replace(",", "")),
                    })
                except ValueError:
                    continue

        # 3. Generic invoice row pattern fallback
        if not items:
            invoice_pattern = re.compile(
                r"(?:[0-9]+[\.\)\s]+)?([A-Za-z0-9\s\-/]{3,50}?)\s+(\d+(?:\.\d+)?)\s+(?:PCS|KGS|CTNS|UNITS|SETS|BOXES|BAGS)?\s*(?:[A-Z]{3}\s*|\$\s*)?([0-9,]+\.?\d*)\s+(?:[A-Z]{3}\s*|\$\s*)?([0-9,]+\.?\d*)",
                re.IGNORECASE | re.MULTILINE,
            )
            for m in invoice_pattern.finditer(text):
                try:
                    qty = float(m.group(2).replace(",", ""))
                    price = float(m.group(3).replace(",", ""))
                    total = float(m.group(4).replace(",", ""))
                    if qty > 0 and price > 0 and total > 0:
                        items.append({
                            "item_code": "ITEM-001",
                            "description": m.group(1).strip(),
                            "quantity": qty,
                            "unit_price": price,
                            "total_price": total,
                        })
                except ValueError:
                    continue

        return items[:50]

    def _extract_packing_list_items(self, text: str) -> List[Dict[str, Any]]:
        """
        Extracts cargo dimensions and packing list details from invoice footers.
        e.g. "960 boxes / 31 pallets @ 110cm x 110cm x 106cm Gross weight 20030kg Net weight 19410kg"
        """
        packing: List[Dict[str, Any]] = []

        m = re.search(
            r"(\d+)\s+boxes\s*/\s*(\d+)\s+pallets\s*@\s*(\d+(?:\.\d+)?)cm\s*x\s*(\d+(?:\.\d+)?)cm\s*x\s*(\d+(?:\.\d+)?)cm\s*Gross\s+weight\s*(\d+(?:\.\d+)?)kg\s*Net\s+weight\s*(\d+(?:\.\d+)?)kg",
            text,
            re.IGNORECASE,
        )
        if m:
            boxes = float(m.group(1))
            pallets = float(m.group(2))
            l = float(m.group(3))
            w = float(m.group(4))
            h = float(m.group(5))
            gross_wt = float(m.group(6))
            net_wt = float(m.group(7))

            pkg_count = pallets if pallets > 0 else boxes
            unit_gross = gross_wt / pkg_count if pkg_count > 0 else gross_wt
            unit_net = net_wt / pkg_count if pkg_count > 0 else net_wt

            packing.append({
                "package_type": "Pallet" if pallets > 0 else "Carton",
                "qty_pkg": pkg_count,
                "qty_pcs": boxes,
                "length_cm": l,
                "width_cm": w,
                "height_cm": h,
                "gross_weight_unit_kg": unit_gross,
                "net_weight_unit_kg": unit_net,
                "total_gross_weight_kg": gross_wt,
                "total_net_weight_kg": net_wt,
                "is_stackable": True,
            })

        return packing
