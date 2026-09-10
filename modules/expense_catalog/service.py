"""
Expense Catalog Service (AI-EXPENSE-CATALOG-002)
Business logic and matching engine for Coded Reference Expense Catalog.
"""

from __future__ import annotations

import re
from typing import Any, Dict, List, Optional, Tuple
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from modules.expense_catalog.model import ExpenseCatalog
from modules.expense_catalog.schemas import ExpenseCatalogCreate, ExpenseCatalogUpdate
from modules.expense_catalog.repository import ExpenseCatalogRepository
from modules.expense_catalog.validators import ExpenseCatalogValidator


def normalize_text(text: str) -> str:
    """Normalizes Arabic/English text for robust pattern matching."""
    if not text:
        return ""
    t = text.lower().strip()
    # Normalize Arabic alefs, teh marbuta, yeh
    t = re.sub(r"[أإآ]", "ا", t)
    t = t.replace("ة", "ه").replace("ى", "ي")
    # Replace non-word chars with spaces
    t = re.sub(r"[^\w\s\u0600-\u06FF]", " ", t)
    # Collapse multiple spaces
    return re.sub(r"\s+", " ", t).strip()


class ExpenseCatalogService:

    @staticmethod
    def list_items(
        db: Session,
        category: Optional[str] = None,
        search: Optional[str] = None,
        active_only: bool = True,
    ) -> List[ExpenseCatalog]:
        return ExpenseCatalogRepository.list(
            db, category=category, search=search, active_only=active_only
        )

    @staticmethod
    def get_item(db: Session, code: str) -> ExpenseCatalog:
        item = ExpenseCatalogRepository.get_by_code(db, code)
        if not item:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Expense item with code '{code}' not found in catalog.",
            )
        return item

    @staticmethod
    def create_item(db: Session, schema: ExpenseCatalogCreate) -> ExpenseCatalog:
        schema.code = ExpenseCatalogValidator.validate_code_format(schema.code)
        schema.category = ExpenseCatalogValidator.validate_category(schema.category)
        schema.unit_type = ExpenseCatalogValidator.validate_unit_type(schema.unit_type)
        ExpenseCatalogValidator.validate_unique_code(db, schema.code)
        return ExpenseCatalogRepository.create(db, schema)

    @staticmethod
    def update_item(db: Session, code: str, schema: ExpenseCatalogUpdate) -> ExpenseCatalog:
        item = ExpenseCatalogService.get_item(db, code)
        if schema.category is not None:
            schema.category = ExpenseCatalogValidator.validate_category(schema.category)
        if schema.unit_type is not None:
            schema.unit_type = ExpenseCatalogValidator.validate_unit_type(schema.unit_type)
        return ExpenseCatalogRepository.update(db, item, schema)

    @staticmethod
    def add_pattern(db: Session, code: str, pattern: str) -> ExpenseCatalog:
        clean_pat = pattern.strip()
        if not clean_pat:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Recognition pattern cannot be empty.",
            )
        item = ExpenseCatalogService.get_item(db, code)
        updated = ExpenseCatalogRepository.add_pattern(db, code, clean_pat)
        return updated or item

    @staticmethod
    def deactivate_item(db: Session, code: str) -> ExpenseCatalog:
        item = ExpenseCatalogService.get_item(db, code)
        item.is_active = False
        db.commit()
        db.refresh(item)
        return item

    @staticmethod
    def find_matching_item(
        db: Session,
        text: str,
        category: Optional[str] = None,
        current_section: str = "",
    ) -> Optional[ExpenseCatalog]:
        items = ExpenseCatalogRepository.list(db, category=category, active_only=True)
        res = ExpenseCatalogService.match_line_against_catalog(text, items, current_section=current_section)
        return res[0] if res else None

    @staticmethod
    def match_line_against_catalog(
        line: str,
        catalog_items: List[ExpenseCatalog],
        current_section: str = "",
    ) -> Optional[Tuple[ExpenseCatalog, float]]:
        """
        Matches a raw text line or item name against catalog items.
        Returns the best matching ExpenseCatalog and confidence score (0.0 to 1.0).
        """
        if not line or not line.strip():
            return None

        norm_line = normalize_text(line)
        best_match: Optional[ExpenseCatalog] = None
        best_score = 0.0

        for item in catalog_items:
            # Section relevance bonus / filter
            section_match = False
            cat = item.category.lower()
            if current_section == "LCL" and "clearance" in cat:
                if "lcl" in item.code.lower():
                    section_match = True
            elif current_section in ("20FT", "40FT") and "clearance" in cat:
                if current_section.lower() in item.code.lower():
                    section_match = True
            elif current_section in ("TRANSPORT", "DEMURRAGE") and "transport" in cat:
                section_match = True
            elif current_section == "PORT" and "port" in cat:
                section_match = True

            # Check all recognition patterns
            all_patterns = list(item.recognition_patterns or [])
            if item.canonical_name_ar:
                all_patterns.append(item.canonical_name_ar)
            if item.canonical_name_en:
                all_patterns.append(item.canonical_name_en)

            for pat in all_patterns:
                norm_pat = normalize_text(pat)
                if not norm_pat:
                    continue

                score = 0.0
                if norm_pat == norm_line:
                    score = 1.0
                elif norm_pat in norm_line:
                    # Ratio of pattern length to line length
                    score = 0.85 + (0.10 * (len(norm_pat) / max(len(norm_line), 1)))
                elif norm_line in norm_pat:
                    score = 0.80 + (0.10 * (len(norm_line) / max(len(norm_pat), 1)))
                else:
                    # Token overlap
                    line_words = set(norm_line.split())
                    pat_words = set(norm_pat.split())
                    if pat_words and pat_words.issubset(line_words):
                        score = 0.82
                    elif len(pat_words & line_words) >= 2:
                        overlap = len(pat_words & line_words) / len(pat_words)
                        if overlap >= 0.6:
                            score = 0.70 * overlap

                # Apply section bonus
                if section_match and score > 0.6:
                    score = min(1.0, score + 0.1)

                # Penalize mismatched container sizes
                if ("40" in norm_line and "20" in item.code) or ("20" in norm_line and "40" in item.code):
                    score = 0.0
                if ("lcl" in norm_line and "fcl" in item.code.lower()) or ("fcl" in norm_line and "lcl" in item.code.lower()):
                    score = 0.0

                if score > best_score:
                    best_score = score
                    best_match = item

        if best_match and best_score >= 0.70:
            return best_match, best_score
        return None
