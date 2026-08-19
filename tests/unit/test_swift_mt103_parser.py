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
