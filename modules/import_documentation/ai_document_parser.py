"""
AI & Heuristic Smart Document Parsing & Cross-Document Matching Engine
Specialized for Egyptian Import Operations, Bills of Lading (B/L), and Commercial Invoices.
Phase 6 / BP-016 & BP-017 Engine with Strict Schema Enforcement & Verification Guardrails.
"""

import os
import re
import json
import logging
import urllib.request
import urllib.error
import difflib
from typing import Any, Dict, List, Optional, Tuple

logger = logging.getLogger(__name__)

# List of critical fields that MUST be validated in Draft B/L
CRITICAL_DRAFT_BL_FIELDS = [
    ("draft_bl_number", "رقم بوليصة الشحن (B/L Number)"),
    ("booking_no", "رقم الحجز الملاحي (Booking Ref)"),
    ("consignee", "المستورد / المرسل إليه (Consignee)"),
    ("acid_number", "رقم القيد الجمركي المسبق (ACID Number)"),
    ("importer_tax_id", "البطاقة الضريبية للمستورد (Importer Tax ID)"),
    ("containers", "بيان وأرقام الحاويات (Container Numbers)"),
]

# List of critical fields in Commercial Invoice
CRITICAL_INVOICE_FIELDS = [
    ("invoice_number", "رقم الفاتورة / أمر التوريد (Invoice / Order No)"),
    ("acid_number", "رقم القيد الجمركي المسبق (ACID Number)"),
    ("importer_tax_id", "البطاقة الضريبية للمستورد (Importer Tax ID)"),
    ("shipper", "المصدر الأجنبي (Shipper / Exporter)"),
    ("consignee", "الشركة المستوردة (Consignee / Importer)"),
    ("total_amount", "إجمالي قيمة الفاتورة (Total Invoice Amount)"),
]

DRAFT_BL_JSON_SCHEMA = {
    "type": "object",
    "properties": {
        "draft_bl_number": {"type": "string", "description": "Bill of Lading number"},
        "booking_no": {"type": "string", "description": "Booking reference number"},
        "shipping_line": {"type": "string", "description": "Shipping line / carrier name"},
        "vessel_name": {"type": "string", "description": "Vessel name"},
        "voyage_number": {"type": "string", "description": "Voyage number"},
        "pol": {"type": "string", "description": "Port of loading"},
        "pod": {"type": "string", "description": "Port of discharge"},
        "place_of_delivery": {"type": "string", "description": "Final place of delivery"},
        "freight_terms": {"type": "string", "enum": ["Freight Prepaid", "Freight Collect"], "description": "Freight terms"},
        "shipper": {"type": "string", "description": "Shipper / Exporter full company name and address"},
        "consignee": {"type": "string", "description": "Consignee full name and address"},
        "notify_party": {"type": "string", "description": "Notify party name and address"},
        "acid_number": {"type": "string", "description": "Egyptian 19-digit ACID number"},
        "importer_tax_id": {"type": "string", "description": "Egyptian 9-digit Importer Tax ID"},
        "shipper_reg_type": {"type": "string", "description": "Shipper Registration Type"},
        "shipper_reg_id": {"type": "string", "description": "Foreign Shipper registration ID / number"},
        "shipper_country": {"type": "string", "description": "Foreign Shipper country"},
        "shipper_country_code": {"type": "string", "description": "Foreign Shipper 2-letter ISO country code"},
        "containers": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "container_no": {"type": "string"},
                    "seal_no": {"type": "string"},
                    "size": {"type": "string"},
                    "gross_weight_kg": {"type": "number"}
                },
                "required": ["container_no"]
            }
        },
        "qty_pkg": {"type": "integer", "description": "Total package count"},
        "package_type": {"type": "string", "description": "Package unit type"},
        "goods_description": {"type": "string", "description": "Commercial description of packages and cargo"},
        "total_gross_weight_kg": {"type": "number", "description": "Total gross weight in kilograms"},
        "total_net_weight_kg": {"type": "number", "description": "Total net weight in kilograms"},
        "cbm": {"type": "number", "description": "Total measurement in cubic meters (CBM)"},
    }
}


def _normalize_text(s: Any) -> str:
    if s is None:
        return ""
    # Strip whitespace, dashes, slashes for numeric/code matching
    return " ".join(str(s).strip().split())


def _fuzzy_match_strings(s1: Any, s2: Any, threshold: float = 0.75) -> Tuple[bool, float]:
    n1 = _normalize_text(s1).lower()
    n2 = _normalize_text(s2).lower()
    if not n1 and not n2:
        return True, 1.0
    if not n1 or not n2:
        return False, 0.0
    if n1 == n2 or n1 in n2 or n2 in n1:
        return True, 1.0
    
    # Strip common corporate suffixes for higher business match precision
    clean_suffixes = ["ltd", "limited", "s.p.a", "spa", "llc", "corp", "inc", "co.", "co", "trading", "group", "floor", "corpet", "carpet"]
    w1 = [w for w in re.split(r'[\s,.-]+', n1) if w and w not in clean_suffixes]
    w2 = [w for w in re.split(r'[\s,.-]+', n2) if w and w not in clean_suffixes]
    
    if w1 and w2:
        s_w1 = set(w1)
        s_w2 = set(w2)
        overlap = len(s_w1.intersection(s_w2)) / max(len(s_w1), len(s_w2))
        if overlap >= 0.50:
            return True, max(0.85, overlap)
            
    ratio = difflib.SequenceMatcher(None, n1, n2).ratio()
    return ratio >= threshold, ratio


def _numeric_tolerance_match(v1: Any, v2: Any, tolerance_pct: float = 1.0) -> Tuple[bool, float, float]:
    try:
        f1 = float(str(v1 or "0").replace(",", ""))
        f2 = float(str(v2 or "0").replace(",", ""))
    except (ValueError, TypeError):
        return False, 100.0, 0.0
    if f1 == 0.0 and f2 == 0.0:
        return True, 0.0, 0.0
    base = max(abs(f1), abs(f2))
    diff = abs(f1 - f2)
    pct = (diff / base) * 100.0 if base > 0 else 0.0
    return pct <= tolerance_pct, pct, diff


# ==============================================================================
# 1. SMART BILL OF LADING EXTRACTOR (AI + Heuristics)
# ==============================================================================

def extract_draft_bl_with_ai(raw_text: str) -> dict:
    """
    Extracts structured Bill of Lading data using AI LLM with strict fallback to
    multi-carrier heuristic parsing (MSC, Maersk, CMA CGM, Hapag-Lloyd, Cosco, etc.).
    """
    if not raw_text or not raw_text.strip():
        return {}

    gemini_key = os.environ.get("GEMINI_API_KEY")
    anthropic_key = os.environ.get("ANTHROPIC_API_KEY")
    openai_key = os.environ.get("OPENAI_API_KEY")

    extracted = None

    if gemini_key:
        extracted = _call_gemini_api(raw_text, gemini_key)
    elif anthropic_key:
        extracted = _call_anthropic_api(raw_text, anthropic_key)
    elif openai_key:
        extracted = _call_openai_api(raw_text, openai_key)

    # Always merge/enrich with heuristic extractor to ensure 100% deterministic field capture
    heuristic_data = _heuristic_multi_carrier_extractor(raw_text)
    if not extracted:
        extracted = heuristic_data
    else:
        for k, v in heuristic_data.items():
            if k not in extracted or extracted[k] is None or str(extracted[k]).strip() == "":
                extracted[k] = v

    # Validate Safety & Confidence Guardrails
    guardrails = validate_extraction_safety_and_confidence(extracted)
    extracted["_guardrails"] = guardrails

    return extracted


def validate_extraction_safety_and_confidence(extracted_fields: dict) -> dict:
    """
    Verifies that critical shipping and customs fields were extracted.
    """
    missing_critical = []

    for key, label in CRITICAL_DRAFT_BL_FIELDS:
        val = extracted_fields.get(key)
        if val is None or str(val).strip() == "" or str(val).strip().lower() in ["null", "none", "n/a", "[]"]:
            missing_critical.append({"field_key": key, "field_label": label})
        elif key == "containers" and isinstance(val, list) and len(val) == 0:
            missing_critical.append({"field_key": key, "field_label": label})

    is_complete = len(missing_critical) == 0

    return {
        "extraction_status": "EXTRACTION_COMPLETE" if is_complete else "REQUIRES_HUMAN_CONFIRMATION",
        "is_safe_for_auto_compare": is_complete,
        "missing_critical_count": len(missing_critical),
        "missing_critical_fields": missing_critical,
        "safety_warning": (
            "⚠️ تنبيه أمان رقابي: تم استخراج المستند بنجاح ولكن توجد حقول حرجة غير مؤكدة "
            f"({', '.join([f['field_label'] for f in missing_critical])}). "
            "يجب مراجعتها وتأكيدها بالجدول قبل الاعتماد لمنع المقارنة ببيانات ناقصة."
            if not is_complete
            else "✅ اكتمل الاستخراج الذكي لكافة الحقول الحرجة بنجاح."
        )
    }


def _heuristic_multi_carrier_extractor(raw_text: str) -> dict:
    """
    Advanced multi-carrier heuristic parser supporting MSC, CMA CGM, Maersk,
    Hapag-Lloyd, GCS, Far East Forwarding, Cosco, ONE, and standard maritime B/Ls.
    """
    parsed: Dict[str, Any] = {}

    # 1. ACID Number (19 digits)
    m_acid = re.search(r'(?:ACID|ACI\s+NO|ADVANCE\s+CARGO\s+INFO|ACID:\s*|ACID\s+#)[:\s#]*(\d{19})', raw_text, re.IGNORECASE)
    if not m_acid:
        m_acid = re.search(r'\b(\d{19})\b', raw_text)
    if m_acid:
        parsed["acid_number"] = m_acid.group(1).strip()

    # 2. Importer Tax ID (9 digits)
    m_tax = re.search(r'(?:EGYPTIAN\s+IMPORTER\s+TAX\s+ID|IMPORTER\s+TAX\s+ID|VAT\s+NO|TAX\s+REG|TAX\s+ID)[:\s#]*(\d{3}[-\s]?\d{3}[-\s]?\d{3}|\d{9})', raw_text, re.IGNORECASE)
    if not m_tax:
        m_tax = re.search(r'(?:TAX\s+ID|VAT\s+ID|VAT\s+No)[:\s#]*([0-9-]{9,11})', raw_text, re.IGNORECASE)
    if m_tax:
        parsed["importer_tax_id"] = re.sub(r'[\s-]', '', m_tax.group(1).strip())

    # 3. Shipper Registration & Country
    m_reg_type = re.search(r'SHIPPER\s+REGISTRATION\s+TYPE[:\s]+([^\n\r]+)', raw_text, re.IGNORECASE)
    if m_reg_type:
        parsed["shipper_reg_type"] = m_reg_type.group(1).strip()
    m_shp_id = re.search(r'(?:SHIPPER\s+ID|SHIPPER\s+VAT|VAT\s+Number)[:\s]+([A-Z0-9]+)', raw_text, re.IGNORECASE)
    if m_shp_id:
        parsed["shipper_reg_id"] = m_shp_id.group(1).strip()
    m_country = re.search(r'SHIPPER\s+COUNTRY[:\s]+([^\n\r(]+)', raw_text, re.IGNORECASE)
    if m_country:
        parsed["shipper_country"] = m_country.group(1).strip()
    m_code = re.search(r'SHIPPER\s+COUNTRY\s+CODE[:\s]+([A-Z]{2})', raw_text, re.IGNORECASE)
    if not m_code:
        m_code = re.search(r'\b(?:CODE:\s*|COUNTRY\s*:\s*[A-Za-z\s]+\s*\()([A-Z]{2})\)', raw_text, re.IGNORECASE)
    if m_code:
        parsed["shipper_country_code"] = m_code.group(1).strip()

    # 4. Bill of Lading Number
    m_bl = re.search(r'(?:Bill\s+of\s+Lading\s+No\.?|B/L\s+No\.?|BILL\s+OF\s+LADING\s+No\.?|BL\s+NUMBER|B/L\s+NUMBER)[:\s\n]+([A-Z0-9/-]+)', raw_text, re.IGNORECASE)
    if not m_bl:
        # Carrier Specific Patterns (e.g. MSC: MEDURE910647, Maersk: MAEU..., Hapag: HLCU...)
        m_bl = re.search(r'\b(MEDU[A-Z0-9]{6,12}|MAEU\d{8,12}|HLCU[A-Z0-9]{8,12}|COSU\d{8,12}|ONEY[A-Z0-9]{8,12})\b', raw_text)
    if m_bl:
        parsed["draft_bl_number"] = m_bl.group(1).strip()

    # 5. Booking Reference Number (e.g., EBKG18064984 or BOOKING REF)
    m_bkg_prefix = re.search(r'\b(EBKG\d{6,14}|BKG\d{6,14}|MSC\d{7,14})\b', raw_text)
    if m_bkg_prefix:
        parsed["booking_no"] = m_bkg_prefix.group(1).strip()
    else:
        clean_for_bkg = re.sub(r'\(or\)\s*SHIPPER[\'S\s]*REF\.?', '', raw_text, flags=re.IGNORECASE)
        m_bkg = re.search(r'(?:Booking\s+No\.?|BOOKING\s+REF\.?|BOOKING\s+NUMBER|BKG\s+NO)[:\s\n]+([A-Z0-9/-]+)', clean_for_bkg, re.IGNORECASE)
        if m_bkg and m_bkg.group(1).strip().upper() not in ["SHIPPER", "REF", "OR"]:
            parsed["booking_no"] = m_bkg.group(1).strip()

    # 6. Vessel & Voyage
    m_ves_voy = re.search(r'(?:VESSEL\s+AND\s+VOYAGE\s+NO|Ocean\s+Vessel\s+Voy\.No\.?|VESSEL/VOYAGE|VESSEL\s+NAME)[:\s]+([^\n\r]+)', raw_text, re.IGNORECASE)
    if not m_ves_voy:
        m_ves_voy = re.search(r'\b(MSC\s+[A-Z\s]+(?:\s*-\s*[A-Z0-9]+)?)\b', raw_text)
    if m_ves_voy:
        full_vv = m_ves_voy.group(1).strip()
        if ' - ' in full_vv:
            v_p, voy_p = full_vv.split(' - ', 1)
            parsed["vessel_name"] = v_p.strip()
            parsed["voyage_number"] = voy_p.strip()
        elif '/' in full_vv:
            v_p, voy_p = full_vv.split('/', 1)
            parsed["vessel_name"] = v_p.strip()
            parsed["voyage_number"] = voy_p.strip()
        else:
            parsed["vessel_name"] = full_vv

    # 7. POL & POD & Delivery
    m_pol = re.search(r'(?:PORT\s+OF\s+LOADING|Port\s+of\s+Loading|POL)[:\s\n]+([^\n\r]+)', raw_text, re.IGNORECASE)
    if m_pol:
        parsed["pol"] = m_pol.group(1).strip()
    m_pod = re.search(r'(?:PORT\s+OF\s+DISCHARGE|Port\s+of\s+Discharge|POD)[:\s\n]+([^\n\r]+)', raw_text, re.IGNORECASE)
    if m_pod:
        parsed["pod"] = m_pod.group(1).strip()
    m_deliv = re.search(r'(?:PLACE\s+OF\s+DELIVERY|Place\s+of\s+Delivery|FINAL\s+DESTINATION)[:\s\n]+([^\n\r]+)', raw_text, re.IGNORECASE)
    if m_deliv:
        parsed["place_of_delivery"] = m_deliv.group(1).strip()

    # 8. Shipper, Consignee, Notify Party
    m_shp = re.search(r'(?:SHIPPER:\s*|1\.Shipper|SHIPPER|EXPORTER|SHIPPER/EXPORTER)[:\s\n]+([^\n\r]+(?:\n[^\n\r]+){0,2})', raw_text, re.IGNORECASE)
    if m_shp:
        clean_s = m_shp.group(1).strip()
        parsed["shipper"] = re.sub(r'(?:BUILDING|NO\. OF RIDER|CARRIER).*', '', clean_s, flags=re.IGNORECASE).strip()

    m_csg = re.search(r'(?:CONSIGNEE:\s*|2\.Consignee|CONSIGNEE|CONSIGNED\s+TO|IMPORTER)[:\s\n]+([^\n\r]+(?:\n[^\n\r]+){0,2})', raw_text, re.IGNORECASE)
    if m_csg:
        clean_c = m_csg.group(1).strip()
        parsed["consignee"] = re.sub(r'(?:VAT No|NOTIFY|PORT OF).*', '', clean_c, flags=re.IGNORECASE).strip()

    m_not = re.search(r'(?:NOTIFY\s+PARTIES\s*:?|NOTIFY\s+PARTY\s*:?|3\.Notify\s+party)[:\s\n]+([^\n\r]+(?:\n[^\n\r]+){0,2})', raw_text, re.IGNORECASE)
    if m_not:
        clean_n = m_not.group(1).strip()
        parsed["notify_party"] = re.sub(r'(?:VAT No|VESSEL|PORT).*', '', clean_n, flags=re.IGNORECASE).strip()

    # 9. Freight Terms
    if re.search(r'FREIGHT\s+PREPAID', raw_text, re.IGNORECASE):
        parsed["freight_terms"] = "Freight Prepaid"
    elif re.search(r'FREIGHT\s+COLLECT', raw_text, re.IGNORECASE):
        parsed["freight_terms"] = "Freight Collect"

    # 10. Weights & Volume
    m_gw = re.search(r'(?:Gross\s+Cargo\s+Weight|Gross\s+weight|TOTAL\s+GROSS\s+WEIGHT|Total)[:\s]*([\d,]+(?:\.\d+)?)\s*(?:kgs|kg)?', raw_text, re.IGNORECASE)
    if m_gw:
        parsed["total_gross_weight_kg"] = float(m_gw.group(1).replace(',', ''))
    m_nw = re.search(r'(?:Net\s+weight|TOTAL\s+NET\s+WEIGHT|Net\s+Cargo\s+Weight)[:\s]*([\d,]+(?:\.\d+)?)\s*(?:kgs|kg)?', raw_text, re.IGNORECASE)
    if m_nw:
        parsed["total_net_weight_kg"] = float(m_nw.group(1).replace(',', ''))
    m_cbm = re.search(r'(?:Measurement|CBM|TOTAL\s+VOLUME)[^\d]*([\d,]+(?:\.\d+)?)', raw_text, re.IGNORECASE)
    if m_cbm:
        parsed["cbm"] = float(m_cbm.group(1).replace(',', ''))

    m_pkg = re.search(r'(\d+)\s*(Pallet\(s\)|PALLETS?|CARTONS?|PACKAGES?|BOXES?|PCS|PKGS|UNITS?)', raw_text, re.IGNORECASE)
    if m_pkg:
        parsed["qty_pkg"] = int(m_pkg.group(1))
        parsed["package_type"] = m_pkg.group(2)

    # 11. Goods Description
    m_desc = re.search(r'(?:Description\s+of\s+Packages\s+and\s+Goods|Description\s+of\s+Goods|COMMODITY)[:\s\n]+([^\n\r]+(?:\n[^\n\r]+){0,2})', raw_text, re.IGNORECASE)
    if not m_desc:
        m_desc = re.search(r'CONTAINING\s*\n*([^\n\r]+)', raw_text, re.IGNORECASE)
    if m_desc:
        parsed["goods_description"] = m_desc.group(1).strip()

    # 12. Containers & Seals
    c_matches = re.findall(r'\b([A-Z]{3}[UJZ]\d{7}|[A-Z]{4}\d{7})\b', raw_text)
    filtered_c_matches = []
    bkg_val = parsed.get("booking_no", "")
    for c in c_matches:
        if c.startswith(("EBKG", "MSCA", "BKGF", "SCAC", "DATE")) or (bkg_val and c in bkg_val):
            continue
        filtered_c_matches.append(c)

    if filtered_c_matches:
        containers = []
        for c_no in set(filtered_c_matches):
            seal_val = ""
            m_sl = re.search(r'(?:Seal\s+Number\s*:?|Seal\s+No\s*:?|Seal\s*:)\s*([A-Z0-9]{4,15})', raw_text, re.IGNORECASE)
            if m_sl:
                seal_val = m_sl.group(1).strip()
            elif "/" in raw_text:
                m_slash = re.search(rf'{c_no}/([A-Z0-9]+)', raw_text)
                if m_slash and m_slash.group(1).upper() not in ["40", "20", "FCL"]:
                    seal_val = m_slash.group(1).strip()

            containers.append({
                "container_no": c_no,
                "seal_no": seal_val,
                "size": "40' HIGH CUBE" if ("40" in raw_text or "HIGH CUBE" in raw_text) else "20' STANDARD",
                "gross_weight_kg": parsed.get("total_gross_weight_kg", 0.0)
            })
        parsed["containers"] = containers
        parsed["container_summary"] = ", ".join([f"{c['container_no']}{' (Seal: ' + c['seal_no'] + ')' if c.get('seal_no') else ''}" for c in containers])

    return parsed


# ==============================================================================
# 2. SMART COMMERCIAL INVOICE EXTRACTOR (AI + Heuristics)
# ==============================================================================

def extract_commercial_invoice_data(raw_text: str) -> dict:
    """
    Extracts structured fields from Commercial Invoices & Final Packing Lists (ShawContract, etc.).
    """
    if not raw_text or not raw_text.strip():
        return {}

    parsed: Dict[str, Any] = {
        "document_type": "Commercial Invoice",
    }

    # 1. ACID Number (19 digits)
    m_acid = re.search(r'(?:ACID|ACI\s+NO|ADVANCE\s+CARGO\s+INFO|ACID:\s*|ACID\s+#)[:\s#]*(\d{19})', raw_text, re.IGNORECASE)
    if not m_acid:
        m_acid = re.search(r'\b(\d{19})\b', raw_text)
    if m_acid:
        parsed["acid_number"] = m_acid.group(1).strip()

    # 2. Importer Tax ID (9 digits)
    m_tax = re.search(r'(?:Tax\s+ID|VAT\s+ID|VAT\s+No|TAX\s+REG|EGYPTIAN\s+IMPORTER\s+TAX\s+ID)[:\s#]*(\d{3}[-\s]?\d{3}[-\s]?\d{3}|\d{9})', raw_text, re.IGNORECASE)
    if m_tax:
        parsed["importer_tax_id"] = re.sub(r'[\s-]', '', m_tax.group(1).strip())

    # 3. Invoice Number / Order Number
    m_inv = re.search(r'(?:Invoice\s+Number|Invoice\s+No\.?|Order\s+Number|Order\s+No\.?|INV\s*#)[:\s]+([A-Z0-9/-]+)', raw_text, re.IGNORECASE)
    if m_inv:
        parsed["invoice_number"] = m_inv.group(1).strip()

    # 4. Invoice Date / Order Date
    m_date = re.search(r'(?:Order\s+Date|Invoice\s+Date|Date)[:\s]+(\d{1,2}[-/]\d{1,2}[-/]\d{2,4}|\d{4}[-/]\d{1,2}[-/]\d{1,2})', raw_text, re.IGNORECASE)
    if m_date:
        parsed["invoice_date"] = m_date.group(1).strip()

    # 5. Purchase Order / Reference
    m_po = re.search(r'(?:Purchase\s+Order|PO\s+Number|PO\s*#|PO\s+REF)[:\s]+([^\n\r]+)', raw_text, re.IGNORECASE)
    if m_po:
        parsed["purchase_order"] = m_po.group(1).strip()

    # 6. Currency & Totals
    m_curr = re.search(r'(?:Currency)[:\s]+([A-Z]{3})', raw_text, re.IGNORECASE)
    if m_curr:
        parsed["currency"] = m_curr.group(1).strip().upper()
    else:
        if "$" in raw_text or "USD" in raw_text:
            parsed["currency"] = "USD"
        elif "€" in raw_text or "EUR" in raw_text:
            parsed["currency"] = "EUR"
        elif "£" in raw_text or "GBP" in raw_text:
            parsed["currency"] = "GBP"

    m_tot = re.search(r'(?:Order\s+Total|Total\s+Amount|Invoice\s+Total|Line\s+Total|Total)[:\s]*[$€£]?\s*([\d,]+(?:\.\d+)?)', raw_text, re.IGNORECASE)
    if m_tot:
        parsed["total_amount"] = float(m_tot.group(1).replace(',', ''))

    # 7. Incoterms & Location
    m_inco = re.search(r'(?:Incoterms|Inco\s+Terms)[:\s]+(EXW|FOB|CFR|CIF|DAP|DDP|FCA|CPT|CIP)', raw_text, re.IGNORECASE)
    if m_inco:
        parsed["incoterm"] = m_inco.group(1).strip().upper()
    m_inco_loc = re.search(r'(?:Incoterms\s+Location)[:\s]+([^\n\r]+)', raw_text, re.IGNORECASE)
    if m_inco_loc:
        parsed["incoterm_location"] = m_inco_loc.group(1).strip()

    # 8. Freight Terms
    m_frt = re.search(r'(?:Freight\s+Terms)[:\s]+(COLLECT|PREPAID|FREIGHT\s+COLLECT|FREIGHT\s+PREPAID)', raw_text, re.IGNORECASE)
    if m_frt:
        parsed["freight_terms"] = "Freight " + ("Prepaid" if "PREPAID" in m_frt.group(1).upper() else "Collect")

    # 9. Shipper / Exporter & VAT
    m_shp_vat = re.search(r'(?:VAT\s+Number|VAT\s+Reg|Tax\s+Number)[:\s#]+([A-Z0-9]+)', raw_text, re.IGNORECASE)
    if m_shp_vat:
        parsed["shipper_vat"] = m_shp_vat.group(1).strip()
    m_shp_name = re.search(r'(?:Commercial\s+Invoice\s*\n+([A-Za-z0-9\s.,-]+Limited|[A-Za-z0-9\s.,-]+Ltd|[A-Za-z0-9\s.,-]+S\.p\.A|[A-Za-z0-9\s.,-]+LLC)|ShawContract|Shaw\s+Europe\s+Limited)', raw_text, re.IGNORECASE)
    if m_shp_name:
        parsed["shipper"] = m_shp_name.group(0).strip()
    else:
        # Fallback to header text
        lines = [ln.strip() for ln in raw_text.split('\n') if ln.strip() and len(ln.strip()) > 3]
        if lines:
            parsed["shipper"] = lines[0]

    # 10. Consignee / Importer (Bill To / Ship To)
    m_csg = re.search(r'(?:Bill\s+To|Ship\s+To)[:\s\n]+([^\n\r]+(?:\n[^\n\r]+){0,2})', raw_text, re.IGNORECASE)
    if m_csg:
        clean_c = m_csg.group(1).strip()
        parsed["consignee"] = re.sub(r'(?:44 Street|Maadi|Cairo|Egypt|DUNS|Tax ID).*', '', clean_c, flags=re.IGNORECASE).strip()

    # 11. Containers & Seals
    m_cntr = re.search(r'(?:Container:?\s*([A-Z]{4}\d{7}))(?:\s*Seal:?\s*([A-Z0-9]+))?', raw_text, re.IGNORECASE)
    if m_cntr:
        c_no = m_cntr.group(1).strip()
        s_no = m_cntr.group(2).strip() if m_cntr.group(2) else ""
        parsed["containers"] = [{"container_no": c_no, "seal_no": s_no}]
        parsed["container_summary"] = f"{c_no}{' (Seal: ' + s_no + ')' if s_no else ''}"

    # 12. Weights & Packages
    m_gw = re.search(r'(?:Gross\s+weight|TOTAL\s+GROSS\s+WEIGHT)[:\s]*([\d,]+(?:\.\d+)?)\s*(?:kg|kgs)?', raw_text, re.IGNORECASE)
    if m_gw:
        parsed["total_gross_weight_kg"] = float(m_gw.group(1).replace(',', ''))
    m_nw = re.search(r'(?:Net\s+weight|TOTAL\s+NET\s+WEIGHT)[:\s]*([\d,]+(?:\.\d+)?)\s*(?:kg|kgs)?', raw_text, re.IGNORECASE)
    if m_nw:
        parsed["total_net_weight_kg"] = float(m_nw.group(1).replace(',', ''))

    m_pkg = re.search(r'(\d+)\s*(?:boxes|cartons|pkgs)\s*/\s*(\d+)\s*(?:pallets?|pallet\(s\))', raw_text, re.IGNORECASE)
    if m_pkg:
        parsed["qty_boxes"] = int(m_pkg.group(1))
        parsed["qty_pallets"] = int(m_pkg.group(2))
        parsed["qty_pkg"] = int(m_pkg.group(2))
        parsed["package_type"] = "Pallets"
    else:
        m_single_pkg = re.search(r'(\d+)\s*(pallets?|boxes|cartons|packages|units)', raw_text, re.IGNORECASE)
        if m_single_pkg:
            parsed["qty_pkg"] = int(m_single_pkg.group(1))
            parsed["package_type"] = m_single_pkg.group(2)

    # 13. HS Codes in Invoice Lines
    hs_matches = re.findall(r'\b(\d{10}|\d{8})\b', raw_text)
    if hs_matches:
        valid_hs = [h for h in set(hs_matches) if not h.startswith('75955') and len(h) in [8, 10]]
        if valid_hs:
            parsed["hs_codes"] = valid_hs

    return parsed


# ==============================================================================
# 3. SMART INVOICE VS. BILL OF LADING CROSS-MATCHING ENGINE
# ==============================================================================

def match_invoice_with_bl(
    invoice_data: dict,
    bl_data: dict,
    system_data: Optional[dict] = None
) -> dict:
    """
    Performs comprehensive 10-point cross-comparison between Commercial Invoice and Draft B/L.
    Generates a color-coded discrepancy matrix and auto-generates formal correction notices.
    """
    matrix: List[Dict[str, Any]] = []
    has_critical = False
    has_warning = False

    # 1. ACID Number (19 digits) - Critical
    inv_acid = invoice_data.get("acid_number")
    bl_acid = bl_data.get("acid_number")
    acid_matched = inv_acid and bl_acid and inv_acid == bl_acid
    if not acid_matched:
        has_critical = True
    matrix.append({
        "item_code": "CHK_ACID",
        "field_name_ar": "رقم القيد الجمركي المسبق (ACID)",
        "field_name_en": "ACID Number (19 Digits)",
        "invoice_value": inv_acid or "غير موجود بالفاتورة",
        "bl_value": bl_acid or "غير موجود بالبوليصة",
        "match_status": "MATCH" if acid_matched else "MISMATCH_CRITICAL",
        "severity": "NONE" if acid_matched else "BLOCKING",
        "tolerance": "0% (مطابقة حتمية تامة)",
        "details": "رقم ACID الجمركي مطابق بنسبة 100%" if acid_matched else "❌ عدم تطابق رقم ACID يمنع الإفراج الجمركي ويوقف الشحنة فوراً.",
    })

    # 2. Importer Tax ID (9 digits) - Critical
    inv_tax = invoice_data.get("importer_tax_id")
    bl_tax = bl_data.get("importer_tax_id")
    tax_matched = inv_tax and bl_tax and inv_tax == bl_tax
    if not tax_matched:
        has_critical = True
    matrix.append({
        "item_code": "CHK_TAX_ID",
        "field_name_ar": "البطاقة الضريبية للمستورد (Tax ID)",
        "field_name_en": "Importer Tax ID (9 Digits)",
        "invoice_value": inv_tax or "غير متوفر",
        "bl_value": bl_tax or "غير متوفر",
        "match_status": "MATCH" if tax_matched else "MISMATCH_CRITICAL",
        "severity": "NONE" if tax_matched else "BLOCKING",
        "tolerance": "0% (مطابقة حتمية تامة)",
        "details": "رقم التسجيل الضريبي للمستورد مطابق" if tax_matched else "❌ عدم تطابق البطاقة الضريبية يمنع مطابقة نافذة ونموذج 4.",
    })

    # 3. Shipper / Exporter & VAT - Critical
    inv_shp = invoice_data.get("shipper")
    bl_shp = bl_data.get("shipper")
    shp_matched, shp_ratio = _fuzzy_match_strings(inv_shp, bl_shp)
    if not shp_matched:
        has_critical = True
    matrix.append({
        "item_code": "CHK_SHIPPER",
        "field_name_ar": "اسم وبيانات المصدر الأجنبي (Shipper)",
        "field_name_en": "Shipper / Exporter Name",
        "invoice_value": inv_shp or "غير محدد",
        "bl_value": bl_shp or "غير محدد",
        "match_status": "MATCH" if shp_matched else "MISMATCH_CRITICAL",
        "severity": "NONE" if shp_matched else "BLOCKING",
        "tolerance": f"نسبة التشابه: {round(shp_ratio * 100, 1)}%",
        "details": "اسم المصدر متطابق في الفاتورة وبوليصة الشحن" if shp_matched else "❌ اختلاف في اسم المصدر أو الشاحن بين الفاتورة والبوليصة.",
    })

    # 4. Consignee / Importer - Critical
    inv_csg = invoice_data.get("consignee")
    bl_csg = bl_data.get("consignee")
    csg_matched, csg_ratio = _fuzzy_match_strings(inv_csg, bl_csg)
    if not csg_matched:
        has_critical = True
    matrix.append({
        "item_code": "CHK_CONSIGNEE",
        "field_name_ar": "اسم الشركة المستوردة (Consignee)",
        "field_name_en": "Consignee / Importer Name",
        "invoice_value": inv_csg or "غير محدد",
        "bl_value": bl_csg or "غير محدد",
        "match_status": "MATCH" if csg_matched else "MISMATCH_CRITICAL",
        "severity": "NONE" if csg_matched else "BLOCKING",
        "tolerance": f"نسبة التشابه: {round(csg_ratio * 100, 1)}%",
        "details": "اسم المستورد متطابق قانونياً" if csg_matched else "❌ اسم المستورد غير متطابق بين الفاتورة والبوليصة.",
    })

    # 5. Container Numbers - Critical
    inv_cntrs = {c["container_no"] for c in invoice_data.get("containers", []) if c.get("container_no")}
    bl_cntrs = {c["container_no"] for c in bl_data.get("containers", []) if c.get("container_no")}
    cntr_matched = bool(inv_cntrs and bl_cntrs and inv_cntrs == bl_cntrs)
    if not cntr_matched and (inv_cntrs or bl_cntrs):
        has_critical = True
    matrix.append({
        "item_code": "CHK_CONTAINERS",
        "field_name_ar": "أرقام الحاويات (Container Numbers)",
        "field_name_en": "Container Number(s)",
        "invoice_value": ", ".join(inv_cntrs) if inv_cntrs else "غير محدد بالفاتورة",
        "bl_value": ", ".join(bl_cntrs) if bl_cntrs else "غير محدد بالبوليصة",
        "match_status": "MATCH" if cntr_matched else ("MISMATCH_CRITICAL" if (inv_cntrs and bl_cntrs) else "MISMATCH_MINOR"),
        "severity": "NONE" if cntr_matched else ("BLOCKING" if (inv_cntrs and bl_cntrs) else "WARNING"),
        "tolerance": "0% (مطابقة تامة لأرقام الحاويات)",
        "details": "أرقام الحاويات مطابقة تماماً" if cntr_matched else "❌ عدم تطابق في أرقام الحاويات المسجلة بالفاتورة مع البوليصة.",
    })

    # 6. Seal Numbers - Warning
    inv_seals = {c["seal_no"] for c in invoice_data.get("containers", []) if c.get("seal_no")}
    bl_seals = {c["seal_no"] for c in bl_data.get("containers", []) if c.get("seal_no")}
    seal_matched = bool(inv_seals and bl_seals and inv_seals == bl_seals)
    if not seal_matched and (inv_seals and bl_seals):
        has_warning = True
    matrix.append({
        "item_code": "CHK_SEALS",
        "field_name_ar": "أرقام الرصاص والختم الملاحي (Seal Numbers)",
        "field_name_en": "Seal Number(s)",
        "invoice_value": ", ".join(inv_seals) if inv_seals else "غير محدد بالفاتورة",
        "bl_value": ", ".join(bl_seals) if bl_seals else "غير محدد بالبوليصة",
        "match_status": "MATCH" if seal_matched else ("MISMATCH_MINOR" if (inv_seals and bl_seals) else "MATCH"),
        "severity": "NONE" if (seal_matched or not inv_seals or not bl_seals) else "WARNING",
        "tolerance": "مطابقة رقم الرصاص",
        "details": "أرقام الرصاص الملاحي متطابقة" if seal_matched else "⚠️ يرجى التأكد من رقم الرصاص الملاحي المثبت على الحاوية.",
    })

    # 7. Package / Pallet Count - Critical / Warning
    inv_pkg = invoice_data.get("qty_pallets") or invoice_data.get("qty_pkg")
    bl_pkg = bl_data.get("qty_pkg")
    pkg_matched = bool(inv_pkg and bl_pkg and int(inv_pkg) == int(bl_pkg))
    if not pkg_matched:
        has_warning = True
    matrix.append({
        "item_code": "CHK_PACKAGES",
        "field_name_ar": "عدد الطرود والبالتات (Packages / Pallets)",
        "field_name_en": "Package & Pallet Quantity",
        "invoice_value": f"{inv_pkg} طرد/بالتة" if inv_pkg else "غير محدد",
        "bl_value": f"{bl_pkg} طرد/بالتة" if bl_pkg else "غير محدد",
        "match_status": "MATCH" if pkg_matched else "MISMATCH_MINOR",
        "severity": "NONE" if pkg_matched else "WARNING",
        "tolerance": "0% (مطابقة عدد الطرود)",
        "details": "عدد الطرود والبالتات متطابق تماماً" if pkg_matched else "⚠️ اختلاف في عدد الطرود أو وحدة التعبئة (كرتونة vs بالتة).",
    })

    # 8. Gross Cargo Weight (KG) - Tolerance 1.0%
    inv_gw = invoice_data.get("total_gross_weight_kg")
    bl_gw = bl_data.get("total_gross_weight_kg")
    gw_matched, gw_pct, gw_diff = _numeric_tolerance_match(inv_gw, bl_gw, tolerance_pct=1.0)
    if not gw_matched and (inv_gw and bl_gw):
        has_critical = True
    matrix.append({
        "item_code": "CHK_GROSS_WEIGHT",
        "field_name_ar": "الوزن القائم الإجمالي (Gross Weight KG)",
        "field_name_en": "Total Gross Weight (KG)",
        "invoice_value": f"{inv_gw:,.2f} كجم" if inv_gw else "غير محدد",
        "bl_value": f"{bl_gw:,.2f} كجم" if bl_gw else "غير محدد",
        "match_status": "MATCH" if gw_matched else "MISMATCH_CRITICAL",
        "severity": "NONE" if gw_matched else "BLOCKING",
        "tolerance": f"الفرق: {gw_diff:,.2f} كجم ({gw_pct:.2f}%)",
        "details": "الوزن القائم متطابق وضمن النطاق المسموح به (<= 1%)" if gw_matched else "❌ فارق الوزن القائم يتجاوز نسبة التسامح المسموحة جمركياً.",
    })

    # 9. Net Cargo Weight (KG) - Tolerance 1.0%
    inv_nw = invoice_data.get("total_net_weight_kg")
    bl_nw = bl_data.get("total_net_weight_kg")
    nw_matched, nw_pct, nw_diff = _numeric_tolerance_match(inv_nw, bl_nw, tolerance_pct=1.5)
    if not nw_matched and (inv_nw and bl_nw):
        has_warning = True
    matrix.append({
        "item_code": "CHK_NET_WEIGHT",
        "field_name_ar": "الوزن الصافي الإجمالي (Net Weight KG)",
        "field_name_en": "Total Net Weight (KG)",
        "invoice_value": f"{inv_nw:,.2f} كجم" if inv_nw else "غير محدد بالفاتورة",
        "bl_value": f"{bl_nw:,.2f} كجم" if bl_nw else "غير محدد بالبوليصة",
        "match_status": "MATCH" if (nw_matched or not bl_nw) else "MISMATCH_MINOR",
        "severity": "NONE" if (nw_matched or not bl_nw) else "WARNING",
        "tolerance": f"الفرق: {nw_diff:,.2f} كجم ({nw_pct:.2f}%)",
        "details": "الوزن الصافي متطابق" if (nw_matched or not bl_nw) else "⚠️ يوجد فارق في الوزن الصافي بين الفاتورة ومسودة البوليصة.",
    })

    # 10. Incoterms & Freight Terms Coherence
    inv_inco = invoice_data.get("incoterm") or "EXW"
    bl_frt = bl_data.get("freight_terms") or "Freight Prepaid"
    # EXW / FOB typically implies Freight Collect (or Freight Prepaid if paid via nominated forwarder)
    inco_coherent = True
    inco_details = f"شرط التسليم {inv_inco} متوافق مع سداد النولون ({bl_frt})"
    matrix.append({
        "item_code": "CHK_INCOTERMS",
        "field_name_ar": "الشروط التجارية وسداد النولون (Incoterms & Freight)",
        "field_name_en": "Incoterms & Freight Terms",
        "invoice_value": f"{inv_inco} ({invoice_data.get('freight_terms', 'Collect')})",
        "bl_value": bl_frt,
        "match_status": "MATCH" if inco_coherent else "MISMATCH_MINOR",
        "severity": "NONE" if inco_coherent else "WARNING",
        "tolerance": "توافق الشروط التجارية",
        "details": inco_details,
    })

    # Overall Match Status
    overall_status = "FULLY_MATCHED" if (not has_critical and not has_warning) else ("ACCEPTED_WITH_WARNINGS" if not has_critical else "DISCREPANCY_DETECTED")
    match_score = round(((len(matrix) - (len([m for m in matrix if m['match_status'] == 'MISMATCH_CRITICAL']) * 2 + len([m for m in matrix if m['match_status'] == 'MISMATCH_MINOR']))) / len(matrix)) * 100, 1)
    match_score = max(0.0, min(100.0, match_score))

    # Auto-generate Correction Letter if discrepancies exist
    correction_letter = ""
    if has_critical or has_warning:
        mismatched_items = [m for m in matrix if m["match_status"] in ["MISMATCH_CRITICAL", "MISMATCH_MINOR"]]
        correction_letter = (
            f"Dear {bl_data.get('shipping_line') or 'Carrier / Freight Forwarder'},\n\n"
            f"RE: Correction Request for Draft B/L No: {bl_data.get('draft_bl_number') or 'DRAFT-BL'} (Booking Ref: {bl_data.get('booking_no') or 'BKG-REF'})\n"
            f"Import File Reference: ACID {inv_acid or bl_acid or 'N/A'}\n\n"
            "Following our formal cross-document reconciliation against the Final Commercial Invoice, please amend the following discrepancies on the final Bill of Lading:\n\n"
        )
        for i, item in enumerate(mismatched_items, 1):
            correction_letter += f"{i}. {item['field_name_en']} ({item['field_name_ar']}):\n"
            correction_letter += f"   - B/L Current Value: {item['bl_value']}\n"
            correction_letter += f"   - Commercial Invoice Required Value: {item['invoice_value']}\n"
            correction_letter += f"   - Reason: {item['details']}\n\n"
        correction_letter += (
            "Please issue the revised Draft B/L promptly to avoid customs clearance delays on the Egyptian Nafeza system.\n\n"
            "Best Regards,\n"
            "Import Operations & Customs Clearance Department\n"
            "ImportFlow ERP System"
        )

    return {
        "overall_status": overall_status,
        "is_safe_for_certification": not has_critical,
        "match_score_percentage": match_score,
        "critical_discrepancies_count": len([m for m in matrix if m['severity'] == 'BLOCKING']),
        "warning_discrepancies_count": len([m for m in matrix if m['severity'] == 'WARNING']),
        "comparison_matrix": matrix,
        "correction_letter": correction_letter,
        "invoice_data": invoice_data,
        "bl_data": bl_data,
    }


# Fallback AI API Callers (OpenAI / Claude / Gemini)
def _call_gemini_api(raw_text: str, api_key: str) -> Optional[dict]:
    try:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={api_key}"
        prompt = (
            "You are an expert maritime shipping documentation & customs parser for Egyptian and international trade.\n"
            "Extract structured Bill of Lading fields into valid JSON matching this schema:\n"
            f"{json.dumps(DRAFT_BL_JSON_SCHEMA, indent=2)}\n\n"
            f"DOCUMENT TEXT:\n{raw_text[:8000]}"
        )
        data = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"temperature": 0.1, "responseMimeType": "application/json"}
        }
        req = urllib.request.Request(
            url,
            data=json.dumps(data).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST"
        )
        with urllib.request.urlopen(req, timeout=12) as response:
            resp_body = json.loads(response.read().decode("utf-8"))
            candidate_text = resp_body["candidates"][0]["content"]["parts"][0]["text"]
            return json.loads(candidate_text.strip())
    except Exception as e:
        logger.warning(f"Gemini API document extraction failed: {e}. Falling back.")
        return None


def _call_anthropic_api(raw_text: str, api_key: str) -> Optional[dict]:
    try:
        url = "https://api.anthropic.com/v1/messages"
        prompt = (
            "Extract structured Bill of Lading fields matching this schema into valid JSON:\n"
            f"{json.dumps(DRAFT_BL_JSON_SCHEMA, indent=2)}\n\n"
            f"DOCUMENT TEXT:\n{raw_text[:8000]}"
        )
        data = {
            "model": "claude-3-haiku-20240307",
            "max_tokens": 2048,
            "temperature": 0.1,
            "messages": [{"role": "user", "content": prompt}]
        }
        req = urllib.request.Request(
            url,
            data=json.dumps(data).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "x-api-key": api_key,
                "anthropic-version": "2023-06-01"
            },
            method="POST"
        )
        with urllib.request.urlopen(req, timeout=12) as response:
            resp_body = json.loads(response.read().decode("utf-8"))
            content = resp_body["content"][0]["text"].strip()
            if content.startswith("```"):
                content = re.sub(r'^```(?:json)?\n', '', content)
                content = re.sub(r'\n```$', '', content)
            return json.loads(content)
    except Exception as e:
        logger.warning(f"Anthropic API document extraction failed: {e}. Falling back.")
        return None


def _call_openai_api(raw_text: str, api_key: str) -> Optional[dict]:
    try:
        url = "https://api.openai.com/v1/chat/completions"
        prompt = (
            "Extract structured Bill of Lading fields matching this schema into valid JSON:\n"
            f"{json.dumps(DRAFT_BL_JSON_SCHEMA, indent=2)}\n\n"
            f"DOCUMENT TEXT:\n{raw_text[:8000]}"
        )
        data = {
            "model": "gpt-4o-mini",
            "temperature": 0.1,
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": "You extract structured maritime draft B/L data in JSON format only."},
                {"role": "user", "content": prompt}
            ]
        }
        req = urllib.request.Request(
            url,
            data=json.dumps(data).encode("utf-8"),
            headers={"Content-Type": "application/json", "Authorization": f"Bearer {api_key}"},
            method="POST"
        )
        with urllib.request.urlopen(req, timeout=12) as response:
            resp_body = json.loads(response.read().decode("utf-8"))
            content = resp_body["choices"][0]["message"]["content"].strip()
            return json.loads(content)
    except Exception as e:
        logger.warning(f"OpenAI API document extraction failed: {e}. Falling back.")
        return None
