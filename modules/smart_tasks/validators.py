"""
Business Validators for Smart Tasks Module
"""

from fastapi import HTTPException, status
from modules.smart_tasks.schemas import SmartTaskCreate, SmartTaskUpdate


def validate_task_create(schema: SmartTaskCreate):
    if not schema.title or not schema.title.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="عنوان المهمة مطلوب ولا يمكن ترك فارغاً.",
        )
