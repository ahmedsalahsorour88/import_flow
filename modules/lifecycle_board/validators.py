"""
Business Validators for Lifecycle Board & Stage Transitions
"""

from fastapi import HTTPException, status

VALID_STEP_CODES = {
    "STEP_01": "Freight Studies",
    "STEP_02": "Customs Studies",
    "STEP_03": "Regulatory Requirements",
    "STEP_04": "Finance Approvals",
    "STEP_05": "ACID Operations",
    "STEP_06": "Freight Booking",
    "STEP_07": "Freight Allocations",
    "STEP_08": "Draft Docs Review",
    "STEP_09": "Docs Customs Approval",
    "STEP_10": "CargoX Follow-up",
    "STEP_11": "Originals Collection",
    "STEP_12": "Bank Form 4",
    "STEP_13": "Customs Declaration 46",
    "STEP_14": "Clearance Follow-up",
    "STEP_15": "Drawing Samples",
    "STEP_16": "Cargo Discrepancy",
    "STEP_17": "Final Customs Calculation",
    "STEP_18": "Demurrage & Detention",
    "STEP_19": "Warehouse Receiving GRN",
    "STEP_20": "Landed Cost Settlement",
    "STEP_21": "Import File Final Closure",
}


def validate_step_code(step_code: str):
    if step_code not in VALID_STEP_CODES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"كود الخطوة '{step_code}' غير صالح. الأكواد المعتمدة من STEP_01 إلى STEP_21.",
        )


def validate_multi_step_codes(step_codes: list[str]):
    for code in step_codes:
        validate_step_code(code)
