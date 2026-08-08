from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database.database import get_db

from .schemas import (
    CostItemCreate,
    CostItemResponse,
    CostItemUpdate,
    IncotermCreate,
    IncotermResponse,
    IncotermResponsibilityCreate,
    IncotermResponsibilityResponse,
    IncotermResponsibilityUpdate,
    IncotermUpdate,
)
from .service import (
    create_cost_item_service,
    create_incoterm_service,
    create_responsibility_service,
    delete_cost_item_service,
    delete_incoterm_service,
    delete_responsibility_service,
    get_all_cost_items_service,
    get_all_incoterms_service,
    get_all_responsibilities_service,
    get_cost_item_by_id_service,
    get_incoterm_by_id_service,
    get_matrix_for_incoterm_service,
    restore_cost_item_service,
    restore_incoterm_service,
    update_cost_item_service,
    update_incoterm_service,
    update_responsibility_service,
)


# ==================================================
# Router
# ==================================================

incoterms_router = APIRouter(prefix="/api/v1", tags=["Incoterms"])


# ==================================================
# Incoterms Endpoints (MD-006)
# ==================================================

@incoterms_router.post("/incoterms", response_model=IncotermResponse)
@incoterms_router.post("/incoterms/", response_model=IncotermResponse, include_in_schema=False)
def create_incoterm(data: IncotermCreate, db: Session = Depends(get_db)):
    try:
        return create_incoterm_service(db, data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@incoterms_router.get("/incoterms", response_model=List[IncotermResponse])
@incoterms_router.get("/incoterms/", response_model=List[IncotermResponse], include_in_schema=False)
def list_incoterms(include_inactive: bool = False, db: Session = Depends(get_db)):
    return get_all_incoterms_service(db, include_inactive)


@incoterms_router.get("/incoterms/{incoterm_id}", response_model=IncotermResponse)
def get_incoterm(incoterm_id: int, db: Session = Depends(get_db)):
    return get_incoterm_by_id_service(db, incoterm_id)


@incoterms_router.put("/incoterms/{incoterm_id}", response_model=IncotermResponse)
def update_incoterm(incoterm_id: int, data: IncotermUpdate, db: Session = Depends(get_db)):
    try:
        return update_incoterm_service(db, incoterm_id, data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@incoterms_router.delete("/incoterms/{incoterm_id}", response_model=IncotermResponse)
def delete_incoterm(incoterm_id: int, db: Session = Depends(get_db)):
    return delete_incoterm_service(db, incoterm_id)


@incoterms_router.patch("/incoterms/{incoterm_id}/restore", response_model=IncotermResponse)
def restore_incoterm(incoterm_id: int, db: Session = Depends(get_db)):
    return restore_incoterm_service(db, incoterm_id)


# ==================================================
# Cost Items Endpoints (MD-006A)
# ==================================================

@incoterms_router.post("/cost-items", response_model=CostItemResponse)
@incoterms_router.post("/cost-items/", response_model=CostItemResponse, include_in_schema=False)
def create_cost_item(data: CostItemCreate, db: Session = Depends(get_db)):
    try:
        return create_cost_item_service(db, data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@incoterms_router.get("/cost-items", response_model=List[CostItemResponse])
@incoterms_router.get("/cost-items/", response_model=List[CostItemResponse], include_in_schema=False)
def list_cost_items(include_inactive: bool = False, db: Session = Depends(get_db)):
    return get_all_cost_items_service(db, include_inactive)


@incoterms_router.get("/cost-items/{cost_item_id}", response_model=CostItemResponse)
def get_cost_item(cost_item_id: int, db: Session = Depends(get_db)):
    return get_cost_item_by_id_service(db, cost_item_id)


@incoterms_router.put("/cost-items/{cost_item_id}", response_model=CostItemResponse)
def update_cost_item(cost_item_id: int, data: CostItemUpdate, db: Session = Depends(get_db)):
    try:
        return update_cost_item_service(db, cost_item_id, data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@incoterms_router.delete("/cost-items/{cost_item_id}", response_model=CostItemResponse)
def delete_cost_item(cost_item_id: int, db: Session = Depends(get_db)):
    return delete_cost_item_service(db, cost_item_id)


@incoterms_router.patch("/cost-items/{cost_item_id}/restore", response_model=CostItemResponse)
def restore_cost_item(cost_item_id: int, db: Session = Depends(get_db)):
    return restore_cost_item_service(db, cost_item_id)


# ==================================================
# Responsibility Matrix Endpoints (MD-006B)
# ==================================================

@incoterms_router.post(
    "/incoterm-responsibilities", response_model=IncotermResponsibilityResponse
)
@incoterms_router.post(
    "/incoterm-responsibilities/", response_model=IncotermResponsibilityResponse, include_in_schema=False
)
def create_responsibility(
    data: IncotermResponsibilityCreate, db: Session = Depends(get_db)
):
    try:
        return create_responsibility_service(db, data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@incoterms_router.get(
    "/incoterm-responsibilities", response_model=List[IncotermResponsibilityResponse]
)
@incoterms_router.get(
    "/incoterm-responsibilities/", response_model=List[IncotermResponsibilityResponse], include_in_schema=False
)
def list_responsibilities(db: Session = Depends(get_db)):
    return get_all_responsibilities_service(db)


@incoterms_router.get(
    "/incoterm-responsibilities/matrix/{incoterm_id}",
    response_model=List[IncotermResponsibilityResponse],
)
def get_matrix(incoterm_id: int, db: Session = Depends(get_db)):
    try:
        return get_matrix_for_incoterm_service(db, incoterm_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@incoterms_router.put(
    "/incoterm-responsibilities/{responsibility_id}",
    response_model=IncotermResponsibilityResponse,
)
def update_responsibility(
    responsibility_id: int,
    data: IncotermResponsibilityUpdate,
    db: Session = Depends(get_db),
):
    try:
        return update_responsibility_service(db, responsibility_id, data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@incoterms_router.delete(
    "/incoterm-responsibilities/{responsibility_id}",
    response_model=IncotermResponsibilityResponse,
)
def delete_responsibility(responsibility_id: int, db: Session = Depends(get_db)):
    return delete_responsibility_service(db, responsibility_id)
