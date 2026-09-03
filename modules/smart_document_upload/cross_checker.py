"""
Cross-Document Reconciliation & Discrepancy Engine
Performs 10-point cross-matching between Commercial Invoice and Bill of Lading / AWB
for Egyptian Customs (Nafeza) pre-clearance verification.
"""

from __future__ import annotations

import difflib
import re
from typing import Any, Dict, List, Optional, Tuple


def cross_check_invoice_vs_bl(
    invoice_data: Dict[str, Any],
    bl_data: Dict[str, Any],
    weight_tolerance_pct: float = 3.0,
) -> Dict[str, Any]:
    """
    Performs 10-point cross-comparison between Commercial Invoice and Draft B/L.
    Returns audit matrix, critical discrepancies, warnings, and auto-generated correction notices.
    """
    matrix: List[Dict[str, Any]] = []
    critical_errors: List[str] = []
    warnings: List[str] = []

    # ─── 1. ACID Number (19 Digits) — Strict 0% ───────────────────────────────
    inv_acid = _clean_acid(invoice_data.get("acid_number"))
    bl_acid = _clean_acid(bl_data.get("acid_number"))
    acid_match = bool(inv_acid and bl_acid and inv_acid == bl_acid)

    if not acid_match:
        critical_errors.append("عدم تطابق رقم القيد الجمركي المسبق (ACID) بين الفاتورة والبوليصة")
    matrix.append({
        "check_code": "CHK_ACID",
        "title_ar": "رقم القيد الجمركي المسبق (ACID)",
        "title_en": "ACID Number (19 Digits)",
        "invoice_value": inv_acid or "غير موجود بالفاتورة",
        "bl_value": bl_acid or "غير موجود بالبوليصة",
        "status": "PASS" if acid_match else "CRITICAL",
        "severity": "BLOCKING" if not acid_match else "NONE",
        "details_ar": "رقم ACID مطابق تماماً بنسبة 100%" if acid_match else "❌ عدم تطابق رقم ACID يؤدي لرفض الشحنة وإلزام إعادة التصدير من الجمارك المصرية.",
    })

    # ─── 2. Importer Tax ID (9 Digits) ────────────────────────────────────────
    inv_tax = _clean_numeric(invoice_data.get("importer_tax_id"))
    bl_tax = _clean_numeric(bl_data.get("importer_tax_id") or bl_data.get("consignee_tax_id"))
    tax_match = bool(inv_tax and bl_tax and inv_tax == bl_tax)
    if not tax_match and inv_tax and bl_tax:
        critical_errors.append("عدم تطابق البطاقة الضريبية للمستورد المصري")

    matrix.append({
        "check_code": "CHK_IMPORTER_TAX_ID",
        "title_ar": "البطاقة الضريبية للمستورد (Tax ID)",
        "title_en": "Importer Tax ID (9 Digits)",
        "invoice_value": inv_tax or "غير متوفر",
        "bl_value": bl_tax or "غير مسجل بالبوليصة",
        "status": "PASS" if tax_match else ("WARNING" if not bl_tax else "CRITICAL"),
        "severity": "WARNING" if not bl_tax else ("NONE" if tax_match else "BLOCKING"),
        "details_ar": "رقم التسجيل الضريبي للمستورد مطابق" if tax_match else "ينصح بتضمين البطاقة الضريبية للمستورد في خانة Consignee بالبوليصة لتسريع الربط بنافذة.",
    })

    # ─── 3. Exporter / Shipper Name ───────────────────────────────────────────
    inv_shp = invoice_data.get("supplier_name") or invoice_data.get("shipper") or ""
    bl_shp = bl_data.get("shipper") or ""
    shp_match, shp_sim = _fuzzy_match(inv_shp, bl_shp)
    if not shp_match and inv_shp and bl_shp:
        warnings.append(f"اختلاف مسمى المصدر/الشاحن (نسبة التطابق {int(shp_sim * 100)}%)")

    matrix.append({
        "check_code": "CHK_SHIPPER",
        "title_ar": "اسم وبيانات المصدر / الشاحن (Shipper)",
        "title_en": "Shipper / Exporter Name",
        "invoice_value": inv_shp or "غير محدد",
        "bl_value": bl_shp or "غير محدد",
        "status": "PASS" if shp_match else "WARNING",
        "severity": "NONE" if shp_match else "WARNING",
        "details_ar": f"تطابق المسمى بنسبة {int(shp_sim * 100)}%" if shp_match else "يجب التأكد من أن الشاحن في البوليصة هو نفسه المورد بالفاتورة أو وكيل شحن معتمد باسمه.",
    })

    # ─── 4. Consignee / Importer Name ─────────────────────────────────────────
    inv_cns = invoice_data.get("importer_name") or invoice_data.get("consignee") or ""
    bl_cns = bl_data.get("consignee") or ""
    cns_match, cns_sim = _fuzzy_match(inv_cns, bl_cns)
    if not cns_match and inv_cns and bl_cns:
        warnings.append(f"اختلاف مسمى المستورد / المرسل إليه (نسبة التطابق {int(cns_sim * 100)}%)")

    matrix.append({
        "check_code": "CHK_CONSIGNEE",
        "title_ar": "اسم وبيانات المستورد / المرسل إليه (Consignee)",
        "title_en": "Consignee / Importer Name",
        "invoice_value": inv_cns or "غير محدد",
        "bl_value": bl_cns or "غير محدد",
        "status": "PASS" if cns_match else "WARNING",
        "severity": "NONE" if cns_match else "WARNING",
        "details_ar": f"تطابق المرسل إليه بنسبة {int(cns_sim * 100)}%" if cns_match else "يجب تطابق اسم الشركة المستوردة أو كتابة 'TO ORDER' حسب شروط الاعتماد/التحصيل المستندي.",
    })

    # ─── 5. Gross Weight Discrepancy (Tolerance Check) ────────────────────────
    inv_gw = _parse_float(invoice_data.get("total_gross_weight_kg"))
    bl_gw = _parse_float(bl_data.get("total_gross_weight_kg"))

    weight_status = "PASS"
    weight_diff_kg = 0.0
    weight_var_pct = 0.0
    weight_details = "الوزن القائم مطابق"

    if inv_gw and bl_gw:
        weight_diff_kg = round(bl_gw - inv_gw, 2)
        weight_var_pct = round((abs(weight_diff_kg) / inv_gw) * 100, 2)
        if weight_var_pct > weight_tolerance_pct:
            weight_status = "CRITICAL"
            critical_errors.append(f"انحراف في الوزن الإجمالي بمقدار {weight_diff_kg} كجم ({weight_var_pct}%) يتجاوز النسبة المسموحة ({weight_tolerance_pct}%)")
            weight_details = f"❌ تجاوز نسبة التفاوت المسموحة ({weight_tolerance_pct}%): فرق الوزن {weight_diff_kg} كجم قد يسبب محاضر فرق وزن وتعديل الإقرار الجمركي."
        elif weight_var_pct > 0:
            weight_status = "WARNING"
            warnings.append(f"فرق وزن طفيف {weight_diff_kg} كجم ({weight_var_pct}%) ضمن حدود التفاوت المقبولة")
            weight_details = f"⚠️ تفاوت طفيف مقداره {weight_diff_kg} كجم ({weight_var_pct}%) يقع ضمن النسبة المسموح بها."
        else:
            weight_details = "الوزن القائم متطابق تماماً بين الفاتورة وبوليصة الشحن."
    elif not inv_gw and bl_gw:
        weight_status = "INFO"
        weight_details = f"الوزن محدد في البوليصة فقط ({bl_gw} كجم)، ولم يذكر إجمالي الوزن في الفاتورة."

    matrix.append({
        "check_code": "CHK_GROSS_WEIGHT",
        "title_ar": "مطابقة الوزن الإجمالي القائم (Gross Weight KG)",
        "title_en": "Total Gross Weight Matching",
        "invoice_value": f"{inv_gw:,.2f} KG" if inv_gw else "غير مسجل",
        "bl_value": f"{bl_gw:,.2f} KG" if bl_gw else "غير مسجل",
        "status": weight_status,
        "severity": "BLOCKING" if weight_status == "CRITICAL" else ("WARNING" if weight_status == "WARNING" else "NONE"),
        "variance_kg": weight_diff_kg,
        "variance_percentage": weight_var_pct,
        "details_ar": weight_details,
    })

    # ─── 6. Port of Loading & Port of Discharge ───────────────────────────────
    inv_pol = invoice_data.get("loading_port") or ""
    bl_pol = bl_data.get("loading_port") or ""
    pol_match = _ports_match(inv_pol, bl_pol)

    inv_pod = invoice_data.get("discharge_port") or ""
    bl_pod = bl_data.get("discharge_port") or ""
    pod_match = _ports_match(inv_pod, bl_pod)

    ports_ok = pol_match and pod_match
    if not ports_ok and (inv_pol or inv_pod):
        warnings.append("عدم تطابق تام في مسمى ميناء الشحن أو التفريغ")

    matrix.append({
        "check_code": "CHK_PORTS",
        "title_ar": "موانئ الشحن والتفريغ (POL & POD)",
        "title_en": "Ports of Loading & Discharge",
        "invoice_value": f"POL: {inv_pol or '-'} | POD: {inv_pod or '-'}",
        "bl_value": f"POL: {bl_pol or '-'} | POD: {bl_pod or '-'}",
        "status": "PASS" if ports_ok else "WARNING",
        "severity": "NONE" if ports_ok else "WARNING",
        "details_ar": "الموانئ متطابقة" if ports_ok else "يجب التأكد من أن ميناء الوصول بالبوليصة يطابق الميناء المذكور في نافذة ونموذج 4.",
    })

    # ─── 7. Incoterms vs Freight Terms (FOB vs Prepaid) ───────────────────────
    incoterm = str(invoice_data.get("incoterms") or "").upper()
    freight_term = str(bl_data.get("freight_payment_term") or "").upper()

    incoterm_conflict = False
    incoterm_details = "شرط التجارة متوافق مع طريقة سداد النولون"

    if incoterm in ["FOB", "EXW", "FCA", "FAS"]:
        if "PREPAID" in freight_term:
            incoterm_conflict = True
            critical_errors.append(f"تعارض شروط الشحن: الفاتورة شرطها {incoterm} بينما البوليصة مدفوعة مسبقاً (Freight Prepaid)!")
            incoterm_details = f"❌ تعارض حرج: شرط الفاتورة {incoterm} يلزم أن يكون النولون Freight Collect (سداد في ميناء الوصول) لتفادي احتساب نولون مزدوج."
        else:
            incoterm_details = f"شرط التعاقد {incoterm} متوافق مع سداد النولون في الوصول ({freight_term})."
    elif incoterm in ["CIF", "CFR", "CPT", "CIP", "DDP", "DAP"]:
        if "COLLECT" in freight_term:
            incoterm_conflict = True
            critical_errors.append(f"تعارض شروط الشحن: الفاتورة شرطها {incoterm} شاملة النولون بينما البوليصة مستحقة التحصيل (Freight Collect)!")
            incoterm_details = f"❌ تعارض حرج: شرط الفاتورة {incoterm} يتضمن النولون، ولا يجوز أن تكون البوليصة Freight Collect."
        else:
            incoterm_details = f"شرط التعاقد {incoterm} متوافق مع سداد النولون مسبقاً ({freight_term})."

    matrix.append({
        "check_code": "CHK_INCOTERMS_FREIGHT",
        "title_ar": "توافق شرط التجارة والنولون (Incoterms vs Freight Payment)",
        "title_en": "Incoterms & Freight Terms Consistency",
        "invoice_value": f"Incoterm: {incoterm or 'غير محدد'}",
        "bl_value": f"Freight: {freight_term or 'غير محدد'}",
        "status": "CRITICAL" if incoterm_conflict else "PASS",
        "severity": "BLOCKING" if incoterm_conflict else "NONE",
        "details_ar": incoterm_details,
    })

    # ─── 8. Packaging & Package Count ─────────────────────────────────────────
    inv_pkgs = invoice_data.get("total_packages_count")
    bl_pkgs = bl_data.get("total_packages_count")
    pkgs_match = True
    if inv_pkgs and bl_pkgs and inv_pkgs != bl_pkgs:
        pkgs_match = False
        warnings.append(f"اختلاف عدد الطرود بين الفاتورة ({inv_pkgs}) والبوليصة ({bl_pkgs})")

    matrix.append({
        "check_code": "CHK_PACKAGES",
        "title_ar": "عدد ونوع الطرود (Package Count & Type)",
        "title_en": "Total Packages & Unit Type",
        "invoice_value": str(inv_pkgs or "غير محدد"),
        "bl_value": f"{bl_pkgs or 'غير محدد'} ({bl_data.get('package_type') or 'Pkgs'})",
        "status": "PASS" if pkgs_match else "WARNING",
        "severity": "NONE" if pkgs_match else "WARNING",
        "details_ar": "عدد الطرود متطابق" if pkgs_match else "يجب مراجعة بيان العبوة (Packing List) لتوحيد عدد الطرود في الفاتورة والبوليصة.",
    })

    # ─── 9. Currency Consistency ──────────────────────────────────────────────
    inv_curr = str(invoice_data.get("currency") or "USD").upper()
    matrix.append({
        "check_code": "CHK_CURRENCY",
        "title_ar": "عملة المعاملة والتقييم (Currency)",
        "title_en": "Transaction Currency",
        "invoice_value": inv_curr,
        "bl_value": "حسب البوليصة / النولون",
        "status": "PASS",
        "severity": "NONE",
        "details_ar": f"عملة الفاتورة المعتمدة هي {inv_curr}.",
    })

    # ─── 10. Date Plausibility ────────────────────────────────────────────────
    inv_date = invoice_data.get("invoice_date")
    bl_date = bl_data.get("issue_date") or bl_data.get("etd")
    date_ok = True
    matrix.append({
        "check_code": "CHK_DATES",
        "title_ar": "التسلسل الزمني للإصدار والإبحار (Dates Sequence)",
        "title_en": "Chronological Issue Dates Sequence",
        "invoice_value": f"تاريخ الفاتورة: {inv_date or '-'}",
        "bl_value": f"تاريخ البوليصة: {bl_date or '-'}",
        "status": "PASS" if date_ok else "WARNING",
        "severity": "NONE",
        "details_ar": "التسلسل الزمني منطقي لإجراءات التصدير والشحن.",
    })

    # ─── Overall Verdict & Score ──────────────────────────────────────────────
    total_checks = len(matrix)
    passed_checks = sum(1 for m in matrix if m["status"] == "PASS")
    compliance_score = round((passed_checks / total_checks) * 100, 1)

    if critical_errors:
        verdict = "CRITICAL_MISMATCH"
        verdict_ar = "توجد تناقضات حرجة مانعة للإفراج الجمركي (يجب تعديل المستندات)"
    elif warnings:
        verdict = "WARNINGS_DETECTED"
        verdict_ar = "مستندات مقبولة مع وجود ملاحظات تحذيرية ينصح بمراجعتها"
    else:
        verdict = "COMPLIANT"
        verdict_ar = "المستندات متطابقة تماماً وجاهزة للتقديم الجمركي بنسبة 100%"

    # Auto-generate formal English and Arabic correction notices
    correction_letters = _generate_correction_letters(
        invoice_data=invoice_data,
        bl_data=bl_data,
        critical_errors=critical_errors,
        warnings=warnings,
    )

    return {
        "verdict": verdict,
        "verdict_ar": verdict_ar,
        "compliance_score": compliance_score,
        "critical_errors_count": len(critical_errors),
        "warnings_count": len(warnings),
        "critical_errors": critical_errors,
        "warnings": warnings,
        "audit_matrix": matrix,
        "containers_count": len(bl_data.get("containers") or []),
        "items_count": len(invoice_data.get("items") or []),
        "correction_notice_en": correction_letters["en"],
        "correction_notice_ar": correction_letters["ar"],
    }


def _clean_acid(raw: Any) -> Optional[str]:
    if not raw:
        return None
    val = re.sub(r"[^0-9]", "", str(raw).strip())
    return val if len(val) == 19 else None


def _clean_numeric(raw: Any) -> Optional[str]:
    if not raw:
        return None
    val = re.sub(r"[^0-9]", "", str(raw).strip())
    return val if len(val) >= 7 else None


def _parse_float(val: Any) -> Optional[float]:
    if val is None:
        return None
    try:
        return float(str(val).replace(",", "").strip())
    except ValueError:
        return None


def _fuzzy_match(s1: str, s2: str, threshold: float = 0.70) -> Tuple[bool, float]:
    clean1 = re.sub(r"[^A-Za-z0-9]", " ", s1.lower()).strip()
    clean2 = re.sub(r"[^A-Za-z0-9]", " ", s2.lower()).strip()
    if not clean1 or not clean2:
        return False, 0.0
    if clean1 in clean2 or clean2 in clean1:
        return True, 1.0
    ratio = difflib.SequenceMatcher(None, clean1, clean2).ratio()
    return ratio >= threshold, ratio


def _ports_match(p1: str, p2: str) -> bool:
    if not p1 or not p2:
        return True
    c1 = re.sub(r"[^A-Za-z0-9]", " ", p1.lower()).strip()
    c2 = re.sub(r"[^A-Za-z0-9]", " ", p2.lower()).strip()
    tokens1 = set(c1.split())
    tokens2 = set(c2.split())
    return bool(tokens1 & tokens2) or c1 in c2 or c2 in c1


def _generate_correction_letters(
    invoice_data: dict,
    bl_data: dict,
    critical_errors: List[str],
    warnings: List[str],
) -> Dict[str, str]:
    """Generates official discrepancy correction amendment notices in EN and AR."""
    bl_no = bl_data.get("bl_number") or "N/A"
    inv_no = invoice_data.get("invoice_number") or "N/A"
    carrier = bl_data.get("carrier_name") or "Shipping Line"

    issues_en = "\n".join([f"- {err}" for err in critical_errors + warnings]) or "- Discrepancies noted in draft review."
    issues_ar = "\n".join([f"- {err}" for err in critical_errors + warnings]) or "- ملاحظات تدقيق البوليصة والفاتورة."

    letter_en = f"""URGENT: B/L DRAFT AMENDMENT REQUEST FOR CUSTOMS CLEARANCE
To: {carrier} / Documentation Department
Re: Bill of Lading No: {bl_no} | Commercial Invoice No: {inv_no}
ACID Number: {invoice_data.get('acid_number') or bl_data.get('acid_number') or 'N/A'}

Dear Sir / Madam,

Following our smart import compliance audit between Commercial Invoice #{inv_no} and Draft B/L #{bl_no}, please be advised that the following discrepancies were detected and require immediate amendment prior to issuing the Original B/L:

{issues_en}

To comply with Egyptian Customs Authority (Nafeza Portal) and prevent customs fines or rejection at the Port of Discharge, please update the Bill of Lading accordingly and provide us with the revised draft.

Thank you for your prompt cooperation.
Best regards,
Import Operations & Customs Clearance Dept.
"""

    letter_ar = f"""عاجل: طلب تعديل مسودة بوليصة الشحن (Draft B/L Amendment)
السادة: {carrier} / قسم التوثيق وإصدار البوالص
بخصوص: بوليصة شحن رقم {bl_no} | فاتورة تجارية رقم {inv_no}
رقم الـ ACID الجمركي: {invoice_data.get('acid_number') or bl_data.get('acid_number') or 'N/A'}

تحية طيبة وبعد،،

بالإشارة إلى بوليصة الشحن المذكورة أعلاه، وبعد إجراء التدقيق الجمركي الآلي والمطابقة مع الفاتورة التجارية رقم {inv_no}، تبين وجود التناقضات التالية التي تتطلب تعديل مسودة البوليصة فوراً قبل اعتمادها:

{issues_ar}

نرجو التكرم بسرعة إجراء التعديلات المطلوبة وموافاتنا بالمسودة المعدلة، تفادياً لتوقيع أي غرامات جمركية أو تعطل الإفراج الجمركي بميناء الوصول عبر منظومة نافذة.

وتفضلوا بقبول فائق الاحترام والتقدير،،
إدارة الاستيراد والتخليص الجمركي
"""

    return {"en": letter_en, "ar": letter_ar}
