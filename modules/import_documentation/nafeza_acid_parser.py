"""
Nafeza Smart ACID Text Parser & Discrepancy Comparison Engine (BP-014)
Extracts structured ACID data from raw MTS / Nafeza notification emails & texts.
Performs fuzzy / exact field comparison against requested shipment data.
"""

import re
from datetime import datetime, date
from typing import Dict, Any, List, Optional, Tuple


def _normalize_string(val: Optional[str]) -> str:
    if not val:
        return ""
    # Strip spaces, normalize multiple spaces, lowercase
    cleaned = re.sub(r"\s+", " ", str(val)).strip()
    return cleaned


def _clean_tax_id(val: Optional[str]) -> str:
    if not val:
        return ""
    return re.sub(r"[\s\-_/]", "", str(val))


def parse_date_flexible(val: Optional[str]) -> Optional[str]:
    if not val:
        return None
    val_clean = val.strip()
    # Common formats from Nafeza / MTS:
    # '31-May-2026 10:40:55 AM', '31-May-2026', '5/27/2026 12:00:00 AM', '5/27/2026', '2026-05-31', '31/05/2026'
    date_patterns = [
        ("%d-%b-%Y %I:%M:%S %p", True),
        ("%d-%b-%Y %H:%M:%S", True),
        ("%d-%b-%Y", False),
        ("%m/%d/%Y %I:%M:%S %p", True),
        ("%m/%d/%Y %H:%M:%S", True),
        ("%m/%d/%Y", False),
        ("%d/%m/%Y %I:%M:%S %p", True),
        ("%d/%m/%Y", False),
        ("%Y-%m-%d %H:%M:%S", True),
        ("%Y-%m-%d", False),
    ]

    # Clean non-breaking spaces or tabs
    val_clean = val_clean.replace("\u2003", " ").replace("\xa0", " ")

    for fmt, _ in date_patterns:
        try:
            dt = datetime.strptime(val_clean, fmt)
            return dt.strftime("%Y-%m-%d")
        except ValueError:
            pass

    # Try regex fallback for YYYY-MM-DD or DD-Mon-YYYY
    match_iso = re.search(r"(\d{4})-(\d{1,2})-(\d{1,2})", val_clean)
    if match_iso:
        y, m, d = match_iso.groups()
        return f"{int(y):04d}-{int(m):02d}-{int(d):02d}"

    match_slash = re.search(r"(\d{1,2})/(\d{1,2})/(\d{4})", val_clean)
    if match_slash:
        m, d, y = match_slash.groups()
        return f"{int(y):04d}-{int(m):02d}-{int(d):02d}"

    return None


def parse_nafeza_acid_text(raw_text: str) -> Dict[str, Any]:
    """
    Parses full raw text from Nafeza / MTS approval notification.
    """
    if not raw_text or not raw_text.strip():
        raise ValueError("النص المدخل فارغ. يرجى لصق نص إشعار نافذة كاملاً.")

    text = raw_text.replace("\r\n", "\n").replace("\r", "\n")

    result: Dict[str, Any] = {
        "acid_number": "",
        "requested_date": None,
        "generated_date": None,
        "expiry_date": None,
        "importer_name": "",
        "importer_tax_id": "",
        "importer_address": "",
        "exporter_name": "",
        "exporter_reg_type": "VAT Number",
        "exporter_reg_id": "",
        "exporter_country": "",
        "exporter_country_code": "",
        "exporter_address": "",
        "exporter_phone": "",
        "cargox_id": "",
        "proforma_invoice_no": "",
        "proforma_invoice_date": None,
        "invoice_date": None,
        "invoice_type": "Proforma Invoice",
        "pol_name": "",
        "pod_name": "",
        "raw_text": raw_text.strip(),
    }

    # 1. ACID Number (19 digits)
    acid_match = re.search(r"\[\s*ACID\s*:\s*(\d{19})\s*\]", text, re.IGNORECASE)
    if not acid_match:
        acid_match = re.search(r"ACID\s*:\s*(\d{19})", text, re.IGNORECASE)
    if not acid_match:
        acid_match = re.search(r"\b(\d{19})\b", text)

    if acid_match:
        result["acid_number"] = acid_match.group(1).strip()
    else:
        # Check if there is an ACID with variable length
        acid_fallback = re.search(r"ACID\s*:\s*([A-Za-z0-9]+)", text, re.IGNORECASE)
        if acid_fallback:
            result["acid_number"] = acid_fallback.group(1).strip()

    # 2. Dates line (Requested, Generated, Expires)
    req_date_match = re.search(r"Requested\s*:\s*([^\n\t\u2003]+?)(?=\s*(?:Generated|Expires|$|\n))", text, re.IGNORECASE)
    if req_date_match:
        result["requested_date"] = parse_date_flexible(req_date_match.group(1))

    gen_date_match = re.search(r"Generated\s*:\s*([^\n\t\u2003]+?)(?=\s*(?:Expires|$|\n))", text, re.IGNORECASE)
    if gen_date_match:
        result["generated_date"] = parse_date_flexible(gen_date_match.group(1))

    exp_date_match = re.search(r"Expires\s*:\s*([^\n\t\u2003]+?)(?=\s*(?:Egyptian|$|\n))", text, re.IGNORECASE)
    if exp_date_match:
        result["expiry_date"] = parse_date_flexible(exp_date_match.group(1))

    # Fallback for individual dates
    if not result["requested_date"]:
        m = re.search(r"تاريخ\s*الطلب\s*:\s*([^\n]+)", text)
        if m:
            result["requested_date"] = parse_date_flexible(m.group(1))

    if not result["expiry_date"]:
        m = re.search(r"تاريخ\s*الانتهاء\s*:\s*([^\n]+)", text)
        if m:
            result["expiry_date"] = parse_date_flexible(m.group(1))

    # 3. Egyptian Importer Details
    imp_name_match = re.search(r"Egyptian\s*Importer\s*Name\s*:\s*([^\n]+)", text, re.IGNORECASE)
    if not imp_name_match:
        imp_name_match = re.search(r"اسم\s*المستورد\s*:\s*([^\n]+)", text)
    if imp_name_match:
        result["importer_name"] = imp_name_match.group(1).strip()

    imp_tax_match = re.search(r"Egyptian\s*Importer\s*Tax\s*ID\s*:\s*([0-9\-\s]+)", text, re.IGNORECASE)
    if not imp_tax_match:
        imp_tax_match = re.search(r"الرقم\s*الضريبي\s*للمستورد\s*:\s*([0-9\-\s]+)", text)
    if imp_tax_match:
        result["importer_tax_id"] = imp_tax_match.group(1).strip()

    # Importer Address
    imp_sec_match = re.search(r"Egyptian\s*Importer\b(.*?)(?=Foreign\s*Exporter|Shipment|$)", text, re.DOTALL | re.IGNORECASE)
    if imp_sec_match:
        imp_sec_text = imp_sec_match.group(1)
        addr_match = re.search(r"Address\s*:\s*([^\n]+(?:\n[^\n:]+)*?)(?=\n\s*(?:Foreign|Shipment|Tel|$))", imp_sec_text, re.IGNORECASE)
        if addr_match:
            result["importer_address"] = " ".join(addr_match.group(1).split()).strip()

    # 4. Foreign Exporter Details
    exp_name_match = re.search(r"Foreign\s*Exporter\s*Name\s*:\s*([^\n]+)", text, re.IGNORECASE)
    if not exp_name_match:
        exp_name_match = re.search(r"Dear\s+([^,\n]+),", text, re.IGNORECASE)
    if exp_name_match:
        result["exporter_name"] = exp_name_match.group(1).strip()

    reg_type_match = re.search(r"Foreign\s*Exporter\s*Registration\s*Type\s*:\s*([^\n]+)|Registration\s*Type\s*:\s*([^\n]+)", text, re.IGNORECASE)
    if reg_type_match:
        result["exporter_reg_type"] = (reg_type_match.group(1) or reg_type_match.group(2)).strip()

    exp_id_match = re.search(r"Foreign\s*Exporter\s*ID\s*:\s*([A-Za-z0-9\-_]+)", text, re.IGNORECASE)
    if not exp_id_match:
        exp_id_match = re.search(r"(?<!AC)\bID\s*:\s*([A-Za-z0-9\-_]+)", text, re.IGNORECASE)
    if exp_id_match:
        result["exporter_reg_id"] = exp_id_match.group(1).strip()

    exp_country_match = re.search(r"(?:Foreign\s*Exporter\s*)?Country\s*:\s*([A-Za-z\s]+?)(?=\s*Country\s*Code|\n|$)", text, re.IGNORECASE)
    if exp_country_match:
        result["exporter_country"] = exp_country_match.group(1).strip()

    exp_code_match = re.search(r"(?:Foreign\s*Exporter\s*)?Country\s*Code\s*:\s*([A-Za-z0-9]+)", text, re.IGNORECASE)
    if exp_code_match:
        result["exporter_country_code"] = exp_code_match.group(1).strip().upper()

    exp_tel_match = re.search(r"Tel\.?\s*No\.?\s*:\s*([^\n]+)", text, re.IGNORECASE)
    if exp_tel_match:
        result["exporter_phone"] = exp_tel_match.group(1).strip()

    # Exporter Address
    exp_sec_match = re.search(r"Foreign\s*Exporter\b(.*?)(?=Shipment|Warning|Please\s*make\s*sure|$)", text, re.DOTALL | re.IGNORECASE)
    if exp_sec_match:
        exp_sec_text = exp_sec_match.group(1)
        addr_match = re.search(r"Address\s*:\s*([\s\S]+?)(?=\n\s*(?:Tel\.|Shipment|Warning|$))", exp_sec_text, re.IGNORECASE)
        if addr_match:
            result["exporter_address"] = " ".join(addr_match.group(1).split()).strip()

    # 5. Shipment & Invoice Details
    pi_no_match = re.search(r"Proforma\s*Invoice\s*No\.?\s*:\s*([^\n]+)", text, re.IGNORECASE)
    if not pi_no_match:
        pi_no_match = re.search(r"Invoice\s*No\.?\s*:\s*([^\n]+)", text, re.IGNORECASE)
    if pi_no_match:
        result["proforma_invoice_no"] = pi_no_match.group(1).strip()

    pi_date_match = re.search(r"Proforma\s*Invoice\s*Date\s*:\s*([^\n]+)", text, re.IGNORECASE)
    if pi_date_match:
        result["proforma_invoice_date"] = parse_date_flexible(pi_date_match.group(1))

    inv_date_match = re.search(r"(?<!Proforma\s)Invoice\s*Date\s*:\s*([^\n]+)", text, re.IGNORECASE)
    if inv_date_match:
        result["invoice_date"] = parse_date_flexible(inv_date_match.group(1))

    inv_type_match = re.search(r"Type\s*of\s*invoice\s*:\s*([^\n]+)", text, re.IGNORECASE)
    if inv_type_match:
        result["invoice_type"] = inv_type_match.group(1).strip()

    pol_match = re.search(r"Shipping\s*Port\s*:\s*([^\n]+)", text, re.IGNORECASE)
    if not pol_match:
        pol_match = re.search(r"Port\s*of\s*Loading\s*:\s*([^\n]+)", text, re.IGNORECASE)
    if pol_match:
        result["pol_name"] = pol_match.group(1).strip()

    pod_match = re.search(r"Destination\s*Port\s*:\s*([^\n]+)", text, re.IGNORECASE)
    if not pod_match:
        pod_match = re.search(r"Port\s*of\s*Discharge\s*:\s*([^\n]+)", text, re.IGNORECASE)
    if pod_match:
        result["pod_name"] = pod_match.group(1).strip()

    # 6. CargoX Exporter ID
    cargox_match = re.search(r"(?:registered\s*with\s*ID\s*:\s*|CargoX\s*ID\s*:\s*)([a-f0-9\-]+)", text, re.IGNORECASE)
    if cargox_match:
        result["cargox_id"] = cargox_match.group(1).strip()

    return result


def compare_acid_data(requested: Dict[str, Any], generated: Dict[str, Any]) -> Dict[str, Any]:
    """
    Compares what was requested against what was generated by MTS / Nafeza.
    Returns comparison matrix with field match indicators, severity, and overall match score.
    """
    comparison_fields = [
        {
            "field": "importer_name",
            "label_ar": "اسم الشركة المستوردة",
            "label_en": "Egyptian Importer Name",
            "severity": "error",
            "comparator": "fuzzy",
        },
        {
            "field": "importer_tax_id",
            "label_ar": "الرقم الضريبي للمستورد",
            "label_en": "Egyptian Importer Tax ID",
            "severity": "error",
            "comparator": "tax_id",
        },
        {
            "field": "exporter_name",
            "label_ar": "اسم المورد / المصدر الأجنبي",
            "label_en": "Foreign Exporter Name",
            "severity": "error",
            "comparator": "fuzzy",
        },
        {
            "field": "exporter_reg_type",
            "label_ar": "نوع تسجيل المصدر",
            "label_en": "Foreign Exporter Reg Type",
            "severity": "warning",
            "comparator": "exact",
        },
        {
            "field": "exporter_reg_id",
            "label_ar": "معرف / بطاقة المصدر الضريبية",
            "label_en": "Foreign Exporter ID",
            "severity": "error",
            "comparator": "exact",
        },
        {
            "field": "exporter_country",
            "label_ar": "دولة المصدر",
            "label_en": "Foreign Exporter Country",
            "severity": "warning",
            "comparator": "fuzzy",
        },
        {
            "field": "exporter_country_code",
            "label_ar": "كود دولة المصدر",
            "label_en": "Country Code",
            "severity": "warning",
            "comparator": "exact",
        },
        {
            "field": "proforma_invoice_no",
            "label_ar": "رقم الفاتورة المبدئية",
            "label_en": "Proforma Invoice No",
            "severity": "error",
            "comparator": "exact",
        },
        {
            "field": "pol_name",
            "label_ar": "ميناء الشحن (POL)",
            "label_en": "Shipping Port",
            "severity": "warning",
            "comparator": "port",
        },
        {
            "field": "pod_name",
            "label_ar": "ميناء الوصول والتفريغ (POD)",
            "label_en": "Destination Port",
            "severity": "warning",
            "comparator": "port",
        },
        {
            "field": "cargox_id",
            "label_ar": "معرف كارجو إكس (CargoX ID)",
            "label_en": "CargoX ID",
            "severity": "warning",
            "comparator": "exact",
        },
    ]

    discrepancies: List[Dict[str, Any]] = []
    total_fields = 0
    matched_fields = 0
    has_critical_error = False

    for item in comparison_fields:
        field_key = item["field"]
        req_val = str(requested.get(field_key) or "").strip()
        gen_val = str(generated.get(field_key) or "").strip()

        # If requested value is empty and generated is empty, skip
        if not req_val and not gen_val:
            continue

        total_fields += 1
        is_match = False

        if item["comparator"] == "tax_id":
            is_match = _clean_tax_id(req_val) == _clean_tax_id(gen_val)
        elif item["comparator"] == "exact":
            is_match = _normalize_string(req_val).lower() == _normalize_string(gen_val).lower()
        elif item["comparator"] == "port":
            # Ports can have variations like "Genoa" vs "Genoa Port (IT GOA)"
            norm_req = _normalize_string(req_val).lower()
            norm_gen = _normalize_string(gen_val).lower()
            is_match = (
                norm_req == norm_gen
                or (norm_req in norm_gen)
                or (norm_gen in norm_req)
            )
        else:  # fuzzy
            norm_req = _normalize_string(req_val).lower()
            norm_gen = _normalize_string(gen_val).lower()
            is_match = (
                norm_req == norm_gen
                or (norm_req in norm_gen)
                or (norm_gen in norm_req)
            )

        if is_match:
            matched_fields += 1
        else:
            if item["severity"] == "error":
                has_critical_error = True

        discrepancies.append({
            "field": field_key,
            "label_ar": item["label_ar"],
            "label_en": item["label_en"],
            "requested_value": req_val,
            "generated_value": gen_val,
            "is_matched": is_match,
            "severity": item["severity"],
        })

    match_percent = round((matched_fields / total_fields) * 100.0, 1) if total_fields > 0 else 100.0
    all_matched = (matched_fields == total_fields)

    return {
        "all_matched": all_matched,
        "has_critical_error": has_critical_error,
        "match_percentage": match_percent,
        "total_compared_fields": total_fields,
        "matched_count": matched_fields,
        "discrepant_count": total_fields - matched_fields,
        "items": discrepancies,
    }


def generate_whatsapp_request_text(req_data: Dict[str, Any]) -> str:
    """
    Generates a formatted, professional WhatsApp message ready to send to customs broker.
    """
    return (
        f"📋 *طلب استخراج رقم ACID جديد*\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"🏢 *المستورد المصري:* {req_data.get('importer_name', '-')}\n"
        f"🔢 *البطاقة الضريبية:* {req_data.get('importer_tax_id', '-')}\n"
        f"📍 *العنوان:* {req_data.get('importer_address', '-')}\n\n"
        f"🌍 *المصدر الأجنبي:* {req_data.get('exporter_name', '-')}\n"
        f"🆔 *المعرف الضريبي / نوعه:* {req_data.get('exporter_reg_id', '-')} ({req_data.get('exporter_reg_type', 'VAT Number')})\n"
        f"🌐 *الدولة والكود:* {req_data.get('exporter_country', '-')} ({req_data.get('exporter_country_code', '-')})\n"
        f"📍 *عنوان المصدر:* {req_data.get('exporter_address', '-')}\n"
        f"📞 *هاتف المصدر:* {req_data.get('exporter_phone', '-')}\n\n"
        f"📄 *رقم الفاتورة المبدئية:* {req_data.get('proforma_invoice_no', '-')}\n"
        f"📅 *تاريخ الفاتورة المبدئية:* {req_data.get('proforma_invoice_date', '-')}\n"
        f"📅 *تاريخ الفاتورة:* {req_data.get('invoice_date', '-')}\n"
        f"📑 *نوع الفاتورة:* {req_data.get('invoice_type', 'Proforma Invoice')}\n"
        f"📦 *أمر الشراء (PO):* {req_data.get('po_number', '-')}\n"
        f"📅 *تاريخ أمر الشراء:* {req_data.get('po_date', '-')}\n\n"
        f"🚢 *ميناء الشحن (POL):* {req_data.get('pol_name', '-')}\n"
        f"⚓ *ميناء الوصول (POD):* {req_data.get('pod_name', '-')}\n"
        f"📅 *تاريخ الطلب:* {req_data.get('requested_date', date.today().isoformat())}\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"⚠️ *ملاحظة:* يرجى مراجعة الفاتورة المبدئية المرفقة وسرعة موافاتنا برقم الـ ACID فور صدوره مع خالص الشكر."
    )


def generate_email_request_template(req_data: Dict[str, Any]) -> Dict[str, str]:
    """
    Generates structured Subject and Body for email dispatch to customs broker.
    """
    subject = f"طلب إصدار رقم ACID - شحنة {req_data.get('importer_name', 'Import')} - فاتورة {req_data.get('proforma_invoice_no', '')}"
    body = (
        f"السيد المخلص الجمركي المحترم / {req_data.get('customs_broker_name', 'مكتب التخليص الجمركي')}\n\n"
        f"تحية طيبة وبعد،،،\n\n"
        f"يرجى التكرم ببدء إجراءات طلب واستخراج رقم القيد الجمركي المبدئي (ACID) عبر منظومة نافذة للشحنة الموضحة بياناتها أدناه:\n\n"
        f"1. بيانات المستورد المصري:\n"
        f"   - اسم المستورد: {req_data.get('importer_name', '-')}\n"
        f"   - الرقم الضريبي: {req_data.get('importer_tax_id', '-')}\n"
        f"   - العنوان: {req_data.get('importer_address', '-')}\n\n"
        f"2. بيانات المصدر الأجنبي:\n"
        f"   - اسم المصدر: {req_data.get('exporter_name', '-')}\n"
        f"   - نوع التسجيل والمعرف: {req_data.get('exporter_reg_id', '-')} ({req_data.get('exporter_reg_type', 'VAT Number')})\n"
        f"   - الدولة والكود: {req_data.get('exporter_country', '-')} ({req_data.get('exporter_country_code', '-')})\n"
        f"   - عنوان المصدر: {req_data.get('exporter_address', '-')}\n"
        f"   - هاتف المصدر: {req_data.get('exporter_phone', '-')}\n\n"
        f"3. بيانات الفاتورة والشحن:\n"
        f"   - رقم الفاتورة المبدئية: {req_data.get('proforma_invoice_no', '-')}\n"
        f"   - تاريخ الفاتورة المبدئية: {req_data.get('proforma_invoice_date', '-')}\n"
        f"   - تاريخ الفاتورة: {req_data.get('invoice_date', '-')}\n"
        f"   - نوع الفاتورة: {req_data.get('invoice_type', 'Proforma Invoice')}\n"
        f"   - رقم أمر الشراء وتاريخه: {req_data.get('po_number', '-')} بتاريخ {req_data.get('po_date', '-')}\n"
        f"   - ميناء الشحن: {req_data.get('pol_name', '-')}\n"
        f"   - ميناء الوصول: {req_data.get('pod_name', '-')}\n\n"
        f"تجدون برفقه نسخة من الفاتورة المبدئية للاطلاع.\n"
        f"شاكرين لكم حسن تعاونكم الدائم.\n\n"
        f"قسم الاستيراد والتخليص الجمركي\n"
        f"ImportFlow ERP System"
    )
    return {"subject": subject, "body": body}
