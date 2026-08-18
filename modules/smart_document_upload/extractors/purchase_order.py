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
            "delivery_port": self._extract_port(text),
            "payment_terms": self._extract_payment_terms(text),
            "total_amount": self.find_float([
                r"(?:grand\s+total|total\s+amount|total\s+value|amount\s+due|invoice\s+total|net\s+amount)[:\s]+(?:[A-Z]{3}\s*)?([0-9,]+\.?\d*)",
                r"(?:total)[:\s]+(?:[A-Z]{3}\s*)?([0-9,]+\.?\d*)",
                r"[A-Z]{3}\s+([0-9,]+\.?\d*)\s*$",
            ], text),
            "items": self._extract_line_items(text),
        }
        return result

    def _extract_po_number(self, text: str) -> Optional[str]:
        return self.find_first([
            r"P\.?O\.?\s*(?:No\.?|Number|#|Num)[:\s]*([A-Z0-9/\-]+)",
            r"Purchase\s+Order\s+(?:No\.?|Number|#)?[:\s]*([A-Z0-9/\-]+)",
            r"(?:Commercial\s+)?Invoice\s*(?:No\.?|Number|#|Num)[:\s]*([A-Z0-9/\-]+)",
            r"Inv(?:oice)?\s*(?:No\.?|#)[:\s]*([A-Z0-9/\-]+)",
            r"Order\s+(?:No\.?|#)[:\s]*([A-Z0-9/\-]+)",
            r"(?:PO)[:\s]*([A-Z0-9/\-]{4,})",
        ], text)

    def _extract_supplier(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:Supplier|Vendor|Seller|Exporter|Shipper|From|Sold By|Beneficiary|Shipped By)[:\s]+([A-Za-z0-9\s&,.'-]{3,60}?)(?:\n|,|\|)",
            r"(?:Company|Messrs|M/S|Messers)[:\s]+([A-Za-z0-9\s&,.'-]{3,60}?)(?:\n|,|\|)",
            r"^([A-Z0-9\s&,.'-]{4,60}\s+(?:LTD|LIMITED|INC|CORP|CORPORATION|CO\.|GMBH|LLC|PLC|S\.P\.A|S\.R\.L))",
        ], text)

    def _extract_date(self, text: str) -> Optional[str]:
        return self.find_first([
            r"(?:Order\s+Date|Invoice\s+Date|Date|Issue\s+Date)[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
            r"(?:Order\s+Date|Invoice\s+Date|Date|Issue\s+Date)[:\s]+(\d{4}-\d{2}-\d{2})",
            r"(?:Dated?)[:\s]+(\d{1,2}\s+\w+\s+\d{4})",
        ], text)

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
        Attempts to extract tabular line items from the document.
        Handles pipe-separated (Excel rows), space-aligned (PDF table), and invoice row formats.
        """
        items = []

        # 1. Pattern for pipe-separated rows (from Excel/openpyxl extraction)
        pipe_pattern = re.compile(
            r"([A-Za-z0-9][^|]{2,60})\s*\|\s*(\d+(?:\.\d+)?)\s*\|\s*([A-Za-z]{2,10})\s*\|\s*([0-9,]+\.?\d*)\s*\|\s*([0-9,]+\.?\d*)",
            re.IGNORECASE,
        )
        for m in pipe_pattern.finditer(text):
            try:
                items.append({
                    "description": m.group(1).strip(),
                    "quantity": float(m.group(2).replace(",", "")),
                    "unit": m.group(3).strip(),
                    "unit_price": float(m.group(4).replace(",", "")),
                    "total_price": float(m.group(5).replace(",", "")),
                })
            except ValueError:
                continue

        # 2. Standard commercial invoice row pattern: Description Qty Price Amount
        if not items:
            invoice_pattern = re.compile(
                r"(?:[0-9]+[\.\)\s]+)?([A-Za-z0-9\s\-/]{3,50}?)\s+(\d+(?:\.\d+)?)\s+(?:PCS|KGS|CTNS|UNITS|SETS|BOXES|BAGS)?\s*(?:[A-Z]{3}\s*)?([0-9,]+\.?\d*)\s+(?:[A-Z]{3}\s*)?([0-9,]+\.?\d*)",
                re.IGNORECASE | re.MULTILINE,
            )
            for m in invoice_pattern.finditer(text):
                try:
                    qty = float(m.group(2).replace(",", ""))
                    price = float(m.group(3).replace(",", ""))
                    total = float(m.group(4).replace(",", ""))
                    if qty > 0 and price > 0 and total > 0:
                        items.append({
                            "description": m.group(1).strip(),
                            "quantity": qty,
                            "unit_price": price,
                            "total_price": total,
                        })
                except ValueError:
                    continue

        # 3. Fallback: simpler pattern for description + total
        if not items:
            simple_pattern = re.compile(
                r"^\s*(\d+)\s+(.{5,60?})\s+(\d+(?:\.\d+)?)\s+([0-9,]+\.?\d+)\s*$",
                re.MULTILINE,
            )
            for m in simple_pattern.finditer(text):
                try:
                    items.append({
                        "description": m.group(2).strip(),
                        "quantity": float(m.group(3).replace(",", "")),
                        "unit_price": None,
                        "total_price": float(m.group(4).replace(",", "")),
                    })
                except ValueError:
                    continue

        return items[:50]
