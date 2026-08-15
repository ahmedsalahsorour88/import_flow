from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from database.database import get_db

from .schemas import (
    DemurragePolicyCreate,
    DemurragePolicyUpdate,
    DemurragePolicyResponse,
    DemurrageTrackingCreate,
    DemurrageTrackingUpdate,
    DemurrageTrackingResponse,
    DemurrageSimulationRequest,
    DemurrageSimulationResponse,
    PushToSettlementRequest,
)
from .service import (
    simulate_demurrage_and_detention,
    create_demurrage_policy_service,
    get_demurrage_policies_service,
    get_demurrage_policy_by_id_service,
    update_demurrage_policy_service,
    delete_demurrage_policy_service,
    create_demurrage_tracking_service,
    get_demurrage_trackings_service,
    get_demurrage_tracking_by_id_service,
    recalculate_and_update_tracking_service,
    push_demurrage_to_financial_settlement_service,
)

router = APIRouter(prefix="/api/v1/demurrage-detention", tags=["Demurrage & Detention Engine"])


# ----------------------------------------------------
# Interactive Simulator Endpoint
# ----------------------------------------------------

@router.post("/simulate", response_model=DemurrageSimulationResponse, summary="محاكي حساب غرامات وفترات سماح الحاويات والأرضيات")
def simulate_demurrage_endpoint(req: DemurrageSimulationRequest):
    return simulate_demurrage_and_detention(req)


# ----------------------------------------------------
# Carrier Tariff Policies Endpoints
# ----------------------------------------------------

@router.post("/policies", response_model=DemurragePolicyResponse, status_code=status.HTTP_201_CREATED, summary="إنشاء سياسة تعريفة غرامات لخط ملاحي")
def create_policy_endpoint(req: DemurragePolicyCreate, db: Session = Depends(get_db)):
    return create_demurrage_policy_service(db, req)


@router.get("/policies", response_model=List[DemurragePolicyResponse], summary="استعراض سياسات غرامات الخطوط الملاحية")
def get_policies_endpoint(
    carrier_name: Optional[str] = Query(None, description="تصفية باسم الخط الملاحي"),
    container_type: Optional[str] = Query(None, description="تصفية بنوع الحاوية"),
    db: Session = Depends(get_db),
):
    return get_demurrage_policies_service(db, carrier_name=carrier_name, container_type=container_type)


@router.get("/policies/{policy_id}", response_model=DemurragePolicyResponse, summary="جلب تفاصيل سياسة غرامات محددة")
def get_policy_by_id_endpoint(policy_id: int, db: Session = Depends(get_db)):
    return get_demurrage_policy_by_id_service(db, policy_id)


@router.put("/policies/{policy_id}", response_model=DemurragePolicyResponse, summary="تعديل سياسة غرامات خط ملاحي")
def update_policy_endpoint(policy_id: int, req: DemurragePolicyUpdate, db: Session = Depends(get_db)):
    return update_demurrage_policy_service(db, policy_id, req)


@router.delete("/policies/{policy_id}", response_model=DemurragePolicyResponse, summary="حذف سياسة غرامات (Soft Delete)")
def delete_policy_endpoint(policy_id: int, db: Session = Depends(get_db)):
    return delete_demurrage_policy_service(db, policy_id)


# ----------------------------------------------------
# Container Tracking Sessions Endpoints
# ----------------------------------------------------

@router.post("/trackings", response_model=DemurrageTrackingResponse, status_code=status.HTTP_201_CREATED, summary="إنشاء جلسة تتبع حاويات وحساب غرامات")
def create_tracking_endpoint(req: DemurrageTrackingCreate, db: Session = Depends(get_db)):
    return create_demurrage_tracking_service(db, req)


@router.get("/trackings", response_model=List[DemurrageTrackingResponse], summary="استعراض جلسات تتبع الحاويات")
def get_trackings_endpoint(
    import_file_id: Optional[int] = Query(None, description="تصفية برقم ملف الاستيراد"),
    carrier_name: Optional[str] = Query(None, description="تصفية باسم الخط الملاحي"),
    status: Optional[str] = Query(None, description="تصفية بالحالة"),
    db: Session = Depends(get_db),
):
    return get_demurrage_trackings_service(db, import_file_id=import_file_id, carrier_name=carrier_name, status_filter=status)


@router.get("/trackings/{tracking_id}", response_model=DemurrageTrackingResponse, summary="جلب تفاصيل جلسة تتبع حاويات")
def get_tracking_by_id_endpoint(tracking_id: int, db: Session = Depends(get_db)):
    return get_demurrage_tracking_by_id_service(db, tracking_id)


@router.put("/trackings/{tracking_id}", response_model=DemurrageTrackingResponse, summary="تحديث وإعادة حساب جلسة تتبع حاويات")
def update_tracking_endpoint(tracking_id: int, req: DemurrageTrackingUpdate, db: Session = Depends(get_db)):
    return recalculate_and_update_tracking_service(db, tracking_id, req)


@router.post("/trackings/push-to-settlement", summary="ترحيل الغرامات تلقائياً إلى فواتير التسوية المالية Landed Cost")
def push_to_settlement_endpoint(req: PushToSettlementRequest, db: Session = Depends(get_db)):
    return push_demurrage_to_financial_settlement_service(db, req)
