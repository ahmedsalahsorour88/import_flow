"""
Smart SWIFT MT103 & Bank Transfer Advice Parser and Reconciliation Engine
(BP-012 / BP-013 / SWIFT-AI-EXTRACTOR)
"""

import re
from typing import Optional, Dict, Any, List
from datetime import datetime, date


def parse_swift_mt103_text(raw_text: str) -> Dict[str, Any]:
    """
    Parses raw SWIFT MT103 message text or standard bank transfer advice receipts
    and extracts all financial, beneficiary, ordering, and reference fields.
    """
    if not raw_text or not raw_text.strip():
        return {
            "success": False,
            "error": "Empty text provided",
        }

    text = raw_text.strip()

    # 1. Transaction Reference Number (Field :20)
    # Format: :20/TRANSACTION REFERENCE NUMBER : FT/26228/KZ70Q or :20:FT/26228/KZ70Q
    trans_ref = None
    ref_match = re.search(
        r':20(?:/TRANSACTION\s+REFERENCE(?:\s+NUMBER)?)?\s*:\s*([^\r\n]+)',
        text,
        re.IGNORECASE,
    )
    if ref_match:
        raw_val = ref_match.group(1).strip()
        parts = [p.strip() for p in raw_val.split('|') if p.strip()]
        trans_ref = parts[0] if parts else raw_val
    else:
        # Fallback for plain "Reference: FT/..." or "TRN: ..."
        fb_ref = re.search(r'(?:Reference(?:\s+No)?|TRN|Ref\s*#?)\s*[:=]\s*([A-Za-z0-9/\-_]+)', text, re.IGNORECASE)
        if fb_ref:
            trans_ref = fb_ref.group(1).strip()
    if trans_ref:
        trans_ref = trans_ref.strip(' |:')


    # 2. Bank Operation Code (Field :23B)
    # Format: :23B/BANK OPERATION CODE : CRED or :23B:CRED
    bank_op_code = None
    op_match = re.search(
        r':23B(?:/BANK\s+OPERATION\s+CODE)?\s*:\s*([A-Za-z0-9]+)',
        text,
        re.IGNORECASE,
    )
    if op_match:
        bank_op_code = op_match.group(1).strip()

    # 3. Value Date, Currency, Amount (Field :32A)
    # Format: :32A/Value Date, CCY, Amount : 260818USD43704,00 or :32A:260818USD43704,00
    value_date_str = None
    value_date = None
    currency = "USD"
    amount = 0.0

    val_match = re.search(
        r':32A(?:/Value\s+Date,?\s*CCY,?\s*Amount)?\s*:\s*(\d{6})([A-Z]{3})([0-9.,]+)',
        text,
        re.IGNORECASE,
    )
    if val_match:
        raw_date = val_match.group(1) # YYMMDD e.g. 260818 -> 2026-08-18
        currency = val_match.group(2).upper()
        raw_amount = val_match.group(3).replace(',', '.') # e.g. 43704.00
        try:
            amount = float(raw_amount)
        except ValueError:
            amount = 0.0

        try:
            # YYMMDD
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
        # Fallback search for Currency & Amount
        amt_match = re.search(r'(?:Amount|Value|المبلغ)\s*[:=]?\s*([0-9.,]+)\s*([A-Z]{3})?', text, re.IGNORECASE)
        if amt_match:
            try:
                amount = float(amt_match.group(1).replace(',', '.'))
            except ValueError:
                pass
            if amt_match.group(2):
                currency = amt_match.group(2).upper()

        curr_match = re.search(r'\b(USD|EUR|EGP|GBP|CNY|SAR|AED)\b', text)
        if curr_match and currency == "USD":
            currency = curr_match.group(1).upper()

        date_match = re.search(r'\b(20\d{2}[-/.]\d{1,2}[-/.]\d{1,2}|\d{1,2}[-/.]\d{1,2}[-/.]20\d{2})\b', text)
        if date_match:
            value_date_str = date_match.group(1)
            value_date = value_date_str

    # 4. Ordering Customer (Field :50K or :50A)
    # Format:
    # :50K/ORDERING CUST : /EG780057004001017153610010101
    # SCAS FOR CONSTRUCTION AND FINISHING
    # ROAD 18
    # EGYPT,44 ROAD 18
    # SARIAT EL MAADI,CAIRO
    ordering_account = None
    ordering_customer_name = None
    ordering_address = None

    cust_match = re.search(
        r':50[KA](?:/ORDERING\s+CUST(?:OMER)?)?\s*:\s*(?:/([A-Za-z0-9]+))?\s*\n?([^\n\r:]+)(?:\n([^\n\r:]+))?',
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
        # Generic check for Ordering / Importer
        ord_gen = re.search(r'(?:Ordering\s+Customer|الآمر\s+بالتحويل|الشركة\s+المستوردة)\s*[:=]\s*([^\r\n]+)', text, re.IGNORECASE)
        if ord_gen:
            ordering_customer_name = ord_gen.group(1).strip()

    # 5. Account with Bank / SWIFT (Field :57A)
    # Format: :57A/Account with Bank : PCBCCNBJJSS
    beneficiary_bank_swift = None
    b_bank_match = re.search(
        r':57A(?:/Account\s+with\s+Bank)?\s*:\s*([A-Z0-9]{8,11})',
        text,
        re.IGNORECASE,
    )
    if b_bank_match:
        beneficiary_bank_swift = b_bank_match.group(1).strip()
    else:
        swift_gen = re.search(r'(?:SWIFT(?:\s+Code)?|BIC)\s*[:=]?\s*([A-Z0-9]{8,11})', text, re.IGNORECASE)
        if swift_gen:
            beneficiary_bank_swift = swift_gen.group(1).strip()

    # 6. Beneficiary Customer (Field :59 or :59A)
    # Format:
    # :59/Beneficiary Customer : /32250198613609841015
    # SUZHOU YUHENG TEXTILE CO., LTD
    # 16 KANGSHENG ROAD ZHITANG TOWN CHANGSHU CITY SUZHOU CHINA
    beneficiary_account = None
    beneficiary_name = None
    beneficiary_address = None

    ben_match = re.search(
        r':59[A]?\s*(?:/Beneficiary\s+Customer)?\s*:\s*(?:/([A-Za-z0-9]+))?\s*\n?([^\n\r:]+)(?:\n([^\n\r:]+))?',
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
        ben_gen = re.search(r'(?:Beneficiary(?:\s+Name)?|المستفيد|المورد)\s*[:=]\s*([^\r\n]+)', text, re.IGNORECASE)
        if ben_gen:
            beneficiary_name = ben_gen.group(1).strip()

        iban_gen = re.search(r'(?:IBAN|Account(?:\s+No)?|رقم\s+الحساب)\s*[:=]?\s*([A-Za-z0-9]{8,34})', text, re.IGNORECASE)
        if iban_gen:
            beneficiary_account = iban_gen.group(1).strip()

    # 7. Details of Payment (Field :70)
    # Format: :70/DETAILS OF PAYMENT : EG0010040 PI NO.YH20260730.6 ALL DOCUMENTS SHOULD BE TRADED THROUGH AAIB
    payment_details = None
    pi_number = None
    po_number = None

    details_match = re.search(
        r':70(?:/DETAILS\s+OF\s+PAYMENT)?\s*:\s*([^\r\n:]+(?:\n[^\r\n:]+)?)',
        text,
        re.IGNORECASE,
    )
    if details_match:
        payment_details = details_match.group(1).strip()
        # Search for PI or PO inside payment details or full text
        pi_match = re.search(r'(?:PI|Proforma\s+Invoice)\s*(?:NO\.?|#)?\s*([A-Za-z0-9\-_.]+)', payment_details, re.IGNORECASE)
        if pi_match:
            pi_number = pi_match.group(1).strip().rstrip('.')

        po_match = re.search(r'(?:PO|Purchase\s+Order)\s*(?:NO\.?|#)?\s*([A-Za-z0-9\-_.]+)', payment_details, re.IGNORECASE)
        if po_match:
            po_number = po_match.group(1).strip().rstrip('.')
    else:
        pi_match = re.search(r'(?:PI|Proforma\s+Invoice)\s*(?:NO\.?|#)?\s*([A-Za-z0-9\-_.]+)', text, re.IGNORECASE)
        if pi_match:
            pi_number = pi_match.group(1).strip().rstrip('.')

    # 8. Details of Charges (Field :71A)
    charge_details = "SHA"
    charge_match = re.search(r':71A(?:/DETAILS\s+OF\s+CHARGES)?\s*:\s*([A-Za-z]+)', text, re.IGNORECASE)
    if charge_match:
        charge_details = charge_match.group(1).strip().upper()

    # 9. Issuing / Sender Bank SWIFT from Header
    # {1:F01ARAIECXXXXX...} -> ARAIECXXXXX
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
