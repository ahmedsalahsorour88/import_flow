"""
FastAPI Router for Smart Email Listener (INT-EMAIL-010)
"""

from typing import List
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from database.database import get_db

from .schemas import (
    InboundEmailCreate,
    InboundEmailParsePreviewRequest,
    ArrivalNoticeParseResult,
    InboundEmailLogResponse,
)
from .service import (
    process_inbound_email_service,
    preview_arrival_notice_service,
)
from . import repository

router = APIRouter(prefix="/api/v1/smart-email", tags=["Smart Email Listener (INT-EMAIL-010)"])


@router.post(
    "/incoming",
    response_model=ArrivalNoticeParseResult,
    status_code=status.HTTP_201_CREATED,
    summary="استلام ومعالجة إيميل إشعار وصول واستخراج البوليصة وتوليد مهمة السداد",
)
def process_incoming_email_endpoint(req: InboundEmailCreate, db: Session = Depends(get_db)):
    return process_inbound_email_service(db, req)


@router.post(
    "/parse-preview",
    response_model=ArrivalNoticeParseResult,
    summary="معاينة فورية لاستخراج بيانات إشعار الوصول بدون تسجيل في قاعدة البيانات",
)
def preview_email_parse_endpoint(req: InboundEmailParsePreviewRequest):
    return preview_arrival_notice_service(req)


@router.get(
    "/logs",
    response_model=List[InboundEmailLogResponse],
    summary="جلب سجل الإيميلات الواردة والمعالجة",
)
def get_email_logs_endpoint(
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    logs = repository.get_email_logs(db, limit=limit, offset=offset)
    return logs


@router.get(
    "/logs/{email_id}",
    response_model=InboundEmailLogResponse,
    summary="جلب تفاصيل إيميل وارد ومعالج محدد",
)
def get_email_log_detail_endpoint(email_id: int, db: Session = Depends(get_db)):
    log = repository.get_email_log_by_id(db, email_id)
    if not log:
        from fastapi import HTTPException
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="سجل الإيميل غير موجود.")
    return log
