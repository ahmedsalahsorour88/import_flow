import 'package:flutter/material.dart';
import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

/// Base abstract class for ImportFlow ERP localization.
/// Access via: context.l10n.save  OR  AppLocalizations.of(context).save
abstract class AppLocalizations {
  const AppLocalizations();

  static AppLocalizations of(BuildContext context) {
    return _AppLocalizationsScope.of(context);
  }

  // ── Navigation / Sidebar ─────────────────────────────────────────────────
  String get appTitle;
  String get appSubtitle;
  String get masterData;
  String get masterDataSub;
  String get shipmentPlanning;
  String get shipmentPlanningSub;
  String get phase1;
  String get phase1Sub;
  String get phase2;
  String get phase2Sub;
  String get phase3;
  String get phase3Sub;
  String get phase4;
  String get phase4Sub;
  String get phase5;
  String get phase5Sub;
  String get phase6;
  String get phase6Sub;
  String get dashboardAndReports;
  String get dashboardAndReportsSub;

  // ── Sidebar Menu Items ────────────────────────────────────────────────────
  String get importCompanies;
  String get foreignSuppliers;
  String get partnersAndBanks;
  String get projectsAndCostCenters;
  String get portsAndLocations;
  String get incotermsRules;
  String get customsTariffSchedule;
  String get currenciesAndRates;
  String get importFiles;
  String get purchaseOrders;
  String get cbmCalculator;
  String get freightStudies;
  String get freightQuotations;
  String get customsStudies;
  String get clearanceQuotations;
  String get importRequirements;
  String get financeApprovals;
  String get acidOperations;
  String get freightBooking;
  String get freightAllocations;
  String get cargoShippingTracking;
  String get packingReconciliation;
  String get draftDocsReview;
  String get draftCOO;
  String get draftInspection;
  String get docsCustomsApproval;
  String get centralDocsHub;
  String get customsDutyEstimator;
  String get cargoXBlockchain;
  String get originalsCollection;
  String get bankForm4;
  String get customsDeclaration46;
  String get customsClearanceFollowup;
  String get drawingSamples;
  String get discrepancyDamage;
  String get finalCustomsPayment;
  String get demurrageDetention;
  String get goodsInTransit;
  String get warehouseReceiving;
  String get receivedShipmentsReport;
  String get landedCostSettlement;
  String get landedCostComparison;
  String get importFileFinalClosure;
  String get operationalDashboard;
  String get lifecycleBoard;
  String get masterShipmentReport;
  String get dynamicReportBuilder;
  String get quickUpdateEngine;
  String get smartTasksAndAlerts;
  String get systemAuditLogs;
  String get productionSyncHub;

  // ── Buttons ───────────────────────────────────────────────────────────────
  String get save;
  String get saveDraft;
  String get saveAndConfirm;
  String get updateRecord;
  String get cancel;
  String get close;
  String get resetForm;
  String get refresh;
  String get liveRefresh;
  String get edit;
  String get delete;
  String get viewDetails;
  String get print;
  String get exportExcel;
  String get exportPdf;
  String get importExcel;
  String get downloadTemplate;
  String get uploading;
  String get backToDashboard;

  // ── Common Messages ───────────────────────────────────────────────────────
  String get connectionError;
  String get connectionErrorDetail;
  String get retryConnection;
  String get loading;
  String get saving;
  String get noData;
  String get search;
  String get searchHint;
  String get clearSearch;
  String get ok;
  String get confirm;
  String get warning;
  String get error;
  String get success;
  String get importSuccessful;
  String get importWithAlerts;
  String get alertsErrors;
  String get preparingExport;
  String get dataActionsTitle;

  // ── System Info ───────────────────────────────────────────────────────────
  String get systemVersion;
  String get buildId;
  String get backendEngine;
  String get database;
  String get operatingMode;
  String get licenseAndRights;
  String get systemInfo;
  String get syncHub;
  String get expandSidebar;
  String get collapseSidebar;
  String get userOptions;
  String get logout;
  String get versionBadge;

  // ── Tooltips ─────────────────────────────────────────────────────────────
  String get viewDetailsTooltip;
  String get editTooltip;
  String get printTooltip;
  String get deleteTooltip;
  String get syncHubTooltip;
  String get systemInfoTooltip;
  String get backToDashboardTooltip;
  String get languageToggleTooltip;

  // ── Role Switcher ─────────────────────────────────────────────────────────
  String get switchAsAdmin;
  String get switchAsManager;
  String get switchAsSpecialist;
  String get productionSyncTitle;

  // ── Sidebar Search ────────────────────────────────────────────────────────
  String get quickSearch;

  // ── Operational Dashboard ───────────────────────────────────────────────────
  String get operationalDashboardTitle;
  String get priority;
  String get priorityAll;
  String get priorityLow;
  String get priorityMedium;
  String get priorityHigh;
  String get priorityCritical;
  String get customsBrokerLabel;
  String get allBrokers;
  String get quickSearchLabel;
  String get dashboardSearchHint;
  String get resetFilters;
  String get clearFilter;
  String get serverConnectionError;
  String get serverConnectionHint;
  String get matchingShipments;
  String get lastUpdated;
  String get noMatchingShipments;
  String get noMatchingShipmentsDesc;
  String get clearFiltersShowAll;
  String get currentPhase;
  String get operationalStep;
  String get unassigned;
  String get closedShipment;
  String get recordDailyUpdate;
  String get closeStopShipment;
  String get nextStepAction;
  String get responsiblePerson;
  String get executeStepNow;
  String get openShipmentTasks;
  String get manageAllTasks;
  String get taskCompletedSuccessfully;
  String get riskAlertsCenter;
  String get dailyCheckinsLog;
  String get addDailyUpdate;
  String get noDailyUpdates;
  String get aiSmartExtractorTitle;
  String get smartExtractSupplier;
  String get smartExtractCompany;
  String get smartExtractPartner;
  String get smartExtractBank;
  String get quickShortcutsTitle;
  String get createNewProject;
  String get createNewImportFile;
  String get createNewImportCompany;
  String get createNewSupplier;
  String get createNewPartnerBank;
  String get createNewCustomsTariff;
  String get createNewLocation;
  String get createNewCurrency;
  String get createNewExchangeRate;
  String get interactiveOperationsBoardTitle;
  String get interactiveOperationsBoardDesc;
  String get openInteractiveBoard;
  String get lifecycleBoardSummaryTitle;
  String get lifecycleBoardSummaryDesc;
  String get fullOperationsBoardButton;
  String get shipmentCountUnit;
  String get tasksCountUnit;
  String get kpiTodaysTasks;
  String get kpiTodaysTasksSub;
  String get kpiPendingTasks;
  String get kpiPendingTasksSub;
  String get kpiUpcomingShipments;
  String get kpiUpcomingShipmentsSub;
  String get kpiArrivingThisWeek;
  String get kpiArrivingThisWeekSub;
  String get kpiEtaChanges;
  String get kpiEtaChangesSub;
  String get kpiWaitingPayment;
  String get kpiWaitingPaymentSub;
  String get kpiWaitingForm4;
  String get kpiWaitingForm4Sub;
  String get kpiPendingRequirements;
  String get kpiPendingRequirementsSub;
  String get kpiHighPriorityAlerts;
  String get kpiHighPriorityAlertsSub;
  String get retry;
  String get purchaseOrder;
}



// ─────────────────────────────────────────────────────────────────────────────
// InheritedWidget scope
// ─────────────────────────────────────────────────────────────────────────────

class _AppLocalizationsScope extends InheritedWidget {
  final AppLocalizations localizations;

  const _AppLocalizationsScope({
    required this.localizations,
    required super.child,
  });

  static AppLocalizations of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_AppLocalizationsScope>();
    return scope?.localizations ?? const AppLocalizationsAr();
  }


  @override
  bool updateShouldNotify(_AppLocalizationsScope oldWidget) =>
      localizations != oldWidget.localizations;
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider widget
// ─────────────────────────────────────────────────────────────────────────────

class AppLocalizationsProvider extends StatelessWidget {
  final Locale locale;
  final Widget child;

  const AppLocalizationsProvider({
    super.key,
    required this.locale,
    required this.child,
  });

  static AppLocalizations resolve(Locale locale) {
    switch (locale.languageCode) {
      case 'ar':
        return const AppLocalizationsAr();
      case 'en':
      default:
        return const AppLocalizationsEn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AppLocalizationsScope(
      localizations: resolve(locale),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BuildContext extension
// ─────────────────────────────────────────────────────────────────────────────

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
