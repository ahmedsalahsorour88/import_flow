"""
Master Data Corporate Name Normalizer & Duplicate Detection Engine
Normalizes Arabic and English corporate names to catch exact and fuzzy duplicates.
"""

from __future__ import annotations

import difflib
import re
from typing import List, Optional


def normalize_master_data_name(name: str) -> str:
    """
    Normalizes corporate & entity names for strict duplicate detection.
    Strips whitespace, punctuation, casing, and standard corporate suffixes
    (e.g., 'Co., Ltd.', 'Inc.', 'LLC', 'S.P.A.', 'GmbH', 'شركة', 'مؤسسة').
    """
    if not name:
        return ""

    text = name.lower().strip()

    # Normalize unicode & strip non-alphanumeric chars (keep English, numbers, Arabic letters)
    text = re.sub(r"[^\w\s\u0600-\u06FF]", " ", text)

    # Common corporate suffixes and stopwords to filter out for similarity comparison
    stopwords = {
        "co", "ltd", "limited", "inc", "corp", "corporation", "llc", "spa", "gmbh", "company", "group", "factory",
        "trade", "trading", "international", "holding", "holdings", "industries", "industrial",
        "شركة", "مؤسسة", "مصنع", "مجموعة", "محدودة", "ذمم", "ذ م م", "تجارية", "صناعية", "استيراد", "تصدير"
    }

    words = [w for w in text.split() if w not in stopwords]
    return "".join(words) if words else "".join(text.split())


def check_duplicate_name(new_name: str, existing_names: List[str], threshold: float = 0.85) -> Optional[str]:
    """
    Checks if new_name matches any existing_name by exact normalized match or high fuzzy similarity ratio.
    Returns the matching existing_name string if duplicate, or None.
    """
    if not new_name or not new_name.strip():
        return None

    norm_new = normalize_master_data_name(new_name)
    if not norm_new:
        return None

    for existing in existing_names:
        if not existing or not existing.strip():
            continue
        norm_exist = normalize_master_data_name(existing)

        # 1 — Direct exact match or raw lowercase match
        if norm_new == norm_exist or new_name.strip().lower() == existing.strip().lower():
            return existing

        # 2 — Substring match for long names
        if len(norm_new) >= 6 and len(norm_exist) >= 6:
            if norm_new in norm_exist or norm_exist in norm_new:
                return existing

        # 3 — Fuzzy similarity ratio check
        if len(norm_new) >= 5 and len(norm_exist) >= 5:
            ratio = difflib.SequenceMatcher(None, norm_new, norm_exist).ratio()
            if ratio >= threshold:
                return existing

    return None
