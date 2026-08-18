"""
modules/common/regex_patterns.py
Centralized regex patterns for ImportFlow ERP document parsing.
Consolidates patterns previously duplicated across:
 - import_documentation/ai_document_parser.py
 - import_documentation/nafeza_acid_parser.py
 - customs_tariff/nafeza_text_parser.py
 - smart_document_upload/extractors/
"""
import re

# Egyptian ACID number: 19-digit numeric string
ACID_PATTERN = re.compile(r'\b(\d{19})\b')

# Egyptian Tax ID: 9-digit (with optional hyphens: XXX-XXX-XXX)
EGYPTIAN_TAX_ID_PATTERN = re.compile(
    r'\b(\d{3}[-\s]?\d{3}[-\s]?\d{3})\b'
)

# HS Code: 4 to 10 digits (WCO standard)
HS_CODE_PATTERN = re.compile(r'\b(\d{4}\.?\d{2}\.?\d{0,4})\b')

# Commercial Registry: Egyptian commercial register numbers
COMMERCIAL_REGISTRY_PATTERN = re.compile(
    r'(?:commercial\s*reg(?:istry|istration)?|س\.ت|سجل\s*تجاري)[\s:]*([\w\-/]+)',
    re.IGNORECASE
)

# Bill of Lading number
BL_NUMBER_PATTERN = re.compile(
    r'(?:b/?l|bill\s+of\s+lading|b\.l\.?)[\s:]*([A-Z0-9]{4,20})',
    re.IGNORECASE
)

# SWIFT / BIC code: 8 or 11 characters
SWIFT_CODE_PATTERN = re.compile(
    r'\b([A-Z]{4}[A-Z]{2}[A-Z0-9]{2}(?:[A-Z0-9]{3})?)\b'
)

# IBAN: International Bank Account Number
IBAN_PATTERN = re.compile(
    r'\b([A-Z]{2}\d{2}[A-Z0-9]{4,30})\b'
)

# Email address
EMAIL_PATTERN = re.compile(
    r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}'
)

# International phone number
PHONE_PATTERN = re.compile(
    r'(?:\+?\d[\s\-]?){7,15}'
)
