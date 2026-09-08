"""
incoterms_matrix.py
====================
طبقة المنطق (Business Logic Layer) لمصفوفة إنكوترمز 2020.

الفلسفة المعمارية:
- البيانات (incoterms_data.json) منفصلة تمامًا عن الكود => Single Source of Truth.
- الأنواع (Enums) بدل النصوص الحرة => يمنع الأخطاء مبكرًا (fail fast) عبر type checking.
- كل كلاس له مسؤولية واحدة فقط (Single Responsibility Principle):
    Party            -> يمثّل "من يدفع" فقط.
    CostCategory     -> يمثّل تعريف بند تكلفة واحد + هل هو رسمي من ICC أم عرف تجاري.
    Incoterm         -> يمثّل شرط تجاري واحد وكل مسؤولياته.
    IncotermsMatrix  -> بوابة الاستعلام الوحيدة (Facade) فوق البيانات، ولا تُنشئ أي بيانات بنفسها.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Dict, List, Optional, Union


# ---------------------------------------------------------------------------
# 1) طبقة الأنواع (Domain Enums)
# ---------------------------------------------------------------------------

class Party(str, Enum):
    """من يتحمل البند: المشتري أم البائع."""
    BUYER = "BUYER"
    SELLER = "SELLER"

    def label_ar(self) -> str:
        return "المشتري" if self is Party.BUYER else "البائع"


class TransportMode(str, Enum):
    ANY = "any"
    SEA_INLAND_WATERWAY = "sea_inland_waterway"


# ---------------------------------------------------------------------------
# 2) طبقة النماذج (Domain Models) - كائنات بيانات غير قابلة للتعديل (immutable)
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class CostCategory:
    key: str
    label_ar: str
    is_icc_defined: bool  # False = بند تعاقدي/عرف تجاري وليس نصًا رسميًا من ICC


@dataclass(frozen=True)
class Incoterm:
    code: str
    label_ar: str
    mode: TransportMode
    responsibilities: Dict[str, Party]  # key = CostCategory.key

    def who_pays(self, category_key: str) -> Party:
        try:
            return self.responsibilities[category_key]
        except KeyError as exc:
            raise KeyError(f"لا يوجد بند تكلفة باسم '{category_key}' في {self.code}") from exc


# ---------------------------------------------------------------------------
# 3) طبقة الوصول للبيانات + الاستعلام (Repository / Facade)
# ---------------------------------------------------------------------------

class IncotermsMatrix:
    """
    الواجهة الوحيدة للتعامل مع مصفوفة الإنكوترمز.
    - تحمّل البيانات من JSON (فصل البيانات عن الكود).
    - تبني كائنات Incoterm / CostCategory (تحويل بيانات خام إلى نماذج آمنة الأنواع).
    - توفر دوال استعلام جاهزة بدل ما يكتب كل مبرمج if/else بنفسه.
    """

    def __init__(self, categories: Dict[str, CostCategory], terms: Dict[str, Incoterm]):
        self._categories = categories
        self._terms = terms
        self._validate()

    # ---- التحميل (Loading) ----
    @classmethod
    def from_json_file(cls, path: str | Path | None = None) -> "IncotermsMatrix":
        target_path: Path
        if path is not None:
            target_path = Path(path)
            if not target_path.exists():
                candidate1 = Path(__file__).parent / path
                candidate2 = Path(__file__).parent / "incoterms_data.json"
                if candidate1.exists():
                    target_path = candidate1
                elif candidate2.exists():
                    target_path = candidate2
        else:
            candidate1 = Path(__file__).parent / "incoterms_data.json"
            candidate2 = Path("incoterms_data.json")
            if candidate1.exists():
                target_path = candidate1
            elif candidate2.exists():
                target_path = candidate2
            else:
                target_path = Path("incoterms_data.json")

        raw = json.loads(target_path.read_text(encoding="utf-8"))

        categories = {
            c["key"]: CostCategory(
                key=c["key"], label_ar=c["label_ar"], is_icc_defined=c["is_icc_defined"]
            )
            for c in raw["cost_categories"]
        }

        terms = {
            code: Incoterm(
                code=code,
                label_ar=data["label_ar"],
                mode=TransportMode(data["mode"]),
                responsibilities={
                    k: Party(v) for k, v in data["responsibilities"].items()
                },
            )
            for code, data in raw["incoterms"].items()
        }
        return cls(categories, terms)

    # ---- التحقق من سلامة البيانات (Validation) ----
    def _validate(self) -> None:
        expected_keys = set(self._categories.keys())
        for code, term in self._terms.items():
            missing = expected_keys - term.responsibilities.keys()
            extra = term.responsibilities.keys() - expected_keys
            if missing:
                raise ValueError(f"الشرط {code} ناقص بنود: {missing}")
            if extra:
                raise ValueError(f"الشرط {code} فيه بنود غير معرّفة: {extra}")

    # ---- دوال الاستعلام (Query API) ----
    def who_pays(self, term_code: str, category_key: str) -> Party:
        return self._terms[term_code].who_pays(category_key)

    def get_term(self, term_code: str) -> Incoterm:
        return self._terms[term_code]

    def list_terms(self) -> List[str]:
        return list(self._terms.keys())

    def list_categories(self, icc_defined_only: bool = False) -> List[CostCategory]:
        cats = self._categories.values()
        if icc_defined_only:
            cats = [c for c in cats if c.is_icc_defined]
        return list(cats)

    def compare(self, term_a: str, term_b: str) -> Dict[str, tuple[Party, Party]]:
        """يقارن كل بنود التكلفة بين شرطين تجاريين."""
        a, b = self._terms[term_a], self._terms[term_b]
        return {
            key: (a.responsibilities[key], b.responsibilities[key])
            for key in self._categories
        }

    def terms_where_buyer_handles_import(self) -> List[str]:
        """مثال عملي: كل الشروط التي يتحمل فيها المشتري التخليص الجمركي للاستيراد."""
        return [
            code for code, term in self._terms.items()
            if term.who_pays("import_clearance") is Party.BUYER
        ]

    # ---- طبقة العرض (Presentation helpers) ----
    def to_matrix_dict(self) -> Dict[str, Dict[str, str]]:
        """تنسيق مناسب للعرض أو التصدير لجدول (بدون أي اعتماد على pandas)."""
        return {
            code: {key: term.responsibilities[key].value for key in self._categories}
            for code, term in self._terms.items()
        }

    def to_dataframe(self):
        """تصدير اختياري لـ pandas DataFrame - مستقل عن منطق العمل الأساسي."""
        import pandas as pd  # استيراد محلي: لا نفرض pandas على من لا يحتاج العرض فقط
        return pd.DataFrame.from_dict(self.to_matrix_dict(), orient="index")


# ---------------------------------------------------------------------------
# مثال استخدام (Usage Example) - يوضّح الهدف من الأساس المعماري أعلاه
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    matrix = IncotermsMatrix.from_json_file("incoterms_data.json")

    print("من يدفع رسوم OTHC في شرط FOB؟ ->", matrix.who_pays("FOB", "othc").label_ar())

    print("\nمقارنة CPT مقابل DAP في بند DTHC:")
    cmp = matrix.compare("CPT", "DAP")
    p_cpt, p_dap = cmp["dthc"]
    print(f"  CPT: {p_cpt.label_ar()} | DAP: {p_dap.label_ar()}")

    print("\nالشروط التي يتحمل فيها المشتري التخليص الجمركي للاستيراد:")
    print(", ".join(matrix.terms_where_buyer_handles_import()))

    print("\nالبنود غير المعرّفة رسميًا من ICC (عرف تجاري فقط):")
    for c in matrix.list_categories(icc_defined_only=False):
        if not c.is_icc_defined:
            print(" -", c.label_ar)
