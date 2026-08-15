"""
Business Validation Rules for Import Documentation & ACI (Phase 3 - BP-014 to BP-019)
"""

from datetime import date
from fastapi import HTTPException, status
from sqlalchemy.orm import Session


def validate_acid_number(acid_number: str | None, allow_pending: bool = True):
    """
    Validates Egyptian Nafeza ACID Number structure:
    Must be exactly 19 numeric digits when issued, or PENDING during initial request stage.
    """
    if not acid_number:
        if allow_pending:
            return
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="ACID Number is required.",
        )
    cleaned = acid_number.strip()
    if allow_pending and cleaned.upper() in ["PENDING", "REQUESTED", "DRAFT", ""]:
        return
    if len(cleaned) != 19 or not cleaned.isdigit():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid ACID Number '{acid_number}'. Egyptian Nafeza ACID must be exactly 19 numeric digits.",
        )


def validate_acid_expiry(expiry_date: date | None, issue_date: date | None = None):
    """
    Validates that ACID expiry date is in the future.
    """
    if not expiry_date:
        return
    ref_date = issue_date or date.today()
    if expiry_date <= ref_date:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"ACID Expiry Date ({expiry_date}) must be after Issue/Requested Date ({ref_date}).",
        )


def validate_no_duplicate_acid_session(
    db: Session,
    import_file_id: int | None,
    current_acid_id: int | None = None,
):
    """
    Prevents creating duplicate active ACID registration sessions for the same Import File.
    Directs user to edit the existing session instead of creating a new one.
    """
    if not import_file_id:
        return

    from modules.import_documentation.model import AcidRegistrationSession

    query = db.query(AcidRegistrationSession).filter(
        AcidRegistrationSession.import_file_id == import_file_id,
        AcidRegistrationSession.is_active == True,
    )
    if current_acid_id is not None:
        query = query.filter(AcidRegistrationSession.acid_id != current_acid_id)

    existing = query.first()
    if existing:
        ref_display = f" - رقم ACID: {existing.acid_number}" if existing.acid_number and existing.acid_number != "PENDING" else ""
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"لا يمكن حفظ طلب ACID جديد لأن ملف الشحنة مرتبط بالفعل بجلسة مسجلة ومحفوظة "
                f"في سجل الطلبات (كود الجلسة: {existing.acid_code}{ref_display}). "
                f"يرجى التوجه إلى سجل الطلبات والإصدار للتعديل على الجلسة الحالية بدلاً من إنشاء طلب جديد."
            ),
        )


def validate_no_duplicate_form4_session(
    db: Session,
    import_file_id: int | None,
    current_doc_id: int | None = None,
):
    """
    Prevents creating duplicate active Form 4 requests for the same Import File.
    Directs user to edit the existing session instead of creating a new one.
    """
    if not import_file_id:
        return

    from modules.import_documentation.model import BankingDocumentSession

    query = db.query(BankingDocumentSession).filter(
        BankingDocumentSession.import_file_id == import_file_id,
        BankingDocumentSession.doc_type == "Form 4",
        BankingDocumentSession.is_active == True,
    )
    if current_doc_id is not None:
        query = query.filter(BankingDocumentSession.bank_doc_id != current_doc_id)

    existing = query.first()
    if existing:
        ref_display = f" - رقم النموذج: {existing.doc_reference_number}" if existing.doc_reference_number and existing.doc_reference_number != "PENDING" else ""
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"لا يمكن حفظ طلب نموذج 4 جديد لأن ملف الشحنة مرتبط بالفعل بجلسة مسجلة ومحفوظة "
                f"في سجل النماذج (كود الطلب: {existing.bank_doc_code}{ref_display}). "
                f"يرجى التوجه إلى سجل النماذج للتعديل على الطلب الحالي بدلاً من إنشاء طلب جديد."
            ),
        )
