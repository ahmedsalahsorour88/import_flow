"""
Quotation Validation Layer (AI-EXTRACT-VALIDATE-001)
Provides an independent reference counter and verification audit layer
for customs broker quotation extraction, detecting incomplete extraction
before final quote adoption.
"""

from __future__ import annotations

import re
from typing import Any, Dict, List, Optional


class QuotationValidationLayer:
    """
    Independent validation and completeness verification engine for
    customs broker quotation documents.
    """

    @classmethod
    def count_expected_items(cls, raw_text: str) -> Dict[str, Any]:
        """
        Independent reference counter running on raw document text.
        Scans for price patterns, multi-value cells, and price ranges
        to estimate expected line item count independent of the AI model.
        """
        if not raw_text or not raw_text.strip():
            return {
                "expected_item_count": 0,
                "detected_patterns_count": 0,
                "pattern_details": [],
            }

        expected_count = 0
        pattern_details: List[Dict[str, Any]] = []

        ignore_prefix_keywords = [
            "تاريخ", "date", "السادة", "عناية", "هاتف", "فاكس", "العنوان",
            "سجل", "بطاقة", "ساري", "تلفون", "موبايل", "صلاحية", "phone", "fax",
            "صفحة", "page", "الرقم الضريبي", "إجمالي", "المجموع", "total"
        ]

        lines = raw_text.splitlines()
        for line in lines:
            line_clean = line.strip()
            if not line_clean or len(line_clean) < 3:
                continue

            # Skip pure container/table section header lines
            u_line = line_clean.upper()
            if u_line in ("LCL", "20FT", "20 FT", "40FT", "40 FT", "40HQ", "40'HQ"):
                continue

            # Skip metadata and total lines
            if any(line_clean.lower().startswith(kw) for kw in ignore_prefix_keywords):
                continue
            if any(kw in line_clean.lower() for kw in ["إجمالي", "المجموع", "grand total", "total cost", "total estimate"]):
                continue

            # 1. Check for conditional range lines (e.g. بخلاف ... من X إلى Y)
            range_match = re.search(
                r"(?:من|from)\s*([0-9,]+(?:\.[0-9]+)?)\s*(?:إلى|الي|to|-)\s*([0-9,]+(?:\.[0-9]+)?)",
                line_clean,
                re.IGNORECASE,
            )
            if range_match and (
                "بخلاف" in line_clean
                or "شروط" in line_clean
                or "ملاحظات" in line_clean
                or any(curr in line_clean for curr in ["جنيه", "EGP", "ج.م", "$", "USD"])
            ):
                expected_count += 1
                pattern_details.append({
                    "pattern_type": "range_item",
                    "line": line_clean[:80],
                    "items_count": 1,
                })
                continue

            # 2. Check for multi-value pattern inside parentheses: ( 250 / 250 / 250 )
            multi_paren = re.search(
                r"\(\s*([0-9,]+(?:\.[0-9]+)?(?:\s*[/–—\-]\s*[0-9,]+(?:\.[0-9]+)?)+)\s*\)",
                line_clean,
            )
            if multi_paren:
                parts = [p.strip() for p in re.split(r"[/–—\-]", multi_paren.group(1)) if p.strip()]
                if len(parts) >= 2:
                    expected_count += len(parts)
                    pattern_details.append({
                        "pattern_type": "multi_value_paren",
                        "line": line_clean[:80],
                        "items_count": len(parts),
                    })
                    continue

            # 3. Check for composite named procedures with single bundled price (e.g. مطافي ومفرقعات ودمغة موازين)
            if "مطافي" in line_clean and "مفرقعات" in line_clean and "موازين" in line_clean:
                expected_count += 3
                pattern_details.append({
                    "pattern_type": "composite_procedures_3",
                    "line": line_clean[:80],
                    "items_count": 3,
                })
                continue

            if "افراج نهائي" in line_clean and ("اشعاع" in line_clean or "إشعاع" in line_clean) and "كيمياء" in line_clean:
                expected_count += 3
                pattern_details.append({
                    "pattern_type": "composite_procedures_3",
                    "line": line_clean[:80],
                    "items_count": 3,
                })
                continue

            if "زراعة" in line_clean and "مهمل" in line_clean and "سيل" in line_clean:
                expected_count += 3
                pattern_details.append({
                    "pattern_type": "composite_procedures_3",
                    "line": line_clean[:80],
                    "items_count": 3,
                })
                continue

            # 4. Check for multi-value dash / slash price patterns (e.g. 250.00 - 250.00 or 500 - 1000 - 1500)
            multi_val_dash = re.search(
                r"(?:(?:EGP|ج\.م|جنيه)\s*)?([0-9,]+(?:\.[0-9]+)?)\s*[-/–—]\s*([0-9,]+(?:\.[0-9]+)?)(?:\s*[-/–—]\s*([0-9,]+(?:\.[0-9]+)?))?",
                line_clean,
            )
            if multi_val_dash and any(curr in line_clean for curr in ["EGP", "ج.م", "جنيه", "$", "USD"]):
                groups = [g for g in multi_val_dash.groups() if g]
                if len(groups) == 3:
                    expected_count += 3
                    pattern_details.append({
                        "pattern_type": "multi_value_3",
                        "line": line_clean[:80],
                        "items_count": 3,
                    })
                    continue
                elif len(groups) == 2:
                    after_price = line_clean.split(groups[1])[-1]
                    has_multi_names = any(d in after_price for d in ["-", "/", "+"]) or any(
                        kw in line_clean for kw in ["دمغات", "كفر الشيخ", "البحيرة", "ايباك", "إيباك"]
                    )
                    if groups[0] == groups[1] or has_multi_names:
                        expected_count += 2
                        pattern_details.append({
                            "pattern_type": "multi_value_2",
                            "line": line_clean[:80],
                            "items_count": 2,
                        })
                        continue
                    else:
                        expected_count += 1
                        pattern_details.append({
                            "pattern_type": "range_item_dash",
                            "line": line_clean[:80],
                            "items_count": 1,
                        })
                        continue

            # 5. Single price line with currency or substantial numeric price
            multi_numbers = re.findall(r"[0-9,]+(?:\.[0-9]+)?", line_clean)
            price_candidates = []
            for n_str in multi_numbers:
                try:
                    val = float(n_str.replace(",", ""))
                    if val >= 50 and val not in (2025, 2026, 2027):
                        price_candidates.append(val)
                except ValueError:
                    pass

            if any(curr in line_clean for curr in ["EGP", "ج.م", "جنيه", "$", "USD"]) or price_candidates:
                if price_candidates:
                    expected_count += 1
                    pattern_details.append({
                        "pattern_type": "single_price_line",
                        "line": line_clean[:80],
                        "items_count": 1,
                    })

        return {
            "expected_item_count": expected_count,
            "detected_patterns_count": len(pattern_details),
            "pattern_details": pattern_details,
        }

    @classmethod
    def validate_extraction(
        cls,
        expected_count: int,
        extracted_items: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        """
        Validates the extracted items against the independent expected item count.
        Calculates gap, gap percentage, confidence classification, and localized banner messages.
        """
        extracted_count = len(extracted_items) if extracted_items else 0
        expected = max(expected_count, 1) if (expected_count > 0 or extracted_count > 0) else 0

        if expected == 0:
            return {
                "expected_count": 0,
                "extracted_count": 0,
                "gap_count": 0,
                "gap_percentage": 0.0,
                "confidence_level": "reliable",
                "banner_status": "safe",
                "requires_modal_confirmation": False,
                "banner_message_ar": "لا توجد بنود مستخرجة",
                "banner_message_en": "No items extracted",
                "multi_value_items_count": 0,
                "range_items_count": 0,
                "outside_table_items_count": 0,
            }

        # Count coded vs uncoded items
        coded_items = [itm for itm in extracted_items if itm.get("code") and not itm.get("is_uncoded")]
        coded_count = len(coded_items)
        uncoded_items = [itm for itm in extracted_items if itm.get("is_uncoded") or not itm.get("code")]
        uncoded_count = len(uncoded_items)

        # Calculate completeness gap strictly
        if extracted_count >= expected:
            gap_count = 0
            gap_percentage = 0.0
        else:
            gap_count = expected - extracted_count
            gap_percentage = round((gap_count / expected) * 100, 1)

        # Strict mathematical guarantee: equal counts always mean zero gap
        if extracted_count == expected:
            gap_count = 0
            gap_percentage = 0.0

        # Classification rules from spec AI-EXTRACT-VALIDATE-001 Section 4.2 & AI-EXPENSE-CATALOG-002:
        # - Gap <= 5% -> safe / reliable
        # - 5% < Gap <= 20% -> warning
        # - Gap > 20% -> critical (requires explicit confirmation)
        if gap_percentage <= 5.0:
            confidence_level = "reliable"
            banner_status = "safe"
            requires_modal = False
            banner_message_ar = (
                f"استخراج موثوق ومكتمل: تم استخراج وتكويد {extracted_count} بنداً بنجاح بنسبة دقة وتطابق عالية."
            )
            banner_message_en = (
                f"Reliable and complete extraction: {extracted_count} items successfully extracted with high confidence."
            )
        elif gap_percentage <= 20.0:
            confidence_level = "warning"
            banner_status = "warning"
            requires_modal = False
            banner_message_ar = (
                f"تنبيه مراجعة البيان: احتمال وجود بنود لم تُستخرج (تم استخراج {extracted_count} من {expected} بنداً متوقعاً بفجوة {gap_percentage}%)."
            )
            banner_message_en = (
                f"Review notice: Likely unextracted items ({extracted_count} of {expected} expected items, gap: {gap_percentage}%)."
            )
        else:
            confidence_level = "critical"
            banner_status = "critical"
            requires_modal = True
            banner_message_ar = (
                f"تحذير حرج: اكتشفنا {expected} نمطاً سعرياً في المستند لكن تم استخراج {extracted_count} بنداً فقط (فجوة نقص {gap_percentage}%). يرجى المراجعة والتحقق قبل الاعتماد النهائي."
            )
            banner_message_en = (
                f"Critical warning: Found {expected} price patterns but extracted only {extracted_count} items (gap: {gap_percentage}%). Review before approval."
            )

        if uncoded_count > 0:
            banner_message_ar += f" (تنبيه: {uncoded_count} بنداً يحتاج تكويداً في الكتالوج)"
            banner_message_en += f" (Notice: {uncoded_count} items require coding in catalog)"

        # Count special categories in extracted items
        multi_value_count = sum(
            1 for itm in extracted_items
            if itm.get("is_multi_value_split") or itm.get("extraction_confidence") == "medium"
        )
        range_count = sum(
            1 for itm in extracted_items
            if itm.get("price_type") == "range" or itm.get("min_price") is not None
        )
        outside_table_count = sum(
            1 for itm in extracted_items
            if itm.get("source_location") == "outside_table"
        )

        return {
            "expected_count": expected,
            "expected_item_count": expected,
            "extracted_count": extracted_count,
            "extracted_item_count": extracted_count,
            "coded_items_count": coded_count,
            "uncoded_items_count": uncoded_count,
            "uncoded_items": [
                itm.get("item_name") or itm.get("expense_name") for itm in uncoded_items
            ],
            "gap_count": gap_count,
            "gap_percentage": gap_percentage,
            "confidence_level": confidence_level,
            "banner_status": banner_status,
            "requires_modal_confirmation": requires_modal,
            "banner_message_ar": banner_message_ar,
            "banner_message_en": banner_message_en,
            "message_ar": banner_message_ar,
            "message_en": banner_message_en,
            "multi_value_items_count": multi_value_count,
            "range_items_count": range_count,
            "outside_table_items_count": outside_table_count,
        }
