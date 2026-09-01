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


def sync_regulatory_tasks_and_alerts(db: Session, assessment_id: int):
    """
    Business Rule & Smart Tasks Sync:
    1. Identify all uncompleted/pending regulatory requirements across the 5 pillars.
    2. Generate/Update Smart Tasks for incomplete regulatory requirements for this Import File (linking ACID if present).
    3. Auto-close tasks if requirements become Verified/Approved.
    4. Auto-update ImportFile next_action and stage progression.
    """
    assessment = repo.get_assessment_by_id(db, assessment_id)
    if not assessment:
        return

    import_file = None
    if assessment.import_file_id:
        import_file = db.query(ImportFile).filter(ImportFile.import_file_id == assessment.import_file_id).first()

    file_code = assessment.import_file_code or (import_file.import_file_code if import_file else f"FILE-{assessment.import_file_id}")
    acid_str = assessment.acid_number or (import_file.acid_number if import_file else None) or "قيد الإصدار لاحقاً"

    # If import_file has an acid_number but assessment doesn't, sync it
    if import_file and import_file.acid_number and not assessment.acid_number:
        assessment.acid_number = import_file.acid_number
        db.commit()

    # Identify uncompleted / pending items
    uncompleted = []
    completed = []

    # 1. Decree 43
    if assessment.decree_43_applicable:
        if not assessment.white_list_verified:
            uncompleted.append({
                "type": "Decree43",
                "title": f"[{file_code}] [ACID: {acid_str}] توثيق قيد المصنع/المورد الأجنبي بالهيئة العامة للرقابة على الصادرات والواردات (قرار 43)",
                "desc": "السلعة تخضع للقرار الوزاري 43 لسنة 2016 ويلزم التحقق من قيد المصنع بالقائمة البيضاء لدى GOEIC قبل الشحن",
                "priority": "Critical",
            })
        else:
            completed.append("Decree43")

    # 2. Certificate of Origin
    if assessment.coo_required:
        if assessment.coo_status not in ["Verified", "Approved", "Received", "Obtained"]:
            uncompleted.append({
                "type": "COO",
                "title": f"[{file_code}] [ACID: {acid_str}] استيفاء شهادة المنشأ ({assessment.coo_type or 'COO'}) وتوثيقها رسمياً",
                "desc": f"يلزم استلام وتوثيق شهادة المنشأ الأصلية لتطبيق المعاملات التفضيلية والإفراج الجمركي - الحالة الحالية: {assessment.coo_status}",
                "priority": "High",
            })
        else:
            completed.append("COO")

    # 3. Pre-Shipment Inspection
    if assessment.inspection_required:
        if assessment.inspection_status not in ["Verified", "Approved", "Received", "Completed", "Obtained"]:
            uncompleted.append({
                "type": "Inspection",
                "title": f"[{file_code}] [ACID: {acid_str}] إصدار شهادة الفحص المسبق قبل الشحن ({assessment.inspection_body or 'SGS/CIQ'})",
                "desc": f"الصنف يخضع للفحص الفني الإلزامي قبل الشحن من بلد المنشأ بواسطة {assessment.inspection_body or 'جهة الفحص المعين'}",
                "priority": "Critical",
            })
        else:
            completed.append("Inspection")

    # 4. Import Permit / Regulatory Approvals
    if assessment.import_permit_required:
        if assessment.permit_status not in ["Verified", "Approved", "Received", "Obtained"]:
            uncompleted.append({
                "type": "Permit",
                "title": f"[{file_code}] [ACID: {acid_str}] استخراج موافقة الاستيراد المسبقة من ({assessment.permit_issuing_authority or 'جهة العرض والرقابة'})",
                "desc": f"يلزم الحصول على تصريح/موافقة استيرادية رسمية من {assessment.permit_issuing_authority or 'جهة الرقابة'} قبل الشحن",
                "priority": "Critical",
            })
        else:
            completed.append("Permit")

    # 5. Technical Documents
    if assessment.msds_required:
        if assessment.msds_status not in ["Verified", "Approved", "Received", "Obtained"]:
            uncompleted.append({
                "type": "MSDS",
                "title": f"[{file_code}] [ACID: {acid_str}] استيفاء صحيفة بيانات سلامة المادة (MSDS) معتمدة ومحدثة",
                "desc": "يلزم تقديم شهادة الـ MSDS للصنف لتحديد متطلبات السلامة والتعامل المينائي والتخزين",
                "priority": "Medium",
            })
        else:
            completed.append("MSDS")

    if assessment.halal_cert_required:
        if assessment.halal_cert_status not in ["Verified", "Approved", "Received", "Obtained"]:
            uncompleted.append({
                "type": "Halal",
                "title": f"[{file_code}] [ACID: {acid_str}] استيفاء شهادة الحلال الرسمية (Halal Certificate)",
                "desc": "يلزم تقديم شهادة الحلال الصادرة من مركز معتمد من IS EG Halal",
                "priority": "High",
            })
        else:
            completed.append("Halal")

    if assessment.coa_required:
        if assessment.coa_status not in ["Verified", "Approved", "Received", "Obtained"]:
            uncompleted.append({
                "type": "COA",
                "title": f"[{file_code}] [ACID: {acid_str}] استيفاء شهادة التحليل المخبري والمطابقة للمواصفات (COA)",
                "desc": "يلزم استلام تقرير الفحص والتحليل الكيميائي/الميكانيكي من المصنع المنتج",
                "priority": "Medium",
            })
        else:
            completed.append("COA")

    # Manage SmartTasks in DB
    try:
        from modules.smart_tasks.model import SmartTask
        import modules.smart_tasks.repository as task_repo
        from modules.smart_tasks.schemas import SmartTaskCreate

        # 1. Create or ensure uncompleted tasks exist
        for item in uncompleted:
            existing_task = db.query(SmartTask).filter(
                SmartTask.import_file_id == assessment.import_file_id,
                SmartTask.notes.ilike(f"%REQ_TYPE:{item['type']}%"),
                SmartTask.is_active == True,
                SmartTask.status.in_(["Pending", "In Progress"]),
            ).first()

            if not existing_task:
                task_schema = SmartTaskCreate(
                    title=item["title"],
                    description=item["desc"],
                    task_type="Regulatory Compliance",
                    import_file_id=assessment.import_file_id,
                    import_file_code=file_code,
                    phase_name="STEP_03: اشتراطات ومتطلبات الاستيراد",
                    assigned_user=import_file.owner if import_file and import_file.owner else "Import Specialist",
                    priority=item["priority"],
                    reminder_type="Regulatory Compliance",
                    status="Pending",
                    due_date=datetime.now(timezone.utc).strftime("%Y-%m-%d"),
                    notes=f"REQ_TYPE:{item['type']} | ASSESSMENT:{assessment.assessment_code}",
                )
                task_repo.create_task(db, task_schema, created_by="Requirements Engine")
            else:
                existing_task.title = item["title"]

        # 2. Auto-close completed requirements tasks
        for c_type in completed:
            open_tasks = db.query(SmartTask).filter(
                SmartTask.import_file_id == assessment.import_file_id,
                SmartTask.notes.ilike(f"%REQ_TYPE:{c_type}%"),
                SmartTask.is_active == True,
                SmartTask.status.in_(["Pending", "In Progress"]),
            ).all()
            for t in open_tasks:
                t.status = "Completed"
                t.is_auto_closed = True

    except Exception:
        pass

    # 3. Synchronize ImportFile next action and stage activity
    if import_file:
        try:
            from modules.lifecycle_board.service import sync_requirements_lifecycle_stage
            import modules.lifecycle_board.repository as lifecycle_repo

            if len(uncompleted) == 0 and assessment.overall_status in ["Complete", "Approved", "Cleared", "Confirmed"]:
                # Complete STEP_03 and move to STEP_04
                lifecycle_repo.save_or_update_activity(
                    db,
                    import_file_code=file_code,
                    step_code="STEP_03",
                    status="Completed",
                    completed_at=datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S"),
                )
                lifecycle_repo.save_or_update_activity(
                    db,
                    import_file_code=file_code,
                    step_code="STEP_04",
                    status="In-Progress",
                    started_at=datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S"),
                )
                import_file.current_stage = "المرحلة الثانية: بداية الشحنة"
                import_file.current_module = "STEP_04: اعتمادات الميزانية وسداد الموردين"
                import_file.next_action = "استكمال سداد دفعة المورد وطلب استخراج رقم ACID (STEP_05)"
                import_file.progress_percent = max(float(import_file.progress_percent or 0), 30.0)
            else:
                # Mark STEP_01 and STEP_02 as Completed, and STEP_03 as In-Progress
                sync_requirements_lifecycle_stage(db, assessment.import_file_id)
                req_names = [r["type"] for r in uncompleted]
                req_display = ", ".join(req_names[:3]) if req_names else "مراجعة المتطلبات"
                import_file.next_action = f"استيفاء {len(uncompleted)} متطلبات رقابية معلقة ({req_display})"

            db.commit()
        except Exception:
            pass


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
    created = repo.create_assessment(db, obj_data)
    
    # Synchronize Smart Tasks and Stage Progression
    try:
        sync_regulatory_tasks_and_alerts(db, created.assessment_id)
    except Exception:
        pass

    return created


def update_assessment_service(db: Session, assessment_id: int, payload: ImportRequirementUpdate):
    update_data = {k: v for k, v in payload.model_dump().items() if v is not None}
    if "risk_level" in update_data:
        validate_risk_level(update_data["risk_level"])
    if "overall_status" in update_data:
        validate_overall_status(update_data["overall_status"])
    if "shipment_value_usd" in update_data:
        validate_shipment_value(update_data["shipment_value_usd"])
    update_data["updated_at"] = datetime.now(timezone.utc)
    updated = repo.update_assessment(db, assessment_id, update_data)
    
    # Synchronize Smart Tasks and Stage Progression
    if updated:
        try:
            sync_regulatory_tasks_and_alerts(db, updated.assessment_id)
        except Exception:
            pass

    return updated


def restore_assessment_service(db: Session, assessment_id: int):
    restored = repo.restore_assessment(db, assessment_id)
    if restored:
        try:
            sync_regulatory_tasks_and_alerts(db, restored.assessment_id)
        except Exception:
            pass
    return restored


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


def get_all_assessments_service(db: Session, import_file_id: int = None, overall_status: str = None, risk_level: str = None, search: str = None, include_inactive: bool = False):
    return repo.get_all_assessments(db, import_file_id=import_file_id, overall_status=overall_status, risk_level=risk_level, search=search, include_inactive=include_inactive)

def get_assessment_by_id_service(db: Session, assessment_id: int):
    return repo.get_assessment_by_id(db, assessment_id)

def soft_delete_assessment_service(db: Session, assessment_id: int):
    return repo.soft_delete_assessment(db, assessment_id)
