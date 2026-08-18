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
        """Detect currency code from text."""
        text_upper = text.upper()
        for code in ["USD", "EUR", "GBP", "EGP", "CNY", "JPY", "AED", "SAR"]:
            if code in text_upper:
                return code
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
