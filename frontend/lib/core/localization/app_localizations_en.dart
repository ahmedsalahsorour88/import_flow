import 'app_localizations.dart';

/// English localization — default language for ImportFlow ERP.
class AppLocalizationsEn extends AppLocalizations {
  const AppLocalizationsEn();

  // ── Navigation / Sidebar ─────────────────────────────────────────────────
  @override String get appTitle => 'Sorour Logistics';
  @override String get appSubtitle => 'Import Management ERP';
  @override String get masterData => 'Master Data & Tables';
  @override String get masterDataSub => 'Reference data and registries';
  @override String get shipmentPlanning => 'Shipment Planning';
  @override String get shipmentPlanningSub => 'Files, POs & calculations';
  @override String get phase1 => '1. Pre-Planning & Studies';
  @override String get phase1Sub => 'Freight & customs feasibility';
  @override String get phase2 => '2. Shipment Initiation';
  @override String get phase2Sub => 'Budget approvals & ACID';
  @override String get phase3 => '3. Booking & Doc Prep';
  @override String get phase3Sub => 'Freight booking & document review';
  @override String get phase4 => '4. Digital & Banking';
  @override String get phase4Sub => 'CargoX, originals & bank forms';
  @override String get phase5 => '5. Port & Clearance';
  @override String get phase5Sub => 'Customs declaration & clearance';
  @override String get phase6 => '6. Inbound & Closure';
  @override String get phase6Sub => 'Warehouse, landed cost & closure';
  @override String get dashboardAndReports => 'Dashboard & Reports';
  @override String get dashboardAndReportsSub => 'KPIs, audit & reporting hub';

  // ── Sidebar Menu Items ────────────────────────────────────────────────────
  @override String get importCompanies => 'Import Companies';
  @override String get foreignSuppliers => 'Foreign Suppliers';
  @override String get partnersAndBanks => 'Partners & Banks';
  @override String get projectsAndCostCenters => 'Projects & Cost Centers';
  @override String get portsAndLocations => 'Ports & Locations';
  @override String get incotermsRules => 'Incoterms Rules';
  @override String get customsTariffSchedule => 'Customs Tariff Schedule';
  @override String get currenciesAndRates => 'Currencies & Rates';
  @override String get importFiles => 'Import Files';
  @override String get purchaseOrders => 'Purchase Orders & Origin';
  @override String get cbmCalculator => 'CBM & Container Loading';
  @override String get freightStudies => 'Freight Studies';
  @override String get freightQuotations => 'Freight Quotations Comparison';
  @override String get customsStudies => 'Customs Studies';
  @override String get clearanceQuotations => 'Clearance Quotations & Extractor';
  @override String get importRequirements => 'Import Regulatory Requirements';
  @override String get financeApprovals => 'Finance Approvals & Budget';
  @override String get acidOperations => 'ACID Operations';
  @override String get freightBooking => 'Freight Booking';
  @override String get freightAllocations => 'Freight Allocations (VGM)';
  @override String get cargoShippingTracking => 'Cargo Shipping Tracking';
  @override String get packingReconciliation => 'PO & Packing Reconciliation';
  @override String get draftDocsReview => 'Draft Docs Review (B/L)';
  @override String get draftCOO => 'Draft COO / EUR.1';
  @override String get draftInspection => 'Draft Inspection / COC';
  @override String get docsCustomsApproval => 'Docs Customs Approval';
  @override String get centralDocsHub => 'Central Docs & Rectifications Hub';
  @override String get customsDutyEstimator => 'Customs Duty Estimator';
  @override String get cargoXBlockchain => 'CargoX Blockchain & ACI Hub';
  @override String get originalsCollection => 'Originals Collection';
  @override String get bankForm4 => 'Bank Form 4';
  @override String get customsDeclaration46 => 'Customs Declaration 46';
  @override String get customsClearanceFollowup => 'Customs Clearance Follow-up';
  @override String get drawingSamples => 'Drawing Samples / Shortage';
  @override String get discrepancyDamage => 'Discrepancy / Damage';
  @override String get finalCustomsPayment => 'Final Customs Payment';
  @override String get demurrageDetention => 'Demurrage & Detention';
  @override String get goodsInTransit => 'Goods In Transit (GIT) Ledger';
  @override String get warehouseReceiving => 'Warehouse Receiving GRN';
  @override String get receivedShipmentsReport => 'Received Shipments Report';
  @override String get landedCostSettlement => 'Landed Cost Settlement';
  @override String get landedCostComparison => 'Landed Cost Comparison';
  @override String get importFileFinalClosure => 'Import File Final Closure';
  @override String get operationalDashboard => 'Operational Dashboard';
  @override String get lifecycleBoard => 'Lifecycle Operations Board';
  @override String get masterShipmentReport => 'Master Shipment Report';
  @override String get dynamicReportBuilder => 'Dynamic Report Builder';
  @override String get quickUpdateEngine => 'Quick Update Engine';
  @override String get smartTasksAndAlerts => 'Smart Tasks & Alerts';
  @override String get systemAuditLogs => 'System Audit Logs';
  @override String get productionSyncHub => 'Production Sync Hub';

  // ── Buttons ───────────────────────────────────────────────────────────────
  @override String get save => 'Save';
  @override String get saveDraft => 'Save Draft';
  @override String get saveAndConfirm => 'Save & Confirm';
  @override String get updateRecord => 'Update Record';
  @override String get cancel => 'Cancel';
  @override String get close => 'Close';
  @override String get resetForm => 'Clear Form';
  @override String get refresh => 'Refresh';
  @override String get liveRefresh => 'Live Refresh';
  @override String get edit => 'Edit';
  @override String get delete => 'Delete';
  @override String get viewDetails => 'View Details';
  @override String get print => 'Print / Export';
  @override String get exportExcel => 'Export Excel';
  @override String get exportPdf => 'Export PDF';
  @override String get importExcel => 'Import Excel';
  @override String get downloadTemplate => 'Download Template';
  @override String get uploading => 'Uploading...';
  @override String get backToDashboard => 'Back to Dashboard';

  // ── Common Messages ───────────────────────────────────────────────────────
  @override String get connectionError => 'Server Connection Error';
  @override String get connectionErrorDetail =>
      'Could not connect to the backend server. Make sure it is running then press Retry.';
  @override String get retryConnection => 'Retry Connection';
  @override String get loading => 'Loading...';
  @override String get saving => 'Saving...';
  @override String get noData => 'No data available';
  @override String get search => 'Search';
  @override String get searchHint => 'Quick search...';
  @override String get clearSearch => 'Clear';
  @override String get ok => 'OK';
  @override String get confirm => 'Confirm';
  @override String get warning => 'Warning';
  @override String get error => 'Error';
  @override String get success => 'Success';
  @override String get importSuccessful => 'Import Successful';
  @override String get importWithAlerts => 'Import Completed with Alerts';
  @override String get alertsErrors => 'Alerts / Errors:';
  @override String get preparingExport => 'Preparing document export...';
  @override String get dataActionsTitle => 'Data Actions & Export/Import';

  // ── System Info ───────────────────────────────────────────────────────────
  @override String get systemVersion => 'System Version';
  @override String get buildId => 'Build ID';
  @override String get backendEngine => 'Backend Engine';
  @override String get database => 'Database';
  @override String get operatingMode => 'Operating Mode';
  @override String get licenseAndRights => 'License & Rights';
  @override String get systemInfo => 'System Info';
  @override String get syncHub => 'Sync Hub';
  @override String get expandSidebar => 'Expand Sidebar';
  @override String get collapseSidebar => 'Collapse Sidebar';
  @override String get userOptions => 'User Options';
  @override String get logout => 'Logout';
  @override String get versionBadge => 'v1.0.2 (Build 2026.08)';

  // ── Tooltips ─────────────────────────────────────────────────────────────
  @override String get viewDetailsTooltip => 'View Details';
  @override String get editTooltip => 'Edit Record';
  @override String get printTooltip => 'Print / Export PDF';
  @override String get deleteTooltip => 'Delete / Deactivate';
  @override String get syncHubTooltip => 'Production Sync Hub';
  @override String get systemInfoTooltip => 'System Version & Info';
  @override String get backToDashboardTooltip => 'Back to Dashboard';
  @override String get languageToggleTooltip => 'Switch Language (AR / EN)';

  // ── Role Switcher ─────────────────────────────────────────────────────────
  @override String get switchAsAdmin => 'Switch as: Admin 🔴';
  @override String get switchAsManager => 'Switch as: Manager 🔵';
  @override String get switchAsSpecialist => 'Switch as: Specialist 🟢';
  @override String get productionSyncTitle => 'Production Sync & Deployment';

  // ── Sidebar Search ────────────────────────────────────────────────────────
  @override String get quickSearch => 'Quick Search...';

  // ── Operational Dashboard ───────────────────────────────────────────────────
  @override String get operationalDashboardTitle => 'Operational Workspace Dashboard';
  @override String get priority => 'Priority:';
  @override String get priorityAll => 'All';
  @override String get priorityLow => 'Low';
  @override String get priorityMedium => 'Medium';
  @override String get priorityHigh => 'High';
  @override String get priorityCritical => 'Critical';
  @override String get customsBrokerLabel => 'Customs Broker:';
  @override String get allBrokers => 'All Brokers';
  @override String get quickSearchLabel => 'Quick Search:';
  @override String get dashboardSearchHint => 'Shipment code, PO, supplier...';
  @override String get resetFilters => 'Reset Filters';
  @override String get clearFilter => 'Clear Filter';
  @override String get serverConnectionError => 'Could not connect to backend server';
  @override String get serverConnectionHint => 'Please ensure the backend server is running or click retry.';
  @override String get matchingShipments => 'Matching Shipments';
  @override String get lastUpdated => 'Last Updated';
  @override String get noMatchingShipments => 'No Matching Shipments';
  @override String get noMatchingShipmentsDesc => 'No shipments found matching the current filter criteria.';
  @override String get clearFiltersShowAll => 'Clear Filters & Show All';
  @override String get currentPhase => 'Current Phase';
  @override String get operationalStep => 'Operational Step';
  @override String get unassigned => 'Unassigned';
  @override String get closedShipment => 'Closed Shipment';
  @override String get recordDailyUpdate => 'Record Daily Update';
  @override String get closeStopShipment => 'Close & Stop Shipment';
  @override String get nextStepAction => '🎯 Next Step & Target Action:';
  @override String get responsiblePerson => 'Responsible';
  @override String get executeStepNow => 'Execute Step Now';
  @override String get openShipmentTasks => 'Open TO-DO Tasks for Shipment';
  @override String get manageAllTasks => 'Manage All Tasks';
  @override String get taskCompletedSuccessfully => '✅ Task completed successfully';
  @override String get riskAlertsCenter => 'Operational Risk & Escalation Center:';
  @override String get dailyCheckinsLog => 'Daily Check-ins & Live Operations Log:';
  @override String get addDailyUpdate => 'Add Daily Update';
  @override String get noDailyUpdates => 'No daily check-ins recorded today.';
  @override String get aiSmartExtractorTitle => 'AI Master Data Smart Extractor:';
  @override String get smartExtractSupplier => 'Smart Foreign Supplier 🌍';
  @override String get smartExtractCompany => 'Smart Import Company 🏢';
  @override String get smartExtractPartner => 'Smart Partner / Broker 🤝';
  @override String get smartExtractBank => 'Smart Approved Bank 🏦';
  @override String get quickShortcutsTitle => 'Quick Create & Register Shortcuts:';
  @override String get createNewProject => 'Create New Project';
  @override String get createNewImportFile => 'Create Import File';
  @override String get createNewImportCompany => 'Create Import Company';
  @override String get createNewSupplier => 'Create Foreign Supplier';
  @override String get createNewPartnerBank => 'Create Partner / Bank';
  @override String get createNewCustomsTariff => 'Add Customs Tariff';
  @override String get createNewLocation => 'Add Ports & Locations';
  @override String get createNewCurrency => 'Add New Currency';
  @override String get createNewExchangeRate => 'Update Exchange Rate';
  @override String get interactiveOperationsBoardTitle => 'Interactive 6-Phase Operations Board';
  @override String get interactiveOperationsBoardDesc => 'Comprehensive visual board (6 Major Phases — 21 Operational Steps) supporting live multi-phase tracking and instant shipment movement.';
  @override String get openInteractiveBoard => 'Open Interactive Board';
  @override String get lifecycleBoardSummaryTitle => 'Shipment Operations Lifecycle Summary (21 Steps)';
  @override String get lifecycleBoardSummaryDesc => 'Live tracking of shipment files across 6 major phases and 21 detailed operational steps.';
  @override String get fullOperationsBoardButton => 'Full Operations Board (21 Steps) ↗️';
  @override String get shipmentCountUnit => 'Shipments';
  @override String get tasksCountUnit => 'Tasks';
  @override String get kpiTodaysTasks => "Today's Tasks";
  @override String get kpiTodaysTasksSub => 'Tasks to execute today';
  @override String get kpiPendingTasks => 'Pending Tasks';
  @override String get kpiPendingTasksSub => 'Incomplete tasks requiring action';
  @override String get kpiUpcomingShipments => 'Upcoming Shipments';
  @override String get kpiUpcomingShipmentsSub => 'Expected future arrivals';
  @override String get kpiArrivingThisWeek => 'Arriving This Week';
  @override String get kpiArrivingThisWeekSub => 'Vessel arrivals this week';
  @override String get kpiEtaChanges => 'ETA Changes';
  @override String get kpiEtaChangesSub => 'Arrival schedule updated';
  @override String get kpiWaitingPayment => 'Waiting For Payment';
  @override String get kpiWaitingPaymentSub => 'Pending financial approvals (Phase 2)';
  @override String get kpiWaitingForm4 => 'Waiting For Form 4';
  @override String get kpiWaitingForm4Sub => 'Bank Form 4 procedures pending';
  @override String get kpiPendingRequirements => 'Pending Requirements';
  @override String get kpiPendingRequirementsSub => 'Incomplete documents & approvals';
  @override String get kpiHighPriorityAlerts => 'High Priority Alerts';
  @override String get kpiHighPriorityAlertsSub => 'High / Critical priority alerts';
  @override String get retry => 'Retry';
  @override String get purchaseOrder => 'Purchase Order:';
}


