from typing import List, Optional

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from fastapi.responses import Response
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
    bulk_import_tariffs_service,
    create_tariff_service,
    delete_tariff_service,
    estimate_customs_duty_service,
    get_all_tariffs_service,
    get_tariff_by_hs_code_service,
    get_tariff_by_id_service,
    restore_tariff_service,
    update_tariff_service,
)

customs_tariff_router = APIRouter(prefix="/api/v1/customs-tariff", tags=["Customs Tariff"])


@customs_tariff_router.get("", response_model=List[CustomsTariffResponse])
def get_all_tariffs(include_inactive: bool = Query(False), db: Session = Depends(get_db)):
    return get_all_tariffs_service(db, include_inactive)


@customs_tariff_router.post("", response_model=CustomsTariffResponse)
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


@customs_tariff_router.post("/upload-excel")
async def upload_customs_tariffs(file: UploadFile = File(...), db: Session = Depends(get_db)):
    """
    Upload Excel/CSV file containing Nafeza/Egyptian Customs Tariffs (HS Codes) for bulk creation or update.
    """
    contents = await file.read()
    return bulk_import_tariffs_service(db, contents, file.filename or "uploaded.csv")


@customs_tariff_router.get("/export-template")
def export_customs_tariff_template():
    """
    Download sample CSV template for Egyptian Customs Tariff (MD-008).
    """
    csv_content = (
        "hs_code,hs_description,customs_category,customs_duty_rate,vat_rate,schedule_tax_rate,development_fee_rate,import_fee_rate,regulatory_authority,requires_coo,requires_inspection,requires_acid,notes\n"
        "1001.99.00,Wheat and meslin (Other than durum wheat),Agriculture & Food,0.0,0.0,0.0,0.0,0.0,GOEIC & NFSA,true,true,true,Essential Strategic Commodity\n"
        "8471.30.00,Portable laptops & notebooks,Electronics,5.0,14.0,0.0,5.0,0.0,NTRA,true,true,true,NTRA Approval Required\n"
        "8703.23.00,Passenger cars 1600cc to 2000cc,Automotive,135.0,14.0,15.0,5.5,0.0,GOEIC,true,true,true,Schedule Tax 15%\n"
    )
    return Response(
        content=csv_content,
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=customs_tariff_template.csv"},
    )

