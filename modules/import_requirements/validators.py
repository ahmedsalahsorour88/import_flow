from fastapi import HTTPException, status


VALID_STATUSES = {"Not Required", "Pending", "Obtained", "Waived", "Scheduled", "Completed", "Applied", "Approved", "Rejected", "In Progress"}
VALID_RISK_LEVELS = {"Low", "Medium", "High"}
VALID_OVERALL_STATUSES = {"Draft", "In Progress", "Complete", "Cleared"}


def validate_risk_level(risk_level: str):
    if risk_level not in VALID_RISK_LEVELS:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail=f"Invalid risk_level '{risk_level}'. Must be one of: {VALID_RISK_LEVELS}"
        )


def validate_overall_status(overall_status: str):
    if overall_status not in VALID_OVERALL_STATUSES:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail=f"Invalid overall_status '{overall_status}'. Must be one of: {VALID_OVERALL_STATUSES}"
        )


def validate_shipment_value(value: float):
    if value < 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="shipment_value_usd must be >= 0"
        )
