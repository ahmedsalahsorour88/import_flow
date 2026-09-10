"""
Validators for Smart Email Listener (INT-EMAIL-010)
"""

from fastapi import HTTPException, status


def validate_email_payload(sender_email: str, subject: str, body_text: str):
    if not sender_email or "@" not in sender_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="عنوان البريد الإلكتروني للمرسل غير صالح.",
        )
    if not subject or len(subject.strip()) < 3:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="عنوان موضوع الإيميل مطلوب ويجب ألا يقل عن 3 أحرف.",
        )
    if not body_text or len(body_text.strip()) < 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="محتوى نص الإيميل فارغ أو قصير جداً للتحليل والاستخراج.",
        )
