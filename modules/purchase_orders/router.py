from typing import List, Optional

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from database.database import get_db
from modules.purchase_orders.schemas import PurchaseOrderCreate, PurchaseOrderResponse, PurchaseOrderUpdate
from modules.purchase_orders.service import PurchaseOrderService

router = APIRouter(
    prefix="/api/v1/purchase-orders",
    tags=["Purchase Orders"],
)


@router.get("", response_model=List[PurchaseOrderResponse])
def get_purchase_orders(
    include_inactive: bool = Query(False),
    status_filter: Optional[str] = Query(None, alias="status"),
    project_id: Optional[int] = Query(None),
    company_id: Optional[int] = Query(None),
    supplier_id: Optional[int] = Query(None),
    search: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    service = PurchaseOrderService(db)
    return service.get_all(
        include_inactive=include_inactive,
        status_filter=status_filter,
        project_id=project_id,
        company_id=company_id,
        supplier_id=supplier_id,
        search=search,
    )


@router.get("/{po_id}", response_model=PurchaseOrderResponse)
def get_purchase_order(po_id: int, db: Session = Depends(get_db)):
    service = PurchaseOrderService(db)
    return service.get_by_id(po_id)


@router.post("", response_model=PurchaseOrderResponse, status_code=status.HTTP_201_CREATED)
def create_purchase_order(data: PurchaseOrderCreate, db: Session = Depends(get_db)):
    service = PurchaseOrderService(db)
    return service.create(data)


@router.put("/{po_id}", response_model=PurchaseOrderResponse)
def update_purchase_order(po_id: int, data: PurchaseOrderUpdate, db: Session = Depends(get_db)):
    service = PurchaseOrderService(db)
    return service.update(po_id, data)


@router.delete("/{po_id}", response_model=PurchaseOrderResponse)
def delete_purchase_order(po_id: int, db: Session = Depends(get_db)):
    service = PurchaseOrderService(db)
    return service.soft_delete(po_id)


@router.post("/{po_id}/restore", response_model=PurchaseOrderResponse)
def restore_purchase_order(po_id: int, db: Session = Depends(get_db)):
    service = PurchaseOrderService(db)
    return service.restore(po_id)
