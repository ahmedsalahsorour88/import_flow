from fastapi import HTTPException

def validate_bank_receipt_no(receipt_no: str) -> None:
    """Validates bank receipt number is non-empty and has proper format."""
    if not receipt_no or not receipt_no.strip():
        raise HTTPException(status_code=400, detail="رقم إيصال السداد البنكي إجباري ومطلوب لتوثيق سداد الرسوم الجمركية.")

def validate_release_permit(permit_no: str, payment_status: str) -> None:
    """Ensures customs duty payment is verified before issuing final release permit."""
    if payment_status != "Paid & Verified":
        raise HTTPException(status_code=400, detail="لا يمكن إصدار الإفراج الجمركي النهائي قبل تأكيد وتوثيق سداد الرسوم الجمركية بنجاح.")
    if not permit_no or not permit_no.strip():
        raise HTTPException(status_code=400, detail="رقم إذن/تصريح الإفراج الجمركي النهائي مطلوب ولا يمكن أن يكون فارغاً.")
