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
}


