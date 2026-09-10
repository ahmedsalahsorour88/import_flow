"""
Pydantic Schemas for AI Formal Letter Drafting (AI-DRAFT-014)
"""

from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict


class FormalLetterGenerateRequest(BaseModel):
    import_file_id: int = Field(..., description="معرف ملف الاستيراد المرتبط")
    template_type: str = Field(
        ...,
        description="نوع الخطاب: demurrage_extension, bank_delegation, bank_form4, customs_broker_mandate",
    )
    recipient_name: Optional[str] = Field(None, description="اسم الجهة أو التوكيل أو البنك المستلم")
    broker_name: Optional[str] = Field(None, description="اسم المخلص الجمركي المفوض")
    broker_license: Optional[str] = Field(None, description="رقم رخصة التخليص الجمركي")
    bank_name: Optional[str] = Field(None, description="اسم البنك")
    bank_branch: Optional[str] = Field(None, description="فرع البنك")
    extension_days: Optional[int] = Field(21, description="عدد أيام مهلة السماح المطلوبة")
    custom_notes: Optional[str] = Field(None, description="ملاحظات أو تعهدات إضافية تضاف لنص الخطاب")


class FormalLetterResponse(BaseModel):
    letter_id: Optional[int] = None
    letter_code: Optional[str] = None
    template_type: str
    letter_title_ar: str
    letter_body: str
    import_file_id: int
    import_file_code: str
    generated_at: str


class FormalLetterTemplateInfo(BaseModel):
    template_type: str
    title_ar: str
    title_en: str
    description_ar: str


class FormalLetterRecordResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    letter_id: int
    letter_code: str
    import_file_id: int
    template_type: str
    letter_title_ar: str
    recipient_name: Optional[str] = None
    letter_body: str
    created_at: datetime
    created_by: str
