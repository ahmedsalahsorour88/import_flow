"""
Smart SWIFT MT103 & Bank Transfer Advice Parser and Reconciliation Engine
(BP-012 / BP-013 / SWIFT-AI-EXTRACTOR)
"""

import re
from typing import Optional, Dict, Any, List
from datetime import datetime, date


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

    text = raw_text.strip()

    # 1. Transaction Reference Number (Field :20)
    trans_ref = None
    ref_match = re.search(
        r'(?:^|[\r\n])\s*:?20(?:/TRANSACTION\s+REFERENCE(?:\s+NUMBER)?)?\s*[:/]?\s*([^\r\n]+)',
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
        r'(?:^|[\r\n])\s*:?23B(?:/BANK\s+OPERATION\s+CODE)?\s*[:/]?\s*([A-Za-z0-9]+)',
        text,
        re.IGNORECASE,
    )
    if op_match:
        bank_op_code = op_match.group(1).strip()

    # 3. Value Date, Currency, Amount (Field :32A / General)
    value_date_str = None
    value_date = None
    currency = "USD"
    amount = 0.0

    val_match = re.search(
        r'(?:^|[\r\n])\s*:?32A(?:/Value\s+Date,?\s*CCY,?\s*Amount)?\s*[:/]?\s*(\d{6})([A-Z]{3})([0-9.,]+)',
        text,
        re.IGNORECASE,
    )
    if val_match:
        raw_date = val_match.group(1) # YYMMDD e.g. 260818 -> 2026-08-18
        currency = val_match.group(2).upper()
        raw_amount = val_match.group(3).replace(',', '.')
        try:
            amount = float(raw_amount)
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
        # Currency + Amount fallback patterns
        # 1. Primary: Labeled Amount (Amount: USD 43,704.00 or المبلغ: 50,000.00 USD)
        labeled_amt = re.search(
            r'(?:Amount|Value|Sum|Total(?:\s+Amount)?|المبلغ|القيمة|الصافي|إجمالي\s+المبلغ)\s*[:=]?\s*(?:([A-Za-z]{3}|\$|€|£|¥)\s*([0-9.,]+)|([0-9.,]+)\s*([A-Za-z]{3}|\$|€|£|¥))',
            text,
            re.IGNORECASE,
        )
        if labeled_amt:
            c1, a1, a2, c2 = labeled_amt.groups()
            raw_c = c1 or c2 or "USD"
            raw_a = a1 or a2 or "0"
            if raw_c == "$":
                currency = "USD"
            elif raw_c == "€":
                currency = "EUR"
            elif raw_c == "£":
                currency = "GBP"
            elif raw_c == "¥":
                currency = "CNY"
            elif len(raw_c) == 3:
                currency = raw_c.upper()

            clean_a = raw_a.strip().rstrip('.')
            if ',' in clean_a and '.' in clean_a:
                if clean_a.find(',') < clean_a.find('.'):
                    clean_a = clean_a.replace(',', '')
                else:
                    clean_a = clean_a.replace('.', '').replace(',', '.')
            elif ',' in clean_a:
                if len(clean_a.split(',')[-1]) == 2:
                    clean_a = clean_a.replace(',', '.')
                else:
                    clean_a = clean_a.replace(',', '')
            try:
                amount = float(clean_a)
            except ValueError:
                amount = 0.0
        else:
            # 2. Secondary: Unlabeled currency + amount pattern (e.g. 43,704.00 USD or EUR 15,375.50)
            unlabeled_amt = re.search(
                r'(?:(USD|EUR|EGP|GBP|CNY|SAR|AED|CHF|CAD|JPY|\$|€|£|¥)\s*([0-9]+(?:[,.][0-9]{2,3})+)|([0-9]+(?:[,.][0-9]{2,3})+)\s*(USD|EUR|EGP|GBP|CNY|SAR|AED|CHF|CAD|JPY|\$|€|£|¥))',
                text,
                re.IGNORECASE,
            )
            if unlabeled_amt:
                c1, a1, a2, c2 = unlabeled_amt.groups()
                raw_c = c1 or c2 or "USD"
                raw_a = a1 or a2 or "0"
                if raw_c == "$":
                    currency = "USD"
                elif raw_c == "€":
                    currency = "EUR"
                elif raw_c == "£":
                    currency = "GBP"
                elif raw_c == "¥":
                    currency = "CNY"
                elif len(raw_c) == 3:
                    currency = raw_c.upper()

                clean_a = raw_a.strip().rstrip('.')
                if ',' in clean_a and '.' in clean_a:
                    if clean_a.find(',') < clean_a.find('.'):
                        clean_a = clean_a.replace(',', '')
                    else:
                        clean_a = clean_a.replace('.', '').replace(',', '.')
                elif ',' in clean_a:
                    if len(clean_a.split(',')[-1]) == 2:
                        clean_a = clean_a.replace(',', '.')
                    else:
                        clean_a = clean_a.replace(',', '')
                try:
                    amount = float(clean_a)
                except ValueError:
                    amount = 0.0

        if currency == "USD":
            curr_match = re.search(r'\b(USD|EUR|EGP|GBP|CNY|SAR|AED|CHF|CAD|JPY)\b', text, re.IGNORECASE)
            if curr_match:
                currency = curr_match.group(1).upper()

        date_match = re.search(
            r'\b(20\d{2}[-/.]\d{1,2}[-/.]\d{1,2}|\d{1,2}[-/.]\d{1,2}[-/.]20\d{2}|\d{1,2}[-/.]\d{1,2}[-/.]\d{2})\b',
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
        r'(?:^|[\r\n])\s*:?50[KA]?(?:/ORDERING\s+CUST(?:OMER)?)?\s*[:/]?\s*(?:/([A-Za-z0-9]+))?\s*\n?([^\n\r:]+)(?:\n([^\n\r:]+))?',
        text,
        re.IGNORECASE,
    )
    if cust_match:
        ordering_account = cust_match.group(1)
        name_line = cust_match.group(2).strip() if cust_match.group(2) else None
        addr_line = cust_match.group(3).strip() if cust_match.group(3) else None
        ordering_customer_name = name_line
        ordering_address = addr_line
    else:
        ord_gen = re.search(
            r'(?:Ordering\s+Customer|Applicant|Sender|Remitter|الآمر\s+بالتحويل|طالب\s+التحويل|الشركة\s+المستوردة|العميل)\s*[:=]\s*([^\r\n]+)',
            text,
            re.IGNORECASE,
        )
        if ord_gen:
            ordering_customer_name = ord_gen.group(1).strip()

    # 5. Account with Bank / SWIFT (Field :57A or Bank Name)
    beneficiary_bank_swift = None
    b_bank_match = re.search(
        r'(?:^|[\r\n])\s*:?57[AD]?(?:/Account\s+with\s+Bank)?\s*[:/]?\s*([A-Za-z0-9]{8,11})',
        text,
        re.IGNORECASE,
    )
    if b_bank_match:
        beneficiary_bank_swift = b_bank_match.group(1).strip().upper()
    else:
        swift_gen = re.search(
            r'(?:SWIFT(?:\s+Code)?|BIC|Bank\s+SWIFT|كود\s+السويفت|سويفت)\s*[:=]?\s*([A-Za-z0-9]{8,11})',
            text,
            re.IGNORECASE,
        )
        if swift_gen:
            beneficiary_bank_swift = swift_gen.group(1).strip().upper()

    # 6. Beneficiary Customer (Field :59 or :59A or Beneficiary Name)
    beneficiary_account = None
    beneficiary_name = None
    beneficiary_address = None

    ben_match = re.search(
        r'(?:^|[\r\n])\s*:?59[A]?\s*(?:/Beneficiary\s+Customer)?\s*[:/]?\s*(?:/([A-Za-z0-9]+))?\s*\n?([^\n\r:]+)(?:\n([^\n\r:]+))?',
        text,
        re.IGNORECASE,
    )
    if ben_match:
        beneficiary_account = ben_match.group(1)
        b_name = ben_match.group(2).strip() if ben_match.group(2) else None
        b_addr = ben_match.group(3).strip() if ben_match.group(3) else None
        beneficiary_name = b_name
        beneficiary_address = b_addr
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

    # 7. Details of Payment (Field :70 or Details)
    payment_details = None
    pi_number = None
    po_number = None

    details_match = re.search(
        r'(?:^|[\r\n])\s*:?70(?:/DETAILS\s+OF\s+PAYMENT)?\s*[:/]?\s*([^\r\n:]+(?:\n[^\r\n:]+)?)',
        text,
        re.IGNORECASE,
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
        pi_match = re.search(r'(?:PI|Proforma\s+Invoice|فاتورة\s+مبدئية)\s*(?:NO\.?|#)?\s*([A-Za-z0-9\-_.]+)', text, re.IGNORECASE)
        if pi_match:
            pi_number = pi_match.group(1).strip().rstrip('.')
        po_match = re.search(r'(?:PO|Purchase\s+Order|أمر\s+شراء)\s*(?:NO\.?|#)?\s*([A-Za-z0-9\-_.]+)', text, re.IGNORECASE)
        if po_match:
            po_number = po_match.group(1).strip().rstrip('.')

    # 8. Details of Charges (Field :71A)
    charge_details = "SHA"
    charge_match = re.search(r':?71A(?:/DETAILS\s+OF\s+CHARGES)?\s*[:/]?\s*([A-Za-z]+)', text, re.IGNORECASE)
    if charge_match:
        charge_details = charge_match.group(1).strip().upper()

    # 9. Issuing / Sender Bank SWIFT from Header
    sender_bank_swift = None
    header_match = re.search(r'\{1:[A-Z0-9]{3}([A-Z0-9]{8,11})', text)
    if header_match:
        sender_bank_swift = header_match.group(1)

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
        "raw_text_length": len(text),
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
    swift_iban = (parsed_swift.get("beneficiary_account_or_iban", "") or "").strip().replace(' ', '')
    swift_ref = parsed_swift.get("transaction_reference", "")
    swift_pi = parsed_swift.get("pi_number", "")

    # 1. Amount Match
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

    # 3. SWIFT Code Match
    is_swift_match = False
    if req_swift and swift_swift:
        is_swift_match = (req_swift[:8] == swift_swift[:8]) # Match 8-character base SWIFT code

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
