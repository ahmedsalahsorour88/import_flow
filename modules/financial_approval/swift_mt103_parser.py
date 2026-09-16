"""
Smart SWIFT MT103 & Bank Transfer Advice Parser and Reconciliation Engine
(BP-012 / BP-013 / SWIFT-AI-EXTRACTOR)
"""

import re
from typing import Optional, Dict, Any, List
from datetime import datetime, date


KNOWN_SWIFT_LABELS_BLACKLIST = {
    "BENEFICIARYCUSTOMER", "BENEFICIARY", "BENEFICIARYNAME", "PAYEE",
    "ACCOUNTWITHBANK", "ACCOUNTWITH", "BANKSWIFT", "SWIFTCODE", "BIC",
    "ORDERINGCUST", "ORDERINGCUSTOMER", "APPLICANT", "SENDER", "REMITTER",
    "TRANSACTIONREFERENCENUMBER", "TRANSACTIONREF", "REFNUMBER", "TRN",
    "BANKOPERATIONCODE", "OPERATIONCODE",
    "VALUEDATECCYAMOUNT", "VALUEDATE", "CCY", "AMOUNT",
    "DETAILSOFPAYMENT", "PAYMENTDETAILS", "REMITTANCEINFORMATION",
    "DETAILSOFCHARGES", "CHARGES", "SENDERTORECEIVERINFORMATION",
}


def _is_label_not_value(val: Optional[str]) -> bool:
    """Returns True if the string is a SWIFT tag label rather than an actual field value."""
    if not val or not str(val).strip():
        return True
    clean = re.sub(r'[^A-Za-z0-9]', '', str(val)).upper()
    return clean in KNOWN_SWIFT_LABELS_BLACKLIST


def parse_swift_mt103_text(raw_text: str) -> Dict[str, Any]:
    """
    Parses raw SWIFT MT103 message text, bank transfer advices, and unstructured text
    and extracts all financial, beneficiary, ordering, and reference fields.
    """
    if not raw_text or not raw_text.strip():
        return {
            "success": False,
            "error": "Empty text provided",
        }

    # Automatically normalize OCR and fullwidth character artifacts
    from modules.financial_approval.swift_file_extractor import normalize_swift_ocr_text
    text = normalize_swift_ocr_text(raw_text.strip())

    # 1. Transaction Reference Number (Field :20)
    trans_ref = None
    ref_match = re.search(
        r'(?:^|[\r\n])\s*:?20(?:\s*[:/]|(?:/[^\n:]+)?[:/])\s*(?:\|\s*)?([^\r\n|]+)',
        text,
        re.IGNORECASE,
    )
    if ref_match:
        raw_val = ref_match.group(1).strip()
        parts = [p.strip() for p in raw_val.split('|') if p.strip()]
        trans_ref = parts[0] if parts else raw_val
    else:
        # Fallback for plain "Reference: FT/...", "TRN: ...", "رقم المرجع: ..."
        fb_ref = re.search(
            r'(?:Reference(?:\s+No|\s+Number)?|TRN|Ref\s*#?|Transaction\s+(?:Ref|Reference|Id)|Bank\s+Ref|رقم\s+(?:المرجع|المعاملة|الحوالة|العملية)|الرقم\s+المرجعي)\s*[:=-]?\s*([A-Za-z0-9/\-_.]+)',
            text,
            re.IGNORECASE,
        )
        if fb_ref:
            trans_ref = fb_ref.group(1).strip()
    if trans_ref:
        trans_ref = trans_ref.strip(' |:/')

    # 2. Bank Operation Code (Field :23B)
    bank_op_code = None
    op_match = re.search(
        r'(?:^|[\r\n])\s*:?23B(?:\s*[:/]|(?:/[^\n:]+)?[:/])\s*(?:\|\s*)?([A-Za-z0-9]+)',
        text,
        re.IGNORECASE,
    )
    if op_match:
        bank_op_code = op_match.group(1).strip()

    # 3. Value Date, Currency, Amount (Field :32A / :32B / SWIFT Standard)
    value_date_str = None
    value_date = None
    currency = "USD"
    amount = 0.0

    # A. Standard Tagged SWIFT 32A:
    # Matches :32A: 260818USD43704,00 or :32A/Value Date... : 260818USD43704,00
    val_match = re.search(
        r'(?:^|[\r\n])\s*:?32A(?:\s*[:/]|(?:/[^\n:]+)?[:/])\s*(?:\|\s*)?(\d{6})\s*([A-Za-z0-9]{3})\s*([0-9]+(?:[,.][0-9]+)?)',
        text,
        re.IGNORECASE,
    )

    # B. Untagged SWIFT 32A sequence (6 digits date + currency + amount):
    # e.g. 260818USD43704,00 or 260818 USD 43,704.00
    if not val_match:
        val_match = re.search(
            r'\b(\d{6})\s*([A-Za-z]{3}|U5D|E0R|E6P)\s*([0-9]+(?:[,.][0-9]+)?)\b',
            text,
            re.IGNORECASE,
        )

    if val_match:
        raw_date = val_match.group(1)  # YYMMDD e.g. 260818 -> 2026-08-18
        raw_curr = val_match.group(2).upper()
        if raw_curr in ["U5D", "U50", "US0", "U5O"]:
            currency = "USD"
        elif raw_curr in ["E0R", "EVR", "FUR", "EOR"]:
            currency = "EUR"
        elif raw_curr in ["E6P", "ECP"]:
            currency = "EGP"
        elif raw_curr in ["6BP"]:
            currency = "GBP"
        elif raw_curr in ["5AR"]:
            currency = "SAR"
        elif re.match(r'^[A-Z]{3}$', raw_curr):
            currency = raw_curr
        else:
            currency = "USD"

        raw_amount_str = val_match.group(3).strip()
        if ',' in raw_amount_str and '.' in raw_amount_str:
            if raw_amount_str.find(',') < raw_amount_str.find('.'):
                clean_amount = raw_amount_str.replace(',', '')
            else:
                clean_amount = raw_amount_str.replace('.', '').replace(',', '.')
            try:
                amount = float(clean_amount)
            except ValueError:
                amount = 0.0
        elif ',' in raw_amount_str:
            clean_amount = raw_amount_str.replace(',', '.')
            try:
                amount = float(clean_amount)
            except ValueError:
                amount = 0.0
        elif '.' in raw_amount_str:
            try:
                amount = float(raw_amount_str)
            except ValueError:
                amount = 0.0
        else:
            # Integer string without dot or comma
            # In SWIFT MT103 field 32A, decimals are standard (e.g. ,00).
            # If OCR stripped the comma e.g. 43704,00 -> 4370400:
            if len(raw_amount_str) > 4 and raw_amount_str.endswith('00'):
                try:
                    amount = float(raw_amount_str) / 100.0
                except ValueError:
                    amount = 0.0
            else:
                try:
                    amount = float(raw_amount_str)
                except ValueError:
                    amount = 0.0

        try:
            yy = int(raw_date[0:2])
            mm = int(raw_date[2:4])
            dd = int(raw_date[4:6])
            year = 2000 + yy if yy < 70 else 1900 + yy
            parsed_d = date(year, mm, dd)
            value_date = parsed_d.isoformat()
            value_date_str = parsed_d.strftime("%Y-%m-%d")
        except Exception:
            value_date = None
    else:
        # C. Field 32B (Currency + Amount without Date e.g. :32B: USD 43,704.00)
        val_32b = re.search(
            r'(?:^|[\r\n])\s*:?32B(?:\s*[:/]|(?:/[^\n:]+)?[:/])\s*(?:\|\s*)?([A-Za-z]{3})\s*([0-9]+(?:[,.][0-9]+)?)',
            text,
            re.IGNORECASE,
        )
        if val_32b:
            raw_curr = val_32b.group(1).upper()
            currency = raw_curr if re.match(r'^[A-Z]{3}$', raw_curr) else "USD"
            raw_amount_str = val_32b.group(2).strip()
            if ',' in raw_amount_str and '.' in raw_amount_str:
                clean_amount = raw_amount_str.replace(',', '') if raw_amount_str.find(',') < raw_amount_str.find('.') else raw_amount_str.replace('.', '').replace(',', '.')
            elif ',' in raw_amount_str:
                clean_amount = raw_amount_str.replace(',', '.')
            else:
                clean_amount = raw_amount_str
            try:
                amount = float(clean_amount)
            except ValueError:
                amount = 0.0
        else:
            # D. Fallback: Labeled or Unlabeled advice slips
            # Look for "Currency Amount" first (amount is AFTER currency!)
            curr_then_amt = re.search(
                r'\b(USD|EUR|EGP|GBP|CNY|SAR|AED|CHF|CAD|JPY|\$|€|£|¥)\s*([0-9]+(?:[,.][0-9]{2,3})+|[0-9]{3,})\b',
                text,
                re.IGNORECASE,
            )
            if curr_then_amt:
                raw_c, raw_a = curr_then_amt.groups()
                c_map = {"$": "USD", "€": "EUR", "£": "GBP", "¥": "CNY"}
                currency = c_map.get(raw_c, raw_c.upper())
                clean_a = raw_a.strip().rstrip('.')
                if ',' in clean_a and '.' in clean_a:
                    clean_a = clean_a.replace(',', '') if clean_a.find(',') < clean_a.find('.') else clean_a.replace('.', '').replace(',', '.')
                elif ',' in clean_a:
                    clean_a = clean_a.replace(',', '.')
                try:
                    amount = float(clean_a)
                except ValueError:
                    amount = 0.0
            else:
                # Look for "Amount Currency" (e.g. 43,704.00 USD) - ONLY if it has decimal or comma!
                amt_then_curr = re.search(
                    r'\b([0-9]+(?:[,.][0-9]{2,3})+)\s*(USD|EUR|EGP|GBP|CNY|SAR|AED|CHF|CAD|JPY|\$|€|£|¥)\b',
                    text,
                    re.IGNORECASE,
                )
                if amt_then_curr:
                    raw_a, raw_c = amt_then_curr.groups()
                    c_map = {"$": "USD", "€": "EUR", "£": "GBP", "¥": "CNY"}
                    currency = c_map.get(raw_c, raw_c.upper())
                    clean_a = raw_a.strip().rstrip('.')
                    if ',' in clean_a and '.' in clean_a:
                        clean_a = clean_a.replace(',', '') if clean_a.find(',') < clean_a.find('.') else clean_a.replace('.', '').replace(',', '.')
                    elif ',' in clean_a:
                        clean_a = clean_a.replace(',', '.')
                    try:
                        amount = float(clean_a)
                    except ValueError:
                        amount = 0.0

        # Fallback date lookup if not yet found
        if not value_date:
            date_match = re.search(
                r'\b(20\d{2}[-/.]\d{1,2}[-/.]\d{1,2}|\d{1,2}[-/.]\d{1,2}[-/.]20\d{2})\b',
                text,
            )
            if date_match:
                value_date_str = date_match.group(1)
                value_date = value_date_str

    # 4. Ordering Customer (Field :50K or :50A or Applicant)
    ordering_account = None
    ordering_customer_name = None
    ordering_address = None

    cust_match = re.search(
        r'(?:^|[\r\n])\s*:?50[KA]?(?:\s*[:/]|(?:/[^\n:]+)?[:/])\s*(?:\|\s*)?(.*?)(?=\s*:[0-9]{2}[A-Z]?|\s*-\}\s*|\Z)',
        text,
        re.DOTALL | re.IGNORECASE,
    )
    if cust_match:
        lines = [l.strip(' |') for l in cust_match.group(1).strip().splitlines() if l.strip(' |') and l.strip(' |') != '.']
        # Discard any leading lines that are labels (e.g. 'ORDERING CUST')
        clean_lines = [l for l in lines if not _is_label_not_value(l)]
        if clean_lines:
            if clean_lines[0].startswith('/'):
                ordering_account = clean_lines[0].lstrip('/')
                ordering_customer_name = clean_lines[1] if len(clean_lines) > 1 else None
                ordering_address = ', '.join(clean_lines[2:]) if len(clean_lines) > 2 else None
            else:
                ordering_customer_name = clean_lines[0]
                ordering_address = ', '.join(clean_lines[1:]) if len(clean_lines) > 1 else None
            if ordering_customer_name and ' | ' in ordering_customer_name:
                ordering_customer_name = ordering_customer_name.split(' | ')[0].strip()
    else:
        ord_gen = re.search(
            r'(?:Ordering\s+Customer|Applicant|Sender|Remitter|الآمر\s+بالتحويل|طالب\s+التحويل|الشركة\s+المستوردة|العميل)\s*[:=]\s*([^\r\n]+)',
            text,
            re.IGNORECASE,
        )
        if ord_gen:
            ordering_customer_name = ord_gen.group(1).strip()
    if ordering_customer_name and _is_label_not_value(ordering_customer_name):
        ordering_customer_name = None

    # 5. Account with Bank / SWIFT (Field :57A or Bank Name)
    beneficiary_bank_swift = None
    b_bank_match = re.search(
        r'(?:^|[\r\n])\s*:?57[AD]?(?:\s*[:/]|(?:/[^\n:]+)?[:/])\s*(?:\|\s*)?([A-Za-z0-9]{8,11})',
        text,
        re.IGNORECASE,
    )
    if b_bank_match:
        candidate_swift = b_bank_match.group(1).strip().upper()
        if not _is_label_not_value(candidate_swift):
            beneficiary_bank_swift = candidate_swift
    else:
        swift_gen = re.search(
            r'(?:SWIFT(?:\s+Code)?|BIC|Bank\s+SWIFT|كود\s+السويفت|سويفت)\s*[:=]?\s*([A-Za-z0-9]{8,11})',
            text,
            re.IGNORECASE,
        )
        if swift_gen:
            candidate_swift = swift_gen.group(1).strip().upper()
            if not _is_label_not_value(candidate_swift):
                beneficiary_bank_swift = candidate_swift

    # 6. Beneficiary Customer (Field :59 or :59A or Beneficiary Name)
    beneficiary_account = None
    beneficiary_name = None
    beneficiary_address = None

    ben_match = re.search(
        r'(?:^|[\r\n])\s*:?59[A]?(?:\s*[:/]|(?:/[^\n:]+)?[:/])\s*(?:\|\s*)?(.*?)(?=\s*:[0-9]{2}[A-Z]?|\s*-\}\s*|\Z)',
        text,
        re.DOTALL | re.IGNORECASE,
    )
    if ben_match:
        lines = [l.strip(' |') for l in ben_match.group(1).strip().splitlines() if l.strip(' |') and l.strip(' |') != '.']
        # Discard any leading lines that are labels (e.g. 'BeneficiaryCustomer', 'ACCOUNTWITHBANK')
        clean_lines = [l for l in lines if not _is_label_not_value(l)]
        if clean_lines:
            if clean_lines[0].startswith('/'):
                beneficiary_account = clean_lines[0].lstrip('/')
                beneficiary_name = clean_lines[1] if len(clean_lines) > 1 else None
                beneficiary_address = ', '.join(clean_lines[2:]) if len(clean_lines) > 2 else None
            else:
                beneficiary_name = clean_lines[0]
                beneficiary_address = ', '.join(clean_lines[1:]) if len(clean_lines) > 1 else None
            if beneficiary_name and ' | ' in beneficiary_name:
                beneficiary_name = beneficiary_name.split(' | ')[0].strip()
    else:
        ben_gen = re.search(
            r'(?:Beneficiary(?:\s+Customer|\s+Name)?|Payee|To\s+the\s+order\s+of|المستفيد|المورد|اسم\s+المستفيد|اسم\s+المورد)\s*[:=]\s*([^\r\n]+)',
            text,
            re.IGNORECASE,
        )
        if ben_gen:
            beneficiary_name = ben_gen.group(1).strip()

        iban_gen = re.search(
            r'(?:IBAN|Account(?:\s+No|\s+Number)?|رقم\s+(?:الحساب|الآيبان)|الآيبان)\s*[:=]?\s*([A-Za-z0-9]{8,34})',
            text,
            re.IGNORECASE,
        )
        if iban_gen:
            beneficiary_account = iban_gen.group(1).strip()

    if beneficiary_name and _is_label_not_value(beneficiary_name):
        beneficiary_name = None

    # 7. Details of Payment (Field :70 or Details)
    payment_details = None
    pi_number = None
    po_number = None

    details_match = re.search(
        r'(?:^|[\r\n])\s*:?70(?:\s*[:/]|(?:/[^\n:]+)?[:/])\s*(?:\|\s*)?(.*?)(?=\s*:[0-9]{2}[A-Z]?|\s*-\}\s*|\Z)',
        text,
        re.DOTALL | re.IGNORECASE,
    )
    if details_match:
        payment_details = details_match.group(1).strip()
        pi_match = re.search(r'(?:PI|Proforma\s+Invoice|فاتورة\s+مبدئية)\s*(?:NO\.?|#)?\s*([A-Za-z0-9\-_.]+)', payment_details, re.IGNORECASE)
        if pi_match:
            pi_number = pi_match.group(1).strip().rstrip('.')

        po_match = re.search(r'(?:PO|Purchase\s+Order|أمر\s+شراء)\s*(?:NO\.?|#)?\s*([A-Za-z0-9\-_.]+)', payment_details, re.IGNORECASE)
        if po_match:
            po_number = po_match.group(1).strip().rstrip('.')
        else:
            ref_code_match = re.search(r'\b(EG\d+|PO[-\d]+|IMP[-\d]+|\d{10})\b', payment_details, re.IGNORECASE)
            if ref_code_match:
                po_number = ref_code_match.group(1).strip()
    else:
        pi_match = re.search(r'(?:PI|Proforma\s+Invoice|فاتورة\s+مبدئية)\s*(?:NO\.?|#)?\s*([A-Za-z0-9\-_.]+)', text, re.IGNORECASE)
        if pi_match:
            pi_number = pi_match.group(1).strip().rstrip('.')
        po_match = re.search(r'(?:PO|Purchase\s+Order|أمر\s+شراء)\s*(?:NO\.?|#)?\s*([A-Za-z0-9\-_.]+)', text, re.IGNORECASE)
        if po_match:
            po_number = po_match.group(1).strip().rstrip('.')

    # 8. Details of Charges (Field :71A)
    charge_details = "SHA"
    charge_match = re.search(
        r'(?:^|[\r\n])\s*:?71A(?:\s*[:/]|(?:/[^\n:]+)?[:/])\s*(?:\|\s*)?([A-Za-z]{3})',
        text,
        re.IGNORECASE,
    )
    if charge_match:
        charge_details = charge_match.group(1).strip().upper()
    else:
        fb_charge = re.search(r'(?:^|[\r\n])\s*(?:DETAILS\s+OF\s+CHARGES|Charges)\s*[:=]?\s*([A-Za-z]{3})', text, re.IGNORECASE)
        if fb_charge:
            charge_details = fb_charge.group(1).strip().upper()

    # 9. Issuing / Sender Bank SWIFT from Header (Block 1)
    sender_bank_swift = None
    header_match = re.search(r'[\{\(]1:[A-Z0-9]{3}([A-Z0-9]{8,12})', raw_text)
    if header_match:
        sender_bank_swift = header_match.group(1)[:11]

    # 10. Receiver Bank SWIFT from Header (Block 2)
    receiver_bank_swift = None
    header2_match = re.search(r'[\{\(]2:[IO][0-9]{3}([A-Z0-9]{8,12})', raw_text)
    if header2_match:
        receiver_bank_swift = header2_match.group(1)[:11]

    # 11. Sender Bank Name resolution (e.g. AAIB from SWIFT BIC ARAIEGC... or payment details)
    sender_bank_name = None
    if sender_bank_swift and "ARAI" in sender_bank_swift:
        sender_bank_name = "Arab African International Bank (AAIB)"
    elif payment_details and "AAIB" in payment_details.upper():
        sender_bank_name = "Arab African International Bank (AAIB)"

    return {
        "success": True,
        "transaction_reference": trans_ref,
        "bank_operation_code": bank_op_code or "CRED",
        "value_date": value_date or value_date_str,
        "value_date_formatted": value_date_str,
        "currency": currency,
        "amount": amount,
        "ordering_customer_name": ordering_customer_name,
        "ordering_account_or_iban": ordering_account,
        "ordering_address": ordering_address,
        "beneficiary_name": beneficiary_name,
        "beneficiary_account_or_iban": beneficiary_account,
        "beneficiary_address": beneficiary_address,
        "beneficiary_bank_swift": beneficiary_bank_swift,
        "payment_details": payment_details,
        "pi_number": pi_number,
        "po_number": po_number,
        "charge_details": charge_details,
        "sender_bank_swift": sender_bank_swift,
        "receiver_bank_swift": receiver_bank_swift,
        "sender_bank_name": sender_bank_name,
        "raw_text_length": len(text),
    }


def extract_swift_fields_breakdown(raw_text: str) -> Dict[str, Any]:
    """
    Parses SWIFT MT103 text and produces a detailed list of independent field records
    with raw OCR snippet, individual confidence score, and validation status.
    """
    parsed = parse_swift_mt103_text(raw_text)

    def find_raw_snippet(pattern: str, fallback: str = "") -> str:
        m = re.search(pattern, raw_text, re.IGNORECASE | re.MULTILINE)
        if m:
            return m.group(0).strip()
        return fallback

    fields = [
        {
            "field_key": "amount",
            "swift_field_code": ":32A",
            "label_en": "Transferred Amount",
            "label_ar": "مبلغ التحويل الفعلي",
            "raw_ocr_text": find_raw_snippet(r'(?mi)^\s*:?(?:32A|[B8]2A|3ZA|BZA)[^\n]*\n?[^\n]*', str(parsed.get("amount", ""))),
            "parsed_value": str(parsed.get("amount", 0.0)) if parsed.get("amount") else "",
            "confidence_score": 0.98 if (parsed.get("amount") or 0.0) > 0.0 else 0.0,
            "is_mandatory": True,
        },
        {
            "field_key": "currency",
            "swift_field_code": ":32A",
            "label_en": "Currency",
            "label_ar": "عملة التحويل",
            "raw_ocr_text": find_raw_snippet(r'(?mi)\b(USD|EUR|EGP|GBP|SAR|CNY|U5D|E0R|E6P)\b', parsed.get("currency", "USD")),
            "parsed_value": parsed.get("currency", "USD"),
            "confidence_score": 0.98 if parsed.get("currency") in ["USD", "EUR", "EGP", "GBP", "SAR", "CNY"] else 0.50,
            "is_mandatory": True,
        },
        {
            "field_key": "value_date",
            "swift_field_code": ":32A",
            "label_en": "Value Date",
            "label_ar": "تاريخ الاستحقاق / التنفيذ",
            "raw_ocr_text": find_raw_snippet(r'(?mi)\b\d{6}\b|\b20\d{2}[-/.]\d{1,2}[-/.]\d{1,2}\b', parsed.get("value_date") or ""),
            "parsed_value": parsed.get("value_date") or "",
            "confidence_score": 0.95 if parsed.get("value_date") else 0.0,
            "is_mandatory": True,
        },
        {
            "field_key": "beneficiary_name",
            "swift_field_code": ":59",
            "label_en": "Beneficiary Customer",
            "label_ar": "اسم المستفيد / المورد",
            "raw_ocr_text": find_raw_snippet(r'(?mi)^\s*:?59[A]?[^\n]*\n(?:[^\n]+\n){1,3}[^\n]+', parsed.get("beneficiary_name") or ""),
            "parsed_value": parsed.get("beneficiary_name") or "",
            "confidence_score": 0.95 if parsed.get("beneficiary_name") else 0.0,
            "is_mandatory": True,
        },
        {
            "field_key": "beneficiary_account_or_iban",
            "swift_field_code": ":59",
            "label_en": "Beneficiary Account / IBAN",
            "label_ar": "رقم حساب / آيبان المستفيد",
            "raw_ocr_text": find_raw_snippet(r'/\s*[0-9]{8,34}|[0-9]{12,30}', parsed.get("beneficiary_account_or_iban") or ""),
            "parsed_value": parsed.get("beneficiary_account_or_iban") or "",
            "confidence_score": 0.95 if parsed.get("beneficiary_account_or_iban") else 0.0,
            "is_mandatory": True,
        },
        {
            "field_key": "transaction_reference",
            "swift_field_code": ":20",
            "label_en": "Transaction Reference Number",
            "label_ar": "الرقم المرجعي للعملية (TRN)",
            "raw_ocr_text": find_raw_snippet(r'(?mi)^\s*:?(?:20|[2Z][oO0])[^\n]*\n?[^\n]*', parsed.get("transaction_reference") or ""),
            "parsed_value": parsed.get("transaction_reference") or "",
            "confidence_score": 0.95 if parsed.get("transaction_reference") else 0.0,
            "is_mandatory": True,
        },
        {
            "field_key": "beneficiary_bank_swift",
            "swift_field_code": ":57A",
            "label_en": "Beneficiary Bank SWIFT (BIC)",
            "label_ar": "كود سويفت بنك المستفيد (BIC)",
            "raw_ocr_text": find_raw_snippet(r'(?mi)^\s*:?(?:57A|S7A)[^\n]*\n?[A-Z0-9]{8,11}', parsed.get("beneficiary_bank_swift") or ""),
            "parsed_value": parsed.get("beneficiary_bank_swift") or "",
            "confidence_score": 0.90 if parsed.get("beneficiary_bank_swift") else 0.0,
            "is_mandatory": False,
        },
        {
            "field_key": "ordering_customer_name",
            "swift_field_code": ":50K",
            "label_en": "Ordering Customer (Applicant)",
            "label_ar": "الآمر بالتحويل (المستورد)",
            "raw_ocr_text": find_raw_snippet(r'(?mi)^\s*:?(?:50K|[5S][oO0]K)[^\n]*\n(?:[^\n]+\n){1,2}[^\n]+', parsed.get("ordering_customer_name") or ""),
            "parsed_value": parsed.get("ordering_customer_name") or "",
            "confidence_score": 0.90 if parsed.get("ordering_customer_name") else 0.0,
            "is_mandatory": False,
        },
        {
            "field_key": "ordering_account_or_iban",
            "swift_field_code": ":50K",
            "label_en": "Ordering Account / IBAN",
            "label_ar": "حساب الآمر بالتحويل",
            "raw_ocr_text": find_raw_snippet(r'/EG[0-9]{20,30}|/EG[A-Z0-9]+', parsed.get("ordering_account_or_iban") or ""),
            "parsed_value": parsed.get("ordering_account_or_iban") or "",
            "confidence_score": 0.90 if parsed.get("ordering_account_or_iban") else 0.0,
            "is_mandatory": False,
        },
        {
            "field_key": "charge_details",
            "swift_field_code": ":71A",
            "label_en": "Bank Charges (71A)",
            "label_ar": "تفاصيل رسوم البنك (71A)",
            "raw_ocr_text": find_raw_snippet(r'(?mi)^\s*:?(?:71A|ZA)[^\n]*\n?[:\s]*([A-Za-z]{3})?', parsed.get("charge_details") or "SHA"),
            "parsed_value": parsed.get("charge_details") or "SHA",
            "confidence_score": 0.95 if parsed.get("charge_details") in ["SHA", "OUR", "BEN"] else 0.60,
            "is_mandatory": False,
        },
        {
            "field_key": "bank_operation_code",
            "swift_field_code": ":23B",
            "label_en": "Bank Operation Code",
            "label_ar": "كود العملية المصرفية",
            "raw_ocr_text": find_raw_snippet(r'(?mi)^\s*:?(?:23B|2BB)[^\n]*\n?[:\s]*[A-Za-z0-9]+', parsed.get("bank_operation_code") or "CRED"),
            "parsed_value": parsed.get("bank_operation_code") or "CRED",
            "confidence_score": 0.90 if parsed.get("bank_operation_code") else 0.70,
            "is_mandatory": False,
        },
        {
            "field_key": "sender_bank_swift",
            "swift_field_code": ":BLOCK1",
            "label_en": "Sender Bank SWIFT (BIC)",
            "label_ar": "كود سويفت البنك المرسل",
            "raw_ocr_text": find_raw_snippet(r'[\{\(]1:[A-Z0-9]{3}[A-Z0-9]{8,12}', parsed.get("sender_bank_swift") or ""),
            "parsed_value": parsed.get("sender_bank_swift") or "",
            "confidence_score": 0.90 if parsed.get("sender_bank_swift") else 0.0,
            "is_mandatory": False,
        },
        {
            "field_key": "receiver_bank_swift",
            "swift_field_code": ":BLOCK2",
            "label_en": "Receiver Bank SWIFT (BIC)",
            "label_ar": "كود سويفت بنك الاستقبال",
            "raw_ocr_text": find_raw_snippet(r'[\{\(]2:[IO][0-9]{3}[A-Z0-9]{8,12}', parsed.get("receiver_bank_swift") or ""),
            "parsed_value": parsed.get("receiver_bank_swift") or "",
            "confidence_score": 0.90 if parsed.get("receiver_bank_swift") else 0.0,
            "is_mandatory": False,
        },
        {
            "field_key": "pi_number",
            "swift_field_code": ":70",
            "label_en": "Proforma Invoice (PI)",
            "label_ar": "رقم الفاتورة المبدئية (PI)",
            "raw_ocr_text": find_raw_snippet(r'(?mi)(?:PI|Proforma\s+Invoice)\s*(?:NO\.?|#)?\s*[A-Za-z0-9\-_.]+', parsed.get("pi_number") or ""),
            "parsed_value": parsed.get("pi_number") or "",
            "confidence_score": 0.85 if parsed.get("pi_number") else 0.0,
            "is_mandatory": False,
        },
        {
            "field_key": "po_number",
            "swift_field_code": ":70",
            "label_en": "PO / File Reference",
            "label_ar": "رقم أمر الشراء / الملف",
            "raw_ocr_text": find_raw_snippet(r'(?mi)\b(EG\d+|PO[-\d]+|IMP[-\d]+)\b', parsed.get("po_number") or ""),
            "parsed_value": parsed.get("po_number") or "",
            "confidence_score": 0.85 if parsed.get("po_number") else 0.0,
            "is_mandatory": False,
        },
        {
            "field_key": "payment_details",
            "swift_field_code": ":70",
            "label_en": "Remittance Information",
            "label_ar": "تفاصيل وبيانات التحويل (:70)",
            "raw_ocr_text": find_raw_snippet(r'(?mi)^\s*:?(?:70|[7Z][oO0])[^\n]*\n(?:[^\n]+\n?){1,3}', parsed.get("payment_details") or ""),
            "parsed_value": parsed.get("payment_details") or "",
            "confidence_score": 0.85 if parsed.get("payment_details") else 0.0,
            "is_mandatory": False,
        },
    ]

    for f in fields:
        f["is_edited_by_user"] = False
        f["edited_value"] = None
        f["final_value"] = f["parsed_value"]

    return {
        "parsed_swift": parsed,
        "fields": fields,
    }


def match_swift_against_payment_request(parsed_swift: Dict[str, Any], payment_req: Any) -> Dict[str, Any]:
    """
    Compares parsed SWIFT MT103 data against a Payment Request model instance or dict.
    Returns matching scores, status, and variance analysis.
    """
    req_amount = getattr(payment_req, 'requested_amount', 0.0) or 0.0
    req_curr = (getattr(payment_req, 'currency_code', '') or 'USD').upper()
    req_supplier = (getattr(payment_req, 'beneficiary_name', '') or getattr(payment_req, 'supplier_name', '') or '').strip()
    req_swift = (getattr(payment_req, 'swift_code', '') or '').strip().upper()
    req_iban = (getattr(payment_req, 'iban_account_no', '') or '').strip().replace(' ', '')
    req_title = (getattr(payment_req, 'title', '') or '').strip()
    req_code = getattr(payment_req, 'payment_code', '')

    swift_amt = parsed_swift.get("amount", 0.0)
    swift_curr = (parsed_swift.get("currency", "") or "USD").upper()
    swift_ben = (parsed_swift.get("beneficiary_name", "") or "").strip()
    swift_swift = (parsed_swift.get("beneficiary_bank_swift", "") or "").strip().upper()
    swift_sender_swift = (parsed_swift.get("sender_bank_swift", "") or "").strip().upper()
    swift_sender_name = (parsed_swift.get("sender_bank_name", "") or "").strip()
    swift_iban = (parsed_swift.get("beneficiary_account_or_iban", "") or "").strip().replace(' ', '')
    swift_ref = parsed_swift.get("transaction_reference", "")
    swift_pi = parsed_swift.get("pi_number", "")

    # 1. Amount Match
    # Auto-recover OCR dropped decimal separator (e.g. 4370400 vs 43704.00)
    if req_amount > 0 and abs(swift_amt - req_amount * 100) < 0.01:
        swift_amt = req_amount
        parsed_swift["amount"] = req_amount

    amount_variance = swift_amt - req_amount
    is_amount_exact = abs(amount_variance) < 0.01
    is_currency_match = req_curr == swift_curr

    # 2. Supplier / Beneficiary Match
    # Fuzzy or substring match
    clean_req_sup = re.sub(r'[^a-zA-Z0-9]', '', req_supplier.lower())
    clean_swift_ben = re.sub(r'[^a-zA-Z0-9]', '', swift_ben.lower())
    is_beneficiary_match = False
    if clean_req_sup and clean_swift_ben:
        is_beneficiary_match = (clean_req_sup in clean_swift_ben) or (clean_swift_ben in clean_req_sup)

    # 3. SWIFT Code Match (Dual Check: Beneficiary Bank :57A vs Remitting/Sender Bank Block 1)
    is_swift_match = False
    matched_bank_type = None
    if req_swift and swift_swift and (req_swift[:8] == swift_swift[:8]):
        is_swift_match = True
        matched_bank_type = "BENEFICIARY_BANK"
    elif req_swift and swift_sender_swift and (req_swift[:8] == swift_sender_swift[:8]):
        is_swift_match = True
        matched_bank_type = "SENDER_BANK"

    # 4. IBAN / Account Match
    is_iban_match = False
    if req_iban and swift_iban:
        is_iban_match = (req_iban in swift_iban) or (swift_iban in req_iban)

    # 5. PI / Title Match
    is_pi_match = False
    if swift_pi:
        clean_pi = re.sub(r'[^a-zA-Z0-9]', '', swift_pi.lower())
        clean_title = re.sub(r'[^a-zA-Z0-9]', '', req_title.lower())
        is_pi_match = clean_pi in clean_title

    # Compute overall confidence score (0 to 100)
    score = 0
    if is_amount_exact and is_currency_match:
        score += 40
    elif abs(amount_variance) / max(req_amount, 1) < 0.05:
        score += 25

    if is_beneficiary_match:
        score += 25

    if is_iban_match:
        score += 15

    if is_swift_match:
        score += 10

    if is_pi_match:
        score += 10

    match_status = "PERFECT_MATCH" if score >= 85 and is_amount_exact else ("HIGH_MATCH" if score >= 60 else ("PARTIAL_MATCH" if score >= 35 else "LOW_MATCH"))

    return {
        "payment_id": getattr(payment_req, 'payment_id', None),
        "payment_code": req_code,
        "payment_title": req_title,
        "import_file_id": getattr(payment_req, 'import_file_id', None),
        "import_file_code": getattr(payment_req, 'import_file_code', None),
        "confidence_score": score,
        "match_status": match_status,
        "amount_matching": {
            "requested_amount": req_amount,
            "swift_amount": swift_amt,
            "currency": swift_curr,
            "variance": amount_variance,
            "is_matched": is_amount_exact and is_currency_match,
        },
        "beneficiary_matching": {
            "requested_beneficiary": req_supplier,
            "swift_beneficiary": swift_ben,
            "is_matched": is_beneficiary_match,
        },
        "bank_swift_matching": {
            "requested_swift": req_swift,
            "swift_code": swift_swift,
            "beneficiary_bank_swift": swift_swift,
            "sender_bank_swift": swift_sender_swift,
            "sender_bank_name": swift_sender_name,
            "matched_bank_type": matched_bank_type,
            "is_matched": is_swift_match,
        },
        "account_iban_matching": {
            "requested_iban": req_iban,
            "swift_iban": swift_iban,
            "is_matched": is_iban_match,
        },
        "pi_matching": {
            "swift_pi": swift_pi,
            "is_matched": is_pi_match,
        },
        "swift_reference_no": swift_ref,
        "value_date": parsed_swift.get("value_date"),
    }
