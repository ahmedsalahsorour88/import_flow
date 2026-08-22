"""
Production Sync Validators
"""
from pathlib import Path
from fastapi import HTTPException, status


def validate_db_exists(db_path: Path, db_label: str = "Database") -> None:
    if not db_path.exists():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"ملف قاعدة البيانات ({db_label}) غير موجود في المسار: {db_path}",
        )


def validate_sync_action(action: str) -> None:
    allowed = ["PUSH_TO_PROD", "PULL_TO_DEV", "BACKUP_DEV", "BACKUP_PROD"]
    if action not in allowed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"نوع عملية المزامنة غير مدعوم: {action}. العمليات المتاحة: {', '.join(allowed)}",
        )
