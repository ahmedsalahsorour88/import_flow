"""
Smart Document Upload — Base Extractor
Abstract base class for all module-specific field extractors.
"""

from __future__ import annotations

import re
from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional, Tuple


class BaseExtractor(ABC):
    """
    Every module extractor inherits from this class.
    Provides common regex helpers and defines the extract() contract.
    """

    # ─── Contract ─────────────────────────────────────────────────────────────

    @abstractmethod
    def extract(self, raw_text: str, spatial_boxes: dict) -> Dict[str, Any]:
        """
        Extract structured fields from raw document text.
        Returns a dict of field_name → value.
        """
        ...

    @abstractmethod
    def required_fields(self) -> List[str]:
        """Returns the list of field names that MUST be present for full extraction."""
        ...

    # ─── Helpers ──────────────────────────────────────────────────────────────

    def compute_confidence(self, extracted: Dict[str, Any]) -> float:
        """
        Computes a 0.0–1.0 confidence score based on required fields found.
        """
        required = self.required_fields()
        if not required:
            return 1.0
        found = sum(
            1 for f in required
            if extracted.get(f) is not None and str(extracted.get(f, "")).strip() != ""
        )
        return round(found / len(required), 2)

    def missing_required(self, extracted: Dict[str, Any]) -> List[str]:
        return [
            f for f in self.required_fields()
            if not extracted.get(f) or str(extracted.get(f, "")).strip() == ""
        ]

    @staticmethod
    def find_first(patterns: List[str], text: str, flags: int = re.IGNORECASE) -> Optional[str]:
        """Try multiple regex patterns and return the first match group(1)."""
        for pat in patterns:
            m = re.search(pat, text, flags)
            if m:
                try:
                    return m.group(1).strip()
                except IndexError:
                    return m.group(0).strip()
        return None

    @staticmethod
    def find_float(patterns: List[str], text: str) -> Optional[float]:
        """Try multiple patterns, return first numeric match as float."""
        for pat in patterns:
            m = re.search(pat, text, re.IGNORECASE)
            if m:
                try:
                    raw = m.group(1).replace(",", "").strip()
                    return float(raw)
                except (IndexError, ValueError):
                    pass
        return None

    @staticmethod
    def find_int(patterns: List[str], text: str) -> Optional[int]:
        val = BaseExtractor.find_float(patterns, text)
        return int(val) if val is not None else None

    @staticmethod
    def normalize_currency(text: str) -> Optional[str]:
        """Detect currency code from text, prioritizing total lines and frequency."""
        if not text:
            return None

        # 1. Check currency explicitly adjacent to total / invoice amount
        total_curr_match = re.search(
            r"(?:Total|Invoice\s+amount|Payment\s+amount|Amount\s+due|Grand\s+Total|Total\s+Value)[^\n]*?\b(EUR|USD|GBP|EGP|CNY|JPY|AED|SAR|€|\$|£|¥)\b",
            text,
            re.IGNORECASE,
        )
        if total_curr_match:
            code = total_curr_match.group(1).upper()
            symbol_map = {"€": "EUR", "$": "USD", "£": "GBP", "¥": "CNY"}
            return symbol_map.get(code, code)

        # 2. Check suffix after numeric amounts (e.g. "15,375.50 EUR")
        amount_suffix_match = re.search(
            r"\b\d{1,3}(?:,\d{3})*(?:\.\d{2})\s*(EUR|USD|GBP|EGP|CNY|JPY|AED|SAR|€|\$|£|¥)\b",
            text,
            re.IGNORECASE,
        )
        if amount_suffix_match:
            code = amount_suffix_match.group(1).upper()
            symbol_map = {"€": "EUR", "$": "USD", "£": "GBP", "¥": "CNY"}
            return symbol_map.get(code, code)

        # 3. Frequency count across the document
        text_upper = text.upper()
        currencies = ["EUR", "USD", "GBP", "EGP", "CNY", "JPY", "AED", "SAR"]
        counts = {c: len(re.findall(rf"\b{c}\b", text_upper)) for c in currencies}
        sorted_by_freq = sorted(counts.items(), key=lambda x: x[1], reverse=True)
        if sorted_by_freq and sorted_by_freq[0][1] > 0:
            return sorted_by_freq[0][0]

        return None

    @staticmethod
    def normalize_incoterms(text: str) -> Optional[str]:
        """Extract Incoterm from text."""
        pattern = r"\b(FOB|CIF|CFR|EXW|DAP|DDP|FCA|CPT|CIP|DAT|FAS)\b"
        m = re.search(pattern, text, re.IGNORECASE)
        return m.group(1).upper() if m else None

    @staticmethod
    def normalize_container_type(text: str) -> Optional[str]:
        """Normalize container size/type."""
        for code in ["40HC", "40'HC", "40 HC", "40HQ", "40 HQ"]:
            if code.replace("'", "").replace(" ", "").upper() in text.upper().replace("'", "").replace(" ", ""):
                return "40HC"
        if re.search(r"40['\s]?(?:ft|foot|feet)?", text, re.IGNORECASE):
            return "40GP"
        if re.search(r"20['\s]?(?:ft|foot|feet)?", text, re.IGNORECASE):
            return "20GP"
        return None
