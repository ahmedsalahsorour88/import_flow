from typing import List, Optional

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from fastapi.responses import Response
from sqlalchemy.orm import Session

from database.database import get_db

from .schemas import (
    CustomsDutyBreakdown,
    CustomsDutyEstimateRequest,
    CustomsTariffCreate,
    CustomsTariffResponse,
    CustomsTariffUpdate,
    MultiItemCustomsBreakdown,
    MultiItemCustomsEstimateRequest,
    PreferentialAgreementCreate,
    PreferentialAgreementResponse,
    TariffVerificationRequest,
)
from .service import (
    bulk_import_tariffs_service,
    create_preferential_agreement_service,
    create_tariff_service,
    delete_tariff_service,
    estimate_customs_duty_service,
    estimate_multi_item_customs_duty_service,
    get_agreements_by_hs_code_service,
    get_all_tariffs_service,
    get_tariff_by_hs_code_service,
    get_tariff_by_id_service,
    restore_tariff_service,
    update_tariff_service,
    verify_and_update_tariff_service,
)

customs_tariff_router = APIRouter(prefix="/api/v1/customs-tariff", tags=["Customs Tariff"])


@customs_tariff_router.get("", response_model=List[CustomsTariffResponse])
def get_all_tariffs(
    include_inactive: bool = Query(False),
    search: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    return get_all_tariffs_service(db, include_inactive=include_inactive, search=search)


@customs_tariff_router.post("", response_model=CustomsTariffResponse)
def create_tariff(data: CustomsTariffCreate, db: Session = Depends(get_db)):
    try:
        return create_tariff_service(db, data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@customs_tariff_router.get("/", response_model=List[CustomsTariffResponse])
def list_tariffs(
    include_inactive: bool = Query(False),
    search: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    return get_all_tariffs_service(db, include_inactive=include_inactive, search=search)


@customs_tariff_router.post("/estimate", response_model=CustomsDutyBreakdown)
def estimate_customs_duty(request: CustomsDutyEstimateRequest, db: Session = Depends(get_db)):
    """
    Egyptian Customs Calculation Engine API Endpoint.
    Estimates customs duties, VAT, schedule tax, and development fees based on the HS Code.
    """
    return estimate_customs_duty_service(db, request)


@customs_tariff_router.post("/estimate-multi", response_model=MultiItemCustomsBreakdown)
def estimate_multi_item_customs_duty(
    request: MultiItemCustomsEstimateRequest, db: Session = Depends(get_db)
):
    """
    Egyptian Multi-Item Customs Calculation Engine API Endpoint.
    Estimates customs duties, VAT, schedule taxes, and grand totals for multi-item invoices based on official Nafeza specifications.
    """
    return estimate_multi_item_customs_duty_service(db, request)



@customs_tariff_router.get("/hs/{hs_code}", response_model=CustomsTariffResponse)
def get_tariff_by_hs_code(hs_code: str, db: Session = Depends(get_db)):
    return get_tariff_by_hs_code_service(db, hs_code)


@customs_tariff_router.get("/{tariff_id}", response_model=CustomsTariffResponse)
def get_tariff(tariff_id: int, db: Session = Depends(get_db)):
    return get_tariff_by_id_service(db, tariff_id)


@customs_tariff_router.put("/{tariff_id}", response_model=CustomsTariffResponse)
def update_tariff(tariff_id: int, data: CustomsTariffUpdate, db: Session = Depends(get_db)):
    try:
        return update_tariff_service(db, tariff_id, data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@customs_tariff_router.delete("/{tariff_id}", response_model=CustomsTariffResponse)
def delete_tariff(tariff_id: int, db: Session = Depends(get_db)):
    return delete_tariff_service(db, tariff_id)


@customs_tariff_router.patch("/{tariff_id}/restore", response_model=CustomsTariffResponse)
def restore_tariff(tariff_id: int, db: Session = Depends(get_db)):
    return restore_tariff_service(db, tariff_id)


@customs_tariff_router.post("/hs/{hs_code}/verify", response_model=CustomsTariffResponse)
def verify_and_update_tariff(
    hs_code: str, request: TariffVerificationRequest, db: Session = Depends(get_db)
):
    """
    تسجيل مراجعة يدوية وتحديث لبيانات البند الجمركي (Addendum 3 Workflow).
    في حال تغيير نسب الضرائب، يتم إنشاء إيراد جديد أوتوماتيكياً والحفاظ على السجل التاريخي.
    """
    return verify_and_update_tariff_service(db, hs_code, request)


@customs_tariff_router.get("/hs/{hs_code}/agreements", response_model=List[PreferentialAgreementResponse])
def get_agreements_by_hs_code(
    hs_code: str, origin_country: Optional[str] = Query(None), db: Session = Depends(get_db)
):
    """
    استرجاع الاتفاقيات التجارية التفضيلية الخاصة ببند جمركي معين.
    """
    return get_agreements_by_hs_code_service(db, hs_code, origin_country)


@customs_tariff_router.post("/agreements", response_model=PreferentialAgreementResponse)
def create_preferential_agreement(
    data: PreferentialAgreementCreate, db: Session = Depends(get_db)
):
    """
    إضافة اتفاقية تفضيلية جديدة مرتبط بدولة منشأ وبند جمركي.
    """
    return create_preferential_agreement_service(db, data)


@customs_tariff_router.post("/upload-excel")
async def upload_customs_tariffs(file: UploadFile = File(...), db: Session = Depends(get_db)):
    """
    Upload Excel/CSV file containing Nafeza/Egyptian Customs Tariffs (HS Codes) for bulk creation or update.
    """
    contents = await file.read()
    return bulk_import_tariffs_service(db, contents, file.filename or "uploaded.csv")


@customs_tariff_router.get("/export-template")
def export_customs_tariff_template():
    """
    Download sample CSV template for Egyptian Customs Tariff (MD-008).
    """
    csv_content = (
        "hs_code,hs_description,customs_category,customs_duty_rate,vat_rate,schedule_tax_rate,development_fee_rate,import_fee_rate,regulatory_authority,requires_coo,requires_inspection,requires_acid,notes\n"
        "1001.99.00,Wheat and meslin (Other than durum wheat),Agriculture & Food,0.0,0.0,0.0,0.0,0.0,GOEIC & NFSA,true,true,true,Essential Strategic Commodity\n"
        "8471.30.00,Portable laptops & notebooks,Electronics,5.0,14.0,0.0,5.0,0.0,NTRA,true,true,true,NTRA Approval Required\n"
        "8703.23.00,Passenger cars 1600cc to 2000cc,Automotive,135.0,14.0,15.0,5.5,0.0,GOEIC,true,true,true,Schedule Tax 15%\n"
    )
    return Response(
        content=csv_content,
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=customs_tariff_template.csv"},
    )


from .schemas import FeeCodeCreate, FeeCodeResponse
from .service import create_fee_code_service, get_all_fee_codes_service


@customs_tariff_router.get("/fee-codes", response_model=List[FeeCodeResponse])
def get_all_fee_codes(include_inactive: bool = Query(False), db: Session = Depends(get_db)):
    """
    استرجاع رسوم الإقرارات والنافذة الموحدة الرسمية.
    """
    return get_all_fee_codes_service(db, include_inactive)


@customs_tariff_router.post("/fee-codes", response_model=FeeCodeResponse)
def create_fee_code(data: FeeCodeCreate, db: Session = Depends(get_db)):
    """
    إضافة كود رسم جديد لقائمة تحصيل نافذة والجمارك المصرية.
    """
    return create_fee_code_service(db, data)


# ==================================================
# Smart Nafeza Text Parser & Origin Check Endpoints
# ==================================================

from .schemas import (
    SmartTariffParseRequest,
    SmartTariffParseResponse,
    TariffAgreementBulkSaveRequest,
    OriginDutyCheckRequest,
    OriginDutyCheckResponse,
)
from .service import (
    parse_smart_nafeza_tariff_text_service,
    save_tariff_with_agreements_service,
    evaluate_duty_by_origin_and_document_service,
    get_tariff_version_history_service,
)


@customs_tariff_router.post("/parse-text", response_model=SmartTariffParseResponse)
def parse_smart_nafeza_tariff_text(payload: SmartTariffParseRequest, db: Session = Depends(get_db)):
    """
    محلل وصائغ النصوص الجمركية الذكي (Smart Nafeza Tariff Text Parser).
    يقوم بتحليل نص البند المجمع المنسوخ من موقع/شيت نافذة واستخراج كود البند والوصف والضرائب والاتفاقيات،
    مع مقارنة التعديلات والإضافات والمحذوفات فورياً بالنسخة السابقة الفعالة في قاعدة البيانات.
    """
    try:
        return parse_smart_nafeza_tariff_text_service(payload.raw_text, db=db)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@customs_tariff_router.post("/with-agreements")
def save_tariff_with_agreements(payload: TariffAgreementBulkSaveRequest, db: Session = Depends(get_db)):
    """
    حفظ/تحديث البند الجمركي مع كافة الاتفاقيات التفضيلية الخاصة به مع الحفاظ الكامل على السجلات واللقطات التاريخية.
    """
    return save_tariff_with_agreements_service(db, payload)


@customs_tariff_router.post("/check-duty-for-origin", response_model=OriginDutyCheckResponse)
def check_duty_for_origin_and_document(payload: OriginDutyCheckRequest, db: Session = Depends(get_db)):
    """
    استعلام وتقييم فئة الضريبة الجمركية والتنبيهات حسب بلد المنشأ وتأكيد المستند المطلوب (EUR.1).
    """
    return evaluate_duty_by_origin_and_document_service(db, payload)


@customs_tariff_router.get("/history/{hs_code}")
def get_tariff_version_history(hs_code: str, db: Session = Depends(get_db)):
    """
    استعلام سجل تاريخ السريان والإصدارات السابقة والحالية للبند الجمركي (HS Code Tariff History).
    """
    return get_tariff_version_history_service(db, hs_code)


