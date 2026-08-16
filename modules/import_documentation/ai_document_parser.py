"""
AI Smart Document Parsing & Extraction Engine for Maritime Bills of Lading (Draft B/L)
Phase 6 / BP-016 Engine with LLM Schema Enforcement & Critical Safety Guardrails
"""

import os
import re
import json
import logging
import urllib.request
import urllib.error

logger = logging.getLogger(__name__)

# List of critical fields that MUST be validated before allowing automated comparisons
CRITICAL_DRAFT_BL_FIELDS = [
    ("booking_no", "رقم الحجز الملاحي (Booking Ref)"),
    ("consignee", "المستورد / المرسل إليه (Consignee)"),
    ("acid_number", "رقم القيد الجمركي المسبق (ACID Number)"),
    ("importer_tax_id", "البطاقة الضريبية للمستورد (Importer Tax ID)"),
    ("containers", "بيان وأرقام الحاويات (Container Numbers)"),
]

DRAFT_BL_JSON_SCHEMA = {
    "type": "object",
    "properties": {
        "draft_bl_number": {"type": "string", "description": "Bill of Lading number"},
        "booking_no": {"type": "string", "description": "Booking reference number"},
        "shipping_line": {"type": "string", "description": "Shipping line / carrier name (e.g., MSC, Maersk, CMA CGM, Hapag-Lloyd, GCS, Far East)"},
        "vessel_name": {"type": "string", "description": "Vessel name"},
        "voyage_number": {"type": "string", "description": "Voyage number"},
        "pol": {"type": "string", "description": "Port of loading"},
        "pod": {"type": "string", "description": "Port of discharge"},
        "place_of_delivery": {"type": "string", "description": "Final place of delivery"},
        "freight_terms": {"type": "string", "enum": ["Freight Prepaid", "Freight Collect"], "description": "Freight payment terms"},
        "shipper": {"type": "string", "description": "Shipper / Exporter full company name and address"},
        "consignee": {"type": "string", "description": "Consignee full name and address"},
        "notify_party": {"type": "string", "description": "Notify party name and address"},
        "acid_number": {"type": "string", "description": "Egyptian 19-digit ACID number"},
        "importer_tax_id": {"type": "string", "description": "Egyptian 9-digit Importer Tax ID"},
        "shipper_reg_type": {"type": "string", "description": "Shipper Registration Type (e.g. VAT NUMBER, TAX ID, BUSINESS REG)"},
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
        "package_type": {"type": "string", "description": "Package unit type (e.g. Pallets, Cartons, Boxes, Packages)"},
        "goods_description": {"type": "string", "description": "Commercial description of packages and cargo"},
        "total_gross_weight_kg": {"type": "number", "description": "Total gross weight in kilograms"},
        "total_net_weight_kg": {"type": "number", "description": "Total net weight in kilograms"},
        "cbm": {"type": "number", "description": "Total measurement in cubic meters (CBM)"},
    }
}


def extract_draft_bl_with_ai(raw_text: str) -> dict:
    """
    Extracts structured Bill of Lading data using AI LLM (Gemini / Anthropic / OpenAI)
    with strict JSON Schema enforcement. Falls back to multi-carrier heuristic parser.
    """
    if not raw_text or not raw_text.strip():
        return {}

    # Check for available AI APIs
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

    if not extracted:
        # Resilient multi-carrier heuristic extractor
        extracted = _heuristic_multi_carrier_extractor(raw_text)

    # Validate Safety & Confidence Guardrails
    guardrails = validate_extraction_safety_and_confidence(extracted)
    extracted["_guardrails"] = guardrails

    return extracted


def validate_extraction_safety_and_confidence(extracted_fields: dict) -> dict:
    """
    Safety Guardrail: Verifies that all critical shipping and customs fields were extracted.
    Halts automated silent approval if critical information is missing or uncertain.
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


def _call_gemini_api(raw_text: str, api_key: str) -> dict | None:
    try:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={api_key}"
        prompt = (
            "You are an expert maritime shipping documentation & customs parser for Egyptian and international trade.\n"
            "Analyze the following Draft Bill of Lading (B/L) text and extract all required structured fields in strictly valid JSON matching this schema:\n"
            f"{json.dumps(DRAFT_BL_JSON_SCHEMA, indent=2)}\n\n"
            "STRICT RULES:\n"
            "1. Output ONLY valid raw JSON with NO markdown formatting, NO backticks, and NO conversational text.\n"
            "2. Never hallucinate or invent data not present in the text.\n"
            "3. If a field is not present, set it to null.\n"
            "4. Extract ACID number (19 digits) and Importer Tax ID (9 digits) accurately.\n\n"
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
        logger.warning(f"Gemini API document extraction failed: {e}. Falling back to multi-carrier engine.")
        return None


def _call_anthropic_api(raw_text: str, api_key: str) -> dict | None:
    try:
        url = "https://api.anthropic.com/v1/messages"
        prompt = (
            "You are an expert maritime shipping document parser. "
            "Extract structured Bill of Lading fields matching this schema into valid JSON:\n"
            f"{json.dumps(DRAFT_BL_JSON_SCHEMA, indent=2)}\n\n"
            "Return JSON only.\n\n"
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
            # Clean possible markdown blocks
            if content.startswith("```"):
                content = re.sub(r'^```(?:json)?\n', '', content)
                content = re.sub(r'\n```$', '', content)
            return json.loads(content)
    except Exception as e:
        logger.warning(f"Anthropic API document extraction failed: {e}. Falling back.")
        return None


def _call_openai_api(raw_text: str, api_key: str) -> dict | None:
    try:
        url = "https://api.openai.com/v1/chat/completions"
        prompt = (
            "You are an expert maritime shipping document parser. "
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


def _heuristic_multi_carrier_extractor(raw_text: str) -> dict:
    """
    Advanced multi-carrier heuristic parser supporting MSC, CMA CGM, Maersk,
    Hapag-Lloyd, GCS, Far East Forwarding, Cosco, ONE, and generic freight forwarders.
    """
    parsed = {}
    
    # 1. ACID Number (19 digits)
    m_acid = re.search(r'(?:ACID|ACI\s+NO|ADVANCE\s+CARGO\s+INFO)[:\s#]+(\d{19})', raw_text, re.IGNORECASE)
    if m_acid:
        parsed["acid_number"] = m_acid.group(1).strip()
    
    # 2. Importer Tax ID (9 digits)
    m_tax = re.search(r'(?:EGYPTIAN\s+IMPORTER\s+TAX\s+ID|IMPORTER\s+TAX\s+ID|VAT\s+NO|TAX\s+REG)[:\s#]+(\d{9})', raw_text, re.IGNORECASE)
    if not m_tax:
        m_tax = re.search(r'(?:TAX\s+ID|VAT\s+ID)[:\s#]+(\d+)', raw_text, re.IGNORECASE)
    if m_tax:
        parsed["importer_tax_id"] = m_tax.group(1).strip()
    
    # 3. Shipper Registration
    m_reg_type = re.search(r'SHIPPER\s+REGISTRATION\s+TYPE[:\s]+([^\n\r]+)', raw_text, re.IGNORECASE)
    if m_reg_type:
        parsed["shipper_reg_type"] = m_reg_type.group(1).strip()
    m_shp_id = re.search(r'SHIPPER\s+ID[:\s]+([A-Z0-9]+)', raw_text, re.IGNORECASE)
    if m_shp_id:
        parsed["shipper_reg_id"] = m_shp_id.group(1).strip()
    m_country = re.search(r'SHIPPER\s+COUNTRY[:\s]+([^\n\r]+)', raw_text, re.IGNORECASE)
    if m_country:
        parsed["shipper_country"] = m_country.group(1).strip()
    m_code = re.search(r'SHIPPER\s+COUNTRY\s+CODE[:\s]+([A-Z]{2})', raw_text, re.IGNORECASE)
    if m_code:
        parsed["shipper_country_code"] = m_code.group(1).strip()

    # 4. Bill of Lading No & Booking No
    m_bl = re.search(r'(?:Bill\s+of\s+Lading\s+No\.?|B/L\s+No\.?|BILL\s+OF\s+LADING\s+No\.?|BL\s+NUMBER)[:\s]+([A-Z0-9/-]+)', raw_text, re.IGNORECASE)
    if m_bl:
        parsed["draft_bl_number"] = m_bl.group(1).strip()
    m_bkg = re.search(r'(?:Booking\s+No\.?|BOOKING\s+REF\.?|BOOKING\s+NUMBER|BKG\s+NO)[:\s]+([A-Z0-9/-]+)', raw_text, re.IGNORECASE)
    if m_bkg:
        parsed["booking_no"] = m_bkg.group(1).strip()
    
    # 5. Vessel & Voyage
    m_ves_voy = re.search(r'(?:VESSEL\s+AND\s+VOYAGE\s+NO|Ocean\s+Vessel\s+Voy\.No\.?|VESSEL/VOYAGE)[:\s]+([^\n\r]+)', raw_text, re.IGNORECASE)
    if m_ves_voy:
        full_vv = m_ves_voy.group(1).strip()
        if '/' in full_vv:
            v_p, voy_p = full_vv.split('/', 1)
            parsed["vessel_name"] = v_p.strip()
            parsed["voyage_number"] = voy_p.strip()
        elif '-' in full_vv:
            v_p, voy_p = full_vv.split('-', 1)
            parsed["vessel_name"] = v_p.strip()
            parsed["voyage_number"] = voy_p.strip()
        else:
            parsed["vessel_name"] = full_vv
    
    # 6. POL & POD & Delivery
    m_pol = re.search(r'(?:PORT\s+OF\s+LOADING|Port\s+of\s+Loading|POL)[:\s]+([^\n\r]+)', raw_text, re.IGNORECASE)
    if m_pol:
        parsed["pol"] = m_pol.group(1).strip()
    m_pod = re.search(r'(?:PORT\s+OF\s+DISCHARGE|Port\s+of\s+Discharge|POD)[:\s]+([^\n\r]+)', raw_text, re.IGNORECASE)
    if m_pod:
        parsed["pod"] = m_pod.group(1).strip()
    m_deliv = re.search(r'(?:PLACE\s+OF\s+DELIVERY|Place\s+of\s+Delivery|FINAL\s+DESTINATION)[:\s]+([^\n\r]+)', raw_text, re.IGNORECASE)
    if m_deliv:
        parsed["place_of_delivery"] = m_deliv.group(1).strip()

    # 7. Shipper, Consignee, Notify Party
    m_shp = re.search(r'(?:1\.Shipper|SHIPPER|EXPORTER|SHIPPER/EXPORTER)[:\s]+([^\n\r]+(?:\n[^\n\r]+){0,2})', raw_text, re.IGNORECASE)
    if m_shp:
        parsed["shipper"] = m_shp.group(1).strip()
    m_csg = re.search(r'(?:2\.Consignee|CONSIGNEE|CONSIGNED\s+TO|IMPORTER)[:\s]+([^\n\r]+(?:\n[^\n\r]+){0,2})', raw_text, re.IGNORECASE)
    if m_csg:
        parsed["consignee"] = m_csg.group(1).strip()
    m_not = re.search(r'(?:3\.Notify\s+party|NOTIFY\s+PARTIES|NOTIFY\s+PARTY|NOTIFY\s+ADDRESS)[:\s]+([^\n\r]+(?:\n[^\n\r]+){0,2})', raw_text, re.IGNORECASE)
    if m_not:
        parsed["notify_party"] = m_not.group(1).strip()

    # 8. Freight Terms
    if re.search(r'FREIGHT\s+PREPAID', raw_text, re.IGNORECASE):
        parsed["freight_terms"] = "Freight Prepaid"
    elif re.search(r'FREIGHT\s+COLLECT', raw_text, re.IGNORECASE):
        parsed["freight_terms"] = "Freight Collect"

    # 9. Weights & Volume
    m_gw = re.search(r'(?:Gross\s+Weight|Gross\s+Cargo\s+Weight|TOTAL\s+GROSS\s+WEIGHT)[^\d]*([\d,]+(?:\.\d+)?)', raw_text, re.IGNORECASE)
    if m_gw:
        parsed["total_gross_weight_kg"] = float(m_gw.group(1).replace(',', ''))
    m_cbm = re.search(r'(?:Measurement|CBM|TOTAL\s+VOLUME)[^\d]*([\d,]+(?:\.\d+)?)', raw_text, re.IGNORECASE)
    if m_cbm:
        parsed["cbm"] = float(m_cbm.group(1).replace(',', ''))
    m_pkg = re.search(r'(\d+)\s*(CARTONS|Pallet\(s\)|PALLETS|PACKAGES|BOXES|PCS|PKGS|UNITS)', raw_text, re.IGNORECASE)
    if m_pkg:
        parsed["qty_pkg"] = int(m_pkg.group(1))
        parsed["package_type"] = m_pkg.group(2)

    # 10. Goods Description
    m_desc = re.search(r'(?:Description\s+of\s+Packages\s+and\s+Goods|Description\s+of\s+Goods|COMMODITY)[:\s]+([^\n\r]+(?:\n[^\n\r]+){0,2})', raw_text, re.IGNORECASE)
    if m_desc:
        parsed["goods_description"] = m_desc.group(1).strip()

    # 11. Containers & Seals
    c_matches = re.findall(r'([A-Z]{4}\d{7})', raw_text)
    if c_matches:
        containers = []
        for c_no in set(c_matches):
            seal_val = ""
            m_sl = re.search(r'Seal\s+Number:?\s*([A-Z0-9]+)', raw_text, re.IGNORECASE)
            if m_sl:
                seal_val = m_sl.group(1)
            elif "/" in raw_text:
                m_slash = re.search(rf'{c_no}/([A-Z0-9]+)', raw_text)
                if m_slash:
                    seal_val = m_slash.group(1)
            
            containers.append({
                "container_no": c_no,
                "seal_no": seal_val,
                "size": "40' HIGH CUBE" if "40" in raw_text else "20' STANDARD",
                "gross_weight_kg": parsed.get("total_gross_weight_kg", 0.0)
            })
        parsed["containers"] = containers
        parsed["container_summary"] = ", ".join([f"{c['container_no']} ({c.get('seal_no','')})" for c in containers])

    return parsed
