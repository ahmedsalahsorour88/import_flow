"""
SQLAlchemy Models for Smart Import Checklist Engine (الطبقة التفاعلية الذكية لملفات الاستيراد)
"""

from datetime import datetime, timezone
from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    ForeignKey,
    Text,
    Index,
)
from sqlalchemy.orm import relationship
from database.database import Base


class ImportFileChecklistItem(Base):
    """
    Checklist Item Model linked to an Import File.
    Tracks questions, requirements, verification status, and gatekeeper rules across 5 phases.
    """
    __tablename__ = "import_file_checklist_items"

    item_id = Column(Integer, primary_key=True, autoincrement=True, index=True)
    import_file_id = Column(Integer, ForeignKey("import_files.import_file_id", ondelete="CASCADE"), nullable=False, index=True)
    import_file_code = Column(String(50), nullable=True, index=True)

    # Phase category: PRE_SHIPMENT, IN_TRANSIT, PORT_ARRIVAL, CLEARANCE, POST_CLEARANCE
    phase_code = Column(String(50), nullable=False, index=True)
    
    # Business Code e.g. CHK_PRE_01
    question_code = Column(String(50), nullable=False, index=True)
    question_title_ar = Column(String(500), nullable=False)
    description_ar = Column(Text, nullable=True)
    question_title_en = Column(String(500), nullable=True)
    description_en = Column(Text, nullable=True)

    # Responsible: COORDINATOR, SUPPLIER, CUSTOMS_BROKER, SHIPPING_LINE
    responsible_role = Column(String(50), nullable=False, default="COORDINATOR")

    # Gatekeeper enforcement
    is_mandatory = Column(Boolean, nullable=False, default=True)

    # Verification: AUTOMATIC (verified from DB) or MANUAL (toggled by user)
    verification_type = Column(String(20), nullable=False, default="MANUAL")
    auto_check_source = Column(String(150), nullable=True)

    # Status: PENDING, PASSED, WAIVED
    status = Column(String(20), nullable=False, default="PENDING", index=True)

    # Audit & Sign-off
    verified_by = Column(String(100), nullable=True)
    verified_at = Column(DateTime, nullable=True)
    notes = Column(Text, nullable=True)
    override_reason = Column(Text, nullable=True)
    action_route = Column(String(100), nullable=True)

    # Standard Audit Trail
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    created_by = Column(String(100), default="System", nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)
    updated_by = Column(String(100), default="System", nullable=False)

    # Relationship
    import_file = relationship("ImportFile", backref="checklist_items", foreign_keys=[import_file_id])

    __table_args__ = (
        Index("idx_checklist_file_phase", "import_file_id", "phase_code"),
        Index("idx_checklist_status", "status"),
    )


# Standard Master Template Questions across the 5 Stages
DEFAULT_CHECKLIST_QUESTIONS = [
    # 1️⃣ قبل الشحن (Pre-Shipment)
    {
        "phase_code": "PRE_SHIPMENT",
        "question_code": "CHK_PRE_01",
        "question_title_ar": "الـ Incoterm المتفق عليه ومصفوفة مسؤولية التكاليف بعده (شحن، تأمين، تخليص)",
        "description_ar": "تحديد ما إذا كان FOB أو CIF أو EXW وتوثيق مسؤولية كل طرف لمنع أي نزاع لاحق.",
        "question_title_en": "Agreed Incoterm & Cost Responsibility Matrix (Freight, Insurance, Clearance)",
        "description_en": "Confirm FOB, CIF, or EXW terms and document party cost responsibilities to prevent disputes.",
        "responsible_role": "COORDINATOR",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "import_files.incoterm_code",
        "action_route": "incoterms",
    },
    {
        "phase_code": "PRE_SHIPMENT",
        "question_code": "CHK_PRE_02",
        "question_title_ar": "تراخيص الاستيراد المسبقة وقرار 43 والقيد بالقائمة البيضاء للمصانع",
        "description_ar": "التأكد من تسجيل المصنع بالهيئة العامة للرقابة على الصادرات والواردات (GOEIC) أو موافقات هيئة الدواء.",
        "question_title_en": "Prior Import Licenses, Decree 43, & Factory White-List Verification",
        "description_en": "Verify GOEIC factory registration, EDA approvals, or relevant pre-import regulatory permits.",
        "responsible_role": "COORDINATOR",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "import_requirement_assessments.decree_43_applicable",
        "action_route": "import_requirements",
    },
    {
        "phase_code": "PRE_SHIPMENT",
        "question_code": "CHK_PRE_03",
        "question_title_ar": "التأكد من الكود الجمركي (HS Code) ونسب الضرائب ورسوم الرقابة المعتمدة",
        "description_ar": "مطابقة بند التعريفة الجمركية ونسب ضريبة الوارد والقيمة المضافة والجهات الرقابية (ملحق 8).",
        "question_title_en": "Harmonized System Code (HS Code) Verification & Approved Duty/Tax Rates",
        "description_en": "Match HS code with tariff schedule, import duty, VAT, and regulatory authority mandates.",
        "responsible_role": "COORDINATOR",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "customs_tariffs.hs_code",
        "action_route": "customs_tariff",
    },
    {
        "phase_code": "PRE_SHIPMENT",
        "question_code": "CHK_PRE_04",
        "question_title_ar": "شهادة مطابقة المواصفات والفحص قبل الشحن (COC / GOEIC)",
        "description_ar": "إلزامية للبضائع الخاضعة للمواصفات القياسية المصرية قبل الشحن (SGS, TUV, BV).",
        "question_title_en": "Certificate of Conformity (COC) & Pre-Shipment Inspection (GOEIC)",
        "description_en": "Mandatory for goods regulated under Egyptian standards prior to departure (SGS, TUV, BV).",
        "responsible_role": "COORDINATOR",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "import_requirement_assessments.inspection_status",
        "action_route": "import_requirements",
    },
    {
        "phase_code": "PRE_SHIPMENT",
        "question_code": "CHK_PRE_05",
        "question_title_ar": "طريقة الدفع وضمان السداد البنكي (L/C, Form 4, TT مقسم)",
        "description_ar": "التأكد من مطابقة السداد لتعليمات البنك المركزي المصري ونموذج 4 لضمان الإفراج.",
        "question_title_en": "Payment Method & Bank Guarantee Compliance (L/C, Form 4, Advance TT)",
        "description_en": "Ensure payment compliance with Central Bank of Egypt rules and Form 4 release requirements.",
        "responsible_role": "COORDINATOR",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "banking_document_sessions",
        "action_route": "financial_approval",
    },
    {
        "phase_code": "PRE_SHIPMENT",
        "question_code": "CHK_PRE_06",
        "question_title_ar": "شهادة المنشأ (Certificate of Origin) ومطابقتها للفاتورة ورفعها على CargoX",
        "description_ar": "التأكد من مطابقة الكمية والأوزان والقيمة، ونوع الشهادة (EUR.1, Form A, Arab League).",
        "question_title_en": "Certificate of Origin (COO) Matching Invoice & CargoX Upload",
        "description_en": "Verify COO matches weights, quantities, values, and valid trade agreement (EUR.1, Form A).",
        "responsible_role": "SUPPLIER",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "cargox_envelopes.documents",
        "action_route": "cargox",
    },
    {
        "phase_code": "PRE_SHIPMENT",
        "question_code": "CHK_PRE_07",
        "question_title_ar": "الـ Packing List والتغليف وختم التبخير للباليتات الخشبية (IPPC Stamp)",
        "description_ar": "التأكد من التغليف المانع للتلف ووجود ختم المعالجة الحرارية على الخشب تفادياً لغرامات الحجر الزراعي.",
        "question_title_en": "Packing List Packaging & Wooden Pallet Fumigation (IPPC Stamp)",
        "description_en": "Ensure protective packaging and valid heat-treatment stamp on timber to avoid quarantine fines.",
        "responsible_role": "SUPPLIER",
        "is_mandatory": False,
        "verification_type": "MANUAL",
        "auto_check_source": None,
        "action_route": "cbm_calculator",
    },
    {
        "phase_code": "PRE_SHIPMENT",
        "question_code": "CHK_PRE_08",
        "question_title_ar": "تاريخ الجاهزية الفعلي للبضاعة (Cargo Ready Date) وتطابقه مع الحجز",
        "description_ar": "تأكيد التاريخ الحقيقي لخروج البضاعة من المصنع ومواءمته مع مواعيد إغلاق الشحن (Cut-off).",
        "question_title_en": "Cargo Ready Date (CRD) Alignment with Freight Booking Cut-off",
        "description_en": "Confirm factory release date aligns with shipping cut-off deadlines and vessel schedule.",
        "responsible_role": "SUPPLIER",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "import_files.cargo_ready_date",
        "action_route": "freight_booking",
    },
    {
        "phase_code": "PRE_SHIPMENT",
        "question_code": "CHK_PRE_09",
        "question_title_ar": "مراجعة مسودة الفاتورة والمستندات مع المستخلص واعتمادها ثنائياً قبل الشحن",
        "description_ar": "مراجعة تفاصيل المسميات والأكواد والأوزان لتفادي أي تعديلات معقدة بعد تحرك السفينة.",
        "question_title_en": "Draft Invoice & Documents Dual Review with Customs Broker",
        "description_en": "Review descriptions, HS codes, and weights to prevent complex post-departure amendments.",
        "responsible_role": "CUSTOMS_BROKER",
        "is_mandatory": True,
        "verification_type": "MANUAL",
        "auto_check_source": None,
        "action_route": "import_documentation",
    },

    # 2️⃣ أثناء الشحن (In-Transit)
    {
        "phase_code": "IN_TRANSIT",
        "question_code": "CHK_TRN_01",
        "question_title_ar": "إصدار وثيقة التأمين البحري (Marine Insurance) الشاملة 110% CIF",
        "description_ar": "التأكد من تغطية كافة المخاطر ICC (A) والحرب والإضرابات وتحديد جهة تسوية التعويضات بمصر.",
        "question_title_en": "Comprehensive Marine Cargo Insurance Policy Issued (110% CIF)",
        "description_en": "Verify ICC (A) all-risks cover, war & strikes, with claims settling agent located in Egypt.",
        "responsible_role": "COORDINATOR",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "cargo_insurance_certificates",
        "action_route": "cargo_insurance",
    },
    {
        "phase_code": "IN_TRANSIT",
        "question_code": "CHK_TRN_02",
        "question_title_ar": "متابعة التتبع الملاحي وتأكيد الـ ETA ورصد أي مسار ترانزيت (Transshipment)",
        "description_ar": "تتبع خط سير السفينة ورصد أي تأخير في موانئ الترانزيت وتحديث موعد الوصول المتوقع.",
        "question_title_en": "Vessel Tracking, ETA Confirmation & Transshipment Monitoring",
        "description_en": "Track vessel coordinates, monitor transshipment ports, and update estimated arrival dates.",
        "responsible_role": "COORDINATOR",
        "is_mandatory": False,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "shipment_bookings.eta",
        "action_route": "freight_booking",
    },
    {
        "phase_code": "IN_TRANSIT",
        "question_code": "CHK_TRN_03",
        "question_title_ar": "إرسال واستلام أصول المستندات (Original B/L أو Telex Release والتظهير البنكي)",
        "description_ar": "تتبع مكان وصول البوالص الأصلية وتسليمها للبنك للتظهير أو تأكيد التنازل الإلكتروني.",
        "question_title_en": "Original Shipping Documents Dispatch & Bank Endorsement / Telex Release",
        "description_en": "Track original B/L courier, ensure bank endorsement, or confirm telex release status.",
        "responsible_role": "SUPPLIER",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "shipment_document_items.is_bl_endorsed",
        "action_route": "import_documentation",
    },
    {
        "phase_code": "IN_TRANSIT",
        "question_code": "CHK_TRN_04",
        "question_title_ar": "التحقق من عدم وجود تعديل على الفاتورة أو الكمية ومطابقتها مع المخلص",
        "description_ar": "مطابقة الأوزان النهائية بالمانيفيست ورصد أي فروق قبل وصول السفينة.",
        "question_title_en": "Verification of Final Commercial Invoice & Manifest Discrepancies",
        "description_en": "Cross-check final manifest weights and invoice quantities prior to vessel berthing.",
        "responsible_role": "CUSTOMS_BROKER",
        "is_mandatory": False,
        "verification_type": "MANUAL",
        "auto_check_source": None,
        "action_route": "shipment_updates",
    },
    {
        "phase_code": "IN_TRANSIT",
        "question_code": "CHK_TRN_05",
        "question_title_ar": "تجهيز المستندات التكميلية والموافقات قبل رسو السفينة لتفادي التأخير",
        "description_ar": "إعداد التوكيل الملاحي، شهادات التحليل، وأذونات الاستيراد المسبقة.",
        "question_title_en": "Supplementary Documentation & Pre-Berthing Clearances Prepared",
        "description_en": "Prepare carrier authorizations, certificates of analysis, and prior clearance permits.",
        "responsible_role": "CUSTOMS_BROKER",
        "is_mandatory": False,
        "verification_type": "MANUAL",
        "auto_check_source": None,
        "action_route": "import_documentation",
    },

    # 3️⃣ بعد الوصول للميناء (Port Arrival)
    {
        "phase_code": "PORT_ARRIVAL",
        "question_code": "CHK_PRT_01",
        "question_title_ar": "تأكيد تفريغ الحاويات وتسجيلها في مانيفيست الميناء وإصدار إذن التسليم",
        "description_ar": "تسجيل وصول السفينة وتفريغ الشحنة وطلب إذن التسليم الملاحي (Delivery Order).",
        "question_title_en": "Container Discharge Confirmation, Port Manifest & Delivery Order Issued",
        "description_en": "Confirm vessel arrival, container discharge, and secure shipping line Delivery Order (DO).",
        "responsible_role": "CUSTOMS_BROKER",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "customs_clearance_records.port_arrival_date",
        "action_route": "customs_clearance",
    },
    {
        "phase_code": "PORT_ARRIVAL",
        "question_code": "CHK_PRT_02",
        "question_title_ar": "تثبيت فترة السماح المجانية (Free Time) وتفعيل عداد مراقبة الغرامات والأرضيات",
        "description_ar": "تحديد الأيام المجانية للحاويات بالميناء وخارجه لمنع تراكم غرامات التأخير (Demurrage & Detention).",
        "question_title_en": "Demurrage & Detention Free Time Logged & Countdown Activated",
        "description_en": "Record port and liner free days to prevent demurrage, detention, and storage penalties.",
        "responsible_role": "COORDINATOR",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "demurrage_trackings",
        "action_route": "demurrage_detention",
    },
    {
        "phase_code": "PORT_ARRIVAL",
        "question_code": "CHK_PRT_03",
        "question_title_ar": "تحديد مسار الفحص الجمركي (أخضر سكنر أم أحمر كشف ومعاينة فعلية)",
        "description_ar": "معرفة مسار الشحنة على منظومة نافذة لتجهيز فتح الحاويات وسحب العينات إن وُجدت.",
        "question_title_en": "Customs Inspection Channel Allocated (Green Scanner vs Red Physical Exam)",
        "description_en": "Identify Nafeza channel route to prepare container devanning, staging, and lab sampling.",
        "responsible_role": "CUSTOMS_BROKER",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "customs_clearance_records.channel_type",
        "action_route": "customs_clearance",
    },
    {
        "phase_code": "PORT_ARRIVAL",
        "question_code": "CHK_PRT_04",
        "question_title_ar": "التحقق من حالة رقم ACID على نافذة وعدم وجود أي Discrepancy مانع للشهادة",
        "description_ar": "مطابقة رقم البيان برقم 46 ك.م جمركي في مركز الخدمات اللوجستية.",
        "question_title_en": "ACID Status Verified on Nafeza & Absence of Blocking Discrepancies",
        "description_en": "Reconcile declaration with Form 46 K.M in logistics center without data discrepancies.",
        "responsible_role": "CUSTOMS_BROKER",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "acid_registration_sessions.status",
        "action_route": "import_documentation",
    },

    # 4️⃣ أثناء عمليات التخليص الجمركي (Customs Clearance)
    {
        "phase_code": "CLEARANCE",
        "question_code": "CHK_CLR_01",
        "question_title_ar": "مراجعة تقييم وتثمين الجمارك ومطابقته مع الفاتورة وميزانية الرسوم",
        "description_ar": "التحقق من عدم رفع القيمة الجمركية من قِبل المثمن والتأهب لتقديم تظلم حال وجود نزاع.",
        "question_title_en": "Customs Valuation Review & Comparison with Invoice and Duty Budget",
        "description_en": "Verify customs appraiser valuation against CIF invoice and prepare grievance if contested.",
        "responsible_role": "COORDINATOR",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "customs_clearance_records.actual_duty_total",
        "action_route": "customs_clearance",
    },
    {
        "phase_code": "CLEARANCE",
        "question_code": "CHK_CLR_02",
        "question_title_ar": "متابعة العروض الرقابية والمعامل وسحب العينات أو تفعيل الإفراج تحت التحفظ",
        "description_ar": "متابعة فحص الصادرات والواردات أو سلامة الغذاء أو تفعيل قفل الحظر المخزني (Quarantine Lock).",
        "question_title_en": "Regulatory Lab Testing, Sampling & Conditional Release under Quarantine",
        "description_en": "Track GOEIC / NFSA lab testing or activate conditional release warehouse quarantine lock.",
        "responsible_role": "CUSTOMS_BROKER",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "customs_clearance_records.sample_test_status",
        "action_route": "customs_clearance",
    },
    {
        "phase_code": "CLEARANCE",
        "question_code": "CHK_CLR_03",
        "question_title_ar": "سداد الرسوم والضرائب الجمركية بالبنك واستلام إشعار الخصم والإيصال",
        "description_ar": "توثيق رقم الإيصال البنكي وتاريخ السداد وتأكيد السداد على منظومة نافذة.",
        "question_title_en": "Customs Duties & Taxes Settlement via Bank & Receipt Obtained",
        "description_en": "Record bank receipt number, date, and confirm payment settlement on Nafeza system.",
        "responsible_role": "COORDINATOR",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "customs_clearance_records.bank_receipt_no",
        "action_route": "customs_clearance",
    },
    {
        "phase_code": "CLEARANCE",
        "question_code": "CHK_CLR_04",
        "question_title_ar": "تسجيل كل بند تكلفة منفصلاً (جمارك، ضريبة ق.م، رسوم خدمات، أتعاب تخليص)",
        "description_ar": "الالتزام بتفكيك البنود بدقة لضمان صحة التدقيق الضريبي واحتساب الوعاء الصحيح.",
        "question_title_en": "Itemized Cost Breakdown Recorded (Duty, VAT, Service Fees, Brokerage)",
        "description_en": "Ensure detailed expense breakdown for accurate tax base calculations and audit compliance.",
        "responsible_role": "COORDINATOR",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "customs_clearance_records.import_duty_amount",
        "action_route": "customs_clearance",
    },

    # 5️⃣ بعد التخليص وسداد الرسوم (Post-Clearance)
    {
        "phase_code": "POST_CLEARANCE",
        "question_code": "CHK_PST_01",
        "question_title_ar": "استلام وحفظ المستندات النهائية وإذن الإفراج النهائي وأرشفة الملف رقمياً",
        "description_ar": "حفظ إيصالات السداد الرسمية، تصريح الخروج، والمطابقة لأي فحص ضريبي لاحق.",
        "question_title_en": "Final Customs Release Permit & Complete Document Dossier Archived",
        "description_en": "Archive official payment receipts, gate passes, and audit documentation digitally.",
        "responsible_role": "COORDINATOR",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "customs_clearance_records.release_permit_no",
        "action_route": "file_closure",
    },
    {
        "phase_code": "POST_CLEARANCE",
        "question_code": "CHK_PST_02",
        "question_title_ar": "احتساب تكلفة الوحدة النهائية الشاملة (Landed Cost) ومعامل الضرب (Markup)",
        "description_ar": "توزيع كافة النفقات الفعلية على الأصناف بالوزن أو القيمة لتحديد سعر التكلفة النهائي بدقة.",
        "question_title_en": "Comprehensive Landed Cost per Unit Calculation & Margin Multiplier",
        "description_en": "Apportion all landed expenses across items by weight/value to establish final unit cost.",
        "responsible_role": "COORDINATOR",
        "is_mandatory": True,
        "verification_type": "AUTOMATIC",
        "auto_check_source": "financial_settlement_records",
        "action_route": "financial_settlement",
    },
]
