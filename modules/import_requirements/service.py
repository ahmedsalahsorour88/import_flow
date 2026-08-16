from datetime import datetime, timezone
from sqlalchemy.orm import Session
from modules.import_requirements.schemas import (
    ImportRequirementCreate,
    ImportRequirementUpdate,
    ImportRequirementPrefillResponse,
    ImportRequirementHSCodeItem,
)
from modules.import_requirements import repository as repo
from modules.import_requirements.validators import validate_risk_level, validate_overall_status, validate_shipment_value
from modules.import_files.model import ImportFile
from modules.purchase_orders.model import PurchaseOrder
from modules.suppliers.model import Supplier
from modules.customs_consultation.model import CustomsConsultationSession
from modules.customs_tariff.model import CustomsTariff


def create_assessment_service(db: Session, payload: ImportRequirementCreate):
    validate_risk_level(payload.risk_level)
    validate_overall_status(payload.overall_status)
    validate_shipment_value(payload.shipment_value_usd)
    
    # Rule: Prevent duplicate assessment for the same Import File
    if payload.import_file_id:
        existing = repo.get_assessment_by_import_file(db, payload.import_file_id)
        if existing:
            file_code = payload.import_file_code or str(payload.import_file_id)
            raise ValueError(
                f"يوجد بالفعل دراسة تقييم متطلبات استيرادية نشطة للملف الاستيرادي #{file_code} (كود التقييم: {existing.assessment_code}). يمكنك تعديل التقييم القائم بدلاً من إنشاء تقييم جديد."
            )

    code = repo.generate_assessment_code(db)
    obj_data = payload.model_dump()
    obj_data["assessment_code"] = code
    obj_data["created_at"] = datetime.now(timezone.utc)
    obj_data["updated_at"] = datetime.now(timezone.utc)
    return repo.create_assessment(db, obj_data)


def update_assessment_service(db: Session, assessment_id: int, payload: ImportRequirementUpdate):
    update_data = {k: v for k, v in payload.model_dump().items() if v is not None}
    if "risk_level" in update_data:
        validate_risk_level(update_data["risk_level"])
    if "overall_status" in update_data:
        validate_overall_status(update_data["overall_status"])
    if "shipment_value_usd" in update_data:
        validate_shipment_value(update_data["shipment_value_usd"])
    update_data["updated_at"] = datetime.now(timezone.utc)
    return repo.update_assessment(db, assessment_id, update_data)


def restore_assessment_service(db: Session, assessment_id: int):
    return repo.restore_assessment(db, assessment_id)


def get_import_file_prefill_service(db: Session, import_file_id: int) -> ImportRequirementPrefillResponse:
    """
    Extracts all shipment, supplier, ACID, HS Codes with individual values/currencies,
    and 5-pillar compliance findings from the linked Import File, PO line items, and Customs Consultation.
    """
    import_file = db.query(ImportFile).filter(ImportFile.import_file_id == import_file_id).first()
    if not import_file:
        raise ValueError(f"Import File #{import_file_id} not found.")

    currency = import_file.estimated_cost_currency or "USD"
    total_val = float(import_file.estimated_cost or 0.0)

    # Supplier Info
    country_of_origin = "China"
    foreign_exporter_id = None
    supp = None
    if import_file.supplier_id:
        supp = db.query(Supplier).filter(Supplier.supplier_id == import_file.supplier_id).first()
        if supp:
            country_of_origin = supp.foreign_exporter_country or "China"
            foreign_exporter_id = supp.foreign_exporter_id

    # Search for linked Customs Consultation Session
    consultation = (
        db.query(CustomsConsultationSession)
        .filter(CustomsConsultationSession.import_file_id == import_file_id)
        .order_by(CustomsConsultationSession.consultation_id.desc())
        .first()
    )

    # Initialize 5 Pillars
    decree_43 = False
    white_list_req = False
    white_list_ver = False
    factory_reg_no = foreign_exporter_id
    coo_req = False
    coo_type = "EUR.1 (الشراكة الأوروبية / إفتا / تركيا)"
    coo_status = "Not Required"
    coo_notes = None
    insp_req = False
    insp_body = "SGS"
    insp_status = "Not Required"
    insp_notes = None
    permit_req = False
    permit_auth = "جهاز شئون البيئة (EEAA)"
    permit_status = "Not Required"
    permit_notes = None
    msds_req = False
    msds_status = "Not Required"
    halal_req = False
    halal_status = "Not Required"
    coa_req = False
    coa_status = "Not Required"
    special_notes = None
    primary_hs_code = None
    primary_commodity_desc = None

    if consultation:
        for item in consultation.checklist_items:
            doc_lower = (item.document_type or "").lower()
            agency = item.regulatory_agency or ""
            status = item.status or "Pending"
            remarks = item.remarks or ""

            if item.hs_code and not primary_hs_code:
                primary_hs_code = item.hs_code

            # Pillar 1: Decree 43 / GOEIC Factory Registration
            if "43" in doc_lower or "مصانع" in doc_lower or "goeic" in doc_lower or "هيئة الرقابة" in agency:
                decree_43 = True
                white_list_req = True
                if status in ["Verified", "Approved", "Received"]:
                    white_list_ver = True

            # Pillar 2: Certificate of Origin
            if "origin" in doc_lower or "منشأ" in doc_lower or "eur.1" in doc_lower or "coo" in doc_lower:
                coo_req = True
                coo_type = item.document_type
                coo_status = status
                coo_notes = remarks

            # Pillar 3: Pre-Shipment Inspection Certificate
            if "inspection" in doc_lower or "فحص" in doc_lower or "مطابقة" in doc_lower or "sgs" in doc_lower:
                insp_req = True
                insp_body = agency or "SGS"
                insp_status = status
                insp_notes = remarks

            # Pillar 4: Regulatory Permits & Approvals
            if "permit" in doc_lower or "موافقة" in doc_lower or "تصريح" in doc_lower or "eeaa" in doc_lower or "بيئة" in agency or "دواء" in agency:
                permit_req = True
                permit_auth = agency or "جهاز شئون البيئة (EEAA)"
                permit_status = status
                permit_notes = remarks

            # Pillar 5: Technical / Special (MSDS / Halal / COA)
            if "msds" in doc_lower or "safety" in doc_lower or "أمان" in doc_lower:
                msds_req = True
                msds_status = status
                special_notes = remarks
            if "halal" in doc_lower or "حلال" in doc_lower:
                halal_req = True
                halal_status = status
                special_notes = remarks
            if "coa" in doc_lower or "تحليل" in doc_lower:
                coa_req = True
                coa_status = status
                special_notes = remarks

    # -------------------------------------------------------------
    # Extract All Linked HS Codes with Values and Currencies from POs & Invoices
    # -------------------------------------------------------------
    hs_code_items_dict = {}

    # 1. Fetch Purchase Orders linked to this import file
    pos = (
        db.query(PurchaseOrder)
        .filter(PurchaseOrder.import_file_id == import_file_id, PurchaseOrder.is_active == True)
        .all()
    )
    if not pos and getattr(import_file, "po_ids", None):
        pos = (
            db.query(PurchaseOrder)
            .filter(PurchaseOrder.po_id.in_(import_file.po_ids), PurchaseOrder.is_active == True)
            .all()
        )
    if not pos and getattr(import_file, "po_number", None):
        po_by_num = (
            db.query(PurchaseOrder)
            .filter(PurchaseOrder.po_number == import_file.po_number, PurchaseOrder.is_active == True)
            .first()
        )
        if po_by_num:
            pos = [po_by_num]

    po_calculated_total = 0.0
    for po in pos:
        po_curr = po.currency.currency_code if po.currency else currency
        for line in po.line_items:
            tariff = line.tariff
            hs = (tariff.hs_code if tariff else line.item_code) or "General"
            desc = line.description_ar or (tariff.hs_description if tariff else line.description_en) or "صنف مستورد"
            item_val = float(line.total_price or 0.0)
            if item_val == 0.0:
                item_val = float((line.unit_price or 0.0) * (line.quantity or 1.0))
            po_calculated_total += item_val

            origin = line.country_of_origin or po.country_of_origin or country_of_origin

            if hs in hs_code_items_dict:
                hs_code_items_dict[hs]["item_value"] += item_val
                hs_code_items_dict[hs]["quantity"] += float(line.quantity or 0.0)
            else:
                hs_code_items_dict[hs] = {
                    "hs_code": hs,
                    "commodity_description": desc,
                    "item_code": line.item_code or f"ITEM-{len(hs_code_items_dict)+1:02d}",
                    "country_of_origin": origin,
                    "currency": po_curr,
                    "item_value": item_val,
                    "quantity": float(line.quantity or 1.0),
                    "unit_of_measure": line.unit_of_measure or "PCS",
                    "decree_43_applicable": decree_43,
                    "coo_required": bool(tariff.requires_coo) if tariff else coo_req,
                    "inspection_required": bool(tariff.requires_inspection) if tariff else insp_req,
                    "permit_required": bool(tariff.regulatory_authority) if tariff else permit_req,
                    "regulatory_authority": tariff.regulatory_authority if (tariff and tariff.regulatory_authority) else (permit_auth if permit_req else None),
                }

    # 2. Extract from Invoices Data if no PO line items found or additional items exist
    if import_file.invoices_data and len(import_file.invoices_data) > 0:
        inv_sum = 0.0
        for inv in import_file.invoices_data:
            hs = inv.get("hs_code") or inv.get("item_code") or primary_hs_code
            val = float(inv.get("amount", 0.0))
            inv_sum += val
            curr = inv.get("currency") or currency
            if hs:
                if hs in hs_code_items_dict:
                    if hs_code_items_dict[hs]["item_value"] == 0.0:
                        hs_code_items_dict[hs]["item_value"] = val
                else:
                    tariff = db.query(CustomsTariff).filter(CustomsTariff.hs_code == hs).first()
                    hs_code_items_dict[hs] = {
                        "hs_code": hs,
                        "commodity_description": inv.get("description") or (tariff.hs_description if tariff else hs),
                        "item_code": inv.get("item_code") or f"ITEM-{len(hs_code_items_dict)+1:02d}",
                        "country_of_origin": country_of_origin,
                        "currency": curr,
                        "item_value": val,
                        "quantity": 1.0,
                        "unit_of_measure": "LOT",
                        "decree_43_applicable": decree_43,
                        "coo_required": bool(tariff.requires_coo) if tariff else coo_req,
                        "inspection_required": bool(tariff.requires_inspection) if tariff else insp_req,
                        "permit_required": bool(tariff.regulatory_authority) if tariff else permit_req,
                        "regulatory_authority": tariff.regulatory_authority if (tariff and tariff.regulatory_authority) else (permit_auth if permit_req else None),
                    }
        if total_val == 0.0:
            total_val = inv_sum

    if po_calculated_total > 0.0:
        total_val = po_calculated_total
        if pos and pos[0].currency:
            currency = pos[0].currency.currency_code

    # 3. Fallback if still empty
    if not hs_code_items_dict:
        fallback_hs = primary_hs_code or "8415820010"
        tariff = db.query(CustomsTariff).filter(CustomsTariff.hs_code == fallback_hs).first()
        hs_code_items_dict[fallback_hs] = {
            "hs_code": fallback_hs,
            "commodity_description": primary_commodity_desc or (tariff.hs_description if tariff else "آلات وأجهزة تكييف ووحدات تبريد"),
            "item_code": "ITEM-01",
            "country_of_origin": country_of_origin,
            "currency": currency,
            "item_value": total_val,
            "quantity": 1.0,
            "unit_of_measure": "LOT",
            "decree_43_applicable": decree_43,
            "coo_required": bool(tariff.requires_coo) if tariff else coo_req,
            "inspection_required": bool(tariff.requires_inspection) if tariff else insp_req,
            "permit_required": bool(tariff.regulatory_authority) if tariff else permit_req,
            "regulatory_authority": tariff.regulatory_authority if (tariff and tariff.regulatory_authority) else permit_auth,
        }

    hs_code_items_list = [
        ImportRequirementHSCodeItem(**item_data)
        for item_data in hs_code_items_dict.values()
    ]

    # Select primary HS Code & description
    if hs_code_items_list:
        primary_hs_code = hs_code_items_list[0].hs_code
        primary_commodity_desc = hs_code_items_list[0].commodity_description
        if not total_val or total_val == 0.0:
            total_val = sum(i.item_value for i in hs_code_items_list)
        currency = hs_code_items_list[0].currency

    return ImportRequirementPrefillResponse(
        import_file_id=import_file.import_file_id,
        import_file_code=import_file.import_file_code,
        importer_name=import_file.company_name,
        supplier_id=import_file.supplier_id,
        supplier_name=import_file.supplier_name,
        country_of_origin=country_of_origin,
        foreign_exporter_id=foreign_exporter_id,
        currency=currency,
        shipment_value=total_val,
        po_number=import_file.po_number,
        pi_number=import_file.pi_number,
        acid_number=import_file.acid_number,
        hs_code=primary_hs_code,
        commodity_description=primary_commodity_desc,
        hs_code_items=hs_code_items_list,
        consultation_id=consultation.consultation_id if consultation else None,
        consultation_code=consultation.consultation_code if consultation else None,
        broker_name=consultation.broker_name if consultation else None,
        consultation_status=consultation.overall_status if consultation else None,
        readiness_percentage=consultation.readiness_percentage if consultation else 0.0,
        decree_43_applicable=decree_43,
        white_list_required=white_list_req,
        white_list_verified=white_list_ver,
        factory_registration_no=factory_reg_no,
        coo_required=coo_req,
        coo_type=coo_type,
        coo_status=coo_status,
        coo_notes=coo_notes,
        inspection_required=insp_req,
        inspection_body=insp_body,
        inspection_status=insp_status,
        inspection_notes=insp_notes,
        import_permit_required=permit_req,
        permit_issuing_authority=permit_auth,
        permit_status=permit_status,
        permit_notes=permit_notes,
        msds_required=msds_req,
        msds_status=msds_status,
        halal_cert_required=halal_req,
        halal_cert_status=halal_status,
        coa_required=coa_req,
        coa_status=coa_status,
        special_notes=special_notes,
    )

