# ==================================================
# System
# ==================================================

SYSTEM_USER = "system"

ADMIN_USER = "admin"


# ==================================================
# Status
# ==================================================

ACTIVE = True

INACTIVE = False


# ==================================================
# Default Pagination
# ==================================================

DEFAULT_PAGE = 1

DEFAULT_PAGE_SIZE = 20

MAX_PAGE_SIZE = 100


# ==================================================
# Countries
# ==================================================

DEFAULT_COUNTRY = "Egypt"


# ==================================================
# Date Format
# ==================================================

DATE_FORMAT = "%Y-%m-%d"

DATETIME_FORMAT = "%Y-%m-%d %H:%M:%S"


# ==================================================
# Import Company Messages
# ==================================================

IMPORT_COMPANY_NOT_FOUND = "Import Company not found"

IMPORT_COMPANY_CREATED = "Import Company created successfully"

IMPORT_COMPANY_UPDATED = "Import Company updated successfully"

IMPORT_COMPANY_DELETED = "Import Company deleted successfully"

IMPORT_COMPANY_RESTORED = "Import Company restored successfully"


# ==================================================
# Supplier Messages
# ==================================================

SUPPLIER_NOT_FOUND = "Supplier not found"

SUPPLIER_CREATED = "Supplier created successfully"

SUPPLIER_UPDATED = "Supplier updated successfully"

SUPPLIER_DELETED = "Supplier deleted successfully"

SUPPLIER_RESTORED = "Supplier restored successfully"


# ==================================================
# Validation Messages
# ==================================================

IMPORTER_ID_ALREADY_EXISTS = "Importer ID already exists"

VAT_ID_ALREADY_EXISTS = "VAT ID already exists"

REGISTRATION_NUMBER_ALREADY_EXISTS = (
    "Registration Number already exists"
)

SUPPLIER_ALREADY_EXISTS = (
    "Supplier already exists"
)


# ==================================================
# Audit Actions
# ==================================================

CREATE_ACTION = "CREATE"

UPDATE_ACTION = "UPDATE"

DELETE_ACTION = "DELETE"

RESTORE_ACTION = "RESTORE"