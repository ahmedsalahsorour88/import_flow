"""
Repository for Inbound Email Logs & Smart Task Generation (INT-EMAIL-010)
"""

from typing import List, Optional
from datetime import datetime, timezone, date
from sqlalchemy.orm import Session
from sqlalchemy import desc

from .model import InboundEmailLog
from modules.import_files.model import ImportFile
from modules.smart_tasks.model import SmartTask


def create_email_log(db: Session, data: dict, user: str = "SmartEmailListener") -> InboundEmailLog:
    log = InboundEmailLog(
        sender_email=data.get("sender_email", ""),
        subject=data.get("subject", ""),
        body_text=data.get("body_text", ""),
        email_type=data.get("email_type", "Arrival Notice"),
        extracted_bl_number=data.get("extracted_bl_number"),
        extracted_eta=data.get("extracted_eta"),
        extracted_vessel=data.get("extracted_vessel"),
        extracted_voyage=data.get("extracted_voyage"),
        extracted_containers=data.get("extracted_containers"),
        import_file_id=data.get("import_file_id"),
        processing_status=data.get("processing_status", "Processed"),
        task_id=data.get("task_id"),
        notes=data.get("notes"),
        created_by=user,
    )
    db.add(log)
    db.commit()
    db.refresh(log)
    return log


def get_email_logs(db: Session, limit: int = 50, offset: int = 0) -> List[InboundEmailLog]:
    return (
        db.query(InboundEmailLog)
        .filter(InboundEmailLog.is_active == True)
        .order_by(desc(InboundEmailLog.received_at))
        .offset(offset)
        .limit(limit)
        .all()
    )


def get_email_log_by_id(db: Session, email_id: int) -> Optional[InboundEmailLog]:
    return (
        db.query(InboundEmailLog)
        .filter(InboundEmailLog.email_id == email_id, InboundEmailLog.is_active == True)
        .first()
    )


def find_import_file_by_bl(db: Session, bl_number: str) -> Optional[ImportFile]:
    if not bl_number:
        return None
    clean_bl = bl_number.strip().upper()

    # 1. Search in CustomsDeclarationDraft
    from modules.import_documentation.model import CustomsDeclarationDraft, DraftBLReviewSession
    decl = (
        db.query(CustomsDeclarationDraft)
        .filter(
            CustomsDeclarationDraft.is_active == True,
            CustomsDeclarationDraft.bl_number.ilike(f"%{clean_bl}%"),
            CustomsDeclarationDraft.import_file_id.isnot(None),
        )
        .first()
    )
    if decl and decl.import_file_id:
        file = db.query(ImportFile).filter(ImportFile.import_file_id == decl.import_file_id).first()
        if file:
            return file

    # 2. Search in DraftBLReviewSession
    bl_rev = (
        db.query(DraftBLReviewSession)
        .filter(
            DraftBLReviewSession.is_active == True,
            DraftBLReviewSession.draft_bl_number.ilike(f"%{clean_bl}%"),
            DraftBLReviewSession.import_file_id.isnot(None),
        )
        .first()
    )
    if bl_rev and bl_rev.import_file_id:
        file = db.query(ImportFile).filter(ImportFile.import_file_id == bl_rev.import_file_id).first()
        if file:
            return file

    # 3. Search in CargoXEnvelope
    from modules.cargox.model import CargoXEnvelope
    envelope = (
        db.query(CargoXEnvelope)
        .filter(
            CargoXEnvelope.is_active == True,
            CargoXEnvelope.bl_number.ilike(f"%{clean_bl}%"),
            CargoXEnvelope.import_file_id.isnot(None),
        )
        .first()
    )
    if envelope and envelope.import_file_id:
        file = db.query(ImportFile).filter(ImportFile.import_file_id == envelope.import_file_id).first()
        if file:
            return file

    # 4. Fallback search on ImportFile notes or custom_file_number
    return (
        db.query(ImportFile)
        .filter(
            ImportFile.is_active == True,
            (ImportFile.custom_file_number.ilike(f"%{clean_bl}%"))
            | (ImportFile.notes.ilike(f"%{clean_bl}%")),
        )
        .first()
    )


def update_import_file_eta(db: Session, import_file_id: int, new_eta: date) -> Optional[ImportFile]:
    file = db.query(ImportFile).filter(ImportFile.import_file_id == import_file_id).first()
    if file:
        file.required_eta = new_eta
        file.updated_at = datetime.now(timezone.utc)

        # Also update linked ShipmentBooking if exists
        from modules.freight_booking.model import ShipmentBooking
        booking = db.query(ShipmentBooking).filter(ShipmentBooking.import_file_id == import_file_id).first()
        if booking:
            booking.eta = datetime.combine(new_eta, datetime.min.time())
            booking.updated_at = datetime.now(timezone.utc)

        db.commit()
        db.refresh(file)
    return file


def create_delivery_order_payment_task(
    db: Session, import_file: ImportFile, bl_number: str, eta_date: Optional[date]
) -> SmartTask:
    task_count = db.query(SmartTask).count() + 1
    task_code = f"TSK-ARV-{task_count:05d}"
    due_str = eta_date.isoformat() if eta_date else (date.today()).isoformat()

    title = f"سداد مصاريف إذن التسليم للشحنة ({import_file.import_file_code})"
    desc = (
        f"تم رصد إشعار وصول رسمي (Arrival Notice) للبوليصة [{bl_number}]. "
        f"مطلوب المتابعة الفورية مع التوكيل الملاحي لسداد مصاريف إذن التسليم "
        f"والعوائد المينائية قبل وصول السفينة المتوقع بتاريخ {due_str} لتفادي أي غرامات تأخير أو أرضيات."
    )

    task = SmartTask(
        task_code=task_code,
        title=title,
        description=desc,
        task_type="System Generated",
        import_file_id=import_file.import_file_id,
        import_file_code=import_file.import_file_code,
        phase_name="Shipping & Transit",
        assigned_user="Finance Team",
        priority="High",
        reminder_type="Arrival Notice Payment",
        due_date=due_str,
        reminder_date=due_str,
        status="Pending",
        notes=f"تم التوليد التلقائي عبر المستمع الذكي للإيميلات INT-EMAIL-010 للبوليصة: {bl_number}",
        created_by="SmartEmailListener",
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return task
