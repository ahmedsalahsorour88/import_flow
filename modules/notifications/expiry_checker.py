"""
Smart Alerts & Expiry Checker Engine
Comprehensive proactive monitoring for Egyptian Customs, Freight Logistics, and Import Finance Operations.
"""

from datetime import date, datetime, timezone, timedelta
from typing import List, Optional
from sqlalchemy.orm import Session

from modules.import_companies.model import ImportCompany
from modules.import_documentation.model import AcidRegistrationSession, BankingDocumentSession
from modules.import_files.model import ImportFile
from modules.cargox.model import CargoXEnvelope
from modules.original_documents_collection.model import OriginalDocumentsCollectionSession
from modules.import_requirements.model import ImportRequirementAssessment
from modules.demurrage_detention.model import DemurrageTracking
from modules.financial_settlement.model import LandedCostSettlementRecord
from modules.currencies.model import Currency, ExchangeRate
from .repository import NotificationRepository
from .schemas import NotificationCreate


class ExpiryCheckerService:
    """
    Unified Proactive Alert & Expiry Checker Engine.
    Executes all 9 alert workflows across the ImportFlow ERP lifecycle.
    """

    def __init__(self, db: Session):
        self.db = db
        self.repo = NotificationRepository(db)

    def check_all_expiries(self) -> List[NotificationCreate]:
        """
        Runs all alert and expiry checks, generates notifications,
        and returns the list of newly created notifications.
        """
        new_notifications: List[NotificationCreate] = []

        # 1. Import Companies Master Expiries (Importer Card, Commercial Reg)
        new_notifications.extend(self._check_company_expiries())

        # 2. Nafeza ACID 30-Day Expiry Window
        new_notifications.extend(self._check_acid_expiries())

        # 3. CargoX Document Upload Watchdog
        new_notifications.extend(self._check_cargox_upload_alerts())

        # 4. Bank Form 4 Pending Watchdog
        new_notifications.extend(self._check_bank_form4_alerts())

        # 5. Empty Container Return / Detention Risk Watchdog
        new_notifications.extend(self._check_empty_container_detention_alerts())

        # 6. Original Documents Courier Tracking Watchdog
        new_notifications.extend(self._check_courier_tracking_alerts())

        # 7. Regulatory Inspection & Prior Approval Certificate Watchdog
        new_notifications.extend(self._check_regulatory_inspection_alerts())

        # 8. Budget & Landed Cost Variance Watchdog
        new_notifications.extend(self._check_budget_variance_alerts())

        # 9. Customs Exchange Rate Fluctuation Watchdog
        new_notifications.extend(self._check_currency_fluctuation_alerts())

        # CL-006 ── 10. Active Demurrage Charges Alert (غرامات أرضيات نشطة)
        new_notifications.extend(self._check_active_demurrage_alerts())

        # CL-006 ── 11. Demurrage Free-Time Warning (72-hour window)
        new_notifications.extend(self._check_demurrage_freetime_warning())

        # CL-006 ── 12. Incomplete Documents on Arrived Shipments
        new_notifications.extend(self._check_incomplete_docs_alerts())

        # CL-006 ── 13. ETA < 48 Hours without Open Customs Clearance
        new_notifications.extend(self._check_eta_customs_readiness_alerts())

        return new_notifications

    # ─── 1. Company Expiries ──────────────────────────────────────────────────

    def _check_company_expiries(self) -> List[NotificationCreate]:
        new_notifications = []
        today = date.today()

        companies = self.db.query(ImportCompany).filter(ImportCompany.is_active == True).all()
        for company in companies:
            # Importer ID Expiry
            if company.importer_id_expiry:
                days_left = (company.importer_id_expiry - today).days
                if days_left <= 30:
                    severity = "CRITICAL" if days_left <= 7 else "WARNING"
                    category = "COMPANY_EXPIRY_IMP_ID"
                    if not self.repo.exists_active_for_entity("ImportCompany", company.company_id, category):
                        schema = NotificationCreate(
                            title=f"تنبيه انتهاء البطاقة الاستيرادية: {company.importer_name}",
                            message=f"البطاقة الاستيرادية (رقم {company.importer_id}) متبقي عليها {days_left} يوماً وتنتهي في {company.importer_id_expiry}. يرجى التجديد فوراً.",
                            severity=severity,
                            category=category,
                            entity_type="ImportCompany",
                            entity_id=company.company_id,
                            target_role="ALL",
                        )
                        created = self.repo.create(schema)
                        new_notifications.append(created)

            # Commercial Registration Expiry
            if company.registration_expiry:
                days_left = (company.registration_expiry - today).days
                if days_left <= 30:
                    severity = "CRITICAL" if days_left <= 7 else "WARNING"
                    category = "COMPANY_EXPIRY_REG"
                    if not self.repo.exists_active_for_entity("ImportCompany", company.company_id, category):
                        schema = NotificationCreate(
                            title=f"تنبيه انتهاء السجل التجاري: {company.importer_name}",
                            message=f"السجل التجاري (رقم {company.registration_number}) متبقي عليه {days_left} يوماً وينتهي في {company.registration_expiry}.",
                            severity=severity,
                            category=category,
                            entity_type="ImportCompany",
                            entity_id=company.company_id,
                            target_role="ALL",
                        )
                        created = self.repo.create(schema)
                        new_notifications.append(created)

        return new_notifications

    # ─── 2. ACID Expiries ─────────────────────────────────────────────────────

    def _check_acid_expiries(self) -> List[NotificationCreate]:
        new_notifications = []
        today = date.today()

        acid_sessions = self.db.query(AcidRegistrationSession).filter(
            AcidRegistrationSession.is_active == True,
            AcidRegistrationSession.status == "ACID Issued"
        ).all()

        for acid in acid_sessions:
            if acid.expiry_date:
                days_left = (acid.expiry_date - today).days
                if days_left <= 14:
                    severity = "CRITICAL" if days_left <= 3 else "WARNING"
                    if not self.repo.exists_active_for_entity("AcidRegistrationSession", acid.acid_session_id, "ACID_EXPIRY"):
                        schema = NotificationCreate(
                            title=f"تنبيه قرب انتهاء الرقم المبدئي ACID: {acid.acid_number}",
                            message=f"رقم الـ ACID ({acid.acid_number}) للشحنة متبقي عليه {days_left} أيام فقط قبل الشحن وتنتهي صلاحيته في {acid.expiry_date}.",
                            severity=severity,
                            category="ACID_EXPIRY",
                            entity_type="AcidRegistrationSession",
                            entity_id=acid.acid_session_id,
                            target_role="ALL",
                        )
                        created = self.repo.create(schema)
                        new_notifications.append(created)

        return new_notifications

    # ─── 3. CargoX Upload Watchdog ───────────────────────────────────────────

    def _check_cargox_upload_alerts(self) -> List[NotificationCreate]:
        """
        Alerts when shipment is in transit or approaching arrival (ETA <= 7 days)
        and no approved / transferred CargoX envelope exists.
        """
        new_notifications = []
        today = date.today()

        active_files = self.db.query(ImportFile).filter(
            ImportFile.status.in_(["Open", "In Progress"]),
            ImportFile.is_customs_released == False,
            ImportFile.required_eta != None,
        ).all()

        for file in active_files:
            days_to_eta = (file.required_eta - today).days
            if 0 <= days_to_eta <= 7:
                # Check if CargoX envelope uploaded or approved
                envelope = self.db.query(CargoXEnvelope).filter(
                    CargoXEnvelope.import_file_id == file.import_file_id,
                    CargoXEnvelope.status.in_(["UPLOADED_BY_SUPPLIER", "SEALED_AND_TRANSFERRED", "ACCEPTED_BY_CUSTOMS"]),
                ).first()

                if not envelope:
                    severity = "CRITICAL" if days_to_eta <= 3 else "WARNING"
                    category = "CARGOX_UPLOAD_PENDING"
                    if not self.repo.exists_active_for_entity("ImportFile", file.import_file_id, category):
                        file_code = file.custom_file_number or file.import_file_code
                        schema = NotificationCreate(
                            title=f"تنبيه تأخر رفع مستندات CargoX: {file_code}",
                            message=f"الشحنة {file_code} متوقع وصولها خلال {days_to_eta} يوماً (ETA: {file.required_eta}) ولم يتم رفع أو اعتماد مظروف المستندات على منصة CargoX من المورد {file.supplier_name}. يرجى المتابعة العاجلة.",
                            severity=severity,
                            category=category,
                            entity_type="ImportFile",
                            entity_id=file.import_file_id,
                            target_role="ALL",
                        )
                        created = self.repo.create(schema)
                        new_notifications.append(created)

        return new_notifications

    # ─── 4. Bank Form 4 Pending Watchdog ─────────────────────────────────────

    def _check_bank_form4_alerts(self) -> List[NotificationCreate]:
        """
        Alerts when Bank Form 4 session has been pending for >= 7 days or shipment reached port.
        """
        new_notifications = []
        today = date.today()

        pending_docs = self.db.query(BankingDocumentSession).filter(
            BankingDocumentSession.is_active == True,
            BankingDocumentSession.status.in_(["Requested", "Draft", "Submitted to Bank"]),
        ).all()

        for doc in pending_docs:
            days_pending = (today - doc.request_date).days if doc.request_date else 0
            if days_pending >= 7:
                severity = "CRITICAL" if days_pending >= 14 else "WARNING"
                category = "BANK_FORM4_PENDING"
                if not self.repo.exists_active_for_entity("BankingDocumentSession", doc.bank_doc_id, category):
                    schema = NotificationCreate(
                        title=f"تنبيه تأخر صدور نموذج 4 البنكي: {doc.bank_name}",
                        message=f"طلب نموذج 4 مع بنك {doc.bank_name} معلق منذ {days_pending} يوماً (مرجع: {doc.bank_doc_code}). يرجى مراجعة البنك لتسريع الاعتماد قبل وصول البضاعة.",
                        severity=severity,
                        category=category,
                        entity_type="BankingDocumentSession",
                        entity_id=doc.bank_doc_id,
                        target_role="ALL",
                    )
                    created = self.repo.create(schema)
                    new_notifications.append(created)

        return new_notifications

    # ─── 5. Empty Container Return / Detention Risk Watchdog ───────────────────

    def _check_empty_container_detention_alerts(self) -> List[NotificationCreate]:
        """
        Alerts when container is gated out to warehouse and empty return deadline <= 2 days or past due.
        """
        new_notifications = []
        today = date.today()

        trackings = self.db.query(DemurrageTracking).filter(
            DemurrageTracking.is_active == True,
            DemurrageTracking.gate_out_date != None,
            DemurrageTracking.empty_return_date == None,
            DemurrageTracking.status != "Closed",
        ).all()

        for tr in trackings:
            detention_free_days = 7
            if tr.policy and tr.policy.detention_free_days:
                detention_free_days = tr.policy.detention_free_days

            deadline = tr.gate_out_date + timedelta(days=detention_free_days)
            days_left = (deadline - today).days

            if days_left <= 2:
                severity = "CRITICAL" if days_left <= 0 else "WARNING"
                category = "CONTAINER_DETENTION_RISK"
                if not self.repo.exists_active_for_entity("DemurrageTracking", tr.tracking_id, category):
                    schema = NotificationCreate(
                        title=f"تحذير مهلة إرجاع الحاويات الفارغة (Detention): {tr.tracking_code}",
                        message=f"متبقي {days_left} يوماً على انتهاء فترة سماح الحاويات الفارغة للخط الملاحي {tr.carrier_name} (بوليصة {tr.bill_of_lading_no}). يرجى إرجاع الحاويات للساحة لتفادي غرامات الحراسات بالدولار.",
                        severity=severity,
                        category=category,
                        entity_type="DemurrageTracking",
                        entity_id=tr.tracking_id,
                        target_role="ALL",
                    )
                    created = self.repo.create(schema)
                    new_notifications.append(created)

        return new_notifications

    # ─── 6. Original Documents Courier Tracking Watchdog ───────────────────────

    def _check_courier_tracking_alerts(self) -> List[NotificationCreate]:
        """
        Alerts when hard-copy original documents are in transit and shipment ETA <= 3 days.
        """
        new_notifications = []
        today = date.today()

        collections = self.db.query(OriginalDocumentsCollectionSession).filter(
            OriginalDocumentsCollectionSession.is_active == True,
            OriginalDocumentsCollectionSession.status.in_(["DRAFT", "IN_TRANSIT", "PARTIALLY_RECEIVED"]),
        ).all()

        for col in collections:
            linked_file = self.db.query(ImportFile).filter(
                ImportFile.import_file_id == col.import_file_id,
                ImportFile.required_eta != None,
            ).first()

            if linked_file:
                days_to_eta = (linked_file.required_eta - today).days
                if days_to_eta <= 3:
                    severity = "CRITICAL" if days_to_eta <= 1 else "WARNING"
                    category = "COURIER_DELAY"
                    if not self.repo.exists_active_for_entity("OriginalDocumentsCollectionSession", col.collection_id, category):
                        schema = NotificationCreate(
                            title=f"تنبيه تأخر استلام أصول المستندات: {col.import_file_code}",
                            message=f"البوليصة وأصول المستندات للشحنة {col.import_file_code} لم يتم استلامها بالكامل بينما موعد وصول الباخرة متبقي عليه {days_to_eta} أيام (ETA: {linked_file.required_eta}). يرجى مراجعة التتبع مع شركة الشحن السريع.",
                            severity=severity,
                            category=category,
                            entity_type="OriginalDocumentsCollectionSession",
                            entity_id=col.collection_id,
                            target_role="ALL",
                        )
                        created = self.repo.create(schema)
                        new_notifications.append(created)

        return new_notifications

    # ─── 7. Regulatory Inspection & Prior Approval Certificate Watchdog ────────

    def _check_regulatory_inspection_alerts(self) -> List[NotificationCreate]:
        """
        Alerts when shipment requires mandatory prior inspection / certificate and is pending during shipping.
        """
        new_notifications = []

        assessments = self.db.query(ImportRequirementAssessment).filter(
            (ImportRequirementAssessment.inspection_required == True) & (ImportRequirementAssessment.inspection_status == "Pending")
            | (ImportRequirementAssessment.import_permit_required == True) & (ImportRequirementAssessment.permit_status.in_(["Pending", "Applied"]))
            | (ImportRequirementAssessment.coo_required == True) & (ImportRequirementAssessment.coo_status == "Pending")
        ).all()

        for ass in assessments:
            category = "REGULATORY_INSPECTION_PENDING"
            if not self.repo.exists_active_for_entity("ImportRequirementAssessment", ass.assessment_id, category):
                file_code = ass.import_file_code or f"ASSESS-{ass.assessment_id}"
                schema = NotificationCreate(
                    title=f"تنبيه متطلبات رقابية وفحص مسبق: {file_code}",
                    message=f"الشحنة {file_code} تحتوي على أصناف (بند تعريفي: {ass.hs_code or 'عام'}) تتطلب شهادة فحص مسبق أو موافقة رقابية ({ass.permit_issuing_authority or 'رقابة على الصادرات/واردات'}) وهي معلقة حتى الآن.",
                    severity="WARNING",
                    category=category,
                    entity_type="ImportRequirementAssessment",
                    entity_id=ass.assessment_id,
                    target_role="ALL",
                )
                created = self.repo.create(schema)
                new_notifications.append(created)

        return new_notifications

    # ─── 8. Budget & Landed Cost Variance Watchdog ────────────────────────────

    def _check_budget_variance_alerts(self) -> List[NotificationCreate]:
        """
        Alerts when actual expenses exceed the initial estimated budget by >= 5%.
        """
        new_notifications = []

        records = self.db.query(LandedCostSettlementRecord).filter(
            LandedCostSettlementRecord.is_active == True,
            LandedCostSettlementRecord.total_expenses_egp > 0,
        ).all()

        for rec in records:
            file = self.db.query(ImportFile).filter(ImportFile.import_file_id == rec.import_file_id).first()
            if file and file.estimated_cost > 0:
                est_egp = file.estimated_cost * (50.0 if file.estimated_cost_currency in ["USD", "EUR"] else 1.0)
                actual_egp = rec.total_expenses_egp

                if actual_egp > est_egp * 1.05:
                    pct = round(((actual_egp - est_egp) / est_egp) * 100, 1)
                    severity = "CRITICAL" if pct >= 15 else "WARNING"
                    category = "BUDGET_VARIANCE"
                    if not self.repo.exists_active_for_entity("LandedCostSettlementRecord", rec.settlement_id, category):
                        file_code = file.custom_file_number or file.import_file_code
                        schema = NotificationCreate(
                            title=f"تنبيه تجاوز ميزانية الشحنة: {file_code}",
                            message=f"المصروفات الفعلية المسجلة للشحنة {file_code} تجاوزت الميزانية التقديرية بنسبة {pct}% (الفعلي: {actual_egp:,.2f} ج.م مقابل التقديري: {est_egp:,.2f} ج.م). يرجى مراجعة الفروق.",
                            severity=severity,
                            category=category,
                            entity_type="LandedCostSettlementRecord",
                            entity_id=rec.settlement_id,
                            target_role="ALL",
                        )
                        created = self.repo.create(schema)
                        new_notifications.append(created)

        return new_notifications

    # ─── 9. Customs Exchange Rate Fluctuation Watchdog ─────────────────────────

    def _check_currency_fluctuation_alerts(self) -> List[NotificationCreate]:
        """
        Alerts when active Egyptian Customs Exchange Rate has changed by >= 2%.
        """
        new_notifications = []

        usd_curr = self.db.query(Currency).filter(Currency.currency_code == "USD").first()
        if usd_curr:
            rates = self.db.query(ExchangeRate).filter(
                ExchangeRate.currency_id == usd_curr.currency_id,
                ExchangeRate.is_active == True,
            ).order_by(ExchangeRate.effective_date.desc()).limit(2).all()

            if len(rates) >= 2:
                current_rate = float(rates[0].customs_rate)
                prev_rate = float(rates[1].customs_rate)
                if prev_rate > 0 and abs(current_rate - prev_rate) / prev_rate >= 0.02:
                    pct = round(((current_rate - prev_rate) / prev_rate) * 100, 2)
                    category = "CURRENCY_FLUCTUATION"
                    if not self.repo.exists_active_for_entity("Currency", usd_curr.currency_id, category):
                        schema = NotificationCreate(
                            title="تنبيه تقلب سعر الدولار الجمركي",
                            message=f"تم رصد تغير في سعر الصرف الجمركي للدولار بنسبة {pct:+.2f}% (السعر الحالي: {current_rate:.2f} ج.م مقارنة بـ {prev_rate:.2f} ج.م). يرجى تحديث دراسات الرسوم الجمركية للشحنات الجارية.",
                            severity="WARNING",
                            category=category,
                            entity_type="Currency",
                            entity_id=usd_curr.currency_id,
                            target_role="ALL",
                        )
                        created = self.repo.create(schema)
                        new_notifications.append(created)

        return new_notifications

    # ─── CL-006: 10. Active Demurrage Charges Alert ──────────────────────────

    def _check_active_demurrage_alerts(self) -> list:
        """Alert 10: شحنات بدأت باحتساب غرامات أرضيات فعلية (total_demurrage_fx > 0)."""
        from modules.demurrage_detention.model import DemurrageTracking as DT
        new_notifications = []

        active_sessions = self.db.query(DT).filter(
            DT.total_demurrage_fx > 0,
            DT.is_active == True,
        ).all()

        for session in active_sessions:
            category = "DEMURRAGE_ACTIVE"
            entity_id = getattr(session, 'tracking_id', getattr(session, 'id', 0))
            if not self.repo.exists_active_for_entity("DemurrageTracking", entity_id, category):
                total_fx = getattr(session, 'total_demurrage_fx', 0.0)
                total_egp = getattr(session, 'total_cost_egp', 0.0)
                schema = NotificationCreate(
                    title=f"🚨 غرامات أرضيات نشطة: {session.import_file_code}",
                    message=(
                        f"شحنة {session.import_file_code} تتراكم عليها غرامات أرضيات "
                        f"بقيمة ${total_fx:.0f} "
                        f"({total_egp:.0f} ج.م). "
                        f"يُرجى التدخل الفوري للتخليص والسحب."
                    ),
                    severity="CRITICAL",
                    category=category,
                    entity_type="DemurrageTracking",
                    entity_id=entity_id,
                    target_role="ALL",
                )
                created = self.repo.create(schema)
                new_notifications.append(created)

        return new_notifications

    # ─── CL-006: 11. Demurrage Free-Time 72-Hour Warning ─────────────────────

    def _check_demurrage_freetime_warning(self) -> list:
        """Alert 11: شحنات ستنتهي فترة سماحها خلال 72 ساعة (3 أيام أو أقل) أو في حالة Warning."""
        from modules.demurrage_detention.model import DemurrageTracking as DT
        new_notifications = []
        today = date.today()

        at_risk_sessions = self.db.query(DT).filter(
            DT.total_demurrage_fx == 0,
            DT.is_active == True,
        ).all()

        for session in at_risk_sessions:
            free_days_remaining = None
            if hasattr(session, 'free_days_remaining') and session.free_days_remaining is not None:
                free_days_remaining = session.free_days_remaining
            elif getattr(session, 'discharge_date', None):
                policy_days = getattr(getattr(session, 'policy', None), 'demurrage_free_days', 14) or 14
                used_days = (today - session.discharge_date).days
                free_days_remaining = policy_days - used_days

            is_warning = getattr(session, 'status', '') == 'Warning' or (
                free_days_remaining is not None and 0 <= free_days_remaining <= 3
            )

            if is_warning:
                category = "DEMURRAGE_WARNING"
                entity_id = getattr(session, 'tracking_id', getattr(session, 'id', 0))
                if not self.repo.exists_active_for_entity("DemurrageTracking", entity_id, category):
                    days_left = int(free_days_remaining if free_days_remaining is not None else 3)
                    schema = NotificationCreate(
                        title=f"⚠️ تحذير أرضيات: {session.import_file_code}",
                        message=(
                            f"شحنة {session.import_file_code} متبقي لها {days_left} يوم "
                            f"قبل انتهاء فترة السماح وبدء احتساب الغرامات. "
                            f"الرجاء التعجيل في إجراءات التخليص."
                        ),
                        severity="WARNING",
                        category=category,
                        entity_type="DemurrageTracking",
                        entity_id=entity_id,
                        target_role="ALL",
                    )
                    created = self.repo.create(schema)
                    new_notifications.append(created)

        return new_notifications

    # ─── CL-006: 12. Incomplete Documents on Arrived Shipments ───────────────

    def _check_incomplete_docs_alerts(self) -> list:
        """Alert 12: شحنات بها نقص مستندي (readiness < 60%)."""
        new_notifications = []

        arrived_files = self.db.query(ImportFile).filter(
            ImportFile.is_active == True,
            ImportFile.is_customs_released == False,
        ).all()

        for f in arrived_files:
            verified = 0
            if getattr(f, 'invoices_data', None) or getattr(f, 'invoice_value', None): verified += 1
            if getattr(f, 'packing_lists_data', None) or getattr(f, 'packing_list_value', None): verified += 1
            if getattr(f, 'acid_number', None): verified += 1
            if getattr(f, 'form4_no', None): verified += 1
            if getattr(f, 'custom_file_number', None): verified += 1
            if getattr(f, 'form46_no', None) or getattr(f, 'is_customs_released', False): verified += 1
            if getattr(f, 'pi_number', None) or getattr(f, 'bl_number', None): verified += 1

            readiness_pct = (verified / 7) * 100.0
            if readiness_pct >= 60.0:
                continue

            category = "INCOMPLETE_DOCS"
            entity_id = getattr(f, 'import_file_id', getattr(f, 'id', 0))
            if not self.repo.exists_active_for_entity("ImportFile", entity_id, category):
                schema = NotificationCreate(
                    title=f"📄 نقص مستندي: {f.import_file_code}",
                    message=(
                        f"شحنة {f.import_file_code} وصلت أو قاربت الوصول لكن اكتمال المستندات "
                        f"{readiness_pct:.0f}% فقط ({verified}/7 مستندات). "
                        f"يُرجى استكمال الملف المستندي فوراً."
                    ),
                    severity="WARNING",
                    category=category,
                    entity_type="ImportFile",
                    entity_id=entity_id,
                    target_role="ALL",
                )
                created = self.repo.create(schema)
                new_notifications.append(created)

        return new_notifications

    # ─── CL-006: 13. ETA < 48 Hours without Open Customs Clearance ───────────

    def _check_eta_customs_readiness_alerts(self) -> list:
        """Alert 13: شحنات ETA خلال 48 ساعة بدون ملف تخليص جمركي مفتوح."""
        new_notifications = []
        now = datetime.now(timezone.utc)
        threshold = now + timedelta(hours=48)

        try:
            from modules.freight_booking.model import ShipmentBooking
        except ImportError:
            return new_notifications

        bookings = self.db.query(ShipmentBooking).filter(
            ShipmentBooking.eta.isnot(None),
        ).all()

        for booking in bookings:
            try:
                b_eta = getattr(booking, 'eta', None)
                if isinstance(b_eta, datetime):
                    eta_dt = b_eta if b_eta.tzinfo else b_eta.replace(tzinfo=timezone.utc)
                elif isinstance(b_eta, date):
                    eta_dt = datetime.combine(b_eta, datetime.min.time(), tzinfo=timezone.utc)
                else:
                    continue
            except Exception:
                continue

            if not (now <= eta_dt <= threshold):
                continue

            import_file = None
            if getattr(booking, 'import_file_id', None):
                import_file = self.db.query(ImportFile).filter(
                    ImportFile.import_file_id == booking.import_file_id,
                    ImportFile.is_active == True,
                ).first()

            if not import_file:
                continue
            if getattr(import_file, 'form46_no', None) or getattr(import_file, 'custom_file_number', None) or getattr(import_file, 'is_customs_released', False):
                continue

            category = "ETA_CUSTOMS_ALERT"
            entity_id = getattr(import_file, 'import_file_id', getattr(import_file, 'id', 0))
            if not self.repo.exists_active_for_entity("ImportFile", entity_id, category):
                hours_left = max(0, int((eta_dt - now).total_seconds() / 3600))
                schema = NotificationCreate(
                    title=f"🚢 ETA وشيك بدون تخليص: {import_file.import_file_code}",
                    message=(
                        f"شحنة {import_file.import_file_code} ستصل خلال {hours_left} ساعة "
                        f"ولم يُفتح لها ملف تخليص جمركي بعد. "
                        f"يُرجى المباشرة فوراً في إجراءات إقرار 46 ك.م."
                    ),
                    severity="CRITICAL",
                    category=category,
                    entity_type="ImportFile",
                    entity_id=entity_id,
                    target_role="ALL",
                )
                created = self.repo.create(schema)
                new_notifications.append(created)

        return new_notifications

