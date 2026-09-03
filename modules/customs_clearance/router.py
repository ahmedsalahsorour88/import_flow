from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from database.database import get_db
from .schemas import (
    CustomsClearanceCreate,
    CustomsClearanceUpdate,
    CustomsClearanceResponse,
    DutyPaymentSubmit,
    CompleteReleaseSubmit,
    UnderBondReleaseSubmit,
    LabTestResultSubmit,
)
from .service import (
    create_customs_clearance_service,
    get_customs_clearance_service,
    list_customs_clearances_service,
    submit_duty_payment_service,
    complete_customs_release_service,
    issue_under_bond_release_service,
    record_lab_result_and_lift_quarantine_service,
    update_customs_clearance_service,
    soft_delete_customs_clearance_service,
    restore_customs_clearance_service,
)

router = APIRouter(prefix="/api/v1/customs-clearance", tags=["Phase 7 - Customs Clearance"])

@router.get("", response_model=List[CustomsClearanceResponse])
def list_customs_clearances(
    include_inactive: bool = Query(False, description="Include soft-deleted records"),
    import_file_id: Optional[int] = Query(None, description="Filter by import file ID"),
    status_filter: Optional[str] = Query(None, alias="status", description="Filter by operational status"),
    search: Optional[str] = Query(None, description="Search term"),
    db: Session = Depends(get_db),
):
    return list_customs_clearances_service(db, include_inactive, import_file_id, status_filter, search)

@router.post("", response_model=CustomsClearanceResponse, status_code=status.HTTP_201_CREATED)
def create_customs_clearance(
    schema: CustomsClearanceCreate,
    db: Session = Depends(get_db),
):
    return create_customs_clearance_service(db, schema)

@router.get("/{record_id}", response_model=CustomsClearanceResponse)
def get_customs_clearance(
    record_id: int,
    db: Session = Depends(get_db),
):
    return get_customs_clearance_service(db, record_id)

@router.put("/{record_id}", response_model=CustomsClearanceResponse)
def update_customs_clearance(
    record_id: int,
    schema: CustomsClearanceUpdate,
    db: Session = Depends(get_db),
):
    return update_customs_clearance_service(db, record_id, schema)

@router.post("/{record_id}/pay-duty", response_model=CustomsClearanceResponse)
def submit_duty_payment(
    record_id: int,
    payload: DutyPaymentSubmit,
    db: Session = Depends(get_db),
):
    return submit_duty_payment_service(db, record_id, payload)

@router.post("/{record_id}/complete-release", response_model=CustomsClearanceResponse)
def complete_customs_release(
    record_id: int,
    payload: CompleteReleaseSubmit,
    db: Session = Depends(get_db),
):
    return complete_customs_release_service(db, record_id, payload)

@router.post("/{record_id}/under-bond-release", response_model=CustomsClearanceResponse, summary="إصدار إفراج مشروط تحت التحفظ الجمركي والسحب على عهدة")
def issue_under_bond_release(
    record_id: int,
    payload: UnderBondReleaseSubmit,
    db: Session = Depends(get_db),
):
    return issue_under_bond_release_service(db, record_id, payload)

@router.post("/{record_id}/lab-test-result", response_model=CustomsClearanceResponse, summary="تسجيل نتيجة الفحص المعملي وفك التحفظ الجمركي")
def record_lab_test_result(
    record_id: int,
    payload: LabTestResultSubmit,
    db: Session = Depends(get_db),
):
    return record_lab_result_and_lift_quarantine_service(db, record_id, payload)


@router.delete("/{record_id}", status_code=status.HTTP_204_NO_CONTENT)
def soft_delete_customs_clearance(
    record_id: int,
    db: Session = Depends(get_db),
):
    soft_delete_customs_clearance_service(db, record_id)
    return None

@router.patch("/{record_id}/restore", response_model=CustomsClearanceResponse)
def restore_customs_clearance(
    record_id: int,
    db: Session = Depends(get_db),
):
    return restore_customs_clearance_service(db, record_id)
