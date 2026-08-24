# 🌐 Localization Review Log (i18n) — ImportFlow ERP

---

## 🏗️ Architecture Decisions

- **Localization System Used:** Custom Riverpod-driven `InheritedWidget` (`AppLocalizations` base class with typed getters, implemented by `AppLocalizationsAr` and `AppLocalizationsEn`, managed by `localeProvider` with `flutter_secure_storage` persistence).
- **Justification:** Zero external code-generation dependencies (`flutter gen-l10n` not required), 100% type-safe compilation, instant reactivity on toggle via Riverpod `ref.watch(localeProvider)`, automated RTL/LTR `Directionality` switching in `main.dart`.
- **Root Cause of the "Stacked Languages" Bug:**
  1. Widgets were hardcoded with bilingual strings concatenated together (e.g. `'الاسم / Name'` or `'إصدار المنظومة (Version)'`).
  2. Sidebar hubs and menu tiles used `Column` widgets displaying `titleEn` on line 1 and `titleAr` on line 2 simultaneously regardless of language mode.
  3. No central language switch mechanism existed to instruct widgets to select the single active locale.
- **Translation File Locations:**
  - Base Contract & Extension: `frontend/lib/core/localization/app_localizations.dart`
  - Arabic (ar): `frontend/lib/core/localization/app_localizations_ar.dart`
  - English (en): `frontend/lib/core/localization/app_localizations_en.dart`
  - State Provider: `frontend/lib/core/localization/locale_provider.dart`
- **Key Naming Convention:** CamelCase descriptive property getters (e.g. `save`, `cancel`, `masterData`, `importCompanies`, `systemVersion`, `syncHub`, `backToDashboardTooltip`).

---

## 📋 Session Log

### Session: Foundation, Core Widgets & App Shell (HomeScreen) — 2026-08-23

#### 1. Screens / Modules Fully Reviewed & Fixed
- **Core App Shell & Navigation:** `frontend/lib/features/home/home_screen.dart`
  - Fixed bilingual stacked titles in `_buildHubTile` and `_buildMenuItem` (now displays only primary title according to active locale).
  - Fixed hardcoded sidebar search bar, header, collapsed rail tooltips, user switcher, and system info dialog.
  - Added live language toggle button (`🌐`) in sidebar header.
- **Core Shared Toolbars & Buttons:**
  - `frontend/lib/core/widgets/standard_form_action_bar.dart` — All actions localized (`save`, `saveDraft`, `cancel`, `loading`).
  - `frontend/lib/core/widgets/master_data_toolbar.dart` — All export/import actions, alert dialogs, and tooltips localized.
  - `frontend/lib/core/widgets/row_actions_pill.dart` — View, edit, print, delete action tooltips localized.
  - `frontend/lib/core/widgets/back_to_dashboard_button.dart` — Label and tooltip localized.
- **Screen 0: Operational Workspace Dashboard (`frontend/lib/features/operational_dashboard/screens/operational_dashboard_screen.dart`):**
  - Replaced all bilingual concatenated titles and labels (e.g. `'الأولوية (Priority):'`, `'المخلص الجمركي (Customs Broker):'`, `'بحث سريع (Search):'`, `'جميع المخلصين (All Brokers)'`, `'سجل التحديثات التشغيلية واليومية المباشرة (Daily Check-ins & Live Log):'`, `'روابط الاختصارات السريعة لإنشاء وإدخال السجلات (Quick Create & Register Shortcuts):'`) with dynamic `context.l10n` getters.
  - Localized 6 lifecycle major phases and all 21 operational step titles with bilingual names (`name_ar` and `name_en`), and made chips responsive with `Expanded` to prevent RenderFlex overflow in English mode.
  - Localized all 9 Executive KPI Summary cards, empty state messages, connection error banners, next-step action cards, linked tasks section, and risk alerts center.
  - Created automated widget tests in `frontend/test/operational_dashboard_test.dart` to verify Arabic and English single-language rendering and confirm absence of stacked bilingual text.

#### 2. Translation Keys Added in this Session
- **Navigation & Hubs:** `appTitle`, `appSubtitle`, `masterData`, `masterDataSub`, `shipmentPlanning`, `shipmentPlanningSub`, `phase1`, `phase1Sub`, `phase2`, `phase2Sub`, `phase3`, `phase3Sub`, `phase4`, `phase4Sub`, `phase5`, `phase5Sub`, `phase6`, `phase6Sub`, `dashboardAndReports`, `dashboardAndReportsSub`.
- **Menu Items (30+ keys):** `importCompanies`, `foreignSuppliers`, `partnersAndBanks`, `projectsAndCostCenters`, `portsAndLocations`, `incotermsRules`, `customsTariffSchedule`, `currenciesAndRates`, `importFiles`, `purchaseOrders`, `cbmCalculator`, `freightStudies`, `freightQuotations`, `customsStudies`, `clearanceQuotations`, `regulatoryRequirements`, `financialApprovals`, `acidOperations`, `freightBooking`, `freightAllocations`, `cargoShippingTracking`, `poPackingReconciliation`, `draftBlReview`, `draftCooEur1`, `draftInspectionCoc`, `customsApproval`, `centralDocsHub`, `customsEstimator`, `cargoxBlockchain`, `originalsCollection`, `bankForm4`, `customsDeclaration46`, `customsClearanceFollowup`, `drawingSamples`, `discrepancyDamage`, `finalCustomsPayment`, `demurrageDetention`, `goodsInTransitLedger`, `warehouseReceiving`, `receivedShipmentsReport`, `landedCostSettlement`, `landedCostComparison`, `finalClosure`, `operationalDashboard`, `analyticsKpi`, `lifecycleBoard`, `auditLogs`.
- **Common Actions & Dialogs:** `save`, `cancel`, `saveDraft`, `delete`, `edit`, `viewDetails`, `print`, `exportExcel`, `exportPdf`, `downloadTemplate`, `importExcel`, `refresh`, `close`, `ok`, `confirm`, `retry`, `search`, `noDataFound`, `loading`, `language`, `english`, `arabic`, `switchLanguage`, `systemVersion`, `buildId`, `backendEngine`, `database`, `operatingMode`, `licenseAndRights`, `syncHub`.
- **Operational Dashboard Keys:** `operationalDashboardTitle`, `priority`, `priorityAll`, `priorityLow`, `priorityMedium`, `priorityHigh`, `priorityCritical`, `customsBrokerLabel`, `allBrokers`, `quickSearchLabel`, `dashboardSearchHint`, `resetFilters`, `clearFilter`, `serverConnectionError`, `serverConnectionHint`, `matchingShipments`, `lastUpdated`, `noMatchingShipments`, `noMatchingShipmentsDesc`, `clearFiltersShowAll`, `currentPhase`, `operationalStep`, `unassigned`, `closedShipment`, `recordDailyUpdate`, `closeStopShipment`, `nextStepAction`, `responsiblePerson`, `executeStepNow`, `openShipmentTasks`, `manageAllTasks`, `taskCompletedSuccessfully`, `riskAlertsCenter`, `dailyCheckinsLog`, `addDailyUpdate`, `noDailyUpdates`, `aiSmartExtractorTitle`, `smartExtractSupplier`, `smartExtractCompany`, `smartExtractPartner`, `smartExtractBank`, `quickShortcutsTitle`, `createNewProject`, `createNewImportFile`, `createNewImportCompany`, `createNewSupplier`, `createNewPartnerBank`, `createNewCustomsTariff`, `createNewLocation`, `createNewCurrency`, `createNewExchangeRate`, `interactiveOperationsBoardTitle`, `interactiveOperationsBoardDesc`, `openInteractiveBoard`, `lifecycleBoardSummaryTitle`, `lifecycleBoardSummaryDesc`, `fullOperationsBoardButton`, `shipmentCountUnit`, `tasksCountUnit`, `kpiTodaysTasks`, `kpiTodaysTasksSub`, `kpiPendingTasks`, `kpiPendingTasksSub`, `kpiUpcomingShipments`, `kpiUpcomingShipmentsSub`, `kpiArrivingThisWeek`, `kpiArrivingThisWeekSub`, `kpiEtaChanges`, `kpiEtaChangesSub`, `kpiWaitingPayment`, `kpiWaitingPaymentSub`, `kpiWaitingForm4`, `kpiWaitingForm4Sub`, `kpiPendingRequirements`, `kpiPendingRequirementsSub`, `kpiHighPriorityAlerts`, `kpiHighPriorityAlertsSub`, `retry`, `purchaseOrder`.

#### 3. Remaining Screens / Modules to Review (65 Total Screens)
- [x] Screen 0: Operational Dashboard (`operational_dashboard_screen.dart`) — **Reviewed & Fixed**
- [x] Screen 1: Import Files (`import_files_screen.dart` & sub-dialogs `import_file_details_dialog.dart`, `import_file_form_dialog.dart`, `freight_rfq_dialog.dart`, `close_shipment_dialog.dart`) — **Reviewed & Fixed**
- [x] Screen 2: Purchase Orders (`PurchaseOrdersScreen` & sub-dialogs `purchase_orders_screen.dart`, `po_form_dialog.dart`, `po_reconciliation_warning_dialog.dart`) — **Reviewed & Fixed**
- [x] Screen 3: CBM Calculator (`cbm_calculator_screen.dart`, `saved_cbm_registry_tab.dart`, save & load plan modals) — **Reviewed & Fixed**
- [x] Screen 4: Freight Studies (`shipping_scenarios_screen.dart` & `saved_scenarios_registry_tab.dart`) — **Reviewed & Fixed**
- [x] Screen 6: Customs Studies & Consultations (`customs_consultation_screen.dart` & sub-widgets `saved_consultations_tab.dart`, `consultation_details_dialog.dart`, `blocking_issues_dialog.dart`, `nafeza_fee_breakdown_card.dart`, `recalculation_variance_comparison_card.dart`, `broker_quote_details_card.dart`, `add_checklist_item_dialog.dart`, `add_custom_expense_dialog.dart`, `add_custom_broker_expense_row_dialog.dart`, `post_save_status_dialog.dart`, `broker_price_lists_tab.dart`) — **Reviewed & Fixed**
- [x] Screen 8: Financial Approvals (`FinancialApprovalScreen`, `saved_budgets_registry_tab.dart`, `swift_reconciliation_screen.dart`, export dialogs) — **Reviewed & Fixed**
- [x] Screen 11: ACID Operations (`NafezaAcidScreen` / `nafeza_acid_screen.dart`) — **Reviewed & Fixed**
- [x] Screen 16: Bank Form 4 (`BankForm4Screen` / `bank_form4_screen.dart`) — **Reviewed & Fixed**
- [x] Screen 18: Draft B/L Review (`DraftBLReviewTab` / `draft_bl_review_tab.dart` & `VisualDraftBLSheet` / `visual_draft_bl_sheet.dart`) — **Reviewed & Fixed**
- [x] Screen 19: Draft COO / EUR.1 (`COOReviewTab` in `coo_review_tab.dart` & `VisualDraftCOOSheet` in `visual_draft_coo_sheet.dart`) — **Reviewed & Fixed**
- [x] Screen 20: Customs Docs Approval (`CustomsDocumentApprovalTab` in `customs_document_approval_tab.dart` & sub-dialogs `_CommercialReviewDialog`, `_CustomsBrokerReviewDialog`, `_RaiseTicketDialog`, `_ResolveTicketDialog`) — **Reviewed & Fixed**
- [x] Screen 21: PO & Packing Reconciliation (`POReconciliationTab` in `po_reconciliation_tab.dart` & `POReconciliationWarningDialog` in `po_reconciliation_warning_dialog.dart`) — **Reviewed & Fixed**
- [x] Screen 23: Customs Declaration 46 (`CustomsDeclaration46Screen` in `customs_declaration46_screen.dart`) — **Reviewed & Fixed**
- [x] Screen 24: Customs Clearance Management (`CustomsClearanceScreen` in `customs_clearance_screen.dart`) — **Reviewed & Fixed**
- [x] Screen 25: Freight Booking (`FreightBookingScreen` in `freight_booking_screen.dart` and dialogs `_FreightBookingFormDialog`, `_FreightBookingViewDialog`, `_FreightBookingPrintDialog`) — **Reviewed & Fixed**
- [ ] Screen 26: Freight Allocations (`FreightAllocationsScreen`)
- [ ] Screen 27: Clearance Follow-up (`ClearanceFollowupScreen`)
- [ ] Screen 28: Warehouse Receiving GRN (`WarehouseReceivingScreen`)
- [ ] Screen 29: Landed Cost Settlement (`LandedCostSettlementScreen`)
- [ ] Screen 30: Import File Closure (`ImportFileClosureScreen`)
- [ ] Screen 31: Projects & Cost Centers (`ProjectsScreen`)
- [ ] Screen 32: Import Companies (`ImportCompaniesScreen`)
- [ ] Screen 33: Foreign Suppliers (`SuppliersScreen`)
- [ ] Screen 34: Partners & Banks (`PartnersScreen`)
- [ ] Screen 35: Incoterms Rules (`IncotermsScreen`)
- [ ] Screen 36: Customs Tariff Schedule (`CustomsTariffScreen`)
- [ ] Screen 37: Ports & Transport Locations (`TransportLocationsScreen`)
- [ ] Screen 38: Currencies & Exchange Rates (`CurrenciesScreen`)
- [ ] Screen 43: Regulatory Requirements (`RegulatoryRequirementsScreen`)
- [ ] Screen 44: Demurrage & Detention (`DemurrageDetentionScreen`)
- [ ] Screen 47: Audit Logs (`AuditLogsScreen`)
- [ ] Screen 48: Lifecycle Kanban Board (`LifecycleBoardScreen`)
- [ ] Screen 49: Freight Quotations Comparison (`FreightQuotationsScreen`)
- [ ] Screen 50: Landed Cost Comparison (`LandedCostComparisonScreen`)
- [ ] Screen 51: Central Docs Hub (`CentralDocsHubScreen`)
- [ ] Screen 52: Cargo Shipping Tracking (`CargoShippingScreen`)
- [ ] Screen 53: Draft Inspection COC (`DraftInspectionScreen`)
- [ ] Screen 54: CargoX Blockchain Hub (`CargoXScreen`)
- [ ] Screen 55: Clearance Quotations Extractor (`CustomsClearanceQuotationsScreen`)
- [ ] Screen 56: Customs Duty Estimator (`CustomsDutyEstimatorScreen`)
- [ ] Screen 57: Originals Collection & Courier (`OriginalsCollectionScreen`)
- [ ] Screen 59: Production Sync Screen (`ProductionSyncScreen`)
- [ ] Screens 60-64: Customs subtabs, GIT Ledger, Received Shipments Report

---

**Last Screen Fully Fixed:** `Screen 25: Freight Booking (FreightBookingScreen in freight_booking_screen.dart)`  
**Next Screen to Review:** `Screen 26: Freight Allocations (FreightAllocationsScreen / freight_allocations_screen.dart)`












