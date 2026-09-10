"""
Expense Catalog Repository (AI-EXPENSE-CATALOG-002)
Database CRUD operations for ExpenseCatalog.
"""

from __future__ import annotations

from typing import Dict, List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import or_

from modules.expense_catalog.model import ExpenseCatalog
from modules.expense_catalog.schemas import ExpenseCatalogCreate, ExpenseCatalogUpdate


class ExpenseCatalogRepository:

    @staticmethod
    def get_by_code(db: Session, code: str) -> Optional[ExpenseCatalog]:
        return db.query(ExpenseCatalog).filter(ExpenseCatalog.code == code.strip().upper()).first()

    @staticmethod
    def list(
        db: Session,
        category: Optional[str] = None,
        search: Optional[str] = None,
        active_only: bool = True,
        skip: int = 0,
        limit: int = 500,
    ) -> List[ExpenseCatalog]:
        query = db.query(ExpenseCatalog)
        if active_only:
            query = query.filter(ExpenseCatalog.is_active.is_(True))
        if category and category != "All":
            query = query.filter(ExpenseCatalog.category == category)
        if search:
            s = f"%{search.strip()}%"
            query = query.filter(
                or_(
                    ExpenseCatalog.code.ilike(s),
                    ExpenseCatalog.canonical_name_ar.ilike(s),
                    ExpenseCatalog.canonical_name_en.ilike(s),
                )
            )
        return query.order_by(ExpenseCatalog.category, ExpenseCatalog.code).offset(skip).limit(limit).all()

    @staticmethod
    def create(db: Session, schema: ExpenseCatalogCreate) -> ExpenseCatalog:
        # Normalize code
        code_normalized = schema.code.strip().upper()
        # Clean patterns
        patterns = [p.strip() for p in schema.recognition_patterns if p and p.strip()]
        # Always ensure canonical names are in recognition patterns
        if schema.canonical_name_ar and schema.canonical_name_ar not in patterns:
            patterns.append(schema.canonical_name_ar)
        if schema.canonical_name_en and schema.canonical_name_en not in patterns:
            patterns.append(schema.canonical_name_en)

        obj = ExpenseCatalog(
            code=code_normalized,
            canonical_name_ar=schema.canonical_name_ar.strip(),
            canonical_name_en=schema.canonical_name_en.strip() if schema.canonical_name_en else None,
            category=schema.category.strip(),
            unit_type=schema.unit_type.strip(),
            allow_composite=schema.allow_composite,
            recognition_patterns=patterns,
            is_active=schema.is_active,
        )
        db.add(obj)
        db.commit()
        db.refresh(obj)
        return obj

    @staticmethod
    def update(db: Session, db_obj: ExpenseCatalog, schema: ExpenseCatalogUpdate) -> ExpenseCatalog:
        data = schema.model_dump(exclude_unset=True)
        if "recognition_patterns" in data and data["recognition_patterns"] is not None:
            clean_patterns = [p.strip() for p in data["recognition_patterns"] if p and p.strip()]
            data["recognition_patterns"] = clean_patterns
        for field, value in data.items():
            setattr(db_obj, field, value)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    @staticmethod
    def add_pattern(db: Session, code: str, pattern: str) -> Optional[ExpenseCatalog]:
        clean_pat = pattern.strip()
        if not clean_pat:
            return None
        obj = ExpenseCatalogRepository.get_by_code(db, code)
        if not obj:
            return None
        current = list(obj.recognition_patterns or [])
        if clean_pat not in current:
            current.append(clean_pat)
            obj.recognition_patterns = current
            db.commit()
            db.refresh(obj)
        return obj
