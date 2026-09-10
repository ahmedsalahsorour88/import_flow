"""
Pydantic Schemas for Smart Email Listener (INT-EMAIL-010)
"""

from datetime import datetime, date
from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict


class InboundEmailCreate(BaseModel):
    sender_email: str = Field(...)
    subject: str = Field(...)
    body_text: str = Field(..., description="نص الإيميل الكامل المستلم من التوكيل الملاحي")
    email_type: Optional[str] = "Arrival Notice"


class InboundEmailParsePreviewRequest(BaseModel):
    subject: str
    body_text: str


class ArrivalNoticeParseResult(BaseModel):
    extracted_bl_number: Optional[str] = None
    extracted_eta: Optional[date] = None
    extracted_vessel: Optional[str] = None
    extracted_voyage: Optional[str] = None
    extracted_containers: List[str] = []
    is_matched_file: bool = False
    import_file_id: Optional[int] = None
    import_file_code: Optional[str] = None
    payment_task_created: bool = False
    task_id: Optional[int] = None
    summary_message: str


class InboundEmailLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    email_id: int
    sender_email: str
    subject: str
    body_text: str
    received_at: datetime
    email_type: str
    extracted_bl_number: Optional[str] = None
    extracted_eta: Optional[date] = None
    extracted_vessel: Optional[str] = None
    extracted_voyage: Optional[str] = None
    extracted_containers: Optional[str] = None
    import_file_id: Optional[int] = None
    processing_status: str
    task_id: Optional[int] = None
    notes: Optional[str] = None
    created_at: datetime
