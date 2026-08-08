from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from database.database import get_db

from .schemas import (
    CustomsDutyBreakdown,
    CustomsDutyEstimateRequest,
    CustomsTariffCreate,
    CustomsTariffResponse,
    CustomsTariffUpdate,
)
from .service import (
    create_tariff_service,
    delete_tariff_service,
    estimate_customs_duty_service,
    get_all_tariffs_service,
    get_tariff_by_hs_code_service,
    get_tariff_by_id_service,
    restore_tariff_service,
    update_tariff_service,
)

customs_tariff_router = APIRouter(prefix="/customs-tariff", tags=["Customs Tariff"])


@customs_tariff_router.post("/", response_model=CustomsTariffResponse)
def create_tariff(data: CustomsTariffCreate, db: Session = Depends(get_db)):
    try:
        return create_tariff_service(db, data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@customs_tariff_router.get("/", response_model=List[CustomsTariffResponse])
def list_tariffs(
    include_inactive: bool = Query(False),
    search: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    return get_all_tariffs_service(db, include_inactive=include_inactive, search=search)


@customs_tariff_router.post("/estimate", response_model=CustomsDutyBreakdown)
def estimate_customs_duty(request: CustomsDutyEstimateRequest, db: Session = Depends(get_db)):
    """
    Egyptian Customs Calculation Engine API Endpoint.
    Estimates customs duties, VAT, schedule tax, and development fees based on the HS Code.
    """
    return estimate_customs_duty_service(db, request)


@customs_tariff_router.get("/hs/{hs_code}", response_model=CustomsTariffResponse)
def get_tariff_by_hs_code(hs_code: str, db: Session = Depends(get_db)):
    return get_tariff_by_hs_code_service(db, hs_code)


@customs_tariff_router.get("/{tariff_id}", response_model=CustomsTariffResponse)
def get_tariff(tariff_id: int, db: Session = Depends(get_db)):
    return get_tariff_by_id_service(db, tariff_id)


@customs_tariff_router.put("/{tariff_id}", response_model=CustomsTariffResponse)
def update_tariff(tariff_id: int, data: CustomsTariffUpdate, db: Session = Depends(get_db)):
    try:
        return update_tariff_service(db, tariff_id, data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@customs_tariff_router.delete("/{tariff_id}", response_model=CustomsTariffResponse)
def delete_tariff(tariff_id: int, db: Session = Depends(get_db)):
    return delete_tariff_service(db, tariff_id)


@customs_tariff_router.patch("/{tariff_id}/restore", response_model=CustomsTariffResponse)
def restore_tariff(tariff_id: int, db: Session = Depends(get_db)):
    return restore_tariff_service(db, tariff_id)
