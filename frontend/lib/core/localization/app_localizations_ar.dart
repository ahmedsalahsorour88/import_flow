import 'app_localizations.dart';

/// Arabic localization for ImportFlow ERP.
class AppLocalizationsAr extends AppLocalizations {
  const AppLocalizationsAr();

  // ── Navigation / Sidebar ─────────────────────────────────────────────────
  @override String get appTitle => 'سرور للخدمات اللوجستية';
  @override String get appSubtitle => 'نظام إدارة الاستيراد';
  @override String get masterData => 'البيانات والجداول الأساسية';
  @override String get masterDataSub => 'البيانات المرجعية والسجلات';
  @override String get shipmentPlanning => 'تخطيط الشحنة وأوامر الشراء';
  @override String get shipmentPlanningSub => 'الملفات وأوامر الشراء والحسابات';
  @override String get phase1 => 'المرحلة 1: التخطيط والدراسات';
  @override String get phase1Sub => 'دراسات الشحن والجمارك';
  @override String get phase2 => 'المرحلة 2: بداية الشحنة';
  @override String get phase2Sub => 'الميزانية والـ ACID';
  @override String get phase3 => 'المرحلة 3: حجز الشحن والمستندات';
  @override String get phase3Sub => 'الحجز والتدقيق المستندي';
  @override String get phase4 => 'المرحلة 4: التوثيق الرقمي والبنكي';
  @override String get phase4Sub => 'CargoX والأصول والنماذج البنكية';
  @override String get phase5 => 'المرحلة 5: الميناء والتخليص';
  @override String get phase5Sub => 'التصريح الجمركي والإفراج';
  @override String get phase6 => 'المرحلة 6: الاستلام والإغلاق';
  @override String get phase6Sub => 'المستودع وتكلفة الوصول والإغلاق';
  @override String get dashboardAndReports => 'لوحة القيادة والتقارير';
  @override String get dashboardAndReportsSub => 'المؤشرات والتدقيق والتقارير';

  // ── Sidebar Menu Items ────────────────────────────────────────────────────
  @override String get importCompanies => 'الشركات المستوردة';
  @override String get foreignSuppliers => 'دليل الموردين الأجانب';
  @override String get partnersAndBanks => 'الشركاء والبنوك ومقدمو الخدمات';
  @override String get projectsAndCostCenters => 'المشاريع ومراكز التكلفة';
  @override String get portsAndLocations => 'الموانئ والمنافذ الجمركية';
  @override String get incotermsRules => 'الشروط التجارية الدولية';
  @override String get customsTariffSchedule => 'جدول التعريفة الجمركية';
  @override String get currenciesAndRates => 'العملات وأسعار الصرف';
  @override String get importFiles => 'ملفات الشحنات الاستيرادية';
  @override String get purchaseOrders => 'أوامر الشراء وإثبات المنشأ';
  @override String get cbmCalculator => 'حاسبة الأحجام وتوزيع الحاويات';
  @override String get freightStudies => 'دراسات ومفاضلة نولون الشحن';
  @override String get freightQuotations => 'مقارنة عروض أسعار الشحن';
  @override String get customsStudies => 'الدراسات والاستشارات الجمركية';
  @override String get clearanceQuotations => 'عروض ومقايسات التخليص والاستخراج';
  @override String get importRequirements => 'متطلبات واشتراطات الاستيراد';
  @override String get financeApprovals => 'اعتمادات الميزانية وسداد الموردين';
  @override String get acidOperations => 'الرقم التعريفي المبدئي للشحنة ACID';
  @override String get freightBooking => 'حجز النولون وتأكيد الخط الملاحي';
  @override String get freightAllocations => 'تخصيص وتوزيع الحاويات (VGM)';
  @override String get cargoShippingTracking => 'متابعة حركة الشحن البحري والجوي';
  @override String get packingReconciliation => 'مطابقة وتأكيد الفاتورة والباكينج';
  @override String get draftDocsReview => 'مراجعة مسودات بوالص الشحن';
  @override String get draftCOO => 'مسودة وتوليد شهادة المنشأ';
  @override String get draftInspection => 'مسودة وتوليد شهادة الفحص والمطابقة';
  @override String get docsCustomsApproval => 'الاعتماد النهائي للمستندات جمركياً';
  @override String get centralDocsHub => 'الأرشيف المركزي لمستندات الشحنة';
  @override String get customsDutyEstimator => 'حساب ومراجعة الضرائب الجمركية';
  @override String get cargoXBlockchain => 'منظومة الشحن المسبق والبلوك تشين';
  @override String get originalsCollection => 'تحصيل أصول مستندات الشحنة';
  @override String get bankForm4 => 'النموذج الإحصائي والتحويل البنكي نموذج 4';
  @override String get customsDeclaration46 => 'شهادة الإجراءات الجمركية إقرار 46 ك.م';
  @override String get customsClearanceFollowup => 'متابعة الكشف والتثمين الجمركي';
  @override String get drawingSamples => 'سحب العينات وتحديد عجز البضائع';
  @override String get discrepancyDamage => 'إثبات الفاقد والتلف الجمركي';
  @override String get finalCustomsPayment => 'سداد الرسوم والضرائب الجمركية النهائية';
  @override String get demurrageDetention => 'تتبع غرامات الأرضيات وحراسات الحاويات';
  @override String get goodsInTransit => 'رصيد ومطابقة البضاعة في الطريق';
  @override String get warehouseReceiving => 'إذن إضافة المخزن واستلام الشحنة';
  @override String get receivedShipmentsReport => 'تقرير الشحنات المستلمة بالمخزن';
  @override String get landedCostSettlement => 'حساب تكلفة الوصول النهائية للوحدة';
  @override String get landedCostComparison => 'مقارنة تكاليف الوصول';
  @override String get importFileFinalClosure => 'الإغلاق المالي والإداري لملف الاستيراد';
  @override String get operationalDashboard => 'لوحة التحكم ومؤشرات الأداء';
  @override String get lifecycleBoard => 'لوحة تتبع ومراحل الشحنات التفاعلية';
  @override String get masterShipmentReport => 'تقرير الشحنة الشامل المدمج';
  @override String get dynamicReportBuilder => 'مُنشئ التقارير المخصصة';
  @override String get quickUpdateEngine => 'محرك التحديث السريع';
  @override String get smartTasksAndAlerts => 'المهام والتنبيهات الذكية';
  @override String get systemAuditLogs => 'سجل التدقيق والرقابة';
  @override String get productionSyncHub => 'مركز مزامنة وتحديث الإنتاج';

  // ── Buttons ───────────────────────────────────────────────────────────────
  @override String get save => 'حفظ';
  @override String get saveDraft => 'حفظ مؤقت';
  @override String get saveAndConfirm => 'حفظ وتأكيد السجل';
  @override String get updateRecord => 'تحديث وحفظ السجل';
  @override String get cancel => 'إلغاء';
  @override String get close => 'إغلاق وتراجع';
  @override String get resetForm => 'تفريغ وبدء تسجيل جديد';
  @override String get refresh => 'تحديث';
  @override String get liveRefresh => 'إعادة تحميل حية';
  @override String get edit => 'تعديل';
  @override String get delete => 'حذف';
  @override String get viewDetails => 'عرض التفاصيل';
  @override String get print => 'طباعة وتصدير';
  @override String get exportExcel => 'تصدير Excel';
  @override String get exportPdf => 'تصدير PDF';
  @override String get importExcel => 'استيراد Excel';
  @override String get downloadTemplate => 'تحميل النموذج';
  @override String get uploading => 'جاري الرفع...';
  @override String get backToDashboard => 'العودة للداش بورد';

  // ── Common Messages ───────────────────────────────────────────────────────
  @override String get connectionError => 'تعذر الاتصال بسيرفر النظام';
  @override String get connectionErrorDetail =>
      'تأكد من تشغيل سيرفر الباك إند ثم اضغط على زر إعادة المحاولة.';
  @override String get retryConnection => 'إعادة المحاولة وتحديث البيانات';
  @override String get loading => 'جاري التحميل...';
  @override String get saving => 'جاري الحفظ...';
  @override String get noData => 'لا توجد بيانات';
  @override String get search => 'بحث';
  @override String get searchHint => 'بحث سريع...';
  @override String get clearSearch => 'مسح';
  @override String get ok => 'موافق';
  @override String get confirm => 'تأكيد';
  @override String get warning => 'تحذير';
  @override String get error => 'خطأ';
  @override String get success => 'نجاح';
  @override String get importSuccessful => 'تم الاستيراد بنجاح';
  @override String get approved => 'معتمد';
  @override String get pending => 'قيد الانتظار';
  @override String get statusPending => 'قيد الانتظار';
  @override String get rejected => 'مرفوض';
  @override String get importWithAlerts => 'تم الاستيراد مع تنبيهات';
  @override String get alertsErrors => 'التنبيهات والأخطاء:';
  @override String get preparingExport => 'جاري تحضير ملف التصدير...';
  @override String get dataActionsTitle => 'عمليات البيانات والتصدير/الاستيراد';

  // ── System Info ───────────────────────────────────────────────────────────
  @override String get systemVersion => 'إصدار المنظومة';
  @override String get buildId => 'رقم البناء';
  @override String get backendEngine => 'الخادم المدمج';
  @override String get database => 'قاعدة البيانات';
  @override String get operatingMode => 'نمط التشغيل';
  @override String get licenseAndRights => 'الترخيص والحقوق';
  @override String get systemInfo => 'معلومات الإصدار والنظام';
  @override String get syncHub => 'مركز المزامنة والتحديث';
  @override String get expandSidebar => 'إظهار القائمة الجانبية الكاملة';
  @override String get collapseSidebar => 'إخفاء القائمة لتوسيع الشاشة';
  @override String get userOptions => 'خيارات المستخدم';
  @override String get logout => 'تسجيل الخروج';
  @override String get versionBadge => 'v1.0.2 (Build 2026.08)';

  // ── Tooltips ─────────────────────────────────────────────────────────────
  @override String get viewDetailsTooltip => 'عرض التفاصيل';
  @override String get editTooltip => 'تعديل السجل';
  @override String get printTooltip => 'طباعة وتصدير PDF';
  @override String get deleteTooltip => 'حذف / إيقاف التفعيل';
  @override String get syncHubTooltip => 'مركز مزامنة وتحديث الإنتاج';
  @override String get systemInfoTooltip => 'معلومات الإصدار والنظام';
  @override String get backToDashboardTooltip => 'العودة إلى لوحة التحكم';
  @override String get languageToggleTooltip => 'تغيير اللغة (عربي / إنجليزي)';

  // ── Role Switcher ─────────────────────────────────────────────────────────
  @override String get switchAsAdmin => 'تبديل كـ: مدير النظام 🔴';
  @override String get switchAsManager => 'تبديل كـ: مدير 🔵';
  @override String get switchAsSpecialist => 'تبديل كـ: أخصائي 🟢';
  @override String get productionSyncTitle => 'مزامنة ونشر الإنتاج';

  // ── Sidebar Search ────────────────────────────────────────────────────────
  @override String get quickSearch => 'بحث سريع...';

  // ── Operational Dashboard ───────────────────────────────────────────────────
  @override String get operationalDashboardTitle => 'لوحة التحكم ومساحة العمليات';
  @override String get priority => 'الأولوية:';
  @override String get priorityAll => 'الكل';
  @override String get priorityLow => 'منخفض';
  @override String get priorityMedium => 'متوسط';
  @override String get priorityHigh => 'عالي';
  @override String get priorityCritical => 'حرج';
  @override String get customsBrokerLabel => 'المخلص الجمركي:';
  @override String get allBrokers => 'جميع المخلصين';
  @override String get quickSearchLabel => 'بحث سريع:';
  @override String get dashboardSearchHint => 'كود الشحنة، PO، المورد...';
  @override String get resetFilters => 'إعادة ضبط الفلاتر';
  @override String get clearFilter => 'إلغاء التصفية';
  @override String get serverConnectionError => 'تعذر الاتصال بسيرفر الخادم';
  @override String get serverConnectionHint => 'يرجى التأكد من تشغيل خادم الباك إند أو الضغط على زر إعادة المحاولة.';
  @override String get matchingShipments => 'عدد الشحنات المطابقة';
  @override String get lastUpdated => 'آخر تحديث للبيانات';
  @override String get noMatchingShipments => 'لا توجد شحنات مطابقة';
  @override String get noMatchingShipmentsDesc => 'لم يتم العثور على أي شحنات تطابق خيارات التصفية الحالية.';
  @override String get clearFiltersShowAll => 'إلغاء الفلاتر وعرض الكل';
  @override String get currentPhase => 'المرحلة الحالية';
  @override String get operationalStep => 'الخطوة التشغيلية';
  @override String get unassigned => 'غير محدد';
  @override String get closedShipment => 'شحنة مغلقة';
  @override String get recordDailyUpdate => 'تسجيل تحديث يومي';
  @override String get closeStopShipment => 'إغلاق وإيقاف الشحنة';
  @override String get nextStepAction => '🎯 النقطة التالية والإجراء القادم:';
  @override String get responsiblePerson => 'المسؤول';
  @override String get executeStepNow => 'تنفيذ الخطوة الآن';
  @override String get openShipmentTasks => 'مهام الـ TO-DO المفتوحة للشحنة';
  @override String get manageAllTasks => 'إدارة كل المهام';
  @override String get taskCompletedSuccessfully => '✅ تم إنجاز المهمة بنجاح';
  @override String get riskAlertsCenter => 'مركز التنبيهات والمخاطر التشغيلية:';
  @override String get dailyCheckinsLog => 'سجل التحديثات التشغيلية واليومية المباشرة:';
  @override String get addDailyUpdate => 'إضافة تحديث يومي';
  @override String get noDailyUpdates => 'لا توجد تحديثات يومية مسجلة اليوم.';
  @override String get aiSmartExtractorTitle => 'أداة التكويد والاستخراج الذكي بالذكاء الاصطناعي:';
  @override String get smartExtractSupplier => 'تكويد مورد أجنبي ذكي 🌍';
  @override String get smartExtractCompany => 'تكويد شركة مستوردة ذكي 🏢';
  @override String get smartExtractPartner => 'تكويد شريك / مخلص ذكي 🤝';
  @override String get smartExtractBank => 'تكويد بنك معتمد ذكي 🏦';
  @override String get quickShortcutsTitle => 'روابط الاختصارات السريعة لإنشاء وإدخال السجلات:';
  @override String get createNewProject => 'إنشاء مشروع جديد';
  @override String get createNewImportFile => 'إنشاء ملف استيرادي';
  @override String get createNewImportCompany => 'إنشاء شركة مستوردة';
  @override String get createNewSupplier => 'إنشاء مورد خارجي';
  @override String get createNewPartnerBank => 'إنشاء بنك / شريك';
  @override String get createNewCustomsTariff => 'إدخال تعريفة جمركية';
  @override String get createNewLocation => 'إدخال موانئ ومواقع';
  @override String get createNewCurrency => 'إدخال عملة جديدة';
  @override String get createNewExchangeRate => 'تعديل سعر صرف جديد';
  @override String get interactiveOperationsBoardTitle => 'لوحة تتبع ومراحل الشحنات التفاعلية';
  @override String get interactiveOperationsBoardDesc => 'لوحة بصرية متكاملة مدمجة داخل البرنامج (6 مراحل كبرى — 21 خطوة تشغيلية) تدعم تتبع وتعدد المراحل النشطة ونقل الشحنات لحظياً.';
  @override String get openInteractiveBoard => 'فتح لوحة المراحل التفاعلية';
  @override String get lifecycleBoardSummaryTitle => 'ملخص مسار عمليات الشحنات (21 خطوة تشغيلية)';
  @override String get lifecycleBoardSummaryDesc => 'متابعة حية لتوزيع ملفات الشحنات عبر 6 مراحل رئيسية و 21 خطوة تشغيلية تفصيلية';
  @override String get fullOperationsBoardButton => 'لوحة مسار العمليات الكاملة (21 Steps) ↗️';
  @override String get shipmentCountUnit => 'شحنة';
  @override String get tasksCountUnit => 'مهام';
  @override String get kpiTodaysTasks => 'مهام اليوم';
  @override String get kpiTodaysTasksSub => 'المهام المطلوب تنفيذها اليوم';
  @override String get kpiPendingTasks => 'المهام المعلقة';
  @override String get kpiPendingTasksSub => 'المهام التي لم يتم الانتهاء منها';
  @override String get kpiUpcomingShipments => 'الشحنات القادمة';
  @override String get kpiUpcomingShipmentsSub => 'متوقع وصولها القادم';
  @override String get kpiArrivingThisWeek => 'شحنات هذا الأسبوع';
  @override String get kpiArrivingThisWeekSub => 'وصول بالأسبوع الحالي';
  @override String get kpiEtaChanges => 'تعديلات الـ ETA';
  @override String get kpiEtaChangesSub => 'تم تعديل موعد وصولها';
  @override String get kpiWaitingPayment => 'معلق للسداد';
  @override String get kpiWaitingPaymentSub => 'موافقات مالية معلقة (Phase 2)';
  @override String get kpiWaitingForm4 => 'بانتظار نموذج 4';
  @override String get kpiWaitingForm4Sub => 'إجراءات نموذج 4 بنك مصر';
  @override String get kpiPendingRequirements => 'متطلبات معلقة';
  @override String get kpiPendingRequirementsSub => 'مستندات وموافقات غير مكتملة';
  @override String get kpiHighPriorityAlerts => 'تنبيهات عالية الأولوية';
  @override String get kpiHighPriorityAlertsSub => 'أولوية عالي / حرج (Critical)';
  @override String get retry => 'إعادة المحاولة';
  @override String get purchaseOrder => 'أمر الشراء:';

  // ── Screen 1: Import Files & Shipments ────────────────────────────────────
  @override String get importFilesManagementTitle => 'إدارة وملفات استيراد الشحنات';
  @override String get uploadImportDocument => 'رفع وثيقة ملف استيراد (PDF / Word / Excel)';
  @override String get addNewImportFile => 'إضافة ملف استيراد شحنة جديد';
  @override String get editImportFile => 'تعديل وتحديث بيانات ملف الاستيراد';
  @override String get generateComprehensiveReport => 'استخراج تقرير الشحنات الشامل';
  @override String get searchByShipmentOrCompany => 'بحث بكود الشحنة أو الشركة...';
  @override String get statusAll => 'جميع الحالات';
  @override String get statusOpen => 'مفتوح';
  @override String get statusInProgress => 'قيد التنفيذ';
  @override String get statusClosed => 'مغلق';
  @override String get importFileIdLabel => 'رقم ملف الاستيراد';
  @override String get importingCompany => 'الشركة المستوردة';
  @override String get foreignSupplier => 'المورد الأجنبي';
  @override String get status => 'الحالة';
  @override String get actions => 'إجراءات';
  @override String get poInvoiceLabel => 'أمر الشراء / الفاتورة';
  @override String get transportModeIncoterm => 'وسيلة النقل / الشروط';
  @override String get priorityType => 'الأولوية';
  @override String get targetEta => 'الوصول المتوقع (ETA)';
  @override String get currentPhaseStage => 'المرحلة الحالية';
  @override String get progressPercentLabel => 'نسبة الإنجاز %';
  @override String get nextActionLabel => 'الخطوة القادمة';
  @override String get responsiblePersonLabel => 'المسؤول';
  @override String get stopShipmentTooltip => 'إغلاق وإيقاف الشحنة عند هذه المرحلة';
  @override String get reopenShipmentTooltip => 'إعادة فتح وتنشيط الشحنة المغلقة';
  @override String get freightRfqTooltip => 'طلب أسعار نولون الشحن';
  @override String get printFileHistoryTooltip => 'طباعة ملف الشحنة الشامل والتاريخ التشغيلي';
  @override String get noImportFilesFound => 'لا توجد ملفات استيراد مسجلة بالنظام. اضغط إضافة ملف جديد.';
  @override String get confirmDeleteImportFileTitle => 'تأكيد الحذف';
  @override String get confirmDeleteImportFileMessage => 'هل أنت متأكد من حذف ملف الاستيراد رقم';
  @override String get evaluateMasterReportTitle => 'استخراج وتقييم تقرير الشحنات الشامل';
  @override String get selectShipmentForReport => 'اختر رقم الشحنة / ملف الاستيراد المطلوب إنشاء التقرير المدمج الخاص بها:';
  @override String get allShipmentFiles => 'جميع الشحنات والملفات';
  @override String get shipmentNoPrefix => 'شحنة رقم:';
  @override String get createAndDisplayReport => 'إنشاء وعرض التقرير';
  @override String get masterImportReportTitle => 'تقرير ملخص ملفات الاستيراد المدمج والشامل';
  @override String get filteredForShipment => 'مصفى لحساب الشحنة رقم:';
  @override String get printReport => 'طباعة التقرير';
  @override String get filterReportByShipment => 'تصفية التقرير برقم الشحنة:';
  @override String get totalFilesMetric => 'إجمالي الملفات';
  @override String get openFilesMetric => 'الملفات المفتوحة';
  @override String get inProgressMetric => 'قيد التنفيذ';
  @override String get totalCostMetric => 'إجمالي التكلفة';
  @override String get operationalTrackingMatrixSection => '1. جدول التتبع العملياتي للشحنات';
  @override String get cargoAndLinkedPosSection => '2. ملخص الفواتير وأحجام التعبئة وأوامر الشراء التفصيلية لكل شحنة';
  @override String get invoicesCountAndNumbers => 'عدد الفواتير وأرقامها';
  @override String get invoicesUnit => 'فواتير';
  @override String get totalCbmFromPackingList => 'إجمالي الـ CBM من قوائم التعبئة';
  @override String get cbmSumDescription => 'مجموع CBM كافة قوائم التعبئة';
  @override String get totalGrossWeightFromPl => 'إجمالي الوزن القائم (Gross Wt)';
  @override String get grossWeightSumDescription => 'مجموع الوزن من كافة قوائم التعبئة';
  @override String get linkedPurchaseOrdersTitle => 'أوامر الشراء المرتبطة';
  @override String get posUnit => 'أوامر شراء';
  @override String get packingListsUnit => 'قوائم تعبئة';
  @override String get noLinkedPosForFile => 'لا توجد أوامر شراء مسندة حالياً لهذا الملف.';
  @override String get paymentTermsLabel => 'طريقة وشروط السداد';
  @override String get packingListItemsCol => 'قوائم التعبئة';
  @override String get weightCbmCol => 'الوزن / CBM';
  @override String get palletsShippingPlan => 'بالتة (مخطط الشحن)';
  @override String get packingItemsCount => 'بند تعبئة';
  @override String get visualLoadPlannerTitle => 'مخطط ومحاكاة رص الحاويات';
  @override String get containerLoadPlanButton => 'مخطط رص الحاويات (Load Plan)';
  @override String get exportReportExcelPdf => 'تصدير التقرير (Excel / PDF)';
  @override String get reportCopiedToClipboard => 'تم إعداد نسخة التقرير المدمجة ونقلها للحافظة بنجاح! جاهز للطباعة';
  @override String get csvExportSuccess => 'تم استخراج وتنزيل تقرير ملخص ملفات الاستيراد المدمج بصيغة CSV بنجاح!';
  @override String get sideViewTitle => 'مسقط جانبي (Side View)';
  @override String get topViewTitle => 'مسقط أفقي (Top View)';
  @override String get internalDimensions => 'الأبعاد الداخلية';
  @override String get containerLoadFailed => 'فشل التحميل (طرود كبيرة الحجم/الوزن)';
  @override String get containerOverfilled => 'ممتلئة طوليًا (أبعاد الممر تعوق الرص الجانبي)';
  @override String get containerEmpty => 'فاضية جدًا لسه (استغلال طول ومساحة ضعيف)';
  @override String get containerGoodUtil => 'استغلال جيد للمساحة';
  @override String get allStackableChip => 'بضائع تقبل الرص';
  @override String get allNonStackableChip => 'بضائع لا تقبل الرص';
  @override String get mixedStackingChip => 'مزيج يقبل ولا يقبل الرص';
  @override String get containerSpecType => 'نوع الحاوية';
  @override String get requiredCount => 'العدد المطلوب';
  @override String get effectiveCapacityCbm => 'السعة الفعالة CBM';
  @override String get spaceUtilizationPercent => 'استغلال المساحة %';
  @override String get weightUtilizationPercent => 'استغلال الوزن %';
  @override String get acidStatusTitle => 'بيانات القيد الجمركي المبدئي (ACID)';
  @override String get customsReleasedBadge => 'صُرفت من الجمرك (معفى من التنبيهات)';
  @override String get underClearanceBadge => 'قيد التخليص والصرف';
  @override String get cargoStackingScenariosTitle => 'نتائج احتمالات رص الحاويات وتوزيع الشحنة';
  @override String get scenariosMatrixButton => 'مقارنة الحالات (Matrix)';
  @override String get scenarioAllStackableTitle => 'الاحتمال الأول: بضائع تقبل الرص بالكامل';
  @override String get scenarioAllNonStackableTitle => 'الاحتمال الثاني: بضائع لا تقبل الرص';
  @override String get scenarioMixedStackingTitle => 'الاحتمال الثالث: مزيج يقبل ولا يقبل الرص';
  @override String get savedShippingStudiesTitle => 'دراسات وسيناريوهات الشحن المسجلة للشحنة';
  @override String get date => 'التاريخ';
  @override String get shipmentCategoryLabel => 'تصنيف الشحنة';
  @override String get fileOpeningDateLabel => 'تاريخ فتح الملف';
  @override String get logisticsAndPortsDetails => 'بيانات النقل وموانئ الشحن لطلب النولون';
  @override String get portOfLoadingLabel => 'ميناء الشحن (POL)';
  @override String get portOfDischargeLabel => 'ميناء الوصول والتفريغ (POD)';
  @override String get cargoReadyDateLabel => 'تاريخ جاهزية البضاعة (CRD)';
  @override String get targetFreeDaysLabel => 'أيام السماح المطلوبة (FT)';
  @override String get serviceTypePreferenceLabel => 'تفضيل مسار الخدمة';
  @override String get pickupAddressLabel => 'عنوان الاستلام / المصنع';
  @override String get shippingInstructionsLabel => 'تعليمات واشتراطات الشحن الخاصة';
  @override String get multiProjectsTitle => 'إسناد الشحنة للمشاريع';
  @override String get notes => 'الملاحظات والتعليمات';
  @override String get liveReload => 'إعادة تحميل حية';
  @override String get clearAndReset => 'تفريغ وبدء تسجيل جديد';
  @override String get customsClearanceBroker => 'المخلص الجمركي';
  @override String get freightRfqTitle => 'طلب أسعار نولون الشحن الدولي';
  @override String get emailDraftTab => 'نموذج الإيميل الرسمي';
  @override String get whatsappTemplateTab => 'رسالة الواتساب';
  @override String get shipmentSpecsTab => 'ملخص مواصفات الشحنة';
  @override String get grossWeightMetric => 'الوزن القائم (Gross)';
  @override String get netWeightMetric => 'الوزن الصافي (Net)';
  @override String get commodityTitle => 'اسم البضاعة';
  @override String get closeShipmentTitle => 'إيقاف وإغلاق الشحنة';
  @override String get reason => 'سبب الإيقاف والملاحظات';
  @override String get cbmVolumeMetric => 'الحجم الإجمالي (CBM)';
  @override String get currency => 'العملة';
  @override String get owner => 'المسؤول';
  @override String get purchaseOrdersTitle => 'أوامر الشراء والفواتير المبدئية';
  @override String get purchaseOrdersSubtitle => 'المرحلة الأولى: إدارة وتسجيل أوامر الشراء، الفواتير المبدئية، وحساب الـ CBM والأوزان الإجمالية';
  @override String get smartInvoiceExtract => 'استخراج الفاتورة والتعبئة الذكي';
  @override String get newPurchaseOrder => 'أمر شراء جديد';
  @override String get editPurchaseOrder => 'تعديل أمر الشراء';
  @override String get totalOrdersMetric => 'إجمالي أوامر الشراء';
  @override String get totalFobMetric => 'إجمالي قيمة البضاعة';
  @override String get totalCargoCbmMetric => 'إجمالي الحجم CBM';
  @override String get totalGrossWeightMetric => 'إجمالي الوزن القائم';
  @override String get searchByPoHint => 'بحث برقم أمر الشراء أو الفاتورة أو الملاحظات...';
  @override String get filterByProject => 'تصفية حسب المشروع';
  @override String get allProjects => 'جميع المشاريع';
  @override String get filterByStatus => 'تصفية حسب الحالة';
  @override String get allStatuses => 'جميع الحالات';
  @override String get showInactive => 'إظهار غير النشط';
  @override String get poReferenceCol => 'رقم أمر الشراء';
  @override String get invoiceDateCol => 'تاريخ الفاتورة';
  @override String get importFileCol => 'ملف الاستيراد';
  @override String get piNumberCol => 'رقم الفاتورة المبدئية';
  @override String get countryOfOriginCol => 'بلد المنشأ';
  @override String get actionsCol => 'الإجراءات';
  @override String get poLineItemsTab => 'بنود الفاتورة المبدئية';
  @override String get reviewPackingListTab => 'بيان التعبئة والوزن';
  @override String get palletizationPlanTitle => 'مخطط وحدات الشحن والبالتات';
  @override String get totalPalletsMetric => 'إجمالي البالتات';
  @override String get palletSimulation3D => 'محاكاة ورص الحاويات 3D';
  @override String get palletTypeCol => 'نوع ومقاس البالتة';
  @override String get palletCountCol => 'عدد البالتات';
  @override String get palletDimensionsCol => 'الأبعاد (L × W × H)';
  @override String get palletWeightCol => 'وزن البالتة (Gross)';
  @override String get palletTotalWeightCol => 'إجمالي الوزن';
  @override String get palletVolumeCol => 'حجم السطر CBM';
  @override String get palletStackingInstructionsCol => 'تعليمات الرص';
  @override String get stackable => 'قابل للرص';
  @override String get nonStackable => 'غير قابل للرص';
  @override String get discrepancyWarningTitle => 'تنبيه: عدم تطابق بين الفاتورة المبدئية وبيان التعبئة';
  @override String get discrepancyJustificationLabel => 'سبب الاستمرار وتبرير الاختلاف';
  @override String get backToEdit => 'الرجوع للتعديل';
  @override String get continueAndSave => 'الاستمرار وحفظ أمر الشراء';
  @override String get summaryByHsCodeReport => 'ملخص بيان التعبئة حسب البند الجمركي';
  @override String get hsCode => 'البند الجمركي';
  @override String get quantityMetric => 'الكمية';
  @override String get requiredField => 'هذا الحقل مطلوب';
  @override String get saveChanges => 'حفظ التعديلات';
  @override String get noDataFound => 'لا توجد بيانات مسجلة';

  // ── CBM Calculator ───────────────────────────────────────────────────────
  @override String get cbmCalculatorTitle => 'حاسبة الأحجام والوزن الجوي';
  @override String get cbmCalculatorSubtitle => 'احتساب الأحجام CBM، الوزن الجوي المحاسبي، وتوصيات الحاويات ووسيلة الشحن';
  @override String get quickOperationalCalculatorTab => 'حاسبة القياسات التشغيلية السريعة';
  @override String get savedCalculationsRegistryTab => 'سجل دراسة وحسابات الشحن المحفوظة';
  @override String get activeEditSessionBanner => 'وضع تعديل جلسة محفوظة';
  @override String get activeEditSessionHint => 'يتم الآن تعديل طرود وقياسات هذه الجلسة. يمكنك حفظ التعديلات مباشرة في نفس الجلسة أو كجلسة جديدة.';
  @override String get saveChangesInSession => 'حفظ التعديلات في الجلسة';
  @override String get newBlankSession => 'جلسة جديدة فارغة';
  @override String get totalCbmVolumeMetric => 'إجمالي الحجم (CBM)';
  @override String get airChargeableWtMetric => 'الوزن الجوي المحاسبي';
  @override String get volumetricWeight => 'الوزن الحجمي';
  @override String get recommendedShippingMetric => 'وسيلة الشحن المقترحة';
  @override String get cargoStackingInstructions => 'تعليمات التحميل والرص:';
  @override String get stackableOption => 'قابل للرص';
  @override String get nonStackableOption => 'غير قابل للرص';
  @override String get allStackableOption => 'بضائع تقبل الرص';
  @override String get allNonStackableOption => 'بضائع لا تقبل الرص';
  @override String get mixedStackingOption => 'مزيج يقبل ولا يقبل الرص';
  @override String get compareContainersMatrix => 'مقارنة خيارات الحاويات';
  @override String get visualLoadPlanSimulator => 'مخطط ومحاكاة رص الحاويات';
  @override String get packageMeasurementsTitle => 'أبعاد وأوزان طرود الشحنة';
  @override String get airFreightMode => 'شحن جوي';
  @override String get seaFreightMode => 'شحن بحري';
  @override String get addPackageLine => 'إضافة سطر طرد';
  @override String get saveCalculationSession => 'حفظ الجلسة التشغيلية';
  @override String get saveAsNewSession => 'حفظ كجلسة جديدة';
  @override String get unitCol => 'الوحدة';
  @override String get qtyCol => 'العدد';
  @override String get lengthCol => 'الطول';
  @override String get widthCol => 'العرض';
  @override String get heightCol => 'الارتفاع';
  @override String get stackingCol => 'الرص';
  @override String get grossWtPerUnitCol => 'وزن الوحدة (كجم)';
  @override String get calculatedOutputsCol => 'النتائج المحسوبة';
  @override String get deleteRowTooltip => 'حذف السطر';
  @override String get packageTypeCol => 'نوع الطرد';
  @override String get calculationSessionTitle => 'عنوان جلسة الحساب';
  @override String get notesAndCargoRemarks => 'ملاحظات ومواصفات البضاعة';
  @override String get containerOptionsAnalysis => 'تحليل خيارات الحاويات وسيناريوهات التحميل';
  @override String get totalShipmentSummary => 'إجمالي الشحنة';
  @override String get approvedRecommendation => 'التوصية المعتمدة';
  @override String get containerSpecCol => 'نوع ومواصفات الحاوية';
  @override String get requiredCountCol => 'العدد المطلوب';
  @override String get spaceUtilizationCol => 'استغلال المساحة %';
  @override String get weightUtilizationCol => 'استغلال الوزن %';
  @override String get recommendationCol => 'التوصية';
  @override String get bestOptionBadge => 'الخيار الأنسب';
  @override String get viableAlternative => 'بديل قابل للتطبيق';
  @override String get chooseStackingScenario => 'اختر سيناريو الرص للمعاينة:';
  @override String get requiredFleet => 'الأسطول المطلوب:';
  @override String get containerPlanTitle => 'مخطط رص الحاوية';
  @override String get closePlan => 'إغلاق المخطط';
  @override String get totalCalculationsMetric => 'إجمالي الحسابات';
  @override String get activeSessionsMetric => 'جلسات نشطة';
  @override String get totalGrossWeightRegistryMetric => 'إجمالي الوزن القائم';
  @override String get refreshRegistry => 'تحديث السجل';
  @override String get searchCalculationsHint => 'ابحث بكود الحساب، العنوان، ملف الشحنة، أو الملاحظات...';
  @override String get calcCodeCol => 'كود الحساب';
  @override String get shippingStrategyCol => 'استراتيجية الشحن';
  @override String get recommendedContainerCol => 'الحاوية المقترحة';
  @override String get linkPoProjectCol => 'الارتباط (أمر شراء / مشروع)';
  @override String get confirmSoftDelete => 'تأكيد الحذف المنطقي';
  @override String get confirmDeleteCalcMessage => 'هل أنت متأكد من حذف جلسة الحساب هذه؟ يمكن استعادتها لاحقاً من قائمة إظهار الملغية.';
  @override String get operationFailed => 'فشلت العملية';
  @override String get operationSuccessful => 'تمت العملية بنجاح';
  @override String get showDeleted => 'إظهار الملغية';
  @override String get hideDeleted => 'إخفاء الملغية';
  @override String get restore => 'استعادة';
  @override String cbmSessionDetailsTitle(String code) => 'تفاصيل دراسة الأحجام والأوزان ($code)';
  @override String get cbmSessionActiveBadge => 'جلسة نشطة';
  @override String get cbmSessionCancelledBadge => 'جلسة ملغاة';
  @override String cbmSessionLinkedPo(String po) => 'أمر شراء: $po';
  @override String cbmSessionImportFile(String file) => 'ملف: $file';
  @override String get cbmSessionStandalone => 'جلسة مستقلة';
  @override String cbmCargoNotes(String notes) => 'ملاحظات الشحنة: $notes';
  @override String cbmCreationDate(String date) => 'تاريخ الإنشاء: $date';
  @override String cbmStrategy(String strategy) => 'الاستراتيجية: $strategy';
  @override String get cbmStandardMetricsTitle => 'المؤشرات القياسية ومحددات الشحن:';
  @override String get cbmContainerComparisonTitle => 'مقارنة سيناريوهات الحاويات:';
  @override String get cbmScenarioApprovedStackable => 'المعتمد: سيناريو القابل للرص';
  @override String get cbmScenarioApprovedNonStackable => 'المعتمد: سيناريو غير القابل للرص';
  @override String get cbmScenarioHypothesisCol => 'السيناريو والفرضية';
  @override String get cbmScenarioStackableCol => 'سيناريو يقبل الرص';
  @override String get cbmScenarioNonStackableCol => 'سيناريو لا يقبل الرص';
  @override String get cbmRequiredContainerCount => 'الحاوية والعدد المطلوب';
  @override String get cbmSpaceUtilizationPercent => 'نسبة استغلال المساحة %';
  @override String get cbmReopenInCalcBtn => 'إعادة فتح وتعديل في الحاسبة';
  @override String get cbmEditMetadataBtn => 'تعديل البيانات';
  @override String get cbmLinkToPoProjectBtn => 'ربط بأمر شراء / مشروع';
  @override String get cbmPrintExportReportBtn => 'طباعة وتصدير التقرير';
  @override String cbmEditMetadataDialogTitle(String code) => 'تعديل بيانات الجلسة: $code';
  @override String get cbmMetadataTitleLabel => 'عنوان دراسة القياسات *';
  @override String get cbmMetadataNotesLabel => 'ملاحظات وبيان الشحنة';
  @override String get cbmMetadataSavedSuccess => 'تم تحديث بيانات الجلسة بنجاح';
  @override String cbmPrintableReportTitle(String code) => 'تقرير احتساب حجوم وأوزان الشحنة ($code)';
  @override String get cbmPrintDownloadCsvBtn => 'تنزيل ملف بيانات CSV';
  @override String get cbmPrintReportBtn => 'طباعة التقرير';
  @override String cbmLinkPoDialogTitle(String code) => 'ربط الجلسة ($code) بشحنة وأمر شراء';
  @override String get cbmLinkSelectPoLabel => 'اختر أمر الشراء';
  @override String get cbmLinkSelectPoSearchHint => 'ابحث عن أمر الشراء...';
  @override String get cbmLinkSelectProjectLabel => 'اختر المشروع';
  @override String get cbmLinkSelectProjectSearchHint => 'ابحث عن المشروع...';
  @override String get cbmLinkSavedSuccess => 'تم ربط سجل الحسابات بنجاح';
  @override String get cbmVisualPlannerTitle => 'مخطط ومحاكاة رص الحاويات';
  @override String get cbmFloorAreaUtilization => 'استغلال أرضية الحاوية';
  @override String get cbmWoodenPalletsFloor => 'طبالي خشبية أرضية';
  @override String get cbmInternalDimensionsLabel => 'الأبعاد الداخلية:';
  @override String get cbmPackageDimensionsCol => 'الأبعاد L x W x H (cm)';

  // ── Freight Studies (Shipping Scenarios) ───────────────────────────────────
  @override String get freightStudiesTitle => 'دراسات وسيناريوهات الشحن والمفاضلة';
  @override String get scenariosEvaluatorTab => 'دراسة وسيناريوهات الشحن';
  @override String get savedEvaluationsLogTab => 'سجل الدراسات المحفوظة';
  @override String get extractFreightQuotes => 'استخراج عروض أسعار النولون';
  @override String get activeEditStudyBanner => 'وضع تعديل دراسة محفوظة';
  @override String get activeEditStudyHint => 'يتم الآن تعديل خيارات وعروض هذه الدراسة. سيتم حفظ التعديلات على نفس الدراسة.';
  @override String get cancelEditAndStartNew => 'إلغاء التعديل والبدء من جديد';
  @override String get avgWarehouseArrivalMetric => 'متوسط موعد التوصيل للمخزن';
  @override String get earliestLineMetric => 'أسرع خط ملاحي وصولاً';
  @override String get latestLineMetric => 'أبطأ خط ملاحي وصولاً';
  @override String get recommendedLineMetric => 'الخط الموصى به رسمياً';
  @override String get studySetupAndParameters => 'إعدادات ومعلمات دراسة الشحن';
  @override String get studyTitleLabel => 'مسمى دراسة خيارات الشحن';
  @override String get crdLabel => 'تاريخ جاهزية البضاعة (CRD)';
  @override String get avgForm4DaysLabel => 'أيام نموذج 4 المتوقعة';
  @override String get avgClearanceDaysLabel => 'أيام التخليص الجمركي المتوقعة';
  @override String get cargoStackingType => 'نوع التحميل والتخزين';
  @override String get shippingCarrierOptions => 'خيارات وعروض شحن الشركات';
  @override String get addNewShippingOption => 'إضافة خيار شحن جديد';
  @override String get freightForwarderCol => 'وكيل الشحن / الناقل';
  @override String get shippingLineCol => 'الخط الملاحي';
  @override String get vesselNameCol => 'اسم الباخرة / الرحلة';
  @override String get voyageCol => 'رقم الرحلة';
  @override String get portOfLoadingCol => 'ميناء السفر / التحميل (POL)';
  @override String get portOfDischargeCol => 'ميناء الوصول / التفريغ (POD)';
  @override String get sailingDateCol => 'تاريخ الإبحار (ETD)';
  @override String get estimatedArrivalDateCol => 'تاريخ الوصول المتوقع (ETA)';
  @override String get expectedDelayCol => 'أيام التأخير المتوقعة';
  @override String get riskLevelCol => 'مستوى المخاطر';
  @override String get freeTimeDaysCol => 'أيام السماح (Free Time)';
  @override String get quoteCurrencyCol => 'عملة عرض السعر';
  @override String get quoteDetails => 'تفاصيل عرض السعر';
  @override String get hideQuote => 'إخفاء عرض السعر';
  @override String get totalQuoteValue => 'إجمالي قيمة العرض';
  @override String get container40ftItem => 'شحن حاوية 40 قدم';
  @override String get container20ftItem => 'شحن حاوية 20 قدم';
  @override String get lclCbmItem => 'شحن CBM لشحنة LCL';
  @override String get expressCourierItem => 'البريد السريع للمستندات';
  @override String get eurAtrItem => 'شهادة المنشأ (EUR.1 / ATR)';
  @override String get solasVgmItem => 'مصاريف التحقق من الوزن (SOLAS/VGM)';
  @override String get vgmNotificationItem => 'إخطار إقرار الوزن (VGM Notification)';
  @override String get telexReleaseItem => 'إطلاق الفاكس الملاحي (Telex Release)';
  @override String get insuranceItem => 'بوليصة التأمين البحري';
  @override String get bookingCancellationItem => 'غرامة إلغاء الحجز';
  @override String get ics2FilingFeeItem => 'رسوم إيداع بيان الحمول الرقمية (ICS2)';
  @override String get documentFeesItem => 'مصاريف المستندات الإضافية';
  @override String get waiverLetterFeeItem => 'مصاريف خطاب التنازل';
  @override String get othersFeeItem => 'مصاريف أخرى';
  @override String get dthcItem => 'تفريغ ومناولة ميناء الوصول (DTHC)';
  @override String get storagePerWeekItem => 'أرضيات / تخزين لأول أسبوع';
  @override String get extraDayStorageItem => 'أرضيات / تخزين لليوم الإضافي';
  @override String get applicable => 'مطبق';
  @override String get notApplicable => 'غير مطبق';
  @override String get itemPriceCol => 'سعر البند';
  @override String get sideBySideComparison => 'جدول المقارنة التفصيلي لخيارات الشحن';
  @override String get saveAndSubmitStudy => 'حفظ الدراسة والنتائج';
  @override String get saveDraftContinueLater => 'حفظ مؤقت ومتابعة لاحقة';
  @override String get clearAndStartNew => 'تفريغ وبدء تسجيل جديد';
  @override String get totalStudiesMetric => 'إجمالي الدراسات';
  @override String get avgTransitMetric => 'متوسط الترانزيت';
  @override String get withRecommendationMetric => 'مع توصية';
  @override String get searchStudiesHint => 'ابحث بكود الدراسة، العنوان، أو الملاحظات...';
  @override String get studyCodeCol => 'كود الدراسة';
  @override String get optionsCountCol => 'عدد الخيارات';
  @override String get confirmDeleteStudyMessage => 'هل أنت متأكد من حذف هذه الدراسة؟ يمكن استعادتها لاحقاً من قائمة إظهار الملغية.';
  @override String get quantity => 'الكمية';
  @override String get activeStatus => 'نشطة';
  @override String get noResultsFound => 'لا توجد نتائج مطابقة للبحث';
  @override String get linkImportFile => 'ربط بملف استيراد';
  @override String get titleField => 'العنوان';
  @override String get linkPurchaseOrder => 'ربط بأمر الشراء';
  @override String get linkProject => 'ربط بمشروع';
  @override String get confirmDelete => 'تأكيد الحذف';
  @override String get view => 'عرض';
  @override String get statusCol => 'الحالة';

  // ── Screen 6: Customs Studies & Consultations ──────────────────────────
  @override String get customsStudiesTitle => 'مركز الاستشارة والفحص ومراجعة الضرائب الجمركية';
  @override String get customsWorkspaceTab => 'مركز الاستشارة والفحص الجمركي';
  @override String get consultationsLogTab => 'سجل الدراسات المحفوظة';
  @override String get brokerPriceListsTab => 'قوائم الأسعار وتكويد المصروفات';
  @override String get clearanceQuotesTab => 'عروض التخليص والاستخراج الذكي';
  @override String get taxReviewWorkspaceTab => 'مركز احتساب ومراجعة الضرائب';
  @override String get taxReviewLogTab => 'سجل مراجعات الضرائب المحفوظة';
  @override String get customsDutyReviewTitle => 'مركز مراجعة واحتساب الضرائب والرسوم الجمركية';
  @override String get customsInspectionReadiness => 'جاهزية الفحص الجمركي';
  @override String get itemsAndDocsCount => 'عدد البنود والمستندات';
  @override String get blockingIssuesCount => 'عوائق التخليص';
  @override String get clearanceReadyStatus => 'جاهزة للتخليص';
  @override String get avgReadinessMetric => 'متوسط الجاهزية';
  @override String get openBlockingIssues => 'عوائق مفتوحة';
  @override String get searchConsultationsHint => 'بحث بالكود أو العنوان أو المستخلص...';
  @override String get statusFilterLabel => 'تصفية الحالة';
  @override String get customsCalculationEngine => 'محرك حساب الرسوم والضرائب الجمركية للشحنة';
  @override String get customsCalculationEngineSub => 'يستدعي بنود HS Code والقيم والاشتراطات تلقائياً من ملف الشحنة وأوامر الشراء المربوطة ويحسب الجمارك والـ VAT ورسم التنمية';
  @override String get fetchReconciledFinalInvoice => 'استدعاء بنود وقيم الفاتورة والباكينج ليست النهائية المعتمدة';
  @override String get syncHsRequirementsToChecklist => 'مزامنة اشتراطات الـ HS Codes مع قائمة المستندات';
  @override String get customsExchangeRate => 'سعر الصرف الجمركي';
  @override String get studyDateLabel => 'تاريخ الدراسة الجمركية';
  @override String get freightEgpLabel => 'النولون البحري/الجوي';
  @override String get insuranceEgpLabel => 'التأمين البحري';
  @override String get customsTariffItemCol => 'بند التعريفة';
  @override String get itemDescriptionAndOriginCol => 'بيان الصنف والمنشأ';
  @override String get quantityAndUnitCol => 'الكمية والوحدة';
  @override String get fobEgpCol => 'القيمة FOB';
  @override String get cifEgpCol => 'القيمة الجمركية CIF';
  @override String get customsDutyCol => 'ضريبة الوارد';
  @override String get vatCol => 'ضريبة القيمة المضافة';
  @override String get otherTaxesCol => 'ض.جدول / تنمية / خدمات';
  @override String get totalTaxesAndDutiesCol => 'إجمالي الضرائب والرسوم';
  @override String get regulatoryRequirementsCol => 'الاشتراطات والعروض';
  @override String get customsChecklistTitle => 'قائمة فحص واشتراطات المستندات الجمركية';
  @override String get addNewChecklistItem => 'إضافة بند جديد للفحص';
  @override String get responsiblePartyLabel => 'الجهة المسؤولة';
  @override String get blockingConditionTooltip => 'بند يعطل الإفراج الجمركي';
  @override String get nonBlockingConditionTooltip => 'بند غير معطل للإفراج';
  @override String get applyAndLinkFinancialEstimate => 'اعتماد وربط التقدير المالي للدراسة';
  @override String get smartClearanceQuoteExtractor => 'استخراج ذكي لمقايسة تخليص';
  @override String get saveCustomsStudy => 'حفظ دراسة الاستشارة الجمركية';
  @override String get saveTaxReviewSession => 'حفظ جلسة مراجعة الضرائب الجمركية';
  @override String get saveConsultationChanges => 'حفظ تعديلات المراجعة الجمركية';
  @override String get consultationDetailsTitle => 'تفاصيل دراسة ومراجعة التخليص الجمركي';
  @override String get blockingIssuesTitle => 'تقرير عوائق واشتراطات التخليص الجمركي المفتوحة';
  @override String get nafezaDeclarationBreakdown => 'تفاصيل بنود التحصيل وإقرار نافذة الجمركي';
  @override String get categoryCol => 'التصنيف';
  @override String get totalExpenses => 'إجمالي المصروفات';
  @override String get export => 'تصدير';
  @override String get allFiles => 'جميع الملفات';
  @override String get requiredDocCheckbox => 'مستند إلزامي';
  @override String get blockingShipmentCheckbox => 'مانع للشحن والتخليص';
  @override String get responsibleCustomsBroker => 'المستخلص الجمركي';
  @override String get responsibleSupplierExporter => 'المورد / المصدر الأجنبي';
  @override String get responsibleImporterTeam => 'فريق الاستيراد بالشركة';
  @override String get responsibleFreightForwarder => 'وكيل الشحن والنقل';
  @override String get validationIssuesTitle => 'تنبيهات واستيفاء بيانات الدراسة';
  @override String get validationIssuesDesc => 'يرجى استكمال البيانات الإلزامية التالية لتتمكن من حفظ الدراسة بنجاح.';
  @override String get validationTitleRequired => 'عنوان / موضوع الاستشارة الجمركية';
  @override String get validationTitleRequiredDesc => 'حقل إلزامي لا يمكن تركه فارغاً.';
  @override String get validationTitleRequiredRec => 'يرجى كتابة عنوان واضح وموجز لموضوع دراسة الفحص والاستشارة الجمركية.';
  @override String get validationBrokerRequired => 'المستخلص الجمركي المعني';
  @override String get validationBrokerRequiredDesc => 'لم يتم تحديد المستخلص الجمركي المسؤول عن دراسة الملف.';
  @override String get validationBrokerRequiredRec => 'يرجى اختيار المستخلص الجمركي من القائمة المنسدلة.';
  @override String get validationChecklistRequired => 'قائمة الفحص والمستندات الجمركية';
  @override String get validationChecklistRequiredDesc => 'قائمة فحص المستندات والاشتراطات فارغة تماماً.';
  @override String get validationChecklistRequiredRec => 'يرجى إضافة مستند أو اشتراط واحد على الأقل في قائمة الفحص.';
  @override String get consultationReviewChangesTitle => 'مراجعة وتأكيد تعديلات الدراسة الجمركية';
  @override String get sectionGeneralInfo => 'البيانات العامة للدراسة';
  @override String get sectionBrokerInfo => 'المستخلص الجمركي';
  @override String get sectionFinancialEstimates => 'التقديرات المالية';
  @override String get sectionOperationalLink => 'الربط التشغيلي';
  @override String get sectionChecklistDocs => 'قائمة فحص المستندات';
  @override String get totalDocsCountLabel => 'إجمالي عدد المستندات والاشتراطات';
  @override String docsCountSuffix(dynamic count) => '$count مستند';
  @override String get activeEditBannerDesc => 'قم بتعديل بيانات الفحص والمستندات والرسوم ثم اضغط "حفظ التعديلات" لتحديث الدراسة نفسها، أو "حفظ كنسخة جديدة" لإنشاء دراسة منفصلة.';
  @override String activeEditBannerTitle(dynamic code) => 'وضع التعديل النشط: أنت الآن تقوم بتعديل دراسة الاستشارة الجمركية رقم ($code)';
  @override String get saveEditsBtn => 'حفظ التعديلات';
  @override String get saveAsNewCopyBtn => 'حفظ كنسخة جديدة';
  @override String get cancelEditTooltip => 'إلغاء التعديل والعودة كدراسة جديدة فارغة';
  @override String get convertedToNewSessionToast => 'تم تحويل الجلسة إلى دراسة جديدة منفصلة، اضغط "حفظ دراسة الاستشارة الجمركية" للحفظ';
  @override String get defaultStudyTitleClearance => 'دراسة المراجعة الجمركية الأولية لخط إنتاج ومعدات الشحنة';
  @override String get defaultStudyTitleTaxReview => 'مراجعة واحتساب الضرائب والرسوم الجمركية للشحنة';
  @override String get varianceCol => 'الفارق والتغير';
  @override String get preliminaryPoLabel => 'مبدئي:';
  @override String get recalculatedLabel => 'المعاد احتسابه:';
  @override String get varianceLabel => 'الفارق:';
  @override String get originPrefix => 'المنشأ:';
  @override String get applyRecalculatedDutiesTitle => 'اعتماد وتطبيق الرسوم الجمركية والضرائب الجديدة';
  @override String applyRecalculatedDutiesSuccess(dynamic amount) => 'تم اعتماد وتطبيق قيمة الرسوم الجمركية والضرائب الجديدة ($amount ج.م). يمكنك الآن حفظ أو تحديث الدراسة الجمركية.';
  @override String get selectImportFileFirstWarning => 'يرجى اختيار ملف الشحنة الاستيرادية أولاً لاستدعاء الفاتورة النهائية.';
  @override String recalculationSuccessMsg(dynamic num) => 'تم استدعاء بنود وقيم الفاتورة والباكينج ليست النهائية المعتمدة بنجاح ($num) وإعادة احتساب الرسوم بدقة.';
  @override String get recalculationFallbackMsg => 'تم احتساب الرسوم بناءً على بنود أمر الشراء المبدئي لعدم وجود جلسة مطابقة نهائية معتمدة بعد.';
  @override String recalculationErrorMsg(dynamic err) => 'تعذر استدعاء وإعادة احتساب البنود: $err';
  @override String get applyAllQuoteItems => 'تطبيق الكل';
  @override String get disableAllQuoteItems => 'تعطيل الكل';
  @override String get addCustomExpenseRow => 'إضافة مصروف إضافي';
  @override String get quoteItemApplicable => 'مطبق';
  @override String get quoteItemNotApplicable => 'غير مطبق';
  @override String get quoteItemPrice => 'سعر البند';
  @override String get quoteItemQuantity => 'الكمية';
  @override String get quoteItemCurrency => 'العملة';
  @override String get selectBrokerFirstMsg => 'يرجى اختيار المستخلص الجمركي لعرض وتطبيق قائمة أسعاره المعتمدة.';
  @override String get filterByBroker => 'تصفية حسب المخلص الجمركي';
  @override String get searchBrokerHint => 'ابحث عن مخلص...';
  @override String get createBrokerPriceListBtn => 'إنشاء قائمة أسعار جديدة لمخلص';
  @override String get noBrokerPriceListsFound => 'لا توجد قوائم أسعار مسجلة للمخلصين المحددين.';
  @override String get addPriceListNowBtn => 'إضافة قائمة أسعار الآن';
  @override String get activePriceListStatus => 'سارية';
  @override String get archivedPriceListStatus => 'مؤرشفة';
  @override String get editPricesAndItemsBtn => 'تعديل الأسعار والبنود';
  @override String get archivePriceListTooltip => 'أرشفة قائمة الأسعار';
  @override String get confirmArchivePriceListTitle => 'تأكيد أرشفة قائمة الأسعار';
  @override String confirmArchivePriceListMsg(dynamic title) => 'هل أنت متأكد من رغبتك في أرشفة قائمة الأسعار "$title"؟';
  @override String get archiveBtn => 'أرشفة';
  @override String get priceListNotesHeader => 'ملاحظات وشروط:';
  @override String get expenseItemNameCol => 'اسم المصروف / البند';
  @override String get expenseCategoryCol => 'التصنيف';
  @override String get expenseUnitCol => 'الوحدة';
  @override String get standardPriceCol => 'السعر المعتمد';
  @override String get priceRangeAndNotesCol => 'نطاق السعر / ملاحظات';
  @override String get searchExpenseCatalogHint => 'بحث في دليل المصروفات...';
  @override String get addNewExpenseTypeBtn => 'تكويد نوع مصروف جديد';
  @override String get expenseCodeCol => 'الكود';
  @override String get expenseNameArCol => 'اسم المصروف (عربي)';
  @override String get expenseNameEnCol => 'اسم المصروف (إنجليزي)';
  @override String get calculationUnitCol => 'وحدة الحساب';
  @override String get defaultCurrencyCol => 'العملة الافتراضية';
  @override String get newExpenseTypeDialogTitle => 'تكويد نوع مصروف جديد في الدليل';
  @override String get expenseCodeField => 'كود المصروف';
  @override String get expenseNameArField => 'اسم المصروف بالعربية *';
  @override String get expenseNameEnField => 'اسم المصروف بالإنجليزية (اختياري)';
  @override String get defaultCalculationUnitField => 'وحدة الحساب الافتراضية';
  @override String get saveExpenseBtn => 'حفظ المصروف';
  @override String get noBrokersRegistered => 'لا يوجد مخلصين جمركيين مسجلين في الشركاء.';
  @override String editPriceListTitle(dynamic title) => 'تعديل وتحديث أسعار قائمة المستخلص: $title';
  @override String get createPriceListTitle => 'إنشاء وتحديد أسعار قائمة جديدة للمستخلص الجمركي';
  @override String get priceListTitleField => 'عنوان قائمة الأسعار *';
  @override String get targetPortField => 'الميناء المعني';
  @override String get effectiveDateField => 'تاريخ السريان';
  @override String get generalTermsAndNotesField => 'ملاحظات وشروط عامة';
  @override String get filterCategoryLabel => 'تصفية التصنيف';
  @override String get allCategoriesItem => 'جميع التصنيفات';
  @override String get fillStandardRatesBtn => 'تعبئة بالأسعار الاسترشادية';
  @override String get zeroOutRatesBtn => 'تصفير الكل';
  @override String get standardRatesFilledToast => 'تم استدعاء وتعبئة الأسعار الاسترشادية القياسية المصرية بنجاح!';
  @override String get approvedPriceField => 'السعر المعتمد *';
  @override String get notesPriceRangeField => 'ملاحظات / نطاق السعر';
  @override String totalExpensesCountSummary(dynamic total, dynamic priced) => 'إجمالي بنود المصروفات بالقائمة: $total بند ($priced بند مسعر بقيمة)';
  @override String get savePriceListEditsBtn => 'حفظ تعديلات القائمة';
  @override String get createAndSavePriceListBtn => 'إنشاء وحفظ قائمة الأسعار';
  @override String get priceListTitleRequired => 'يرجى كتابة عنوان قائمة الأسعار.';
  @override String get selectBrokerRequired => 'الرجاء اختيار المستخلص الجمركي';
  @override String get priceListUpdatedSuccess => 'تم تحديث وتعديل أسعار القائمة بنجاح!';
  @override String get priceListCreatedSuccess => 'تم إنشاء قائمة أسعار المخلص وحفظ الأسعار بنجاح!';
  @override String get showArchivedChip => 'إظهار المؤرشفة';
  @override String get hideArchivedChip => 'إخفاء المؤرشفة';
  @override String get restoreConsultationTitle => 'استعادة دراسة الاستشارة';
  @override String restoreConsultationMsg(dynamic code, dynamic title) => 'هل ترغب في استعادة وتفعيل دراسة الاستشارة الجمركية "$code - $title"؟';
  @override String get restoreAndActivateBtn => 'استعادة وتفعيل';
  @override String restoreConsultationSuccess(dynamic code) => 'تم استعادة وتفعيل دراسة الاستشارة ($code) بنجاح';
  @override String get deleteConsultationTitle => 'تأكيد حذف الدراسة';
  @override String deleteConsultationMsg(dynamic code, dynamic title) => 'هل أنت متأكد من حذف دراسة الاستشارة الجمركية "$code - $title"؟\n\nسيتم أرشفة الدراسة مع إمكانية استعادتها لاحقاً.';
  @override String get deleteAndArchiveBtn => 'حذف وأرشفة';
  @override String deleteConsultationSuccess(dynamic code) => 'تم حذف وأرشفة دراسة الاستشارة ($code) بنجاح';
  @override String get restoreDeletedTooltip => 'استعادة الدراسة المحذوفة';
  @override String get deleteStudyTooltip => 'حذف الدراسة (أرشفة منطقية)';
  @override String blockingIssuesBadge(dynamic count) => '$count عائق';
  @override String approvedDocsCountBadge(dynamic approved, dynamic total) => '$approved/$total مستند معتمد';
  @override String get agreementEur1 => 'اتفاقية الشراكة المصرية الأوروبية';
  @override String get agreementEur1Doc => 'شهادة حركة البضائع أصلية أو إعلان الفاتورة للمصدر المعتمد';
  @override String agreementEur1Exemption(dynamic rate) => 'إعفاء جمركي كامل لضريبة الوارد (0% بدلاً من $rate%) بموجب اتفاقية الشراكة المصرية الأوروبية.';
  @override String get agreementMercosur => 'اتفاقية التجارة الحرة مع دول الميركسور';
  @override String get agreementMercosurDoc => 'شهادة منشأ الميركسور الأصلية المستوفاة لنموذج التصديق وقواعد المنشأ';
  @override String agreementMercosurExemption(dynamic rate) => 'إعفاء جمركي كامل لضريبة الوارد (0% بدلاً من $rate%) بموجب اتفاقية التجارة الحرة مع تجمع الميركسور.';
  @override String get agreementGafta => 'منطقة التجارة الحرة العربية الكبرى';
  @override String get agreementGaftaDoc => 'شهادة منشأ عربية موحدة معتمدة من الغرفة التجارية والجمارك';
  @override String agreementGaftaExemption(dynamic rate) => 'إعفاء جمركي كامل لضريبة الوارد (0% بدلاً من $rate%) بموجب اتفاقية تيسير وتنمية التبادل التجاري بين الدول العربية.';
  @override String get agreementTurkey => 'اتفاقية التجارة الحرة مع تركيا';
  @override String get agreementTurkeyDoc => 'شهادة حركة البضائع التركية الرسمية';
  @override String agreementTurkeyExemption(dynamic rate) => 'إعفاء جمركي كامل للمنتجات الصناعية (0% بدلاً من $rate%) بموجب اتفاقية التجارة الحرة بين مصر وتركيا.';
  @override String get agreementUk => 'اتفاقية المشاركة المصرية البريطانية';
  @override String get agreementUkDoc => 'إعلان منشأ المملكة المتحدة على الفاتورة أو شهادة الحركة';
  @override String agreementUkExemption(dynamic rate) => 'إعفاء جمركي كامل (0% بدلاً من $rate%) بموجب اتفاقية المشاركة المصرية البريطانية.';
  @override String get nafezaCalculationFlat => 'قطعي';
  @override String get nafezaCalculationReference => 'مرجعي';
  @override String get nafezaCalculationDerived => 'مشتق';
  @override String get nafezaCollectionPrefix => 'تحصيل';
  @override String get statusClearanceReady => 'جاهز للإفراج';
  @override String get statusBlocked => 'معطل / موانع إفراج';
  @override String get statusActionRequired => 'مطلوب إجراء';
  @override String get statusPendingReview => 'قيد المراجعة';
  @override String get statusApproved => 'معتمد ومستوفى';
  @override String get statusRejected => 'مرفوض';
  @override String get statusVerified => 'تم التحقق';
  @override String get statusReceived => 'مستلم';
  @override String get freightAutoFetchedToast => 'تم استدعاء النولون تلقائياً من سيناريوهات الشحن';
  @override String get noPoItemsForHsSync => 'لم يتم العثور على بنود أوامر شراء مرتبطة بهذا الملف لاحتساب شروطها';
  @override String hsRequirementsSyncedToast(dynamic count, dynamic addedCount) => 'تمت مزامنة اشتراطات $count بند جمركي — تم إضافة $addedCount مستند لقائمة فحص الشحنة بنجاح';
  @override String get acidReqChecklistDoc => 'قيد رقم التسجيل المسبق للشحنة الكاملة (نافذة)';
  @override String get cooReqChecklistDoc => 'شهادة المنشأ الموثقة للشحنة الكاملة';
  @override String get goeicReqChecklistDoc => 'عرض وفحص هيئة الرقابة على الصادرات والواردات للشحنة الكاملة';
  @override String authorityApprovalChecklistDoc(dynamic authority) => 'موافقة $authority الفنية المسبقة';
  @override String brokerQuoteExtractedToast(dynamic broker) => 'تم استخلاص وتطبيق بنود مقايسة التخليص بنجاح ($broker)';
  @override String activeEditModeBannerTitle(dynamic code) => 'وضع التعديل النشط: أنت الآن تقوم بتعديل دراسة الاستشارة الجمركية رقم ($code)';
  @override String get activeEditModeBannerSub => 'قم بتعديل بيانات الفحص والمستندات والرسوم ثم اضغط حفظ التعديلات لتحديث الدراسة نفسها، أو حفظ كنسخة جديدة لإنشاء دراسة منفصلة.';
  @override String get saveAsNewCopy => 'حفظ كنسخة جديدة';
  @override String get modifiedCopySuffix => 'نسخة معدلة';
  @override String get convertedToNewStudyToast => 'تم تحويل الجلسة إلى دراسة جديدة منفصلة، اضغط حفظ دراسة الاستشارة الجمركية للحفظ';
  @override String get defaultTaxReviewSessionTitle => 'مراجعة واحتساب الضرائب والرسوم الجمركية للشحنة';
  @override String get defaultCustomsConsultationTitle => 'دراسة المراجعة الجمركية الأولية لخط إنتاج ومعدات الشحنة';
  @override String get selectImportFileFirstToast => 'يرجى اختيار ملف الشحنة الاستيرادية أولاً لاستدعاء الفاتورة النهائية.';
  @override String get defaultCustomsBrokerName => 'مكتب تخليص';
  @override String get defaultImportItemDescription => 'صنف مستورد';
  @override String get customPriceListNoRegisteredTitle => 'قائمة أسعار مخصصة (لم يتم العثور على قائمة معتمدة مسجلة)';
  @override String get customsStudyValidationAlertsTitle => 'تنبيهات واستيفاء بيانات الدراسة';
  @override String get completeRequiredDataErrorMsg => 'يرجى استكمال البيانات الإلزامية التالية لتتمكن من حفظ الدراسة بنجاح.';
  @override String get consultationTitleFieldValidation => 'عنوان وموضوع الاستشارة الجمركية';
  @override String get consultationTitleFieldIssue => 'حقل إلزامي لا يمكن تركه فارغاً.';
  @override String get consultationTitleFieldRec => 'يرجى كتابة عنوان واضح وموجز لموضوع دراسة الفحص والاستشارة الجمركية.';
  @override String get customsBrokerFieldValidation => 'المستخلص الجمركي المعني';
  @override String get customsBrokerFieldIssue => 'لم يتم تحديد المستخلص الجمركي المسؤول عن دراسة الملف.';
  @override String get customsBrokerFieldRec => 'يرجى اختيار المستخلص الجمركي من القائمة المنسدلة.';
  @override String get checklistFieldValidation => 'قائمة الفحص والمستندات الجمركية';
  @override String get checklistFieldIssue => 'قائمة فحص المستندات والاشتراطات فارغة تماماً.';
  @override String get checklistFieldRec => 'يرجى إضافة مستند أو اشتراط واحد على الأقل في قائمة الفحص.';
  @override String get reviewCustomsStudyDiffTitle => 'مراجعة وتأكيد تعديلات الدراسة الجمركية';
  @override String get diffSectionGeneralData => 'البيانات العامة للدراسة';
  @override String get diffSectionCustomsBroker => 'المستخلص الجمركي';
  @override String get diffSectionFinancialEstimates => 'التقديرات المالية';
  @override String get diffSectionOperationalLink => 'الربط التشغيلي';
  @override String get diffSectionChecklist => 'قائمة فحص المستندات';
  @override String get diffFieldEstimatedDuties => 'الرسوم الجمركية والضرائب التقديرية';
  @override String get diffFieldLinkedImportFile => 'ملف الشحنة المرتبط';
  @override String get diffFieldTotalChecklistDocs => 'إجمالي عدد المستندات والاشتراطات';
  @override String get customsStudySavedSuccess => 'تم حفظ مراجعة الضرائب والرسوم الجمركية بنجاح!';
  @override String get customsStudyUpdatedSuccess => 'تم تحديث مراجعة الضرائب الجمركية بنجاح!';
  @override String get unableToSaveCustomsStudy => 'تعذر حفظ مراجعة الضرائب الجمركية';

  // ── Screen 57: Original Documents Collection & Courier ──────────────────
  @override String get originalDocsAndCargoXScaffoldTitle => 'تحصيل المستندات وكارجو إكس — المرحلة 4';
  @override String get originalDocsCollectionTabTitle => 'تحصيل أصول المستندات وتتبع الكورير';
  @override String get cargoxBlockchainTabTitle => 'منظومة كارجو إكس والمانيفست الرقمي';
  @override String get refreshDataTooltip => 'تحديث البيانات';
  @override String get originalDocsHubTitle => 'تحصيل أصول المستندات وتتبع طرود الكورير';
  @override String get originalDocsHubSubtitle => 'استدعاء تلقائي للمستندات المطلوبة من الأرشيف المركزي للشحنة، تتبع طرود البريد السريع المتعددة، وتدقيق استلام الأصول الورقية.';
  @override String savedSessionBadge(dynamic code) => 'جلسة محفوظة: $code';
  @override String get selectImportFileLabel => 'اختيار ملف الشحنة';
  @override String errorFetchingImportFiles(dynamic err) => 'خطأ في جلب ملفات الاستيراد: $err';
  @override String errorFetchingArchiveData(dynamic err) => 'خطأ في استدعاء بيانات الأرشيف: $err';
  @override String get statTotalRequiredDocs => 'إجمالي المستندات المطلوبة';
  @override String get statReceivedOriginals => 'تم استلام الأصل الورقي';
  @override String get statVerifiedDocs => 'تم الفحص والتدقيق';
  @override String get statPendingDocs => 'قيد الانتظار';
  @override String get statReadinessRate => 'نسبة الاكتمال والجاهزية';
  @override String get courierDispatchPackagesHeader => 'طرود وبوالص الشحن السريع للكورير:';
  @override String get addCourierAwbBtn => 'إضافة بوليصة كورير';
  @override String get noCouriersRegisteredMsg => 'لم يتم تسجيل بوالص كورير بعد. اضغط زر إضافة بوليصة لإدراج شحنة بريد سريع.';
  @override String get courierTrackingNoField => 'رقم بوليصة الكورير (رقم التتبع)';
  @override String get courierCompanyField => 'شركة الكورير';
  @override String get dispatchDateField => 'تاريخ الإرسال (السنة-الشهر-اليوم)';
  @override String get isReceivedCheckbox => 'تم الاستلام';
  @override String get receivedByNameField => 'اسم المستلم';
  @override String get deleteCourierTooltip => 'حذف طرد الكورير';
  @override String get physicalDocsVerificationMatrixHeader => 'مصفوفة استلام وتدقيق أصول المستندات الورقية:';
  @override String get addCustomDocBtn => 'إضافة مستند إضافي';
  @override String get defaultNewCustomDocName => 'مستند إضافي جديد';
  @override String get selectCourierPlaceholder => 'اختر الكورير';
  @override String get colCourierNo => 'رقم الكورير';
  @override String get colDocCategory => 'تصنيف الوثيقة';
  @override String get colDocName => 'اسم المستند';
  @override String get colRequirement => 'الإلزامية';
  @override String get colResponsibleParty => 'الجهة المسؤولة';
  @override String get colPhysicalReceived => 'تم الاستلام الورقي';
  @override String get colReceivedDate => 'تاريخ الاستلام';
  @override String get colVerified => 'تم الفحص والتدقيق';
  @override String get colAuditor => 'القائم بالتدقيق';
  @override String get colDocStatus => 'الحالة';
  @override String get colRemarks => 'ملاحظات';
  @override String get colAction => 'إجراء';
  @override String get hintAuditor => 'المدقق';
  @override String get hintRemarks => 'ملاحظات...';
  @override String get reqBadgeYes => 'إلزامي';
  @override String get reqBadgeConditional => 'مشروط';
  @override String get reqBadgeNo => 'اختياري';
  @override String get statusBadgeVerified => 'تم التحقق';
  @override String get statusBadgeReceived => 'مستلم';
  @override String get statusBadgeInTransit => 'في الطريق';
  @override String get statusBadgeDiscrepant => 'غير مطابق / به ملاحظات';
  @override String get statusBadgePending => 'قيد الانتظار';
  @override String get saveDraftSessionBtn => 'حفظ مؤقت';
  @override String get completeCollectionBtn => 'اعتماد واكتمال التحصيل';
  @override String get unverifiedMandatoryDocsWarning => 'توجد مستندات إلزامية لم يتم تدقيقها بعد. يرجى ذكر مبرر الاعتماد قبل التأكيد النهائي.';
  @override String sessionSavedSuccess(dynamic code) => 'تم حفظ وتحديث جلسة تحصيل أصول المستندات بنجاح [$code]';
  @override String sessionSaveError(dynamic err) => 'خطأ في حفظ الجلسة: $err';
  @override String excelExportSuccess(dynamic bytes) => 'تم توليد وتصدير ملف الإكسيل بنجاح ($bytes بايت)';
  @override String excelExportError(dynamic err) => 'خطأ في تصدير ملف الإكسيل: $err';
  @override String get collectionRegistryHeader => 'سجل جلسات تحصيل أصول المستندات:';
  @override String get searchRegistryHint => 'بحث برقم الكود أو الشحنة...';
  @override String get filterStatusAll => 'جميع الحالات';
  @override String get filterStatusDraft => 'مسودة';
  @override String get filterStatusPartiallyReceived => 'مستلم جزئياً';
  @override String get filterStatusFullyReceived => 'مستلم بالكامل';
  @override String get filterStatusFullyVerified => 'معتمد ومدقق بالكامل';
  @override String get noRegisteredSessionsFound => 'لا توجد جلسات تحصيل مسجلة بعد.';
  @override String errorFetchingRegistry(dynamic err) => 'خطأ في جلب السجل: $err';
  @override String get colSessionCode => 'كود الجلسة';
  @override String get colImportFile => 'ملف الشحنة';
  @override String get colAcidNumber => 'رقم القيد المسبق';
  @override String get colSupplierName => 'المورد الأجنبي';
  @override String get colTotalDocs => 'إجمالي المستندات';
  @override String get colReceivedDocs => 'تم الاستلام';
  @override String get colVerifiedDocs => 'تم التدقيق';
  @override String get colCompletionPercentage => 'نسبة الإنجاز';
  @override String get colUpdatedAt => 'تاريخ التحديث';
  @override String get docCatCommercial => 'تجاري';
  @override String get docCatCertificate => 'شهادات';
  @override String get docCatShipping => 'شحن';
  @override String get docCatEgyptImport => 'استيراد مصر';
  @override String get docCatBanking => 'بنكي';
  @override String get docCatRegulatory => 'رقابي';
  @override String get docCatOther => 'أخرى';
  @override String get courierCompanyHandDelivery => 'تسليم باليد';
  @override String get courierCompanyOther => 'أخرى';
  @override String get partySupplier => 'المورد الأجنبي';
  @override String get partyFreightForwarder => 'وكيل الشحن';
  @override String get partyCustomsBroker => 'المخلص الجمركي';
  @override String get partyBank => 'البنك';
  @override String get partyImporter => 'الشركة المستوردة';
  @override String get partyCarrier => 'الخط الملاحي';
  @override String get sessionNotesLabel => 'ملاحظات عامة على جلسة التحصيل';
  @override String get overrideReasonLabel => 'مبرر اعتماد التحصيل في حالة وجود مستندات غير مكتملة';

  // ── Screen 59: Production Sync Screen & Hub ───────────────────────────────
  @override String get prodSyncScreenTitle => 'مركز مزامنة وتحديث الإنتاج';
  @override String get prodSyncScreenSubtitle => 'أداة المزامنة الفورية لقواعد البيانات والتعديلات من داخل النظام مباشرة';
  @override String get prodSyncHubDialogTitle => 'مركز حماية ومزامنة الإنتاج';
  @override String get prodSyncHubDialogSubtitle => 'ترقية هيكل البيانات وإدارة النسخ الاحتياطية والاستعادة دون المساس ببيانات التشغيل';
  @override String get prodSyncTabCompareTables => 'مقارنة ومزامنة الجداول';
  @override String get prodSyncTabSchemaUpgrade => 'ترقية هيكل البيانات';
  @override String get prodSyncTabSafetyBackups => 'سجل النسخ الاحتياطية والاستعادة';
  @override String get prodSyncDevDbTitle => 'قاعدة بيانات التطوير';
  @override String get prodSyncDevDbSubtitle => 'الملف النشط في بيئة العمل الحالية';
  @override String get prodSyncDevDbUpgradeSub => 'مصدر الميزات الجديدة والترقيات';
  @override String get prodSyncProdDbTitle => 'قاعدة بيانات الإنتاج';
  @override String get prodSyncProdDbSubtitle => 'الملف المدمج في حزمة البرنامج المستقلة';
  @override String get prodSyncProdDbUpgradeSub => 'الهدف التشغيلي — بياناتها محمية بالكامل';
  @override String prodSyncDbSize(dynamic size) => 'الحجم: $size';
  @override String prodSyncDbTablesCount(dynamic count) => 'الجداول: $count';
  @override String prodSyncDbRecordsCount(dynamic count) => 'السجلات: $count';
  @override String prodSyncFullySynchronizedTitle(dynamic matched) => 'قواعد البيانات متطابقة تماماً بنسبة مئة بالمئة ($matched جدول متطابق)';
  @override String get prodSyncFullySynchronizedSub => 'الإنتاج يعمل بأحدث نسخة متوافقة بالكامل مع بيئة التطوير.';
  @override String prodSyncDifferencesDetectedTitle(dynamic differing) => 'تم رصد اختلافات في البيانات ($differing جدول به تعديلات غير مدمجة)';
  @override String get prodSyncDifferencesDetectedSub => 'يمكنك بضغطة زر واحدة مزامنة وتحديث قاعدة بيانات الإنتاج فوراً دون الحاجة لإعادة التثبيت.';
  @override String prodSyncUpgradeReadyTitle(dynamic count) => 'توجد ميزات جديدة جاهزة للترقية ($count جدول)';
  @override String get prodSyncUpgradeReadySub => 'اضغط "ترقية الإنتاج" لإضافة الميزات الجديدة فقط — بياناتك التشغيلية محمية تماماً.';
  @override String get prodSyncSafetyGuaranteeTitle => 'ضمان الحماية الكاملة لبيانات التشغيل';
  @override String get prodSyncSafetyGuaranteeBody => 'الترقية تضيف فقط الجداول والأعمدة الجديدة • لا تحذف أي سجل • لا تعدل بيانات الموردين أو الشركات أو أوامر الشراء أو ملفات الشحن • نسخة احتياطية تلقائية قبل البدء';
  @override String get prodSyncSyncNowBtn => 'مزامنة وتحديث الإنتاج الآن';
  @override String get prodSyncUpgradeBtn => 'ترقية الإنتاج';
  @override String get prodSyncPullFromProdBtn => 'سحب من الإنتاج';
  @override String get prodSyncCreateSnapshotBtn => 'أخذ نسخة احتياطية فورية';
  @override String get prodSyncCreateDevSnapshotBtn => 'نسخة احتياطية الآن (بيئة التطوير)';
  @override String prodSyncTablesMatchHeader(dynamic filtered, dynamic total) => 'فحص وتطابق جداول النظام ($filtered / $total جدول)';
  @override String prodSyncTablesUpgradeHeader(dynamic filtered, dynamic total) => 'تفاصيل الجداول ($filtered / $total) — الجداول ذات الفروق ستتلقى الأعمدة الجديدة فقط';
  @override String get prodSyncSearchTablesHint => 'بحث في الجداول...';
  @override String prodSyncDevRecordsCount(dynamic count) => 'التطوير: $count سجل';
  @override String prodSyncProdRecordsCount(dynamic count) => 'الإنتاج: $count سجل';
  @override String get prodSyncTableStatusUpdated => 'محدث';
  @override String get prodSyncBackupsSectionHeader => 'النسخ الاحتياطية المؤرشفة لقاعدة البيانات';
  @override String get prodSyncBackupsSectionSub => 'يتم حفظ نسخة احتياطية مشفرة في مجلد النسخ الاحتياطية قبل كل عملية مزامنة لضمان أمان البيانات بالكامل';
  @override String get prodSyncBackupsDialogSub => 'يمكنك استعادة أي نسخة — يتم حفظ نسخة أمان من الوضع الحالي قبل الاستعادة';
  @override String get prodSyncNoBackupsFound => 'لا توجد نسخ احتياطية محفوظة بعد';
  @override String get prodSyncNoBackupsDialogSub => 'يتم أخذ نسخة احتياطية تلقائياً قبل كل ترقية وعند إغلاق النظام';
  @override String get prodSyncRestoreToProdBtn => 'استعادة إلى الإنتاج';
  @override String get prodSyncRestoreToDevBtn => 'استعادة إلى التطوير';
  @override String prodSyncBackupCreatedAt(dynamic date) => 'تاريخ الإنشاء: $date';
  @override String prodSyncBackupSize(dynamic size) => 'الحجم: $size';
  @override String prodSyncBackupTag(dynamic tag) => 'النوع: $tag';
  @override String get prodSyncConfirmUpgradeTitle => 'تأكيد ترقية الإنتاج';
  @override String get prodSyncConfirmUpgradeWhatHappens => 'ما سيحدث:\n• نسخة احتياطية أمان تلقائية قبل البدء\n• إضافة الجداول الجديدة (إن وجدت)\n• إضافة الأعمدة الجديدة لكل جدول موجود\n• دمج بيانات المرجعية الجديدة';
  @override String get prodSyncConfirmUpgradeWhatWontHappen => 'ما لن يحدث أبداً:\n• لن يُمسّ أي مورد أو شركة أو أمر شراء أو ملف شحن\n• لن يُحذف أي سجل موجود في الإنتاج\n• لن يُعدَّل أي بيان تشغيلي مُدخل يدوياً';
  @override String get prodSyncConfirmUpgradeSubmitBtn => 'تأكيد الترقية';
  @override String get prodSyncConfirmRestoreTitle => 'تأكيد الاستعادة';
  @override String prodSyncConfirmRestoreMsg(dynamic target) => 'سيتم استعادة النسخة التالية إلى قاعدة بيانات $target:';
  @override String get prodSyncConfirmRestoreWarning => 'سيتم حفظ نسخة أمان من الوضع الحالي قبل الاستعادة، ثم استبدال قاعدة البيانات بالنسخة المختارة.';
  @override String get prodSyncConfirmRestoreSubmitBtn => 'تأكيد الاستعادة';
  @override String get prodSyncTargetProdLabel => 'الإنتاج';
  @override String get prodSyncTargetDevLabel => 'التطوير';
  @override String prodSyncBackupCreatedSuccess(dynamic filename) => 'تم إنشاء النسخة الاحتياطية: $filename';
  @override String prodSyncSyncError(dynamic err) => 'فشلت المزامنة: $err';
  @override String prodSyncPullError(dynamic err) => 'فشل السحب: $err';
  @override String prodSyncRestoreError(dynamic err) => 'فشلت الاستعادة: $err';
  @override String get prodSyncComparingDatabasesProgress => 'جاري فحص ومقارنة قواعد البيانات...';
  @override String prodSyncErrorFetchingComparison(dynamic err) => 'تعذر جلب بيانات المقارنة: $err';

  // ── Screen 63: Goods In Transit (GIT) Ledger ─────────────────────────────
  @override String get gitLedgerTabTitle => 'رصيد البضاعة بالطريق وتتبع الشحنات';
  @override String get gitLedgerScaffoldTitle => 'رصيد ومطابقة البضاعة في الطريق';
  @override String gitErrorFetchingData(dynamic err) => 'خطأ في جلب بيانات البضاعة بالطريق: $err';
  @override String get gitInfoBannerTitle => 'تقرير رصيد البضاعة في الطريق تفصيلي لكل أمر شراء';
  @override String get gitInfoBannerSubtitle => 'هذا التقرير يمثل رصيد البضائع المشحونة طبقاً للفواتير وقوائم التعبئة المعتمدة، ويتم تحديثه وخصم الكميات تلقائياً فور تأكيد الاستلام النهائي بالمخزن.';
  @override String get gitExportExcelBtn => 'تصدير إكسيل';
  @override String get gitExportSuccessMsg => 'تم تصدير تقرير البضاعة في الطريق بنجاح';
  @override String get gitKpiInTransitShipments => 'الشحنات في الطريق';
  @override String gitKpiShipmentsValue(dynamic count) => '$count شحنة';
  @override String get gitKpiPurchaseOrders => 'أوامر الشراء';
  @override String gitKpiPurchaseOrdersValue(dynamic count) => '$count أمر شراء';
  @override String get gitKpiInvoicedQuantity => 'إجمالي العدد بالفاتورة';
  @override String gitKpiQuantityValue(dynamic qty) => '$qty قطعة';
  @override String get gitKpiPackagesCount => 'إجمالي الكراتين والطرود';
  @override String gitKpiPackagesValue(dynamic count) => '$count طرد';
  @override String get gitKpiActiveContainers => 'عدد الحاويات النشطة';
  @override String gitKpiContainersValue(dynamic count) => '$count حاوية';
  @override String get gitSearchHint => 'بحث برقم الشحنة، أمر الشراء، كود أو اسم الصنف...';
  @override String get gitFilterAll => 'جميع البضائع';
  @override String get gitFilterInTransitOnly => 'البضاعة في الطريق فقط (الرصيد الفعلي)';
  @override String get gitFilterDeliveredOnly => 'الشحنات المستلمة بالمخزن فقط';
  @override String get gitRefreshTooltip => 'تحديث الرصيد';
  @override String get gitTableSectionHeader => 'جدول رصيد البضاعة في الطريق تفصيلي لكل أمر شراء';
  @override String get gitNoDataFound => 'لا توجد بضائع في الطريق مطابقة لمعايير البحث حالياً.';
  @override String get gitColFileCode => 'رقم ملف الشحنة';
  @override String get gitColPoNumber => 'رقم أمر الشراء';
  @override String get gitColItemCode => 'كود الصنف';
  @override String get gitColItemName => 'اسم وبيان الصنف';
  @override String get gitColInvoicedQty => 'العدد بالفاتورة';
  @override String get gitColPackagesCount => 'عدد الكراتين والطرود';
  @override String get gitColContainers => 'عدد الحاويات ونوعها';
  @override String get gitColCertifiedDate => 'تاريخ الاعتماد';
  @override String get gitColLedgerStatus => 'حالة الرصيد';
  @override String get gitStatusDeliveredToWarehouse => 'تم الاستلام بالمخزن';
  @override String get gitStatusInTransit => 'في الطريق';

  // ── Screen 64: Warehouse Received Shipments Detailed Report ───────────────
  @override String get whReportTabTitle => 'تقرير الشحنات المستلمة بالمخزن تفصيلي';
  @override String get whReportScaffoldTitle => 'تقرير الشحنات المستلمة بالمخزن ومطابقة الفروق';
  @override String whReportErrorFetchingData(dynamic err) => 'خطأ في جلب تقرير الشحنات المستلمة: $err';
  @override String get whReportInfoBannerTitle => 'تقرير الشحنات المستلمة بالمخازن ومطابقة الفروق';
  @override String get whReportInfoBannerSubtitle => 'حصر شامل لكل الشحنات التي تم تأكيد استلامها بالمخازن مفصلة بأوامر الشراء ومطابقة الكميات المقر عنها بالفاتورة مع المستلم الفعلي والفاقد والتالف والعينات المسحوبة.';
  @override String get whReportExportExcelBtn => 'تصدير إكسيل';
  @override String get whReportExportSuccessMsg => 'تم تصدير تقرير الشحنات المستلمة بنجاح';
  @override String get whReportKpiInvoicedQty => 'إجمالي العدد بالفاتورة';
  @override String get whReportKpiReceivedQty => 'المستلم الفعلي بالمخزن';
  @override String get whReportKpiDamagedQty => 'إجمالي التالف';
  @override String get whReportKpiShortageQty => 'إجمالي العجز';
  @override String get whReportKpiSamplesQty => 'العينات المسحوبة';
  @override String get whReportKpiVarianceQty => 'صافي الفروق';
  @override String whReportUnitsValue(dynamic count) => '$count وحدة';
  @override String get whReportSearchHint => 'بحث برقم الشحنة، أمر الشراء، كود أو اسم الصنف...';
  @override String get whReportTableSectionHeader => 'جدول الشحنات المستلمة تفصيلي لكل أمر شراء';
  @override String get whReportNoDataFound => 'لا توجد شحنات مستلمة مطابقة لمعايير البحث حالياً.';
  @override String get whReportColImportFile => 'ملف الشحنة';
  @override String get whReportColPoNumber => 'أمر الشراء';
  @override String get whReportColContainerAndTruck => 'الحاويات والسيارة';
  @override String get whReportColItemAndDescription => 'الصنف وبيانه';
  @override String get whReportColInvoicedQty => 'العدد بالفاتورة';
  @override String get whReportColShortageQty => 'الفاقد والعجز';
  @override String get whReportColDamagedQty => 'التالف';
  @override String get whReportColSamplesQty => 'عينات مسحوبة';
  @override String get whReportColReceivedQty => 'المستلم بالمخزن';
  @override String get whReportColVarianceQty => 'الفارق';
  @override String get whReportColReceiptStatus => 'حالة الاستلام';
  @override String get whReportStatusApprovedAndReceived => 'معتمد ومستلم';

  // ── Screen 8: Financial Approvals & Budgets ─────────────────────────────
  @override String get financialApprovalsTitle => 'الموافقات المالية وإدارة الميزانية';
  @override String get paymentRequestsTab => 'طلبات السداد المالي للمورد';
  @override String get importBudgetApprovalTab => 'اعتماد الميزانية الاستيرادية';
  @override String get savedBudgetsRegistryTab => 'سجل الميزانيات المعتمدة';
  @override String get paymentRequestsRegistryTab => 'سجل طلبات السداد والتحويلات';
  @override String get swiftReconciliationTab => 'استخراج ومطابقة السويفت (MT103)';
  @override String get createPaymentRequestTitle => 'إصدار طلب سداد وتحويل مالي للمورد';
  @override String get editPaymentRequestTitle => 'تعديل بيانات طلب السداد الحالي';
  @override String get activeEditModeBanner => 'وضع التعديل النشط';
  @override String get cancelEdit => 'إلغاء التعديل';
  @override String get paymentTitleLabel => 'عنوان طلب السداد';
  @override String get paymentTypeLabel => 'طريقة / نوع السداد';
  @override String get requestedAmountLabel => 'المبلغ المطلوب بالعملة';
  @override String get beneficiarySupplierLabel => 'المورد المستفيد';
  @override String get selectSupplierFromMasterData => 'اختر المورد من البيانات المرجعية';
  @override String get beneficiaryBankDetails => 'بيانات التحويل البنكي للمورد المستفيد';
  @override String get bankNameLabel => 'اسم بنك المورد';
  @override String get swiftCodeLabel => 'كود السويفت';
  @override String get ibanAccountLabel => 'رقم الحساب / الآيبان';
  @override String get requestDateLabel => 'تاريخ تقديم الطلب';
  @override String get dueDateLabel => 'تاريخ الاستحقاق المطلوب';
  @override String get paymentNotesLabel => 'ملاحظات طلب السداد';
  @override String get issuePaymentRequestButton => 'إصدار طلب السداد للإدارة المالية';
  @override String get savePaymentChangesButton => 'حفظ تعديلات طلب السداد';
  @override String get importBudgetSetupTitle => 'اعتماد ميزانية ملف الاستيراد الشاملة';
  @override String get budgetTitleLabel => 'عنوان الميزانية الاستيرادية';
  @override String get estimatedInvoiceValue => 'قيمة الفاتورة المبدئية';
  @override String get estimatedFreightCost => 'تكلفة النولون المقدرة';
  @override String get customsAndVatEstimate => 'الضرائب والجمارك والـ VAT';
  @override String get clearanceAndTransportEstimate => 'أتعاب التخليص والنقل';
  @override String get budgetApprovalNotes => 'ملاحظات وتوجيهات اعتماد الميزانية';
  @override String get approveAndCertifyBudget => 'التصديق واعتماد الميزانية';
  @override String get saveBudgetChanges => 'حفظ تعديلات الميزانية';
  @override String get totalBudgetEgp => 'إجمالي الميزانية الاستيرادية الكلية المعتمدة';
  @override String get consolidatedBudgetSummary => 'تقرير توزيع بنود الميزانية حسب العملات';
  @override String get totalBudgetsMetric => 'إجمالي الميزانيات';
  @override String get approvedBudgetsMetric => 'ميزانيات معتمدة';
  @override String get pendingBudgetsMetric => 'قيد المراجعة / مسودة';
  @override String get totalValueEgpMetric => 'إجمالي القيمة التقديرية';
  @override String get searchBudgetsHint => 'البحث بكود الميزانية أو العنوان أو كود الشحنة...';
  @override String get searchPaymentsHint => 'البحث بكود الطلب أو اسم المورد أو رقم الملف أو العنوان...';
  @override String get paymentRequestsLogTitle => 'سجل العمليات والتحويلات المالية للموردين';
  @override String get noMatchingPayments => 'لا توجد طلبات سداد مالي مطابقة لخيارات البحث والتصفية.';
  @override String get noMatchingBudgets => 'لا توجد اعتمادات ميزانية مطابقة لمعايير البحث.';
  @override String get swiftExtractorTitle => 'استخراج ومطابقة إشعار التحويل البنكي (SWIFT MT103)';
  @override String get swiftUploadDocument => 'رفع مستند السويفت';
  @override String get swiftPasteText => 'لصق نص رسالة السويفت';
  @override String get swiftMatchedSuccess => 'تمت المطابقة مع طلب السداد بنجاح';
  @override String get swiftExecuteReconciliation => 'تنفيذ المطابقة والاعتماد المالي';
  @override String get paymentCodeCol => 'كود الطلب';
  @override String get bankSwiftCol => 'البنك / السويفت';
  @override String get equivalentEgpCol => 'المعادل (EGP)';
  @override String get requestDueDateCol => 'تاريخ الطلب / الاستحقاق';
  @override String get draftStatus => 'مسودة';
  @override String get paidStatus => 'تم التحويل';
  @override String get reconciledStatus => 'مطابق بالسويفت';
  @override String get importFile => 'ملف الشحنة';
  @override String get notLinked => 'غير مرتبط';
  @override String get currencyCol => 'العملة';
  @override String get exchangeRateCol => 'سعر الصرف';
  @override String get poNumberCol => 'رقم أمر الشراء';
  @override String get projectNameCol => 'اسم المشروع';
  @override String get invoiceAmount => 'قيمة الفاتورة';
  @override String get reset => 'تفريغ';
  @override String get budgetApprovalTab => 'اعتماد ميزانية الشحنة';
  @override String get savedBudgetsTab => 'سجل الميزانيات المحفوظة';
  @override String get paymentRequestsLogTab => 'سجل التحويلات وسداد الموردين';
  @override String get paymentRequestHeader => 'إصدار طلب سداد مالي لمورد / جهة خارجية';
  @override String get paymentRequestSub => 'إنشاء طلب تحويل مالي مستندي وتوجيهه للإدارة المالية';

  // ── Screen 11: Nafeza ACID Operations ───────────────────────────────────
  @override String get nafezaAcidTitle => 'منظومة نافذة والتسجيل المسبق للشحنات';
  @override String get acidRequestTab => 'طلب إصدار الرقم المبدئي';
  @override String get smartMtsParserTab => 'الإدخال الذكي من نافذة';
  @override String get discrepancyMatrixTab => 'المقارنة والتحقق الجمركي';
  @override String get acidRegistryTab => 'سجل إصدارات ACID';
  @override String get expiryTrackerTab => 'متتبع الصلاحية والإفراج';
  @override String get acidInfoBanner => 'تسجيل وطلب استخراج رقم القيد الجمركي المبدئي (ACID) وفق متطلبات مصلحة الجمارك المصرية ومنظومة نافذة (MTS). اختر ملف الشحنة لتحميل بيانات المستورد والمورد الأجنبي تلقائياً.';
  @override String get selectImportFileAcidLabel => 'اختر ملف الشحنة لطلب ACID';
  @override String get searchFileOrSupplierHint => 'ابحث برقم الملف أو اسم المورد أو الشركة...';
  @override String get importerAndExporterSection => '1. بيانات المستورد والمصدر الأجنبي';
  @override String get importerSectionTitle => 'الشركة المستوردة';
  @override String get importerTaxIdLabel => 'الرقم الضريبي للمستورد';
  @override String get importerAddressLabel => 'عنوان المستورد المسجل بنافذة';
  @override String get foreignExporterSectionTitle => 'المصدر الأجنبي';
  @override String get foreignExporterIdLabel => 'رقم السجل / المعرف الضريبي بالخارج';
  @override String get regTypeLabel => 'نوع التسجيل';
  @override String get countryOfOriginExportLabel => 'دولة المنشأ / التصدير';
  @override String get cargoxPlatformIdLabel => 'معرف منصة كارجو إكس (CargoX)';
  @override String get proformaPortsBrokerSection => '2. بيانات الفاتورة المبدئية والموانئ والمخلص';
  @override String get proformaInvoiceNoLabel => 'رقم الفاتورة المبدئية';
  @override String get proformaInvoiceDateLabel => 'تاريخ الفاتورة';
  @override String get invoiceTypeLabel => 'نوع الفاتورة المقدمة';
  @override String get customsBrokerResponsibleLabel => 'المخلص الجمركي المسؤول';
  @override String get brokerPhoneLabel => 'هاتف المخلص للتواصل';
  @override String get acidRequestDateLabel => 'تاريخ تقديم الطلب بنافذة';
  @override String get saveAcidRequestButton => 'حفظ بيانات الطلب وإرسالها للمطابقة';
  @override String get updateAcidRequestButton => 'تعديل وحفظ طلب ACID';
  @override String get goToSmartParserButton => 'الانتقال للإدخال الذكي من نافذة';
  @override String get brokerDispatchMessageTitle => 'رسالة طلب إصدار ACID الجاهزة للإرسال للمخلص الجمركي';
  @override String get brokerDispatchMessageSub => 'تم تجميع وتوليد الرسالة تلقائياً بكافة البيانات المستدعاة من الشحنة لتسهيل إرسالها للمخلص عبر الواتساب أو الإيميل بنقرة واحدة.';
  @override String get copyArabicWhatsApp => 'نسخ عربي (WhatsApp)';
  @override String get copyEnglishRequest => 'نسخ بالإنجليزية (English)';
  @override String get emailTemplateButton => 'قالب الإيميل';
  @override String get smartParserInfoBanner => 'المحلل الذكي لنصوص نافذة (MTS Smart Parser): الصق النص الخام المستلم من إشعار نافذة أو البريد الإلكتروني. سيقوم النظام باستخراج رقم ACID، تاريخ الصلاحية، بيانات المصدر والمستورد تلقائياً وبدقة 100%.';
  @override String get linkImportFileResult => 'ربط بنتيجة ملف شحنة';
  @override String get pasteRawMtsTextTitle => 'الصق نص إشعار نافذة الخام هنا';
  @override String get loadSampleMtsTextButton => 'تحميل نص إشعار نافذة نموذجي';
  @override String get pasteFromClipboardButton => 'لصق من الحافظة';
  @override String get runSmartParserButton => 'تشغيل المحلل الذكي واستخراج البيانات';
  @override String get clearTextButton => 'مسح النص';
  @override String get parsedMtsSuccessTitle => 'البيانات المستخرجة بنجاح من نص نافذة';
  @override String get parsedMtsNoAcidTitle => 'نتائج الاستخراج (لم يتم العثور على رقم ACID في النص)';
  @override String get goToVerificationButton => 'الانتقال للمطابقة والتحقق';
  @override String get saveAndCertifyAcidButton => 'حفظ واعتماد بيانات ACID بالشحنة';
  @override String get saveTempDraftButton => 'حفظ مؤقت (مسودة)';
  @override String get editExtractedDataButton => 'تعديل البيانات المستخرجة';
  @override String get codeSupplierButton => 'تكويد / تحديث المورد';
  @override String get acidNumberCol => 'رقم ACID';
  @override String get issueDateCol => 'تاريخ الإصدار';
  @override String get expiryDateCol => 'تاريخ الصلاحية';
  @override String get foreignExporterCol => 'المصدر الأجنبي';
  @override String get importerCompanyCol => 'الشركة المستوردة';
  @override String get actionCol => 'الإجراءات';
  @override String get daysRemainingCol => 'الأيام المتبقية';
  @override String get validityStatusCol => 'حالة الصلاحية';
  @override String get runDiscrepancyMatrixButton => 'تشغيل مصفوفة المطابقة الفورية';
  @override String get perfectMatchTitle => 'المطابقة الجمركية كاملة بنسبة 100%';
  @override String get discrepancyFoundTitle => 'يوجد عدم تطابق في بعض الحقول الجمركية الأساسية!';
  @override String get customsFieldCol => 'الحقل الجمركي';
  @override String get requestedValueCol => 'البيان المطلوب (النظام)';
  @override String get generatedValueCol => 'البيان الصادر (نافذة)';
  @override String get matchingStatusCol => 'حالة المطابقة';
  @override String get discrepancyOverrideJustificationLabel => 'ملاحظات وتبرير اعتماد الفروق';
  @override String get verifyAndCertifyAcidButton => 'اعتماد وتثبيت رقم ACID بملف الشحنة';
  @override String get searchAcidRegistryHint => 'بحث في سجل أرقام ACID برقم القيد، المورد، رقم الملف...';
  @override String get newAcidRequestButton => 'طلب ACID جديد';
  @override String get totalAcidsCard => 'إجمالي أرقام ACID';
  @override String get validAcidsCard => 'ساري (> 14 يوم)';
  @override String get expiringSoonAcidsCard => 'أوشك على الانتهاء (≤ 14 يوم)';
  @override String get expiredAcidsCard => 'منتهي الصلاحية';
  @override String get searchExpiryTrackerHint => 'بحث في متتبع الصلاحيات والإفراج الجمركي...';
  @override String get validStatusBadge => 'ساري وصالح';
  @override String get expiringSoonStatusBadge => 'أوشك على الانتهاء';
  @override String get expiredStatusBadge => 'منتهي الصلاحية';
  @override String get matchedStatus => 'مطابق';
  @override String get discrepancyStatus => 'فروق';
  @override String get issuedAndValidStatus => 'صادر وساري';
  @override String get tempDraftStatus => 'مسودة مؤقتة';
  @override String get underReviewStatus => 'قيد المراجعة';

  // ── Screen 16: Bank Form 4 ──────────────────────────────────────────────
  @override String get bankForm4Title => 'المستندات والتوثيق البنكي ونموذج 4';
  @override String get form4RequestTab => 'طلب وتوثيق نموذج 4';
  @override String get bankForm4RegistryTab => 'سجل النماذج البنكية';
  @override String bankForm4EditingBanner(String code) => 'أنت الآن في وضع تعديل النموذج البنكي المرجعي: $code';
  @override String get cancelEditNewForm4 => 'إلغاء التعديل والعودة لطلب جديد';
  @override String get selectImportFileForm4Label => 'اختر ملف الشحنة المرتبط بإصدار نموذج 4';
  @override String get bankApplicationDetailsSection => 'تفاصيل طلب التوثيق والتحويل البنكي';
  @override String get issuingBankLabel => 'البنك المصدر / المعتمد';
  @override String get selectBankHint => 'اختر البنك...';
  @override String get bankAmountLabel => 'المبلغ المطلوب توثيقه';
  @override String get transferCurrencyLabel => 'عملة التحويل';
  @override String get selectCurrencyHint => 'اختر العملة...';
  @override String get bankRequestDateLabel => 'تاريخ تقديم الطلب للبنك';
  @override String get bankNotesLabel => 'ملاحظات وتوجيهات خاصة لفرع البنك';
  @override String get form4ChecklistSectionTitle => 'قائمة المستندات المرفقة بملف نموذج 4 للبنك';
  @override String get form4ItemProformaInvoice => 'الفاتورة المبدئية المعتمدة (PI)';
  @override String get form4ItemPackingList => 'قائمة التعبئة والتغليف (P/L)';
  @override String get form4ItemCertificateOfOrigin => 'شهادة المنشأ الموثقة (COO)';
  @override String get form4ItemBillOfLading => 'بوليصة الشحن (B/L Draft)';
  @override String get form4ItemAcidNotice => 'إشعار تسجيل نافذة (ACID Notice)';
  @override String get form4ItemMarineInsurance => 'وثيقة التأمين البحري (Insurance)';
  @override String get form4ItemBankApplication => 'طلب تحويل البنك موقع ومختوم';
  @override String get form4ItemAdminFeeReceipt => 'إيصال سداد المصاريف الإدارية';
  @override String get saveForm4Button => 'حفظ وتسجيل طلب نموذج 4';
  @override String get updateForm4Button => 'تحديث نموذج 4';
  @override String get goToBankRegistryButton => 'الانتقال لسجل النماذج البنكية';
  @override String get searchBankRegistryHint => 'بحث في سجل النماذج البنكية بالرمز، البنك، رقم الملف...';
  @override String get newForm4RequestButton => 'طلب نموذج 4 جديد';
  @override String get documentCodeCol => 'كود المستند';
  @override String get certifiedBankCol => 'البنك المعتمد';
  @override String get amountAndCurrencyCol => 'المبلغ والعملة';
  @override String get requestDateCol => 'تاريخ التقديم';
  @override String get endorsementStatusCol => 'حالة التوثيق';
  @override String get endorsedStatusBadge => 'معتمد وموثق';
  @override String get bankProcessingStatusBadge => 'قيد المعالجة البنكية';
  @override String get form4SavedSuccess => 'تم حفظ نموذج 4 البنكي بنجاح';
  @override String get form4SaveError => 'خطأ في حفظ نموذج 4';

  // ── Screen 18: Draft B/L Review ──────────────────────────────────────────
  @override String get draftBlStage0ReviewSheet => '1. ورقة المراجعة والتدقيق';
  @override String get draftBlStage1RevisionReport => '2. تقرير التعديلات وخطاب الخط الملاحي';
  @override String get draftBlStage2VersionBranching => '3. إدارة النسخ والإصدارات';
  @override String get draftBlStage3DualApproval => '4. الاعتماد الثنائي';
  @override String get draftBlStage4FinalRegistry => '5. السجل النهائي المعتمد';
  @override String get draftBlReviewSheetTitle => 'ورقة مراجعة واعتماد مسودة بوليصة الشحن';
  @override String get draftBlReviewSheetSub => 'يقوم النظام تلقائياً باستدعاء كافة البيانات المرجعية للشحنة من الحجز الملاحي وبيان العبوة المعتمد، ومقارنتها مباشرة بمسودة الخط الملاحي.';
  @override String draftBlMismatchesFound(int count) => 'يوجد $count اختلافات غير مطابقة';
  @override String get draftBlPerfectMatchReady => 'مطابقة تامة 100% جاهزة للاعتماد';
  @override String get draftBlSelectImportFileLabel => 'ملف الشحنة الاستيرادي *';
  @override String get draftBlRefreshAndCompare => 'تحديث ومقارنة البيانات';
  @override String get draftBlSmartExtractorTitle => '📥 استخراج ذكي من ملفات ومسودات البوليصة';
  @override String get draftBlSmartExtractorSub => 'ارفع ملف المسودة مباشرة من الخط الملاحي أو الصق نص المسودة للاستخراج والمطابقة الآلية الفورية';
  @override String get draftBlUploadAndExtractButton => '📁 رفع واستخراج ملف المسودة (PDF / Word / Excel)';
  @override String get draftBlExtractingFileProgress => 'جاري قراءة واستخراج بيانات الملف...';
  @override String draftBlFileExtractedSuccess(String filename, String sizeKb) => 'تم استخراج: $filename ($sizeKb KB)';
  @override String get draftBlReuploadTooltip => 'إعادة رفع ملف آخر';
  @override String get draftBlExtractedBlNumberLabel => 'رقم البوليصة المستخرج:';
  @override String get draftBlCopyBlNumberTooltip => 'نسخ رقم البوليصة';
  @override String draftBlCopiedBlNumberSnackbar(String blNumber) => '✔ تم نسخ رقم البوليصة ($blNumber) إلى الحافظة';
  @override String get draftBlEditBlNumberTitle => 'تعديل رقم بوليصة الشحن';
  @override String get draftBlSafetyAlertTitle => '⚠️ تنبيه أمان رقابي: المستند المستخرج يحتوي على حقول حرجة غير مكتملة أو تحتاج تأكيد يدوي';
  @override String get draftBlSafetyAlertSub => 'يرجى مراجعة وتأكيد الحقول الحرجة بالجدول أدناه لتفادي المقارنة أو الاعتماد بناءً على بيانات غير مكتملة.';
  @override String get draftBlSmartExtractionComplete => '✅ تم الاستخراج الذكي الشامل واكتمال كافة الحقول الحرجة بنسبة 100%.';
  @override String get draftBlPasteRawTextTitle => 'أو الصق نص المسودة يدوياً:';
  @override String get draftBlPasteRawTextHint => 'الصق هنا النص المنسوخ من مسودة البوليصة أو الإيميل...';
  @override String get draftBlExtractFromTextButton => '⚡ استخراج ومطابقة ذكية من النص';
  @override String get draftBlReferenceVisualSheetTitle => '1. ملخص الشحنة المرجعي كشكل بوليصة شحن';
  @override String get draftBlReferenceVisualSheetSub => 'البيانات المرجعية المسجلة داخل النظام من ماستر داتا المورد والمستورد وبيان العبوة والحجز الملاحي ومعايير نافذة (ACID)';
  @override String get draftBlExtractedVisualSheetTitle => '5. شكل بوليصة مسودة الخط الملاحي المستخرجة';
  @override String get draftBlExtractedVisualSheetSub => 'مطابقة حية وتأكيد لصحة بيانات بوليصة الشحن مع متطلبات نافذة (ACID)';
  @override String get draftBlSwitchToGridView => 'التبديل إلى عرض البطاقات التفصيلية';
  @override String get draftBlSwitchToVisualBl => 'عرض كشكل بوليصة رسمية';
  @override String get draftBlAutoSummaryTitle => '1. ملخص الشحنة المرجعي التلقائي';
  @override String get draftBlAutoSummarySub => 'البيانات المرجعية المسجلة داخل النظام من ماستر داتا المورد والمستورد والحجز الملاحي وبيان العبوة المعتمد.';
  @override String get draftBlSummaryShipper => 'المصدر / الشاحن';
  @override String get draftBlSummaryConsignee => 'المستورد';
  @override String get draftBlSummaryNotifyParty => 'جهة الإخطار';
  @override String get draftBlSummaryVesselVoyage => 'الباخرة والرحلة';
  @override String get draftBlSummaryPorts => 'الموانئ';
  @override String get draftBlSummaryFreightTerms => 'شروط النولون';
  @override String get draftBlSummaryBookingNo => 'رقم الحجز';
  @override String get draftBlSummaryAcidNo => 'رقم القيد الجمركي (ACID)';
  @override String get draftBlSummaryImporterTaxId => 'البطاقة الضريبية للمستورد';
  @override String get draftBlSummaryShipperReg => 'رقم تسجيل المصدر';
  @override String get draftBlSummaryContainers => 'الحاويات والرصاص';
  @override String get draftBlSummaryGrossWeight => 'الوزن القائم';
  @override String get draftBlSummaryNetWeight => 'الوزن الصافي';
  @override String get draftBlSummaryCbm => 'الحجم الإجمالي';
  @override String get draftBlSummaryPackages => 'عدد ونوع الطرود';
  @override String get draftBlChecklistSectionTitle => '2. قائمة التدقيق والمطابقة الشاملة';
  @override String get draftBlChecklistSectionSub => 'جدول المطابقة المباشر لكل حقل بين بيانات النظام وقيم المسودة مع تحديد الحالة وتحديد الإجراء والجهة المسؤولة.';
  @override String get draftBlSaveSessionButton => 'حفظ جلسة المراجعة';
  @override String get draftBlRevisionReportCarrierButton => 'تقرير التعديلات للخط الملاحي ➔';
  @override String get draftBlSelectFileToStartChecklist => 'يرجى اختيار ملف الشحنة لبدء المطابقة الآلية';
  @override String get draftBlChecklistColField => 'الحقل';
  @override String get draftBlChecklistColSystemValue => 'البيانات بالنظام';
  @override String get draftBlChecklistColDraftValue => 'قيمة المسودة';
  @override String get draftBlChecklistColStatus => 'الحالة';
  @override String get draftBlChecklistColRequiredAction => 'الإجراء والتصحيح المطلوب';
  @override String get draftBlChecklistColResponsibleParty => 'الجهة المسؤولة';
  @override String get draftBlChecklistColReasonNotes => 'السبب والملاحظات';
  @override String get draftBlStatusCorrect => 'مطابق';
  @override String get draftBlStatusIncorrect => 'غير مطابق';
  @override String get draftBlStatusNA => 'غير مطلوب';
  @override String get draftBlPartyShippingLine => 'الخط الملاحي';
  @override String get draftBlPartySupplier => 'المورد الأجنبي';
  @override String get draftBlPartyImporter => 'المستورد';
  @override String get draftBlPartyCustomsBroker => 'المخلص الجمركي';
  @override String get draftBlCopySystemValueTooltip => 'نسخ قيمة النظام للمسودة وتأكيد المطابقة';
  @override String get draftBlEnterDraftValueHint => 'أدخل قيمة المسودة...';
  @override String get draftBlMatchedHint => 'مطابق';
  @override String get draftBlEnterCorrectionHint => 'اكتب التصحيح المطلوب...';
  @override String get draftBlEnterReasonHint => 'السبب / الملاحظات...';
  @override String get draftBlSelectFileToViewRevision => '⚠️ يرجى اختيار وتحديد ملف الشحنة أولاً لعرض تقرير التعديلات وخطاب الخط الملاحي';
  @override String get draftBlBackToSelectFile => 'العودة لاختيار الملف';
  @override String get draftBlRevisionReportTitle => 'تقرير التعديلات المطلوبة';
  @override String get draftBlRevisionReportSub => 'يضم هذا التقرير فقط البنود غير المطابقة المطلوب تعديلها من الخط الملاحي أو المورد.';
  @override String get draftBlProceedToVersionHistory => 'المتابعة لسجل النسخ (المرحلة 3)';
  @override String get draftBlNoAmendmentsNeeded => 'رائع! لا توجد أي تعديلات مطلوبة. كافة بنود المسودة مطابقة تماماً للمنظومة.';
  @override String get draftBlRevisionColItem => 'البند';
  @override String get draftBlRevisionColRequiredAction => 'الإجراء والتصحيح المطلوب';
  @override String get draftBlRevisionColResponsible => 'الجهة المسؤولة';
  @override String get draftBlRevisionColReason => 'السبب';
  @override String get draftBlCarrierRequestLetterTitle => 'خطاب طلب التعديل الرسمي للخط الملاحي';
  @override String get draftBlCopyLetterButton => 'نسخ الخطاب';
  @override String get draftBlLetterCopiedSnackbar => '✔ تم نسخ خطاب التعديل إلى الحافظة بنجاح';
  @override String get draftBlSelectFileToViewVersions => '⚠️ يرجى اختيار وتحديد ملف الشحنة أولاً لعرض إدارة النسخ والتعديلات';
  @override String get draftBlVersionBranchingTitle => 'إدارة النسخ والإصدارات';
  @override String get draftBlVersionBranchingSub => 'عند استلام مسودة معدلة جديدة (v2, v3)، يقوم النظام بقفل البنود المطابقة سابقاً، وإعادة فتح البنود ذات الملاحظات فقط للتأكد من تعديلها.';
  @override String get draftBlProceedToDualApproval => 'المتابعة للاعتماد الثنائي (المرحلة 4)';
  @override String draftBlActiveVersionBanner(String version, String stage, int lockedCount) => 'النسخة الحالية النشطة: $version ($stage) | البنود المقفلة: $lockedCount';
  @override String get draftBlSelectFileToCompleteApproval => '⚠️ يرجى اختيار وتحديد ملف الشحنة أولاً لإتمام الاعتماد الثنائي للبوليصة';
  @override String get draftBlApprovalBlockedTitle => '🚨 حظر الاعتماد التام: توجد اختلافات حرجة تمنع اعتماد البوليصة';
  @override String get draftBlImporterApprovalTitle => '1. اعتماد مسؤول الاستيراد';
  @override String get draftBlImporterApproverNameLabel => 'اسم مسؤول الاستيراد / المعتمِد *';
  @override String get draftBlImporterNotesLabel => 'ملاحظات وتوجيهات الاستيراد';
  @override String get draftBlApproveAndAcceptButton => 'اعتماد وموافقة';
  @override String get draftBlRejectDraftButton => 'رفض المسودة';
  @override String get draftBlBrokerApprovalTitle => '2. اعتماد المخلص الجمركي';
  @override String get draftBlBrokerApproverNameLabel => 'اسم المخلص الجمركي المعتمد *';
  @override String get draftBlBrokerNotesLabel => 'ملاحظات التخليص ومطابقة نافذة';
  @override String get draftBlBrokerApproveButton => 'اعتماد جمركي وموافقة';
  @override String get draftBlFinalRegistryTitle => 'سجل مسودات البوليصة المعتمدة نهائياً';
  @override String get draftBlFinalRegistrySub => 'النسخ المعتمدة هنا أصبحت غير قابلة للتعديل وتعتبر الوثيقة الحاكمة لإصدار البوليصة الأصلية والإفراج الجمركي.';
  @override String get draftBlRefreshRegistry => 'تحديث السجل';
  @override String get draftBlSearchRegistryHint => 'ابحث برقم البوليصة، رقم الجلسة، الخط الملاحي، أو المرحلة...';
  @override String get draftBlNoRegistriesFound => 'لا توجد نتائج مطابقة لبحثك';
  @override String get draftBlNoRegistriesYet => 'لا توجد جلسات مراجعة مسجلة حتى الآن';
  @override String get draftBlTryDifferentSearch => 'جرّب البحث برقم بوليصة آخر';
  @override String get draftBlExtractNewDraftHint => 'قم باستخراج واعتماد مسودة بوليصة جديدة من التاب الأول';
  @override String get draftBlRegistryColSessionId => 'رقم الجلسة';
  @override String get draftBlRegistryColBlNumber => 'رقم البوليصة';
  @override String get draftBlRegistryColShippingLine => 'الخط الملاحي';
  @override String get draftBlRegistryColVesselVoyage => 'السفينة / الرحلة';
  @override String get draftBlRegistryColStage => 'المرحلة';
  @override String get draftBlRegistryColImporterApproval => 'اعتماد المستورد';
  @override String get draftBlRegistryColBrokerApproval => 'اعتماد المخلص';
  @override String get draftBlRegistryColStatus => 'الحالة';
  @override String get draftBlRegistryColActions => 'الإجراءات';
  @override String get draftBlViewBlTooltip => 'معاينة البوليصة';
  @override String get draftBlPrintBlTooltip => 'طباعة البوليصة';
  @override String get draftBlDownloadPdfTooltip => 'تنزيل PDF';
  @override String get draftBlPrintButton => 'طباعة البوليصة';
  @override String get draftBlDownloadPdfButton => 'تنزيل PDF';
  @override String get draftBlDownloadExcelButton => 'تنزيل Excel';
  @override String get draftBlSessionSavedSuccess => '✔ تم حفظ جلسة مراجعة درافت البوليصة بنجاح';
  @override String get draftBlSessionSaveError => 'خطأ أثناء حفظ الجلسة';

  // ── Screen 19: Draft COO / EUR.1 Review ──────────────────────────────────
  @override String get cooStage1Requirements => '1. متطلبات شهادة المنشأ / EUR.1';
  @override String get cooStage2DraftInput => '2. إدخال واستخراج الدرافت';
  @override String get cooStage3DiscrepancyMatrix => '3. مصفوفة المقارنة والفروق';
  @override String get cooStage4Registry => '4. سجل مراجعات المنشأ';
  @override String get cooDecisionEngineTitle => 'محرك اتخاذ القرار الجمركي لشهادات المنشأ';
  @override String get cooDecisionEngineSub => 'توجيه ذكي لنوع الشهادة تلقائياً بناءً على بلد المنشأ المذكور في الفواتير والاتفاقيات الدولية';
  @override String get cooRecheckAgreementButton => 'إعادة فحص الاتفاقية';
  @override String cooInvoiceOriginBadge(String origin) => '🌍 بلد المنشأ بالفاتورة: $origin';
  @override String get cooManualChoiceRequiredBadge => '⚠️ مطلوب اختيار يدوي (اتفاقيات متعددة)';
  @override String cooApprovedCertBadge(String cert) => '✔ الشهادة المعتمدة: $cert';
  @override String cooExistingReviewBanner(String code, String status) => 'ℹ️ توجد دراسة مسجلة مسبقاً لهذا الملف [كود الجلسة: $code - الحالة: $status]. سيتم تحديث وتعديل نفس الدراسة المعتمدة لضمان عدم تكرار السجلات.';
  @override String get cooReviewRegistryButton => 'سجل المراجعات';
  @override String get cooGenerateDraftHeader => 'توليد واستدعاء مسودة شهادة المنشأ الرسمية';
  @override String get cooSelectImportFileLabel => 'اختر ملف الشحنة *';
  @override String get cooSearchFileHint => 'ابحث برقم الملف...';
  @override String get cooCertTypeLabel => 'نوع شهادة المنشأ *';
  @override String get cooSelectCertTypeHint => 'اختر نوع الشهادة...';
  @override String get cooCertTypeEur1 => 'EUR.1 (الاتفاقية المصرية الأوروبية - قواعد معدلة)';
  @override String get cooCertTypeChina => 'شهادة منشأ الصين (CCPIT / China-Egypt)';
  @override String get cooCertTypeStandard => 'شهادة منشأ عادية (Standard COO)';
  @override String get cooCertTypeFormA => 'Form A / نظام الأفضليات المعمم (GSP)';
  @override String get cooCertTypeAgadir => 'شهادة اتفاقية أغادير';
  @override String get cooCertTypeGafta => 'شهادة منطقة التجارة الحرة العربية الكبرى (GAFTA)';
  @override String get cooOpenVisualPreviewButton => '⚡ فتح المعاينة المصورة والتصدير';
  @override String get cooNextDraftInputButton => 'التالي: إدخال الدرافت';
  @override String get cooOfficialDraftPreviewTitle => 'معاينة المسودة الرسمية لشهادة المنشأ';
  @override String get cooAutoFillFieldsButton => 'اعتماد وتعبئة الحقول تلقائياً';
  @override String get cooDraftFilledSuccess => '✔ تم ملء بيانات المسودة الرسمية بنجاح';
  @override String cooGenerateDraftError(String e) => 'خطأ أثناء توليد المسودة: $e';
  @override String get cooDraftInputTitle => 'إدخال واستخراج بيانات درافت شهادة المنشأ';
  @override String get cooRunComparisonButton => 'تشغيل المقارنة';
  @override String get cooLinkedImportFileLabel => 'اختر ملف الشحنة المربوط *';
  @override String get cooSelectFileWarning => '⚠️ يرجى اختيار وتحديد ملف الشحنة أولاً حتى يتم استخراج البيانات ومقارنتها بسجلات النظام.';
  @override String get cooDraftCertNumberLabel => 'رقم درافت الشهادة *';
  @override String get cooOriginCountryLabel => 'بلد المنشأ *';
  @override String get cooDestinationCountryLabel => 'بلد المقصد *';
  @override String get cooExporterNameLabel => 'اسم المصدر / الشاحن *';
  @override String get cooExporterRegIdLabel => 'كود المصدر الأجنبي / السجل الضريبي';
  @override String get cooImporterNameLabel => 'اسم المستورد / المرسل إليه *';
  @override String get cooInvoiceNumberLabel => 'رقم الفاتورة المذكورة *';
  @override String get cooSmartUploadButtonLabel => 'رفع واستخراج شهادة المنشأ الذكي (PDF / Word / Excel)';
  @override String get cooRawTextSectionTitle => 'النص الخام لدرافت شهادة المنشأ (OCR):';
  @override String get cooSmartExtractFromTextButton => '⚡ استخراج وتعبئة ذكية من النص';
  @override String get cooRawTextHint => 'الصق النص الكامل للشهادة هنا (مثل نصوص CCPIT أو EUR.1)...';
  @override String get cooPasteTextOrUploadWarning => 'يرجى لصق نص الشهادة أو رفع الملف أولاً';
  @override String get cooAiExtractSuccess => '✔ تم استخراج ومطابقة بيانات الشهادة بالذكاء الاصطناعي بنجاح';
  @override String cooExtractError(String e) => 'خطأ أثناء الاستخراج: $e';
  @override String get cooSelectFileFirstForComparison => 'يرجى اختيار ملف الشحنة أولاً';
  @override String cooComparisonError(String e) => 'خطأ أثناء المقارنة: $e';
  @override String get cooSelectFileToViewMatrix => '⚠️ يجب اختيار ملف الشحنة أولاً لعرض مصفوفة المقارنة';
  @override String get cooBackToSelectFile => 'العودة لاختيار الملف';
  @override String get cooRunComparisonPreviousStep => 'يرجى تشغيل المقارنة في الخطوة السابقة لاستعراض مصفوفة الفروق';
  @override String get cooBackToRunComparison => 'العودة لتشغيل المقارنة';
  @override String get cooCriticalMismatchAlert => '🚨 توجد اختلافات حرجة في بيانات شهادة المنشأ';
  @override String get cooMinorDiscrepancyAlert => '⚠️ توجد فروق طفيفة في الشهادة';
  @override String get cooPerfectMatchSuccess => '✔ شهادة المنشأ مطابقة 100%';
  @override String get cooExportPdfButton => 'تصدير PDF';
  @override String get cooExportExcelButton => 'تصدير Excel';
  @override String get cooSaveToRegistryButton => 'حفظ بالسجل';
  @override String get cooExportingPdfReportSnackbar => 'جارٍ تصدير تقرير مطابقة شهادة المنشأ...';
  @override String get cooExcelCopiedSnackbar => '📊 تم نسخ وتصدير بيانات المطابقة إلى Excel بنجاح';
  @override String get cooMatrixColField => 'الحقل';
  @override String get cooMatrixColSystemValue => 'القيمة بالنظام';
  @override String get cooMatrixColDraftValue => 'القيمة بالدرافت';
  @override String get cooMatrixColStatus => 'حالة التطابق';
  @override String get cooMatrixColDetails => 'التفاصيل';
  @override String get cooOverrideReasonTitle => 'سبب ومبررات الموافقة على الاختلافات (إلزامي للاعتماد والحفظ):';
  @override String get cooOverrideReasonSub => 'عند وجود فروق أو اختلافات في شهادة المنشأ، يجب تسجيل سبب الموافقة والاعتماد (مثال: ملحق تفويضي من المصدر / الاسم التجاري موثق بالسجل)، أو الضغط على العودة للتعديل ومخاطبة المورد.';
  @override String get cooOverrideReasonLabel => 'سبب ومبرر الموافقة على الاختلافات *';
  @override String get cooOverrideReasonHint => 'اكتب مبررات قبول الاختلافات هنا قبل الحفظ...';
  @override String get cooSaveWithJustificationButton => '✔ اعتماد وحفظ مع ذكر سبب الموافقة';
  @override String get cooReturnToEditAndNotifySupplierButton => '↩ العودة لتعديل المسودة ومخاطبة المورد';
  @override String get cooMustProvideJustificationSnackbar => '⚠️ يجب كتابة سبب ومبرر الموافقة على الاختلافات قبل الاعتماد والحفظ، أو الضغط على [العودة للتعديل ومخاطبة المورد].';
  @override String get cooSessionSavedSuccess => '✔ تم حفظ جلسة مراجعة شهادة المنشأ بنجاح بالسجل';
  @override String cooSaveError(String e) => 'خطأ في الحفظ: $e';
  @override String get cooRegistryTitle => 'سجل مراجعات شهادات المنشأ واليورو 1';
  @override String get cooReviewNewDraftButton => 'مراجعة درافت جديد';
  @override String get cooNoReviewsYet => 'لا توجد مراجعات مسجلة';
  @override String get cooRegistryColCode => 'كود الجلسة';
  @override String get cooRegistryColType => 'النوع';
  @override String get cooRegistryColNumber => 'رقم الشهادة';
  @override String get cooRegistryColExporter => 'المصدر';
  @override String get cooRegistryColStatus => 'الحالة';
  @override String get cooRegistryColDate => 'تاريخ الإنشاء';
  @override String get cooRegistryColActions => 'الإجراءات';
  @override String get cooEditSessionTooltip => 'تعديل الجلسة';
  @override String get cooViewDetailsTooltip => 'معاينة التفاصيل';
  @override String get cooDownloadPdfTooltip => 'تنزيل PDF';
  @override String get cooDeleteSessionTooltip => 'حذف الجلسة';
  @override String cooLoadedSessionForEditSnackbar(String code) => 'تم تحميل بيانات الجلسة ($code) للتعديل';
  @override String cooDetailsDialogTitle(String code) => 'تفاصيل جلسة مراجعة شهادة المنشأ: $code';
  @override String get cooDetailsCertTypeAndNumber => 'نوع الشهادة ورقمها';
  @override String get cooDetailsExporterAndImporter => 'المصدر والمستورد';
  @override String get cooDetailsOriginAndDestination => 'بلد المنشأ والمقصد';
  @override String get cooDetailsOverrideReason => 'سبب ومبرر الموافقة على الاختلافات';
  @override String get cooDetailsMatrixTitle => 'مصفوفة الفروق والمطابقة:';
  @override String get cooDeleteDialogTitle => 'تأكيد حذف جلسة مراجعة المنشأ';
  @override String cooDeleteDialogContent(String code, String cert) => 'هل أنت متأكد من حذف جلسة المراجعة رقم ($code) لشهادة ($cert)؟';
  @override String get cooDeleteSuccessSnackbar => '✔ تم حذف جلسة المراجعة بنجاح';
  @override String cooDeleteErrorSnackbar(String e) => 'خطأ في الحذف: $e';
  @override String cooVisualPreviewTitle(String type) => 'معاينة مسودة شهادة المنشأ الرسمية: $type';
  @override String get cooVisualRefreshTooltip => 'تحديث حي للبيانات المستدعاة';
  @override String get cooVisualCopyButton => 'نسخ البيانات 📋';
  @override String get cooVisualCopiedSnackbar => '📋 تم نسخ بيانات شهادة المنشأ إلى الحافظة';
  @override String get cooVisualExcelButton => 'حفظ إكسل (Excel) 📊';
  @override String get cooVisualExcelReadySnackbar => '📊 تم توليد وتجهيز بيانات الإكسل لشهادة المنشأ بنجاح';
  @override String get cooVisualPrintPdfButton => 'حفظ وطباعة PDF 🖨️';

  // ── Screen 20: Customs Docs Approval (CustomsDocumentApprovalTab) ─────────
  @override String get customsApprovalSelectFileForMatrixWarning => '⚠️ برجاء اختيار ملف الشحنة أولاً لإجراء الفحص المتقاطع.';
  @override String customsApprovalMatrixCheckCompleted(String compliance) => '✅ تم الانتهاء من الفحص المتقاطع الآلي: $compliance';
  @override String customsApprovalMatrixCheckFailed(String error) => '❌ فشل إجراء الفحص: $error';
  @override String get customsApprovalSelectFileWarning => '⚠️ برجاء اختيار ملف الشحنة أولاً.';
  @override String get customsApprovalStandardListGeneratedSuccess => '✅ تم توليد قائمة مستندات الاعتماد القياسية بنجاح.';
  @override String customsApprovalGenerateFailed(String error) => '❌ خطأ أثناء التوليد: $error';
  @override String get customsApprovalSelectFileForTicketWarning => '⚠️ برجاء اختيار ملف الشحنة لربط التذكرة.';
  @override String get customsApprovalImportFileLabel => 'ملف الشحنة المستوردة';
  @override String get customsApprovalSearchFileHint => 'ابحث برقم الملف أو اسم الشركة...';
  @override String get customsApprovalRunAiMatrixButton => 'فحص متقاطع ذكي';
  @override String get customsApprovalAutoGenerateStandardListButton => 'توليد القائمة القياسية';
  @override String get customsApprovalRaiseTicketButton => 'تذكرة استدراك للمورد';
  @override String get customsApprovalFilterAll => 'الكل';
  @override String get customsApprovalFilterPending => 'قيد المراجعة';
  @override String get customsApprovalFilterApproved => 'معتمد';
  @override String get customsApprovalFilterRejected => 'مرفوض';
  @override String get customsApprovalFilterDiscrepancy => 'يوجد فروق';
  @override String get customsApprovalTabDualSignoff => 'مصفوفة الاعتماد الثنائي والفحص المتقاطع';
  @override String get customsApprovalTabCentralArchive => 'الأرشيف المركزي وملخص إخطارات التعديل';
  @override String customsApprovalMatrixComplianceResult(String compliance, int passed, int total) => 'نتيجة المطابقة المتقاطعة: $compliance ($passed/$total مطابق)';
  @override String customsApprovalMatrixRecommendations(String recs) => 'توصيات الجمارك: $recs';
  @override String customsApprovalMatrixOpenTicketsCount(int count) => 'تذاكر مفتوحة: $count';
  @override String get customsApprovalDualTierHeader => 'مصفوفة اعتماد المستندات الجمركية';
  @override String get customsApprovalNoDocuments => 'لا توجد مستندات مسجلة. اضغط "توليد القائمة القياسية" للبدء.';
  @override String customsApprovalError(String error) => 'خطأ: $error';
  @override String customsApprovalDocRef(String ref) => 'رقم: $ref';
  @override String customsApprovalCommercialReviewStatus(String status) => 'المراجعة التجارية: $status';
  @override String customsApprovalBrokerReviewStatus(String status) => 'اعتماد المخلص الجمركي: $status';
  @override String get customsApprovalTicketsHeader => 'سجل تذاكر الاستدراك والاستفسارات';
  @override String get customsApprovalNewTicketButton => 'تذكرة جديدة';
  @override String get customsApprovalNoTickets => 'لا توجد تذاكر استدراك مفتوحة. كافة المستندات متطابقة.';
  @override String customsApprovalTicketExpectedVsFound(String expected, String found) => 'المتوقع: $expected ➔ الوارد بالمسودة: $found';
  @override String get customsApprovalResolveTicketButton => 'تسجيل رد المورد / إغلاق التذكرة';
  @override String customsApprovalCommercialDialogTitle(String docType) => 'المراجعة التجارية: $docType';
  @override String get customsApprovalCommercialReviewerLabel => 'اسم المراجع التجاري *';
  @override String get customsApprovalRequiredField => 'الحقل إلزامي';
  @override String get customsApprovalCommercialDecisionLabel => 'قرار المراجعة *';
  @override String get customsApprovalSelectDecisionHint => 'اختر القرار...';
  @override String get customsApprovalDecisionCommercialApproved => 'معتمد تجارياً';
  @override String get customsApprovalDecisionCommercialUnderReview => 'قيد المراجعة';
  @override String get customsApprovalDecisionCommercialRejected => 'مرفوض لوجود أخطاء';
  @override String get customsApprovalCommercialNotesLabel => 'ملاحظات المراجعة التجارية';
  @override String get customsApprovalSaveApprovalButton => 'حفظ الاعتماد';
  @override String customsApprovalBrokerDialogTitle(String docType) => 'اعتماد المخلص الجمركي: $docType';
  @override String get customsApprovalBrokerOfficeLabel => 'مكتب / شركة التخليص الجمركي *';
  @override String get customsApprovalBrokerReviewerNameLabel => 'اسم المراجع القانوني / المخلص *';
  @override String get customsApprovalBrokerDecisionLabel => 'قرار المطابقة الجمركية *';
  @override String get customsApprovalDecisionBrokerApproved => 'معتمد للإفراج الجمركي';
  @override String get customsApprovalDecisionBrokerConditionallyApproved => 'معتمد بشرط';
  @override String get customsApprovalDecisionBrokerRejected => 'مرفوض جمركياً';
  @override String get customsApprovalBrokerNotesLabel => 'ملاحظات وتعهدات التخليص';
  @override String get customsApprovalBrokerSaveStampButton => 'اعتماد رسمي وختم';
  @override String get customsApprovalRaiseTicketDialogTitle => 'إصدار تذكرة استدراك وتعديل للمورد';
  @override String get customsApprovalIssueCategoryLabel => 'تصنيف الخطأ / التناقض *';
  @override String get customsApprovalSelectCategoryHint => 'اختر التصنيف...';
  @override String get customsApprovalCatHsMismatch => 'عدم تطابق بند التعريفة (HS Code)';
  @override String get customsApprovalCatWeightDiscrepancy => 'اختلاف في الأوزان';
  @override String get customsApprovalCatCbmDiscrepancy => 'اختلاف الحجم التكعيبي (CBM)';
  @override String get customsApprovalCatValueMismatch => 'اختلاف القيمة أو العملة';
  @override String get customsApprovalCatMissingAcid => 'غياب رقم الـ ACID';
  @override String get customsApprovalCatIncotermConflict => 'تعارض شرط الشحن (Incoterms)';
  @override String get customsApprovalCatOther => 'أخرى';
  @override String get customsApprovalSeverityLabel => 'درجة الخطورة *';
  @override String get customsApprovalSelectSeverityHint => 'اختر درجة الخطورة...';
  @override String get customsApprovalSevCritical => 'حرج (يمنع الشحن والإفراج)';
  @override String get customsApprovalSevMajor => 'رئيسي (يتطلب تعديل المسودة)';
  @override String get customsApprovalSevMinor => 'بسيط (للتنبيه)';
  @override String get customsApprovalIssueDescLabel => 'وصف الخطأ والتناقض بالتفصيل *';
  @override String get customsApprovalIssueDescMinLength => 'الوصف يجب أن يكون 5 أحرف على الأقل';
  @override String get customsApprovalExpectedValueLabel => 'القيمة الصحيحة المطلوبة';
  @override String get customsApprovalFoundValueLabel => 'القيمة الخاطئة بالمسودة';
  @override String get customsApprovalSupplierActionLabel => 'الإجراء المطلوب من المورد تنفيذه';
  @override String get customsApprovalCreateTicketSubmitButton => 'إصدار التذكرة';
  @override String customsApprovalResolveTicketDialogTitle(String ticketCode) => 'إغلاق تذكرة الاستدراك: $ticketCode';
  @override String get customsApprovalSupplierResponseLabel => 'رد وتعديل المورد *';
  @override String get customsApprovalResolverNameLabel => 'اسم المراجع القائم بالإغلاق *';
  @override String get customsApprovalFinalStatusLabel => 'الحالة النهائية *';
  @override String get customsApprovalSelectStatusHint => 'اختر الحالة...';
  @override String get customsApprovalStatusResolved => 'تم تصحيح المسودة';
  @override String get customsApprovalStatusWaived => 'تم التنازل مع تعهد';
  @override String get customsApprovalStatusClosed => 'مغلقة';
  @override String get customsApprovalConfirmResolveTicketButton => 'تأكيد الإغلاق';

  // ── Screen 21: PO & Packing Reconciliation ───────────────────────────────
  @override String get poRecSampleLoadedSuccess => 'تم تحميل النموذج التجريبي بنجاح';
  @override String poRecFileSelected(String name, String sizeKb) => 'تم اختيار الملف: $name ($sizeKb ك.ب)';
  @override String poRecFilePickFailed(String error) => 'فشل في اختيار الملف: $error';
  @override String poRecExtractedDigitalFileNotice(String filename) => '[تم تحميل ملف رقمي: $filename — سيتم استخراج ومعالجة بنوده آلياً عند الضغط على زر الاستخراج والمطابقة]';
  @override String get poRecInputValidationTitle => 'تنبيه: تحقق من مدخلات الاستخراج والمطابقة';
  @override String get poRecInputValidationDesc => 'تم رصد الملاحظات التالية في المدخلات التي تمنع إتمام الاستخراج والمطابقة بدقة:';
  @override String get poRecInputValidationRecHeader => 'إرشادات تصحيح المدخلات والحل المقترح:';
  @override String get poRecInputValidationGotIt => 'فهمت، سأقوم بالتصحيح';
  @override String get poRecIssueNoFileSelected => 'لم يتم اختيار الملف الاستيرادي المرجعي.';
  @override String get poRecRecSelectFileFromList => 'يرجى تحديد الملف الاستيرادي من القائمة المنسدلة في أعلى الشاشة.';
  @override String get poRecIssueEmptyInputs => 'لم يتم إدخال أو رفع أي مستند (الفاتورة التجارية أو قائمة التعبئة فارغتان تماماً).';
  @override String get poRecRecProvideInputs => 'قم برفع ملف PDF/Excel أو لصق النص التجاري أو الضغط على "تحميل نموذج تجريبي".';
  @override String get poRecServerSuccessNotice => 'تم الاستخراج الذكي والمطابقة بنجاح من السيرفر! راجع النتائج بالأسفل';
  @override String get poRecFallbackSuccessNotice => 'تم إجراء التحليل والمطابقة محلياً بنجاح عبر محرك الطوارئ المدمج';
  @override String get poRecApplyExtractedSuccess => 'تم تطبيق البيانات المستخرجة في جداول الفاتورة والباكينج ليست بنجاح!';
  @override String get poRecSaveSessionSelectFileWarning => 'يرجى اختيار ملف الشحنة أولاً لحفظ الجلسة';
  @override String get poRecExistingSessionWarningTitle => 'تنبيه: ملف الشحنة له جلسة سابقة';
  @override String poRecExistingSessionWarningContent(String sessionCode) => 'يوجد بالفعل جلسة مطابقة محفوظة لهذا الملف الاستيرادي (رمز الجلسة: $sessionCode).\n\nوفقاً لضوابط المنظومة، لا يُسمح بإنشاء أكثر من جلسة حفظ لنفس الملف الاستيرادي لمنع تكرار وتضارب البيانات.\n\nهل ترغب في تحديث الجلسة الحالية بالبيانات الجديدة؟';
  @override String get poRecUpdateExistingSessionButton => 'تحديث الجلسة الحالية';
  @override String poRecSaveSessionError(String error) => 'خطأ أثناء حفظ الجلسة: $error';
  @override String get poRecVarianceAlertTitle => 'تنبيه: وجود فروق في المطابقة';
  @override String get poRecVarianceAlertContent => 'تم رصد فروق بين أمر الشراء الأصلي والفاتورة والباكينج ليست النهائية:\n• سيتم اعتماد القيم والكميات النهائية كمرجع رسمي.\n• سيتم تحديث رصيد البضاعة في الطريق (GIT) بالكميات المعتمدة.\nهل ترغب في المتابعة وتأكيد الاعتماد؟';
  @override String get poRecCancelAndReview => 'إلغاء والمراجعة';
  @override String get poRecConfirmCertifyButton => 'تأكيد الاعتماد والمطابقة';
  @override String get poRecCertificationSuccess => 'تم اعتماد مطابقة المستندات وتحديث ملف الاستيراد وسجل الجلسات بنجاح!';
  @override String poRecCertificationError(String error) => 'خطأ أثناء اعتماد المطابقة: $error';
  @override String poRecSessionLoadedInEditor(String sessionCode) => 'تم تحميل جلسة المطابقة ($sessionCode) في شاشة التعديل والمطابقة!';

  @override String poRecEditSessionTitle(String code) => 'تعديل جلسة المطابقة: $code';
  @override String get poRecNewSessionTitle => 'مراجعة وتأكيد الفاتورة التجارية والباكينج ليست النهائية';
  @override String poRecOpenSessionBadge(String code) => 'جلسة مفتوحة: $code';
  @override String get poRecHeaderDescription => 'البيانات والكميات والأسعار والأوزان المعتمدة هنا هي المرجع الحاكم لدرافت البوليصة، والمخزون بالطريق، والإفراج الجمركي، واستلام المخزن.';
  @override String get poRecSearchFileHint => 'ابحث عن ملف الشحنة برقم الملف أو الكود...';
  @override String get poRecImportFileLabel => 'ملف الشحنة المرجعي *';
  @override String get poRecSelectFileRequired => 'يرجى اختيار ملف الشحنة';
  @override String get poRecFinalInvoiceNoLabel => 'رقم الفاتورة التجارية النهائية *';
  @override String get poRecFinalInvoiceNoHint => 'مثال: V1/2562';
  @override String get poRecFinalPackingListNoLabel => 'رقم قائمة التعبئة النهائية *';
  @override String get poRecFinalPackingListNoHint => 'مثال: M26 413 / PL-2562';
  @override String get poRecRequired => 'مطلوب';

  @override String get poRecKpiTotalInvoice => 'إجمالي الفاتورة النهائية';
  @override String get poRecKpiTotalPackages => 'إجمالي الطرود الفعلية';
  @override String get poRecKpiTotalGrossWeight => 'إجمالي الوزن القائم';
  @override String get poRecKpiTotalNetWeight => 'إجمالي الوزن الصافي';
  @override String get poRecKpiTotalCbm => 'إجمالي الحجم (CBM)';
  @override String get poRecPackagesUnit => 'طرد';
  @override String get poRecKgUnit => 'كجم';
  @override String get poRecCbmUnit => 'م³';

  @override String get poRecInvoiceSectionTitle => '1. مراجعة وتأكيد بنود وأسعار الفاتورة التجارية النهائية';
  @override String get poRecResetToOriginalValuesButton => 'إعادة تعيين للقيم الأصلية';
  @override String get poRecUpdateSessionButton => 'تحديث جلسة المطابقة';
  @override String get poRecSaveSessionButton => 'حفظ جلسة المطابقة';
  @override String get poRecCertifyFinalDataButton => 'اعتماد ومطابقة البيانات النهائية';
  @override String get poRecSelectFileToViewPoItems => 'يرجى اختيار ملف الشحنة لعرض بنود أمر الشراء للمطابقة';
  @override String get poRecColItemCode => 'كود الصنف';
  @override String get poRecColDescription => 'الوصف';
  @override String get poRecColPoQty => 'كمية PO';
  @override String get poRecColFinalQty => 'الكمية النهائية *';
  @override String get poRecColQtyVariance => 'فارق الكمية';
  @override String get poRecColPoUnitPrice => 'سعر وحدة PO';
  @override String get poRecColFinalUnitPrice => 'سعر الوحدة النهائي *';
  @override String get poRecColPriceVariance => 'فارق السعر';
  @override String get poRecColFinalTotal => 'الإجمالي النهائي';
  @override String get poRecColHsCode => 'بند التعريفة (HS)';

  @override String get poRecPackingSectionTitle => '2. مراجعة وتأكيد قائمة التعبئة والأوزان والطرود والأحجام';
  @override String get poRecSelectFileToViewPackingItems => 'يرجى اختيار ملف الشحنة لعرض بنود قائمة التعبئة';
  @override String get poRecColPackageType => 'نوع الطرد';
  @override String get poRecColFinalPackagesCount => 'عدد الطرود النهائية *';
  @override String get poRecColGrossWeight => 'الوزن القائم (كجم) *';
  @override String get poRecColNetWeight => 'الوزن الصافي (كجم) *';
  @override String get poRecColCbm => 'الحجم (م³) *';

  @override String get poRecExtractorTitle => 'أداة الرفع والاستخراج الذكي والمطابقة الثلاثية';
  @override String get poRecExtractorSubtitle => 'استخراج بنود الفاتورة النهائية وقائمة التعبئة ومطابقتها آلياً مع أمر الشراء بالسستم وكشف الفوارق';
  @override String get poRecLoadSampleDemoButton => 'تحميل نموذج تجريبي حقيقي (G.I. INDUSTRIAL)';
  @override String get poRecHideTool => 'إخفاء الأداة';
  @override String get poRecShowTool => 'عرض الأداة';
  @override String get poRecExtractorTabInvoice => '1. الفاتورة التجارية النهائية';
  @override String get poRecExtractorTabPacking => '2. قائمة التعبئة والأوزان';
  @override String get poRecChangeFile => 'تغيير الملف';
  @override String get poRecUploadFile => 'رفع ملف (PDF/Word/Excel)';
  @override String get poRecPasteInvoiceHint => 'ألصق نص الفاتورة التجارية هنا أو ارفع الملف الرقمي...';
  @override String get poRecPastePackingHint => 'ألصق نص قائمة التعبئة هنا أو ارفع الملف الرقمي...';
  @override String get poRecExtractingProgress => 'جاري الاستخراج والمطابقة الذكية...';
  @override String get poRecExecuteSmartExtractionButton => 'تنفيذ الاستخراج الذكي والمطابقة مع بيانات السستم';
  @override String get poRecStatusFullyMatchedTitle => 'مطابقة تامة بنسبة 100% — لا توجد أي فوارق أو تعارضات';
  @override String poRecStatusWarningsTitle(int count) => 'توجد فوارق أو تنبيهات غير حرجة ($count تنبيه) — يمكن المراجعة والاعتماد';
  @override String poRecStatusCriticalTitle(int count) => 'توجد فوارق حرجة ($count خطأ حرج) — يجب تدقيقها وتعديلها قبل الاعتماد!';
  @override String get poRecApplyExtractedToTablesButton => 'تطبيق البيانات المستخرجة في جداول المطابقة أدناه';
  @override String get poRecHeaderComplianceChecksTitle => 'فحص ومطابقة البيانات الحاكمة:';
  @override String get poRecColCheckItem => 'بند الفحص';
  @override String get poRecColSystemValue => 'القيمة بالسستم';
  @override String get poRecColExtractedValue => 'القيمة بالمستند المرفوع';
  @override String get poRecColMatchStatus => 'حالة المطابقة';
  @override String get poRecColDetails => 'التفاصيل';
  @override String get poRecMatchStatusMatched => 'مطابق';
  @override String get poRecMatchStatusWarning => 'تنبيه';
  @override String get poRecMatchStatusCritical => 'تعارض حرج';
  @override String get poRecExtractedDocMetadataTitle => 'البيانات المستخرجة من المستندات الرقمية:';
  @override String get poRecExtractedInvNo => 'رقم الفاتورة المستخرج';
  @override String get poRecExtractedInvAmount => 'إجمالي قيمة الفاتورة';
  @override String get poRecExtractedAcid => 'رقم ACID المستخرج';
  @override String get poRecExtractedPackagesWeight => 'إجمالي الطرود والوزن';

  @override String get poRecHistorySectionTitle => 'سجل جلسات المطابقة المحفوظة';
  @override String get poRecHistorySectionSubtitle => 'أرشيف جلسات مطابقة وتدقيق مستندات الشحن والفواتير وقوائم التعبئة';
  @override String poRecHistoryTotalSessionsBadge(int count) => '$count جلسة محفوظة';
  @override String get poRecHistoryKpiTotalSessions => 'إجمالي الجلسات المحفوظة';
  @override String get poRecHistoryKpiFullMatch => 'مطابقة بنسبة 100%';
  @override String get poRecHistoryKpiWithVariances => 'جلسات بها فوارق أو تنبيهات';
  @override String get poRecHistoryKpiTotalCertifiedValue => 'إجمالي القيمة المعتمدة';
  @override String get poRecHistoryNewSessionButton => 'جلسة مطابقة جديدة';
  @override String get poRecHistorySearchHint => 'بحث برمز الجلسة، رقم الملف، اسم الشركة، رقم الفاتورة، أو رقم ACID...';
  @override String poRecHistoryFilterAll(int count) => 'الكل ($count)';
  @override String get poRecHistoryFilterMatched => 'مطابق بالكامل';
  @override String get poRecHistoryFilterWarnings => 'فوارق مقبولة';
  @override String get poRecHistoryFilterCritical => 'فوارق حرجة';
  @override String get poRecHistoryRefreshTooltip => 'تحديث السجلات';
  @override String get poRecHistoryEmptyTitle => 'لا توجد جلسات مطابقة محفوظة حتى الآن.';
  @override String get poRecHistoryNoMatchFilter => 'لا توجد جلسات مطابقة مطابقة لمعايير البحث والفلترة.';
  @override String get poRecHistoryCreateFirstSessionButton => 'إنشاء أول جلسة مطابقة';
  @override String get poRecHistoryColIndex => '#';
  @override String get poRecHistoryColSessionCode => 'رمز الجلسة';
  @override String get poRecHistoryColImportFileImporter => 'ملف الشحنة / المستورد';
  @override String get poRecHistoryColInvoicePacking => 'الفاتورة والباكينج';
  @override String get poRecHistoryColTotalValue => 'إجمالي القيمة';
  @override String get poRecHistoryColPackagesWeight => 'الطرود والأوزان';
  @override String get poRecHistoryColCbm => 'الحجم (CBM)';
  @override String get poRecHistoryColStatus => 'حالة المطابقة';
  @override String get poRecHistoryColSavedDate => 'تاريخ الحفظ';
  @override String get poRecHistoryColActions => 'الإجراءات';
  @override String get poRecHistoryCopyCodeTooltip => 'نسخ رمز الجلسة';
  @override String get poRecHistoryCodeCopiedNotice => 'تم نسخ رمز الجلسة';
  @override String get poRecHistoryViewDetailsTooltip => 'عرض تفاصيل وتقرير الجلسة';
  @override String get poRecHistoryLoadIntoEditorTooltip => 'تحميل الجلسة في شاشة التعديل والمطابقة';
  @override String get poRecHistoryPrintTooltip => 'نسخ تقرير المطابقة للطباعة (Ctrl+P)';
  @override String get poRecHistoryDeleteTooltip => 'حذف الجلسة';
  @override String get poRecHistoryDeleteConfirmTitle => 'تأكيد حذف جلسة المطابقة';
  @override String poRecHistoryDeleteConfirmContent(String code, String file) => 'هل أنت متأكد من رغبتك في حذف جلسة المطابقة ($code) الخاصة بملف الشحنة ($file)؟';
  @override String get poRecHistoryDeletePermanent => 'حذف نهائياً';
  @override String poRecHistoryDeletedSuccess(String code) => 'تم حذف جلسة المطابقة ($code) بنجاح';
  @override String get poRecHistoryPrintCopiedSuccess => 'تم نسخ تقرير جلسة المطابقة للحافظة بنجاح! جاهز للطباعة والمشاركة';
  @override String poRecHistorySavedDialogTitle(String code) => 'تم حفظ جلسة المطابقة بنجاح ($code)';
  @override String get poRecHistorySavedUniqueNotice => 'تم تسجيل الجلسة كمرجع موثق وحصري لهذا الملف الاستيرادي لمنع أي تكرار.';
  @override String get poRecHistoryCopyReportButton => 'نسخ تقرير الجلسة للطباعة';
  @override String poRecHistoryDetailsModalTitle(String code) => 'تقرير جلسة المطابقة: $code';
  @override String get poRecHistoryDetailsCertifiedItemsTitle => 'بنود الفاتورة المعتمدة في الجلسة:';
  @override String get poRecHistoryLoadInEditorButton => 'تحميل في شاشة التعديل';
  @override String get poRecDiff => 'الفارق';
  @override String get poRecMissingInPacking => 'غير موجود بالباكينج';
  @override String get poRecMissingInInvoice => 'غير موجود بالفاتورة';
  @override String get poRecQtyDiff => 'فارق كمية';
  @override String get poRecOk => 'مطابق';
  @override String get poRecUnassignedHsCode => 'بدون بند جمركي';

  // ── Screen 23: Customs Declaration 46 ──────────────────────────────────────
  @override String get customsDeclStageTitle => 'الإقرار الجمركي المبدئي وشهادة 46 ك.م';
  @override String get customsDeclTabInitialForm => 'قيد الإقرار الجمركي المبدئي';
  @override String get customsDeclTabRegistry => 'سجل شهادات 46 ومتابعتها';
  @override String get customsDeclRefreshTooltip => 'تحديث البيانات';
  @override String get customsDeclInfoBanner => 'مسودة إقرار 46 ك.م الجاهزة للربط مع نافذة. يتم سحب رقم ACID المعتمد، ورقم نموذج 4 البنكي الموثق، وبيانات بوليصة الشحن تلقائياً لحساب الوعاء الضريبي والضرائب المقدرة طبقاً لجدول التعريفة الجمركية والاتفاقيات التفضيلية.';
  @override String get customsDeclSelectFileLabel => 'ملف الشحنة لقيد شهادة 46 *';
  @override String get customsDeclSearchFileHint => 'ابحث برقم الملف أو اسم المورد...';
  @override String get customsDeclAttributesHeader => 'بيانات الإقرار الجمركي وأرقام القيد المعتمدة:';
  @override String get customsDeclDeclarationNoLabel => 'رقم الإقرار والشهادة الجمركية (46 ك.م) *';
  @override String get customsDeclSubmissionDateLabel => 'تاريخ القيد المبدئي *';
  @override String get customsDeclAcidNumberLabel => 'رقم القيد المسبق (ACID)';
  @override String get customsDeclForm4NumberLabel => 'رقم نموذج 4 البنكي المعتمد';
  @override String get customsDeclBlNumberLabel => 'رقم بوليصة الشحن (B/L)';
  @override String get customsDeclDutiesHeader => 'الوعاء الضريبي والرسوم المقدرة (بالجنيه المصري):';
  @override String get customsDeclCifValueLabel => 'القيمة الجمركية CIF (جنيه)';
  @override String get customsDeclImportDutyLabel => 'ضريبة الوارد المقدرة (جنيه)';
  @override String get customsDeclVatLabel => 'ضريبة القيمة المضافة VAT (جنيه)';
  @override String get customsDeclTotalDutiesLabel => 'إجمالي الضرائب والرسوم المقدرة';
  @override String get customsDeclExemptionHeader => 'الموقف الجمركي وتطبيق الإعفاءات التفضيلية:';
  @override String get customsDeclExemptionConditionsHeader => '📌 الشروط والضوابط الإلزامية للاستفادة من الإعفاء الجمركي:';
  @override String get customsDeclEur1ExemptionTitle => 'اتفاقية الشراكة المصرية الأوروبية (EUR.1) — إعفاء جمركي 0% لضريبة الوارد';
  @override String get customsDeclEur1Condition1 => 'تقديم شهادة المنشأ الأوروبية (EUR.1 / COO) الأصلية المعتمدة ومستوفاة للأختام الرسمية.';
  @override String get customsDeclEur1Condition2 => 'إثبات الشحن المباشر (Direct Transport) من دولة المنشأ بالاتحاد الأوروبي إلى الموانئ المصرية.';
  @override String get customsDeclEur1Condition3 => 'إدراج رقم ACID وقيد المصنع المعتمد بالفاتورة التجارية وبوليصة الشحن.';
  @override String customsDeclMfnExemptionTitle(String rate) => 'خاضع للتعريفة الجمركية العامة (MFN Standard Tariff) — ضريبة الوارد $rate%';
  @override String get customsDeclMfnCondition1 => 'تقديم شهادة المنشأ الرسمية الموثقة من الغرفة التجارية لدولة المصدر.';
  @override String get customsDeclMfnCondition2 => 'سداد الرسوم والضرائب الجمركية المقررة عبر إذن سداد منظومة نافذة.';
  @override String get customsDeclRegulatoryHeader => 'العروض والموافقات المطلوبة والاشتراطات الرقابية:';
  @override String get customsDeclColHsCode => 'بند التعريفة (HS Code)';
  @override String get customsDeclColAuthority => 'جهة العرض الرقابي';
  @override String get customsDeclColInspection => 'فحص مسبق';
  @override String get customsDeclColCoo => 'شهادة المنشأ';
  @override String get customsDeclColRequirements => 'الاشتراطات والملاحظات الرقابية';
  @override String get customsDeclColApprovalStatus => 'حالة الموافقة';
  @override String get customsDeclStatusFulfilled => 'مستوفى ومعتمد';
  @override String get customsDeclDefaultAuthority => 'الهيئة العامة للرقابة على الصادرات والواردات (GOEIC)';
  @override String get customsDeclDefaultNote => 'مطلوب العرض الفني وسحب عينات مطابقة للمواصفات القياسية المصرية';
  @override String get customsDeclDefaultItemDesc => 'بند البضائع والمنتجات المستوردة';
  @override String get customsDeclVisualInspectionNote => 'فحص ظاهري ومطابقة مستندية قبل الإفراج الجمركي';
  @override String get customsDeclSaveButton => 'حفظ وقيد الإقرار الجمركي المبدئي';
  @override String get customsDeclSavingProgress => 'جارٍ الحفظ...';
  @override String get customsDeclSelectFileWarning => 'يرجى اختيار ملف الشحنة أولاً';
  @override String get customsDeclSaveSuccess => 'تم قيد وحفظ مسودة الإقرار الجمركي (46 ك.م) بنجاح';
  @override String get customsDeclRegistrySearchHint => 'بحث في سجل الإقرارات الجمركية وشهادات 46...';
  @override String get customsDeclRegisterNewButton => 'قيد إقرار جديد';
  @override String get customsDeclColDeclarationNo => 'رقم الإقرار (46 ك.م)';
  @override String get customsDeclColFileNumber => 'رقم الملف';
  @override String get customsDeclColSupplier => 'المورد الأجنبي';
  @override String get customsDeclColRegistrationDate => 'تاريخ القيد';
  @override String get customsDeclColDeclarationStatus => 'حالة الإقرار';
  @override String get customsDeclStatusRegisteredNafeza => 'مقيد مبدئياً على نافذة';

  // ── Screen 24: Customs Clearance Management ────────────────────────────────
  @override String get customsClearanceStageTitle => 'الميناء والتخليص الجمركي والمعاينة والمطابقة';
  @override String get customsClearanceTabFollowUp => 'متابعة الكشف والتثمين والتفتيش الجمركي';
  @override String get customsClearanceTabSamples => 'سحب العينات وتحديد عجز البضائع';
  @override String get customsClearanceTabDiscrepancy => 'إثبات الفاقد والتلف الجمركي ومحاضر النقص';
  @override String get customsClearanceTabDutyPayment => 'سداد الرسوم والضرائب الجمركية النهائية';
  @override String customsClearanceErrorFetch(String error) => 'خطأ في جلب بيانات التخليص الجمركي: $error';
  @override String get customsClearanceSearchHint => 'بحث بكود التخليص، رقم 46 ك.م، إذن التسليم...';
  @override String get customsClearanceFilterAll => 'جميع الحالات';
  @override String get customsClearanceFilterInspection => 'قيد المعاينة والفحص';
  @override String get customsClearanceFilterDutyRequested => 'مطلوب سداد الجمارك';
  @override String get customsClearanceFilterDutyPaid => 'تم سداد الرسوم';
  @override String get customsClearanceFilterFinalRelease => 'تم الإفراج النهائي';
  @override String get customsClearanceNewRecordButton => 'تسجيل معاملة تخليص';
  @override String get customsClearanceEmptyRecords => 'لا توجد سجلات تخليص جمركي مطابقة للبحث حالياً.';
  @override String get customsClearanceDeclaration46Label => '46 ك.م';
  @override String get customsClearanceDeliveryOrderLabel => 'إذن التسليم';
  @override String get customsClearanceOfficeLabel => 'الجمرك / المركز';
  @override String get customsClearanceFileRefLabel => 'ملف الشحنة المرجعي';
  @override String customsClearanceFreeDaysLabel(int days) => 'فترة السماح بالميناء: $days يوم';
  @override String get customsClearanceTotalDutiesCard => 'إجمالي الرسوم';
  @override String customsClearanceEstimatedDutiesCard(String est, String diff, String percent) => 'التقديري: $est ج.م (الفارق: $diff ج.م [$percent%])';
  @override String get customsClearancePaymentStatusLabel => 'حالة السداد';
  @override String get customsClearanceStatusPaid => 'تم السداد والتحقق';
  @override String get customsClearanceStatusPendingPayment => 'مطلوب السداد';
  @override String get customsClearanceEditTooltip => 'تعديل المعاملة';
  @override String get customsClearancePayTooltip => 'سداد ومطابقة الجمارك من نافذة';
  @override String get customsClearanceReleaseTooltip => 'إصدار الإفراج النهائي';
  @override String get customsClearanceSamplesBannerTitle => 'منظومة سحب العينات وتتبع الفحص المعملي وتحديد عجز البضائع';
  @override String get customsClearanceSamplesBannerDesc => 'توثيق إيصالات المعامل الرقابية (GOEIC, NFSA, Chemistry, Radiation) ومتابعة المهلة القانونية لنتائج التحليل ومطابقة الأوزان والطرود الفعلية.';
  @override String get customsClearanceAddSampleButton => 'تسجيل سحب عينة';
  @override String get customsClearanceSamplesTableTitle => 'سجل العينات المسحوبة للفحص والتحليل المعملي';
  @override String get customsClearanceColSampleCode => 'كود العينة';
  @override String get customsClearanceColAuthority => 'الجهة الرقابية / المعمل';
  @override String get customsClearanceColDrawingDate => 'تاريخ السحب';
  @override String get customsClearanceColReceiptNo => 'رقم الإيصال';
  @override String get customsClearanceColTestType => 'نوع الفحص والتحليل';
  @override String get customsClearanceColTestResult => 'نتيجة الفحص';
  @override String get customsClearanceColNotes => 'ملاحظات';
  @override String get customsClearanceSamplePassed => 'مطابقة للمواصفات';
  @override String get customsClearanceSamplePending => 'قيد الفحص المعملي';
  @override String get customsClearanceAddSampleDialogTitle => 'تسجيل سحب عينة معملية جديدة';
  @override String get customsClearanceSampleAuthLabel => 'الجهة الرقابية / المعمل *';
  @override String get customsClearanceSampleReceiptLabel => 'رقم إيصال السحب *';
  @override String get customsClearanceSampleTestTypeLabel => 'نوع التحليل المطلوب *';
  @override String get customsClearanceSampleNotesLabel => 'ملاحظات الكشاف والمعمل';
  @override String get customsClearanceSampleSaveButton => 'حفظ العينة';
  @override String get customsClearanceSampleSaveSuccess => 'تم تسجيل سحب العينة المعملية بنجاح';
  @override String get customsClearanceDamageBannerTitle => 'سجل إثبات الفاقد والتلف الجمركي ومحاضر المعاينة المشتركة';
  @override String get customsClearanceDamageBannerDesc => 'توثيق محاضر كسر الحاويات والبلل والنقص مع مندوب التوكيل الملاحي والجمارك والتأمين البحري لتحصيل التعويضات.';
  @override String get customsClearanceAddDamageButton => 'تحرير محضر مشترك';
  @override String get customsClearanceDamageTableTitle => 'محاضر المعاينة المشتركة والمطالبات التأمينية';
  @override String get customsClearanceColProtocolNo => 'رقم المحضر';
  @override String get customsClearanceColDeclarationNo => 'الإقرار الجمركي (46 ك.م)';
  @override String get customsClearanceColContainerNo => 'رقم الحاوية';
  @override String get customsClearanceColDamageType => 'طبيعة الضرر والتلف';
  @override String get customsClearanceColDamagedQty => 'الكمية التالفة';
  @override String get customsClearanceColEstimatedLoss => 'الخسارة المقدرة (جنيه)';
  @override String get customsClearanceColResponsibleParty => 'الجهة المتسببة بالضرر';
  @override String get customsClearanceColClaimStatus => 'حالة المطالبة';
  @override String get customsClearanceColDate => 'التاريخ';
  @override String get customsClearanceClaimApproved => 'معتمدة للتعويض';
  @override String get customsClearanceClaimSubmitted => 'مقدمة لشركة التأمين';
  @override String get customsClearanceAddDamageDialogTitle => 'تحرير محضر تلف وفاقد جمركي ومعاينة مشتركة';
  @override String get customsClearanceDamageDeclLabel => 'رقم الإقرار (46 ك.م) *';
  @override String get customsClearanceDamageContainerLabel => 'رقم الحاوية *';
  @override String get customsClearanceDamageTypeLabel => 'طبيعة الضرر والتلف *';
  @override String get customsClearanceDamagedQtyLabel => 'الكمية التالفة *';
  @override String get customsClearanceDamageLossLabel => 'الخسارة المقدرة (جنيه) *';
  @override String get customsClearanceDamagePartyLabel => 'الجهة المسؤولة عن الضرر *';
  @override String get customsClearanceDamageNotesLabel => 'تفاصيل المحضر المشترك والمعاينة';
  @override String get customsClearanceDamageSaveButton => 'حفظ المحضر';
  @override String get customsClearanceDamageSaveSuccess => 'تم تحرير وحفظ محضر المعاينة المشتركة بنجاح';
  @override String get customsClearancePaymentBannerTitle => 'منظومة سداد الرسوم والضرائب الجمركية وإذن الإفراج النهائي';
  @override String get customsClearancePaymentBannerDesc => 'مطابقة إذن سداد نافذة وتوثيق إيصالات السداد البنكي وحفظ الفروق المالية واعتماد إذن الإفراج وتصريح خروج البوابة.';
  @override String get customsClearanceDutyLedgerTableTitle => 'سجل أذون سداد نافذة المعتمدة ومطابقة الرسوم';
  @override String get customsClearanceEmptyDutyLedger => 'لا توجد مطالبات سداد مسجلة حالياً.';
  @override String get customsClearanceColClearanceCode => 'كود التخليص';
  @override String get customsClearanceColDecl46 => 'الإقرار (46 ك.م)';
  @override String get customsClearanceColCustomsOffice => 'الجمرك المختص';
  @override String get customsClearanceColActualDuty => 'الرسوم الفعلية (نافذة)';
  @override String get customsClearanceColEstimatedDuty => 'الرسوم التقديرية';
  @override String get customsClearanceColDutyVariance => 'الفارق المالي';
  @override String get customsClearanceColPaymentStatus => 'حالة السداد';
  @override String get customsClearanceColActions => 'إجراءات السداد والإفراج';
  @override String get customsClearanceBtnPaymentDetails => 'تفاصيل السداد';
  @override String get customsClearanceBtnPayReconcile => 'سداد ومطابقة';
  @override String get customsClearanceBtnFinalRelease => 'الإفراج النهائي';
  @override String get customsClearanceNewDialogTitle => 'تسجيل معاملة تخليص جمركي وميناء جديدة';
  @override String customsClearanceEditDialogTitle(String code) => 'تعديل بيانات التخليص الجمركي ($code)';
  @override String get customsClearanceExtractNafezaBtn => 'استخلاص من نافذة';
  @override String get customsClearanceExtractNafezaSuccess => 'تم استخلاص وتعبئة بيانات إقرار نافذة والرسوم بنجاح!';
  @override String get customsClearanceImportFileLabel => 'ملف الشحنة الاستيرادية المرتكز عليه *';
  @override String get customsClearanceImportFileSearchHint => 'ابحث برقم الملف أو كود الشحنة...';
  @override String get customsClearanceSelectFileValidator => 'يرجى اختيار ملف الشحنة';
  @override String get customsClearanceDecl46Label => 'رقم الإقرار الجمركي (46 ك.م)';
  @override String get customsClearanceDoNumberLabel => 'رقم إذن التسليم';
  @override String get customsClearanceFreeDaysInputLabel => 'أيام السماح بالميناء';
  @override String get customsClearanceOfficeInputLabel => 'اسم الجمرك والدائرة الجمركية *';
  @override String get customsClearanceOfficeValidator => 'يرجى إدخال اسم الجمرك';
  @override String get customsClearanceChannelLabel => 'المسار الجمركي *';
  @override String get customsClearanceChannelRed => 'مسار أحمر (معاينة وعينات)';
  @override String get customsClearanceChannelGreen => 'مسار أخضر (إفراج مستندي)';
  @override String get customsClearanceChannelYellow => 'مسار أصفر (مراجعة مستندية)';
  @override String get customsClearanceDutyBreakdownHeader => 'مطالبة الرسوم والضرائب الجمركية (بالجنيه المصري):';
  @override String get customsClearanceImportDutyInput => 'ضريبة الوارد';
  @override String get customsClearanceVatInput => 'ضريبة القيمة المضافة (VAT)';
  @override String get customsClearanceScheduleTaxInput => 'ضريبة الجدول';
  @override String get customsClearanceWhtInput => 'أرباح تجارية وصناعية (1%)';
  @override String get customsClearanceLabFeesInput => 'رسوم معملية وخدمات';
  @override String get customsClearanceEstimatedDutyInput => 'التقديري من النظام';
  @override String get customsClearanceSaveRecordBtn => 'حفظ المعاملة';
  @override String get customsClearanceSaveRecordSuccess => 'تم حفظ معاملة التخليص بنجاح';
  @override String customsClearanceSaveRecordError(String err) => 'خطأ أثناء الحفظ: $err';
  @override String customsClearanceDutyPaymentDialogTitle(String code) => 'سداد ومطابقة رسوم الجمارك ($code)';
  @override String get customsClearanceExtractReceiptBtn => 'استخلاص إيصال السداد';
  @override String customsClearanceEstimatorDutyBoxLabel(String amount) => 'الرسوم التقديرية: $amount ج.م';
  @override String customsClearanceNafezaDutyBoxLabel(String amount) => 'المطلوب بطلب سداد نافذة: $amount ج.م';
  @override String get customsClearanceVarianceBoxLabel => 'فارق التباين الضريبي:';
  @override String get customsClearanceActualPaidInput => 'إجمالي المبلغ الفعلي المسدد (جنيه) *';
  @override String get customsClearanceBankReceiptInput => 'رقم إيصال السداد البنكي والتحويل *';
  @override String get customsClearanceVarianceReasonInput => 'أسباب الفارق إن وجدت (تسويات معملية، بنود إضافية...)';
  @override String get customsClearanceConfirmPaymentBtn => 'تأكيد السداد والترحيل';
  @override String get customsClearancePaymentSuccess => 'تم توثيق سداد الرسوم الجمركية ومطابقة نافذة بنجاح';
  @override String customsClearancePaymentError(String err) => 'خطأ أثناء توثيق السداد: $err';
  @override String get customsClearanceFinalReleaseDialogTitle => 'إصدار تصريح الإفراج الجمركي النهائي';
  @override String get customsClearanceFinalReleaseDialogDesc => 'سيتم تغيير حالة المعاملة إلى الإفراج النهائي المعتمد وجاهزية خروج الحاويات من الميناء.';
  @override String get customsClearanceReleasePermitInput => 'رقم تصريح الإفراج الجمركي وتصريح البوابة *';
  @override String get customsClearanceConfirmReleaseBtn => 'اعتماد الإفراج النهائي';
  @override String get customsClearanceReleaseSuccess => 'تم منح الإفراج الجمركي النهائي بنجاح!';
  @override String customsClearanceReleaseError(String err) => 'خطأ أثناء منح الإفراج: $err';

  // ── Screen 25: Freight Booking ─────────────────────────────────────────────
  @override String get freightBookingStageTitle => 'حجز الشحن وتخصيص الحاويات';
  @override String get freightBookingTabRegistry => 'سجل حجوزات الشحن والناقلين';
  @override String get freightBookingTabNewRequest => 'طلب حجز شحن جديد';
  @override String get freightBookingCreateButton => 'إنشاء حجز شحن جديد';
  @override String get freightBookingSearchHint => 'بحث بكود الحجز أو رقم التأكيد...';
  @override String get freightBookingFilterStatusLabel => 'تصفية حسب الحالة';
  @override String get freightBookingFilterStatusHint => 'ابحث عن الحالة...';
  @override String get freightBookingStatusAll => 'جميع الحالات';
  @override String get freightBookingStatusDraft => 'مسودة';
  @override String get freightBookingStatusRequested => 'تم طلب الحجز';
  @override String get freightBookingStatusConfirmed => 'مؤكد';
  @override String get freightBookingStatusSailed => 'أبحر / غادر';
  @override String get freightBookingEmptyRecords => 'لا توجد حجوزات شحن مسجلة بالنظام. اضغط إضافة حجز جديد.';
  @override String get freightBookingColActions => 'العمليات ⚡';
  @override String get freightBookingColBookingCode => 'كود الحجز';
  @override String get freightBookingColImportFile => 'ملف الشحنة';
  @override String get freightBookingColConfirmationNo => 'رقم تأكيد الحجز';
  @override String get freightBookingColCarrierForwarder => 'الخط الملاحي والوكيل';
  @override String get freightBookingColRoute => 'مسار الشحن (POL ➔ POD)';
  @override String get freightBookingColVesselVoyage => 'السفينة ورقم الرحلة';
  @override String get freightBookingColDeparture => 'تاريخ المغادرة';
  @override String get freightBookingColArrival => 'تاريخ الوصول';
  @override String get freightBookingColContainers => 'الحاويات المخصصة';
  @override String get freightBookingColTotalFreight => 'إجمالي النولون USD';
  @override String get freightBookingColStatus => 'الحالة';
  @override String freightBookingApprovedQuoteLabel(String provider) => 'عرض معتمد: $provider';
  @override String freightBookingWhArrivalLabel(String date) => 'مخزن: $date';
  @override String get freightBookingPendingDate => 'لم يحدد بعد';
  @override String get freightBookingViewTooltip => 'عرض تفاصيل الحجز';
  @override String get freightBookingEditTooltip => 'تعديل حجز الشحن';
  @override String get freightBookingPrintTooltip => 'طباعة بطاقة الحجز';
  @override String get freightBookingDeleteTooltip => 'حذف حجز الشحن';
  @override String get freightBookingDeleteConfirmTitle => 'تأكيد الحذف';
  @override String freightBookingDeleteConfirmMessage(String code) => 'هل أنت متأكد من حذف حجز الشحن $code؟';
  @override String get freightBookingNewDialogTitle => 'إنشاء حجز شحن ملاحي';
  @override String freightBookingEditDialogTitle(String code) => 'تعديل حجز الشحن: $code';
  @override String get freightBookingCloseTooltip => 'إغلاق النافذة';
  @override String get freightBookingTabBookingDetails => '1. تفاصيل الحجز وعروض الشحن';
  @override String get freightBookingTabCostBreakdown => '2. بنود التكلفة والنولون';
  @override String get freightBookingImportFileLabel => 'ملف الشحنة الاستيرادية *';
  @override String get freightBookingImportFileHint => 'ابحث عن ملف الشحنة...';
  @override String get freightBookingConfirmNoInputLabel => 'رقم تأكيد الحجز *';
  @override String get freightBookingConfirmNoValidator => 'أدخل رقم تأكيد الحجز';
  @override String get freightBookingEvaluatedQuotesHeader => 'عروض وسيناريوهات الشحن المقيمة للملف:';
  @override String freightBookingAvailableQuotesBadge(int count) => '$count عرض متاح';
  @override String get freightBookingNoEvaluatedQuotes => 'لم يتم العثور على دراسة سيناريوهات شحن محفوظة لهذا الملف. يمكنك تعبئة بيانات الناقل أدناه يدوياً.';
  @override String get freightBookingApplyQuoteInstruction => 'اضغط على زر "اعتماد وتطبيق هذا العرض" لتعبئة بيانات الناقل، الموانئ، السفينة، المواعيد، التكاليف، والحاويات آلياً:';
  @override String get freightBookingBestQuoteBadge => 'الأفضل في الدراسة';
  @override String freightBookingQuoteVesselDetails(String vessel, String voyage, String pol, String pod) => 'سفينة: $vessel | رحلة: $voyage | موانئ: $pol ➔ $pod';
  @override String freightBookingQuoteScheduleDetails(String sailing, String eta, int days) => 'إبحار: $sailing ➔ وصول متوقع: $eta | فري تايم: $days يوم';
  @override String freightBookingQuoteStudyRef(String code, String date) => 'دراسة: $code ($date)';
  @override String get freightBookingSelectedQuoteBtn => 'العرض المعتمد ⭐';
  @override String get freightBookingApplyQuoteBtn => 'اعتماد هذا العرض';
  @override String freightBookingQuoteAppliedSuccess(String provider, String vessel) => 'تم استدعاء وتحديث بيانات العرض المعتمد بنجاح ($provider - $vessel)!';
  @override String get freightBookingShippingLineLabel => 'الخط الملاحي *';
  @override String get freightBookingShippingLineHint => 'ابحث عن الخط الملاحي...';
  @override String get freightBookingForwarderLabel => 'وكيل الشحن';
  @override String get freightBookingForwarderHint => 'ابحث عن وكيل الشحن...';
  @override String get freightBookingPolLabel => 'ميناء التحميل *';
  @override String get freightBookingPolHint => 'ابحث عن ميناء التحميل...';
  @override String get freightBookingPodLabel => 'ميناء الوصول *';
  @override String get freightBookingPodHint => 'ابحث عن ميناء الوصول...';
  @override String get freightBookingEtdLabel => 'تاريخ المغادرة المتوقع *';
  @override String get freightBookingEtaLabel => 'تاريخ الوصول المتوقع *';
  @override String get freightBookingAtdLabel => 'تاريخ المغادرة الفعلي';
  @override String freightBookingDelayBannerDelayed(int days) => '⚠️ تأخير في الإبحار: $days يوم عن الموعد المجدول';
  @override String get freightBookingDelayBannerOnTime => '✅ تم الإبحار في الموعد المجدول (لا توجد تأخيرات)';
  @override String freightBookingExpectedWhArrival(String date) => 'موعد الوصول للمخزن المتوقع: $date';
  @override String get freightBookingFreeDaysInput => 'الأيام المجانية بالميناء *';
  @override String get freightBookingWarehouseDaysInput => 'أيام الوصول للمخزن';
  @override String get freightBookingStatusInputLabel => 'حالة الحجز *';
  @override String get freightBookingVesselNameInput => 'اسم السفينة';
  @override String get freightBookingVoyageNoInput => 'رقم الرحلة';
  @override String get freightBookingReleaseOrderInput => 'إذن الإفراج عن الحاويات';
  @override String get freightBookingContainerTypeInput => 'نوع الحاوية المطلوب حجزها';
  @override String get freightBookingContainersQtyInput => 'عدد الحاويات المحجوزة';
  @override String get freightBookingEquipmentNote => 'ℹ️ ملاحظة: تخصيص الحاويات التفصيلي، أرقام السيل، أوزان VGM، والفحص يتم في مرحلة (متابعة وتجهيز التحميل).';
  @override String get freightBookingCostBreakdownTitle => 'تفاصيل بنود عرض السعر الشاملة:';
  @override String freightBookingBaseCurrencyLabel(String cur) => 'العملة الأساسية: $cur';
  @override String get freightBookingItemRateLabel => 'سعر البند';
  @override String get freightBookingCurrencyLabel => 'العملة';
  @override String get freightBookingQuantityLabel => 'الكمية';
  @override String get freightBookingCbmVolumeLabel => 'الحجم CBM';
  @override String get freightBookingItemActive => 'مطبق';
  @override String get freightBookingItemInactive => 'غير مطبق';
  @override String get freightBookingItem40ft => '1. شحن حاوية 40 قدم';
  @override String get freightBookingItem20ft => '2. شحن حاوية 20 قدم';
  @override String get freightBookingItemLcl => '3. نولون مجزأ (LCL CBM)';
  @override String get freightBookingItemCourier => '4. البريد السريع للمستندات';
  @override String get freightBookingItemEur1 => '5. شهادة المنشأ (EUR.1 / ATR)';
  @override String get freightBookingItemVgm => '6. مصاريف التحقق من الوزن (VGM)';
  @override String get freightBookingItemVgmNotif => '7. إخطار إقرار الوزن';
  @override String get freightBookingItemTelex => '8. إطلاق الفاكس الملاحي';
  @override String get freightBookingItemInsurance => '9. بوليصة التأمين البحري';
  @override String get freightBookingItemCancellation => '10. غرامة إلغاء الحجز';
  @override String get freightBookingItemIcs2 => '11. رسوم بيان الحمول المسبقة (ICS2)';
  @override String get freightBookingItemOther => '12. مصاريف ورسوم أخرى';
  @override String get freightBookingItemDocFees => '13. مصاريف إصدار وثائق الشحن';
  @override String get freightBookingItemWaiver => '14. رسوم خطاب التنازل';
  @override String get freightBookingItemDthc => '15. تفريغ ومناولة ميناء الوصول (DTHC)';
  @override String get freightBookingItemStorageWeek => '16. أرضيات وتخزين الأسبوع الأول';
  @override String get freightBookingItemStorageExtra => '17. أرضيات وتخزين الأيام الإضافية';
  @override String get freightBookingMismatchTitle => 'تنبيه عدم تطابق الحاويات';
  @override String freightBookingMismatchWarning(String assigned, String suggested) => 'عدد الحاويات المخصصة ونوعها ($assigned) مختلف عن الحاوية المقترحة ($suggested).';
  @override String get freightBookingMismatchPrompt => 'هل ترغب في الاستمرار وتثبيت هذا التخصيص؟';
  @override String get freightBookingMismatchNote => 'في حال اختيار "نعم"، يتطلب النظام إدخال سبب التغيير لتوثيق القرار.';
  @override String get freightBookingMismatchBtnNo => 'لا (العودة للمطابقة)';
  @override String get freightBookingMismatchBtnYes => 'نعم (الاستمرار وكتابة السبب)';
  @override String get freightBookingMismatchReasonTitle => 'سبب تغيير الحاويات المقترحة *';
  @override String get freightBookingMismatchReasonHint => 'اكتب سبب اعتماد هذا التخصيص المختلف...';
  @override String get freightBookingMismatchReasonValidator => 'يجب إدخال سبب التغيير للاستمرار';
  @override String get freightBookingMismatchReasonConfirm => 'تأكيد وحفظ';
  @override String get freightBookingDuplicateTitle => 'تنبيه: الشحنة مسجلة بالفعل!';
  @override String get freightBookingDuplicateMessage => 'ملف الشحنة الاستيرادية المختار مرتبط بالفعل بحجز شحن محفوظ:';
  @override String get freightBookingDuplicateRowFile => 'ملف الشحنة:';
  @override String get freightBookingDuplicateRowCode => 'كود الحجز:';
  @override String get freightBookingDuplicateRowConfirmNo => 'رقم تأكيد الحجز:';
  @override String get freightBookingDuplicateRowLine => 'الخط الملاحي:';
  @override String get freightBookingDuplicateRowStatus => 'الحالة الحالية:';
  @override String get freightBookingDuplicateNotice => 'قواعد النظام تمنع إنشاء أكثر من حجز لنفس الملف الاستيرادي. يمكنك التحويل لتعديل الحجز الحالي فوراً.';
  @override String get freightBookingDuplicateBtnCancel => 'إلغاء والتراجع';
  @override String get freightBookingDuplicateBtnSwitch => 'التحويل إلى التعديل';
  @override String get freightBookingBtnCloseDiscard => 'إغلاق وتراجع';
  @override String get freightBookingBtnLiveReload => 'إعادة تحميل حية';
  @override String get freightBookingBtnClearNew => 'تفريغ وبدء تسجيل جديد';
  @override String get freightBookingBtnSaveDraft => 'حفظ مسودة ومتابعة لاحقة';
  @override String get freightBookingBtnSaveConfirm => 'حفظ وتأكيد حجز الشحن';
  @override String get freightBookingBtnUpdate => 'تحديث وحفظ الحجز';
  @override String get freightBookingSaveSuccess => 'تم حفظ وتأكيد حجز الشحن بنجاح!';
  @override String freightBookingViewTitle(String code) => 'تفاصيل حجز الشحن: $code';
  @override String get freightBookingViewShippingLine => 'الخط الملاحي:';
  @override String get freightBookingViewConfirmNo => 'رقم التأكيد:';
  @override String get freightBookingViewRouteSection => 'المسار والمواعيد:';
  @override String get freightBookingViewPol => 'ميناء التحميل:';
  @override String get freightBookingViewPod => 'ميناء الوصول:';
  @override String freightBookingViewVesselVoyage(String vessel, String voyage) => 'السفينة: $vessel (رحلة: $voyage)';
  @override String freightBookingViewTransitTime(int days) => 'مدة الترانزيت: $days يوم';
  @override String freightBookingViewEtd(String date) => 'تاريخ المغادرة (ETD): $date';
  @override String freightBookingViewEta(String date) => 'تاريخ الوصول (ETA): $date';
  @override String freightBookingViewAtd(String date, String delay) => 'تاريخ المغادرة الفعلي (ATD): $date ($delay)';
  @override String freightBookingViewExpectedWh(String date) => 'وصول المخزن المتوقع: $date';
  @override String get freightBookingViewContainersSection => 'الحاويات وأرقام السيل المخصصة:';
  @override String get freightBookingViewChargesSection => 'بنود التكاليف والنولون المعتمدة:';
  @override String get freightBookingViewTotalFreight => 'إجمالي النولون التقديري (USD):';
  @override String freightBookingPrintTitle(String code) => 'طباعة بطاقة حجز الشحن: $code';
  @override String freightBookingPrintManifestHeader(String code) => 'سند تأكيد حجز الشحن الملاحي ($code)';
  @override String freightBookingPrintDate(String date) => 'تاريخ الطباعة: $date';
  @override String get freightBookingPrintContainersHeader => 'قائمة الحاويات وأرقام السيل:';
  @override String get freightBookingPrintChargesHeader => 'إجمالي النولون والمصاريف المعتمدة:';
  @override String freightBookingPrintGrandTotal(String amount) => 'الإجمالي العام: \$ $amount USD';
  @override String get freightBookingPrintNowBtn => 'طباعة الآن';
  @override String get freightBookingPrintSuccess => 'تم إرسال سند الحجز للطباعة بنجاح!';

  // ── Screen 26 & 52: Cargo Shipping Tracking & Freight Allocations (VGM) ───
  @override String get cargoShippingAllocationsTitle => 'تخصيص وتوزيع الحاويات ومتابعة حركة الشحن (VGM)';
  @override String get cargoShippingTrackingTitle => 'متابعة حركة الشحن وتحميل وتوريد الحاويات (48h SLA)';
  @override String get cargoShippingFormTab => 'تجهيز الشحن ومتابعة التحميل';
  @override String get cargoShippingRegistryTab => 'سجل متابعة الشحنات والتحميل';
  @override String get cargoShippingUploadBlLabel => 'رفع واستخراج B/L (PDF / Word / Excel)';
  @override String cargoShippingUploadBlSuccess(String blNo) => 'تم استخراج بيانات شحنة B/L بنجاح ($blNo)';
  @override String get cargoShippingLinkedFileBannerPrefix => 'ملف الاستيراد المربوط:';
  @override String get cargoShippingSupplierLabel => 'المورد:';
  @override String get cargoShippingCodeLabel => 'كود الشحنة:';
  @override String get cargoShippingCancelStartNew => 'إلغاء والبدء من جديد';
  @override String get cargoShippingStep1Title => '1. تخصيص الحاويات والـ VGM';
  @override String get cargoShippingStep2Title => '2. متابعة تحميل وتوريد الحاويات (48h SLA)';
  @override String get cargoShippingImportFileLabel => 'ملف الشحنة الاستيرادية المربوط *';
  @override String get cargoShippingImportFileHint => 'اختر ملف الشحنة...';
  @override String get cargoShippingImportFileDefault => '-- اختر ملف الشحنة --';
  @override String get cargoShippingPreviouslyRegistered => '(مسجل سابقاً)';
  @override String get cargoShippingSelectFileValidator => 'يرجى اختيار ملف الشحنة';
  @override String get cargoShippingShipmentTypeLabel => 'نوع الشحنة *';
  @override String get cargoShippingFclLabel => 'FCL (حاوية كاملة)';
  @override String get cargoShippingLclLabel => 'LCL (تجميع بضائع - CFS)';
  @override String cargoShippingAggregatedCargoMetrics(String cbm, String weight) => 'حمولة الملف المجمعة من قوائم التعبئة: $cbm m³ | $weight kg';
  @override String get cargoShippingCargoStackingLabel => 'نوع التحميل والتخزين:';
  @override String get cargoShippingStackable => 'قابل للرص';
  @override String get cargoShippingNonStackable => 'غير قابل للرص';
  @override String cargoShippingAutoRecommendation(int count, String code, String spaceUtil, String weightUtil) => 'اقتراح الحاوية التلقائي: $count x $code (استغلال المساحة: $spaceUtil% | استغلال الوزن: $weightUtil%)';
  @override String get cargoShippingContainersHeader => 'بيانات الحاويات المخصصة وأرقام السيل والـ VGM:';
  @override String get cargoShippingAddContainerType => 'إضافة نوع حاوية جديد';
  @override String get cargoShippingContainerType => 'نوع الحاوية';
  @override String get cargoShippingQty => 'العدد';
  @override String get cargoShippingVgmWeight => 'إجمالي VGM (كجم)';
  @override String get cargoShippingUnitDetailsHeader => 'تفاصيل أرقام الحاويات والسيل لكل وحدة:';
  @override String cargoShippingUnitPrefix(int number) => 'حاوية #$number: ';
  @override String get cargoShippingContainerNo => 'رقم الحاوية';
  @override String get cargoShippingSealNo => 'رقم السيل / القفل';
  @override String get cargoShippingCfsHeader => 'بيانات مخزن تجميع الشحنة (CFS):';
  @override String get cargoShippingCfsWarehouseLabel => 'اسم وموقع مخزن التجميع (CFS)';
  @override String get cargoShippingImportFileTrackingLabel => 'ملف الشحنة الاستيرادية المربوط للمتابعة *';
  @override String get cargoShippingImportFileTrackingHint => 'اختر ملف الشحنة لمتابعة التوريد والتحميل...';
  @override String cargoShippingActiveFileTrackingBanner(String fileCode, String company, String supplier, String acid) => 'ملف الاستيراد: [$fileCode] $company | المورد: $supplier | ACID: $acid';
  @override String get cargoShippingMetricTotalContainers => 'إجمالي الحاويات';
  @override String get cargoShippingMetricInProgress => 'جاري التحميل والتوريد';
  @override String get cargoShippingMetricGatedIn => 'دخلت الميناء';
  @override String get cargoShippingMetricSlaBreached => 'تجاوزت مهلة SLA (48h)';
  @override String cargoShippingContainerCardHeader(int index, String containerNo, String containerType, String sealNo) => 'حاوية #$index: $containerNo ($containerType) | سيل: $sealNo';
  @override String get cargoShippingSlaBreachedBadge => 'تجاوزت مهلة الـ 48h SLA';
  @override String get cargoShippingQuickSaveContainer => 'حفظ تحديث هذه الحاوية 💾';
  @override String get cargoShippingMilestone1 => '1. التخصيص';
  @override String get cargoShippingMilestone2 => '2. وصول للمورد';
  @override String get cargoShippingMilestone3 => '3. بداية التحميل';
  @override String get cargoShippingMilestone4 => '4. نهاية التحميل';
  @override String get cargoShippingMilestone5 => '5. دخول الميناء';
  @override String get cargoShippingMilestone1Title => 'تاريخ ووقت التخصيص';
  @override String get cargoShippingMilestone2Title => 'وصول للمورد';
  @override String get cargoShippingMilestone3Title => 'بداية التحميل';
  @override String get cargoShippingMilestone4Title => 'نهاية التحميل';
  @override String get cargoShippingMilestone5Title => 'دخول الميناء';
  @override String get cargoShippingPickMilestone1 => 'تسجيل تاريخ ووقت تخصيص الحاوية';
  @override String get cargoShippingPickMilestone2 => 'تسجيل وصول الحاوية لدى المورد';
  @override String get cargoShippingPickMilestone3 => 'تسجيل بداية تحميل وتعبئة الحاوية';
  @override String get cargoShippingPickMilestone4 => 'تسجيل نهاية التحميل وتركيب السيل';
  @override String get cargoShippingPickMilestone5 => 'تسجيل دخول الحاوية بوابة الميناء';
  @override String get cargoShippingPickBtn => 'اختيار 📅';
  @override String get cargoShippingSetNowBtn => 'الآن ⚡';
  @override String get cargoShippingClickToSetDateTime => 'انقر لتسجيل التاريخ والوقت 📅';
  @override String cargoShippingNotesHeader(String containerName) => 'تدوين وملاحظات مراحل التسلسل الزمني للحاوية ($containerName):';
  @override String get cargoShippingSelectMilestoneTarget => 'اختر المرحلة المستهدفة: ';
  @override String get cargoShippingTagDriverDelayed => '⚠️ تأخر السائق في الاستلام';
  @override String get cargoShippingTagPermitPending => '⏳ انتظار إذن وتصريح التحميل';
  @override String get cargoShippingTagContainerInspection => '🔍 فحص سلامة الحاوية والسيل';
  @override String get cargoShippingTagPortCongestion => '🛑 ازدحام عند بوابة الميناء';
  @override String get cargoShippingTagPalletizedCargo => '📦 بضاعة معبأة على بالتات خشبية';
  @override String get cargoShippingTagVisualCheck => '📝 فحص ظاهري ومطابقة الباكنج ليست';
  @override String cargoShippingNoteHint(String stepTitle) => 'اكتب ملاحظة تفصيلية للمرحلة المحددة ($stepTitle)...';
  @override String get cargoShippingSaveNote => 'حفظ الملاحظة 💾';
  @override String get cargoShippingClearNote => 'مسح الملاحظة';
  @override String cargoShippingLclTrackingHeader(String warehouse) => 'متابعة تجميع بضائع الـ LCL بمخزن: $warehouse';
  @override String get cargoShippingQuickSaveLcl => 'حفظ مرحلة الـ LCL 💾';
  @override String get cargoShippingLclMilestone1 => '1. جدولة التجميع';
  @override String get cargoShippingLclMilestone2 => '2. وصول مخزن CFS';
  @override String get cargoShippingLclMilestone3 => '3. بداية التعبئة';
  @override String get cargoShippingLclMilestone4 => '4. نهاية التعبئة';
  @override String get cargoShippingLclMilestone5 => '5. دخول الميناء';
  @override String get cargoShippingLclPickMilestone1 => 'تسجيل تاريخ وتوقيت جدولة التجميع بمخزن CFS';
  @override String get cargoShippingLclPickMilestone2 => 'تسجيل وصول البضاعة لمخزن التجميع (CFS)';
  @override String get cargoShippingLclPickMilestone3 => 'تسجيل بداية تعبئة الحاوية المجمعة';
  @override String get cargoShippingLclPickMilestone4 => 'تسجيل اكتمال تعبئة وتجهيز الحاوية';
  @override String get cargoShippingLclPickMilestone5 => 'تسجيل دخول الحاوية المجمعة للميناء';
  @override String get cargoShippingAutoCompleteCycle => 'استيفاء وتأكيد دورة التحميل ودخول الميناء ⚡';
  @override String get cargoShippingClearStartNew => 'تفريغ وبدء تسجيل جديد 🔄';
  @override String get cargoShippingSaveDraft => 'حفظ مؤقت ومتابعة لاحقة 💾';
  @override String get cargoShippingUpdateStudy => 'تحديث وحفظ دراسة ملف الاستيراد';
  @override String get cargoShippingSaveStudy => 'حفظ دراسة ملف الاستيراد وتأكيد المتابعة';
  @override String get cargoShippingRegistrySearchHint => 'بحث باسم أو كود ملف الاستيراد، اسم الشركة، كود الشحن، أو رقم الحاوية...';
  @override String get cargoShippingStatusFilterLabel => 'حالة الشحن';
  @override String get cargoShippingStatusAll => 'كافة الحالات';
  @override String get cargoShippingStatusCargoReady => 'جاهزية البضاعة';
  @override String get cargoShippingStatusCompleted => 'مكتمل';
  @override String get cargoShippingSlaFilterLabel => 'مهلة الـ 48h SLA';
  @override String get cargoShippingSlaAll => 'كافة المهل';
  @override String get cargoShippingSlaOnTimeFilter => 'ضمن المهلة';
  @override String get cargoShippingSlaBreachedFilter => 'متأخرة عن SLA';
  @override String get cargoShippingActiveFilterLabel => 'السجلات النشطة / المحذوفة';
  @override String get cargoShippingActiveAll => 'كافة السجلات (النشطة والمحذوفة)';
  @override String get cargoShippingActiveOnly => 'النشطة فقط';
  @override String get cargoShippingDeletedOnly => 'المحذوفة فقط';
  @override String get cargoShippingNoMatchingRecords => 'لا توجد دراسات متابعة مطابقة للبحث الحالي.';
  @override String get cargoShippingCreateNewRecord => 'تسجيل ومتابعة شحنة جديدة';
  @override String get cargoShippingSoftDeletedBadge => 'محذوف منطقياً';
  @override String cargoShippingGatedCountBadge(int count, int total) => 'دخلت الميناء: $count / $total';
  @override String get cargoShippingSlaBreached => '⚠️ متأخر عن SLA';
  @override String get cargoShippingSlaOnTime => '✅ ضمن الـ 48h SLA';
  @override String get cargoShippingEditTooltip => 'تعديل ومتابعة الحاويات وإعادة التفعيل';
  @override String get cargoShippingRestoreTooltip => 'استعادة وتفعيل السجل';
  @override String cargoShippingLoadSuccessSnack(String identifier) => '📂 تم استدعاء البيانات وتحديثات المراحل المحفوظة للشحنة ($identifier) بنجاح!';
  @override String cargoShippingSaveContainerMilestoneSuccess(String containerNo, String status) => '💾 تم حفظ وتحديث مرحلة الحاوية ($containerNo) بنجاح! الحالة: $status';
  @override String cargoShippingSaveLclMilestoneSuccess(String status) => '💾 تم حفظ وتحديث مرحلة تجميع الـ LCL بنجاح! الحالة: $status';
  @override String get cargoShippingAutoCompleteSuccess => '⚡ تم استيفاء دورة التحميل ودخول الميناء لجميع الحاويات بنجاح!';
  @override String cargoShippingStudySaveSuccess(String code) => '✅ تم حفظ وتحديث دراسة ومتابعة ملف الاستيراد ($code) بنجاح!';
  @override String get cargoShippingDraftSaveSuccess => '💾 تم الحفظ المؤقت بنجاح (Draft)! تم الاحتفاظ بالبيانات ويمكنك استكمال المراحل في أي وقت.';
  @override String cargoShippingRestoreSuccess(String code) => '♻️ تم استعادة سجل متابعة الشحن ($code) بنجاح!';
  @override String cargoShippingDeleteSuccess(String code) => '🗑️ تم حذف سجل الشحن ($code) منطقياً.';
  @override String get cargoShippingDeleteConfirmTitle => 'تأكيد الحذف المنطقي لسجل الشحن';
  @override String cargoShippingDeleteConfirmMessage(String code, String fileCode) => 'هل أنت متأكد من حذف سجل الشحن ($code) لملف الاستيراد ($fileCode)؟\n\nيمكنك استعادته أو إعادة تفعيله في أي وقت من خلال تعديله أو عبر زر الاستعادة.';
  @override String get cargoShippingConfirmDeleteBtn => 'تأكيد الحذف';
  @override String get cargoShippingDuplicateWarningTitle => 'تنبيه عدم التكرار / تعارض الحاوية';
  @override String get cargoShippingGoToSavedRegistry => 'الانتقال لسجل المتابعة المحفوظ';
  @override String get cargoShippingDateSequenceError => '⚠️ لا يمكن اختيار تاريخ ووقت يسبق توقيت المرحلة السابقة في التسلسل الزمني!';
  @override String get cargoShippingSelectFileFirstForContainer => '⚠️ يرجى اختيار ملف الشحنة الاستيرادية المربوط أولاً في الخطوة 1 قبل حفظ تحديثات الحاوية.';
  @override String get cargoShippingSelectFileFirstForLcl => '⚠️ يرجى اختيار ملف الشحنة الاستيرادية المربوط أولاً في الخطوة 1 قبل حفظ تحديثات LCL.';
  @override String cargoShippingQuickSaveError(String msg) => '❌ تعذر الحفظ المؤقت للمرحلة: $msg';
  @override String cargoShippingLclSaveError(String msg) => '❌ تعذر حفظ مرحلة الـ LCL: $msg';
  @override String get cargoShippingFillRequiredFields => 'يرجى التأكد من تعبئة جميع الحقول المطلوبة.';
  @override String get cargoShippingSelectLinkedFilePrompt => 'يرجى اختيار ملف الشحنة الاستيرادية المربوط أولاً.';
  @override String get cargoShippingStatusGatedIn => 'دخلت الميناء';
  @override String get cargoShippingStatusLoadingCompleted => 'اكتمل التحميل';
  @override String get cargoShippingStatusLoadingInProgress => 'جاري التحميل';
  @override String get cargoShippingStatusArrivedAtSupplier => 'وصلت لدى المورد';
  @override String get cargoShippingStatusArrivedAtCfs => 'وصلت لمخزن التجميع (CFS)';
  @override String get cargoShippingStatusAssigned => 'تم التخصيص';
  @override String get cargoShippingStatusPendingAssignment => 'قيد التخصيص';

  // Screen 28: Warehouse Receiving & Inspection (GRN)
  @override String get warehouseReceivingStageTitle => 'استلام البضائع بالمخازن وفحص الجودة';
  @override String get warehouseReceivingTabRegistry => 'سجل أذون الإضافة المخزنية';
  @override String get warehouseReceivingTabNewEntry => 'إنشاء إذن استلام وفحص مخزني';
  @override String get warehouseReceivingRefreshTooltip => 'تحديث البيانات';
  @override String get warehouseReceivingNewGrnBtn => 'تسجيل وصول شاحنة واستلام محضر جديد';
  @override String get warehouseReceivingSearchHint => 'بحث برقم الإذن، الشاحنة، السائق...';
  @override String get warehouseReceivingStatusAll => 'جميع الحالات';
  @override String get warehouseReceivingStatusDraft => 'مسودة مؤقتة (بانتظار العد)';
  @override String get warehouseReceivingStatusGoodsReceived => 'تم الاستلام النهائي بالمخزن';
  @override String get warehouseReceivingStatusDiscrepancy => 'مُثبت به عجز/تلف جمركي';
  @override String get warehouseReceivingEmptyRecords => 'لا توجد سجلات استلام بمخازن الشركة حالياً.';
  @override String get warehouseReceivingTruckAndDriver => 'الشاحنة والسائق';
  @override String get warehouseReceivingArrivalDatetime => 'تاريخ ووقت الوصول';
  @override String get warehouseReceivingInspector => 'مسئول الاستلام والجودة';
  @override String get warehouseReceivingDiscrepancyStatus => 'حالة الفروق';
  @override String get warehouseReceivingMetricInvoiced => 'الفاتورة';
  @override String get warehouseReceivingMetricAccepted => 'المقبول';
  @override String get warehouseReceivingMetricShortage => 'العجز';
  @override String get warehouseReceivingMetricDamaged => 'التلف';
  @override String get warehouseReceivingConfirmFinalReceiptBtn => 'تأكيد الاستلام النهائي للمخزن';
  @override String get warehouseReceivingRecordDiscrepancyBtn => 'إثبات عجز / تلف';
  @override String warehouseReceivingPrintGrnSnack(String grn, String wh) => 'طباعة محضر استلام البضاعة: $grn ($wh)';
  @override String get warehouseReceivingDeleteTitle => 'حذف محضر الاستلام';
  @override String get warehouseReceivingDeleteConfirmMessage => 'هل أنت متأكد من نقل محضر الاستلام للمحذوفات؟';
  @override String get warehouseReceivingViewTooltip => 'عرض محضر الاستلام';
  @override String get warehouseReceivingEditTooltip => 'تعديل محضر الاستلام';
  @override String get warehouseReceivingPrintTooltip => 'طباعة محضر الاستلام';
  @override String get warehouseReceivingDeleteTooltip => 'حذف محضر الاستلام (حذف منطقي)';
  @override String get warehouseReceivingSealIntact => 'الرصاص أصل وسليم';
  @override String get warehouseReceivingSealBroken => 'الرصاص تالف/مكسور';
  @override String get warehouseReceivingConfirmReceiptTitle => 'تأكيد الاستلام النهائي للمخزن';
  @override String warehouseReceivingConfirmReceiptMessage(String grn) => 'هل تريد تأكيد الاستلام النهائي للشحنة رقم [$grn] بالمخزن؟\n\n⚠️ هذا الإجراء سيقوم بتثبيت الكميات الفعلية وإغلاق المحضر وخصم رصيد الشحنة من تقرير البضاعة في الطريق.';
  @override String get warehouseReceivingConfirmReceiptBtn => 'نعم، تأكيد الاستلام النهائي';
  @override String warehouseReceivingConfirmReceiptSuccess(String grn) => 'تم تأكيد الاستلام النهائي لـ $grn وخصم رصيد البضاعة بالطريق بنجاح';
  @override String warehouseReceivingConfirmReceiptError(String error) => 'خطأ أثناء تأكيد الاستلام: $error';
  @override String get warehouseReceivingNewDialogTitle => 'تسجيل محضر استلام شحنة جديدة بالمخزن';
  @override String get warehouseReceivingEditDialogTitle => 'تعديل بيانات المحضر وتأكيد الاستلام';
  @override String get warehouseReceivingDispatchAlertTitle => 'تنبيه إداري عاجل:';
  @override String get warehouseReceivingDispatchAlertDesc => 'يجب إرسال أوراق الشحنة المعتمدة (قائمة التعبئة والفاتورة التجارية) فوراً إلى مسؤولي المخزن لمطابقة البضائع عند وصول الشاحنة.';
  @override String get warehouseReceivingDispatchSentBtn => 'تم الإرسال للمخزن';
  @override String get warehouseReceivingDispatchSendBtn => 'إرسال إشعار للمخزن وتوليد مهمة';
  @override String get warehouseReceivingDispatchSuccessSnack => 'تم إرسال إشعار المستندات وتوليد مهمة ذكية في لوحة العمليات لمسؤولي المخزن بنجاح';
  @override String get warehouseReceivingImportFileLabel => 'ملف الشحنة الاستيرادية *';
  @override String get warehouseReceivingSelectFileValidator => 'يرجى اختيار ملف الشحنة';
  @override String get warehouseReceivingWarehouseNameLabel => 'اسم المخزن والفرع *';
  @override String get warehouseReceivingWarehouseNameValidator => 'يرجى إدخال اسم المخزن';
  @override String get warehouseReceivingTruckPlateLabel => 'رقم الشاحنة / السيارة';
  @override String get warehouseReceivingDriverNameLabel => 'اسم السائق';
  @override String get warehouseReceivingSealNumberLabel => 'رقم السيل / الرصاص الأمني';
  @override String get warehouseReceivingSealIntactSwitch => 'سلامة السيل';
  @override String get warehouseReceivingMultiPoHeader => 'بيانات جرد واختبار كميات الأصناف تفصيلياً بكل أمر شراء:';
  @override String get warehouseReceivingAddItemBtn => 'إضافة صنف';
  @override String warehouseReceivingPoLabel(String po) => 'أمر الشراء: $po';
  @override String get warehouseReceivingItemNameLabel => 'اسم وبيان الصنف';
  @override String get warehouseReceivingInvoicedQtyLabel => 'العدد بالفاتورة';
  @override String get warehouseReceivingAcceptedQtyLabel => 'المستلم الفعلي';
  @override String get warehouseReceivingShortageQtyLabel => 'العجز';
  @override String get warehouseReceivingDamagedQtyLabel => 'التلف';
  @override String get warehouseReceivingSamplesQtyLabel => 'عينات مسحوبة';
  @override String get warehouseReceivingSaveDraftBtn => 'حفظ مؤقت (مسودة بانتظار العد)';
  @override String get warehouseReceivingSaveFinalBtn => 'تأكيد الاستلام النهائي للمخزن';
  @override String get warehouseReceivingDraftSuccessSnack => 'تم حفظ المحضر كمسودة مؤقتة بانتظار العد الفعلي للمخزن';
  @override String get warehouseReceivingFinalSuccessSnack => 'تم تأكيد الاستلام النهائي للمخزن وخصم رصيد البضاعة بالطريق بنجاح';
  @override String warehouseReceivingDiscrepancyDialogTitle(String grn) => 'إثبات عجز / تلف رسمي لمحضر: $grn';
  @override String get warehouseReceivingDiscrepancyTypeLabel => 'نوع التباين والعجز *';
  @override String get warehouseReceivingDiscrepancyTypeShortageAndDamage => 'عجز وتلف كلي';
  @override String get warehouseReceivingDiscrepancyTypeShortageOnly => 'عجز طرود فقط';
  @override String get warehouseReceivingDiscrepancyTypeDamageOnly => 'تلف وكسر بضائع فقط';
  @override String get warehouseReceivingDiscrepancyTypeBrokenSeal => 'كسر سيل وتباين مشمول';
  @override String get warehouseReceivingDiscrepancyNotesLabel => 'ملاحظات وتفاصيل الفحص *';
  @override String get warehouseReceivingDiscrepancyNotesValidator => 'يرجى كتابة الملاحظات';
  @override String get warehouseReceivingQuarantineSwitch => 'عزل البضاعة في منطقة الحجر';
  @override String get warehouseReceivingInsuranceClaimSwitch => 'رفع مطالبة تعويض تأمين بحري';
  @override String get warehouseReceivingClaimRefLabel => 'رقم مرجع المطالبة التأمينية';
  @override String get warehouseReceivingCertifyDiscrepancyBtn => 'اعتماد محضر العجز والتلف';
  @override String get warehouseReceivingDiscrepancySuccessSnack => 'تم توثيق محضر العجز والتلف بنجاح';

  // ==========================================
  // Screen 29: Landed Cost Settlement (FinancialSettlementScreen & OdooJournalEntryDialog)
  // ==========================================
  @override String get financialSettlementStageTitle => 'التسوية المالية وتكلفة البند النهائي';
  @override String get financialSettlementTabRegistry => 'سجل تسويات تكلفة الوصول';
  @override String get financialSettlementTabNewEntry => 'احتساب وتسوية تكلفة شحنة جديدة';
  @override String get financialSettlementRefreshTooltip => 'تحديث البيانات';
  @override String get financialSettlementNewSettlementBtn => 'تسجيل فواتير مصاريف واحتساب تكلفة الوصول';
  @override String get financialSettlementSearchHint => 'بحث برقم التسوية، اسم المحاسب...';
  @override String get financialSettlementFetchError => 'خطأ في جلب بيانات التسوية المالية:';
  @override String get financialSettlementEmptyRecords => 'لا توجد تسويات مالية لتكلفة الوصول مسجلة حالياً.';
  @override String financialSettlementAccountantLabel(String accountant) => 'المحاسب: $accountant';
  @override String get financialSettlementStatusDraft => 'مسودة مؤقتة';
  @override String get financialSettlementStatusCalculated => 'مُحتسب وموزع';
  @override String get financialSettlementStatusApproved => 'معتمد نهائياً';
  @override String get financialSettlementMetricFobTotal => 'إجمالي الفاتورة (FOB)';
  @override String get financialSettlementMetricExpensesTotal => 'إجمالي المصاريف والنولون';
  @override String get financialSettlementMetricLandedCostTotal => 'تكلفة الوصول الشاملة';
  @override String get financialSettlementMetricMarkupFactor => 'معامل زيادة التكلفة';
  @override String get financialSettlementExpensesSectionHeader => '1️⃣ فواتير ومصاريف الاستيراد المسجلة:';
  @override String get financialSettlementColInvoiceNo => 'رقم الفاتورة';
  @override String get financialSettlementColCategory => 'نوع البند / الفئة';
  @override String get financialSettlementColProvider => 'المورد / مزود الخدمة';
  @override String get financialSettlementColAmountFx => 'المبلغ بالعملة الأجنبية';
  @override String get financialSettlementColExchangeRate => 'سعر الصرف';
  @override String get financialSettlementColAmountEgp => 'المبلغ بالجنيه';
  @override String get financialSettlementColAllocationRule => 'قاعدة التوزيع';
  @override String get financialSettlementCategoryFreight => 'نولون شحن';
  @override String get financialSettlementCategoryCustomsDuty => 'ضرائب وجمارك';
  @override String get financialSettlementCategoryBrokerage => 'أتعاب تخليص';
  @override String get financialSettlementCategoryLocalTransport => 'نقل بري وداخلي';
  @override String get financialSettlementCategoryStorage => 'أرضيات وتخزين';
  @override String get financialSettlementRuleVolumeBased => 'حسب الحجم';
  @override String get financialSettlementRuleValueBased => 'حسب القيمة';
  @override String get financialSettlementRuleWeightBased => 'حسب الوزن الإجمالي';
  @override String get financialSettlementRuleEqual => 'بالتساوي';
  @override String get financialSettlementItemsSectionHeader => '2️⃣ جدول تكلفة الوصول للوحدة وتوزيع المصاريف:';
  @override String get financialSettlementColItemCode => 'كود الصنف';
  @override String get financialSettlementColItemName => 'اسم الصنف';
  @override String get financialSettlementColQty => 'الكمية';
  @override String get financialSettlementColFobUnit => 'سعر FOB للوحدة';
  @override String get financialSettlementColAllocatedFreight => 'نولون مخصص';
  @override String get financialSettlementColAllocatedCustoms => 'جمارك مخصصة';
  @override String get financialSettlementColAllocatedClearance => 'تخليص مخصص';
  @override String get financialSettlementColAllocatedTransport => 'نقل مخصص';
  @override String get financialSettlementColUnitLandedCost => 'تكلفة الوصول للوحدة';
  @override String get financialSettlementColMarkupFactor => 'معامل الزيادة';
  @override String get financialSettlementExportOdooBtn => '📒 تصدير قيد اليومية لـ Odoo / ERP';
  @override String get financialSettlementRecalculateBtn => 'إعادة احتساب التكاليف';
  @override String financialSettlementRecalculateSuccessSnack(String code) => 'تمت إعادة توزيع التكاليف لسجل التسوية: $code بنجاح';
  @override String financialSettlementPrintSnack(String code, String total) => 'طباعة كشف ومطابقة تكلفة الوصول: $code (الإجمالي: $total ج.م)';
  @override String get financialSettlementViewTooltip => 'عرض تفاصيل التسوية';
  @override String get financialSettlementEditTooltip => 'تعديل وإعادة احتساب';
  @override String get financialSettlementPrintTooltip => 'طباعة كشف تكلفة الوصول';
  @override String get financialSettlementDeleteTooltip => 'حذف سجل التسوية';
  @override String get financialSettlementDeleteTitle => 'حذف سجل التسوية';
  @override String get financialSettlementDeleteMessage => 'هل أنت متأكد من نقل سجل التسوية المالية للمحذوفات؟';
  @override String get financialSettlementDialogTitle => 'تسجيل مصاريف وبنود شحنة لاحتساب تكلفة الوصول';
  @override String get financialSettlementImportFileLabel => 'ملف الشحنة الاستيرادية *';
  @override String get financialSettlementImportFileSearchHint => 'ابحث عن ملف الشحنة بالرقم أو اسم الشركة...';
  @override String get financialSettlementImportFileValidator => 'يرجى اختيار ملف الشحنة';
  @override String get financialSettlementExpenseSectionHeader => 'بيانات فاتورة المصروف والخدمات اللوجستية:';
  @override String get financialSettlementInvoiceNoLabel => 'رقم الفاتورة *';
  @override String get financialSettlementCategoryLabel => 'فئة المصروف *';
  @override String get financialSettlementCategorySearchHint => 'ابحث عن فئة المصروف...';
  @override String get financialSettlementProviderNameLabel => 'اسم مورد الخدمة *';
  @override String get financialSettlementAmountFxLabel => 'المبلغ بالعملة الأجنبية';
  @override String get financialSettlementExchangeRateLabel => 'سعر الصرف';
  @override String get financialSettlementAllocationRuleLabel => 'قاعدة توزيع المصروف على الأصناف *';
  @override String get financialSettlementAllocationRuleSearchHint => 'ابحث عن قاعدة التوزيع...';
  @override String get financialSettlementItemSectionHeader => 'بيانات صنف الشحنة والاستيراد:';
  @override String get financialSettlementItemCodeLabel => 'كود الصنف';
  @override String get financialSettlementItemNameLabel => 'اسم الصنف';
  @override String get financialSettlementQtyReceivedLabel => 'الكمية المستلمة';
  @override String get financialSettlementFobUnitPriceLabel => 'سعر الفاتورة للوحدة (FOB بالجنيه)';
  @override String get financialSettlementLiveReloadBtn => 'إعادة تحميل حية';
  @override String get financialSettlementResetFormBtn => 'تفريغ وبدء تسجيل جديد';
  @override String get financialSettlementSaveAndAllocateBtn => 'حفظ وتوزيع بنود المصروف';
  @override String financialSettlementSaveError(String error) => 'خطأ أثناء حفظ وحساب التسوية: $error';
  @override String get odooJournalLoading => 'جارٍ إعداد وتوليد قيد اليومية المزدوج المتوازن لـ Odoo / ERP...';
  @override String odooJournalFetchError(String error) => 'خطأ أثناء جلب القيد: $error';
  @override String odooJournalTitle(String code) => 'قيد اليومية المحاسبي المزدوج وتصدير Odoo ERP ($code)';
  @override String odooJournalSubtitle(String fileCode, String ref) => 'ملف الاستيراد: $fileCode | المرجع: $ref';
  @override String get odooJournalBalanced => '🟢 قيد متوازن 100% (المدين = الدائن)';
  @override String odooJournalUnbalanced(String diff) => '🔴 غير متوازن (فارق: $diff ج.م)';
  @override String get odooJournalMetaImporter => 'الشركة المستوردة';
  @override String get odooJournalMetaSupplier => 'المورد الأجنبي';
  @override String get odooJournalMetaProject => 'المشروع / الحساب التحليلي';
  @override String get odooJournalMetaDate => 'تاريخ القيد';
  @override String get odooJournalMetaTotalDebitCredit => 'إجمالي المدين / الدائن';
  @override String get odooJournalLinesSectionHeader => 'تفاصيل بنود القيد المحاسبي المزدوج:';
  @override String get odooJournalColAccountCode => 'رقم الحساب';
  @override String get odooJournalColAccountName => 'اسم الحساب الدفتري';
  @override String get odooJournalColPartner => 'الطرف / الشريك';
  @override String get odooJournalColLabel => 'بيان وشرح القيد';
  @override String get odooJournalColDebit => 'مدين (ج.م)';
  @override String get odooJournalColCredit => 'دائن (ج.م)';
  @override String get odooJournalColForeignCurrency => 'العملة الأجنبية';
  @override String get odooJournalColCostCategory => 'تصنيف التكلفة';
  @override String get odooJournalExportCsvBtn => '📥 تحميل شيت Odoo CSV الجاهز للاستيراد المباشر';
  @override String get odooJournalExportExcelBtn => '📊 تحميل كشف Excel المحاسبي التفصيلي';
  @override String odooJournalExportingSnack(String filename, String directUrl) => 'جارٍ التصدير: $filename\nالرابط المباشر: $directUrl';

  // ---------------------------------------------------------------------------
  // Screen 30: File Closure & Archival
  // ---------------------------------------------------------------------------
  @override String get fileClosureStageTitle => 'إغلاق الملف والأرشفة التاريخية';
  @override String get fileClosureTabArchivedRegistry => 'سجل الملفات المغلقة والمؤرشفة';
  @override String get fileClosureTabCloseFile => 'إغلاق وأرشفة ملف شحنة';
  @override String get fileClosureRefreshTooltip => 'تحديث البيانات';
  @override String get fileClosureNewCertificateBtn => 'إصدار شهادة إغلاق وأرشفة شحنة نهائياً';
  @override String get fileClosureSearchHint => 'بحث بكود الشهادة، المراجع...';
  @override String get fileClosureFetchError => 'خطأ في جلب بيانات أرشيف الشحنات:';
  @override String get fileClosureEmptyRecords => 'لا توجد شحنات مغلقة ومؤرشفة نهائياً حالياً.';
  @override String fileClosureClosedFilesBannerTitle(int count) => 'سجل الشحنات المغلقة مسبقاً ($count شحنة مغلقة بالأرشيف):';
  @override String get fileClosureClosedBadge => 'مغلق';
  @override String fileClosureStopReason(String reason) => 'سبب الإيقاف: $reason';
  @override String get fileClosureReopenBtn => 'إعادة فتح وتنشيط الشحنة';
  @override String fileClosureFileRefLabel(int id) => 'ملف الشحنة المرجعي: #$id';
  @override String fileClosureVaultLabel(String location) => 'مستودع الأرشيف: $location';
  @override String get fileClosureStatusBadgeClosed => 'مغلق ومؤرشف بالكامل (100%)';
  @override String get fileClosureChecklistHeader => 'شروط الإغلاق المكتملة:';
  @override String get fileClosureChecklistDocsOriginals => 'المستندات الأصلية والتبادل الرقمي';
  @override String get fileClosureChecklistCustomsCleared => 'الإفراج الجمركي ونموذج 46';
  @override String get fileClosureChecklistWarehouseGrn => 'فحص واستلام المخازن';
  @override String get fileClosureChecklistLandedCost => 'التسوية المالية وتكلفة الوصول';
  @override String get fileClosureChecklistTasksClosed => 'إغلاق المهام التشغيلية';
  @override String fileClosureArchivalNotes(String notes) => 'ملاحظات الأرشيف: $notes';
  @override String fileClosureAuditorLabel(String auditor) => 'المراجع المسؤول: $auditor';
  @override String fileClosureCertificateDialogTitle(String code) => 'شهادة الإغلاق والأرشفة: $code';
  @override String fileClosureCertFileNo(int id) => 'رقم ملف الشحنة: #$id';
  @override String fileClosureCertLocation(String loc) => 'موقع الأرشيف: $loc';
  @override String fileClosureCertAuditor(String name) => 'المراجع: $name';
  @override String fileClosureCertClosedDate(String date) => 'تاريخ الإغلاق: $date';
  @override String fileClosureCertNotes(String notes) => 'الملاحظات: $notes';
  @override String fileClosureEditSnack(String code) => 'تعديل بيانات وأرشفة الملف: $code';
  @override String fileClosurePrintSnack(String code, int fileId) => 'طباعة شهادة الإغلاق الرسمي والأرشفة النهائية: $code (ملف #$fileId)';
  @override String get fileClosureDeleteTitle => 'حذف سجل الأرشفة';
  @override String get fileClosureDeleteMessage => 'هل أنت متأكد من نقل سجل الإغلاق للمحذوفات؟';
  @override String get fileClosureViewTooltip => 'عرض شهادة الإغلاق';
  @override String get fileClosureEditTooltip => 'تعديل الأرشفة';
  @override String get fileClosurePrintTooltip => 'طباعة شهادة الإغلاق والأرشفة';
  @override String get fileClosureDeleteTooltip => 'حذف سجل الإغلاق (حذف منطقي)';
  @override String get fileClosureDialogTitle => 'إصدار شهادة إغلاق وأرشفة شحنة نهائياً';
  @override String get fileClosureSelectImportFile => 'اختر ملف الشحنة للإغلاق النهائي *';
  @override String get fileClosureSelectImportFileHint => 'ابحث عن ملف الشحنة بالرقم أو اسم الشركة...';
  @override String get fileClosureSelectImportFileValidator => 'يرجى اختيار ملف الشحنة';
  @override String get fileClosureMandatoryChecklistHeader => 'قائمة التحقق الإلزامية للإغلاق:';
  @override String get fileClosureCheck1Docs => '1️⃣ استلام المستندات الأصلية والتبادل الإلكتروني';
  @override String get fileClosureCheck2Customs => '2️⃣ إتمام الإفراج الجمركي وسداد الضرائب والإيقاف الجمركي (إقرار 46)';
  @override String get fileClosureCheck3Warehouse => '3️⃣ استلام البضائع بالمخازن وإصدار إذن الإضافة';
  @override String get fileClosureCheck4LandedCost => '4️⃣ التسوية المالية وتوزيع المصاريف وحساب تكلفة الوصول';
  @override String get fileClosureCheck5Tasks => '5️⃣ إغلاق كافة المهام والتنبيهات المرتبطة بالشحنة';
  @override String get fileClosureAuditorNameLabel => 'اسم المراجع المسؤول *';
  @override String get fileClosureAuditorNameValidator => 'يلزم إدخال اسم المراجع';
  @override String get fileClosureVaultLocationLabel => 'مستودع الأرشيف الرقمي *';
  @override String get fileClosureArchivalNotesLabel => 'ملاحظات الأرشفة والتدقيق';
  @override String get fileClosureLiveReloadBtn => 'إعادة تحميل حية 🔄';
  @override String get fileClosureResetFormBtn => 'تفريغ وبدء تسجيل جديد 🔄';
  @override String get fileClosureCertifySubmitBtn => 'اعتماد الإغلاق والأرشفة النهائية ✅';
  @override String get fileClosureChecklistIncompleteWarning => 'تنبيه: يلزم اكتمال جميع البنود الـ 5 في قائمة التحقق لإغلاق الملف نهائياً.';
  @override String fileClosureSaveError(String error) => 'خطأ أثناء إغلاق وأرشفة الملف: $error';

  // Reopen Shipment Dialog
  @override String reopenShipmentDialogTitle(String code) => 'إعادة فتح وتنشيط الشحنة ($code)';
  @override String reopenShipmentRestoredPhase(String phase) => 'المرحلة التي ستعود إليها الشحنة: $phase';
  @override String get reopenShipmentNotice => 'ملاحظة: سيتم إلغاء حالة الإغلاق وتغيير حالة الشحنة إلى نشطة وإعادتها بنفس البيانات والتفاصيل إلى المرحلة التشغيلية التي تم إيقافها عندها.';
  @override String get reopenShipmentReasonLabel => '* سبب إعادة فتح وتنشيط الشحنة والملاحظات التفصيلية';
  @override String get reopenShipmentReasonHint => 'اكتب هنا سبب استئناف وإعادة فتح الشحنة المغلقة مسبقاً...';
  @override String get reopenShipmentReasonValidatorEmpty => 'يرجى إدخال سبب إعادة فتح الشحنة.';
  @override String get reopenShipmentReasonValidatorMin => 'يجب ألا يقل سبب إعادة الفتح عن 3 حروف.';
  @override String reopenShipmentSuccessSnack(String code, String phase) => 'تم إعادة فتح وتنشيط الشحنة ($code) وإعادتها بنجاح لمرحلة ($phase)!';
  @override String reopenShipmentErrorSnack(String err) => 'حدث خطأ أثناء إعادة فتح الشحنة: $err';
  @override String get reopenShipmentConfirmBtn => 'تأكيد إعادة الفتح والتنشيط';

  // ---------------------------------------------------------------------------
  // Screen 31: Projects & Cost Centers
  // ---------------------------------------------------------------------------
  @override String get projectsScreenTitle => 'مشاريع الاستيراد ومراكز التكلفة';
  @override String get projectsScreenSubtitle => 'المرجع الأساسي لعمليات الاستيراد متعددة الشحنات ومتعددة الشركات';
  @override String get createNewProjectBtn => 'إنشاء مشروع جديد';
  @override String get projectsSearchHint => 'بحث بكود المشروع، الاسم، المسؤول...';
  @override String projectsFetchError(String error) => 'تعذر الاتصال بالسيرفر وجلب المشاريع:\n$error';
  @override String get noProjectsFound => 'لم يتم العثور على مشاريع استيراد.';
  @override String get projectCodeCol => 'كود المشروع';
  @override String get projectNameAndOwnerCol => 'اسم المشروع والمسؤول';
  @override String get companyAndSupplierCol => 'الشركة المستوردة والمورد';
  @override String get typeAndCategoryCol => 'النوع والتصنيف';
  @override String get budgetUsdCol => 'الميزانية (USD)';
  @override String get capabilitiesCol => 'المحددات والمزايا';
  @override String projectOwnerLabel(String owner) => 'المسؤول: $owner';
  @override String projectCompanyFallback(int id) => 'الشركة #$id';
  @override String projectSupplierFallback(int id) => 'المورد #$id';
  @override String projectSupplierLabel(String supplier) => 'المورد: $supplier';
  @override String get capMultiShipment => 'متعدد الشحنات';
  @override String get capMultiCompany => 'متعدد الشركات';
  @override String projectPrintSnack(String name, String code) => 'طباعة بيانات المشروع ومراكز التكلفة: $name ($code)';
  @override String get confirmActionTitle => 'تأكيد الإجراء';
  @override String confirmDeactivateProject(String name) => 'هل أنت متأكد من رغبتك في إيقاف تفعيل المشروع ($name)؟';
  @override String confirmActivateProject(String name) => 'هل أنت متأكد من إعادة تفعيل المشروع ($name)؟';
  @override String get deactivateBtn => 'إيقاف التفعيل';
  @override String get activateBtn => 'تفعيل';
  @override String get deactivateProjectTooltip => 'إيقاف تفعيل المشروع';
  @override String get activateProjectTooltip => 'إعادة تفعيل المشروع';
  @override String get createProjectDialogTitle => 'إنشاء مشروع استيراد جديد';
  @override String editProjectDialogTitle(String code) => 'تعديل المشروع ($code)';
  @override String get projectPrerequisitesMissing => 'يرجى التأكد من تهيئة الشركات المستوردة، الموردين، والشروط التجارية أولاً.';
  @override String get projectNameLabel => 'اسم المشروع *';
  @override String get projectNameHint => 'مثال: مشروع محطة الطاقة الشمسية بالسخنة - المرحلة الأولى';
  @override String get projectOwnerLabelField => 'مدير / مسؤول المشروع *';
  @override String get projectOwnerHint => 'مثال: م. حسن محمود';
  @override String get importingCompaniesFieldLabel => 'الشركات المستوردة للمشروع *';
  @override String get primarySupplierLabel => 'المورد الرئيسي *';
  @override String get defaultIncotermLabel => 'شرط الشحن الافتراضي (Incoterm) *';
  @override String get importTypeLabel => 'نوع الاستيراد *';
  @override String get priorityLabel => 'مستوى الأولوية *';
  @override String get projectStatusLabel => 'حالة المشروع *';
  @override String get allowedShipmentCategoriesLabel => 'أنواع الشحنات المتاحة للمشروع *';
  @override String get estTotalBudgetUsdLabel => 'الميزانية التقديرية (USD)';
  @override String get estTotalBudgetUsdHint => 'مثال: 500000';
  @override String get allowMultiShipmentTitle => 'السماح بالشحن على دفعات (Multi-Shipment)';
  @override String get allowMultiShipmentSubtitle => 'يسمح بتوزيع توريد المشروع على عدة شحنات ورسائل جمركية متتابعة';
  @override String get allowMultiCompanyTitle => 'السماح بتعدد الكيانات والشركات (Multi-Company)';
  @override String get allowMultiCompanySubtitle => 'يسمح بالتعامل مع عدة مخلصين وخطوط ملاحية وموردين فرعيين للمشروع';
  @override String get projectNotesLabel => 'ملاحظات ووصف المشروع';
  @override String get selectAtLeastOneCompanyError => 'يرجى اختيار شركة مستوردة واحدة على الأقل.';
  @override String get selectAtLeastOneCategoryError => 'يرجى اختيار نوع شحن واحد على الأقل.';
  @override String get createProjectSubmitBtn => 'إنشاء المشروع';
  @override String get saveChangesSubmitBtn => 'حفظ التعديلات';
  @override String get statusOnHold => 'قيد الانتظار';
  @override String get priorityUrgent => 'عاجل / حرج';
  @override String get importTypeDirectCommercial => 'تجاري مباشر';
  @override String get importTypeFreeZone => 'منطقة حرة';
  @override String get importTypeTemporaryRelease => 'سماح مؤقت';
  @override String get importTypeDrawback => 'دروباك (استرداد جمركي)';
  @override String get importTypeProjectEquipment => 'معدات مشروعات';
  @override String get categoryFclContainer => 'حاوية كاملة (FCL)';
  @override String get categoryLclBreakbulk => 'شحن مجزأ (LCL)';
  @override String get categoryAirFreight => 'شحن جوي';
  @override String get categoryBulkCargo => 'بضائع صب (Bulk)';
  @override String get categoryMultimodal => 'شحن متعدد الوسائط';

  // ── Screen 32: Egyptian Import Companies ──────────────────────────────────
  @override String get importCompaniesScreenTitle => 'الشركات المستوردة المصرية';
  @override String get importCompaniesScreenSubtitle => 'إدارة بيانات المستوردين والتراخيص الرسمية وتواريخ الصلاحية';
  @override String get includeDeactivatedLabel => 'عرض الشركات المتوقفة:';
  @override String get addImporterCompanyBtn => 'إضافة شركة مستوردة';
  @override String get searchImporterHint => 'بحث باسم المستورد، رقم القيد، أو رقم التسجيل الضريبي...';
  @override String importersFetchError(String error) => 'تعذر الاتصال بالسيرفر وجلب الشركات المستوردة:\n$error';
  @override String get retryConnectionBtn => 'إعادة المحاولة';
  @override String get noImportCompaniesFound => 'لم يتم العثور على شركات مستوردة.';
  @override String get statusActive => 'نشطة';
  @override String get statusInactive => 'متوقفة';
  @override String importerRowMeta(String importerId, String vatId, String regNumber) => 'بطاقة استيرادية: $importerId | ضريبي: $vatId | سجل: $regNumber';
  @override String get badgeImportId => 'البطاقة الاستيرادية';
  @override String get badgeVatExpiry => 'التسجيل الضريبي';
  @override String get badgeComReg => 'السجل التجاري';
  @override String get expiryExpired => 'منتهي الصلاحية';
  @override String expiryDaysLeft(int days) => 'متبقي $days يوم';
  @override String expiryValidDays(int days) => 'سارٍ ($days يوم)';
  @override String confirmDeactivateCompany(String name) => 'هل أنت متأكد من رغبتك في إيقاف تفعيل الشركة ($name)؟';
  @override String confirmActivateCompany(String name) => 'هل أنت متأكد من إعادة تفعيل الشركة ($name)؟';
  @override String get deactivateCompanyTooltip => 'إيقاف تفعيل الشركة';
  @override String get activateCompanyTooltip => 'إعادة تفعيل الشركة';
  @override String get editImporterCompanyTitle => 'تعديل بيانات الشركة المستوردة';
  @override String get addImporterCompanyTitle => 'إضافة شركة استيراد مصرية جديدة';
  @override String get closeDialogTooltip => 'إغلاق النافذة';
  @override String get companyNameLabel => 'اسم الشركة المستوردة *';
  @override String get companyNameHint => 'مثال: شركة الفراعنة للاستيراد والتصدير';
  @override String get addressLabel => 'العنوان *';
  @override String get addressHint => 'مثال: 12 شارع رمسيس، القاهرة';
  @override String get countryLabel => 'الدولة *';
  @override String get importerCardIdLabel => 'رقم البطاقة الاستيرادية (9 أرقام) *';
  @override String get importerCardIdHint => 'مثال: 528153439';
  @override String get importerCardExpiryLabel => 'تاريخ انتهاء البطاقة الاستيرادية *';
  @override String get vatRegIdLabel => 'رقم التسجيل الضريبي (9 أرقام) *';
  @override String get vatRegIdHint => 'مثال: 528153439';
  @override String get vatRegExpiryLabel => 'تاريخ انتهاء التسجيل الضريبي *';
  @override String get commercialRegNumLabel => 'رقم السجل التجاري (15 رقم) *';
  @override String get commercialRegNumHint => 'مثال: 100200000070828';
  @override String get commercialRegExpiryLabel => 'تاريخ انتهاء السجل التجاري *';
  @override String get phoneNumberLabel => 'رقم الهاتف';
  @override String get phoneNumberHint => 'مثال: 01000000000';
  @override String get cancelAndCloseBtn => 'إلغاء وإغلاق ✕';
  @override String get updateCompanyBtn => 'حفظ التعديلات';
  @override String get saveCompanyBtn => 'حفظ بيانات الشركة';
  @override String get diffCompanyName => 'اسم الشركة المستوردة';
  @override String get diffImporterCardId => 'رقم البطاقة الاستيرادية';
  @override String get diffImporterCardExpiry => 'تاريخ انتهاء البطاقة الاستيرادية';
  @override String get diffVatId => 'رقم التسجيل الضريبي';
  @override String get diffCommercialReg => 'رقم السجل التجاري';
  @override String get diffAddress => 'العنوان';
  @override String get diffPhone => 'رقم الهاتف';
  @override String get diffConfirmCompanyTitle => 'مراجعة وتأكيد تعديلات الشركة المستوردة';
  @override String get importerProfileSubtitle => 'بطاقة بيانات الشركة المستوردة والتراخيص الرقابية';
  @override String get officialRegistrationsHeader => 'بيانات القيد والتراخيص الرسمية';
  @override String get importerCardIdRowLabel => 'رقم البطاقة الاستيرادية';
  @override String get vatTaxIdRowLabel => 'رقم التسجيل الضريبي';
  @override String get commercialRegRowLabel => 'رقم السجل التجاري';
  @override String expiryEndingSoon(int days) => 'ينتهي قريباً ($days يوم)';
  @override String expiryValidDaysRemaining(int days) => 'سارٍ ($days يوم)';
  @override String expiryDateLabel(String date) => 'الانتهاء: $date';
  @override String copiedToClipboard(String value) => 'تم نسخ $value إلى الحافظة';
  @override String get locationAndContactHeader => 'بيانات الموقع والتواصل';
  @override String get countryRowLabel => 'الدولة';
  @override String get egyptCountryFallback => 'جمهورية مصر العربية';
  @override String get addressRowLabel => 'العنوان';
  @override String get phoneRowLabel => 'الهاتف';
  @override String get emailRowLabel => 'البريد الإلكتروني';
  @override String get administrativeNotesHeader => 'ملاحظات إدارية ورقمية';
  @override String get printSavePdfBtn => 'طباعة / حفظ PDF 🖨️';
  @override String get downloadExcelBtn => 'تنزيل EXCEL 📊';
  @override String excelSavedSuccess(String path) => 'تم حفظ ملف الإكسل بنجاح: $path';
  @override String get whatsappShareBtn => 'نسخة واتس 💬';
  @override String get emailShareBtn => 'إيميل ✉️';
  @override String get whatsappPreviewTitle => 'نص مشاركة الواتساب';
  @override String get copyWhatsappTextBtn => 'نسخ نص الواتس 📋';
  @override String get whatsappCopiedSuccess => 'تم نسخ نص الواتساب للحافظة بنجاح!';
  @override String get emailPreviewTitle => 'نموذج البريد الإلكتروني';
  @override String emailSubjectPrefix(String subject) => 'الموضوع: $subject';
  @override String get copyEmailTextBtn => 'نسخ نص وموضوع الإيميل 📋';
  @override String get emailCopiedSuccess => 'تم نسخ نص وموضوع الإيميل للحافظة بنجاح!';

  // ── Screen 33: Foreign Suppliers ──
  @override String get suppliersScreenTitle => 'دليل الموردين والمصدرين الأجانب';
  @override String get suppliersScreenSubtitle => 'إدارة بيانات المصدرين الأجانب، أرقام القيد بنافذة، ومعرفات كارجو إكس والدول المصدرة';
  @override String get aiExtractorAndCodingBtn => '⚡ الاستخراج والترميز الذكي';
  @override String get addForeignSupplierBtn => 'إضافة مورد أجنبي جديد';
  @override String get searchSuppliersHint => 'بحث باسم المورد، الكود، معرف كارجو إكس، رقم القيد، أو الدولة...';
  @override String get showInactiveSuppliersLabel => 'عرض الموردين المتوقفين:';
  @override String suppliersFetchError(String error) => 'تعذر الاتصال بالسيرفر وجلب الموردين الأجانب:\n$error';
  @override String get noSuppliersFound => 'لم يتم العثور على موردين أجانب.';
  @override String supplierRowMeta(String exporterId, String? cargoxId, String address, String? brands) {
    final cx = cargoxId != null && cargoxId.isNotEmpty ? ' | كارجو إكس: $cargoxId' : '';
    final br = brands != null && brands.isNotEmpty ? ' | علامات: $brands' : '';
    return 'معرف المصدر: $exporterId$cx | العنوان: $address$br';
  }
  @override String supplierTypeAndReg(String type, String regType) => 'النوع: $type ($regType)';
  @override String confirmDeactivateSupplier(String name) => 'هل أنت متأكد من رغبتك في إيقاف تفعيل المورد ($name)؟';
  @override String confirmActivateSupplier(String name) => 'هل أنت متأكد من إعادة تفعيل المورد ($name)؟';
  @override String get deactivateSupplierTooltip => 'إيقاف تفعيل المورد';
  @override String get activateSupplierTooltip => 'إعادة تفعيل المورد';
  @override String get editSupplierDialogTitle => 'تعديل بيانات المورد الأجنبي';
  @override String get addSupplierDialogTitle => 'إضافة مورد ومصدّر أجنبي جديد';
  @override String get supplierCompanyNameLabel => 'اسم شركة المورد *';
  @override String get supplierCompanyNameHint => 'مثال: شركة الصناعات العامة المحدودة';
  @override String get supplierTypeLabel => 'نوع المورد *';
  @override String get supplierTypeManufacturer => 'مصنع / جهة إنتاج';
  @override String get supplierTypeTrader => 'مورد أجنبي / شركة تجارية';
  @override String get supplierTypeAgent => 'وكيل معتمد / موزع';
  @override String get supplierTypeExporter => 'مصدّر';
  @override String get supplierRegTypeLabel => 'نوع التسجيل والتوثيق *';
  @override String get regTypeFactory => 'قيد مصنع';
  @override String get regTypeNafezaExporter => 'رقم المصدر الأجنبي (نافذة)';
  @override String get regTypeCompanyReg => 'رقم السجل التجاري للشركة';
  @override String get regTypeVat => 'رقم التسجيل الضريبي للقيمة المضافة';
  @override String get regTypeTax => 'الرقم الضريبي العام';
  @override String get regTypeCommercial => 'السجل التجاري';
  @override String get supplierForeignExporterIdLabel => 'معرف المصدر الأجنبي (نافذة) *';
  @override String get foreignExporterIdHint => 'مثال: رقم القيد بالمصدر الأجنبي';
  @override String get cargoxIdLabel => 'معرف منصة كارجو إكس';
  @override String get cargoxIdHint => 'مثال: معرف الحساب في كارجو إكس';
  @override String get supplierCountryLabel => 'دولة المورد *';
  @override String get supplierCountryHint => 'إيطاليا، الصين، ألمانيا، إلخ';
  @override String get supplierCountryCodeLabel => 'كود الدولة المعتمد *';
  @override String get supplierCountryCodeHint => 'كود الدولة حرفين';
  @override String get supplierAddressLabel => 'العنوان بالكامل *';
  @override String get supplierAddressHint => 'مثال: شارع الصناعة، مبنى 7، المدينة، الدولة';
  @override String get supplierEmailLabel => 'البريد الإلكتروني الرئيسي';
  @override String get supplierEmailHint => 'export@supplier.com';
  @override String get supplierSecondaryEmailLabel => 'بريد إلكتروني إضافي';
  @override String get supplierSecondaryEmailHint => 'sales@supplier.com';
  @override String get supplierPhoneLabel => 'رقم الهاتف الأرضي';
  @override String get supplierPhoneHint => 'رقم الهاتف مع كود الدولة';
  @override String get supplierMobileLabel => 'رقم المحمول';
  @override String get supplierMobileHint => 'رقم المحمول مع كود الدولة';
  @override String get supplierFaxLabel => 'رقم الفاكس';
  @override String get supplierFaxHint => 'رقم الفاكس مع كود الدولة';
  @override String get supplierWebsiteLabel => 'الموقع الإلكتروني';
  @override String get supplierWebsiteHint => 'www.supplier.com';
  @override String get beneficiaryBankDetailsHeader => 'بيانات البنك المستفيد والسويفت:';
  @override String get beneficiaryBankNameLabel => 'اسم البنك المستفيد';
  @override String get beneficiaryBankNameHint => 'مثال: بنك الصين، دويتشه بنك';
  @override String get beneficiarySwiftCodeLabel => 'كود السويفت البنكي';
  @override String get beneficiarySwiftCodeHint => 'كود التحويل السريع للبنك';
  @override String get beneficiaryAccountNumberLabel => 'رقم الحساب البنكي';
  @override String get beneficiaryAccountNumberHint => 'رقم الحساب البنكي للمستفيد';
  @override String get beneficiaryIbanLabel => 'رقم الحساب الدولي (آيبان)';
  @override String get beneficiaryIbanHint => 'رقم الآيبان الدولي للحساب';
  @override String get complianceAndCertsHeader => 'الامتثال والشهادات الرقابية:';
  @override String get isoCertifiedCheck => 'حاصل على شهادة الأيزو المعترف بها';
  @override String get decree43Check => 'مسجل بقرار 43 للهيئة العامة للرقابة على الصادرات والواردات';
  @override String get whiteListCheck => 'مسجل بالقائمة الاستيرادية البيضاء';
  @override String get brandsProductLinesLabel => 'العلامات التجارية وخطوط الإنتاج';
  @override String get brandsProductLinesHint => 'مثال: كلينت، نوفير، بروباور';
  @override String get supplierNotesLabel => 'ملاحظات إضافية عن المورد';
  @override String get supplierNotesHint => 'أي تفاصيل أو اشتراطات خاصة بالتعامل مع المورد...';
  @override String get updateSupplierBtn => 'حفظ تعديلات المورد';
  @override String get saveSupplierBtn => 'حفظ بيانات المورد الأجنبي';
  @override String get diffSupplierCompanyName => 'اسم شركة المورد';
  @override String get diffSupplierType => 'نوع المورد';
  @override String get diffSupplierRegType => 'نوع التسجيل';
  @override String get diffForeignExporterId => 'معرف المصدر الأجنبي (نافذة)';
  @override String get diffCargoXId => 'معرف منصة كارجو إكس';
  @override String get diffSupplierCountry => 'دولة المورد';
  @override String get diffSupplierEmail => 'البريد الإلكتروني';
  @override String get diffSupplierPhone => 'الهاتف';
  @override String get diffConfirmSupplierTitle => 'مراجعة وتأكيد تعديلات المورد الأجنبي';
  @override String get supplierProfileSubtitle => 'بطاقة تعريف المورد الأجنبي والتسجيل الرقابي';
  @override String get nafezaCargoXComplianceHeader => 'بيانات التسجيل في نافذة وكارجو إكس والامتثال';
  @override String get foreignExporterIdFieldLabel => 'معرّف المصدر الأجنبي (نافذة)';
  @override String get cargoxPlatformIdFieldLabel => 'معرّف منصة كارجو إكس';
  @override String get notRegisteredCargoX => 'غير مسجل';
  @override String get supplierTypeFieldLabel => 'نوع المورد';
  @override String get supplierOriginCountryFieldLabel => 'الدولة والمنشأ';
  @override String get complianceCertificatesLabel => 'شهادات الامتثال:';
  @override String get isoCertifiedTag => 'شهادة الأيزو';
  @override String get decree43Tag => 'قرار 43';
  @override String get whiteListTag => 'القائمة البيضاء';
  @override String get bankingSwiftSectionHeader => 'بيانات التحويل البنكي والسويفت';
  @override String get beneficiaryBankFieldLabel => 'اسم البنك المستفيد';
  @override String get swiftCodeFieldLabel => 'كود السويفت';
  @override String get accountNumberFieldLabel => 'رقم الحساب البنكي';
  @override String get ibanFieldLabel => 'رقم الآيبان';
  @override String get contactAddressBrandsHeader => 'العنوان ووسائل الاتصال والعلامات التجارية';
  @override String get fullAddressFieldLabel => 'العنوان الكامل';
  @override String get phoneFieldLabel => 'الهاتف';
  @override String get emailFieldLabel => 'البريد الإلكتروني';
  @override String get websiteFieldLabel => 'الموقع الإلكتروني';
  @override String get brandsFieldLabel => 'العلامات التجارية والمنتجات';
  @override String get additionalNotesHeader => 'ملاحظات إدارية إضافية';

  // ── Screen 34: External Partners & Service Providers (Partners & Banks) ──
  @override String get partnersScreenTitle => 'الشركاء ومقدمو الخدمات الخارجية';
  @override String get partnersScreenSubtitle => 'إدارة البنوك التجارية، الخطوط الملاحية، المخلصين الجمركيين، وكلاء الشحن، وشركاء الخدمات اللوجستية';
  @override String get addExternalPartnerBtn => 'إضافة شريك خارجي جديد';
  @override String get partnerCatAll => 'الكل';
  @override String get partnerCatBank => 'بنك';
  @override String get partnerCatShippingLine => 'خط ملاحي';
  @override String get partnerCatCustomsBroker => 'مخلص جمركي';
  @override String get partnerCatFreightForwarder => 'وكيل شحن';
  @override String get partnerCatInlandTransport => 'نقل بري';
  @override String get partnerCatInspectionAgency => 'هيئة فحص ومعاينة';
  @override String get searchPartnersHint => 'بحث باسم الشريك، الكود، كود السويفت، رقم الترخيص، البطاقة الضريبية، أو الدولة...';
  @override String get showInactivePartnersLabel => 'عرض المتوقفين:';
  @override String get partnersFetchError => 'تعذر الاتصال بالسيرفر وجلب الشركاء:\n\$error';
  @override String get noPartnersFound => 'لم يتم العثور على شركاء بالفلاتر المحددة.';
  @override String get partnerCodeCol => 'الكود';
  @override String get partnerNameAndCategoryCol => 'اسم الشريك والتصنيف';
  @override String get registrationAndLicenseCol => 'بيانات القيد والترخيص';
  @override String get contactDetailsCol => 'بيانات التواصل';
  @override String get partnerStatusCol => 'الحالة';
  @override String get partnerActionsCol => 'الإجراءات';
  @override String partnerSwiftLabel(String code) => 'السويفت: $code';
  @override String partnerScacLabel(String code) => 'كود الناقل: $code';
  @override String partnerLicenseLabel(String num) => 'ترخيص: $num';
  @override String partnerRegLabel(String num) => 'سجل: $num';
  @override String partnerCountryLabel(String country) => 'الدولة: $country';
  @override String get noEmailLabel => 'لا يوجد بريد';
  @override String get noPhoneLabel => 'لا يوجد هاتف';
  @override String get partnerStatementOfAccountBtn => 'كشف حساب';
  @override String get partnerStatementOfAccountTooltip => 'كشف حساب الشريك والأرصدة بالعملات';
  @override String confirmDeactivatePartner(String name) => 'هل أنت متأكد من رغبتك في إيقاف تفعيل الشريك ($name)؟';
  @override String confirmActivatePartner(String name) => 'هل أنت متأكد من إعادة تفعيل الشريك ($name)؟';
  @override String get deactivatePartnerTooltip => 'إيقاف تفعيل الشريك';
  @override String get activatePartnerTooltip => 'إعادة تفعيل الشريك';
  @override String get editPartnerDialogTitle => 'تعديل بيانات الشريك الخارجي والبنك';
  @override String get addPartnerDialogTitle => 'إضافة شريك خارجي وبنك جديد';
  @override String get partnerCategoriesLabel => 'تصنيفات الشريك (اختر تصنيفاً واحداً أو أكثر) *';
  @override String get partnerNameLabel => 'اسم الشريك / الشركة *';
  @override String get partnerNameHint => 'مثال: البنك الأهلي المصري / ميرسك لاين / لوجستيات الشحن';
  @override String get bankingDetailsHeader => 'بيانات الحساب البنكي';
  @override String get bankSwiftCodeLabel => 'كود السويفت *';
  @override String get bankSwiftCodeHint => 'كود السويفت البنكي';
  @override String get bankCodeLabel => 'كود البنك';
  @override String get bankCodeHint => 'كود البنك';
  @override String get branchNameLabel => 'اسم الفرع';
  @override String get branchNameHint => 'مثال: الفرع الرئيسي، القاهرة';
  @override String get shippingLineDetailsHeader => 'بيانات الخط الملاحي';
  @override String get scacCarrierCodeLabel => 'كود الناقل الملاحي *';
  @override String get scacCarrierCodeHint => 'كود الناقل الملاحي';
  @override String get trackingWebUrlLabel => 'رابط تتبع الشحنات الملاحية';
  @override String get trackingWebUrlHint => 'رابط التتبع الإلكتروني';
  @override String get customsBrokerLicenseHeader => 'ترخيص التخليص الجمركي';
  @override String get customsClearanceLicenseNumLabel => 'رقم ترخيص مزاولة التخليص الجمركي *';
  @override String get customsClearanceLicenseNumHint => 'رقم رخصة التخليص الجمركي';
  @override String get partnerTaxIdLabel => 'رقم التسجيل الضريبي';
  @override String get partnerTaxIdHint => 'الرقم الضريبي';
  @override String get partnerCommercialRegLabel => 'رقم السجل التجاري';
  @override String get partnerCommercialRegHint => 'رقم السجل التجاري';
  @override String get partnerPrimaryEmailLabel => 'البريد الإلكتروني الرئيسي';
  @override String get partnerPrimaryEmailHint => 'contact@partner.com';
  @override String get partnerSecondaryEmailLabel => 'بريد إلكتروني إضافي';
  @override String get partnerSecondaryEmailHint => 'trade@partner.com';
  @override String get partnerPhoneLabel => 'رقم الهاتف';
  @override String get partnerPhoneHint => 'رقم الهاتف مع كود المحافظة';
  @override String get partnerMobileLabel => 'رقم المحمول';
  @override String get partnerMobileHint => 'رقم المحمول';
  @override String get partnerFaxLabel => 'رقم الفاكس';
  @override String get partnerFaxHint => 'رقم الفاكس';
  @override String get partnerWebsiteUrlLabel => 'الموقع الإلكتروني';
  @override String get partnerWebsiteUrlHint => 'www.partner.com';
  @override String get partnerAddressLabel => 'العنوان';
  @override String get partnerAddressHint => 'العنوان، المدينة';
  @override String get partnerCountryLabelField => 'الدولة *';
  @override String get updatePartnerBtn => 'حفظ تعديلات الشريك';
  @override String get savePartnerBtn => 'حفظ بيانات الشريك';
  @override String get savingChanges => 'جاري حفظ التعديلات...';
  @override String get diffPartnerName => 'اسم مقدم الخدمة / الشريك';
  @override String get diffPartnerType => 'نوع الشريك';
  @override String get diffPartnerEmail => 'البريد الإلكتروني';
  @override String get diffPartnerPhone => 'الهاتف';
  @override String get diffPartnerAddress => 'العنوان';
  @override String get diffPartnerCountry => 'الدولة';
  @override String get diffConfirmPartnerTitle => 'مراجعة وتأكيد تعديلات مقدم الخدمة / الشريك';
  @override String get partnerProfileTitle => 'بطاقة تعريف الشريك ومقدم الخدمة';
  @override String get professionalLicensesSection => 'الرخص المهنية والأكواد والبيانات القانونية';
  @override String get partnerSwiftCodeDetailLabel => 'كود السويفت البنكي';
  @override String get partnerScacCodeDetailLabel => 'كود الخط الملاحي';
  @override String get clearanceLicenseDetailLabel => 'رقم ترخيص التخليص الجمركي';
  @override String get commercialRegDetailLabel => 'السجل التجاري';
  @override String get taxIdDetailLabel => 'البطاقة الضريبية';
  @override String get creditTermsSection => 'شروط السداد والائتمان المالي';
  @override String get paymentTermsDetailLabel => 'نوع وشروط السداد';
  @override String get creditLimitDetailLabel => 'الحد الائتماني';
  @override String get ratingDetailLabel => 'التقييم';
  @override String get bankCodeDetailLabel => 'كود البنك';
  @override String get branchNameDetailLabel => 'اسم الفرع';
  @override String get contactAndAddressSection => 'بيانات التواصل والعنوان الرسمي';
  @override String get contactPersonDetailLabel => 'مسؤول الاتصال';
  @override String get countryDetailLabel => 'الدولة';
  @override String get phoneMobileDetailLabel => 'الهاتف / المحمول';
  @override String get emailDetailLabel => 'البريد الإلكتروني';
  @override String get fullAddressDetailLabel => 'العنوان الكامل';
  @override String get websiteDetailLabel => 'الموقع الإلكتروني';
  @override String get additionalNotesSection => 'ملاحظات إضافية';
  @override String get partnerStatementShortcutBtn => 'كشف حساب 📑';
  @override String get editPartnerBtn => 'تعديل';
  @override String partnerSoaTitle(String name) => 'كشف حساب مقدم الخدمة — $name';
  @override String partnerSoaSubtitle(String type, String taxId) => 'تصنيف الشريك: $type | الرقم الضريبي: $taxId | العملات والحركات المالية';
  @override String get calculatingSoaMsg => 'جاري احتساب كشف الحساب وتجميع الأرصدة...';
  @override String soaFetchError(String error) => 'حدث خطأ أثناء جلب كشف الحساب: $error';
  @override String get noSoaDataAvailable => 'لا توجد بيانات مالية متاحة لهذا الشريك';
  @override String get multiCurrencyBalancesHeader => 'ملخص الأرصدة والمستحقات بكل عملة:';
  @override String get totalInvoicedLabel => 'إجمالي الفواتير:';
  @override String get totalPaidLabel => 'المبالغ المسددة:';
  @override String get balanceDueLabel => 'الرصيد المستحق:';
  @override String transactionsLedgerHeader(int count) => 'سجل العمليات والفواتير والمدفوعات ($count حركة مسجلة):';
  @override String invoicesCountLabel(int invoices, int payments) => 'فواتير: $invoices | دفعات: $payments';
  @override String get noLedgerEntriesFound => 'لا توجد حركات فواتير أو مدفوعات مسجلة لهذا الشريك حتى الآن';
  @override String get ledgerDateCol => 'التاريخ';
  @override String get ledgerTypeCol => 'النوع';
  @override String get ledgerRefCol => 'المرجع';
  @override String get ledgerImportFileCol => 'ملف الشحنة';
  @override String get ledgerDescriptionCol => 'البيان / الوصف';
  @override String get ledgerCurrencyCol => 'العملة';
  @override String get ledgerDebitCol => 'مدين (فاتورة)';
  @override String get ledgerCreditCol => 'دائن (سداد)';
  @override String get ledgerStatusCol => 'الحالة';
  @override String get ledgerInvoiceBadge => 'فاتورة';
  @override String get ledgerPaymentBadge => 'سداد';
  @override String get soaFooterText => 'سلسلة استيراد فلو — وحدة محاسبة الموردين ومقدمي الخدمات متعددة العملات';
  @override String get closeBtn => 'إغلاق';

  // Screen 35: Incoterms Rules (Incoterms 2020 · Cost Items · Responsibility Matrix)
  @override String get incotermsScreenTitle => 'الشروط التجارية الدولية';
  @override String get incotermsScreenSubtitle => 'إصدارات شروط التجارة الدولية، بنود التكلفة ومصفوفة توزيع المسؤوليات';
  @override String get incotermsTabRules => 'شروط التجارة';
  @override String get incotermsTabCostItems => 'بنود التكلفة';
  @override String get incotermsTabMatrix => 'مصفوفة المسؤوليات';
  @override String get searchIncotermsHint => 'بحث بالكود، الاسم، أو التصنيف...';
  @override String get showInactiveIncotermsLabel => 'عرض الشروط المتوقفة:';
  @override String get addIncotermBtn => 'إضافة شرط تجاري جديد';
  @override String get noIncotermsFound => 'لم يتم العثور على شروط تجارة دولية.';
  @override String get incotermCodeCol => 'كود الشرط';
  @override String get incotermNameCol => 'الاسم والبيان';
  @override String get incotermVersionCol => 'الإصدار';
  @override String get incotermStatusCol => 'الحالة';
  @override String get incotermActionsCol => 'الإجراءات';
  @override String printIncotermSnack(String code, String name) => 'طباعة بيانات شرط التجارة الدولي: $code ($name)';
  @override String confirmDeactivateIncoterm(String code) => 'هل أنت متأكد من رغبتك في إيقاف تفعيل شرط التجارة ($code)؟';
  @override String confirmActivateIncoterm(String code) => 'هل أنت متأكد من إعادة تفعيل شرط التجارة ($code)؟';
  @override String get deactivateIncotermTooltip => 'إيقاف تفعيل الشرط';
  @override String get activateIncotermTooltip => 'إعادة تفعيل الشرط';
  @override String get editIncotermDialogTitle => 'تعديل بيانات شرط التجارة الدولي';
  @override String get addIncotermDialogTitle => 'إضافة شرط تجارة دولي جديد';
  @override String get incotermCodeLabel => 'كود شرط التجارة *';
  @override String get incotermFullNameLabel => 'الاسم الكامل للشرط *';
  @override String get incotermVersionLabel => 'إصدار الغرفة التجارية الدولية';
  @override String get incotermDescriptionLabel => 'الوصف وتحديد نقطة انتقال المخاطر';
  @override String get addCostItemBtn => 'إضافة بند تكلفة جديد';
  @override String get showInactiveCostItemsLabel => 'عرض البنود المتوقفة:';
  @override String get noCostItemsFound => 'لم يتم العثور على بنود تكلفة.';
  @override String get costItemCodeCol => 'كود البند';
  @override String get costItemNameCol => 'اسم بند التكلفة';
  @override String get costItemCategoryCol => 'التصنيف';
  @override String get costItemStatusCol => 'الحالة';
  @override String get costItemActionsCol => 'الإجراءات';
  @override String get costCategoryFreight => 'شحن ونولون';
  @override String get costCategoryCustoms => 'جمارك وضرائب';
  @override String get costCategoryPort => 'موانئ وأرضيات';
  @override String get costCategoryBank => 'بنوك وتمويل';
  @override String get costCategoryOther => 'مصاريف أخرى';
  @override String printCostItemSnack(String code, String name) => 'طباعة بيانات بند التكلفة: $code ($name)';
  @override String confirmDeactivateCostItem(String code) => 'هل أنت متأكد من رغبتك في إيقاف تفعيل بند التكلفة ($code)؟';
  @override String confirmActivateCostItem(String code) => 'هل أنت متأكد من إعادة تفعيل بند التكلفة ($code)؟';
  @override String get deactivateCostItemTooltip => 'إيقاف تفعيل بند التكلفة';
  @override String get activateCostItemTooltip => 'إعادة تفعيل بند التكلفة';
  @override String get editCostItemDialogTitle => 'تعديل بيانات بند التكلفة';
  @override String get addCostItemDialogTitle => 'إضافة بند تكلفة جديد';
  @override String get costItemCodeLabel => 'كود بند التكلفة *';
  @override String get costItemNameLabel => 'اسم بند التكلفة *';
  @override String get costCategoryLabel => 'تصنيف التكلفة *';
  @override String get costItemDescriptionLabel => 'وصف وتفاصيل بند التكلفة';
  @override String get filterByIncotermLabel => 'تصفية حسب شرط التجارة:';
  @override String get allIncotermsOption => 'كافة الشروط التجارية (11 شرطاً)';
  @override String get showingAllMatrixResponsibilities => 'عرض مصفوفة المسؤوليات لكافة الشروط التجارية';
  @override String get filteringResponsibilitiesForSelectedTerm => 'عرض وتصفية المسؤوليات للشرط المحدد';
  @override String get noMatrixDataFound => 'لا توجد بيانات مسؤوليات مسجلة.';
  @override String get matrixIncotermCol => 'شرط التجارة';
  @override String get matrixCostItemCol => 'بند التكلفة';
  @override String get matrixCategoryCol => 'التصنيف';
  @override String get matrixResponsibleCol => 'الجهة المسؤولة';
  @override String get matrixIncludedCol => 'مدرج بالسعر';
  @override String get matrixNotesCol => 'ملاحظات وشروط';
  @override String get matrixActionsCol => 'الإجراءات';
  @override String get partyBuyerImporter => 'المشتري / المستورد';
  @override String get partySellerExporter => 'البائع / الشاحن';
  @override String get partyShared => 'مشترك بين الطرفين';
  @override String get editResponsibilityTooltip => 'تعديل توزيع المسؤولية';
  @override String editResponsibilityDialogTitle(String code) => 'تعديل توزيع المسؤولية · $code';
  @override String incotermPrefix(String code) => 'شرط التجارة: $code';
  @override String costItemPrefix(String name, String category) => 'بند التكلفة: $name ($category)';
  @override String get matrixResponsiblePartyFieldLabel => 'الجهة المسؤولة عن التكلفة *';
  @override String get includedInSellerPriceTitle => 'مدرج ضمن سعر الفاتورة للبائع';
  @override String get includedInSellerPriceSubtitle => 'هل يتحمل البائع هذه التكلفة ضمن سعر الفاتورة النهائي؟';
  @override String get commentNotesLabel => 'ملاحظات وشروط إضافية';
  @override String get commentNotesHint => 'إضافة تفاصيل أو شروط خاصة ببند التكلفة...';
  @override String get updatedSuccessfully => 'تم تحديث البيانات بنجاح';

  // Screen 36: Customs Tariff Schedule & HS Codes
  @override String get customsTariffScreenTitle => 'التعريفة الجمركية وبنود التعريفة المنسقة';
  @override String get customsTariffScreenSubtitle => 'فئات ضريبة الوارد المصرية، القيمة المضافة، ضريبة الجدول، رسم التنمية والاشتراطات الاستيرادية';
  @override String get importExcelCsvBtn => 'استيراد ملف جدول بيانات';
  @override String get hsExplorerBtn => '🔍 استعلام وبحث شامل';
  @override String get smartNafezaDiffEngineBtn => '✨ إدخال بند ومحلل الفروقات الذكي';
  @override String get dutyCalculatorBtn => 'حاسبة الرسوم والضرائب';
  @override String get addTariffManualBtn => '+ إضافة بند يدوي';
  @override String get searchTariffsHint => 'بحث بكود البند، الوصف، أو التصنيف...';
  @override String get showInactiveTariffsLabel => 'عرض المتوقف:';
  @override String noTariffsMatchingQuery(String query) => 'لم يتم العثور على أي بند يطابق البحث: "$query"';
  @override String get noTariffsFound => 'لا توجد بنود جمركية مسجلة.';
  @override String get tariffHsCodeCol => 'كود البند الجمركي';
  @override String get tariffDescAndAuthorityCol => 'الوصف والجهة الرقابية';
  @override String get tariffCategoryCol => 'التصنيف';
  @override String get tariffTaxRatesBreakdownCol => 'تفاصيل الضرائب والرسوم';
  @override String get tariffRequirementsCol => 'الاشتراطات';
  @override String get tariffStatusCol => 'الحالة';
  @override String get tariffActionsCol => 'الإجراءات';
  @override String rateDutyBadge(String rate) => 'وارد: $rate';
  @override String rateVatBadge(String rate) => 'ق.م: $rate';
  @override String rateSchedBadge(String rate) => 'جدول: $rate';
  @override String rateDevBadge(String rate) => 'تنمية: $rate';
  @override String govAuthorityPrefix(String auth) => 'الجهة: $auth';
  @override String printTariffSnack(String code, String desc) => 'طباعة بيانات البند الجمركي: $code ($desc)';
  @override String confirmDeactivateTariff(String code) => 'هل أنت متأكد من رغبتك في إيقاف تفعيل البند الجمركي ($code)؟';
  @override String confirmActivateTariff(String code) => 'هل أنت متأكد من إعادة تفعيل البند الجمركي ($code)؟';
  @override String get deactivateTariffTooltip => 'إيقاف تفعيل البند';
  @override String get activateTariffTooltip => 'إعادة تفعيل البند';
  @override String get importingTariffDataset => 'جاري استيراد وتحديث جدول التعريفة الجمركية...';
  @override String get importCompletedTitle => 'اكتمل الاستيراد بنجاح';
  @override String importSummaryContent(int total, int imported, int updated) => 'تمت معالجة $total بند جمركي بنجاح!\n• بنود جديدة تم إنشاؤها: $imported\n• بنود سابقة تم تحديثها: $updated';
  @override String importFailedSnack(String error) => 'فشل الاستيراد: $error';
  @override String get nafezaDetailsModalTitle => 'تفاصيل البند الجمركي';
  @override String get itemNumberLabel => 'رقم البند : ';
  @override String get itemDescriptionLabel => 'نص البند : ';
  @override String get taxesSectionHeader => 'الضرائب والرسوم :';
  @override String get importDutyLabel => 'ضريبة الوارد';
  @override String get vatLabel => 'ضريبة القيمة المضافة';
  @override String get scheduleTaxLabel => 'ضريبة الجدول';
  @override String get developmentFeeLabel => 'رسم التنمية';
  @override String get importFeeLabel => 'رسم الوارد';
  @override String get customsServiceFeeLabel => 'رسوم الخدمات الجمركية';
  @override String get basicFeesLabel => 'رسوم أساسية';
  @override String get documentsAndProceduresHeader => 'المستندات والأعمال :';
  @override String get preferentialAgreementsSubheader => 'الاتفاقيات التفضيلية والإعفاءات الجمركية';
  @override String get addPreferentialAgreementBtn => 'إضافة اتفاقية';
  @override String get noPreferentialAgreements => 'لا توجد اتفاقيات تفضيلية مسجلة لهذا البند.';
  @override String get fullExemptionBadge => 'إعفاء جمركي كامل (0%)';
  @override String reductionPercentageBadge(String pct) => 'تخفيض جمركي: $pct%';
  @override String applicableCountriesLabel(String countries) => 'الدول المشمولة: $countries';
  @override String conditionsLabel(String conditions) => 'الشروط: $conditions';
  @override String get regulatoryApprovalsSubheader => 'الموافقات الرقابية المسبقة وجهات العرض';
  @override String get requiresCooRule => 'يشترط تقديم شهادة منشأ معتمدة وموثقة';
  @override String get requiresInspectionRule => 'خاضع لرقابة وفحص هيئة الرقابة على الصادرات والواردات';
  @override String get requiresAcidRule => 'إلزامية استخراج الرقم التعريفي المسبق للشحنة';
  @override String addAgreementDialogTitle(String code) => 'إضافة اتفاقية تفضيلية للبند $code';
  @override String get agreementNameLabel => 'اسم الاتفاقية *';
  @override String get agreementNameHint => 'مثال: اتفاقية الشراكة المصرية الأوروبية، الكوميسا، أغادير';
  @override String get agreementCountriesLabel => 'دول المنشأ المعنية *';
  @override String get agreementCountriesHint => 'رموز الدول مفصولة بفواصل';
  @override String get dutyReductionPctLabel => 'نسبة التخفيض الجمركي % *';
  @override String get dutyReductionPctHint => '100 للإعفاء الكامل، 10 للتخفيض 10%';
  @override String get agreementConditionsLabel => 'شروط وملاحظات الإفراج التفضيلية';
  @override String get agreementConditionsHint => 'مثال: مصحوبة بشهادة منشأ تفضيلية أو نموذج معتمد';
  @override String get saveAgreementBtn => 'حفظ الاتفاقية';
  @override String verifyTariffDialogTitle(String code) => 'توثيق وتدقيق بيانات البند الجمركي ($code)';
  @override String get verificationProtocolHeader => 'بروتوكول التدقيق والتوثيق المعتمد:';
  @override String get verificationProtocolText => '• يُحظر الاستعلام الخارجي المباشر، كافة البيانات تحفظ وتحدث محلياً.\n• تعديل نسب الضرائب يقوم بأرشفة الإصدار الحالي وإنشاء إصدار نشط جديد.\n• التقديرات التاريخية تحتفظ بنسبتها المسجلة وقت الاحتساب.';
  @override String get verifiedByAuditorLabel => 'اسم المراجع / المسؤول المعتمد *';
  @override String get sourceUrlLabel => 'رابط المصدر في بوابة نافذة';
  @override String get confidenceLevelLabel => 'درجة الموثوقية والتدقيق *';
  @override String get confirmVerificationBtn => 'تأكيد واعتماد التوثيق';
  @override String get verifyTariffBtn => 'توثيق وتدقيق البند';
  @override String get editTariffBtn => 'تعديل البند';
  @override String get agreementNameRequired => 'مطلوب إدخال اسم الاتفاقية';
  @override String get agreementCountriesRequired => 'مطلوب إدخال دول المنشأ';
  @override String get invalidNumberError => 'رقم غير صحيح';
  @override String get agreementAddedSuccess => 'تمت إضافة الاتفاقية التفضيلية بنجاح';
  @override String agreementAddFailed(String error) => 'فشلت إضافة الاتفاقية: $error';
  @override String get auditorNameRequired => 'اسم المراجع / المسؤول مطلوب';
  @override String get verificationSuccessSnack => 'تم توثيق وتدقيق بيانات البند الجمركي بنجاح';
  @override String verificationFailedSnack(String error) => 'فشل التوثيق: $error';
  @override String get confidenceManualAudit => 'تدقيق وتوثيق يدوي معتمد';
  @override String get confidenceOfficialGazette => 'قرار رسمي منشور بالجريدة الرسمية';
  @override String get confidenceDraft => 'مسودة / غير مدقق';
  @override String get priorApprovalSpecialConditionsLabel => 'ملاحظات الموافقة المسبقة والاشتراطات الخاصة';
  @override String get taxRatesVerificationHeader => 'تدقيق ومراجعة فئات الضرائب والرسوم:';
  @override String get dutyRateLabel => 'نسبة ضريبة الوارد %';
  @override String get vatRateLabel => 'نسبة ضريبة القيمة المضافة %';
  @override String get scheduleTaxRateLabel => 'نسبة ضريبة الجدول %';
  @override String tariffVerifiedSuccess(String code) => 'تم توثيق وتدقيق البند الجمركي $code بنجاح';

  // Screen 37: Ports & Transport Locations
  @override String get transportLocationsScreenTitle => 'الموانئ والمنافذ الجمركية';
  @override String get transportLocationsScreenSubtitle => 'دليل الموانئ البحرية، المطارات الجوية، الموانئ الجافة والمنافذ البرية';
  @override String get addTransportLocationBtn => 'إضافة منفذ / ميناء جديد';
  @override String get locationTypeAll => 'الكل';
  @override String get locationTypeSeaPort => 'ميناء بحري';
  @override String get locationTypeAirport => 'مطار جوي';
  @override String get locationTypeDryPort => 'ميناء جاف';
  @override String get locationTypeLandBorder => 'منفذ بري';
  @override String get locationTypeIcd => 'مستودع جمركي / ميناء داخلي';
  @override String get locationTypeRailTerminal => 'محطة سكة حديد';
  @override String get searchTransportLocationsHint => 'بحث بكود المنفذ، الاسم، المدينة...';
  @override String locationsFetchError(String error) => 'تعذر الاتصال بالسيرفر وجلب بيانات الموانئ والمنافذ:\n$error';
  @override String get noTransportLocationsFound => 'لا توجد موانئ أو منافذ مسجلة.';
  @override String get unLocodeCol => 'كود المنفذ';
  @override String get locationNameCol => 'اسم المنفذ / الميناء';
  @override String get locationTypeCol => 'النوع';
  @override String get countryCol => 'الدولة';
  @override String get cityCol => 'المدينة';
  @override String printLocationSnack(String name, String code) => 'طباعة بيانات المنفذ/الميناء: $name ($code)';
  @override String confirmDeactivateLocation(String name) => 'هل أنت متأكد من رغبتك في إيقاف تفعيل الميناء/المنفذ ($name)؟';
  @override String confirmActivateLocation(String name) => 'هل أنت متأكد من إعادة تفعيل الميناء/المنفذ ($name)؟';
  @override String get deactivateLocationTooltip => 'إيقاف تفعيل المنفذ';
  @override String get activateLocationTooltip => 'إعادة تفعيل المنفذ';
  @override String showingLocationsCount(int start, int end, int total, String type) => 'عرض $start–$end من إجمالي $total منفذ ($type)';
  @override String get addLocationDialogTitle => 'إضافة منفذ / ميناء شحن جديد';
  @override String editLocationDialogTitle(String locode) => 'تعديل بيانات المنفذ ($locode)';
  @override String get unLocodeLabel => 'كود المنفذ الدولي *';
  @override String get unLocodeHint => 'مثال: EGALY, EGCAI';
  @override String get locationTypeLabel => 'نوع المنفذ / الميناء *';
  @override String get locationNameLabel => 'اسم المنفذ / الميناء *';
  @override String get locationNameHint => 'مثال: ميناء الإسكندرية البحري';
  @override String get countryLabelRequired => 'الدولة *';
  @override String get countryHint => 'مثال: جمهورية مصر العربية';
  @override String get cityLabelRequired => 'المدينة *';
  @override String get cityHint => 'مثال: الإسكندرية';
  @override String get locationNotesLabel => 'ملاحظات وتفاصيل إضافية';
  @override String get createLocationSubmitBtn => 'إضافة المنفذ';
  @override String get importingLocationsDataset => 'جاري استيراد وتحديث المنافذ والموانئ من الملف...';
  @override String get importWarningsTitle => 'تنبيهات الاستيراد';
  @override String get locationsImportSuccess => 'تم استيراد المنافذ والموانئ بنجاح!';

  // Screen 38: Currencies & Exchange Rates
  @override String get currenciesScreenTitle => 'العملات وأسعار الصرف';
  @override String get currenciesScreenSubtitle => 'إدارة أكواد العملات، أسعار البنوك التجارية وأسعار الصرف الجمركية الرسمية';
  @override String get liveCurrencyConverterBtn => 'محول العملات الحي';
  @override String get currencyGainLossBtn => 'فروق أسعار العملات';
  @override String get updateExchangeRatesBtn => 'تحديث أسعار الصرف';
  @override String get addCurrencyBtn => 'إضافة عملة جديدة';
  @override String get searchCurrenciesHint => 'بحث بكود العملة أو الاسم...';
  @override String currenciesFetchError(String error) => 'تعذر الاتصال بالسيرفر وجلب بيانات العملات:\n$error';
  @override String get noCurrenciesFound => 'لم يتم العثور على عملات مسجلة.';
  @override String get isoCodeCol => 'كود العملة';
  @override String get currencyNameCol => 'اسم العملة';
  @override String get currencySymbolCol => 'الرمز';
  @override String get commercialRateBankCol => 'سعر البنك التجاري';
  @override String get customsRateOfficialCol => 'سعر الجمارك الرسمي';
  @override String get baseCurrencyTooltip => 'عملة الأساس (الجنيه المصري)';
  @override String get viewRateHistoryTooltip => 'عرض السجل التاريخي لتحديث أسعار الصرف';
  @override String get baseCurrencyRateLabel => '1.0000 (أساس)';
  @override String rateToEgpFormatted(String code, String rate) => '1 $code = $rate جنيه';
  @override String get rateNotSet => 'غير محدد';
  @override String printCurrencyDetailsSnack(String code, String name) => 'طباعة بيانات وسجل أسعار العملة: $code ($name)';
  @override String confirmDeactivateCurrency(String code, String name) => 'هل أنت متأكد من رغبتك في إيقاف تفعيل عملة ($code - $name)؟';
  @override String confirmActivateCurrency(String code, String name) => 'هل أنت متأكد من إعادة تفعيل عملة ($code - $name)؟';
  @override String get cannotDeactivateBaseCurrencyTooltip => 'لا يمكن تعطيل عملة الأساس';
  @override String get deactivateCurrencyTooltip => 'إيقاف تفعيل العملة';
  @override String get activateCurrencyTooltip => 'إعادة تفعيل العملة';
  @override String showingCurrenciesCount(int start, int end, int total) => 'عرض $start–$end من إجمالي $total عملة';
  @override String get addCurrencyDialogTitle => 'إضافة عملة جديدة';
  @override String editCurrencyDialogTitle(String code) => 'تعديل بيانات العملة ($code)';
  @override String get isoCodeLabel => 'كود العملة القياسي (3 أحرف) *';
  @override String get isoCodeHint => 'مثال: الدولار، اليورو';
  @override String get isoCodeLengthError => 'يجب أن يتكون الكود من 3 أحرف';
  @override String get currencyNameLabel => 'اسم العملة *';
  @override String get currencyNameHint => 'مثال: دولار أمريكي، يورو';
  @override String get currencySymbolLabel => 'رمز العملة *';
  @override String get currencySymbolHint => 'مثال: رمز العملة';
  @override String get createCurrencySubmitBtn => 'إضافة العملة';
  @override String exchangeRateHistoryTitle(String name) => 'السجل التاريخي لأسعار الصرف — $name';
  @override String get baseCurrencySystemDesc => 'العملة الأساسية للنظام (الجنيه المصري)';
  @override String get rateHistorySubtitle => 'سجل التحديثات والتغيرات في أسعار البنك والجمارك الرسمية';
  @override String get currentCommercialRateStat => 'سعر البنك التجاري الحالي';
  @override String get currentCustomsRateStat => 'سعر الصرف الجمركي الرسمي';
  @override String get rateSpreadStat => 'الفارق بين السعرين';
  @override String get historicalUpdatesCountStat => 'عدد التحديثات التاريخية';
  @override String recordsCountBadge(int count) => '$count سجلات';
  @override String get notSetLabel => 'غير محدد';
  @override String get exchangeRateTimelineHeader => 'سجل التحديثات الزمنية لأسعار الصرف:';
  @override String get recordNewExchangeRateBtn => 'تحديث سعر صرف جديد';
  @override String get baseCurrencyNoticeTitle => 'الجنيه المصري هو عملة الأساس في النظام';
  @override String get baseCurrencyNoticeSubtitle => 'سعر الصرف دائماً 1.0000 ولا يتطلب تحديث أسعار تاريخية مقابل نفسه.';
  @override String noRateHistoryForCurrency(String code) => 'لا يوجد سجل أسعار تاريخي مسجل لعملة ($code) حتى الآن.';
  @override String get recordFirstExchangeRateBtn => 'تسجيل أول سعر صرف';
  @override String get currentActiveRateBadge => 'السعر الحالي الساري';
  @override String get commercialBankRateLabel => 'سعر البنك:';
  @override String get customsExchangeRateLabel => 'سعر الجمارك:';
  @override String get spreadVarianceLabel => 'الفارق:';
  @override String rateSourcePrefix(String source) => 'بواسطة: $source';
  @override String get updateExchangeRatesDialogTitle => 'تحديث أسعار الصرف (البنكي والجمركي)';
  @override String get selectForeignCurrencyLabel => 'اختيار العملة الأجنبية *';
  @override String get commercialRateInputLabel => 'سعر صرف البنك التجاري مقابل الجنيه *';
  @override String get customsRateInputLabel => 'سعر الصرف الجمركي الرسمي مقابل الجنيه *';
  @override String get rateInputHint => 'مثال: 50.25';
  @override String get enterValidRateError => 'أدخل سعر صحيح أكبر من صفر';
  @override String effectiveDateLabel(String date) => 'تاريخ سريان السعر: $date';
  @override String get saveRateSubmitBtn => 'حفظ سعر الصرف';
  @override String get liveCurrencyConverterDialogTitle => 'محول العملات الحي';
  @override String get liveCurrencyConverterDialogSubtitle => 'قم بإدخال المبلغ واختيار العملات لنشاط التحويل المباشر:';
  @override String get amountToConvertLabel => 'المبلغ المراد تحويله *';
  @override String get amountToConvertHint => '10000';
  @override String get enterValidAmountError => 'أدخل مبلغاً صحيحاً أكبر من صفر';
  @override String get fromCurrencyLabel => 'من عملة';
  @override String get toCurrencyLabel => 'إلى عملة';
  @override String get appliedRateTypeLabel => 'نوع سعر الصرف المطبق';
  @override String get rateTypeCommercialOption => 'سعر البنك التجاري';
  @override String get rateTypeCustomsOption => 'سعر الصرف الجمركي الرسمي';
  @override String get convertCurrencyNowBtn => 'تحويل العملة الآن';
  @override String get convertedAmountLabel => 'المبلغ المحول:';
  @override String appliedRatePrefix(dynamic rate) => 'سعر الصرف المطبق: $rate';
  @override String baseEgpEquivalentPrefix(dynamic amount) => 'المكافئ بالجنيه المصري: $amount جنيه';
  @override String get fxGainLossDialogTitle => 'حاسبة فروق أسعار العملات';
  @override String get fxGainLossDialogSubtitle => 'حساب الفرق المالي الناتج عن تغير سعر الصرف بين تاريخ الربط وتاريخ التسوية:';
  @override String get foreignAmountLabel => 'المبلغ بالعملة الأجنبية *';
  @override String get currencyLabel => 'العملة *';
  @override String get initialRateLabel => 'سعر الربط المبدئي *';
  @override String get initialRateHint => '49.00';
  @override String get settlementRateLabel => 'سعر التسوية والدفع *';
  @override String get settlementRateHint => '47.50';
  @override String get calculateGainLossBtn => 'حساب فروق العملة الآن';
  @override String initialCostAtBooking(dynamic amount, dynamic rate) => 'التكلفة المبدئية عند الربط: $amount جنيه (سعر: $rate)';
  @override String actualCostAtSettlement(dynamic amount, dynamic rate) => 'التكلفة الفعلية عند التسوية: $amount جنيه (سعر: $rate)';

  // Generic Pagination
  @override String get rowsPerPageLabel => 'الصفوف بالصفحة:';
  @override String get firstPageTooltip => 'الصفحة الأولى';
  @override String get previousPageTooltip => 'الصفحة السابقة';
  @override String pageOfTotal(dynamic page, dynamic totalPages) => '$page من $totalPages';
  @override String get nextPageTooltip => 'الصفحة التالية';
  @override String get lastPageTooltip => 'الصفحة الأخيرة';

  // Screen 43: Regulatory Requirements & Pre-Shipment Compliance
  @override String get importRequirementsScreenTitle => 'تقييم متطلبات ومستندات الاستيراد والموافقات التنظيمية';
  @override String get importRequirementsFormTab => '📋 تقييم ومطابقة المتطلبات التنظيمية';
  @override String get importRequirementsRegistryTab => '📑 سجل دراسات المتطلبات المحفوظة';
  @override String editingRequirementBanner(dynamic code) => 'أنت الآن في وضع تعديل واستكمال التقييم: ($code) — سيتم تحديث السجل وإعادة تفعيله فور الحفظ.';
  @override String get cancelEditingAndStartNewBtn => 'إلغاء التعديل والبدء من جديد';
  @override String get requirementsLifecycleCardTitle => 'نطاق ومسار المتطلبات (من إصدار الرقم المسبق حتى الإبحار والشحن الفعلي):';
  @override String sailingStatusBadge(dynamic status) => 'حالة الإبحار: $status';
  @override String get acidIssuanceStep => 'إصدار الرقم المسبق للشحنة';
  @override String get preShipmentInspectionStep => 'فحص ومطابقة ما قبل الشحن';
  @override String get approvalsAndCertsStep => 'الموافقات والشهادات';
  @override String get sailingClearanceStep => 'التصريح بالإبحار والشحن';
  @override String get pendingInspectionCoordination => 'قيد الفحص والتنسيق';
  @override String get completedAndPassedInspection => 'تمت المطابقة';
  @override String get allCertsFulfilled100 => 'مستوفاة بالكامل';
  @override String get pendingApprovals => 'قيد الاعتماد';
  @override String get linkImportFileAndConsultationHeader => 'ربط ملف الشحنة الاستيرادية والاستشارة الجمركية:';
  @override String consultationStudyBadge(dynamic code, dynamic readiness) => 'دراسة الاستشارة: $code (جاهزية $readiness%)';
  @override String get linkedImportFileFieldLabel => 'ملف الشحنة المربوط *';
  @override String get selectImportFileHint => 'اختر ملف الشحنة الاستيرادية...';
  @override String get selectImportFileOption => '-- اختر ملف الشحنة --';
  @override String get acidNotIssued => 'لم يصدر';
  @override String get pleaseSelectImportFileError => 'يرجى اختيار ملف الشحنة';
  @override String get acidNumberFieldLabel => 'رقم القيد الجمركي المسبق للشحنة *';
  @override String get acidNumberRequiredError => 'مطلوب إدخال رقم القيد الجمركي المسبق';
  @override String get foreignSupplierFieldLabel => 'المورد الخارجي / المصنع';
  @override String get foreignSupplierHint => 'المورد الأجنبي...';
  @override String get notSpecifiedOption => '-- غير محدد --';
  @override String prefillImportRequirementSuccess(dynamic count, dynamic code) => '⚡ تم استدعاء بنود التعريفة ($count بند) والمتطلبات تلقائياً للملف $code';
  @override String hsCodesSelectorCardTitle(dynamic count) => 'بنود التعريفة الجمركية المرتبطة بالشحنة — $count بنود مسجلة:';
  @override String totalHsValueBadge(dynamic value, dynamic currency) => 'إجمالي القيمة: $value $currency';
  @override String hsItemCodeLabel(dynamic hs, dynamic item) => '$hs ($item)';
  @override String hsItemDescLabel(dynamic desc, dynamic value, dynamic currency) => '$desc | $value $currency';
  @override String get hsCodeFieldLabel => 'بند التعريفة الجمركية *';
  @override String get hsCodeRequiredError => 'مطلوب إدخال بند التعريفة الجمركية';
  @override String get commodityDescFieldLabel => 'وصف السلعة / الصنف التجاري *';
  @override String get commodityDescRequiredError => 'مطلوب إدخال وصف الصنف';
  @override String get countryOfOriginFieldLabel => 'بلد المنشأ والتصدير *';
  @override String get countryOfOriginRequiredError => 'مطلوب إدخال بلد المنشأ';
  @override String get currencyFieldLabel => 'العملة *';
  @override String get valueInCurrencyFieldLabel => 'القيمة بالعملة *';
  @override String get pillar1Decree43Tab => '١. قرار ٤٣ وتسجيل المصانع';
  @override String get pillar2CooTab => '٢. شهادة المنشأ والاتفاقيات';
  @override String get pillar3InspectionTab => '٣. فحص ما قبل الشحن';
  @override String get pillar4PermitsTab => '٤. موافقات وتصاريح جهات العرض';
  @override String get pillar5TechCertsTab => '٥. الشهادات الفنية وتأكيد الإبحار';
  @override String get pillar1Header => 'المحور الأول: قرار ٤٣ لسنة ٢٠١٦ وتسجيل المصانع المؤهلة بالهيئة';
  @override String get decree43ApplicableCheck => 'يخضع الصنف لقرار ٤٣ لسنة ٢٠١٦ (تسجيل مصانع)';
  @override String get decree43ApplicableSub => 'السلع تامة الصنع والمنتجات الاستهلاكية الواجب قيد مصنعها';
  @override String get whiteListVerifiedCheck => 'المصنع مسجل بالقائمة البيضاء';
  @override String get whiteListVerifiedSub => 'تم التحقق من قيد المصنع بالهيئة العامة للرقابة على الصادرات والواردات';
  @override String get factoryRegNumFieldLabel => 'رقم قيد المصنع بالهيئة';
  @override String get factoryRegNumHint => 'مثال: رقم القيد المعتمد بالهيئة';
  @override String get pillar2Header => 'المحور الثاني: شهادة المنشأ والاتفاقيات التفضيلية';
  @override String get cooRequiredCheck => 'شهادة المنشأ إلزامية';
  @override String get cooTypeFieldLabel => 'نوع شهادة المنشأ';
  @override String get cooTypeEur1Option => 'شهادة يورو ١ (الشراكة الأوروبية / إفتا / تركيا)';
  @override String get cooTypeFormAOption => 'نموذج أ (النظام المعمم للمزايا)';
  @override String get cooTypeGaftaOption => 'شهادة منشأ جامعة الدول العربية (منطقة التجارة العربية الكبرى)';
  @override String get cooTypeComesaOption => 'شهادة الكوميسا (السوق المشتركة لشرق وجنوب إفريقيا)';
  @override String get cooTypeStandardChamberOption => 'شهادة منشأ عادية معتمدة وموثقة من الغرفة التجارية';
  @override String get cooStatusFieldLabel => 'حالة الاستيفاء';
  @override String get cooStatusPendingOption => 'قيد الاستيفاء من المصنع';
  @override String get cooStatusObtainedOption => 'تم الاستلام والتحقق';
  @override String get cooStatusWaivedOption => 'معفاة / مستثناة';
  @override String get cooNotesFieldLabel => 'ملاحظات المنشأ والاتفاقيات التفضيلية والإعفاءات';
  @override String get cooNotesHint => 'مثال: إعفاء جمركي بنسبة ١٠٠٪ طبقاً للاتفاقية';
  @override String get pillar3Header => 'المحور الثالث: فحص ما قبل الشحن والشهادات المعملية';
  @override String get inspectionRequiredCheck => 'شهادة الفحص إلزامية';
  @override String get inspectionBodyFieldLabel => 'جهة الفحص الدولية المعتمدة';
  @override String get inspectionBodySgsOption => 'الشركة العامة للمعاينة';
  @override String get inspectionBodyBvOption => 'بيرو فيريتاس';
  @override String get inspectionBodyTuvOption => 'توف راينلاند';
  @override String get inspectionBodyIntertekOption => 'إنترتك الدولية';
  @override String get inspectionBodyQimaOption => 'كيما لخدمات الفحص';
  @override String get inspectionBodyIlacOption => 'معمل دولي معتمد أيزو';
  @override String get inspectionStatusFieldLabel => 'حالة الفحص';
  @override String get inspectionStatusPendingOption => 'قيد التنسيق والطلب';
  @override String get inspectionStatusScheduledOption => 'تم تحديد موعد المعاينة';
  @override String get inspectionStatusCompletedOption => 'تم الفحص واجتياز المطابقة';
  @override String get inspectionStatusRejectedOption => 'غير مطابق للمواصفات';
  @override String get inspectionReportNumFieldLabel => 'رقم شهادة / تقرير الفحص';
  @override String get inspectionNotesFieldLabel => 'ملاحظات الفحص والنتائج المعملية';
  @override String get pillar4Header => 'المحور الرابع: موافقات وتصاريح جهات العرض والجهات الرقابية المسبقة';
  @override String get importPermitRequiredCheck => 'تصريح مسبق إلزامي';
  @override String get issuingAuthorityFieldLabel => 'جهة العرض والترخيص';
  @override String get authorityEeaaOption => 'جهاز شئون البيئة';
  @override String get authorityNfsaOption => 'الهيئة القومية لسلامة الغذاء';
  @override String get authorityEdaOption => 'هيئة الدواء المصرية';
  @override String get authorityNtraOption => 'الجهاز القومي لتنظيم الاتصالات';
  @override String get authorityPublicSecurityOption => 'الأمن العام / مصلحة الأمن والرقابة';
  @override String get authorityChemistryOption => 'مصلحة الكيمياء / الطاقة الذرية';
  @override String get authorityGoeicOption => 'الهيئة العامة للرقابة على الصادرات والواردات';
  @override String get permitStatusFieldLabel => 'حالة التصريح';
  @override String get permitStatusAppliedOption => 'تم تقديم الطلب';
  @override String get permitStatusApprovedOption => 'تمت الموافقة والاعتماد';
  @override String get permitStatusRejectedOption => 'مرفوض';
  @override String get permitNumberFieldLabel => 'رقم التصريح / الموافقة الرقابية';
  @override String get permitNotesFieldLabel => 'ملاحظات وشروط الموافقة الرقابية';
  @override String get pillar5Header => 'المحور الخامس: الشهادات الفنية الخاصة وتأكيد الجاهزية للإبحار';
  @override String get msdsRequiredCheck => 'شهادة صحيفة بيانات الأمان';
  @override String get halalCertRequiredCheck => 'شهادة الذبح الحلال';
  @override String get coaRequiredCheck => 'شهادة التحليل المخبري';
  @override String get sailingStatusFieldLabel => 'حالة الإبحار والشحن الفعلي';
  @override String get sailingStatusPreSailingOption => 'قبل الإبحار';
  @override String get sailingStatusClearedOption => 'مصرح وجاهز للإبحار';
  @override String get sailingStatusSailedOption => 'تم الإبحار والشحن الفعلي';
  @override String get sailingDateFieldLabel => 'تاريخ الإبحار الفعلي / المتوقع';
  @override String get riskLevelFieldLabel => 'تقييم المخاطر';
  @override String get riskLevelLowOption => 'منخفض';
  @override String get riskLevelMediumOption => 'متوسط';
  @override String get riskLevelHighOption => 'مرتفع';
  @override String get overallStatusDraftOption => 'مسودة';
  @override String get overallStatusInProgressOption => 'قيد الاستيفاء';
  @override String get overallStatusCompleteOption => 'مكتمل';
  @override String get overallStatusConfirmedOption => 'معتمد ومصرح للشحن';
  @override String get completeAllPillarsBtn => 'استيفاء وتأكيد كافة المحاور ⚡';
  @override String get completeAllPillarsSuccessSnack => '⚡ تم استيفاء وتأكيد جاهزية كافة المحاور وتجهيز الشحنة للإبحار!';
  @override String get saveRequirementDraftBtn => 'حفظ مؤقت ومتابعة لاحقة 💾';
  @override String get updateRequirementSubmitBtn => 'تحديث وحفظ التعديلات';
  @override String get saveRequirementSubmitBtn => 'حفظ واعتماد التقييم التأكيدي';
  @override String get fillRequiredFieldsError => 'الرجاء التأكد من تعبئة جميع الحقول المطلوبة.';
  @override String updateRequirementSuccessSnack(dynamic code) => '✅ تم تعديل وحفظ تقييم المتطلبات ($code) بنجاح!';
  @override String get createRequirementSuccessSnack => '✅ تم إنشاء وحفظ تقييم المتطلبات التنظيمية والمطابقة بنجاح!';
  @override String get saveRequirementErrorTitle => 'تنبيه عدم التكرار / خطأ بالحفظ';
  @override String get goToSavedRequirementsBtn => 'الانتقال للسجلات المحفوظة والتعديل عليها';
  @override String get searchRequirementsHint => 'بحث برقم التقييم، البند الجمركي، رقم القيد المسبق، المورد، أو الوصف...';
  @override String get complianceStatusFilterLabel => 'حالة المطابقة';
  @override String get riskLevelFilterLabel => 'مستوى المخاطر';
  @override String get activeDeletedFilterLabel => 'السجلات النشطة / المحذوفة';
  @override String get allRecordsActiveAndDeleted => 'كافة السجلات (النشطة والمحذوفة)';
  @override String get activeOnlyOption => 'النشطة فقط';
  @override String get deletedOnlyOption => 'المحذوفة فقط';
  @override String get noRequirementsFound => 'لا توجد تقييمات مسجلة مطابقة للبحث الحالي.';
  @override String get createNewRequirementBtn => 'إنشاء دراسة تقييم جديدة';
  @override String requirementsFetchError(dynamic error) => 'خطأ في تحميل سجلات التقييم:\n$error';
  @override String get fallbackImportingCompany => 'الشركة المستوردة';
  @override String requirementRowSubtitle(dynamic hs, dynamic desc, dynamic val, dynamic curr, dynamic supp, dynamic origin) => 'البند الجمركي: $hs — $desc | القيمة: $val $curr | المورد: $supp ($origin)';
  @override String sailingStatusBadgeRow(dynamic status) => 'حالة الإبحار: $status';
  @override String requirementStatusBadgeRow(dynamic status) => 'الحالة: $status';
  @override String riskLevelBadgeRow(dynamic risk) => 'المخاطر: $risk';
  @override String hsItemsCountBadge(dynamic count) => '$count بنود تعريفة';
  @override String get decree43VerifiedBadge => 'قرار ٤٣ معتمد';
  @override String get cooObtainedBadge => 'منشأ مستوفى';
  @override String get inspectionPassedBadge => 'فحص معتمد مجتاز';
  @override String get editRequirementTooltip => 'تعديل واستكمال التقييم وإعادة تفعيله';
  @override String loadedRequirementForEditingSnack(dynamic code) => '📂 تم تحميل التقييم ($code) وجاهز للتعديل والمطابقة!';
  @override String get restoreRequirementTooltip => 'استعادة وتفعيل التقييم';
  @override String restoredRequirementSuccessSnack(dynamic code) => '♻️ تم استعادة التقييم ($code) بنجاح!';
  @override String get deleteRequirementTooltip => 'حذف منطقي';
  @override String get confirmDeleteRequirementTitle => 'تأكيد الحذف المنطقي للتقييم';
  @override String confirmDeleteRequirementContent(dynamic code, dynamic file) => 'هل أنت متأكد من حذف تقييم المتطلبات ($code) للملف ($file)؟\n\nيمكنك استعادته أو إعادة تفعيله في أي وقت من خلال تعديله أو عبر زر الاستعادة.';
  @override String deletedRequirementSuccessSnack(dynamic code) => '🗑️ تم حذف التقييم ($code) منطقياً.';

  // ── Screen 44: Demurrage & Detention ───────────────────────────────────────
  @override String get demurrageScreenTitle => 'حاسبة ومتابعة فترات السماح وغرامات الحاويات والأرضيات';
  @override String get containerTrackingsTab => 'جلسات تتبع الحاويات الحية';
  @override String get simulatorAndTierCalcTab => 'محاكي وحاسبة الشرائح التصاعدية';
  @override String get carrierTariffPoliciesTab => 'سياسات تعريفة الخطوط الملاحية';
  @override String get totalActiveTrackingsMetric => 'إجمالي الجلسات النشطة';
  @override String activeShipmentsCount(dynamic count) => '$count شحنة';
  @override String get incurredDemurrageShipmentsMetric => 'شحنات بها غرامات سارية';
  @override String get totalCalculatedDemurrageMetric => 'إجمالي الغرامات المحسوبة';
  @override String get searchDemurrageHint => 'بحث برقم البوليصة أو كود التتبع أو الخط الملاحي...';
  @override String get allStatusesOption => 'جميع الحالات';
  @override String get statusFreeTimeActive => 'فترة السماح سارية';
  @override String get statusDemurrageIncurred => 'غرامة أرضيات سارية';
  @override String get statusDetentionIncurred => 'غرامة تأخير فارغ';
  @override String get statusPushedToSettlement => 'تم الترحيل للتسوية';
  @override String get startNewTrackingBtn => 'بدء تتبع شحنة جديدة';
  @override String get noTrackingsFound => 'لا توجد جلسات تتبع مطابقة للبحث';
  @override String billOfLadingLabel(dynamic blNo) => 'بوليصة: $blNo';
  @override String get dischargeDateLabel => 'تاريخ التفريغ';
  @override String get gateOutDateLabel => 'خروج الميناء';
  @override String get notGatedOutYet => 'لم تخرج بعد';
  @override String get emptyReturnDateLabel => 'إعادة الحاوية الفارغة';
  @override String get notReturnedYet => 'لم تُعد بعد';
  @override String get containersCountLabel => 'عدد الحاويات';
  @override String containersCountValue(dynamic count) => '$count حاوية';
  @override String get totalEstimatedCostLabel => 'إجمالي التكلفة التقديرية';
  @override String get updateGateOutAndReturnDatesBtn => 'تحديث تواريخ الخروج والإعادة';
  @override String get pushToFinancialSettlementBtn => 'ترحيل للتسوية المالية';
  @override String get alreadyPushedToSettlementBtn => 'تم ترحيل المصروف للتسوية';
  @override String get calculationSettingsTitle => 'إعدادات ومحددات الحساب';
  @override String get shippingLineFieldLabel => 'الخط الملاحي';
  @override String get containerTypeFieldLabel => 'نوع الحاوية';
  @override String get containersCountFieldLabel => 'عدد الحاويات';
  @override String get exchangeRateFieldLabel => 'سعر الصرف مقابل الجنيه';
  @override String get grantedFreeDaysHeader => 'فترات السماح الممنوحة';
  @override String get portDemurrageFreeDaysLabel => 'سماح الأرضيات بالميناء (يوم)';
  @override String get emptyReturnFreeDaysLabel => 'سماح إعادة الفارغ (يوم)';
  @override String get operationalMilestonesHeader => 'المحطات الزمنية التشغيلية';
  @override String get vesselDischargeDateMilestone => 'تاريخ تفريغ الحاويات من السفينة';
  @override String get portGateOutDateMilestone => 'تاريخ خروج الحاوية من بوابة الميناء';
  @override String get notGatedOutCalculatedToday => 'لم تخرج بعد (تحتسب حتى اليوم)';
  @override String get emptyReturnToDepotMilestone => 'تاريخ إعادة الحاوية الفارغة لساحة الخط';
  @override String get recalculateDemurrageNowBtn => 'إعادة احتساب الغرامات الآن';
  @override String get initializingSimulationResults => 'جاري تهيئة نتائج المحاكاة...';
  @override String get totalDemurrageCostSummaryTitle => 'ملخص التكلفة الإجمالية للغرامات والأرضيات';
  @override String get demurrageFeeMetric => 'غرامة أرضيات';
  @override String get detentionFeeMetric => 'غرامة تأخير فارغ';
  @override String get portStorageFeeMetric => 'أرضيات الميناء';
  @override String daysOverdueFormatted(dynamic days) => '$days يوم تأخير';
  @override String get totalDueComprehensiveCost => 'إجمالي التكلفة الشاملة المستحقة:';
  @override String egpCurrencyAmount(dynamic amount) => '$amount جنيه مصري';
  @override String get tieredBreakdownTitle => 'تفاصيل الشرائح التصاعدية المطبقة';
  @override String get colCategory => 'البند';
  @override String get colConsumedDays => 'الأيام المستهلكة';
  @override String get colFreeDays => 'أيام السماح';
  @override String get colOverdueDays => 'أيام الغرامة';
  @override String get colFeeAmount => 'قيمة الغرامة';
  @override String daysCountFormatted(dynamic days) => '$days يوم';
  @override String demurrageCategoryLabel(dynamic category) {
    switch (category?.toString()) {
      case 'Demurrage':
        return 'أرضيات الخط الملاحي';
      case 'Detention':
        return 'تأخير إعادة الفارغ';
      case 'Port Storage':
        return 'تخزين ساحات الميناء';
      default:
        return category?.toString() ?? '';
    }
  }
  @override String get carrierTariffPoliciesTitle => 'سياسات وشرائح الخطوط الملاحية المعتمدة';
  @override String get carrierTariffPoliciesSubtitle => 'جداول فترات السماح والشرائح التصاعدية لكل خط ملاحي ونوع حاوية';
  @override String get addCarrierPolicyBtn => 'إضافة سياسة خط ملاحي جديدة';
  @override String get noCarrierPoliciesFound => 'لا توجد سياسات مضافة حالياً. يمكنك الضغط على "إضافة سياسة جديدة" أو استخدام السياسات الافتراضية.';
  @override String currencyLabelFormatted(dynamic curr) => 'العملة: $curr';
  @override String get demurrageFreeLabel => 'سماح الأرضيات';
  @override String get detentionFreeLabel => 'سماح الفارغ';
  @override String get portStorageFreeLabel => 'سماح تخزين الميناء';
  @override String get dailyStorageRateLabel => 'رسم التخزين اليومي';
  @override String egpPerDayFormatted(dynamic rate) => '$rate جنيه/يوم';
  @override String get addTrackingDialogTitle => 'بدء تتبع شحنة وحاويات جديدة';
  @override String get arrivalPortFieldLabel => 'ميناء الوصول';
  @override String get blNumberFieldLabel => 'رقم بوليصة الشحن';
  @override String get containerNumberFieldLabel => 'رقم الحاوية';
  @override String get portDischargeDateTile => 'تاريخ تفريغ الحاويات بالميناء';
  @override String get saveAndStartTrackingBtn => 'حفظ وبدء التتبع';
  @override String get trackingCreatedSuccessSnack => 'تم بدء تتبع الشحنة بنجاح';
  @override String get saveTrackingErrorSnack => 'حدث خطأ أثناء الحفظ';
  @override String updateTrackingDatesDialogTitle(dynamic code) => 'تحديث تواريخ الشحنة ($code)';
  @override String get gateOutDateTile => 'تاريخ خروج الحاوية من الميناء';
  @override String get emptyReturnDateTile => 'تاريخ إعادة الحاوية الفارغة للخط';
  @override String get notRecordedOption => 'غير مسجل';
  @override String get saveAndRecalculateBtn => 'حفظ وإعادة الاحتساب';
  @override String get datesUpdatedAndRecalculatedSuccessSnack => 'تم تحديث التواريخ وإعادة احتساب الغرامات بنجاح';
  @override String get datesUpdateErrorSnack => 'حدث خطأ أثناء التحديث';
  @override String get pushedToSettlementSuccessSnack => 'تم ترحيل المصروف بنجاح إلى ملف التسوية المالية';
  @override String get pushToSettlementErrorSnack => 'حدث خطأ أثناء الترحيل';
  @override String get addPolicyDialogTitle => 'إضافة سياسة خط ملاحي جديدة';
  @override String get demurrageFreeDaysFieldLabel => 'سماح الأرضيات (يوم)';
  @override String get detentionFreeDaysFieldLabel => 'سماح الفارغ (يوم)';
  @override String get portStorageFreeDaysFieldLabel => 'سماح تخزين الميناء (يوم)';
  @override String get dailyStorageRateEgpFieldLabel => 'رسم التخزين اليومي (جنيه)';
  @override String get savePolicyBtn => 'حفظ السياسة';
  @override String get policyCreatedSuccessSnack => 'تمت إضافة السياسة بنجاح';
  @override String get genericErrorSnack => 'حدث خطأ أثناء العملية';
  @override String get requiredFieldValidation => 'حقل مطلوب';
  @override String localizedDemurrageStatus(dynamic status) {
    switch (status?.toString()) {
      case 'Free Time Active':
        return 'فترة السماح سارية';
      case 'Demurrage Incurred':
        return 'غرامة أرضيات سارية';
      case 'Detention Incurred':
        return 'غرامة تأخير فارغ';
      case 'Pushed to Settlement':
        return 'تم الترحيل للتسوية';
      default:
        return status?.toString() ?? '';
    }
  }

  // ── Screen 47: Audit Logs ──────────────────────────────────────────────────
  @override String get auditLogsScreenTitle => 'سجل التدقيق والتتبع التاريخي للنظام';
  @override String get auditLogsScreenSubtitle => 'التتبع الشامل لعمليات وتعديلات النظام وفروق الحقول وسجلات المستخدمين';
  @override String get liveRefreshBtn => 'تحديث حي';
  @override String get filterEntityLabel => 'الكيان:';
  @override String get filterActionLabel => 'نوع العملية:';
  @override String get filterAllOption => 'الكل';
  @override String get auditEntityImportCompany => 'الشركة المستوردة';
  @override String get auditEntitySupplier => 'المورد';
  @override String get auditEntityExternalServiceProvider => 'مقدم الخدمة / البنك';
  @override String get auditEntityUser => 'المستخدم';
  @override String auditEntityLabel(dynamic type) {
    switch (type?.toString()) {
      case 'ImportCompany':
        return 'الشركة المستوردة';
      case 'Supplier':
        return 'المورد الأجنبي';
      case 'ExternalServiceProvider':
        return 'مقدم الخدمة / البنك';
      case 'User':
        return 'المستخدم';
      case 'All':
        return 'الكل';
      default:
        return type?.toString() ?? '';
    }
  }
  @override String get auditActionCreate => 'إضافة';
  @override String get auditActionUpdate => 'تعديل';
  @override String get auditActionDelete => 'حذف';
  @override String get auditActionRestore => 'استعادة';
  @override String auditActionLabel(dynamic action) {
    switch (action?.toString().toUpperCase()) {
      case 'CREATE':
        return 'إضافة';
      case 'UPDATE':
        return 'تعديل';
      case 'DELETE':
        return 'حذف';
      case 'RESTORE':
        return 'استعادة';
      case 'ALL':
        return 'الكل';
      default:
        return action?.toString() ?? '';
    }
  }
  @override String get searchAuditLogsHint => 'بحث في السجلات بكود الكيان، المستخدم، أو تفاصيل التغيير...';
  @override String auditLogsFetchError(dynamic error) => 'خطأ في تحميل سجلات التدقيق:\n$error';
  @override String get noAuditLogsFound => 'لا توجد سجلات تدقيق مطابقة لمعايير البحث الحالية.';
  @override String auditEntityWithCode(dynamic type, dynamic code) => '$type #$code';
  @override String get systemMutationFallback => 'تم تسجيل حركة تعديل بالنظام';
  @override String performedByUser(dynamic user) => 'تم بواسطة: $user';

  // ── Screen 48: Lifecycle Kanban Board ───────────────────────────────────────
  @override String get lifecycleBoardTitle => 'لوحة تتبع ومتابعة مراحل الشحنات التفاعلية المباشرة (6 مراحل / 21 خطوة)';
  @override String get lifecycleBoardSubtitle => 'متابعة مراحل الشحنات التفاعلية المباشرة — اختيار المرحلة لعرض وتحديث جدول الملفات';
  @override String get refreshLiveBoardTooltip => 'تحديث البيانات المباشرة';
  @override String lifecycleBoardError(dynamic error) => 'حدث خطأ أثناء تحميل بيانات اللوحة:\n$error';
  @override String get majorPhasesHeader => 'المستويات الستة الكبرى — اضغط على أي مرحلة لعرض وتحديث شحناتها بالجدول أدناه:';
  @override String totalActiveShipmentsCount(dynamic files, dynamic stages) => 'إجمالي الشحنات: $files ملف ($stages مرحلة)';
  @override String get showAllPhasesBtn => 'عرض كافة المراحل';
  @override String get allShipmentsAllPhases => 'كافة الشحنات في جميع المراحل';
  @override String get searchLifecycleTableHint => 'بحث بكود الشحنة، المورد، أمر الشراء، أو الملاحظات...';
  @override String shipmentsCountFormatted(dynamic count) => '$count شحنة';
  @override String get colShipmentCode => 'كود الشحنة';
  @override String get colCurrentStep => 'الخطوة الحالية';
  @override String get colImportCompany => 'الشركة المستوردة';
  @override String get colForeignSupplier => 'المورد الأجنبي';
  @override String get colPurchaseOrder => 'أمر الشراء';
  @override String get colModeAndIncoterm => 'نوع الشحن والشرط';
  @override String get colEstimatedValue => 'القيمة التقديرية';
  @override String get colNotesAndActivities => 'الملاحظات والأنشطة';
  @override String get colActionsAndAdvance => 'الإجراءات والترحيل';
  @override String get notesUnderFollowupFallback => 'قيد المتابعة التشغيلية';
  @override String get executeAndAdvanceStepBtn => 'تنفيذ وترحيل الخطوة';
  @override String get noShipmentsInStage => 'لا توجد شحنات مسجلة حالياً في هذه المرحلة المحددة';
  @override String get noShipmentsInStageDesc => 'يمكنك اختيار مرحلة أخرى من الأقسام بالأعلى أو إلغاء التصفية لعرض كافة الشحنات.';
  @override String lifecycleStepName(String stepCode) {
    switch (stepCode) {
      case 'STEP_01':
        return 'دراسات النولون';
      case 'STEP_02':
        return 'الدراسات الجمركية';
      case 'STEP_03':
        return 'اشتراطات الاستيراد';
      case 'STEP_04':
        return 'اعتماد الميزانية';
      case 'STEP_05':
        return 'إصدار الرقم المبدئي';
      case 'STEP_06':
        return 'تأكيد الحجز';
      case 'STEP_07':
        return 'تخصيص الحاويات';
      case 'STEP_08':
        return 'مراجعة المسودات';
      case 'STEP_09':
        return 'الاعتماد النهائي للمستندات';
      case 'STEP_10':
        return 'رفع المستندات إلكترونياً';
      case 'STEP_11':
        return 'أصول المستندات والشحن';
      case 'STEP_12':
        return 'النموذج البنكي المعتمد';
      case 'STEP_13':
        return 'إقرار الإجراءات الجمركية';
      case 'STEP_14':
        return 'الكشف والتثمين الجمركي';
      case 'STEP_15':
        return 'سحب وفحص العينات';
      case 'STEP_16':
        return 'محضر المعاينة والأضرار';
      case 'STEP_17':
        return 'سداد الرسوم والضرائب';
      case 'STEP_18':
        return 'الأرضيات وغرامات الحاويات';
      case 'STEP_19':
        return 'إذن الإضافة المخزني';
      case 'STEP_20':
        return 'تسوية التكلفة الإجمالية';
      case 'STEP_21':
        return 'إغلاق وأرشفة الملف';
      default:
        return stepCode;
    }
  }
  @override String lifecyclePhaseName(int phaseId, String fallbackAr, String fallbackEn) {
    switch (phaseId) {
      case 1:
        return 'دراسات الشحن والجمارك';
      case 2:
        return 'اعتماد الميزانية وإجراءات التسجيل';
      case 3:
        return 'الحجز الملاحي ومراجعة المسودات';
      case 4:
        return 'التحويل الرقمي والإجراءات البنكية';
      case 5:
        return 'التخليص الجمركي والكشف والتثمين';
      case 6:
        return 'الاستلام المخزني والتكلفة الإجمالية';
      default:
        return fallbackAr.isNotEmpty ? fallbackAr : fallbackEn;
    }
  }

  // Dialog & Advance / Skip / Hold Actions
  @override String stepActionCardTitle(String stepName) => 'بطاقة تنفيذ الخطوة: $stepName';
  @override String get onHoldStatusTag => 'معلقة مؤقتاً';
  @override String get importFileLabel => 'ملف الشحنة';
  @override String get importingCompanyLabel => 'الشركة المستوردة';
  @override String get foreignSupplierLabel => 'المورد الأجنبي';
  @override String get purchaseOrderLabel => 'أمر الشراء';
  @override String get estimatedValueLabel => 'القيمة التقديرية';
  @override String get currentStepRequirementsHeader => 'بيانات ومتطلبات الخطوة التشغيلية الحالية:';
  @override String get targetNextPhasesHeader => 'المراحل التالية المستهدفة بعد الإنجاز (يمكن اختيار أكثر من مرحلة بالتوازي):';
  @override String get stepNotesHeader => 'ملاحظات وسجل التحديثات لهذه الخطوة:';
  @override String get stepNotesHint => 'اكتب الملاحظات الفنية، التوجيهات أو المرجع التشغيلي...';
  @override String get skipStepBtn => 'تخطي المرحلة';
  @override String get resumeShipmentBtn => 'استئناف الشحنة';
  @override String get holdShipmentBtn => 'إيقاف مؤقت';
  @override String get savingAndAdvancing => 'جاري الحفظ والترحيل...';
  @override String get completeAndAdvanceBtn => 'اكتمال الخطوة وترحيل الشحنة';
  @override String stepAdvanceSuccessSnack(dynamic nextSteps, dynamic fileCode) => 'تم حفظ الخطوة وتفعيل المراحل التالية ($nextSteps) بنجاح للشحنة $fileCode.';
  @override String get stepAdvanceErrorSnack => 'حدث خطأ أثناء حفظ الخطوة. يرجى مراجعة الخادم.';
  @override String get skipStepDialogTitle => 'تخطي هذه المرحلة';
  @override String skipStepConfirmText(dynamic stepName, dynamic fileCode) => 'هل أنت متأكد من تخطي الخطوة ($stepName) للشحنة $fileCode؟';
  @override String get skipReasonLabel => 'سبب التخطي *';
  @override String get skipReasonHint => 'مثال: شحنة شاملة النولون، أو إعفاء نظامي...';
  @override String get skipReasonRequired => 'يلزم إدخال سبب التخطي';
  @override String get confirmSkipAndAdvanceBtn => 'تأكيد التخطي والترحيل';
  @override String stepSkippedSuccessSnack(dynamic nextSteps, dynamic fileCode) => 'تم تخطي الخطوة بنجاح وتفعيل المراحل التالية ($nextSteps) للشحنة $fileCode.';
  @override String get shipmentResumedSuccessSnack => 'تم استئناف الشحنة ومواصلة دورة العمل بنجاح.';
  @override String get holdDialogTitle => 'إيقاف مؤقت / تعليق الشحنة';
  @override String holdConfirmText(dynamic fileCode, dynamic stepName) => 'سيتم تعليق الشحنة $fileCode مؤقتاً عند هذه الخطوة ($stepName).';
  @override String get holdReasonLabel => 'سبب الإيقاف المؤقت *';
  @override String get holdReasonHint => 'مثال: في انتظار موافقة البنك، أو مراجعة مع المورد...';
  @override String get holdReasonRequired => 'يلزم إدخال سبب الإيقاف';
  @override String get confirmHoldBtn => 'تأكيد الإيقاف المؤقت';
  @override String get shipmentHeldSuccessSnack => 'تم تعليق الشحنة مؤقتاً بنجاح.';
  @override String stepParam1Label(String stepCode) {
    switch (stepCode) {
      case 'STEP_01':
        return 'اسم الخط الملاحي / شركة الشحن المعتمدة';
      case 'STEP_02':
        return 'بند التعريفة الجمركية';
      case 'STEP_03':
        return 'جهة العرض والرقابة المطلوبة';
      case 'STEP_04':
        return 'مبلغ الدفعة المعتمدة للمورد';
      case 'STEP_05':
        return 'الرقم التعريفي المبدئي للشحنة';
      case 'STEP_06':
        return 'رقم تأكيد الحجز الملاحي';
      case 'STEP_12':
        return 'رقم النموذج البنكي المعتمد';
      case 'STEP_13':
        return 'رقم شهادة الإجراءات الجمركية';
      case 'STEP_19':
        return 'رقم إذن الإضافة المخزني';
      default:
        return 'المرجع التشغيلي الرئيسي للخطوة';
    }
  }
  @override String stepParam2Label(String stepCode) {
    switch (stepCode) {
      case 'STEP_01':
        return 'سعر النولون البحري للحاوية';
      case 'STEP_02':
        return 'نسبة ضريبة الوارد / الجمارك %';
      case 'STEP_04':
        return 'البنك المعتمد للتحويل';
      case 'STEP_05':
        return 'فترة صلاحية الرقم المبدئي (أيام)';
      case 'STEP_06':
        return 'اسم السفينة الناقلة';
      case 'STEP_12':
        return 'البنك المصدر للنموذج';
      case 'STEP_13':
        return 'جمرك الإفراج المعتمد';
      case 'STEP_19':
        return 'المستودع المستلم';
      default:
        return 'الملاحظة الإجرائية الفرعية';
    }
  }
  @override String stepParam3Label(String stepCode) {
    switch (stepCode) {
      case 'STEP_01':
        return 'مدة الإبحار المتوقعة (أيام)';
      case 'STEP_02':
        return 'نسبة ضريبة القيمة المضافة %';
      case 'STEP_04':
        return 'رقم المرجع المصرفي للتحويل';
      case 'STEP_05':
        return 'رقم تسجيل المصنع الأجنبي';
      case 'STEP_06':
        return 'توزيع الحاويات وعدد الطرود';
      case 'STEP_12':
        return 'القيمة المعتمدة بالنموذج';
      case 'STEP_13':
        return 'اسم المخلص الجمركي المعتمد';
      case 'STEP_19':
        return 'حالة الفحص والاستلام الفعلي';
      default:
        return 'بيانات إضافية';
    }
  }

  // ==========================================
  // Screen 49: Freight Quotations Comparison (FreightQuotationsComparisonScreen)
  // ==========================================
  @override
  String get freightQuotationsComparisonTitle => 'مقارنة عروض أسعار الشحن';
  @override
  String get selectImportFileDropdownLabel => 'اختر ملف الاستيراد لمقارنة عروض الأسعار';
  @override
  String get selectImportFileDropdownHint => 'ابحث برقم الملف، اسم المورد الأجنبي، أو الشركة المستوردة...';
  @override
  String get unknownSupplierFallback => 'مورد غير معروف';
  @override
  String freightQuotesLoadError(String error) => 'حدث خطأ أثناء تحميل عروض الأسعار: $error';
  @override
  String get selectImportFilePrompt => 'الرجاء اختيار ملف استيراد لعرض ومقارنة عروض الأسعار';
  @override
  String get noFreightQuotesForFile => 'لا توجد عروض أسعار مسجلة لهذا الملف';
  @override
  String get notSelectedYet => 'لم يتم الاختيار بعد';
  @override
  String get metricCheapestQuote => 'الأرخص';
  @override
  String get metricFastestQuote => 'الأسرع';
  @override
  String transitDaysCount(dynamic days) => '$days يوم';
  @override
  String get metricCurrentlySelected => 'المختار حالياً';
  @override
  String get badgeBestPrice => 'الأفضل سعراً';
  @override
  String get unknownCarrierFallback => 'غير معروف';
  @override
  String get totalFreightCostLabel => 'إجمالي التكلفة';
  @override
  String get oceanFreightLabel => 'الشحن البحري';
  @override
  String get localChargesLabel => 'مصاريف محلية';
  @override
  String get transitDurationLabel => 'مدة الترانزيت';
  @override
  String get sailingDateLabel => 'تاريخ الإبحار';
  @override
  String get estimatedArrivalDateLabel => 'تاريخ الوصول المتوقع';
  @override
  String get remarksLabel => 'ملاحظات:';
  @override
  String get quoteAwardedBtn => 'تم الاختيار';
  @override
  String get awardQuoteBtn => 'اختيارها';
  @override
  String get freightQuoteSelectedSuccess => 'تم اختيار عرض السعر بنجاح';
  @override
  String get freightQuoteAwardedSuccess => 'تم اختيار واعتماد عرض السعر بنجاح';
  @override
  String freightQuoteAwardError(String error) => 'خطأ في اعتماد العرض: $error';

  // ==========================================
  // Screen 50: Landed Cost Comparison (LandedCostComparisonScreen)
  // ==========================================
  @override
  String landedCostComparisonTitle(dynamic fileCode) => 'مقارنة تكلفة الوصول الشاملة — تقديري مقابل فعلي [$fileCode]';
  @override
  String landedCostLoadError(dynamic error) => 'حدث خطأ أثناء تحميل بيانات التكلفة: $error';
  @override
  String get noLandedCostDataRegistered => 'لم يتم تسجيل بيانات تكلفة الوصول الشاملة بعد لهذا الملف';
  @override
  String get expenseBreakdownHeader => 'تفاصيل وبنود المصروفات الفعلية';
  @override
  String get itemLandedCostHeader => 'تكلفة الأصناف بعد توزيع المصروفات';
  @override
  String get estimatedCostHeader => 'التكلفة التقديرية';
  @override
  String get actualCostHeader => 'التكلفة الفعلية';
  @override
  String get fobValueCardTitle => 'قيمة البضاعة فوب';
  @override
  String get totalExpensesCardTitle => 'إجمالي المصروفات الإضافية';
  @override
  String get totalLandedCostCardTitle => 'إجمالي تكلفة الوصول الشاملة';
  @override
  String get estAbbreviation => 'تقديري';
  @override
  String get actAbbreviation => 'فعلي';
  @override
  String get colExpenseCategory => 'الفئة';
  @override
  String get colExpenseProvider => 'مقدم الخدمة / المورد';
  @override
  String get colExpenseCurrency => 'العملة';
  @override
  String get colExpenseAmountFx => 'القيمة بالعملة الأجنبية';
  @override
  String get colExpenseExchangeRate => 'سعر الصرف';
  @override
  String get colExpenseAmountEgp => 'القيمة بالجنيه المصري';
  @override
  String get colItemCode => 'كود الصنف';
  @override
  String get colItemName => 'اسم الصنف';
  @override
  String get colItemQty => 'الكمية';
  @override
  String get colFobUnitPrice => 'سعر الوحدة فوب';
  @override
  String get colLandedUnitPrice => 'تكلفة الوحدة الإجمالية الواصلة';
  @override
  String get colCostMarkupFactor => 'معامل التكلفة';
  @override
  String landedCostOverBudgetBanner(dynamic percent) => 'تجاوزت التكلفة الفعلية الميزانية التقديرية بنسبة $percent%';
  @override
  String landedCostUnderBudgetBanner(dynamic percent) => 'وفر المشروع $percent% من الميزانية التقديرية المعتمدة';
  @override
  String expenseCategoryName(String category) {
    switch (category.toLowerCase()) {
      case 'freight':
        return 'نولون وشحن';
      case 'customs':
        return 'جمارك وضرائب';
      case 'clearance':
        return 'أتعاب تخليص';
      case 'transport':
        return 'نقل وتعتيق داخلي';
      case 'storage':
        return 'أرضيات وتخزين';
      default:
        return 'مصروفات أخرى';
    }
  }

  // ==========================================
  // Screen 51: Central Docs Hub (CentralDocsArchiveScreen)
  // ==========================================
  @override
  String get centralDocsArchiveTitle => 'الأرشيف المركزي لمستندات وتعديلات الشحنة';
  @override
  String get closeAndReturn => 'إغلاق والعودة';
  @override
  String get selectCentralArchiveFileLabel => 'اختر ملف الشحنة للاستعراض المركزي';
  @override
  String get selectCentralArchiveFileHint => 'ابحث برقم الملف أو اسم المستورد أو المورد...';
  @override
  String get refreshArchiveBtn => 'تحديث الأرشيف';
  @override
  String get selectShipmentFilePrompt => 'يرجى اختيار ملف شحنة من القائمة أعلاه';
  @override
  String get centralArchivePlaceholderDesc => 'سيتم استعراض الفاتورة النهائية، قائمة التعبئة، مسودة البوليصة، مسودة شهادة المنشأ، شهادة الفحص، وملخص التعديلات فوراً.';
  @override
  String get centralArchiveLoadingPrompt => 'جارٍ جلب وتجميع الأرشيف المركزي ومطابقة المستندات...';
  @override
  String centralArchiveLoadError(dynamic error) => 'خطأ أثناء جلب بيانات الأرشيف: $error';
  @override
  String get readinessReadyForRelease => 'جاهز تماماً للإفراج والرفع على كارجو إكس';
  @override
  String get readinessActionRequired => 'يتطلب تصحيحات وتعديلات حاسمة قبل إصدار الأصول';
  @override
  String get readinessInReview => 'قيد استكمال ومراجعة مسودات المستندات';
  @override
  String fileCodeLabel(dynamic code) => 'كود الملف: $code';
  @override
  String customsFileNumberLabel(dynamic num) => 'رقم الملف الجمركي: $num';
  @override
  String get importerCompanyLabel => 'الشركة المستوردة:';
  @override
  String get exporterSupplierLabel => 'المورد الأجنبي / المصدر:';
  @override
  String get acidNumberLabel => 'رقم القيد الجمركي (اسيد):';
  @override
  String get shippingRouteLabel => 'مسار الشحن (ميناء الشحن إلى ميناء التفريغ):';
  @override
  String get totalPackagesAndWeightLabel => 'إجمالي الطرود والوزن:';
  @override
  String get totalInvoiceValueLabel => 'القيمة الإجمالية:';
  @override
  String packagesCountText(dynamic pkgs, dynamic weight) => '$pkgs طرد | $weight كجم';
  @override
  String get complianceReportHeader => 'تقرير مطابقة متطلبات الاستيراد والرقابة النوعية';
  @override
  String complianceSummaryTag(dynamic origin, dynamic hsCode, dynamic commodity) => 'المنشأ: $origin | بند التعريفة: $hsCode | $commodity';
  @override
  String get chipCooLabel => 'شهادة المنشأ';
  @override
  String cooRequiredText(dynamic type) => 'مطلوبة ($type)';
  @override
  String get cooNotRequiredText => 'معفاة وغير مطلوبة';
  @override
  String get chipVocLabel => 'فحص ما قبل الشحن';
  @override
  String inspRequiredText(dynamic agency) => 'مطلوب ($agency)';
  @override
  String get inspNotRequiredText => 'غير خاضع للرقابة';
  @override
  String get chipDecree43Label => 'قرار ثلاثة وأربعين وتسجيل المصنع';
  @override
  String get decree43WhiteListed => 'مسجل بالقائمة البيضاء';
  @override
  String get decree43RegistrationRequired => 'يلزم قيد المصنع';
  @override
  String get decree43NotApplicable => 'غير خاضع';
  @override
  String get masterRectificationsHeader => 'ملخص التعديلات والفروق المطلوبة الصريحة:';
  @override
  String get copySupplierEmailBtn => 'نسخ إيميل التعديلات للمورد';
  @override
  String get copySupplierEmailSuccess => 'تم نسخ إيميل التعديلات للمورد بنجاح';
  @override
  String get copyWhatsAppBtn => 'نسخ رسالة واتساب';
  @override
  String get copyWhatsAppSuccess => 'تم نسخ رسالة واتساب السريعة بنجاح';
  @override
  String get noDiscrepanciesSuccessMessage => 'لا توجد أي فروق أو تعديلات مطلوبة. كافة المسودات مطابقة تماماً وجاهزة للإفراج والرفع على كارجو إكس.';
  @override
  String get severityCritical => 'حرج مانع للإفراج';
  @override
  String get severityWarning => 'تنبيه تحذيري';
  @override
  String discrepancyIssueLabel(dynamic issue) => 'الملاحظة: $issue';
  @override
  String discrepancyRectificationLabel(dynamic rect) => 'التعديل المطلوب: $rect';
  @override
  String get fiveCoreDocsSectionTitle => 'أرشيف المستندات الخمسة المعتمدة وتفاصيل التعديلات لكل وثيقة:';
  @override
  String get docTitleCommercialInvoice => '١. الفاتورة التجارية النهائية المعتمدة';
  @override
  String get docTitlePackingList => '٢. قائمة التعبئة النهائية المعتمدة';
  @override
  String get docTitleBillOfLading => '٣. مسودة بوليصة الشحن البحرية';
  @override
  String get docTitleCertificateOfOrigin => '٤. مسودة شهادة المنشأ';
  @override
  String get docTitleInspectionCertificate => '٥. مسودة شهادة الفحص والمطابقة النوعية';
  @override
  String get docMandatoryCore => 'إلزامي حتمي';
  @override
  String get docConditional => 'شرطي وحسب البند';
  @override
  String docReferenceLabel(dynamic ref) => 'المرجع: $ref';
  @override
  String get docStatusWaived => 'معفاة وغير مطلوبة';
  @override
  String get docStatusApproved => 'معتمد بنجاح';
  @override
  String get docStatusModificationsRequested => 'مطلوب تعديلات';
  @override
  String get docStatusReviewPending => 'قيد التدقيق';
  @override
  String get docStatusNotStarted => 'غير مدرج بعد';
  @override
  String get docModificationsRequestedTitle => 'التعديلات المطلوبة لهذا المستند:';
  @override
  String get docWaivedDefaultDesc => 'هذا المستند غير مطلوب ومعفى قانونياً ولا يؤثر على جاهزية الإفراج.';
  @override
  String get docNoDiscrepanciesDesc => 'هذا المستند لا يحتوي على أي ملاحظات أو فروق.';

  // Screen 53: Draft Inspection COC (ShipmentDraftDocsScreen & InspectionReviewTab)
  @override
  String get inspStepRequirements => 'متطلبات شهادة الفحص والمطابقة';
  @override
  String get inspStepDraftInput => 'إدخال واستخراج الدرافت';
  @override
  String get inspStepDiscrepancyMatrix => 'مصفوفة المقارنة والفروق';
  @override
  String get inspStepRegistry => 'سجل شهادات الفحص المعتمدة';
  @override
  String existingInspectionReviewBanner(dynamic code, dynamic status) =>
      'توجد دراسة مسجلة مسبقاً لهذا الملف [كود الجلسة: $code - الحالة: $status]. سيتم تحديث وتعديل نفس الدراسة المعتمدة لضمان عدم تكرار السجلات.';
  @override
  String get inspectionRegistryBtn => 'سجل الشهادات';
  @override
  String get inspRequirementsHeader => 'توليد متطلبات شهادة الفحص المسبق قبل الشحن';
  @override
  String get selectInspectionFileLabel => 'اختر ملف الشحنة *';
  @override
  String get selectInspectionFileHint => 'ابحث برقم الملف...';
  @override
  String get inspectionCertTypeLabel => 'نوع شهادة الفحص *';
  @override
  String get inspectionCertTypeHint => 'اختر نوع الفحص...';
  @override
  String get optInspectionCoc => 'شهادة المطابقة النوعية';
  @override
  String get optInspectionCoa => 'شهادة التحليل المخبري';
  @override
  String get optInspectionVoc => 'التحقق من المطابقة';
  @override
  String get optInspectionPsi => 'تقرير المعاينة قبل الشحن';
  @override
  String get inspectionAgencyLabel => 'جهة الفحص الدولية *';
  @override
  String get inspectionAgencyHint => 'اختر جهة الفحص...';
  @override
  String get openInspectionPreviewBtn => 'فتح المعاينة والتصدير';
  @override
  String get nextInspectionInputBtn => 'التالي: إدخال الدرافت';
  @override
  String inspectionVisualPreviewDialogTitle(dynamic agency, dynamic certType) =>
      'المعاينة المصورة لمسودة شهادة الفحص: $agency ($certType)';
  @override
  String get applyInspectionDraftDataBtn => 'اعتماد وتعبئة الحقول تلقائياً';
  @override
  String get inspectionDraftDataAppliedSuccess => 'تم ملء بيانات درافت شهادة الفحص بنجاح';
  @override
  String get inspDraftInputHeader => 'إدخال واستخراج بيانات درافت شهادة الفحص';
  @override
  String get runInspectionComparisonBtn => 'تشغيل المطابقة';
  @override
  String get linkedInspectionFileLabel => 'اختر ملف الشحنة المربوط *';
  @override
  String get linkedInspectionFileHint => 'ابحث برقم الملف أو اسم الشركة...';
  @override
  String get pleaseSelectInspectionFileWarning =>
      'يرجى اختيار وتحديد ملف الشحنة أولاً حتى يتم استخراج البيانات ومقارنتها بسجلات النظام.';
  @override
  String get certNumberFieldLabel => 'رقم درافت الشهادة *';
  @override
  String get regulatoryAuthorityFieldLabel => 'الجهة الرقابية المصرية المختصة *';
  @override
  String get inspectedInvoiceNumberFieldLabel => 'رقم الفاتورة الخاضعة للفحص *';
  @override
  String get exporterShipperFieldLabel => 'اسم المصدر / الشاحن *';
  @override
  String get importerApplicantFieldLabel => 'اسم المستورد / طالب الفحص *';
  @override
  String get standardSpecFieldLabel => 'المواصفة القياسية المعتمدة *';
  @override
  String get smartUploadInspectionBtn => 'رفع واستخراج شهادة الفحص الذكي';
  @override
  String get rawTextInspectionHeader => 'النص الخام لدرافت شهادة الفحص';
  @override
  String get smartExtractFromTextBtn => 'استخراج ومطابقة ذكية من النص';
  @override
  String get rawTextInspectionHint => 'الصق النص الكامل لشهادة الفحص هنا...';
  @override
  String get pleaseSelectFileFirstPrompt => 'يرجى اختيار ملف الشحنة أولاً';
  @override
  String inspectionComparisonError(dynamic err) => 'خطأ أثناء المقارنة: $err';
  @override
  String get overrideReasonMandatoryWarning =>
      'يجب كتابة سبب ومبرر الموافقة على الاختلافات قبل الاعتماد والحفظ، أو الضغط على العودة للتعديل ومخاطبة المورد.';
  @override
  String get saveInspectionReviewSuccess => 'تم حفظ جلسة مراجعة شهادة الفحص بنجاح بالسجل';
  @override
  String saveInspectionReviewError(dynamic err) => 'خطأ في الحفظ: $err';
  @override
  String get generateDraftSelectFileFirstPrompt => 'يرجى اختيار ملف الشحنة أولاً لتوليد درافت شهادة الفحص';
  @override
  String get cancelAndClose => 'إلغاء وإغلاق';
  @override
  String get exportPdfBtn => 'تصدير التقرير';
  @override
  String get exportExcelBtn => 'تصدير جدول البيانات';
  @override
  String generateDraftError(dynamic err) => 'خطأ أثناء توليد المسودة: $err';
  @override
  String get pasteRawTextFirstPrompt => 'يرجى لصق نص شهادة الفحص أو رفع الملف أولاً';
  @override
  String inspectionOcrWarningsAlert(dynamic warnings) => 'تنبيهات الاستخراج: $warnings';
  @override
  String get inspectionDraft48hWarningAlert =>
      'تم اكتشاف مسودة — يرجى تأكيد الفحص خلال مهلة الـ 48 ساعة لتفادي رفض الإفراج.';
  @override
  String get inspectionExtractionSuccess => 'تم استخراج ومطابقة بيانات شهادة الفحص والمطابقة بنجاح';
  @override
  String get mustSelectFileForMatrixWarning => 'يجب اختيار ملف الشحنة أولاً لعرض مصفوفة المقارنة';
  @override
  String get returnToSelectFileBtn => 'العودة لاختيار الملف';
  @override
  String get pleaseRunComparisonPrompt => 'يرجى تشغيل المطابقة في الخطوة السابقة لاستعراض مصفوفة الفروق';
  @override
  String get returnToRunComparisonBtn => 'العودة لتشغيل المطابقة';
  @override
  String get hasCriticalMismatchStatus => 'توجد اختلافات حرجة في بيانات شهادة الفحص';
  @override
  String get hasMinorDiscrepanciesStatus => 'توجد فروق طفيفة في بيانات شهادة الفحص';
  @override
  String get inspectionConforms100Status => 'شهادة الفحص مطابقة تماماً بنسبة 100%';
  @override
  String get exportingInspectionPdfPrompt => 'جارٍ تصدير تقرير مطابقة شهادة الفحص...';
  @override
  String get copiedInspectionExcelSuccess => 'تم نسخ وتصدير بيانات المطابقة إلى جدول البيانات بنجاح';
  @override
  String get saveToInspectionRegistryBtn => 'حفظ بالسجل';
  @override
  String get colInspField => 'الحقل';
  @override
  String get colInspSystemValue => 'القيمة بالنظام';
  @override
  String get colInspDraftValue => 'القيمة بالدرافت';
  @override
  String get colInspMatchStatus => 'حالة التطابق';
  @override
  String get colInspDetails => 'التفاصيل';
  @override
  String get inspOverrideReasonBoxTitle => 'سبب ومبررات الموافقة على الاختلافات (إلزامي للاعتماد والحفظ):';
  @override
  String get inspOverrideReasonBoxDesc =>
      'عند وجود فروق أو اختلافات في شهادة الفحص والمطابقة، يجب تسجيل سبب الموافقة والاعتماد، أو الضغط على العودة للتعديل ومخاطبة المورد.';
  @override
  String get inspOverrideReasonFieldLabel => 'سبب ومبرر الموافقة على الاختلافات *';
  @override
  String get inspOverrideReasonFieldHint => 'اكتب مبررات قبول الاختلافات هنا قبل الحفظ...';
  @override
  String get approveAndSaveWithReasonBtn => 'اعتماد وحفظ مع ذكر سبب الموافقة';
  @override
  String get returnToEditAndContactSupplierBtn => 'العودة لتعديل المسودة ومخاطبة المورد';
  @override
  String inspReviewsRegistryTitle(dynamic count) => 'سجل مراجعات واعتماد شهادات الفحص والتفتيش ($count جلسة)';
  @override
  String get startNewInspReviewBtn => 'بدء مراجعة جديدة';
  @override
  String get noInspReviewsYet => 'لا توجد جلسات مراجعة مسجلة لشهادات الفحص حتى الآن.';
  @override
  String get colInspSessionCode => 'كود الجلسة';
  @override
  String get colInspCertType => 'نوع الفحص';
  @override
  String get colInspAgency => 'جهة الفحص';
  @override
  String get colInspCertNo => 'رقم الشهادة';
  @override
  String get colInspStatus => 'الحالة';
  @override
  String get colInspCreatedAt => 'تاريخ الإنشاء';
  @override
  String get colInspActions => 'الإجراءات';
  @override
  String get editInspSessionTooltip => 'تعديل الجلسة';
  @override
  String get viewInspDetailsTooltip => 'معاينة التفاصيل';
  @override
  String get downloadInspPdfTooltip => 'تنزيل التقرير';
  @override
  String get deleteInspSessionTooltip => 'حذف الجلسة';
  @override
  String loadedInspSessionForEdit(dynamic code) => 'تم تحميل بيانات الجلسة ($code) للتعديل';
  @override
  String inspDetailsDialogTitle(dynamic code) => 'تفاصيل جلسة مراجعة شهادة الفحص: $code';
  @override
  String get tileInspTypeAndAgency => 'نوع الفحص والجهة المصدرة';
  @override
  String get tileInspCertNoAndStatus => 'رقم الشهادة والحالة';
  @override
  String get tileInspOverrideReason => 'سبب ومبرر الموافقة على الاختلافات';
  @override
  String get sectionInspDiscrepancyMatrix => 'مصفوفة الفروق والمطابقة:';
  @override
  String get confirmDeleteInspSessionTitle => 'تأكيد حذف جلسة مراجعة الفحص';
  @override
  String confirmDeleteInspSessionContent(dynamic code, dynamic cert) =>
      'هل أنت متأكد من حذف جلسة المراجعة رقم ($code) لشهادة ($cert)؟';
  @override
  String get inspSessionDeletedSuccess => 'تم حذف جلسة مراجعة الفحص بنجاح';
  @override
  String deleteInspSessionError(dynamic err) => 'خطأ في الحذف: $err';
  @override
  String visualDraftInspectionToolbarTitle(dynamic agency, dynamic certType) =>
      'مسودة شهادة الفحص والمطابقة: $agency ($certType)';
  @override
  String get liveRefreshTooltip => 'تحديث حي للبيانات المستدعاة';
  @override
  String get copyInspectionDataBtn => 'نسخ البيانات';
  @override
  String get copiedInspectionDataSuccess => 'تم نسخ بيانات شهادة الفحص إلى الحافظة';
  @override
  String get saveExcelCsvBtn => 'حفظ جدول البيانات';
  @override
  String get excelReadySuccess => 'تم تجهيز بيانات جدول البيانات لشهادة الفحص بنجاح';
  @override
  String get savePrintPdfBtn => 'حفظ وطباعة التقرير';
  @override
  String get egyptVerificationOfConformityHeader => 'التحقق الإلزامي من المطابقة في مصر';
  @override
  String get countryOfOriginHeader => 'بلاد المنشأ المستدعاة:';
  @override
  String get hsCodesHeader => 'بنود التعريفة الجمركية:';
  @override
  String get commercialInvoicesHeader => 'الفواتير التجارية المرفقة الخاضعة للفحص:';
  @override
  String get colInvoiceAmountCurrency => 'القيمة والعملة';
  @override
  String get colInvoiceNo => 'رقم الفاتورة';
  @override
  String get colInvoiceDate => 'تاريخ الفاتورة';
  @override
  String get colIncoterm => 'الشرط التجاري';
  @override
  String methodOfShipmentLabel(dynamic val) => 'طريقة الشحن: $val';
  @override
  String countryOfShipmentLabel(dynamic val) => 'بلد الشحن: $val';
  @override
  String pointOfEntryLabel(dynamic val) => 'ميناء الوصول: $val';
  @override
  String totalDeclaredValueLabel(dynamic val) => 'القيمة الإجمالية المصرح عنها: $val';
  @override
  String get inspectedItemsHeader => 'بنود البضائع والمواصفات المعتمدة:';
  @override
  String get colItemNo => 'م';
  @override
  String get colQuantity => 'الكمية';
  @override
  String get colOrigin => 'المنشأ';
  @override
  String get colProductType => 'نوع المنتج';
  @override
  String get colDescriptionBrandModel => 'الوصف (الماركة / الموديل)';
  @override
  String get colAdoptedStandard => 'المواصفة المعتمدة';
  @override
  String placeOfInspectionLabel(dynamic val) => 'مكان الفحص: $val';
  @override
  String dateOfInspectionLabel(dynamic val) => 'تاريخ الفحص: $val';
  @override
  String issuingOfficeLabel(dynamic val) => 'المكتب المصدر: $val';
  @override
  String get egyptianMandatoryStandardsHeader => 'المواصفات القياسية المصرية وبروتوكولات الفحص:';
  @override
  String get conformityAssessmentResultConforming => 'نتيجة تقييم المطابقة: مطابق وصالح للإفراج الجمركي';
  @override
  String authorizedAgencyLabel(dynamic val) => 'الجهة المعتمدة: $val';
  @override
  String get egyptianCustomsComplianceHeader => 'الامتثال الجمركي والرقابي المصري';
  @override
  String get importerCellLabel => 'المستورد (الاسم، العنوان والرقم الضريبي):';
  @override
  String get exporterCellLabel => 'المصدر والمصنع (الاسم والعنوان):';

  // ── Screen 54: CargoX Blockchain Hub & Standard Commercial Invoice ──────────
  @override
  String get cargoxHubTitle => 'منظومة كارجو إكس والبلوك تشين والمانيفست الرقمي';
  @override
  String get cargoxLiveRefreshTooltip => 'تحديث حي';
  @override
  String get cargoxEmbeddedTitle => 'منظومة كارجو إكس والبلوك تشين:';
  @override
  String get cargoxTabStandardInvoice => 'الفاتورة المعيارية والمطابقة';
  @override
  String get cargoxTabCreateEnvelope => 'تجهيز وتوليد المظروف';
  @override
  String get cargoxTabTrackingHub => 'مركز تتبع أظرف البلوك تشين';
  @override
  String get cargoxTabManifestViewer => 'معاينة وتصدير المانيفست الرقمي';
  @override
  String get cargoxSegStandardInvoice => 'الفاتورة المعيارية';
  @override
  String get cargoxSegCreateEnvelope => 'تجهيز المظروف';
  @override
  String get cargoxSegTrackingHub => 'تتبع البلوك تشين';
  @override
  String get cargoxSegManifestViewer => 'المانيفست الرقمي';

  // Tab 1: Envelope Creation
  @override
  String get cargoxEnvelopeGenTitle => 'تجهيز وتوليد مظروف كارجو إكس المشفر';
  @override
  String get cargoxEnvelopeGenDesc => 'يتم إنشاء المظروف الرقمي وتوقيعه إلكترونياً بالتشفير الرقمي وربطه برقم القيد الجمركي ومستندات الشحن المعتمدة قبل التحويل لمصلحة الجمارك المصرية.';
  @override
  String get cargoxSection1ShipmentAcid => '١. بيانات الشحنة والربط مع منظومة التسجيل المسبق للشحنات:';
  @override
  String get cargoxImportFileField => 'ملف الشحنة الاستيرادية *';
  @override
  String get cargoxSearchFileHint => 'ابحث عن ملف الشحنة...';
  @override
  String get cargoxUnlinkedOption => '-- غير مرتبط بملف شحنة --';
  @override
  String get cargoxAcidNumberField => 'رقم القيد الجمركي المسبق (١٩ رقماً) *';
  @override
  String get cargoxAcidValidationDigits => 'يجب أن يتكون من ١٩ رقماً';
  @override
  String get cargoxBlNumberField => 'رقم بوليصة الشحن';
  @override
  String get cargoxImporterCompanyField => 'الشركة المستوردة *';
  @override
  String get cargoxForeignSupplierField => 'المورد الأجنبي *';
  @override
  String get cargoxSupplierCargoxIdField => 'معرف منصة كارجو إكس للمورد *';
  @override
  String get cargoxSection2AttachedDocs => '٢. قائمة المستندات المحملة داخل المظروف:';
  @override
  String get cargoxRestoreDefaultDocsBtn => 'استعادة القائمة القياسية';
  @override
  String get cargoxColDocType => 'نوع المستند';
  @override
  String get cargoxColDocNumber => 'رقم المرجع';
  @override
  String get cargoxColFileName => 'اسم الملف';
  @override
  String get cargoxColFileSize => 'الحجم (كيلوبايت)';
  @override
  String get cargoxColAcidMatch => 'مطابقة القيد الجمركي';
  @override
  String get cargoxColActions => 'حذف';
  @override
  String get cargoxDocMatchedBadge => 'مطابق بنسبة مئة بالمئة';
  @override
  String get cargoxAddDocToEnvelopeBtn => 'إضافة مستند جديد للمظروف';
  @override
  String get cargoxAddDocDialogTitle => 'إضافة مستند جديد للمظروف';
  @override
  String get cargoxDocTypeField => 'نوع المستند *';
  @override
  String get cargoxDocNumberField => 'رقم المستند';
  @override
  String get cargoxDocFileNameField => 'اسم الملف *';
  @override
  String get cargoxAddDocSubmitBtn => 'إضافة للمظروف';
  @override
  String get cargoxGenerateAndSignEnvelopeBtn => 'توليد وتوقيع مظروف كارجو إكس بالبلوك تشين';
  @override
  String get cargoxAtLeastOneDocError => 'يرجى إضافة مستند واحد على الأقل داخل المظروف';
  @override
  String cargoxEnvelopeCreatedSuccess(dynamic code) => 'تم توليد وتوقيع مظروف كارجو إكس بنجاح ($code)';
  @override
  String get cargoxEnvelopeCreateError => 'خطأ أثناء إنشاء المظروف';

  // Tab 2: Tracking Hub
  @override
  String get cargoxMetricTotalEnvelopes => 'إجمالي المظاريف';
  @override
  String get cargoxMetricAcceptedCustoms => 'تم قبولها بالجمارك';
  @override
  String get cargoxMetricInProgress => 'قيد المعالجة والرفع';
  @override
  String get cargoxMetricAcidVerified => 'مطابقة القيد الجمركي بالكامل';
  @override
  String get cargoxSearchEnvelopesHint => 'ابحث برقم المظروف، رقم القيد، المورد، أو البوليصة...';
  @override
  String get cargoxFilterAllStatuses => 'جميع الحالات';
  @override
  String get cargoxFilterDraft => 'مسودة';
  @override
  String get cargoxFilterUploaded => 'مرفوع بالبلوك تشين';
  @override
  String get cargoxFilterAccepted => 'مقبول بالجمارك';
  @override
  String get cargoxPrepareNewEnvelopeBtn => 'تجهيز مظروف جديد';
  @override
  String get cargoxNoEnvelopesFound => 'لا توجد مظاريف مطابقة لشروط البحث';
  @override
  String get cargoxMetaAcidNumber => 'رقم القيد الجمركي المسبق:';
  @override
  String get cargoxMetaSupplier => 'المورد الأجنبي:';
  @override
  String get cargoxMetaSupplierCargoxId => 'معرف كارجو إكس للمورد:';
  @override
  String get cargoxMetaBlNumber => 'رقم البوليصة:';
  @override
  String get cargoxMetaPendingIssuance => 'قيد الإصدار';
  @override
  String get cargoxMetaBlockchainTxHash => 'معرّف المعاملة بالبلوك تشين:';
  @override
  String get cargoxMetaCustomsReceipt => 'إيصال الجمارك:';
  @override
  String get cargoxCopiedToClipboard => 'تم النسخ إلى الحافظة بنجاح';
  @override
  String get cargoxCheckAcidBtn => 'فحص القيد الجمركي';
  @override
  String get cargoxDigitalManifestBtn => 'المانيفست الرقمي';
  @override
  String get cargoxSealAndTransferBtn => 'إغلاق وتحويل للجمارك';
  @override
  String get cargoxDeliveredAndAcceptedBadge => 'تم التسليم والاعتماد الجمركي';
  @override
  String cargoxAcidReportDialogTitle(dynamic code) => 'تقرير مطابقة القيد الجمركي ($code)';
  @override
  String cargoxTargetAcidLabel(dynamic acid) => 'رقم القيد الجمركي المستهدف: $acid';
  @override
  String cargoxMatchRatioLabel(dynamic match, dynamic total) => 'نسبة المطابقة: $match من إجمالي $total مستندات';
  @override
  String get cargoxConfirmSealTransferTitle => 'تأكيد الإغلاق والتحويل للجمارك';
  @override
  String cargoxConfirmSealTransferContent(dynamic code) => 'هل أنت متأكد من إغلاق المظروف ($code) وتوقيعه رقمياً وتحويله لمنظومة نافذة والجمارك المصرية؟';
  @override
  String get cargoxConfirmTransferBtn => 'تأكيد التحويل الجمركي';
  @override
  String cargoxSealSuccessSnackbar(dynamic msg, dynamic receipt) => '$msg (إيصال: $receipt)';
  @override
  String get cargoxAcidCheckError => 'خطأ أثناء فحص القيد الجمركي';
  @override
  String get cargoxTransferError => 'خطأ أثناء تحويل المظروف للجمارك';
  @override
  String get cargoxFetchManifestError => 'خطأ أثناء جلب المانيفست الرقمي';

  // Tab 3: Manifest Viewer
  @override
  String cargoxManifestTitle(dynamic code, dynamic acid) => 'المانيفست الرقمي الرسمي: $code (رقم القيد: $acid)';
  @override
  String get cargoxCopyJsonBtn => 'نسخ البيانات الرقمية';
  @override
  String get cargoxManifestCopiedToast => 'تم نسخ المانيفست الرقمي إلى الحافظة بنجاح';
  @override
  String get cargoxSelectEnvelopeForManifestPrompt => 'يرجى اختيار مظروف من مركز التتبع لعرض المانيفست الرقمي الخاص به';

  // Standard Commercial Invoice Hub SubTab
  @override
  String get standardInvoiceHubTitle => 'مركز إدارة وتوليد الفاتورة التجارية المعيارية';
  @override
  String get standardInvoiceHubDesc => 'توليد نموذج إكسيل الموحد ذو النطاقات المسمّاة، مطابقة بيانات المورد آلياً، واكتشاف الفروق الجمركية قبل إرسال المظروف لكارجو إكس ونافذة.';
  @override
  String get standardInvoiceFileSelectorLabel => 'اختيار ملف الشحنة الاستيرادية *';
  @override
  String get standardInvoiceFileSelectorHint => 'ابحث برقم الملف، رقم القيد الجمركي، اسم المورد أو الشركة...';
  @override
  String get standardInvoiceFetchError => 'خطأ في تحميل ملفات الشحن:';
  @override
  String standardInvoiceExistingSessionTitle(dynamic code) => 'تم العثور على دراسة ومطابقة سابقة محفوظة لهذه الشحنة برقم: [$code]';
  @override
  String standardInvoiceExistingSessionSubtitle(dynamic date, dynamic status, dynamic total, dynamic curr, dynamic count) => 'تاريخ الحفظ: $date | الحالة: $status | إجمالي الفاتورة: $total $curr ($count بنود)';
  @override
  String get standardInvoiceViewSessionBtn => 'عرض التفاصيل';
  @override
  String get standardInvoiceTool1Title => '١. توليد نموذج الإكسيل المعياري';
  @override
  String get standardInvoiceTool1Subtitle => 'تجهيز ملف إكسيل بنطاقات مسمّاة لإرساله للمورد';
  @override
  String get standardInvoiceTool1Btn => 'تحميل نموذج إكسيل الموحد';
  @override
  String get standardInvoiceTool2Title => '٢. قراءة واستخراج فاتورة المورد';
  @override
  String get standardInvoiceTool2Subtitle => 'رفع ملف الإكسيل المكتمل واستخراجه آلياً';
  @override
  String get standardInvoiceTool2Btn => 'رفع وقراءة فاتورة المورد';
  @override
  String get standardInvoiceTabExtracted => 'بيانات الفاتورة المستخرجة';
  @override
  String get standardInvoiceTabComparison => 'مصفوفة المطابقة والفروق';
  @override
  String get standardInvoiceTabGovernance => 'الاعتماد والتحكم الجمركي';
  @override
  String get standardInvoiceTabRegistry => 'سجل الفواتير المعيارية';
  @override
  String get standardInvoiceNoExtractedData => 'لم يتم رفع وقراءة ملف فاتورة المورد بعد.';
  @override
  String get standardInvoiceNoExtractedDataSub => 'قم بتحميل النموذج أولاً ثم ارفعه بعد قيام المورد بملء البيانات.';
  @override
  String standardInvoiceDetailsHeader(dynamic invNum, dynamic date) => 'تفاصيل الفاتورة: $invNum ($date)';
  @override
  String get standardInvoiceSellerCardTitle => 'بيانات المصدّر الأجنبي';
  @override
  String get standardInvoiceBuyerCardTitle => 'بيانات المستورد المحلي';
  @override
  String sellerCompanyLabel(dynamic company) => 'الشركة: $company';
  @override
  String sellerTaxIdLabel(dynamic taxId) => 'الرقم الضريبي: $taxId';
  @override
  String sellerCountryLabel(dynamic country) => 'الدولة: $country';
  @override
  String sellerAddressLabel(dynamic address) => 'العنوان: $address';
  @override
  String buyerCompanyLabel(dynamic company) => 'الشركة: $company';
  @override
  String buyerTaxIdLabel(dynamic taxId) => 'الرقم الضريبي: $taxId';
  @override
  String buyerAcidNumberLabel(dynamic acid) => 'رقم القيد الجمركي: $acid';
  @override
  String buyerIncotermAndCurrencyLabel(dynamic incoterm, dynamic curr) => 'شرط التسليم: $incoterm | العملة: $curr';
  @override
  String get standardInvoiceExtractedItemsHeader => 'جدول البنود المستخرجة';
  @override
  String get standardInvoiceNoComparisonData => 'لم يتم إجراء المطابقة بعد.';
  @override
  String get standardInvoiceNoComparisonDataSub => 'قم برفع فاتورة المورد لتشغيل محرك المطابقة واكتشاف الفروق تلقائياً.';
  @override
  String get standardInvoiceMatch100Banner => 'مطابقة تامة بنسبة مئة بالمئة — لا توجد أي فروق جمركية أو مالية';
  @override
  String standardInvoiceCriticalMismatchBanner(dynamic count) => 'تحذير جمركي حرج: يوجد $count عدم تطابق حرج (رقم القيد / الرقم الضريبي / بند التعريفة)';
  @override
  String standardInvoiceDiscrepanciesBanner(dynamic count) => 'تنبيه: يوجد $count اختلافات بسيطة تحتاج مراجعة قبل الاعتماد';
  @override
  String get standardInvoiceCompHeadersSection => '١. مطابقة الترويسة والبيانات الأساسية والامتثال الرقابي';
  @override
  String get standardInvoiceCompFinancialsSection => '٢. مطابقة القيم المالية والضرائب والتكاليف';
  @override
  String get standardInvoiceCompItemsSection => '٣. مصفوفة مطابقة بنود الأصناف والتعريفة الجمركية';
  @override
  String get standardInvoiceColComparedField => 'الحقل المقارن';
  @override
  String get standardInvoiceColSystemValue => 'القيمة المعتمدة بالنظام';
  @override
  String get standardInvoiceColSupplierValue => 'القيمة بفاتورة المورد';
  @override
  String get standardInvoiceColMatchStatus => 'حالة التطابق';
  @override
  String get standardInvoiceColDiffAndNotes => 'الفروق والملاحظات';
  @override
  String get standardInvoiceColHsSystem => 'بند التعريفة (النظام)';
  @override
  String get standardInvoiceColHsSupplier => 'بند التعريفة (المورد)';
  @override
  String get standardInvoiceColQtySystem => 'الكمية (النظام)';
  @override
  String get standardInvoiceColQtySupplier => 'الكمية (المورد)';
  @override
  String get standardInvoiceColPriceSystem => 'السعر (النظام)';
  @override
  String get standardInvoiceColPriceSupplier => 'السعر (المورد)';
  @override
  String get standardInvoiceRectificationSectionTitle => 'إخطارات تصحيح الفاتورة الجاهزة للمورد';
  @override
  String get standardInvoiceRectificationEnTitle => 'إخطار التصحيح بالإنجليزي (إيميل المورد)';
  @override
  String get standardInvoiceRectificationArTitle => 'إخطار التصحيح بالعربية (واتساب أو إيميل)';
  @override
  String get standardInvoiceGovernanceTitle => 'حالة اعتماد الفاتورة المعيارية والرقابة الإجرائية';
  @override
  String get standardInvoiceStatusDraft => 'مسودة';
  @override
  String get standardInvoiceStatusUnderReview => 'قيد المراجعة والتدقيق';
  @override
  String get standardInvoiceStatusApproved => 'معتمدة ومطابقة جمركياً';
  @override
  String get standardInvoiceStatusRejected => 'مرفوضة وتحتاج تعديل المورد';
  @override
  String get standardInvoiceOverrideWarningBanner => 'تنبيه إجرائي إلزامي: تم رصد فروق في الفاتورة. يُشترط كتابة مبرر وسبب التجاوز والاعتماد قبل الحفظ.';
  @override
  String get standardInvoiceOverrideReasonLabel => 'مبرر وسبب الموافقة على الاختلافات الجمركية *';
  @override
  String get standardInvoiceOverrideReasonHint => 'اكتب المبرر الإداري أو المالي للموافقة على الفروق...';
  @override
  String get standardInvoiceOverrideRequiredError => 'حقل إلزامي: لا يمكن اعتماد الفاتورة مع وجود فروق بدون توضيح السبب والمبرر.';
  @override
  String get standardInvoiceInternalNotesLabel => 'ملاحظات التدقيق الداخلي';
  @override
  String get standardInvoiceSaveSessionBtn => 'حفظ واعتماد جلسة مراجعة الفاتورة المعيارية';
  @override
  String standardInvoiceSessionSavedSuccess(dynamic code) => 'تم حفظ واعتماد جلسة مراجعة الفاتورة المعيارية بنجاح [$code]';
  @override
  String get standardInvoiceRegistrySearchHint => 'بحث في سجل الفواتير برقم الجلسة، رقم القيد، المورد...';
  @override
  String get standardInvoiceFilterAll => 'كل الحالات';
  @override
  String get standardInvoiceColSessionCode => 'كود الجلسة';
  @override
  String get standardInvoiceColFileCode => 'ملف الشحنة';
  @override
  String get standardInvoiceColAcid => 'رقم القيد';
  @override
  String get standardInvoiceColInvoiceNum => 'رقم الفاتورة';
  @override
  String get standardInvoiceColSupplier => 'المصدر الأجنبي';
  @override
  String get standardInvoiceColTotal => 'الإجمالي';
  @override
  String get standardInvoiceColItemsCount => 'البنود';
  @override
  String get standardInvoiceColStatus => 'الحالة';
  @override
  String get standardInvoiceColUpdatedAt => 'تاريخ التحديث';
  @override
  String get standardInvoiceNoSessionsFound => 'لا توجد جلسات فواتير مسجلة.';
  @override
  String get standardInvoiceSelectFileFirstError => 'يرجى اختيار ملف الشحنة أولاً.';
  @override
  String standardInvoiceGeneratedSuccess(dynamic fileCode, dynamic bytesLength) => 'تم توليد الفاتورة بنجاح: $fileCode ($bytesLength بايت)';
  @override
  String standardInvoiceExtractedSuccess(dynamic num, dynamic itemsCount) => 'تم استخراج الفاتورة بنجاح: $num ($itemsCount بنود)';
  @override
  String standardInvoiceSessionLoadedToast(dynamic code) => 'تم استدعاء بيانات الجلسة $code';
  @override
  String standardInvoiceCopiedToClipboard(dynamic label) => 'تم نسخ $label إلى الحافظة بنجاح';
  @override
  String get standardInvoiceMustProvideOverrideJustification => 'يجب كتابة سبب ومبرر اعتماد الفاتورة مع وجود فروق جمركية.';
  @override
  String get required => 'حقل إلزامي';
  @override
  String get errorPrefix => 'خطأ';
  @override
  String get copy => 'نسخ';
  @override
  String get colProductCode => 'كود الصنف';
  @override
  String get colHsCode => 'بند التعريفة';
  @override
  String get colDescription => 'الوصف التجاري';
  @override
  String get colUnit => 'الوحدة';
  @override
  String get colUnitPrice => 'سعر الوحدة';
  @override
  String get colTotalAmount => 'القيمة الإجمالية';
  @override
  String get colGrossWeight => 'الوزن الإجمالي';

  // Screen 55: Customs Clearance Quotations & RFQ Evaluator
  @override
  String get clearanceQuotesScreenTitle => 'عروض ومقايسات التخليص الجمركي وقوائم الأسعار';
  @override
  String get clearanceQuotesScreenSubtitle => 'طلب عروض الأسعار ومقارنة التكاليف المعيارية بين المخلصين';
  @override
  String get clearanceQuotesEmbeddedTitle => 'عروض ومقايسات التخليص الجمركي والاستخراج الذكي';
  @override
  String get clearanceQuotesTabRfqs => 'طلب ومقارنة عروض التخليص الجمركي';
  @override
  String get clearanceQuotesTabPriceLists => 'قوائم أسعار بنود التخليص الثابتة';
  @override
  String get clearanceQuotesSmartExtractorBtn => 'استخراج ذكي لمقايسة تخليص';
  @override
  String get clearanceQuotesCreateRfqBtn => 'إنشاء طلب عرض أسعار جديد';
  @override
  String get clearanceQuotesSearchHint => 'بحث بكود الطلب، العنوان، أو الميناء...';
  @override
  String get clearanceQuotesStatusAll => 'جميع الحالات';
  @override
  String get clearanceQuotesStatusDraft => 'مسودة';
  @override
  String get clearanceQuotesStatusReceived => 'عروض مستلمة';
  @override
  String get clearanceQuotesStatusAwarded => 'معتمد ومُرسى';
  @override
  String get clearanceQuotesNoRfqsFound => 'لا توجد طلبات عروض أسعار تخليص حالياً.';
  @override
  String get clearanceQuotesAwardedBannerPrefix => 'تم اعتماد وترسية التخليص الجمركي على:';
  @override
  String clearanceQuotesReceivedQuotesHeader(dynamic count) => 'العروض المستلمة من المخلصين ($count)';
  @override
  String get clearanceQuotesSmartExtractQuoteBtn => 'استخراج ذكي للعرض';
  @override
  String get clearanceQuotesAddManualQuoteBtn => 'إضافة عرض يدوي';
  @override
  String get clearanceQuotesNoQuotesYet => 'لم يتم إدخال عروض أسعار لهذا الطلب بعد.';
  @override
  String get clearanceQuotesColBroker => 'المخلص الجمركي';
  @override
  String get clearanceQuotesColClearanceFee => 'أتعاب التخليص';
  @override
  String get clearanceQuotesColInlandTransport => 'النقل الداخلي';
  @override
  String get clearanceQuotesColInspectionFee => 'فحص وعرض';
  @override
  String get clearanceQuotesColPortExpenses => 'موانئ وتخزين';
  @override
  String get clearanceQuotesColMiscellaneous => 'نثريات';
  @override
  String get clearanceQuotesColEstimatedTotal => 'الإجمالي التقديري';
  @override
  String get clearanceQuotesColDuration => 'المدة';
  @override
  String get clearanceQuotesColStatusActions => 'الحالة / الإجراءات';
  @override
  String get clearanceQuotesStatusAwardedBadge => 'معتمد';
  @override
  String get clearanceQuotesAwardAndApproveBtn => 'ترسية واعتماد';
  @override
  String clearanceQuotesDaysCount(dynamic days) => '$days أيام';
  @override
  String get clearanceQuotesBadgePort => 'الميناء:';
  @override
  String get clearanceQuotesBadgeShipmentType => 'نوع الشحنة:';
  @override
  String get clearanceQuotesBadgeHsCode => 'بند التعريفة:';
  @override
  String get clearanceQuotesBadgeWeight => 'الوزن:';
  @override
  String get clearanceQuotesBadgeVolume => 'الحجم:';
  @override
  String get clearanceQuotesBadgeLowestCost => 'أقل عرض:';
  @override
  String get clearanceQuotesBadgeFastestDuration => 'أسرع مدة:';
  @override
  String get clearanceQuotesPriceListTitle => 'قوائم أسعار بنود التخليص والنقل الجمركي المعتمدة';
  @override
  String get clearanceQuotesPriceListSubtitle => 'إدارة الأسعار المعيارية لكل مخلص جمركي وميناء وصول';
  @override
  String get clearanceQuotesAddPriceItemBtn => 'إضافة بند لقائمة الأسعار';
  @override
  String get clearanceQuotesNoPriceItemsFound => 'لا توجد بنود أسعار مسجلة بعد.';
  @override
  String get clearanceQuotesColPricePort => 'الميناء';
  @override
  String get clearanceQuotesColPriceServiceType => 'نوع الخدمة';
  @override
  String get clearanceQuotesColPriceContainerType => 'نوع الحاوية';
  @override
  String get clearanceQuotesColPriceStandardRate => 'السعر المعياري';
  @override
  String get clearanceQuotesColPriceNotes => 'ملاحظات';
  @override
  String get clearanceQuotesColPriceDelete => 'حذف';
  @override
  String get clearanceQuotesDialogCreateRfqTitle => 'إنشاء طلب عرض أسعار تخليص جمركي';
  @override
  String get clearanceQuotesFieldRfqTitle => 'عنوان الطلب *';
  @override
  String get clearanceQuotesFieldRfqTitleRequired => 'العنوان مطلوب';
  @override
  String get clearanceQuotesFieldLinkImportFile => 'ربط بملف استيراد (اختياري)';
  @override
  String get clearanceQuotesFieldClearancePort => 'ميناء التخليص الجمركي *';
  @override
  String get clearanceQuotesFieldShipmentType => 'نوع الشحنة والحاوية *';
  @override
  String get clearanceQuotesFieldContainersCount => 'عدد الحاويات *';
  @override
  String get clearanceQuotesFieldGrossWeightKg => 'الوزن القائم (كجم)';
  @override
  String get clearanceQuotesFieldCbm => 'الحجم بالمتر المكعب';
  @override
  String get clearanceQuotesSubmitCreateRfqBtn => 'إنشاء الطلب';
  @override
  String get clearanceQuotesDialogAddQuoteTitle => 'إضافة عرض أسعار مخلص جمركي';
  @override
  String get clearanceQuotesFieldCustomsBroker => 'المخلص الجمركي *';
  @override
  String get clearanceQuotesFieldClearanceFeeEgp => 'أتعاب التخليص الجمركي بالجنيه *';
  @override
  String get clearanceQuotesFieldInlandFeeEgp => 'النقل الداخلي للمصنع بالجنيه *';
  @override
  String get clearanceQuotesFieldInspectionFeeEgp => 'مصاريف فحص وعرض بالجنيه';
  @override
  String get clearanceQuotesFieldPortExpEgp => 'رسوم موانئ وأرضيات بالجنيه';
  @override
  String get clearanceQuotesFieldMiscFeeEgp => 'نثريات ومصروفات إدارية بالجنيه';
  @override
  String get clearanceQuotesFieldEstimatedDays => 'مدة التخليص المقدرة بالأيام *';
  @override
  String get clearanceQuotesTotalEstimatedQuoteLabel => 'الإجمالي التقديري للعرض:';
  @override
  String get clearanceQuotesSubmitSaveQuoteBtn => 'حفظ العرض';
  @override
  String get clearanceQuotesSmartExtractorDialogTitle => 'الاستخلاص الذكي لعروض أسعار ومقايسات التخليص';
  @override
  String get clearanceQuotesSmartExtractorPrompt => 'الصق نص عرض السعر أو البريد الإلكتروني أو اختر ملف المقايسة لاستخلاص البنود آلياً:';
  @override
  String get clearanceQuotesSmartExtractorInputHint => 'مثال:\nعرض أسعار تخليص جمركي من مكتب النسر...\nأتعاب التخليص: ٣٥٠٠ جنيه\nنقل داخلي: ٧٠٠٠ جنيه\nمصاريف فحص وعرض: ١٥٠٠ جنيه...';
  @override
  String get clearanceQuotesExtractingState => 'جاري الاستخراج...';
  @override
  String get clearanceQuotesExtractFromTextBtn => 'استخراج فوري من النص';
  @override
  String get clearanceQuotesUploadDocBtn => 'رفع مستند مقايسة';
  @override
  String get clearanceQuotesExtractedBrokerPrefix => 'المخلص المستخرج:';
  @override
  String get clearanceQuotesExtractedPortPrefix => 'الميناء:';
  @override
  String get clearanceQuotesExtractedContainerPrefix => 'الحاوية:';
  @override
  String get clearanceQuotesExtractedTotalPrefix => 'إجمالي التكلفة المقدرة:';
  @override
  String get clearanceQuotesApplyExtractedQuoteBtn => 'تطبيق وإضافة العرض';
  @override
  String get clearanceQuotesUseExtractedQuoteBtn => 'تطبيق واستخدام العرض';
  @override
  String clearanceQuotesExtractedSuccessToast(dynamic broker, dynamic total) => 'تم استخلاص عرض المخلص بنجاح: $broker - الإجمالي: $total جنيه';
  @override
  String get clearanceQuotesDialogAddPriceItemTitle => 'إضافة بند لقائمة أسعار التخليص';
  @override
  String get clearanceQuotesFieldServiceCategory => 'نوع بند الخدمة *';
  @override
  String get clearanceQuotesFieldStandardPriceEgp => 'السعر المعياري بالجنيه *';
  @override
  String get clearanceQuotesFieldStandardPriceRequired => 'السعر مطلوب';
  @override
  String get clearanceQuotesSubmitSavePriceItemBtn => 'حفظ البند';
  @override
  String get clearanceQuotesCatClearanceFee => 'أتعاب التخليص الجمركي';
  @override
  String get clearanceQuotesCatInlandTransport => 'النقل الداخلي';
  @override
  String get clearanceQuotesCatInspectionFee => 'مصاريف الفحص والعرض';
  @override
  String get clearanceQuotesCatPortCharges => 'رسوم ومصاريف الموانئ';
  @override
  String get clearanceQuotesConfirmAwardTitle => 'تأكيد اعتماد وترسية التخليص الجمركي';
  @override
  String get clearanceQuotesConfirmAwardContent => 'هل أنت متأكد من رغبتك في اعتماد وترسية هذا العرض وتثبيته في منظومة تكاليف الشحنة؟';
  @override
  String get clearanceQuotesConfirmAwardBtn => 'نعم، اعتماد العرض';
  @override
  String get clearanceQuotesAwardSuccessSnackbar => 'تم اعتماد وترسية عرض التخليص الجمركي بنجاح';
  @override
  String get clearanceQuotesConfirmDeleteQuoteTitle => 'تأكيد الحذف';
  @override
  String get clearanceQuotesConfirmDeleteQuoteContent => 'هل تريد حذف هذا العرض من المقارنة؟';
  @override
  String get clearanceQuotesErrorLoadingRfqs => 'خطأ في تحميل عروض التخليص:';
  @override
  String get clearanceQuotesErrorLoadingPriceList => 'خطأ في تحميل قوائم الأسعار:';
  @override
  String get kgUnit => 'كجم';
  @override
  String get cbmUnit => 'م³';
  @override
  String get egpCurrency => 'جنيه';
  @override
  String get searchPlaceholder => 'ابحث هنا...';

  // ── Authentication & Login Screen ──────────────────────────────────────────
  @override
  String get loginScreenTitle => 'تسجيل الدخول إلى المنظومة';
  @override
  String get loginScreenSubtitle => 'منظومة سرور لإدارة سلاسل الإمداد والاستيراد والتخليص الجمركي';
  @override
  String get loginUsernameLabel => 'اسم المستخدم أو البريد الإلكتروني';
  @override
  String get loginUsernameHint => 'اسم المستخدم...';
  @override
  String get loginUsernameRequired => 'يرجى إدخال اسم المستخدم أو البريد الإلكتروني';
  @override
  String get loginPasswordLabel => 'كلمة المرور';
  @override
  String get loginPasswordRequired => 'يرجى إدخال كلمة المرور';
  @override
  String get loginButtonLabel => 'تسجيل الدخول إلى النظام';
  @override
  String get loginAuthenticating => 'جاري تسجيل الدخول والتحقق...';
  @override
  String get loginQuickDemoAccess => 'الدخول السريع بحسابات النظام التجريبية:';
  @override
  String get loginInvalidCredentials => 'اسم المستخدم أو كلمة المرور غير صحيحة';
  @override
  String get loginRoleAdmin => 'مسؤول النظام';
  @override
  String get loginRoleManager => 'مدير العمليات';
  @override
  String get loginRoleSpecialist => 'أخصائي لوجستي';

  // ── Shipping Scenarios & Cargo Stacking ────────────────────────────────────
  @override
  String get multiLayerStacking => 'رص متعدد الطبقات';
  @override
  String get floorPlacementZ0 => 'رص أرضي مستوى 0';
  @override
  String mixedStackingCargoDesc(int nonStack, int stack) =>
      '$nonStack غير قابل للرص + $stack قابل للرص';
  @override
  String get containerCountPill => 'عدد الحاويات';
  @override
  String get spaceAndVolumeUtilPill => 'استغلال المساحة والحجم';
  @override
  String get weightUtilPill => 'استغلال الوزن';
  @override
  String containerCountUnit(int count) => '$count حاوية';

  // ── Smart Invoice & Packing Extractor ──────────────────────────────────────
  @override
  String get smartInvoiceExtractProgressTitle => 'مستخرج بيانات الفواتير وقوائم التعبئة الذكي';
  @override
  String ocrStepProgressLabel(int step, int total, String desc) => 'المرحلة $step من $total: $desc';
  @override
  String get ocrStep1Reading => 'قراءة';
  @override
  String get ocrStep2Upload => 'رفع';
  @override
  String get ocrStep3Ocr => 'تعرف ضوئي';
  @override
  String get ocrStep4Fields => 'استخراج الحقول';
  @override
  String get cancelAndCloseExtractor => 'إلغاء العملية وإغلاق الأداة';
  @override
  String get ocrAnalyzingText => 'جاري تحليل النصوص، أرقام البنود، والأسعار...';
  @override
  String get ocrSendingDoc => 'جاري إرسال المستند ومعالجة الصفحات...';
  @override
  String get ocrExtractingFields => 'جاري استخراج بنود الفاتورة وكشف التعبئة وتنسيق البيانات...';
  @override
  String get ocrCompleteSuccess => 'اكتملت المعالجة بنجاح 100%';
  @override
  String get ocrCompleteSuccessDesc => 'تم استخراج كافة البيانات بنجاح وجاري عرض المعاينة!';
  @override
  String get closeAndCancelExtractionTooltip => 'إغلاق وإلغاء الاستخراج';
  @override
  String get addManualFieldBtn => 'إضافة بيان / حقل إضافي يدوياً';
  @override
  String get populateFormBtn => 'تعبئة النموذج';
  @override
  String get verifyPartiesInDb => 'التحقق من تسجيل الأطراف في قاعدة البيانات';
  @override
  String get partyUnconfirmed => 'غير مؤكد';
  @override
  String get partyConfirmed => 'مؤكد';
  @override
  String get registerPartyAction => 'سجّل +';
  @override
  String get missingFieldsWarning => 'الحقول التالية لم تُستخرج:';
  @override
  String get editFieldValueTitle => 'تعديل قيمة الحقل';
  @override
  String get updatedValueLabel => 'القيمة المحدثة';
  @override
  String get enterCorrectValueHint => 'أدخل القيمة الصحيحة...';
  @override
  String get saveEditBtn => 'حفظ التعديل';
  @override
  String get callSmartNafezaDiffBtn => 'استدعاء أداة نافذة الذكية لتسجيل البند';
  @override
  String get fullExtraction => 'استخراج مكتمل';
  @override
  String get partialExtraction => 'استخراج جزئي';
  @override
  String get extractionFailedStatus => 'فشل الاستخراج';
  @override
  String get extractionResultHeader => 'نتيجة استخراج البيانات';
  @override
  String get extractionConfidenceLabel => 'نسبة الثقة';
  @override
  String get extractedFieldsTitle => 'البيانات المستخرجة';
  @override
  String get supplier => 'المورد';

  // ── Extracted Field Labels Dictionary ───────────────────────────────────────
  @override
  String get fieldSupplierAddress => 'عنوان المورد';
  @override
  String get fieldSupplierPhone => 'هاتف المورد';
  @override
  String get fieldSupplierTaxId => 'الرقم الضريبي للمورد';
  @override
  String get fieldSupplierCountry => 'دولة المورد';
  @override
  String get fieldSupplierCity => 'مدينة المورد';
  @override
  String get fieldSupplierEmail => 'البريد الإلكتروني للمورد';
  @override
  String get fieldCustomerName => 'الشركة المستوردة';
  @override
  String get fieldCustomerAddress => 'عنوان المستورد';
  @override
  String get fieldCustomerTaxId => 'الرقم الضريبي للمستورد';
  @override
  String get fieldInvoiceNumber => 'رقم الفاتورة';
  @override
  String get fieldInvoiceDate => 'تاريخ الفاتورة';
  @override
  String get fieldInvoiceValue => 'قيمة الفاتورة';
  @override
  String get fieldPoNumber => 'رقم أمر الشراء';
  @override
  String get fieldIncoterm => 'شرط الشحن والتسليم';
  @override
  String get fieldCurrency => 'العملة';
  @override
  String get fieldExchangeRate => 'سعر الصرف';
  @override
  String get fieldTotalAmount => 'إجمالي المبلغ';
  @override
  String get fieldPaymentTerms => 'شروط الدفع';
  @override
  String get fieldPolPort => 'ميناء الشحن';
  @override
  String get fieldPodPort => 'ميناء التفريغ والوصول';
  @override
  String get fieldAcidNumber => 'رقم القيد الجمركي ACID';
  @override
  String get fieldBlNumber => 'رقم بوليصة الشحن';
  @override
  String get fieldContainerNumbers => 'أرقام الحاويات';
  @override
  String get fieldGrossWeight => 'الوزن القائم';
  @override
  String get fieldNetWeight => 'الوزن الصافي';
  @override
  String get fieldTotalCbm => 'إجمالي الحجم CBM';
  @override
  String get fieldPackagesCount => 'عدد الطرود';
  @override
  String get fieldCommodityDescription => 'وصف البضاعة';
  @override
  String get fieldOriginCountry => 'بلد المنشأ';
  @override
  String get fieldCustomsValueEgp => 'القيمة الجمركية';
  @override
  String get fieldImportDuty => 'ضريبة الوارد';
  @override
  String get fieldVatAmount => 'ضريبة القيمة المضافة';
  @override
  String get fieldTotalTaxes => 'إجمالي الضرائب';
  @override
  String get fieldCertificateNumber => 'رقم الشهادة';
  @override
  String get fieldIssueDate => 'تاريخ الإصدار';
  @override
  String get fieldCarrierName => 'الناقل الملاحي أو الجوي';
  @override
  String get fieldFreightRate => 'سعر النولون';
  @override
  String get fieldTransitDays => 'أيام العبور';
  @override
  String get fieldValidityDate => 'تاريخ الصلاحية';
  @override
  String get fieldBookingNumber => 'رقم الحجز';
  @override
  String get fieldSiCutoff => 'موعد إغلاق التعليمات';
  @override
  String get fieldAmount => 'المبلغ';
  @override
  String get fieldBankName => 'اسم البنك';
  @override
  String get fieldSwiftCode => 'كود السويفت';
  @override
  String get fieldInspectionResult => 'نتيجة الفحص';

  // ── Purchase Order Details & View Modal ────────────────────────────────────
  @override
  String poViewDialogTitle(String poNumber, String? version) =>
      version != null && version.isNotEmpty
          ? 'أمر الشراء والفاتورة المبدئية: $poNumber ($version)'
          : 'أمر الشراء والفاتورة المبدئية: $poNumber';
  @override
  String get poLineItemsBreakdown => 'بنود الفاتورة المبدئية والأكواد الجمركية';
  @override
  String get descriptionAndHsCode => 'الوصف والبند الجمركي';
  @override
  String get qtyUom => 'الكمية / الوحدة';
  @override
  String get volumeCbmPackingList => 'حجم CBM (بيان التعبئة)';
  @override
  String itemOriginLabel(String origin) => 'المنشأ: $origin';
  @override
  String hsMismatchWarning(String duty, String vat) =>
      'بند جمركي (جمارك: $duty / ق.م: $vat) - عدم تطابق';
  @override
  String get exchangeRateLabel => 'سعر الصرف';
  @override
  String get itemCode => 'كود الصنف';
  @override
  String get unitPrice => 'سعر الوحدة';
  @override
  String get lineTotal => 'الإجمالي';

  // ── Edit Purchase Order & Packing List & 3D Simulator ──────────────────────
  @override
  String editPurchaseOrderTitle(String poNumber) => 'تعديل أمر الشراء ($poNumber)';
  @override
  String poLineItemsTabCount(int count) => 'بنود الفاتورة ($count)';
  @override
  String poPackingListTabCount(int count) => 'بيان التعبئة والطرود ($count)';
  @override
  String get packingListReaderBanner => 'أداة قراءة واستخراج بيان التعبئة والوزن';
  @override
  String get packingListReaderBannerDesc =>
      'قم برفع ملف بيان التعبئة لاستخراج أعداد الطرود، الأوزان القائمة والصافية، والأحجام تلقائياً';
  @override
  String get explicitDimensionsPath => 'مسار الأبعاد الصريحة (L × W × H)';
  @override
  String get cbmDirectPathAndPalletLayout => 'مسار الحجم المباشر ومخطط البالتات';
  @override
  String get packingListEntriesSection => 'بيان التعبئة والطرود والأبعاد *';
  @override
  String get autoFillFromInvoice => 'تعبئة تلقائية من الفاتورة';
  @override
  String get simulateAndPack3d => 'محاكاة ورص الحاويات 3D';
  @override
  String get addPackingEntryBtn => 'إضافة بند تعبئة';
  @override
  String get noPackingEntriesYet => 'لم يتم إضافة بنود تعبئة بعد';
  @override
  String get noPackingEntriesYetDesc =>
      'انقر فوق "تعبئة تلقائية من الفاتورة" لإنشاء قائمة التعبئة آلياً أو "إضافة بند تعبئة"';
  @override
  String pkgCardNumber(int num) => 'طرد #$num';
  @override
  String get hsCodeSearchFieldLabel => 'البند الجمركي (بحث 🔍) *';
  @override
  String get selectTariffItemHint => 'اختر بند جمركي';
  @override
  String get itemNameOrDescHint => 'اسم أو وصف الصنف';
  @override
  String get packageTypeFieldLabel => 'نوع الطرد';
  @override
  String get unitFieldLabel => 'الوحدة';
  @override
  String get qtyPcsFieldLabel => 'الكمية (قطع)';
  @override
  String get qtyPkgFieldLabel => 'عدد الطرود';
  @override
  String lengthFieldLabel(String unit) => 'الطول ($unit)';
  @override
  String widthFieldLabel(String unit) => 'العرض ($unit)';
  @override
  String heightFieldLabel(String unit) => 'الارتفاع ($unit)';
  @override
  String get weightUnitFieldLabel => 'وحدة الوزن';
  @override
  String netWeightFieldLabel(String unit) => 'الوزن الصافي ($unit)';
  @override
  String grossWeightFieldLabel(String unit) => 'الوزن القائم ($unit)';
  @override
  String get stackingInstructionsLabel => 'تعليمات الرص *';
  @override
  String get totalVolumePill => 'إجمالي الحجم';
  @override
  String get totalGrossWeightPill => 'إجمالي الوزن القائم';
  @override
  String get airChargeablePill => 'الوزن الحجمي للشحن الجوي';
  @override
  String autoFillSuccessNotice(int count) =>
      'تمت التعبئة التلقائية لـ $count طرد من بنود الفاتورة المبدئية بنجاح!';
  @override
  String get enterPackingOrPalletsNotice =>
      'يرجى إدخال أصناف قائمة التعبئة أو البالتات أولاً للمحاكاة';
  @override
  String get containerLoadPlan3dTitle => 'مخطط ومحاكاة رص الحاويات 3D';
  @override
  String get containerLoadPlan3dSubtitle =>
      'محاكاة خوارزمية الرص ثلاثية الأبعاد للحاويات البحرية بناءً على قائمة التعبئة وأبعاد الطرود';
  @override
  String get stackingSimulationModeLabel => 'نمط الرص بالمحاكاة:';
  @override
  String get projectionLabel => 'المسقط:';
  @override
  String get simulationModeActualMixed => '⚖️ الرص الفعلي';
  @override
  String get simulationModeStackable => '📦 قابل للرص';
  @override
  String get simulationModeFloorOnly => '🚫 أرضي فقط';
  @override
  String get topViewProjection => '🔝 مسقط علوي';
  @override
  String get sideViewProjection => '🔲 مسقط جانبي';
  @override
  String requiredContainersSummary(String fleet) => 'الحاويات المطلوبة: $fleet';
  @override
  String totalPackagesSummary(int total, int stackable, int floor) =>
      'عدد الطرود: $total طرد ($stackable قابل للرص | $floor أرضي)';
  @override
  String totalWeightSummary(String wt) => 'إجمالي الوزن: $wt كجم';
  @override
  String totalVolumeSummary(String vol) => 'إجمالي الحجم: $vol م³';
  @override
  String get packingFailureTitle =>
      'فشل الرص: تجاوز أبعاد الطرد أو الوزن الأبعاد القياسية المسموح بها داخل الحاوية';
  @override
  String get itemCodeLabel => 'كود الصنف *';
  @override
  String get fieldRequired => 'حقل مطلوب';
  @override
  String get fieldCurrentStage => 'المرحلة الحالية';
  @override
  String get searchFieldHint => 'ابحث برقم الملف أو الكود أو اسم الشركة...';

  // ── Standardized Stage Stop & Resume Buttons ────────────────────────────────
  @override
  String get stopShipmentAtThisStageBtn => 'إيقاف الشحنة عند هذه المرحلة';
  @override
  String get shipmentOnHoldPrefix => 'متوقفة:';
  @override
  String get shipmentClosedArchived => 'الشحنة مغلقة بالأرشيف';
  @override
  String get selectFileToHoldTitle => 'اختيار ملف الشحنة للإيقاف عند هذه المرحلة';
  @override
  String get selectFileToHoldLabel => 'اختر ملف الشحنة المراد إيقافها *';
  @override
  String get selectFileToHoldHint => 'ابحث برقم الملف أو الكود أو اسم الشركة...';
  @override
  String get continueToHoldReasonBtn => 'متابعة وإدخال سبب الإيقاف';
  @override
  String holdShipmentStageBannerTitle(String code, String stage) =>
      '⚠️ تنبيه: هذه الشحنة ($code) متوقفة ومعلقة عند مرحلة: [$stage]';
  @override
  String get holdDialogReasonLabel => 'سبب إيقاف وتعليق الشحنة';
  @override
  String get holdDialogReasonHint => 'اكتب سبب الإيقاف أو اختر من الأسباب بالأعلى...';
  @override
  String get confirmHoldActionBtn => 'تأكيد إيقاف وتجميد الشحنة عند هذه المرحلة';
  @override
  String holdSuccessNotification(String code, String stage) =>
      '⚠️ تم إيقاف وتجميد الشحنة ($code) بنجاح عند مرحلة: $stage';

  // ── Purchase Order Comprehensive Report Preview ───────────────────────────
  @override
  String get poReportPreviewTitle =>
      'معاينة تقرير أمر الشراء وقائمة التعبئة المعتمدة';
  @override
  String get poReportPreviewSubtitle =>
      'استعراض تفصيلي شامل ومطابقة نهائية قبل الحفظ — Sorour Logistics ERP';
  @override
  String get poReport3dSimulation => 'محاكاة الرص 3D';
  @override
  String get poReportCopyText => 'نسخ نص التقرير';
  @override
  String get poReportClosePreview => 'إغلاق المعاينة';
  @override
  String get poReportHeaderDocumentTitle =>
      'أمر الشراء ومواصفات التعبئة المعتمدة';
  @override
  String get poReportPoNumber => 'رقم أمر الشراء';
  @override
  String get poReportPiNumber => 'الفاتورة المبدئية PI';
  @override
  String get poReportAcidNumber => 'رقم القيد الجمركي ACID';
  @override
  String get poReportOrderDate => 'تاريخ الطلب';
  @override
  String get poReportExchangeRate => 'سعر الصرف';
  @override
  String get poReportIncoterms => 'شروط التسليم (Incoterms)';
  @override
  String get poReportOrigin => 'بلد المنشأ';
  @override
  String get poReportBuyer => 'الشركة المستوردة (Buyer)';
  @override
  String get poReportTaxId => 'السجل الضريبي';
  @override
  String get poReportImportFile => 'ملف الشحنة';
  @override
  String get poReportSeller => 'المورد الأجنبي (Seller)';
  @override
  String get poReportSupplierCountry => 'دولة المورد';
  @override
  String get poReportPaymentTerms => 'شروط السداد';
  @override
  String get poReportTotalInvoice => 'إجمالي الفاتورة';
  @override
  String get poReportTotalPkgsAndPcs => 'عدد الطرود والقطع';
  @override
  String get poReportGrossWeight => 'الوزن القائم';
  @override
  String get poReportNetWeight => 'الوزن الصافي';
  @override
  String get poReportVolumeCbm => 'الحجم CBM';
  @override
  String get poReportPalletPlan => 'مخطط البالتات';
  @override
  String get poReportRecommendedContainer => 'الحاوية المقترحة';
  @override
  String get poReportSec1InvoiceItems =>
      '1. جدول بنود الفاتورة التجارية (Commercial Invoice Line Items)';
  @override
  String get poReportSec2PackingList =>
      '2. بيان قائمة التعبئة والطرود والأبعاد (Detailed Packing List)';
  @override
  String get poReportSec3PalletPlan =>
      '3. لوحة مخطط البالتات ووحدات الشحن (Master Palletization Plan)';
  @override
  String get poReportSec4Notes =>
      '4. الملاحظات والشروط الإضافية (Additional Notes & Terms)';
  @override
  String get poReportColItemCode => 'كود الصنف';
  @override
  String get poReportColDescription => 'البيان والوصف';
  @override
  String get poReportColHsCode => 'بند التعريفة (HS Code)';
  @override
  String get poReportColQtyUnit => 'الكمية / الوحدة';
  @override
  String get poReportColUnitPrice => 'سعر الوحدة';
  @override
  String get poReportColTotalAmount => 'الإجمالي (Total)';
  @override
  String get poReportColPkgType => 'نوع التعبئة';
  @override
  String get poReportColDimensions => 'الأبعاد (سم)';
  @override
  String get poReportColStackable => 'الرص';
  @override
  String get poReportStackableYes => '📦 نعم';
  @override
  String get poReportStackableNo => '🚫 أرضي';
  @override
  String get poReportGrandTotal => 'الإجمالي الكلي';
  @override
  String get poReportTotalPacking => 'إجمالي التعبئة';
  @override
  String get poReportTotalPallets => 'إجمالي البالتات';
  @override
  String get poReportReadyForApproval => 'جاهز للاعتماد';
  @override
  String get poReportCloseAndEdit => 'إغلاق والعودة للتعديل';
  @override
  String get poReportSaveAndApprove => 'حفظ واعتماد أمر الشراء';
  @override
  String get poReportCopiedToClipboard =>
      '📋 تم نسخ نص التقرير بالكامل للحافظة بنجاح!';
  @override
  String poReportItemsCountUnit(int count) => '$count بنود';
  @override
  String poReportPackagesCountUnit(int count) => '$count طرد';
  @override
  String poReportPiecesCountUnit(int count) => '$count قطعة';
  @override
  String poReportPalletsCountUnit(int count) => '$count بالتات';
  @override
  String poReportRowsCountUnit(int count) => '$count أسطر';
  @override
  String get poReportDirectVolume => 'حجم مباشر';
  @override
  String get poReportLanguageToggleTooltip =>
      'تغيير لغة التقرير (عربي / English)';
  @override
  String get poReportSwitchLanguageBtn => 'English';
  @override
  String get savePurchaseOrderBtn => 'حفظ أمر الشراء';
  @override
  String get savePoEditsBtn => 'حفظ تعديلات أمر الشراء';
  @override
  String get previewPoReportBtn => 'معاينة تقرير أمر الشراء';
}



















