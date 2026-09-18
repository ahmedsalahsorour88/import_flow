from fastapi import HTTPException
from sqlalchemy.orm import Session
from modules.import_files.model import ImportFile
from .schemas import InlandTransportBookingCreate

def validate_transport_booking_input(schema: InlandTransportBookingCreate):
    if not schema.truck_plate_number or len(schema.truck_plate_number.strip()) < 2:
        raise HTTPException(
            status_code=400,
            detail="رقم لوحة الشاحنة مطلوب ويجب ألا يقل عن حرفين/رقمين.",
        )
    if not schema.driver_name or len(schema.driver_name.strip()) < 2:
        raise HTTPException(
            status_code=400,
            detail="اسم السائق مطلوب ويجب ألا يقل عن حرفين.",
        )
    if not schema.driver_phone or len(schema.driver_phone.strip()) < 5:
        raise HTTPException(
            status_code=400,
            detail="رقم هاتف السائق غير صالح.",
        )
    if not schema.waybill_number or len(schema.waybill_number.strip()) < 2:
        raise HTTPException(
            status_code=400,
            detail="رقم بوليصة النقل البري / إذن التحميل مطلوب.",
        )
    if schema.expected_arrival_at < schema.planned_departure_at:
        raise HTTPException(
            status_code=400,
            detail="تاريخ وموعد الوصول المتوقع لا يمكن أن يسبق موعد التحميل والمغادرة المخطط.",
        )

def validate_import_file_for_transport(db: Session, import_file_id: int) -> ImportFile:
    imp_file = (
        db.query(ImportFile)
        .filter(ImportFile.import_file_id == import_file_id, ImportFile.is_active == True)
        .first()
    )
    if not imp_file:
        raise HTTPException(
            status_code=404,
            detail=f"ملف الشحنة رقم {import_file_id} غير موجود أو غير نشط.",
        )
    return imp_file
