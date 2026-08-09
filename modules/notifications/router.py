from typing import List, Optional
from fastapi import APIRouter, Depends, Query, WebSocket, WebSocketDisconnect, status
from sqlalchemy.orm import Session

from database.database import get_db
from .schemas import NotificationCreate, NotificationResponse, NotificationSummary
from .service import NotificationService
from .websocket_manager import websocket_manager

router = APIRouter(prefix="/api/v1/notifications", tags=["System Notifications & Real-Time Expiry Engine"])


@router.get("", response_model=List[NotificationResponse])
def get_notifications(
    unread_only: bool = Query(False, description="Filter unread notifications only"),
    target_role: Optional[str] = Query(None, description="Role filter (ADMIN, MANAGER, OPERATOR)"),
    severity: Optional[str] = Query(None, description="Severity filter (INFO, WARNING, CRITICAL)"),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
):
    service = NotificationService(db)
    return service.get_notifications(unread_only=unread_only, target_role=target_role, severity=severity, limit=limit)


@router.get("/summary", response_model=NotificationSummary)
def get_notification_summary(
    target_role: Optional[str] = Query(None, description="Role filter"),
    db: Session = Depends(get_db),
):
    service = NotificationService(db)
    return service.get_summary(target_role=target_role)


@router.post("", response_model=NotificationResponse, status_code=status.HTTP_201_CREATED)
async def create_notification(
    payload: NotificationCreate,
    db: Session = Depends(get_db),
):
    service = NotificationService(db)
    created = service.create_notification(payload)
    
    # Broadcast to all connected clients via WebSocket
    await websocket_manager.broadcast({
        "event": "NEW_NOTIFICATION",
        "data": {
            "notification_id": created.notification_id,
            "title": created.title,
            "message": created.message,
            "severity": created.severity,
            "category": created.category,
            "created_at": created.created_at.isoformat(),
        }
    })
    return created


@router.patch("/{notification_id}/read", response_model=NotificationResponse)
def mark_notification_as_read(
    notification_id: int,
    db: Session = Depends(get_db),
):
    service = NotificationService(db)
    updated = service.mark_read(notification_id)
    return updated


@router.post("/mark-all-read")
def mark_all_notifications_as_read(
    target_role: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    service = NotificationService(db)
    count = service.mark_all_read(target_role=target_role)
    return {"message": "All notifications marked as read", "count": count}


@router.post("/trigger-expiry-check", response_model=List[NotificationResponse])
async def trigger_expiry_check(db: Session = Depends(get_db)):
    service = NotificationService(db)
    new_notifs = service.trigger_expiry_check()
    for notif in new_notifs:
        await websocket_manager.broadcast({
            "event": "EXPIRY_ALERT",
            "data": {
                "notification_id": notif.notification_id,
                "title": notif.title,
                "message": notif.message,
                "severity": notif.severity,
                "category": notif.category,
                "created_at": notif.created_at.isoformat(),
            }
        })
    return new_notifs


@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket_manager.connect(websocket)
    try:
        while True:
            # Keep connection open and receive ping messages
            data = await websocket.receive_text()
            if data == "ping":
                await websocket.send_text('{"event": "pong"}')
    except WebSocketDisconnect:
        websocket_manager.disconnect(websocket)
