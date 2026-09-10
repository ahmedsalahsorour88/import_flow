"""
Repository for Smart Shipment Experience Guide (KB-GUIDE-012)
"""
import re
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import or_, desc
from datetime import datetime, timezone

from modules.experience_guide.model import GuideEntry, GuideEntryScope
from modules.experience_guide.schemas import GuideEntryCreate, GuideEntryUpdate


class ExperienceGuideRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, entry_id: int) -> Optional[GuideEntry]:
        return self.db.query(GuideEntry).filter(GuideEntry.entry_id == entry_id).first()

    def list_entries(
        self,
        skip: int = 0,
        limit: int = 100,
        search: Optional[str] = None,
        scope_type: Optional[str] = None,
        scope_value: Optional[str] = None,
        is_active: Optional[bool] = None,
    ) -> List[GuideEntry]:
        query = self.db.query(GuideEntry)

        if is_active is not None:
            query = query.filter(GuideEntry.is_active == is_active)

        if search:
            s = f"%{search.strip()}%"
            query = query.filter(or_(GuideEntry.title.ilike(s), GuideEntry.content.ilike(s)))

        if scope_type or scope_value:
            query = query.join(GuideEntry.scopes)
            if scope_type:
                query = query.filter(GuideEntryScope.scope_type == scope_type)
            if scope_value:
                query = query.filter(GuideEntryScope.scope_value.ilike(f"%{scope_value.strip()}%"))

        return query.order_by(desc(GuideEntry.created_at)).offset(skip).limit(limit).all()

    def create_entry(self, data: GuideEntryCreate) -> GuideEntry:
        entry = GuideEntry(
            title=data.title.strip(),
            content=data.content.strip(),
            entry_type=data.entry_type,
            severity=data.severity,
            created_by=data.created_by.strip() or "System",
            is_active=True,
        )
        self.db.add(entry)
        self.db.flush()

        for sc in data.scopes:
            scope_obj = GuideEntryScope(
                guide_entry_id=entry.entry_id,
                scope_type=sc.scope_type.strip(),
                scope_value=sc.scope_value.strip(),
            )
            self.db.add(scope_obj)

        self.db.commit()
        self.db.refresh(entry)
        return entry

    def update_entry(self, entry_id: int, data: GuideEntryUpdate) -> Optional[GuideEntry]:
        entry = self.get_by_id(entry_id)
        if not entry:
            return None

        if data.title is not None:
            entry.title = data.title.strip()
        if data.content is not None:
            entry.content = data.content.strip()
        if data.entry_type is not None:
            entry.entry_type = data.entry_type
        if data.severity is not None:
            entry.severity = data.severity
        if data.is_active is not None:
            entry.is_active = data.is_active

        entry.updated_at = datetime.now(timezone.utc)

        if data.scopes is not None:
            # Replace scopes
            self.db.query(GuideEntryScope).filter(GuideEntryScope.guide_entry_id == entry_id).delete()
            for sc in data.scopes:
                scope_obj = GuideEntryScope(
                    guide_entry_id=entry.entry_id,
                    scope_type=sc.scope_type.strip(),
                    scope_value=sc.scope_value.strip(),
                )
                self.db.add(scope_obj)

        self.db.commit()
        self.db.refresh(entry)
        return entry

    def delete_entry(self, entry_id: int) -> bool:
        entry = self.get_by_id(entry_id)
        if not entry:
            return False
        entry.is_active = False
        entry.updated_at = datetime.now(timezone.utc)
        self.db.commit()
        return True

    @staticmethod
    def _normalize_code(val: Optional[str]) -> str:
        if not val:
            return ""
        return re.sub(r"[^A-Za-z0-9]", "", str(val)).lower()

    @staticmethod
    def _normalize_text(val: Optional[str]) -> str:
        if not val:
            return ""
        t = str(val).lower().strip()
        # Normalize Arabic characters
        t = re.sub(r"[أإآ]", "ا", t)
        t = re.sub(r"ة", "ه", t)
        t = re.sub(r"ى", "ي", t)
        return t

    def find_matching_entries(self, shipment_params: Dict[str, Any]) -> List[GuideEntry]:
        """
        Multi-Scope AND matching engine.
        Returns all active entries where EVERY scope of the entry is matched by shipment parameters.
        """
        active_entries = self.db.query(GuideEntry).filter(GuideEntry.is_active == True).all()
        matched = []

        hs_clean = self._normalize_code(shipment_params.get("hs_code"))
        cat_clean = self._normalize_text(shipment_params.get("product_category"))
        port_clean = self._normalize_text(shipment_params.get("destination_port"))
        supplier_clean = self._normalize_text(shipment_params.get("supplier"))
        line_clean = self._normalize_text(shipment_params.get("shipping_line"))

        for entry in active_entries:
            if not entry.scopes:
                continue

            entry_matches = True
            for sc in entry.scopes:
                st = sc.scope_type
                sv = sc.scope_value.strip()

                if st == "hs_code":
                    target = self._normalize_code(sv)
                    if not hs_clean or not (hs_clean.startswith(target) or target.startswith(hs_clean)):
                        entry_matches = False
                        break

                elif st == "product_category":
                    target = self._normalize_text(sv)
                    if not cat_clean or not (target in cat_clean or cat_clean in target):
                        entry_matches = False
                        break

                elif st == "destination_port":
                    target = self._normalize_text(sv)
                    # Support matching 'Alexandria' / 'الإسكندرية' / 'الدخيلة'
                    is_alex = ("alex" in target or "اسكندر" in target or "دخيل" in target) and (
                        "alex" in port_clean or "اسكندر" in port_clean or "دخيل" in port_clean
                    )
                    if not (is_alex or (target in port_clean or port_clean in target)):
                        entry_matches = False
                        break

                elif st == "supplier":
                    target = self._normalize_text(sv)
                    if not supplier_clean or not (target in supplier_clean or supplier_clean in target):
                        entry_matches = False
                        break

                elif st == "shipping_line":
                    target = self._normalize_text(sv)
                    if not line_clean or not (target in line_clean or line_clean in target):
                        entry_matches = False
                        break
                else:
                    entry_matches = False
                    break

            if entry_matches:
                matched.append(entry)

        return matched
