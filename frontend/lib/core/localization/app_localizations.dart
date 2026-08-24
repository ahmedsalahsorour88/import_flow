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

  // ── Screen 1: Import Files & Shipments ────────────────────────────────────
  String get importFilesManagementTitle;
  String get uploadImportDocument;
  String get addNewImportFile;
  String get editImportFile;
  String get generateComprehensiveReport;
  String get searchByShipmentOrCompany;
  String get statusAll;
  String get statusOpen;
  String get statusInProgress;
  String get statusClosed;
  String get importFileIdLabel;
  String get importingCompany;
  String get foreignSupplier;
  String get status;
  String get actions;
  String get poInvoiceLabel;
  String get transportModeIncoterm;
  String get priorityType;
  String get targetEta;
  String get currentPhaseStage;
  String get progressPercentLabel;
  String get nextActionLabel;
  String get responsiblePersonLabel;
  String get stopShipmentTooltip;
  String get reopenShipmentTooltip;
  String get freightRfqTooltip;
  String get printFileHistoryTooltip;
  String get noImportFilesFound;
  String get confirmDeleteImportFileTitle;
  String get confirmDeleteImportFileMessage;
  String get evaluateMasterReportTitle;
  String get selectShipmentForReport;
  String get allShipmentFiles;
  String get shipmentNoPrefix;
  String get createAndDisplayReport;
  String get masterImportReportTitle;
  String get filteredForShipment;
  String get printReport;
  String get filterReportByShipment;
  String get totalFilesMetric;
  String get openFilesMetric;
  String get inProgressMetric;
  String get totalCostMetric;
  String get operationalTrackingMatrixSection;
  String get cargoAndLinkedPosSection;
  String get invoicesCountAndNumbers;
  String get invoicesUnit;
  String get totalCbmFromPackingList;
  String get cbmSumDescription;
  String get totalGrossWeightFromPl;
  String get grossWeightSumDescription;
  String get linkedPurchaseOrdersTitle;
  String get posUnit;
  String get packingListsUnit;
  String get noLinkedPosForFile;
  String get paymentTermsLabel;
  String get packingListItemsCol;
  String get weightCbmCol;
  String get palletsShippingPlan;
  String get packingItemsCount;
  String get visualLoadPlannerTitle;
  String get containerLoadPlanButton;
  String get exportReportExcelPdf;
  String get reportCopiedToClipboard;
  String get csvExportSuccess;
  String get sideViewTitle;
  String get topViewTitle;
  String get internalDimensions;
  String get containerLoadFailed;
  String get containerOverfilled;
  String get containerEmpty;
  String get containerGoodUtil;
  String get allStackableChip;
  String get allNonStackableChip;
  String get mixedStackingChip;
  String get containerSpecType;
  String get requiredCount;
  String get effectiveCapacityCbm;
  String get spaceUtilizationPercent;
  String get weightUtilizationPercent;
  String get acidStatusTitle;
  String get customsReleasedBadge;
  String get underClearanceBadge;
  String get cargoStackingScenariosTitle;
  String get scenariosMatrixButton;
  String get scenarioAllStackableTitle;
  String get scenarioAllNonStackableTitle;
  String get scenarioMixedStackingTitle;
  String get savedShippingStudiesTitle;
  String get date;
  String get shipmentCategoryLabel;
  String get fileOpeningDateLabel;
  String get logisticsAndPortsDetails;
  String get portOfLoadingLabel;
  String get portOfDischargeLabel;
  String get cargoReadyDateLabel;
  String get targetFreeDaysLabel;
  String get serviceTypePreferenceLabel;
  String get pickupAddressLabel;
  String get shippingInstructionsLabel;
  String get multiProjectsTitle;
  String get notes;
  String get liveReload;
  String get clearAndReset;
  String get customsClearanceBroker;
  String get freightRfqTitle;
  String get emailDraftTab;
  String get whatsappTemplateTab;
  String get shipmentSpecsTab;
  String get grossWeightMetric;
  String get netWeightMetric;
  String get commodityTitle;
  String get closeShipmentTitle;
  String get reason;
  String get cbmVolumeMetric;
  String get currency;
  String get owner;
  String get purchaseOrdersTitle;
  String get purchaseOrdersSubtitle;
  String get smartInvoiceExtract;
  String get newPurchaseOrder;
  String get editPurchaseOrder;
  String get totalOrdersMetric;
  String get totalFobMetric;
  String get totalCargoCbmMetric;
  String get totalGrossWeightMetric;
  String get searchByPoHint;
  String get filterByProject;
  String get allProjects;
  String get filterByStatus;
  String get allStatuses;
  String get showInactive;
  String get poReferenceCol;
  String get invoiceDateCol;
  String get importFileCol;
  String get piNumberCol;
  String get countryOfOriginCol;
  String get actionsCol;
  String get poLineItemsTab;
  String get reviewPackingListTab;
  String get palletizationPlanTitle;
  String get totalPalletsMetric;
  String get palletSimulation3D;
  String get palletTypeCol;
  String get palletCountCol;
  String get palletDimensionsCol;
  String get palletWeightCol;
  String get palletTotalWeightCol;
  String get palletVolumeCol;
  String get palletStackingInstructionsCol;
  String get stackable;
  String get nonStackable;
  String get discrepancyWarningTitle;
  String get discrepancyJustificationLabel;
  String get backToEdit;
  String get continueAndSave;
  String get summaryByHsCodeReport;
  String get hsCode;
  String get quantityMetric;
  String get requiredField;
  String get saveChanges;
  String get noDataFound;

  // ── CBM Calculator ───────────────────────────────────────────────────────
  String get cbmCalculatorTitle;
  String get cbmCalculatorSubtitle;
  String get quickOperationalCalculatorTab;
  String get savedCalculationsRegistryTab;
  String get activeEditSessionBanner;
  String get activeEditSessionHint;
  String get saveChangesInSession;
  String get newBlankSession;
  String get totalCbmVolumeMetric;
  String get airChargeableWtMetric;
  String get volumetricWeight;
  String get recommendedShippingMetric;
  String get cargoStackingInstructions;
  String get stackableOption;
  String get nonStackableOption;
  String get allStackableOption;
  String get allNonStackableOption;
  String get mixedStackingOption;
  String get compareContainersMatrix;
  String get visualLoadPlanSimulator;
  String get packageMeasurementsTitle;
  String get airFreightMode;
  String get seaFreightMode;
  String get addPackageLine;
  String get saveCalculationSession;
  String get saveAsNewSession;
  String get unitCol;
  String get qtyCol;
  String get lengthCol;
  String get packageTypeCol;
  String get widthCol;
  String get heightCol;
  String get stackingCol;
  String get grossWtPerUnitCol;
  String get calculatedOutputsCol;
  String get deleteRowTooltip;
  String get calculationSessionTitle;
  String get notesAndCargoRemarks;
  String get containerOptionsAnalysis;
  String get totalShipmentSummary;
  String get approvedRecommendation;
  String get containerSpecCol;
  String get requiredCountCol;
  String get spaceUtilizationCol;
  String get weightUtilizationCol;
  String get recommendationCol;
  String get bestOptionBadge;
  String get viableAlternative;
  String get chooseStackingScenario;
  String get requiredFleet;
  String get containerPlanTitle;
  String get closePlan;
  String get totalCalculationsMetric;
  String get activeSessionsMetric;
  String get totalGrossWeightRegistryMetric;
  String get refreshRegistry;
  String get searchCalculationsHint;
  String get calcCodeCol;
  String get shippingStrategyCol;
  String get recommendedContainerCol;
  String get linkPoProjectCol;
  String get confirmSoftDelete;
  String get confirmDeleteCalcMessage;
  String get operationFailed;
  String get operationSuccessful;
  String get showDeleted;
  String get hideDeleted;
  String get restore;

  // ── Freight Studies (Shipping Scenarios) ───────────────────────────────────
  String get freightStudiesTitle;
  String get scenariosEvaluatorTab;
  String get savedEvaluationsLogTab;
  String get extractFreightQuotes;
  String get activeEditStudyBanner;
  String get activeEditStudyHint;
  String get cancelEditAndStartNew;
  String get avgWarehouseArrivalMetric;
  String get earliestLineMetric;
  String get latestLineMetric;
  String get recommendedLineMetric;
  String get studySetupAndParameters;
  String get studyTitleLabel;
  String get crdLabel;
  String get avgForm4DaysLabel;
  String get avgClearanceDaysLabel;
  String get cargoStackingType;
  String get shippingCarrierOptions;
  String get addNewShippingOption;
  String get freightForwarderCol;
  String get shippingLineCol;
  String get vesselNameCol;
  String get voyageCol;
  String get portOfLoadingCol;
  String get portOfDischargeCol;
  String get sailingDateCol;
  String get estimatedArrivalDateCol;
  String get expectedDelayCol;
  String get riskLevelCol;
  String get freeTimeDaysCol;
  String get quoteCurrencyCol;
  String get quoteDetails;
  String get hideQuote;
  String get totalQuoteValue;
  String get container40ftItem;
  String get container20ftItem;
  String get lclCbmItem;
  String get expressCourierItem;
  String get eurAtrItem;
  String get solasVgmItem;
  String get vgmNotificationItem;
  String get telexReleaseItem;
  String get insuranceItem;
  String get bookingCancellationItem;
  String get ics2FilingFeeItem;
  String get documentFeesItem;
  String get waiverLetterFeeItem;
  String get othersFeeItem;
  String get dthcItem;
  String get storagePerWeekItem;
  String get extraDayStorageItem;
  String get applicable;
  String get notApplicable;
  String get itemPriceCol;
  String get sideBySideComparison;
  String get saveAndSubmitStudy;
  String get saveDraftContinueLater;
  String get clearAndStartNew;
  String get totalStudiesMetric;
  String get avgTransitMetric;
  String get withRecommendationMetric;
  String get searchStudiesHint;
  String get studyCodeCol;
  String get optionsCountCol;
  String get confirmDeleteStudyMessage;
  String get quantity;
  String get activeStatus;
  String get noResultsFound;
  String get linkImportFile;
  String get titleField;
  String get linkPurchaseOrder;
  String get linkProject;
  String get confirmDelete;
  String get view;
  String get statusCol;

  // ── Screen 6: Customs Studies & Consultations ──────────────────────────
  String get customsStudiesTitle;
  String get customsWorkspaceTab;
  String get consultationsLogTab;
  String get brokerPriceListsTab;
  String get clearanceQuotesTab;
  String get taxReviewWorkspaceTab;
  String get taxReviewLogTab;
  String get customsDutyReviewTitle;
  String get customsInspectionReadiness;
  String get itemsAndDocsCount;
  String get blockingIssuesCount;
  String get clearanceReadyStatus;
  String get avgReadinessMetric;
  String get openBlockingIssues;
  String get searchConsultationsHint;
  String get statusFilterLabel;
  String get customsCalculationEngine;
  String get customsCalculationEngineSub;
  String get fetchReconciledFinalInvoice;
  String get syncHsRequirementsToChecklist;
  String get customsExchangeRate;
  String get studyDateLabel;
  String get freightEgpLabel;
  String get insuranceEgpLabel;
  String get customsTariffItemCol;
  String get itemDescriptionAndOriginCol;
  String get quantityAndUnitCol;
  String get fobEgpCol;
  String get cifEgpCol;
  String get customsDutyCol;
  String get vatCol;
  String get otherTaxesCol;
  String get totalTaxesAndDutiesCol;
  String get regulatoryRequirementsCol;
  String get customsChecklistTitle;
  String get addNewChecklistItem;
  String get responsiblePartyLabel;
  String get blockingConditionTooltip;
  String get nonBlockingConditionTooltip;
  String get applyAndLinkFinancialEstimate;
  String get smartClearanceQuoteExtractor;
  String get saveCustomsStudy;
  String get saveTaxReviewSession;
  String get saveConsultationChanges;
  String get consultationDetailsTitle;
  String get blockingIssuesTitle;
  String get nafezaDeclarationBreakdown;
  String get categoryCol;
  String get totalExpenses;
  String get export;
  String get allFiles;

  // ── Screen 8: Financial Approvals & Budgets ─────────────────────────────
  String get financialApprovalsTitle;
  String get paymentRequestsTab;
  String get importBudgetApprovalTab;
  String get savedBudgetsRegistryTab;
  String get paymentRequestsRegistryTab;
  String get swiftReconciliationTab;
  String get createPaymentRequestTitle;
  String get editPaymentRequestTitle;
  String get activeEditModeBanner;
  String get cancelEdit;
  String get paymentTitleLabel;
  String get paymentTypeLabel;
  String get requestedAmountLabel;
  String get beneficiarySupplierLabel;
  String get selectSupplierFromMasterData;
  String get beneficiaryBankDetails;
  String get bankNameLabel;
  String get swiftCodeLabel;
  String get ibanAccountLabel;
  String get requestDateLabel;
  String get dueDateLabel;
  String get paymentNotesLabel;
  String get issuePaymentRequestButton;
  String get savePaymentChangesButton;
  String get importBudgetSetupTitle;
  String get budgetTitleLabel;
  String get estimatedInvoiceValue;
  String get estimatedFreightCost;
  String get customsAndVatEstimate;
  String get clearanceAndTransportEstimate;
  String get budgetApprovalNotes;
  String get approveAndCertifyBudget;
  String get saveBudgetChanges;
  String get totalBudgetEgp;
  String get consolidatedBudgetSummary;
  String get totalBudgetsMetric;
  String get approvedBudgetsMetric;
  String get pendingBudgetsMetric;
  String get totalValueEgpMetric;
  String get searchBudgetsHint;
  String get searchPaymentsHint;
  String get paymentRequestsLogTitle;
  String get noMatchingPayments;
  String get noMatchingBudgets;
  String get swiftExtractorTitle;
  String get swiftUploadDocument;
  String get swiftPasteText;
  String get swiftMatchedSuccess;
  String get swiftExecuteReconciliation;
  String get paymentCodeCol;
  String get bankSwiftCol;
  String get equivalentEgpCol;
  String get requestDueDateCol;
  String get draftStatus;
  String get paidStatus;
  String get reconciledStatus;
  String get importFile;
  String get notLinked;
  String get currencyCol;
  String get exchangeRateCol;
  String get poNumberCol;
  String get projectNameCol;
  String get invoiceAmount;
  String get reset;
  String get budgetApprovalTab;
  String get savedBudgetsTab;
  String get paymentRequestsLogTab;
  String get paymentRequestHeader;
  String get paymentRequestSub;

  // ── Screen 11: Nafeza ACID Operations ───────────────────────────────────
  String get nafezaAcidTitle;
  String get acidRequestTab;
  String get smartMtsParserTab;
  String get discrepancyMatrixTab;
  String get acidRegistryTab;
  String get expiryTrackerTab;
  String get acidInfoBanner;
  String get selectImportFileAcidLabel;
  String get searchFileOrSupplierHint;
  String get importerAndExporterSection;
  String get importerSectionTitle;
  String get importerTaxIdLabel;
  String get importerAddressLabel;
  String get foreignExporterSectionTitle;
  String get foreignExporterIdLabel;
  String get regTypeLabel;
  String get countryOfOriginExportLabel;
  String get cargoxPlatformIdLabel;
  String get proformaPortsBrokerSection;
  String get proformaInvoiceNoLabel;
  String get proformaInvoiceDateLabel;
  String get invoiceTypeLabel;
  String get customsBrokerResponsibleLabel;
  String get brokerPhoneLabel;
  String get acidRequestDateLabel;
  String get saveAcidRequestButton;
  String get updateAcidRequestButton;
  String get goToSmartParserButton;
  String get brokerDispatchMessageTitle;
  String get brokerDispatchMessageSub;
  String get copyArabicWhatsApp;
  String get copyEnglishRequest;
  String get emailTemplateButton;
  String get smartParserInfoBanner;
  String get linkImportFileResult;
  String get pasteRawMtsTextTitle;
  String get loadSampleMtsTextButton;
  String get pasteFromClipboardButton;
  String get runSmartParserButton;
  String get clearTextButton;
  String get parsedMtsSuccessTitle;
  String get parsedMtsNoAcidTitle;
  String get goToVerificationButton;
  String get saveAndCertifyAcidButton;
  String get saveTempDraftButton;
  String get editExtractedDataButton;
  String get codeSupplierButton;
  String get acidNumberCol;
  String get issueDateCol;
  String get expiryDateCol;
  String get foreignExporterCol;
  String get importerCompanyCol;
  String get actionCol;
  String get daysRemainingCol;
  String get validityStatusCol;
  String get runDiscrepancyMatrixButton;
  String get perfectMatchTitle;
  String get discrepancyFoundTitle;
  String get customsFieldCol;
  String get requestedValueCol;
  String get generatedValueCol;
  String get matchingStatusCol;
  String get discrepancyOverrideJustificationLabel;
  String get verifyAndCertifyAcidButton;
  String get searchAcidRegistryHint;
  String get newAcidRequestButton;
  String get totalAcidsCard;
  String get validAcidsCard;
  String get expiringSoonAcidsCard;
  String get expiredAcidsCard;
  String get searchExpiryTrackerHint;
  String get validStatusBadge;
  String get expiringSoonStatusBadge;
  String get expiredStatusBadge;
  String get matchedStatus;
  String get discrepancyStatus;
  String get issuedAndValidStatus;
  String get tempDraftStatus;
  String get underReviewStatus;

  // ── Screen 16: Bank Form 4 ──────────────────────────────────────────────
  String get bankForm4Title;
  String get form4RequestTab;
  String get bankForm4RegistryTab;
  String bankForm4EditingBanner(String code);
  String get cancelEditNewForm4;
  String get selectImportFileForm4Label;
  String get bankApplicationDetailsSection;
  String get issuingBankLabel;
  String get selectBankHint;
  String get bankAmountLabel;
  String get transferCurrencyLabel;
  String get selectCurrencyHint;
  String get bankRequestDateLabel;
  String get bankNotesLabel;
  String get form4ChecklistSectionTitle;
  String get form4ItemProformaInvoice;
  String get form4ItemPackingList;
  String get form4ItemCertificateOfOrigin;
  String get form4ItemBillOfLading;
  String get form4ItemAcidNotice;
  String get form4ItemMarineInsurance;
  String get form4ItemBankApplication;
  String get form4ItemAdminFeeReceipt;
  String get saveForm4Button;
  String get updateForm4Button;
  String get goToBankRegistryButton;
  String get searchBankRegistryHint;
  String get newForm4RequestButton;
  String get documentCodeCol;
  String get certifiedBankCol;
  String get amountAndCurrencyCol;
  String get requestDateCol;
  String get endorsementStatusCol;
  String get endorsedStatusBadge;
  String get bankProcessingStatusBadge;
  String get selectImportFileFirstWarning;
  String get form4SavedSuccess;
  String get form4SaveError;
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
