import pytest
from datetime import date
from modules.financial_approval.swift_mt103_parser import (
    parse_swift_mt103_text,
    match_swift_against_payment_request,
)
from modules.financial_approval.schemas import PaymentRequestCreate
from modules.financial_approval.model import PaymentRequestSession


SAMPLE_SWIFT_MT103_TEXT = """
{1:F01ARAIECXXXXX.SN...ISN.}{2:I103CITIUS33XXXXN}{3:{108:xxxxx}}{4:
:20/TRANSACTION REFERENCE NUMBER       : FT/26228/KZ70Q
:23B/BANK OPERATION CODE              : CRED
:32A/Value Date, CCY, Amount          : 260818USD43704,00
:50K/ORDERING CUST                     : /EG780057004001017153610010101
                                        SCAS FOR CONSTRUCTION AND FINISHING
                                        ROAD 18
                                        EGYPT,44 ROAD 18
                                        SARIAT EL MAADI,CAIRO
:57A/Account with Bank                : PCBCCNBJJSS
:59/Beneficiary Customer              : /32250198613609841015
                                        SUZHOU YUHENG TEXTILE CO., LTD
                                        16 KANGSHENG ROAD ZHITANG TOWN
                                        CHANGSHU CITY SUZHOU CHINA
:70/DETAILS OF PAYMENT                : EG0010040 PI NO.YH20260730.6
                                        ALL DOCUMENTS SHOULD BE TRADED
                                        THROUGH AAIB
:71A/DETAILS OF CHARGES               : SHA
-}
"""


def test_parse_swift_mt103_text():
    parsed = parse_swift_mt103_text(SAMPLE_SWIFT_MT103_TEXT)

    assert parsed["success"] is True
    assert parsed["transaction_reference"] == "FT/26228/KZ70Q"
    assert parsed["bank_operation_code"] == "CRED"
    assert parsed["amount"] == 43704.0
    assert parsed["currency"] == "USD"
    assert parsed["value_date"] == "2026-08-18"
    assert "SCAS FOR CONSTRUCTION AND FINISHING" in (parsed["ordering_customer_name"] or "")
    assert parsed["ordering_account_or_iban"] == "EG780057004001017153610010101"
    assert parsed["beneficiary_bank_swift"] == "PCBCCNBJJSS"
    assert "SUZHOU YUHENG TEXTILE" in (parsed["beneficiary_name"] or "")
    assert parsed["beneficiary_account_or_iban"] == "32250198613609841015"
    assert "YH20260730.6" in (parsed["pi_number"] or "")
    assert parsed["charge_details"] == "SHA"


def test_match_swift_against_payment_request_exact():
    parsed = parse_swift_mt103_text(SAMPLE_SWIFT_MT103_TEXT)

    dummy_payment = PaymentRequestSession(
        payment_id=2,
        payment_code="PAY-2026-002",
        title="[6701068101-Acoustic Panel] SCAS FOR CONSTRUCTION AND FINISHING",
        supplier_name="Suzhou Yuheng Textile Co.,Ltd",
        beneficiary_name="Suzhou Yuheng Textile Co.,Ltd",
        requested_amount=43704.0,
        currency_code="USD",
        exchange_rate=50.25,
        requested_amount_egp=2196126.0,
        due_date=date(2026, 8, 31),
        bank_name="China Construction Bank, Suzhou Branch",
        swift_code="PCBCCNBJJSS",
        iban_account_no="32250198613609841015",
        status="Draft",
    )

    match = match_swift_against_payment_request(parsed, dummy_payment)

    assert match["payment_id"] == 2
    assert match["confidence_score"] >= 80
    assert match["amount_matching"]["is_matched"] is True
    assert match["amount_matching"]["variance"] == 0.0
    assert match["beneficiary_matching"]["is_matched"] is True
    assert match["bank_swift_matching"]["is_matched"] is True
    assert match["account_iban_matching"]["is_matched"] is True


def test_parse_informal_english_and_arabic_swift_advices():
    # 1. Informal English advice
    eng_text = """
    OUTGOING TELEGRAPHIC TRANSFER RECEIPT
    Reference Number: TRN-2026-998811
    Date: 2026-08-19
    Amount: 15,375.50 EUR
    Beneficiary Name: UAB Narbutas International
    Beneficiary Account: LT127044060001234567
    SWIFT Code: CBVILT2X
    Remittance Info: Settlement for Invoice IN053328 and PO-2026-0042
    Applicant: Archi brands for corpet and floor trading
    """
    p_eng = parse_swift_mt103_text(eng_text)
    assert p_eng["success"] is True
    assert p_eng["transaction_reference"] == "TRN-2026-998811"
    assert p_eng["amount"] == 15375.50
    assert p_eng["currency"] == "EUR"
    assert "UAB Narbutas" in p_eng["beneficiary_name"]
    assert p_eng["beneficiary_account_or_iban"] == "LT127044060001234567"
    assert p_eng["beneficiary_bank_swift"] == "CBVILT2X"

    # 2. Informal Arabic bank advice
    ar_text = """
    البنك التجاري الدولي CIB - إشعار تحويل خارجي
    رقم المرجع: CIB/2026/88442
    تاريخ التنفيذ: 2026-08-20
    المستفيد: SUZHOU YUHENG TEXTILE CO., LTD
    المبلغ: 50,000.00 USD
    رقم الحساب: 32250198613609841015
    سويفت: PCBCCNBJJSS
    الآمر بالتحويل: شركة سكاس للتشطيبات المعمارية
    البيان: سداد دفعة مقدمة أمر شراء PO-2026-0010
    """
    p_ar = parse_swift_mt103_text(ar_text)
    assert p_ar["success"] is True
    assert p_ar["transaction_reference"] == "CIB/2026/88442"
    assert p_ar["amount"] == 50000.0
    assert p_ar["currency"] == "USD"
    assert "SUZHOU YUHENG" in p_ar["beneficiary_name"]
    assert p_ar["beneficiary_account_or_iban"] == "32250198613609841015"
    assert p_ar["beneficiary_bank_swift"] == "PCBCCNBJJSS"
    assert "شركة سكاس" in p_ar["ordering_customer_name"]
