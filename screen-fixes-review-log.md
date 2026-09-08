# 📋 Screen-by-Screen Review Log: Localization (i18n) & Copy Data Enablement

---

## 📌 Current Review Status
- **Last screen where ALL tasks (A, B, C) were fully completed:** Screen 34: Master Data - External Partners & Service Providers (Partners & Banks) (`frontend/lib/features/external_service_providers/screens/partners_screen.dart`)
- **Next screen to review:** Screen 35: Reference Data - Incoterms Rules (`frontend/lib/features/incoterms/screens/incoterms_screen.dart`)

---

## 📝 Session Log: Screen 34: Master Data - External Partners & Service Providers (Partners & Banks) (MD-003) — 2026-09-08
- **Target Files:**
  - `frontend/lib/features/external_service_providers/screens/partners_screen.dart` (Partners registry, category filter chips, search bar, active switch, add/edit dialog, table actions)
  - `frontend/lib/features/external_service_providers/widgets/partner_details_dialog.dart` (Comprehensive partner profile, contact info, banking identifiers, rating & notes)
  - `frontend/lib/features/external_service_providers/widgets/partner_scorecard_dialog.dart` (Partner performance scorecard, SLA ratings, on-time clearance, dispute frequency, responsiveness)
  - `frontend/lib/features/external_service_providers/widgets/partner_statement_of_account_dialog.dart` (Partner financial ledger, credit/debit statement, balance tracking, TSV export)
  - `frontend/lib/core/services/master_data_export_service.dart` (Partner PDF, Excel, WhatsApp, and Email export templates)
- **Route Index:** `34`
- **Task A (Localization / i18n):** Complete.
  - Added 42 new localization getters across `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`:
    - Screen actions & tooltips: `partnersExportTsvBtn`, `partnersExportTsvSuccess`, `partnersCopyFieldTooltip`, `partnerCopySummaryBtn`, `partnerCopySummarySuccess`, `partnerScorecardTooltip`, `partnerScorecardBtn`, `partnerCodeBadgeLabel`, `partnerStatementOfAccountTooltip`, `partnerStatementOfAccountBtn`.
    - TSV column headers: `partnersTsvHeaderCode`, `partnersTsvHeaderName`, `partnersTsvHeaderCategories`, `partnersTsvHeaderCountry`, `partnersTsvHeaderAddress`, `partnersTsvHeaderPhone`, `partnersTsvHeaderMobile`, `partnersTsvHeaderFax`, `partnersTsvHeaderEmail`, `partnersTsvHeaderSecondaryEmail`, `partnersTsvHeaderWebsite`, `partnersTsvHeaderSwift`, `partnersTsvHeaderScac`, `partnersTsvHeaderLicense`, `partnersTsvHeaderCommercialReg`, `partnersTsvHeaderTaxId`, `partnersTsvHeaderStatus`, `partnersTsvHeaderNotes`.
    - Scorecard metrics & ratings: `scorecardDialogTitle`, `scorecardPartnerSubtitle`, `scorecardTierLabel`, `scorecardTotalJobs`, `scorecardKpiHeader`, `scorecardClearanceSlaLabel`, `scorecardDocsAccuracyLabel`, `scorecardResponseTimeLabel`, `scorecardDisputeFreqLabel`, `scorecardPricingAdherenceLabel`, `scorecardOverallScoreLabel`, `scorecardPerfExcellent`, `scorecardPerfGood`, `scorecardPerfAverage`, `scorecardPerfPoor`.
    - Statement of Account: `partnerSoaExportTsvBtn`, `partnerSoaExportTsvSuccess`.
    - Category: `partnerCatInsuranceCompany`.
  - Purified 6 existing Arabic getters (`partnerNameLabel`: 'اسم الشريك / الجهة', `partnerNameHint`: 'مثال: البنك الأهلي المصري', `diffPartnerName`: 'اسم الشريك', `diffConfirmPartnerTitle`: 'تأكيد تعديل بيانات الشريك', `phoneMobileDetailLabel`: 'الهاتف والمحمول', `ledgerDescriptionCol`: 'البيان / تفاصيل المعاملة') eliminating dual slashes and Latin characters.
  - Purified `master_data_export_service.dart` partner templates (PDF, Excel, WhatsApp, Email) removing Latin words (`Partner`, `Tax ID`, `Commercial Register`, `SWIFT`, `SCAC`) and replacing `EGP` with `ج.م`.
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped `PartnersScreen` scaffold body in top-level `SelectionArea` for mouse drag selection across entire table, filter chips, and dialogs.
  - Added copyable partner code badge with tooltip and explicit company name copy button using `CopyHelper.copy(context, ..., customMessage: ...)`.
  - Added copy suffix buttons (`CopyHelper.copy`) to all 17 dialog form inputs (`nameCtrl`, `swiftCtrl`, `bankCodeCtrl`, `branchCtrl`, `scacCtrl`, `trackingCtrl`, `licenseCtrl`, `taxIdCtrl`, `regCtrl`, `emailCtrl`, `secondaryEmailCtrl`, `phoneCtrl`, `mobileCtrl`, `faxCtrl`, `websiteCtrl`, `addressCtrl`, `countryCtrl`).
  - Wrapped `PartnerDetailsDialog`, `PartnerScorecardDialog`, and `PartnerStatementOfAccountDialog` in top-level `SelectionArea`.
  - Converted clipboard operations to `CopyHelper.copy` with localized confirmation toasts.
- **Task C (Linked Outputs / TSV Export):** Complete.
  - **Single-Click Partners TSV Export (`_copyPartnersTsv`):** Added a dedicated "Export Partners (TSV)" button in top action toolbar copying all active partner records with active-locale column headers.
  - **Single Partner Summary Copy (`_buildPartnerSummary`):** Added quick-copy summary icon button (`Icons.copy_all_rounded`) to each table row and details dialog, copying complete partner profile to clipboard.
  - **Statement of Account TSV Export (`_copySoaTsv`):** Added a dedicated "Export Ledger (TSV)" button in `PartnerStatementOfAccountDialog`.
  - Hardened error state with `SingleChildScrollView` and `maxLines: 4, overflow: TextOverflow.ellipsis` to prevent RenderFlex overflow.
- **Verification:**
  - `flutter analyze lib/features/external_service_providers/ lib/core/localization/ lib/core/services/master_data_export_service.dart test/` ➔ **0 issues found (100% clean)!** ✅
  - `flutter test test/partners_localization_test.dart` ➔ **2/2 tests passed (100%)** ✅
  - `flutter test test/partner_model_test.dart` ➔ **3/3 tests passed (100%)** ✅
  - `flutter test test/perf/screen_34_partners_perf_test.dart` ➔ **1/1 benchmark passed (Nav-IN First Frame: 76.7ms | Settled: 115.7ms | Nav-OUT: 21.0ms)** ✅
  - `flutter test test/perf/partner_details_dialog_perf_test.dart` ➔ **1/1 benchmark passed** ✅
  - `flutter test test/perf/partner_scorecard_dialog_perf_test.dart` ➔ **1/1 benchmark passed** ✅
  - `flutter test test/perf/partner_statement_of_account_dialog_perf_test.dart` ➔ **1/1 benchmark passed** ✅

---

## 📝 Session Log: Screen 33: Master Data - Foreign Suppliers (MD-002) — 2026-09-08
- **Target Files:**
  - `frontend/lib/features/suppliers/screens/suppliers_screen.dart` (Foreign suppliers registry, classification filters, active toggle, create/edit dialog, search bar)
  - `frontend/lib/features/suppliers/widgets/supplier_details_dialog.dart` (Comprehensive supplier profile, bank details, contacts, performance rating)
  - `frontend/lib/features/suppliers/widgets/route_intelligence_dialog.dart` (AI shipping route intelligence, sea/air transit time, port pairs, carrier freight cost analysis)
  - `frontend/lib/features/suppliers/widgets/goeic_verification_dialog.dart` (Egyptian GOEIC decree 43 factory compliance verification, registration status & audit verdict)
- **Route Index:** `33`
- **Task A (Localization / i18n):** Complete.
  - Added 57 new localization getters across `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`:
    - Dialog tooltips & actions: `suppliersCopyFieldTooltip`, `suppliersExportTsvBtn`, `suppliersExportTsvSuccess`, `supplierCopySummaryBtn`, `supplierCopySummarySuccess`, `routeIntelligenceBtnTooltip`, `goeicVerificationBtnTooltip`, `supplierCodeBadgeLabel`, `retryConnectionBtn`.
    - TSV column headers: `suppliersTsvHeaderCode`, `suppliersTsvHeaderName`, `suppliersTsvHeaderCountry`, `suppliersTsvHeaderCity`, `suppliersTsvHeaderType`, `suppliersTsvHeaderEmail`, `suppliersTsvHeaderPhone`, `suppliersTsvHeaderContact`, `suppliersTsvHeaderCurrency`, `suppliersTsvHeaderPaymentTerms`, `suppliersTsvHeaderIncoterm`, `suppliersTsvHeaderTaxId`, `suppliersTsvHeaderRegistrationNo`, `suppliersTsvHeaderGoeicStatus`, `suppliersTsvHeaderStatus`, `suppliersTsvHeaderRating`, `suppliersTsvHeaderNotes`.
    - Route intelligence: `routeOriginCountryPort`, `routeDestinationEgyptPort`, `routeDirectLine`, `routeTransshipment`, `routeTransitDays`, `routeAvgCostLabel`, `routeHistoricalReliability`, `routeCarrierRecommendations`, `routeBestRate`, `routeBestSpeed`, `routeBestReliability`, `routeSeaMode`, `routeAirMode`.
    - GOEIC verification: `goeicVerificationTitle`, `goeicDecree43Subtitle`, `goeicFactoryNameLabel`, `goeicBrandLabel`, `goeicCountryLabel`, `goeicCategoryLabel`, `goeicDecreeRegLabel`, `goeicStatusValid`, `goeicStatusSuspended`, `goeicStatusExpired`, `goeicStatusUnderReview`, `goeicStatusNotRegistered`, `goeicSearchBtn`, `goeicComplianceVerdictTitle`, `goeicClearanceAllowedLabel`, `goeicCargoXAllowedLabel`, `goeicAcidAllowedLabel`, `goeicAuditNotesLabel`.
  - Purified 3 existing Arabic getters (`supplierTypeManufacturer`: `'مصنع إنتاج مباشر'`, `supplierTypeTrader`: `'شركة تجارية وتوريدات'`, `supplierTypeAgent`: `'وكيل تجاري معتمد'`) eliminating all Latin characters and dual slashes.
  - Replaced hardcoded Arabic and English strings across `suppliers_screen.dart`, `supplier_details_dialog.dart`, `route_intelligence_dialog.dart`, and `goeic_verification_dialog.dart` with localized getters.
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped `SuppliersScreen` scaffold body in top-level `SelectionArea` for mouse drag selection across cards, headers, and dialogs.
  - Added copyable supplier code badge (`supplierCodeBadgeLabel`) and explicit company name copy button (`suppliersCopyFieldTooltip`) using `CopyHelper.copy`.
  - Added copy suffix buttons (`CopyHelper.copy`) to all 18 form inputs in `_showSupplierDialog` (`nameCtrl`, `legalNameCtrl`, `countryCtrl`, `cityCtrl`, `addressCtrl`, `contactPersonCtrl`, `emailCtrl`, `phoneCtrl`, `websiteCtrl`, `taxIdCtrl`, `crCtrl`, `leadTimeCtrl`, `currencyCtrl`, `termsCtrl`, `incotermCtrl`, `bankNameCtrl`, `ibanCtrl`, `swiftCtrl`, `notesCtrl`).
  - Wrapped `SupplierDetailsDialog`, `RouteIntelligenceDialog`, and `GoeicVerificationDialog` in top-level `SelectionArea`.
  - Converted manual clipboard handling in `SupplierDetailsDialog` to `CopyHelper.copy`.
- **Task C (Linked Outputs / TSV Export):** Complete.
  - **Single-Click Suppliers TSV Export (`_copySuppliersTsv`):** Added a dedicated "Export Suppliers (TSV)" button in the top action toolbar copying all active supplier records with active-locale column headers.
  - **Single Supplier Summary Copy (`_buildSupplierSummary`):** Added a quick-copy summary icon button (`Icons.copy_all_rounded`) to each supplier card and details dialog, copying complete supplier dossier to clipboard.
  - Hardened error state with `SingleChildScrollView` and `maxLines: 4, overflow: TextOverflow.ellipsis` to ensure zero RenderFlex overflow on network errors.
- **Verification:**
  - `flutter analyze lib/features/suppliers/ lib/core/localization/ test/suppliers_localization_test.dart` ➔ **0 issues found (100% clean)!** ✅
  - `flutter test test/suppliers_localization_test.dart` ➔ **2/2 tests passed (100%)** ✅
  - `flutter test test/supplier_model_test.dart` ➔ **2/2 tests passed (100%)** ✅
  - `flutter test test/perf/screen_33_suppliers_perf_test.dart` ➔ **1/1 benchmark passed (Nav-IN First Frame: 58.0ms | Settled: 84.0ms | Nav-OUT: 17.7ms)** ✅
  - `flutter test test/perf/supplier_details_dialog_perf_test.dart` ➔ **1/1 benchmark passed (Nav-IN First Frame: 162ms | Settled: 168ms | Nav-OUT: 22ms)** ✅

---

## 📝 Session Log: Screen 32: Master Data - Egyptian Import Companies (MD-001) — 2026-09-08
- **Target Files:**
  - `frontend/lib/features/import_companies/screens/import_companies_screen.dart` (Import companies registry, card ID & expiry validation, creation/edit dialog, status toggle, search bar)
  - `frontend/lib/features/import_companies/widgets/import_company_details_dialog.dart` (Comprehensive importer company dossier, WhatsApp/Email templates preview)
  - `frontend/lib/core/widgets/custom_text_field.dart` (Enhanced with optional `suffixIcon` for copy buttons)
- **Route Index:** `32`
- **Task A (Localization / i18n):** Complete.
  - Added 21 new localization getters across `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`:
    - `importCompaniesCopyFieldTooltip`, `importCompaniesExportTsvBtn`, `importCompaniesExportTsvSuccess`, `importCompanyCopySummaryBtn`, `importCompanyCopySummarySuccess`, TSV column headers (`importCompaniesTsvHeaderCode`, `importCompaniesTsvHeaderName`, `importCompaniesTsvHeaderImporterCard`, `importCompaniesTsvHeaderImporterCardExpiry`, `importCompaniesTsvHeaderVatId`, `importCompaniesTsvHeaderVatExpiry`, `importCompaniesTsvHeaderComReg`, `importCompaniesTsvHeaderComRegExpiry`, `importCompaniesTsvHeaderCountry`, `importCompaniesTsvHeaderAddress`, `importCompaniesTsvHeaderPhone`, `importCompaniesTsvHeaderStatus`, `importCompaniesTsvHeaderNotes`), and short badge labels (`importerCardIdLabelShort`, `vatTaxIdLabelShort`, `commercialRegLabelShort`).
  - Purified 6 existing Arabic getters (`printSavePdfBtn`: `'طباعة وحفظ المستند 🖨️'`, `downloadExcelBtn`: `'تصدير جدول بيانات 📊'`, `whatsappShareBtn`: `'مشاركة واتساب 💬'`, `emailShareBtn`: `'مشاركة بريد إلكتروني ✉️'`, `copyWhatsappTextBtn`: `'نسخ نص رسالة الواتساب 📋'`, `copyEmailTextBtn`: `'نسخ نص وموضوع البريد الإلكتروني 📋'`) eliminating all Latin characters (`PDF`, `EXCEL`, `WhatsApp`, `Email`) and dual slashes.
  - Replaced hardcoded Arabic tooltips and button labels with localized getters across screen and details dialog.
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped `ImportCompaniesScreen` scaffold body in top-level `SelectionArea` for mouse drag selection across all company cards, status indicators, and headers.
  - Enhanced `CustomTextField` with `suffixIcon` support, adding explicit copy buttons (`CopyHelper.copy`) to all 7 dialog input fields (`nameCtrl`, `addressCtrl`, `countryCtrl`, `impIdCtrl`, `vatIdCtrl`, `regNumCtrl`, `phoneCtrl`).
  - Implemented `_buildCopyableIdBadge(...)` rendering Importer Card ID, VAT ID, and Commercial Reg No as dedicated clickable copy badges with copy icons and tooltips.
  - Replaced hardcoded clipboard calls in `import_company_details_dialog.dart` with `CopyHelper.copy` and wrapped dialog body in `SelectionArea`.
- **Task C (Linked Outputs / TSV Export):** Complete.
  - **Single-Click Companies TSV Export (`_copyCompaniesTsv`):** Added a dedicated "Export Importers (TSV)" button in the top action toolbar copying all active records with localized headers, tab-separated, and ready for spreadsheet ingestion.
  - **Single Company Summary Copy (`_buildCompanySummary`):** Added a quick-copy summary icon button (`Icons.copy_all_rounded`) to each company list tile, copying complete company dossier to clipboard.
  - **Details Dialog Full Copy:** Connected "Copy Full Dossier" button in `import_company_details_dialog.dart` to `CopyHelper.copy` with localized confirmation toast (`importCompanyCopySummarySuccess`).
- **Verification:**
  - `flutter analyze lib/features/import_companies/ lib/core/widgets/custom_text_field.dart lib/core/localization/` ➔ **0 issues found (100% clean)!** ✅
  - `flutter test test/import_companies_localization_test.dart` ➔ **2/2 tests passed (100%)** ✅
  - `flutter test test/import_company_model_test.dart` ➔ **2/2 tests passed (100%)** ✅
  - `flutter test test/perf/screen_32_import_companies_perf_test.dart` ➔ **1/1 benchmark passed (Nav-IN First Frame: 58.3ms | Settled: 82.0ms | Nav-OUT: 15.7ms)** ✅
  - `flutter test test/perf/import_company_details_dialog_perf_test.dart` ➔ **1/1 benchmark passed (Nav-IN First Frame: 179ms | Settled: 184ms | Nav-OUT: 20ms)** ✅

---

## 📝 Session Log: Screen 31: Master Data - Projects & Cost Centers — 2026-09-08
- **Target Files:**
  - `frontend/lib/features/projects/screens/projects_screen.dart` (Import projects registry, multi-company/shipment capabilities, project creation/edit dialog, status filtering, table listing)
- **Route Index:** `31`
- **Task A (Localization / i18n):** Complete.
  - Added 17 new localization getters across `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`:
    - `projectsCopyFieldTooltip`, `projectsExportTsvBtn`, `projectsExportTsvSuccess`, `projectCopySummaryBtn`, `projectCopySummarySuccess`, `projectBudgetNotSet`, `projectIncotermFallback`, `projectColActive`, `projectColShipmentCategories`, `projectActiveYes`, `projectActiveNo`, `projectMultiShipmentYes`, `projectMultiShipmentNo`, `projectMultiCompanyYes`, `projectMultiCompanyNo`, `projectNotesFallback`, `projectsToolbarTitle`.
  - Purified 11 existing Arabic keys in `app_localizations_ar.dart` eliminating all Latin acronyms (`USD`, `Multi-Shipment`, `Multi-Company`, `FCL`, `LCL`, `Bulk`, `Incoterm`) and all bilingual slashes (`/`).
  - Replaced hardcoded English fallbacks (`"Incoterm"`, `'N/A'`) with dynamic localized getters (`projectIncotermFallback`, `projectBudgetNotSet`).
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped `ProjectsScreen` scaffold body in top-level `SelectionArea` for seamless mouse drag selection across all labels, titles, chips, and table cells.
  - Wrapped `_showProjectDialog` content in `SelectionArea`.
  - Wrapped project deactivation/activation confirmation `AlertDialog` in `SelectionArea`.
  - Wrapped `p.projectCode` and `p.projectName` in `CopyableText`.
  - Converted all cells in the projects `Table` to `CopyableTableCell` with complete tab-separated row summaries for right-click copy actions.
  - Added copy suffix buttons (`CopyHelper.copy`) with tooltips to all 4 dialog inputs (`nameCtrl`, `ownerCtrl`, `budgetCtrl`, `notesCtrl`).
- **Task C (Linked Outputs / TSV Export):** Complete.
  - **Single-Click Projects TSV Export (`_copyProjectsTsv`):** Added a dedicated "Export Projects (TSV)" button in the top action toolbar copying all active project records with active-locale column headers.
  - **Single Project Summary Copy (`_buildProjectSummary`):** Upgraded `RowActionsPill.onPrint` to copy a comprehensive multi-line project specification directly to the clipboard with localized confirmation feedback (`projectCopySummarySuccess`).
- **Verification:**
  - `flutter analyze lib/features/projects/ lib/core/localization/ test/projects_localization_test.dart` ➔ **0 issues found (100% clean)!** ✅
  - `flutter test test/projects_localization_test.dart` ➔ **2/2 tests passed (100%)** ✅
  - `flutter test test/perf/screen_31_projects_perf_test.dart` ➔ **1/1 benchmark passed (Nav-IN First Frame: 50.7ms | Settled: 76.7ms | Nav-OUT: 17.0ms)** ✅

---

## 📝 Session Log: Screen 30: File Closure & Archival (CLR-01) — 2026-09-08
- **Target Files:**
  - `frontend/lib/features/file_closure/screens/file_closure_screen.dart` (Shipment closure checklist, audit certification vault, archived files list, closure certification dialog)
  - `frontend/lib/core/widgets/reopen_shipment_dialog.dart` (Managerial shipment reopening authorization dialog)
- **Route Index:** `30`
- **Task A (Localization / i18n):** Complete.
  - Added 22 new localization getters/methods across `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`:
    - `fileClosureCopyFieldTooltip`, `fileClosureExportTsvBtn`, `fileClosureExportTsvSuccess`, `fileClosureCopyCertTsvBtn`, `fileClosureCopyCertSuccess`, `fileClosurePrintSuccess(code)`, `fileClosureDraftSavedSuccess(pct, completed)`, `fileClosureCertifiedSuccess`, `fileClosureChecklistCompletionLabel`, `fileClosureSaveDraftTip`, `fileClosureSaveDraftBtn`, and 11 TSV column headers (`fileClosureColClosureCode`, `fileClosureColImportFile`, `fileClosureColArchiveVault`, `fileClosureColAuditor`, `fileClosureColClosedDate`, `fileClosureColDocsVerified`, `fileClosureColCustomsCleared`, `fileClosureColWarehouseReceived`, `fileClosureColLandedCostSettled`, `fileClosureColTasksClosed`, `fileClosureColNotes`).
  - Purified all Arabic translations to 100% Arabic without any Latin characters or bilingual slashes (`/`).
  - Replaced hardcoded inline Arabic strings and ternary conditions in `_FileClosureFormDialog` with dynamic localized getters.
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped `FileClosureScreen` scaffold body in top-level `SelectionArea` for seamless mouse drag selection across all text and labels.
  - Wrapped `ReopenShipmentDialog` content in `SelectionArea` and added copy suffix icon button to `_reasonController`.
  - Wrapped `cf.importFileCode`, `r.closureCode`, file titles, vault locations, and auditor labels in `CopyableText`.
  - Added copy suffix buttons (`CopyHelper.copy`) with tooltips to all 3 form inputs in `_FileClosureFormDialog` (`_auditorCtrl`, `_vaultCtrl`, `_notesCtrl`).
  - Wrapped all certificate audit details in `SelectionArea` and converted metadata fields to `CopyableText`.
- **Task C (Linked Outputs / TSV Export):** Complete.
  - **Single-Click Archived Files TSV Export (`_copyArchivedFilesTsv`):** Added a dedicated "Export Archived Files (TSV)" button in the top action toolbar copying all archived closure files with active-locale column headers.
  - **Certificate Summary Copy (`_copySingleCertificateSummary`):** Added "Copy Certificate Data" button to each card row and inside the certificate view dialog, formatted with complete checklist status and auditor details.
  - Upgraded `RowActionsPill.onPrint` to trigger comprehensive certificate summary copy with localized snackbar confirmation (`fileClosurePrintSuccess`).
- **Verification:**
  - `flutter analyze lib/features/file_closure/ lib/core/widgets/reopen_shipment_dialog.dart lib/core/localization/ test/file_closure_localization_test.dart` ➔ **0 issues found (100% clean)!** ✅
  - `flutter test test/file_closure_localization_test.dart` ➔ **2/2 tests passed (100%)** ✅
  - `flutter test test/file_closure_model_test.dart test/inbound_and_closure_workflow_test.dart` ➔ **5/5 tests passed (100%)** ✅
  - `flutter test test/perf/screen_30_file_closure_perf_test.dart` ➔ **1/1 benchmark passed (Nav-IN First Frame: 67.7ms | Settled: 93.7ms | Nav-OUT: 17.0ms)** ✅

---

## 📝 Session Log: Screen 29: Financial Settlement Hub (Landed Cost Settlement) — 2026-09-08
- **Target Files:**
  - `frontend/lib/features/financial_settlement/screens/financial_settlement_screen.dart` (Landed cost settlement registry, expense invoices breakdown, unit landed cost distribution, KPI summary metrics, entry/allocation form dialog)
  - `frontend/lib/features/financial_settlement/screens/odoo_journal_entry_dialog.dart` (Dual-entry balanced accounting journal generator & ERP export dialog)
- **Route Index:** `29`
- **Task A (Localization / i18n):** Complete.
  - Added 18 new localization keys across `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`:
    - `financialSettlementCopyFieldTooltip`, `financialSettlementExportTsvBtn`, `financialSettlementExportTsvSuccess`, `financialSettlementCopyBreakdownTsvBtn`, `financialSettlementCopyBreakdownSuccess`, `financialSettlementPrintSummarySuccess`, `financialSettlementCurrencyEgp`, `odooJournalCopyTsvBtn`, `odooJournalCopyTsvSuccess`, `odooJournalSaveCsvDialogTitle`, `odooJournalSaveExcelDialogTitle`, `odooJournalCatGoods`, `odooJournalCatFreight`, `odooJournalCatCustoms`, `odooJournalCatClearance`, `odooJournalCatTransport`, `odooJournalCatDemurrage`, `odooJournalCatPriceAdjustment`.
  - Purified 13 existing Arabic localizations eliminating English acronyms (`(FOB)` → `فاتورة الشراء`, `FOB` → `فاتورة الشراء`, `Odoo / ERP` → `النظام المالي`, `Odoo ERP` → `النظام المالي`, `Odoo CSV` → `ملف البيانات المجدولة`, `Excel` → `جدول البيانات المحاسبي`) and all bilingual slashes (`/`).
  - Replaced hardcoded currency strings (`' ج.م'`) with dynamic `context.l10n.financialSettlementCurrencyEgp` across KPI tiles and table cells.
  - Replaced hardcoded Arabic file-saving dialog titles with `context.l10n.odooJournalSaveCsvDialogTitle` and `context.l10n.odooJournalSaveExcelDialogTitle`.
  - Replaced hardcoded category badge labels with dynamic localized getters (`odooJournalCatGoods`, `odooJournalCatFreight`, etc.).
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped `_buildRegistryView` and `_FinancialSettlementFormDialog` in top-level `SelectionArea` for full native text selection across labels, headers, and values.
  - Wrapped settlement code badge, import file reference, and all KPI summary metric values (FOB Total, Expenses Total, Landed Cost Total, Markup Factor) in `CopyableText`.
  - Converted all 7 columns in the Expense Invoices DataTable to `DataCell(CopyableTableCell(value: ..., rowSummary: ..., child: ...))`.
  - Converted all 10 columns in the Item Landed Cost DataTable to `DataCell(CopyableTableCell(value: ..., rowSummary: ..., child: ...))`.
  - Wrapped `OdooJournalEntryDialog` metadata values (importer, supplier, project, date, total debit/credit) in `CopyableText`.
  - Converted all 8 columns in the Odoo Journal Lines DataTable to `DataCell(CopyableTableCell(value: ..., rowSummary: ..., child: ...))`.
  - Added copy suffix buttons (`CopyHelper.copy`) with tooltips to all 8 form inputs (`_invNoCtrl`, `_providerCtrl`, `_amountFxCtrl`, `_rateCtrl`, `_itemCodeCtrl`, `_itemNameCtrl`, `_qtyCtrl`, `_fobUnitCtrl`).
- **Task C (Linked Outputs / TSV Export):** Complete.
  - **Single-Click Registry TSV Export (`_copySettlementRecordsTsv`):** Added a dedicated "Export Settlements (TSV)" button in the top action toolbar copying all settlement records with active-locale column headers.
  - **Cost Breakdown TSV Export (`_copySettlementBreakdownTsv`):** Added a "Copy Cost Breakdown (TSV)" action button in each settlement card row, exporting itemized expense allocations and landed cost per unit.
  - **Odoo Journal TSV Export (`_copyJournalEntryTSV`):** Added single-click "Copy TSV" button to `OdooJournalEntryDialog` with active-locale headers and localized feedback notification.
  - Upgraded `RowActionsPill.onPrint` to trigger comprehensive settlement summary copy with snackbar confirmation (`financialSettlementPrintSummarySuccess`).
- **Verification:**
  - `flutter analyze lib/features/financial_settlement/ lib/core/localization/ test/financial_settlement_localization_test.dart` ➔ **0 issues found (100% clean)!** ✅
  - `flutter test test/financial_settlement_localization_test.dart` ➔ **2/2 tests passed (100%)** ✅
  - `flutter test test/financial_settlement_model_test.dart test/perf/screen_29_financial_settlement_perf_test.dart` ➔ **3/3 tests passed (100%)** ✅

---

## 📝 Session Log: Screen 28: Inbound Warehouse Hub (GRN) — 2026-09-08
- **Target Files:**
  - `frontend/lib/features/warehouse_receiving/screens/inbound_warehouse_hub_screen.dart` (Inbound Logistics & Warehouse Hub scaffold & Tab navigation)
  - `frontend/lib/features/warehouse_receiving/screens/warehouse_receiving_screen.dart` (SubTab 1: Goods Receiving Notes (GRN) list, inspection audit summary, multi-PO receiving form, discrepancy certification)
- **Route Index:** `28`
- **Task A (Localization / i18n):** Complete.
  - Added 21 new localization getters/methods across `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`:
    - `warehouseReceivingQuarantineLockBadge`, `warehouseReceivingQuarantineStatusBlocked`, `warehouseReceivingQuarantineStatusCheck`, `warehouseReceivingQuarantineAlertBlocked`, `warehouseReceivingQuarantineAlertCleared`, `warehouseReceivingExportTsvBtn`, `warehouseReceivingExportTsvSuccess`, `warehouseReceivingCopyFieldTooltip`, `warehouseReceivingPrintReceiptSuccess`, `warehouseReceivingColGrnCode`, `warehouseReceivingColWarehouse`, `warehouseReceivingColStatus`, `warehouseReceivingColQuarantine`, `warehouseReceivingColTruckDriver`, `warehouseReceivingColArrivalDate`, `warehouseReceivingColInspector`, `warehouseReceivingColDiscrepancy`, `warehouseReceivingColInvoicedQty`, `warehouseReceivingColAcceptedQty`, `warehouseReceivingColShortageQty`, `warehouseReceivingColDamagedQty`.
  - Replaced hardcoded strings in `warehouse_receiving_screen.dart`:
    - Replaced stacked bilingual quarantine badge `'محظور الصرف: تحت التحفظ الجمركي (Quarantine Lock)'` with `context.l10n.warehouseReceivingQuarantineLockBadge`.
    - Replaced hardcoded Arabic status buttons `'محظور الصرف (تحت التحفظ)' : 'فحص صلاحية الصرف'` with localized getters.
    - Replaced hardcoded SnackBars with localized alerts (`warehouseReceivingQuarantineAlertBlocked`, `warehouseReceivingQuarantineAlertCleared`).
  - Purified Arabic translations in `app_localizations_ar.dart` eliminating all bilingual slashes (`/`), dual headers, and Latin characters (`Excel` → `جدول بيانات`, `الرصاص تالف/مكسور` → `الرصاص تالف أو مكسور`, `إثبات عجز / تلف` → `إثبات عجز أو تلف`, `رقم الشاحنة / السيارة` → `رقم الشاحنة واللوحة`, `رقم السيل / الرصاص الأمني` → `رقم السيل والرصاص الأمني`).
  - Cleaned tab title in `inbound_warehouse_hub_screen.dart` to `titleEn: 'Warehouse Receiving & GRN'`.
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped `inbound_warehouse_hub_screen.dart` tab host body in `SelectionArea(child: _buildCurrentTab())`.
  - Wrapped `warehouse_receiving_screen.dart` `bodyContent` in `SelectionArea` so all labels, instructions, metrics, and card details are natively selectable and copyable via Ctrl+C.
  - Wrapped individual card values in `CopyableText` (GRN Code, warehouse name, driver & truck plate number, arrival date & time, inspector name).
  - Wrapped all 4 audit metric counts (Invoiced, Accepted, Shortage, Damaged) in `CopyableText`.
  - Wrapped `_WarehouseReceivingFormDialog` in `SelectionArea` and added explicit copy suffix buttons (`CopyHelper.copy`) with tooltips on all text inputs (`_whCtrl`, `_plateCtrl`, `_driverCtrl`, `_sealCtrl`).
  - Wrapped `_DiscrepancyReportDialog` in `SelectionArea` and added copy suffix button on `_claimRefCtrl`.
- **Task C (Linked Outputs / TSV Export):** Complete.
  - Added dedicated single-click TSV table export button (`OutlinedButton.icon` with `_copyGrnRecordsTsv`) to toolbar row:
    - Generates 12-column tab-separated table with active-locale column headers (GRN Code, Warehouse, Status, Quarantine Status, Driver & Plate, Arrival Date, Inspector, Discrepancy, Invoiced Qty, Accepted Qty, Shortage Qty, Damaged Qty).
    - Copies directly to system clipboard via `CopyHelper.copy` with snackbar feedback (`warehouseReceivingExportTsvSuccess`), immediately pasteable into Excel, WhatsApp, or Email.
  - Upgraded `RowActionsPill.onPrint`:
    - Formats complete, copyable GRN receipt with active-locale labels and values into multi-line text and copies to clipboard via `CopyHelper.copy` with toast notification (`warehouseReceivingPrintReceiptSuccess`).
- **Verification:**
  - `flutter analyze lib/features/warehouse_receiving/ lib/core/localization/` ➔ **0 issues found (100% clean)!** ✅
  - `flutter test test/warehouse_receiving_localization_test.dart` ➔ **2/2 tests passed (100%)** ✅
  - `flutter test test/warehouse_receiving_model_test.dart test/goods_in_transit_and_warehouse_reports_test.dart test/perf/screen_28_inbound_warehouse_perf_test.dart` ➔ **8/8 tests passed (100%)** ✅
  - Full codebase analysis `flutter analyze` ➔ **No issues found (100% clean)!** ✅

---

## 📝 Session Log: Screen 27: Customs Clearance Execution Hub — 2026-09-08
- **Target Files:**
  - `frontend/lib/features/customs_clearance/screens/customs_clearance_screen.dart` (4 Sub-views: Follow-up & Under-Bond, Drawing Samples & Shortage, Discrepancy & Damage Protocols, Final Duty Payment & Release)
  - `frontend/lib/features/customs_clearance/widgets/under_bond_release_dialog.dart` (Under-Bond Release & Lab Verdict Dialog)
- **Route Index:** `27`
- **Task A (Localization / i18n):** Complete.
  - Added 29 new localization keys across `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`:
    - `customsClearanceAiBrokerExtractorBtn`, `customsClearanceUnderBondTooltip`, `underBondReleaseDialogTitle`, `underBondReleaseDeclSubtitle`, `underBondModeUnderBond`, `underBondModeLabVerdict`, `underBondInfoBanner`, `underBondGuaranteeRefLabel`, `underBondQuarantineLocLabel`, `underBondDefaultQuarantineLoc`, `underBondConfirmReleaseBtn`, `underBondRequiredFieldsError`, `underBondReleaseSuccess`, `underBondActionError`, `underBondLabInfoBanner`, `underBondLabCertLabel`, `underBondLabVerdictLabel`, `underBondLabVerdictPassed`, `underBondLabVerdictRejected`, `underBondLabRemarksLabel`, `underBondApproveReleaseBtn`, `underBondRejectReleaseBtn`, `underBondLabCertRequiredError`, `underBondLabApprovedSuccess`, `underBondLabRejectedAlert`, `underBondLabResultError`, `customsClearanceExportTsvBtn`, `customsClearanceExportTsvSuccess`, `customsClearanceCopyFieldTooltip`.
  - Replaced all hardcoded strings in `under_bond_release_dialog.dart` (banner texts, form fields, validation errors, success/failure notifications, and verdict segmented buttons).
  - Cleaned stacked English acronyms (`(Under-Bond Release)`, `(PASSED)`, `(REJECTED)`, `(VAT)`, `(1%)`) from Arabic translations.
  - Localized AI broker quotation extractor button with pure single-locale getter `l.customsClearanceAiBrokerExtractorBtn`.
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped entire screen scaffold body in top-level `SelectionArea` allowing native text selection across all 4 sub-views without cluttering static text.
  - Wrapped clearance card values (Clearance Code, Declaration 46 No, Delivery Order No, Customs Office, Import File Ref, Total Duties, Estimated Duties & Variance) in `CopyableText`.
  - Converted all DataTables across SubTab 1 (Samples), SubTab 2 (Discrepancies & Damage Protocols), and SubTab 3 (Duty Ledger & Reconciliations) to use `CopyableTableCell` with comprehensive full-row TSV `rowSummary`.
  - Wrapped all dialog bodies (`UnderBondReleaseDialog`, `_CustomsClearanceFormDialog`, `_DutyPaymentDialog`, `_FinalReleaseDialog`, `_showAddSampleDialog`, `_showAddDamageDialog`) in `SelectionArea`.
  - Added explicit copy suffix buttons (`CopyHelper.copy`) to form fields (`_decl46Ctrl`, `_doNumberCtrl`, `_receiptCtrl`, `_releaseNoCtrl`, guarantee reference, lab certificate, sample receipt, damage declaration & container).
- **Task C (Linked Outputs / TSV Export):** Complete.
  - Added 4 dedicated single-click TSV export actions across all 4 sub-views:
    1. `_copyClearanceRecordsTsv`: Exports filtered clearance records with active-locale column headers (Clearance Code, Declaration 46, Office, Channel, Delivery Order, Free Days, Total Duty, Status).
    2. `_copySamplesTsv`: Exports drawn samples table (Sample Code, Authority, Date, Receipt No, Test Type, Result, Notes).
    3. `_copyDiscrepanciesTsv`: Exports discrepancy & damage table (Protocol No, Declaration No, Container No, Damage Type, Damaged Qty, Loss EGP, Responsible Party, Claim Status, Date).
    4. `_copyDutyLedgerTsv`: Exports duty ledger table (Clearance Code, Declaration 46, Customs Office, Actual Duty, Estimated Duty, Variance, Payment Status).
  - Outputs directly to system clipboard via `CopyHelper.copy` with snackbar feedback (`customsClearanceExportTsvSuccess`), immediately pasteable into Excel, WhatsApp, or Email.
- **Verification:**
  - `flutter analyze lib/features/customs_clearance/ lib/core/localization/ test/customs_clearance_localization_test.dart` ➔ **0 issues found (No issues found!)** ✅
  - `flutter test test/customs_clearance_localization_test.dart test/customs_clearance_test.dart test/customs_clearance_model_test.dart test/perf/screen_27_customs_clearance_perf_test.dart` ➔ **10/10 tests passed (100%)** ✅

---

## 📝 Session Log: Screen 26: Cargo Shipping & Tracking - Allocations (VGM) — 2026-09-08
- **Target File:** `frontend/lib/features/cargo_shipping/screens/cargo_shipping_screen.dart` (SubTab 0: Allocations & VGM Manifest)
- **Route Index:** `26`
- **Task A (Localization / i18n):** Complete.
  - Added 14 new localization keys across `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`:
    - `cargoShippingAiExtractorBtn`, `cargoShippingExportManifestBtn`, `cargoShippingManifestCopySuccess`, `cargoShippingCopyFieldTooltip`, `cargoShippingAcidPrefix`, `cargoShippingManifestHeader`, `cargoShippingColUnitNumber`, `cargoShippingColContainerNo`, `cargoShippingColContainerType`, `cargoShippingColSealNo`, `cargoShippingColGrossWeight`, `cargoShippingColVgmStatus`, `cargoShippingColVgmRef`, `cargoShippingColTrackingStatus`.
  - Cleaned all stacked bilingual slashes (`/`), dual headers, and parenthetical English acronyms in Arabic localizations (`(VGM)`, `(48h SLA)`, `(PDF / Word / Excel)`, `FCL (حاوية كاملة)`).
  - Dynamic container type localization helper (`_getLocalizedContainerTypeLabel`) eliminating raw English fallbacks.
  - Localized AI B/L analyzer button with pure single-locale getter `context.l10n.cargoShippingAiExtractorBtn`.
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped entire screen scaffold body in `SelectionArea` making all titles, labels, card headers, and instructions natively drag-selectable and copyable via Ctrl+C.
  - Wrapped active file banner values (Import File Code, Foreign Supplier, ACID Number, Study Code) in `CopyableText` with hover tooltip and double-tap copy.
  - Wrapped aggregated cargo metric totals and auto-recommendation text banner in `CopyableText`.
  - Added explicit copy suffix icon buttons with tooltips to container equipment card text fields (Gross Weight VGM, Container Number, Seal Number, and CFS Warehouse Location).
- **Task C (Linked Outputs / Reports):** Complete.
  - **Single-Click TSV Manifest Export (`_copyContainerAllocationsManifest`):** Added a dedicated "Copy Container Allocations Manifest (TSV)" action button to the bottom action toolbar.
  - Generates structured, tab-separated manifest data with localized column headers (Unit No, Container No, Type, Seal No, Gross Weight VGM, Status, VGM Ref, Tracking Status) matching the active locale.
  - Outputs directly to clipboard via `CopyHelper.copy` with snackbar feedback (`cargoShippingManifestCopySuccess`), pasteable directly into Excel / WhatsApp / Email clients.
- **Verification:**
  - `flutter analyze lib/features/cargo_shipping/ lib/core/localization/ test/cargo_shipping_localization_test.dart` ➔ **0 issues found (100% clean)!** ✅
  - `flutter test test/cargo_shipping_localization_test.dart test/cargo_shipping_screen_test.dart test/cargo_shipping_model_test.dart test/perf/screen_26_cargo_shipping_perf_test.dart` ➔ **12/12 tests passed (100%)** ✅

---

## 📝 Session Log: Screen 25: Freight Booking Operations — 2026-09-07
- **Target File:** `frontend/lib/features/freight_booking/screens/freight_booking_screen.dart`
- **Route Index:** `25`
- **Task A (Localization / i18n):** Complete.
  - Added 15 new localization keys: `freightBookingAiShippingLineBtn`, `freightBookingAiForwarderBtn`, `freightBookingDraftPendingLabel`, `freightBookingForwarderPrefixLabel`, `freightBookingEtdPrefixLabel`, `freightBookingAtdPrefixLabel`, `freightBookingEtaPrefixLabel`, `freightBookingBasedOnQuote`, `freightBookingCostSavingsBadgeAmount`, `freightBookingCostIncreaseBadgeAmount`, `freightBookingCostMatchBadge`, `freightBookingNetDifference`, `freightBookingBreakdownHeader`, `freightBookingBreakdownSavingsUnit`, `freightBookingPrintSystemHeader`.
  - Fixed all hardcoded strings in DataTable cells (columns 4–12): `'Draft Pending'`, `'N/A'`, `'FWD: ...'`, `'ETD: ...'`, `'ATD: ...'`, `'ETA: ...'`.
  - Fixed all hardcoded Arabic strings in cost savings comparison card: `'مبني على عرض أسعار: ...'`, `'توفير: $ ...'`, `'زيادة: $ ...'`, `'مطابق: $ 0.00'`, `'الفرق'`, `'📊 تفاصيل ...'`, `'... USD توفير'`.
  - Fixed hardcoded `'IMPORTFLOW ERP - CARRIER BOOKING CONFIRMATION'` in Print dialog.
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped DataTable cells 4–12 with `DataCell(CopyableTableCell(value: ..., child: ...))` for right-click copy menu.
  - Wrapped `_FreightBookingViewDialog` content in `SelectionArea` for free text selection.
  - Wrapped `_FreightBookingPrintDialog` content in `SelectionArea` for free text selection.
  - Added explicit "Copy" `TextButton.icon` in Print dialog actions — copies full booking manifest as multi-line text to clipboard.
- **Task C (Linked Outputs / Reports):** Complete.
  - Print dialog manifest copy button (multi-line text with all booking fields, containers, charges, totals). ✅
  - PDF / Excel / WhatsApp / Email: N/A for this screen — only Print dialog output exists.
- **Verification:**
  - `flutter analyze lib/features/freight_booking/screens/freight_booking_screen.dart` ➔ **0 issues found (100% clean)!** ✅
  - `flutter test test/freight_booking_localization_test.dart` ➔ **7/7 tests passed (100%)** ✅

---

## 📝 Session Log: Screen 24: Customs Declaration 46 - Tariff Items & Assessment — 2026-09-07
- **Target File:** `frontend/lib/features/import_documentation/screens/customs_declaration46_screen.dart` (SubTab 1: Declaration Registry, KPI Valuation Cards, Tariff Assessment & Valuation Dialog, Itemized Duty Schedule)
- **Route Index:** `24`
- **Task A (Localization / i18n):** Complete.
  - Added 22 new localization keys across `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`:
    - `customsDeclAssessmentTitle`, `customsDeclViewAssessmentTooltip`, `customsDeclAssessmentSubtitle`, `customsDeclShipmentParticularsHeader`, `customsDeclValuationBreakdownHeader`, `customsDeclFobForeignLabel`, `customsDeclFreightEgpLabel`, `customsDeclInsuranceEgpLabel`, `customsDeclCifTotalEgpLabel`, `customsDeclTariffTaxesHeader`, `customsDeclImportDutyRateLabel`, `customsDeclVatRateLabel`, `customsDeclDevFeeLabel`, `customsDeclCustomsServicesFeeLabel`, `customsDeclColActions`, `customsDeclAssessmentCopySuccess`, `customsDeclMetricTotalDeclarations`, `customsDeclMetricTotalCif`, `customsDeclMetricTotalDuties`, `customsDeclMetricExemptions`, `customsDeclFxRateLabel`, `customsDeclVatBaseLabel`.
  - Eliminated all bilingual slashes (`/`), dual headers, and stacked English acronyms (`(CIF)`, `(VAT)`, `(HS Code)`).
  - Used pure Arabic in `app_localizations_ar.dart` and clean professional English in `app_localizations_en.dart`.
- **Task B (Copy Data Enablement):** Complete.
  - Retained top-level `SelectionArea` wrapping the entire screen and dialog contents.
  - Wrapped all 4 SubTab 1 KPI summary card values (`Total Declarations`, `Total CIF Base`, `Total Duties & Taxes`, `European Partnership Exemptions`) in `CopyableText(..., isSelectable: false)` with hover tooltips and double-tap copy.
  - Converted all 8 columns in the Declaration Registry DataTable to `CopyableTableCell` with comprehensive tab-separated `rowSummary` containing all assessment metrics (Declaration No, File Code, Supplier, HS Code, CIF EGP, Total Duties, Status).
  - Added explicit copy button in the Tariff Assessment & Valuation Dialog with toast feedback (`customsDeclAssessmentCopySuccess`).
  - Wrapped each itemized valuation line and duty breakdown row in `CopyableText`.
- **Task C (Linked Outputs / Reports):** Complete.
  - **Itemized Tariff Assessment & Customs Valuation Dialog (`_showTariffAssessmentDialog`):** Full breakdown dialog providing Shipment Particulars, CIF Base Valuation (FOB foreign currency, official customs exchange rate, deemed freight, deemed insurance, CIF total EGP), Tariff Taxes Schedule (HS code, item description, import duty rate & EGP, service fees, development fee, VAT base, VAT rate & EGP, grand total), and European Partnership Exemption card.
  - **Single-Click Formatted Assessment Text Copy:** Formatted monospace text copyable directly via `CopyHelper.copy(context, ..., customMessage: l.customsDeclAssessmentCopySuccess)` with snackbar notification.
  - **Single-Click Structured TSV Export (`_exportRegistryTsv`):** Full 10-column tab-separated export of the entire registry table with active-locale column headers, pasteable directly into Excel / WhatsApp / Email.
- **Verification:**
  - `flutter analyze lib/features/import_documentation/screens/customs_declaration46_screen.dart test/customs_declaration46_localization_test.dart test/customs_declaration46_test.dart` ➔ **0 issues found (100% clean)!** ✅
  - `flutter test test/customs_declaration46_localization_test.dart test/customs_declaration46_test.dart` ➔ **7/7 tests passed (100%)** ✅

---

---

## 📝 Session Log: Screen 23: Customs Declaration 46 Entry & Declaration — 2026-09-07
- **Target File:** `frontend/lib/features/import_documentation/screens/customs_declaration46_screen.dart` (SubTab 0: Declaration 46 Form, Exemption & Trade Agreement Card, Regulatory Approvals Board; SubTab 1: Declaration 46 Registry)
- **Route Index:** `23`
- **Task A (Localization / i18n):** Complete.
  - Added 10 new localization keys across `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`:
    - `customsDeclRequiredField`, `customsDeclCopyValueTooltip`, `customsDeclPrintPreviewButton`, `customsDeclPreviewTitle`, `customsDeclCopySummarySuccess`, `customsDeclExportTsvButton`, `customsDeclExportSuccess`, `customsDeclExportRegistryTsv`, `customsDeclCopyAllSuccess`, `customsDeclCloseDialog`.
  - Cleaned all stacked English acronyms, parenthetical abbreviations, and bilingual slashes from Arabic keys:
    - Removed `(ACID)`, `(B/L)`, `CIF`, `VAT`, `(EUR.1)`, `(GOEIC)`, and `(HS Code)`.
    - Pure Arabic titles and labels when Arabic is active; clean English when English is active.
  - Form validation updated to use dynamic localized message `l.customsDeclRequiredField`.
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped the entire screen in `SelectionArea` so all labels, instructions, table headers, and static text are natively selectable via mouse drag without cluttering static text with copy icons.
  - Added explicit copy suffix icon buttons with tooltips (`customsDeclCopyValueTooltip`) to all 9 text form fields (`_declaration46NoCtrl`, `_submissionDateCtrl`, `_acidNumberCtrl`, `_form4NumberCtrl`, `_blNumberCtrl`, `_customsValueEgpCtrl`, `_importDutyEgpCtrl`, `_vatEgpCtrl`, `_totalDutyAndTaxesCtrl`).
  - Wrapped Exemption & Trade Agreement card title and condition bullet points in `CopyableText`.
  - Converted all 6 columns of Regulatory Approvals DataTable to `CopyableTableCell` with comprehensive TSV `rowSummary`.
  - Converted all 5 data cells in Declaration 46 Registry DataTable (SubTab 1) to `CopyableTableCell` with full-row TSV `rowSummary`.
- **Task C (Linked Outputs / Reports):** Complete.
  - **Declaration 46 Certificate Summary Preview & Copy Dialog (`_showDeclarationSummaryDialog`):** Displays a clean, localized certificate summary formatted with active-locale labels and numbers, copyable via `CopyHelper.copy` in one click with toast confirmation.
  - **Copy Declaration as Table (TSV) (`_copyDeclarationAsTsv`):** Generates structured TSV text with localized headers and field values, pasteable directly into Excel / WhatsApp / Email.
  - **Export Registry (TSV) (`_exportRegistryTsv`):** Enables one-click TSV export of the entire registry table with localized column headers in SubTab 1.
- **Verification:**
  - `flutter analyze lib/features/import_documentation/screens/customs_declaration46_screen.dart test/customs_declaration46_localization_test.dart test/customs_declaration46_test.dart` ➔ **No issues found! (100% clean)** ✅
  - `flutter test test/customs_declaration46_localization_test.dart test/customs_declaration46_test.dart` ➔ **4/4 tests passed (100%)** ✅

---

## 📝 Session Log: Screen 22: Smart Invoice vs B/L Match & Smart Extractor — 2026-09-07
- **Target Files:**
  - `frontend/lib/features/import_documentation/widgets/invoice_bl_matcher_tab.dart` (Discrepancy Matrix & Cross-Matching, Carrier B/L Correction Letter Generator, TSV Export Engine, Matrix KPI Cards, Match Summary)
  - `frontend/lib/features/import_documentation/widgets/smart_invoice_bl_extractor_dialog.dart` (Optical & Text Parser for Invoice & B/L, Commercial Invoice Summary, Bill of Lading Summary, 10-Point Customs Audit Radar, Amendment Notice Dispatcher)
- **Route Index:** `22`
- **Task A (Localization / i18n):** Complete.
  - Added 75+ new localization keys across `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`.
  - Removed all stacked bilingual slashes (`/`), dual titles, and parenthetical English abbreviations:
    - Tab headers: `l.smartExtractorTabInvoice` ('الفاتورة التجارية' / 'Commercial Invoice'), `l.smartExtractorTabBl` ('بوليصة الشحن' / 'Bill of Lading'), `l.smartExtractorTabAudit` ('رادار المطابقة الجمركية' / 'Customs Audit Radar').
    - Discrepancy Matrix & Action buttons: `l.invoiceBlMatcherExecuteMatchButton` ('تنفيذ الاستخراج الذكي والمطابقة الفورية' / 'Execute Smart Extraction & Match'), `l.invoiceBlMatcherLoadSampleButton` ('تحميل نموذج تجريبي حقيقي' / 'Load Real Sample Data'), `l.invoiceBlMatcherExportTsvButton` ('تصدير مصفوفة المطابقة (TSV)' / 'Export Match Matrix (TSV)').
    - Summary & Status indicators: `l.invoiceBlMatcherAllMatchedSuccess`, `l.invoiceBlMatcherDiscrepanciesFoundAlert`, `l.invoiceBlMatcherCorrectionLetterTitle`, `l.invoiceBlMatcherCorrectionLetterSubtitle`, `l.smartExtractorTitle`, `l.smartExtractorSubtitle`.
  - Replaced hardcoded Arabic and English text in SnackBars, dialog headers, item/container table columns, and amendment notices with pure single-locale strings.
  - Removed unused imports and cleaned all ternary `isArabic` expressions.
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped the entire `invoice_bl_matcher_tab.dart` and `smart_invoice_bl_extractor_dialog.dart` in `SelectionArea` so all labels, table headers, form descriptions, and data values are natively selectable with mouse click/drag without adding dedicated icons to static text.
  - Converted all Discrepancy Matrix table cells to use `CopyableTableCell` with comprehensive TSV `rowSummary` (Field, Invoice Value, B/L Value, Match Status, Difference / Tolerance, Regulatory Risk / Customs Impact).
  - Converted Extractor Dialog audit radar table cells and container breakdown table cells to use `CopyableTableCell` with full-row TSV summary.
  - Wrapped all KPI summary card values, match percentage counters, header chips, and extracted metadata pills in `CopyableText`.
  - Replaced raw `Clipboard.setData` with unified `CopyHelper.copy(context, text, customMessage: ...)` for carrier correction letters, amendment notices, and TSV matrix exports with toast feedback.
- **Task C (Linked Outputs — Carrier Correction Letter / Amendment Notice / TSV Export):** Complete.
  - **Carrier Correction Letter:** Fully localized and copy-enabled via `CopyHelper.copy`. Displays dynamic date, shipper, consignee, notify party, B/L number, vessel, and formatted itemized discrepancy list in single active locale.
  - **Customs Audit Radar & Amendment Notice:** Fully localized text preview inside `SelectionArea` with single-click clipboard copy formatted for direct transmission to shipping lines or customs brokers.
  - **TSV Matrix Export:** Structured TSV format with localized column headers, allowing seamless one-click copying and direct paste into Excel / WhatsApp / Email with proper column alignment.
  - **PDF Export:** N/A — no linked standalone PDF generation required for this tab (outputs are Carrier Correction Letter & TSV matrix).
  - **Excel Download:** N/A — no standalone Excel file download required (TSV clipboard export directly pastes into Excel cells).
- **Verification:**
  - `flutter analyze lib/features/import_documentation/widgets/invoice_bl_matcher_tab.dart lib/features/import_documentation/widgets/smart_invoice_bl_extractor_dialog.dart lib/core/localization/` ➔ **0 issues found (100% clean)!** ✅
  - `flutter test test/invoice_bl_matcher_localization_test.dart test/invoice_bl_matcher_test.dart test/features/smart_invoice_bl_extractor_test.dart` ➔ **9/9 tests passed (100%)** ✅

---

## 📝 Session Log: Screen 21: PO & Final Commercial Invoice & Packing List Reconciliation — 2026-09-07
- **Target File:** `frontend/lib/features/import_documentation/widgets/po_reconciliation_tab.dart` (PO & Final Commercial Invoice Line Items Cross-Check, Packing List & Package Breakdown Reconciliation, Smart Optical Discrepancy Extractor & Compliance Checks, Historical Audit Registry, Final Certification Engine)
- **Route Index:** `21`
- **Task A (Localization / i18n):** Complete.
  - Added 27 new localization keys across `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`:
    - Prefixes: `poRecInvoicePrefix` ('فاتورة:' / 'Invoice:'), `poRecPackingPrefix` ('كشف تعبئة:' / 'Packing List:'), `poRecGrossPrefix` ('الوزن القائم:' / 'Gross Wt:').
    - Discrepancy header check fields: `poRecCheckFieldInvoiceNumber` ('رقم الفاتورة التجارية النهائية' / 'Final Commercial Invoice Number'), `poRecCheckFieldAcidNumber` ('رقم القيد الجمركي المبدئي' / 'Customs ACID Number'), `poRecCheckFieldTotalAmount` ('إجمالي قيمة الفاتورة التجارية' / 'Total Commercial Invoice Amount').
    - Discrepancy check messages: `poRecCheckMsgInvoiceMatched`, `poRecCheckMsgAcidMatched`, `poRecCheckMsgTotalAmountMatched`, `poRecCheckNotSpecified`.
    - Print/Export report strings: `poRecReportTitle`, `poRecReportSessionCode`, `poRecReportImportFile`, `poRecReportImporter`, `poRecReportShipper`, `poRecReportAcid`, `poRecReportInvoiceNo`, `poRecReportPackingNo`, `poRecReportTotalValue`, `poRecReportPackages`, `poRecReportGrossWeight`, `poRecReportNetWeight`, `poRecReportTotalCbm`, `poRecReportOverallStatus`, `poRecReportCertifiedBy`, `poRecReportCsvHeader`, `poRecReportPreviewTitle`.
  - Added 3 dynamic localization resolver methods in `_POReconciliationTabState`: `_getLocalizedCheckField`, `_getLocalizedCheckMessage`, and `_getLocalizedSessionStatus`.
  - Cleaned 8 existing Arabic keys from stacked slashes (` / `), English acronyms (`(CBM)`, `(HS)`, `(PDF/Word/Excel)`), and dual-language placeholders.
  - Replaced hardcoded English prefixes (`INV:`, `PL:`, `Gross:`) in saved session cards with localized dynamic labels.
  - Localized the header compliance checks table so field names and verification messages render strictly in the active language.
  - Replaced hardcoded currency formatting in line items table with dynamic currency formatting.
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped entire editor and history sections in `SelectionArea` so labels, table headers, form descriptions, and data values are natively selectable with click/drag without dedicated icons on labels.
  - Wrapped `_showSaveSuccessReportDialog`, `_showSessionDetailsModal`, and `_showPrintReportDialog` dialog contents in `SelectionArea`.
  - Converted history table cells to use `CopyableTableCell` with comprehensive tab-separated `rowSummary` for index, session code, import file/importer, invoice/packing list numbers, total value, packages/weight, CBM volume, status badge, and creation date.
  - Converted `_invoiceItems` DataTable cells to use `CopyableTableCell` with full row summary for item code, description, PO quantity, final quantity, price, variance, and total.
  - Converted `_packingItems` DataTable cells to use `CopyableTableCell` with full row summary for item code, package type, packages count, weights, and CBM.
  - Converted header compliance checks table in discrepancies section to use `CopyableTableCell` with row summary.
  - Replaced raw `Clipboard.setData` with unified `CopyHelper.copy(context, ...)` for session code copy and report copy with toast feedback.
  - Wrapped KPI card values, history stat cards, and extracted metadata pills with `CopyableText(..., isSelectable: false)` with hover tooltips and double-tap copy.
- **Task C (Linked Outputs — PDF / Excel / WhatsApp / Email / Print Report):** Complete.
  - **Text / CSV Comprehensive Report:** Fully localized and copy-enabled.
    - Sourced from unified single-language translation keys (`poRecReportTitle`, `poRecReportSessionCode`, `poRecReportCsvHeader`, etc.).
    - When Arabic is active: 100% Arabic headers and localized statuses.
    - When English is active: 100% English headers and statuses.
    - Content is displayed in a dedicated Preview Dialog inside a `SelectableText` / `SelectionArea` and copyable in one click via `CopyHelper.copy` with toast feedback.
    - Data rows output clean CSV/TSV format, immediately pasteable into Excel, WhatsApp, or Email clients with distinct cell columns.
  - **PDF Export:** N/A — no linked PDF export action on this tab.
  - **Excel Download:** N/A — no standalone Excel action button on this tab (report provides clean structured CSV/TSV data).
  - **WhatsApp Share:** N/A — no linked WhatsApp share action on this tab.
  - **Email Share:** N/A — no linked Email share action on this tab.
- **Verification:**
  - `flutter analyze lib/features/import_documentation/widgets/po_reconciliation_tab.dart test/po_reconciliation_tab_localization_test.dart` ➔ **No issues found! (100% clean)** ✅
  - `flutter test test/po_reconciliation_tab_localization_test.dart test/customs_document_approval_localization_test.dart test/coo_localization_test.dart test/draft_bl_localization_test.dart` ➔ **16/16 tests passed (100%)** ✅

---

## 📝 Session Log: Screen 20: Draft Docs Customs Approval Hub — 2026-09-07
- **Target File:** `frontend/lib/features/import_documentation/widgets/customs_document_approval_tab.dart` (Dual-Tier Sign-off & Matrix Audit, Live Cross-Document Matrix Banner, Discrepancy Rectification Tickets, Commercial Review & Customs Broker Sign-off Dialogs)
- **Route Index:** `20`
- **Task A (Localization / i18n):** Complete.
  - Added 25 new localization keys across `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`:
    - Standard document type resolvers (`customsApprovalDocCommercialInvoice`, `customsApprovalDocPackingList`, `customsApprovalDocBillOfLading`, `customsApprovalDocCertificateOfOrigin`, `customsApprovalDocEur1`, `customsApprovalDocInspectionCertificate`, `customsApprovalDocBankForm4`, `customsApprovalDocProformaInvoice`).
    - Overall status resolvers (`customsApprovalStatusApprovedForClearance`, `customsApprovalStatusRectificationRequired`, `customsApprovalStatusConditionallyApproved`, `customsApprovalStatusUnderReview`, `customsApprovalStatusPendingReview`, `customsApprovalStatusDraft`, `customsApprovalStatusRejected`, `customsApprovalStatusApproved`, `customsApprovalStatusPending`).
    - Compliance resolvers (`customsApprovalComplianceFullyCompliant`, `customsApprovalComplianceNonCompliant`, `customsApprovalComplianceDiscrepancies`, `customsApprovalComplianceCriticalBlocker`).
    - Ticket severity and status resolvers (`customsApprovalSevCriticalBadge`, `customsApprovalSevMajorBadge`, `customsApprovalSevMinorBadge`, `customsApprovalTicketStatusOpen`).
    - Default reviewer title resolvers (`customsApprovalDefaultCommercialReviewer`, `customsApprovalDefaultBrokerOffice`, `customsApprovalDefaultLegalOfficer`, `customsApprovalDefaultComplianceOfficer`).
  - Added 7 static helper methods in `_CustomsDocumentApprovalTabState`: `_getLocalizedDocType`, `_getLocalizedOverallStatus`, `_getLocalizedCommercialStatus`, `_getLocalizedBrokerStatus`, `_getLocalizedSeverity`, `_getLocalizedTicketStatus`, and `_getLocalizedCompliance`.
  - Cleaned all stacked bilingual slashes (` / `), English abbreviations, and parenthetical acronyms from Arabic keys (`مكتب التخليص الجمركي *`, `اسم المخلص الجمركي المعتمد *`, `تصنيف عدم المطابقة *`, `عدم تطابق بند التعريفة الجمركية`, `اختلاف الحجم التكعيبي`, `غياب الرقم التعريفي المبدئي للشحنة`, `تعارض شرط الشحن الدولي`, `تسجيل رد المورد وإغلاق التذكرة`, `رد المورد وتعديل المسودة *`).
  - Replaced raw English text pre-filled into text controllers (`Commercial Specialist`, `Licensed Customs Broker`, `Legal Officer`, `Compliance Specialist`) with localized defaults initialized via `didChangeDependencies`.
  - Cleaned parameterized fraction string in Arabic matrix compliance result (`$passed من $total مطابق` instead of `$passed/$total`).
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped Live Matrix Banner in `SelectionArea` and wrapped compliance results, recommendations, and open tickets count with `CopyableText`.
  - Wrapped Left Column (Dual-Tier Approvals Card) in `SelectionArea` allowing native mouse selection.
  - Wrapped Right Column (Discrepancy Tickets Card) in `SelectionArea` allowing native mouse selection.
  - Wrapped all document types, document reference numbers, and overall status pills in `_buildApprovalRow` with `CopyableText(..., isSelectable: false)`.
  - Wrapped ticket codes, severity badges, ticket status pills, descriptions, and expected vs found values in `_buildTicketCard` with `CopyableText(..., isSelectable: false)`.
- **Verification:**
  - `flutter analyze lib/features/import_documentation/widgets/customs_document_approval_tab.dart test/customs_document_approval_localization_test.dart` → **No issues found (100% clean)!** ✅
  - `flutter test test/customs_document_approval_localization_test.dart test/coo_localization_test.dart test/draft_bl_localization_test.dart` → **12/12 tests passed (100%)** ✅

---

## 📝 Session Log: Screen 19: Draft COO / EUR.1 Review — 2026-09-07
- **Target Files:**
  - `frontend/lib/features/import_documentation/widgets/coo_review_tab.dart` (4 Stages: Origin Requirements & Selection, Draft Extraction & Details, Discrepancy Matrix & Visual Sheet, COO Review Registry)
  - `frontend/lib/features/import_documentation/widgets/visual_draft_coo_sheet.dart` (Official Certificate of Origin & EUR.1 Visual Preview, Egyptian Customs Compliance Banner, Multi-format Export Engine)
- **Route Index:** `19`
- **Task A (Localization / i18n):** Complete.
  - Added 4 new getters across `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart` (`cooCustomsClearanceNote`, `cooExcelSavedSuccess`, `cooDetailsExporterLabel`, `cooDetailsImporterLabel`).
  - Replaced the stacked bilingual Customs Compliance Banner in `visual_draft_coo_sheet.dart` (which was previously displaying Arabic and English notes simultaneously) with a single-language responsive note using `context.l10n.cooCustomsClearanceNote`.
  - Localized hardcoded Excel save success SnackBar with parameterized `context.l10n.cooExcelSavedSuccess(path)`.
  - Replaced ternary bilingual text in COO Details dialog with localized `cooDetailsExporterLabel` and `cooDetailsImporterLabel`.
  - Added localized field label mapping `_getFieldLabel` to present clean localized names in the Discrepancy Matrix instead of raw database keys.
  - Cleaned all 10 Arabic and 11 English existing COO localization keys from stacked bilingual slashes (` / `), such as `(PDF, Word, Excel)`, `(CCPIT - اتفاقية الصين ومصر)`, and `EUR.1 (EU Partnership, EFTA, Turkey)`.
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped Origin badge, Approved Cert badge, and Recommendation alert in Step 1 with `CopyableText`.
  - Replaced raw `Clipboard.setData` calls with unified `CopyHelper.copy(context, ...)` for CSV/Excel export.
  - Wrapped all 5 data cells in Step 3 Discrepancy Matrix DataTable with `CopyableTableCell` with complete TSV `rowSummary`.
  - Wrapped all 6 data cells in Step 4 COO Review Registry DataTable with `CopyableTableCell` with full-row TSV `rowSummary`.
  - Wrapped all COO Review Details dialog fields (cert number, parties, origins, override reason, discrepancy items) with `CopyableText`.
  - Wrapped certificate box contents in `visual_draft_coo_sheet.dart` via `_buildInfoBox` and `_buildTableBodyCell` with `CopyableText`.
  - Wrapped serial numbers, ACID numbers, HS code tags, and invoice metadata with `CopyableText`.
- **Verification:**
  - `flutter analyze lib/features/import_documentation/widgets/coo_review_tab.dart lib/features/import_documentation/widgets/visual_draft_coo_sheet.dart lib/core/localization/ test/coo_localization_test.dart` → **0 issues found (No issues found!)** ✅.
  - `flutter test test/coo_localization_test.dart test/draft_bl_localization_test.dart test/bank_form4_localization_test.dart` → **9/9 test suites passed (100%)** ✅.

---

## 📝 Session Log: Screen 18: Shipment Draft Documents - Draft B/L Review & Dual Approval — 2026-09-07
- **Target Files:**
  - `frontend/lib/features/import_documentation/widgets/draft_bl_review_tab.dart` (5 Stages: Review Sheet & Checklist, Revision Report & Letter, Version Branching, Dual Approval, Final Registry)
  - `frontend/lib/features/import_documentation/widgets/visual_draft_bl_sheet.dart` (Interactive Visual Bill of Lading Sheet & Maritime Export Engine)
- **Route Index:** `18`
- **Task A (Localization / i18n):** Complete.
  - Added 20 new localization keys across `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`.
  - Replaced all 29 hardcoded Arabic and English strings, SnackBars, and search hints with pure single-language localized getters (`context.l10n`).
  - Localized file extraction, comparison result, session saving, dual approval completion/rejection, PDF/Excel export, and print error SnackBars.
  - Cleaned all stacked bilingual slashes (`/`) and dual alternatives from existing Draft B/L localization keys in Arabic and English.
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped all 15 summary cards in Step 0 auto-summary with `CopyableText` via `_buildSummaryBox`.
  - Wrapped all Checklist DataTable field labels and system values with `CopyableText`.
  - Enabled one-click and double-click copying on generated Carrier Correction Request Letters with `CopyHelper.copy`.
  - Wrapped all data cells in Stage 2 Revision Table and Stage 4 Final Approved Registry DataTable with `CopyableTableCell` supporting cell copy and full-row TSV copy (`rowSummary`).
  - Replaced raw `Clipboard.setData` on B/L Number chip with unified `CopyHelper.copy`.
  - Wrapped all cells, header fields, and particulars in `VisualDraftBLSheet` with `CopyableText`.
- **Verification:**
  - `flutter analyze lib/features/import_documentation/widgets/draft_bl_review_tab.dart lib/features/import_documentation/widgets/visual_draft_bl_sheet.dart lib/core/localization/ test/draft_bl_localization_test.dart` → **0 issues found!**
  - `flutter test test/draft_bl_localization_test.dart` → **3/3 test suites passed (100%)** ✅.
  - `flutter test test/draft_bl_localization_test.dart test/bank_form4_localization_test.dart` → **6/6 test suites passed (100%)** ✅.

---

## 📝 Session Log: Screens 16 & 17: Bank Form 4 & Endorsement Hub — 2026-09-07
- **Target File:** `frontend/lib/features/import_documentation/screens/bank_form4_screen.dart` (SubTab 0: Form 4 Request & Checklist, SubTab 1: Bank Form 4 Registry)
- **Route Index:** `16` and `17`
- **Task A (Localization / i18n):** Complete.
  - Cleaned up stacked English acronyms and parenthetical abbreviations from Arabic localizations in `app_localizations_ar.dart` (`(PI)`, `(P/L)`, `(COO)`, `(B/L Draft)`, `(ACID Notice)`, `(Insurance)`, and slash slashes `/`).
  - Cleaned up acronyms and slashes in `app_localizations_en.dart`.
  - Replaced generic file selector error with clean single-locale prompt `selectImportFileFirst`.
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped edit mode banner reference code in SubTab 0 with `CopyableText`.
  - Wrapped all 6 data cells in Bank Form 4 Registry DataTable with `CopyableTableCell` supporting individual cell copy and comprehensive TSV full-row copy (`rowSummary`).
- **Verification:**
  - `flutter analyze lib/features/import_documentation/screens/bank_form4_screen.dart lib/core/localization/` → **0 issues found!**
  - `flutter test test/bank_form4_localization_test.dart` → **3/3 test suites passed (100%)** ✅.
  - `flutter test test/import_documentation_model_test.dart test/copyable_data_helper_test.dart` → **5/5 tests passed (100%)** ✅.

---

## 📝 Session Log: Screen 11: Nafeza & ACID Operations Hub — 2026-09-07
- **Target File:** `frontend/lib/features/import_documentation/screens/nafeza_acid_screen.dart` (SubTabs 0–4: ACID Request Form, MTS Smart AI Parser, Discrepancy Matrix, ACID Issuance Registry, Expiry & Release Tracker)
- **Route Index:** `11`, `12`, `13`, `14`, and `15`
- **Task A (Localization / i18n):** Complete.
  - Added 45+ keys to `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`.
  - SubTab 0: Localized exporter registration types (`vatRegType`, `crRegType`, `taxIdRegType`, `dunsRegType`) in `SearchableDropdownField`, localized invoice types (`proformaInvoiceLabel`, `commercialInvoiceLabel`), edit mode banner subtitle, and integrated single-locale dispatch templates.
  - SubTab 1: Localized raw text hint, sample text buttons, and dropdown options in `_showEditMtsDataDialog` (`companyRegNumberType`, `foreignExporterNafezaType`, `factoryRegType`, `vatRegType`, `taxIdRegType`, `crRegType`).
  - SubTab 2: Matrix field labels localized dynamically by locale (`item.labelEn` vs `item.labelAr`), and override reason hint localized (`discrepancyOverrideReasonHint`).
  - SubTab 3: Table headers and PO number prefix localized cleanly.
  - SubTab 4: Table headers, validity badges (`validStatusBadge`, `expiringSoonStatusBadge`, `expiredStatusBadge`), and card labels localized.
  - Dialogs & Actions: All alerts, confirmations, and SnackBars localized (`mtsNoticeDisclaimerAlertTitle/Content`, `mtsNoticeNoAcidAlertTitle/Content`, `acidSessionLoadedForEdit`, `acidSessionDeletedSuccess`, `mtsExtractedDataUpdated`, `foreignSupplierNotInData`, `supplierCodedSuccess`, `errorCodingSupplier`).
- **Task B (Copy Data Enablement):** Complete.
  - Replaced raw clipboard operations with `CopyHelper.copy(context, text, customMessage: ...)` across WhatsApp, Email, and English dispatch actions.
  - Wrapped edit mode session codes, extracted MTS values, requested/generated discrepancy matrix values, and tracker metrics with `CopyableText`.
  - Wrapped all data cells in ACID Registry DataTable and Expiry Tracker DataTable with `CopyableTableCell` supporting cell copy and full-row TSV copy with comprehensive `rowSummary`.
- **Verification:**
  - `flutter analyze lib/features/import_documentation/screens/nafeza_acid_screen.dart` → **0 issues found!**
  - `flutter test test/nafeza_acid_localization_test.dart` → **3/3 test suites passed (100%)** ✅.
  - `flutter test test/import_documentation_model_test.dart` → **2/2 test suites passed (100%)** ✅.

---

## 📝 Session Log: Screens 8, 9 & 10: Financial Approvals & Budget Management — 2026-09-07
- **Target Files:**
  - `frontend/lib/features/financial_approval/screens/financial_approval_screen.dart` (Screen 8: Tab 0 Payment Requests, Screen 9: Tab 1 Budget Approval, Screen 10: Tab 3 Payment Registry & Tab 4 SWIFT Reconciliation)
  - `frontend/lib/features/financial_approval/widgets/saved_budgets_registry_tab.dart` (Screen 10: Tab 2 Saved Budgets Registry)
- **Route Index:** `8`, `9`, and `10`
- **Task A (Localization / i18n):** Complete.
  - Added 70+ localization keys across `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`.
  - Removed all `isArabic ? ... : ...` ternary logic and unused `isArabic` variable.
  - Localized duplicate warnings for payment requests and budgets (`duplicatePaymentRequestTitle`, `duplicatePaymentRequestMessage`, `duplicateBudgetTitle`, `duplicateBudgetMessage`, `cancelSelection`, `viewAndEditPaymentRequest`, `viewAndPrintBudget`).
  - Localized CRUD SnackBars and error dialogs for payment requests and import budgets.
  - Localized SWIFT extraction titles, notes prefixes (`swiftPaymentPrefix`, `orderingCustomerPrefix`, `paymentDetailsPrefix`), and toasts.
  - Localized Payment Details Dialog (`_showPaymentDetailsDialog`), Budget Details Dialog (`_showBudgetDetailsDialog`), and all WhatsApp/Email sharing modal dialogs.
  - Localized status badges (`_buildStatusBadge`) to display pure Arabic or English for Paid, Approved, Pending Review, Draft, and Reconciled.
  - Localized date column prefixes in Payment Requests Registry (`l.requestDateLabel`, `l.dueDateLabel`).
  - Localized responsible authority in budget summary table (`l.customsAuthority`).
- **Task B (Copy Data Enablement):** Complete.
  - Replaced manual `Clipboard.setData` with unified `CopyHelper.copy` across all share modals and summary actions.
  - Wrapped metric badge values in `_buildMetricBadge` with `CopyableText`.
  - Wrapped Linked POs table cells in Tab 0 with `CopyableText`.
  - Wrapped all 9 data cells in Payment Requests Registry DataTable with `CopyableTableCell` including comprehensive TSV `rowSummary`.
  - Wrapped multi-currency foreign and local cost values in Consolidated Budget Summary with `CopyableText`.
  - Upgraded `SavedBudgetsRegistryTab` cards, metrics, exchange rates, and cost tables with `CopyableText` and `CopyableTableCell`.
- **Verification:**
  - `flutter analyze lib/features/financial_approval/` → **0 issues found (100% clean)!**
  - `flutter analyze lib/core/localization/` → **0 issues found!**
  - `flutter test test/financial_approval_localization_test.dart test/financial_approval_model_test.dart` → **8/8 tests passed (100%)** ✅.
  - `python -m pytest tests/unit/test_swift_mt103_parser.py` → **4/4 passed (100%)** ✅.

---

## 📝 Session Log: Screens 6 & 7: Customs Studies & Consultations — 2026-09-07
- **Target Files:**
  - `frontend/lib/features/customs_consultation/screens/customs_consultation_screen.dart` (Screen 6: Customs Workspace)
  - `frontend/lib/features/customs_consultation/widgets/saved_consultations_tab.dart` (Screen 7: Consultations Log)
  - `frontend/lib/features/customs_consultation/widgets/consultation_metric_badge.dart`
  - `frontend/lib/features/customs_consultation/widgets/consultation_details_dialog.dart`
  - `frontend/lib/features/customs_consultation/widgets/post_save_status_dialog.dart`
  - `frontend/lib/features/customs_consultation/widgets/blocking_issues_dialog.dart`
- **Route Index:** `6` and `7`
- **Task A (Localization / i18n):** Complete.
  - Added 35+ keys for customs workspace, ocean/air freight box, marine insurance segment, CIF formula, tariff details table, checklist documents, agencies, responsible parties, and statuses.
  - Eliminated hardcoded Arabic and bilingual stacked text from:
    - Linked PO, invoice count, and project name summaries (`l.linkedPurchaseOrdersSummary`, `l.approvedInvoicesSummary`, `l.projectNamedSummary`).
    - Currency and customs exchange rate fields (`l.invoiceCurrencyLabel`, `l.customsFxRateLabel`).
    - Freight data container (`l.freightDataHeader`, `l.fetchHighestFreightFromStudy`, `l.foreignFreightAmountLabel`, `l.freightCurrencyLabel`, `l.freightFxRateLabel`).
    - Marine insurance dropdown and helper texts (`l.estimatedCustomsInsuranceRateLabel`, `l.standardCustomsInsuranceRate`, `l.customInsuranceRate`, `l.autoCalculatedCandFInsuranceHelper`).
    - Declared CIF base summary and formula breakdown (`l.declaredCifBaseLabel`, `l.cifFormulaBreakdown`).
    - Tariff details table header and view switcher (`l.tariffDetailsTableTitle`, `l.groupByHsCodeOption`, `l.detailedItemViewOption`).
    - Currency column (`l.valueInCurrencyCol(_customsCurrency)`).
    - Document checklist in both narrow and wide responsive layouts: localized document type via `_getLocalizedDocType(item.documentType, l)`, remarks via `_getLocalizedRemarks(item.remarks, l)`, regulatory agency (`GOEIC` → `l.goeicAgencyName`), responsible party dropdown options (`l.partyCustomsBroker`, `l.partySupplierExporter`, `l.partyImporterTeam`, `l.partyFreightForwarder`), and status dropdown options (`l.statusPending`, `l.statusReceived`, `l.statusVerified`, `l.statusApproved`, `l.statusRejected`).
    - Removed `isArabic` ternary evaluations across the screen.
    - Localized loading and error states in saved consultations tab (`l.loading`, `l.error`).
- **Task B (Copy Data Enablement):** Complete.
  - Upgraded `ConsultationMetricBadge` to wrap its value in `CopyableText`.
  - Wrapped CIF metrics and project names with `CopyableText`.
  - Wrapped all 10 `DataCell`s in tariff calculation `DataTable` with `CopyableTableCell` with complete row summaries.
  - Wrapped checklist HS code, document type, agency, and remarks with `CopyableText`.
  - Wrapped all 7 data cells in `SavedConsultationsTab` main `DataTable` with `CopyableTableCell` and comprehensive `rowSummary`.
  - Wrapped details dialog title, header details, metric badges, broker quote cells, and checklist cells with `CopyableText`.
  - Wrapped post-save status dialog consultation code, document types, and HS codes with `CopyableText`.
  - Wrapped blocking issues dialog document types with `CopyableText`.
- **Verification:**
  - `dart analyze lib/features/customs_consultation/ lib/core/localization/ test/customs_consultation_localization_test.dart` → **0 errors!**
  - `flutter test test/customs_consultation_localization_test.dart test/customs_consultation_model_test.dart` → **10/10 tests passing (100%)** ✅.

---

## 📝 Session Log: Screens 4 & 5: Shipping Scenarios & Saved Scenarios Registry — 2026-09-07
- **Target Files:**
  - `frontend/lib/features/shipping_scenarios/screens/shipping_scenarios_screen.dart` (Tab 0: Evaluator)
  - `frontend/lib/features/shipping_scenarios/widgets/saved_scenarios_registry_tab.dart` (Tab 1: Saved Registry)
- **Route Index:** `4` and `5`
- **Task A (Localization / i18n):** Complete.
  - Replaced all hardcoded Arabic and bilingual strings with keys from `app_localizations.dart`:
    - All snackbars in state methods (session loaded, quotes added, quotes extracted, cancel edit mode, save failed).
    - AI Extractor widget: title, expand/collapse tooltips, paste/clear/sample/upload/extract buttons, banners, attached file, POL/POD chips, transit route chips, ocean freight, local charges, and total labels.
    - Evaluator UI: study title hint, forwarder and shipping line search hints, add line tooltip, POL-POD lead time strip, total containers applied count, clearance cost summary.
    - All 8 validation snackbars in `_saveEvaluationSession` (complete data, shipping line required, dates required, sailing before CRD, ETA after sailing, negative days, duplicate quote).
    - Save success report dialog: titles, details labels, comparative report table headers, badges, and copy buttons.
    - Container dual matrix comparison dialog: localized stackable/non-stackable options, recommended container code, and space utilization without hardcoded bilingual text.
    - Visual container load plan simulation dialog: cleaned up parenthetical English in Arabic localizations (`app_localizations_ar.dart`) and English localizations (`app_localizations_en.dart`), choice chips, metric pills, load table headers, status labels, and layout titles.
    - Cost items 18–21 (`clearanceBrokerFeeItem`, `inspectionFeeItem`, `inlandTransportFeeItem`, `portClearanceExpensesItem`) localized cleanly.
    - Removed unused `isArabic` variable and conditional bilingual ternary expressions.
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped evaluator metric cards (`val`) with `CopyableText`.
  - Wrapped all side-by-side comparison `DataTable` cells with `CopyableTableCell` including full `rowSummary`.
  - Wrapped saved scenarios registry summary cards with `CopyableText`.
  - Wrapped all 10 `DataCell`s in main saved scenarios `DataTable` with `CopyableTableCell` with comprehensive `rowSummary`.
  - Wrapped quotation comparison cells in session details dialog with `CopyableTableCell`.
  - Wrapped load planner metric pills and table cells with `CopyableText`.
- **Verification:**
  - `dart analyze lib/features/shipping_scenarios/ lib/core/localization/` → **0 errors, 0 warnings!**
  - `flutter test test/shipping_scenarios_localization_test.dart test/copyable_data_helper_test.dart` → **8/8 tests passing (100%)** ✅.

---

## 📝 Session Log: Screen 2: Purchase Orders — 2026-09-07
- **Target Screen:** `frontend/lib/features/purchase_orders/screens/purchase_orders_screen.dart`
- **Route Index:** `2`
- **Task A (Localization / i18n):** Complete.
  - Localized status dropdown options (`statusDraft`, `statusPoApproved`, `statusInTransit`, `statusClosed`).
  - Localized table column 9 header with `cbmAndGrossWeightCol` ('الحجم والوزن القائم' / 'CBM & Gross Wt').
  - Localized status badge via `_getStatusLabel(po.status, l)` eliminating hardcoded bilingual or Arabic-only fallbacks.
  - Localized PO balance ledger action button tooltip (`poBalanceLedgerTooltip`).
  - Localized print snackbars and confirmation dialogs (`confirmDeactivatePo`, `confirmRestorePo`, `deactivatePoTooltip`, `restorePoTooltip`).
  - Localized Master Pallet Plan dialog (title, pallet counters with units, 3D simulation button, table headers for dimensions, weights, quantities).
  - Localized Visual Container Load Planner dialog (title, metrics summary, top/side view segmented buttons, container titles, package counts).
  - Cleaned up parenthetical English in Arabic localizations (`app_localizations_ar.dart`) for container load plan, export report, side view, and top view.
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped summary metrics in `_buildSummaryCard` with `CopyableText`.
  - Wrapped all 10 `DataCell`s in main `DataTable` with `CopyableTableCell` generating a complete tab-separated row summary for full-row copying.
  - Wrapped detail items in PO details dialog (`_buildDetailItem`) with `CopyableText`.
  - Added localized feedback messages for single cell and full PO copy (`copyAllData`, `copyAllPoDataSuccess`).
- **Verification:**
  - `flutter test test/purchase_orders_localization_test.dart` (5/5 passing).
  - `flutter analyze lib/features/purchase_orders/ lib/core/localization/ test/purchase_orders_localization_test.dart` (0 issues).
  - Full frontend suite: 408/408 tests passing.

---

## 📝 Session Log: Screen 3: CBM & Cargo Calculator — 2026-09-07
- **Target Files:**
  - `frontend/lib/features/cbm_calculator/screens/cbm_calculator_screen.dart`
  - `frontend/lib/features/cbm_calculator/widgets/saved_cbm_registry_tab.dart`
- **Route Index:** `3`
- **Task A (Localization / i18n):** Complete.
  - Added 9 new localization keys to all 3 localization files (`app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_ar.dart`): `cbmStackingAccepts`, `cbmStackingRejects`, `cbmNotLinked`, `cbmDownloadCsvTitle`, `cbmSendingReportToScreen` (parameterized), `cbmRowLineCbm`, `cbmRowLineGross`, `cbmRowLineAirVol`, `copyAllCbmDataSuccess`.
  - Replaced hardcoded Arabic row output labels (`'CBM: ...'`, `'الإجمالي: ...'`, `'الوزن الجوي: ...'`) with `l.cbmRowLineCbm`, `l.cbmRowLineGross`, `l.cbmRowLineAirVol`.
  - Replaced hardcoded `'FAILED'` string in visual load plan table with `l.operationFailed`.
  - Fixed string-matching color logic in `cbm_calculator_screen.dart` visual load plan: replaced `statusText.contains('Failed')` / `statusText.contains('Non-')` with boolean `res.fits` / `hasNonStackable` flags.
  - Fixed hardcoded `'📦 يقبل الرص'` / `'🚫 لا يقبل'` in registry DataTable stacking cell → `l.cbmStackingAccepts` / `l.cbmStackingRejects`.
  - Fixed hardcoded `'غير مرتبط'` in registry DataTable PO link cell → `l.cbmNotLinked`.
  - Fixed hardcoded `'Calculation Session'` title in registry DataTable → `l.calculationSessionTitle`.
  - Fixed `_downloadCalcCSV` hardcoded Arabic dialog title → `l.cbmDownloadCsvTitle` (added `final l = context.l10n;` at function start).
  - Fixed `_triggerReportPrint` hardcoded Arabic SnackBar text → `l.cbmSendingReportToScreen(calc.calcCode)` (added `final l = context.l10n;` at function start).
  - Fixed string-matching color logic in `saved_cbm_registry_tab.dart` `_showVisualLoadPlanDialog`: replaced `statusText.contains('فشل')` / `statusText.contains('غير قابل')` with boolean `res.fits` / `hasNonStackable` flags.
  - Removed unnecessary `import 'package:flutter/services.dart'` from `saved_cbm_registry_tab.dart` (redundant with `material.dart`).
- **Task B (Copy Data Enablement):** Complete.
  - Added `import '../../../core/widgets/copyable_data_helper.dart'` to both `cbm_calculator_screen.dart` and `saved_cbm_registry_tab.dart`.
  - Wrapped row output column values (`CBM`, `Gross`, `Air Vol`) with `CopyableText` in `cbm_calculator_screen.dart`.
  - Wrapped `_buildResultCardItem` value and subtitle with `CopyableText`.
  - Wrapped all container comparison DataTable data rows with `CopyableTableCell` (value + full row summary).
  - Wrapped all visual load plan summary table rows with `CopyableTableCell` (in `cbm_calculator_screen.dart`).
  - Wrapped all 10 main registry DataTable data cells with `CopyableTableCell` with full row summary (in `saved_cbm_registry_tab.dart`).
- **Verification:**
  - `dart analyze lib/features/cbm_calculator/` → **No issues found!**
  - Full frontend suite: **408/408 tests passing** ✅.

---

## 📝 Session Log: Screen 1: Import Files Management — 2026-09-07
- **Target Screen:** `frontend/lib/features/import_files/screens/import_files_screen.dart`
- **Route Index:** `1`
- **Task A (Localization / i18n):** Complete.
  - Eliminated hardcoded bilingual text (`(AI)`, `(What-If)`) in top toolbar buttons and replaced with clean localized getters `l.smartInvoiceBlExtractorButton` and `l.whatIfSimulatorButton` ('استخلاص الفواتير والبوالص الذكي' in AR, 'Smart Invoice & B/L Extractor' in EN; 'محاكي الأزمات وتحوط الصرف' in AR, 'What-If & Hedging Simulator' in EN).
  - Localized PO and PI short prefixes in main data table (`l.poNumberShortPrefix`, `l.piNumberShortPrefix`).
  - Localized priority badges and status chips via `_getPriorityLabel` and `_getStatusLabel` ensuring pure single-locale rendering without hardcoded fallback strings.
  - Localized all 21 columns and headers in print preview and master report dialogs (`l.colIncoterms`, `l.colPort`, `l.colWarehouse`, `l.colDirectTransit`, `l.colPickupDate`, `l.colDocDate`, `l.colSwift`, `l.colCarrier`, `l.colAcid`, `l.colForm4`, `l.colForm46`, `l.saveComprehensiveReportDialogTitle`, `l.customsBrokerLabel`).
  - Localized field change diff names and confirmation dialog title in `import_file_form_dialog.dart` (`l.importFileIdLabel`, `l.importingCompany`, `l.foreignSupplier`, `l.responsiblePersonLabel`, `l.purchaseOrder`, `l.proformaInvoiceNoLabel`, `l.dynColEstimatedCost`, `l.status`, `l.notesInstructions`, `l.importFileReviewChangesTitle`, `l.importFileSavedSuccess`).
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped metric values in `_buildMetricMiniCard` and `_buildMetricCard` with `CopyableText(value, showIcon: false, ...)`.
  - Wrapped all 12 `DataCell`s for every row in the main `DataTable` with `CopyableTableCell(value: ..., rowSummary: ..., child: ...)`, supporting both individual cell copy and complete row TSV copy.
  - Wrapped file title header in Section 2 with `CopyableText`.
  - Wrapped all cells in the nested Linked POs table in the print preview dialog with `CopyableTableCell` and `poRowSummary`.
- **Verification:** Unit and widget tests passing (4/4 in `test/import_files_localization_test.dart`, 7/7 across import file test suites), `flutter analyze` 0 issues across `lib/features/import_files/` and `lib/core/localization/`.

---

## 📝 Session Log: Screen 0: Operational Dashboard — 2026-09-07
- **Target Screen:** `frontend/lib/features/operational_dashboard/screens/operational_dashboard_screen.dart`
- **Route Index:** `0`
- **Task A (Localization / i18n):** Complete.
  - Eliminated hardcoded bilingual text (`/`) in responsible stakeholder labels (`'المستخلص الجمركي'` in AR, `'Customs Broker'` in EN; removed `'شركة الشحن / Freight Forwarder'`).
  - Localized `'NEW'` badge dynamically via `context.l10n.badgeNew` ('جديد' / 'NEW').
  - Implemented dynamic single-language priority labels via `_getPriorityLabel` mapping to `context.l10n.priorityHigh`, `priorityCritical`, `priorityMedium`, `priorityLow`.
  - Replaced hardcoded string formatting in pending regulatory requirements with parameterized localized method `context.l10n.pendingRegRequirementsCount(...)`.
  - Added localized tooltip to AppBar refresh action button (`l.refresh`).
  - Fixed variable shadowing of `l` in `_buildDailyCheckinsCard`.
- **Task B (Copy Data Enablement):** Complete.
  - Wrapped KPI card metric values with `CopyableText`.
  - Wrapped all shipment card details (custom file name, import file code, company name, supplier name, broker name, PO number, progress percentage) with `CopyableText`.
  - Wrapped shipment 3-way stage pathways (previous, current, next) with `CopyableText`.
  - Wrapped next action title, description, and responsible role badge with `CopyableText`.
  - Wrapped linked smart task titles and due dates with `CopyableText`.
  - Wrapped closed shipment banner with `CopyableText`.
  - Wrapped risk alert chips with double-tap/right-click clipboard copy handlers and localized confirmation feedback.
  - Wrapped daily checkin notes, stage tags, and file codes with `CopyableText`.
- **Verification:** Unit tests passing (9/9 in `test/operational_dashboard_test.dart` and `test/copyable_data_helper_test.dart`), `flutter analyze` 0 issues.

---

## 🏛️ Architecture Decisions

### 1. Localization (i18n) Architecture
- **System Used:** Flutter `InheritedWidget` / `Localizations` architecture via `AppLocalizations` (abstract base class in `frontend/lib/core/localization/app_localizations.dart`), with concrete implementations `AppLocalizationsAr` (`app_localizations_ar.dart`) and `AppLocalizationsEn` (`app_localizations_en.dart`).
- **State Management:** Riverpod `localeProvider` (`StateNotifierProvider<LocaleNotifier, Locale>` in `frontend/lib/core/localization/locale_provider.dart`), persisting user choice in `FlutterSecureStorage` under key `app_locale`.
- **Extension Accessor:** `context.l10n` provides immediate, type-safe access to all translated strings.
- **Root Cause of Stacked Languages:**
  - Hardcoded concatenated strings (e.g. `Text('اسم الشركة / Company Name')`, `Text('المورد / Supplier')`, `Text('القيمة / Value')`).
  - Stacked `Column` or `Wrap` layouts containing two separate `Text` widgets (one in Arabic, one in English) displayed concurrently.
  - Hardcoded Arabic labels in some widgets while others used English fallback, causing visual mixing.
- **Remediation Rule:** Every user-facing string must be queried via `context.l10n.<key>`. If Arabic is selected (`ar`), Arabic only is rendered. If English is selected (`en`), English only is rendered. Concatenated bilingual labels (`/`) are strictly removed.

---

### 2. Clipboard Copy Helper Architecture
- **Central Helper Utility:** `frontend/lib/core/widgets/copyable_data_helper.dart`
  - `CopyHelper.copy(BuildContext context, String text, {String? customMessage})`:
    - Writes sanitized string to `Clipboard.setData(ClipboardData(text: text))`.
    - Automatically displays a floating, high-contrast feedback `SnackBar` (`AppTheme.flatCharcoal` background, `AppTheme.flatEmerald` confirmation icon) displaying `customMessage ?? context.l10n.copiedToClipboardGeneric` with a 1500ms auto-dismiss.
  - `CopyableText(String text, ...)`:
    - Renders text with desktop hover detection, pointer cursor, and tooltip (`context.l10n.copyTooltip`).
    - Double-tap or secondary-tap (right-click on desktop) copies the text instantly.
    - Optional hover copy icon button for clear desktop usability.
  - `CopyableTableCell(Widget child, String value, {String? rowSummary, ...})`:
    - Provides a native desktop right-click context menu offering:
      1. `copyValue` ("نسخ القيمة / Copy Value")
      2. `copyRow` ("نسخ بيانات السطر / Copy Row Data")
  - `EnterpriseDataTable`:
    - Native header toolbar TSV clipboard export (`_copyToClipboard()`) for complete tabular datasets.

---

### 3. Reviewer Workflow Protocol
1. **Scope Limit:** Review and fix strictly **ONE screen per session**. Do not expand to multiple screens.
2. **Element Order:** On each UI element, fix localization key first $\rightarrow$ wrap with copy layer second.
3. **Validation Checklist:**
   - [ ] No concatenated bilingual strings (`/`) remain.
   - [ ] All static labels, headers, chips, and tooltips use `context.l10n`.
   - [ ] Input fields and read-only text allow copying to clipboard.
   - [ ] Table cells allow individual copying and/or row copying via context menu.
   - [ ] Hot reload and verify UI in both Arabic (`ar`) and English (`en`).
   - [ ] Update this log: set status to `Complete`, note date, and point next screen.

---

### 4. Standalone Extraction & Generation Tools Architecture
- **Concept & Operational Scope:**
  - In ImportFlow ERP, multiple advanced AI/OCR tools operate in a **hybrid operational mode**: they can either be called in the context of an active import file, OR used as **standalone desktop utility tools** directly from toolbars, dialogs, or navigation menus without pre-selecting an import file.
- **Tracked Standalone & Extraction Engines:**
  1. **Smart Invoice & B/L Extractor & Matcher (`smart_invoice_bl_extractor_dialog.dart` / `invoice_bl_matcher_tab.dart`):**
     - Standalone modal dialog supporting raw text or document upload (PDF/Word/Excel/Image) for Commercial Invoices and Bills of Lading.
     - Performs automated 10-point Egyptian customs compliance radar matching, calculates weight and CBM variances against tolerances, and generates carrier correction letters and amendment notices completely independently of saved database entities.
  2. **Smart AI Clearance Quotation & Estimate Extractor (`showSmartClearanceExtractorDialog`):**
     - Standalone extractor for complex 3-page, 35+ item freight/clearance broker quotations (e.g. ACC / Sherif Saksali).
     - Provides instant container breakdown (40HQ / 20GP / LCL), 5-pillar cost categorization, and price list coding without requiring a pre-existing RFQ.
  3. **MTS Smart AI Parser (`nafeza_acid_screen.dart` - SubTab 1):**
     - Standalone raw MTS notification parser extracting ACID, foreign exporter, importer VAT/CR, and cargo item descriptions directly from pasted Egyptian Nafeza text blocks.
  4. **CBM & 3D Container Cargo Calculator (`cbm_calculator_screen.dart`):**
     - Operates as a standalone mathematical cargo measurement sandbox or linked to PO packing lists.
  5. **What-If Crisis & FX Hedging Simulator (`what_if_simulator_dialog.dart`):**
     - Independent macro-economic simulation sandbox for currency devaluation, tariff shifts, and demurrage risks.
- **Architectural Rules for Standalone Tools:**
  - **Single-Locale Enforcement:** Must adhere strictly to active app locale; no bilingual slashes or dual-language fallback strings.
  - **Full Selection & Copy Enablement:** All modal dialogs must be wrapped in `SelectionArea` with `CopyableTableCell` for tables and `CopyHelper.copy` for output dispatches.
  - **Decoupled Business Logic:** Standalone tools must never throw exceptions or fail to render when `importFile` is null; they must operate on sample data, user clipboard text, or uploaded files gracefully.

---

## 📱 Master Screen Registry & Review Status

### Screen 0: Operational Dashboard
- **File:** `frontend/lib/features/operational_dashboard/screens/operational_dashboard_screen.dart`
- **Route Index:** `0`
- **Scope:** Metric cards, active shipments overview, critical alerts, phase status indicators, quick action shortcuts.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Removed hardcoded bilingual text (`/`) in responsible titles (e.g. `'المستخلص الجمركي'` in AR, `'Customs Broker'` in EN), removed hardcoded `'NEW'` badge replaced by `l.badgeNew`, dynamic single-language priority labels (`_getPriorityLabel`), localized refresh button tooltip (`l.refresh`), localized regulatory requirements count (`l.pendingRegRequirementsCount`).
- **Copy Data Status:** `Complete` — All metric values wrapped with `CopyableText`, active shipment cards (codes, names, suppliers, brokers, PO numbers, progress, pathways, next actions, task titles, due dates, closed shipment banner) wrapped with `CopyableText` and risk alerts enabled with clipboard copy on double-tap/right-click with toast confirmation.
- **Date Reviewed:** 2026-09-07

### Screen 1: Import Files Management
- **File:** `frontend/lib/features/import_files/screens/import_files_screen.dart`
- **Route Index:** `1`
- **Scope:** Import files data table, file summary cards, filters, status chips, create/edit file dialogs.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Replaced bilingual toolbar buttons with `l.smartInvoiceBlExtractorButton` and `l.whatIfSimulatorButton`, localized PO/PI prefixes, localized priority and status badges, localized all 21 master report and print preview columns, localized field change diffs and confirmation alerts.
- **Copy Data Status:** `Complete` — Wrapped metric card values with `CopyableText`, wrapped all 12 main `DataTable` cells with `CopyableTableCell` with full row summary copy, wrapped nested PO table cells in print preview with `CopyableTableCell`, wrapped shipment headers with `CopyableText`.
- **Date Reviewed:** 2026-09-07

### Screen 2: Purchase Orders
- **File:** `frontend/lib/features/purchase_orders/screens/purchase_orders_screen.dart`
- **Route Index:** `2`
- **Scope:** PO master table, PO items breakdown, financial totals, supplier links, status workflow.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Localized status dropdown options (`statusDraft`, `statusPoApproved`, `statusInTransit`, `statusClosed`), localized all column headers and action labels, removed all hardcoded Arabic/English bilingual strings.
- **Copy Data Status:** `Complete` — Wrapped all main DataTable cells with `CopyableTableCell` with full row summary, wrapped PO items breakdown cells, wrapped financial total values with `CopyableText`.
- **Date Reviewed:** 2026-09-07

### Screen 3: CBM & Cargo Calculator
- **Files:**
  - `frontend/lib/features/cbm_calculator/screens/cbm_calculator_screen.dart`
  - `frontend/lib/features/cbm_calculator/widgets/saved_cbm_registry_tab.dart`
- **Route Index:** `3`
- **Scope:** Package measurements input, 3D container packing results, volumetric weight metrics, container recommendation cards, saved calculation registry DataTable, visual load plan dialogs.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Added 9 new keys (`cbmStackingAccepts`, `cbmStackingRejects`, `cbmNotLinked`, `cbmDownloadCsvTitle`, `cbmSendingReportToScreen`, `cbmRowLineCbm`, `cbmRowLineGross`, `cbmRowLineAirVol`, `copyAllCbmDataSuccess`). Replaced all hardcoded Arabic labels in row output column, `_downloadCalcCSV` dialog title, `_triggerReportPrint` SnackBar, container comparison table, visual load plan summary tables (both screen and registry widget). Fixed string-matching color logic to use boolean flags (`res.fits`, `hasNonStackable`) instead of locale-sensitive string comparisons.
- **Copy Data Status:** `Complete` — Wrapped row output column values with `CopyableText`, wrapped `_buildResultCardItem` value and subtitle with `CopyableText`, wrapped all container comparison DataTable rows with `CopyableTableCell`, wrapped all visual load plan summary table rows with `CopyableTableCell`, wrapped all 10 main registry DataTable data cells with `CopyableTableCell` with full row summary.
- **Date Reviewed:** 2026-09-07

### Screen 4: Shipping Scenarios & Timeline (Study)
- **File:** `frontend/lib/features/shipping_scenarios/screens/shipping_scenarios_screen.dart` (Tab 0)
- **Route Index:** `4`
- **Scope:** Feasibility analysis, freight comparison matrix, scenario parameters form, cost breakdown.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Localized all snackbars, AI extractor, evaluator form, validation messages, clearance fee cost items 18-21, success report dialog, container dual matrix dialog, and visual load plan simulation dialog. Eliminated all hardcoded bilingual text.
- **Copy Data Status:** `Complete` — Wrapped evaluator metrics with `CopyableText`, wrapped all side-by-side comparison `DataTable` cells with `CopyableTableCell` + `rowSummary`.
- **Date Reviewed:** 2026-09-07

### Screen 5: Shipping Scenarios Saved Records
- **File:** `frontend/lib/features/shipping_scenarios/widgets/saved_scenarios_registry_tab.dart` (Tab 1)
- **Route Index:** `5`
- **Scope:** Historical scenario records table, scenario comparator, archived records summary, load planner.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Removed `isArabic` variable and conditional bilingual branching, localized headers, stat cards, load planner simulation dialog, and details dialog with pure Arabic and English.
- **Copy Data Status:** `Complete` — Wrapped summary stat cards with `CopyableText`, wrapped all 10 registry `DataTable` cells with `CopyableTableCell` + `rowSummary`, wrapped quotation comparison cells in session details dialog with `CopyableTableCell`, wrapped load planner metrics and table cells with `CopyableText`.
- **Date Reviewed:** 2026-09-07

### Screen 6: Customs Studies & Consultations (Workspace)
- **File:** `frontend/lib/features/customs_consultation/screens/customs_consultation_screen.dart` (Tab 0)
- **Route Index:** `6`
- **Scope:** Tariff HS Code checklist, regulatory pre-clearance validation, required approval documents table.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — 35+ keys added, eliminated all hardcoded Arabic and bilingual stacked text from CIF breakdown, currency, freight, marine insurance, tariff details table, regulatory document checklist (narrow & wide layouts), agencies, responsible parties, and statuses.
- **Copy Data Status:** `Complete` — Wrapped ConsultationMetricBadge, CIF metrics, project names, all 10 DataCells in tariff calculation DataTable with CopyableTableCell + rowSummary, and checklist items with CopyableText.
- **Date Reviewed:** 2026-09-07

### Screen 7: Customs Studies Consultations Log
- **File:** `frontend/lib/features/customs_consultation/widgets/saved_consultations_tab.dart` (Tab 1)
- **Route Index:** `7`
- **Scope:** Consultation log history, broker opinions, compliance audit trail.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Localized loading and error states, and dialog titles.
- **Copy Data Status:** `Complete` — Wrapped all 7 data cells in SavedConsultationsTab DataTable with CopyableTableCell + full rowSummary, plus details and blocking dialogs with CopyableText.
- **Date Reviewed:** 2026-09-07

### Screen 8: Financial Approval - Requests & Approvals
- **File:** `frontend/lib/features/financial_approval/screens/financial_approval_screen.dart` (Tab 0)
- **Route Index:** `8`
- **Scope:** Supplier payment requests form, master data link, duplicate prevention, linked POs table, and financial authorization.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Full pure Arabic and English translations without bilingual stacking, localized duplicate request alerts, CRUD toasts, notes, and toolbar actions.
- **Copy Data Status:** `Complete` — Enabled CopyableText for Linked POs, metric badges, and CopyHelper for summary data.
- **Date Reviewed:** 2026-09-07

### Screen 9: Financial Approval - Import Budget Approval Form
- **File:** `frontend/lib/features/financial_approval/screens/financial_approval_screen.dart` (Tab 1)
- **Route Index:** `9`
- **Scope:** Multi-currency import budget estimation form, foreign and local expense breakdown, and executive certification.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Localized budget setup fields, duplicate budget warnings, authority labels (Customs Authority / מصلحة الجمارك), and certification toasts.
- **Copy Data Status:** `Complete` — Wrapped multi-currency budget amounts, EGP totals, and Grand Total bar with CopyableText.
- **Date Reviewed:** 2026-09-07

### Screen 10: Financial Approval - Saved Budgets & Payments Registry & SWIFT Hub
- **File:** `frontend/lib/features/financial_approval/widgets/saved_budgets_registry_tab.dart` (Tab 2) & `financial_approval_screen.dart` (Tab 3 & 4)
- **Route Index:** `10`
- **Scope:** Saved budgets registry cards and cost breakdown, payment requests log DataTable, SWIFT MT103 extraction and reconciliation hub.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Localized all 9 table columns, date prefixes, status badges (Paid, Approved, Pending Review, Draft, Reconciled), and share/export dialogs.
- **Copy Data Status:** `Complete` — Wrapped all 9 DataCells in Payment Requests Registry with CopyableTableCell + rowSummary, budget cards with CopyableText and CopyableTableCell.
- **Date Reviewed:** 2026-09-07

### Screen 11: Nafeza & ACID Operations - ACID Request Form
- **File:** `frontend/lib/features/import_documentation/screens/nafeza_acid_screen.dart` (SubTab 0)
- **Route Index:** `11`
- **Scope:** ACID number issuance request, master party links, SearchableDropdowns, dispatch messages (WhatsApp, Email, English).
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Pure single-locale dropdown options, invoice types, and localized WhatsApp/Email dispatch preview cards.
- **Copy Data Status:** `Complete` — CopyHelper.copy on all dispatch actions and CopyableText on loaded session banners.
- **Date Reviewed:** 2026-09-07

### Screen 12: Nafeza & ACID Operations - MTS Smart AI Parser
- **File:** `frontend/lib/features/import_documentation/screens/nafeza_acid_screen.dart` (SubTab 1)
- **Route Index:** `12`
- **Scope:** Nafeza raw notification parsing, automated data extraction, supplier auto-coding, and manual edit modal.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Localized parser buttons, disclaimer alerts, supplier coding toasts, and edit modal dropdown types.
- **Copy Data Status:** `Complete` — Extracted fields wrapped with CopyableText.
- **Date Reviewed:** 2026-09-07

### Screen 13: Nafeza & ACID Operations - Discrepancy Matrix
- **File:** `frontend/lib/features/import_documentation/screens/nafeza_acid_screen.dart` (SubTab 2)
- **Route Index:** `13`
- **Scope:** Pre-shipment document conformity, requested vs generated value comparison, discrepancy justification.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Dynamic single-locale field labels, status badges, and override reason hints.
- **Copy Data Status:** `Complete` — Requested and generated comparison values wrapped with CopyableText.
- **Date Reviewed:** 2026-09-07

### Screen 14: Nafeza & ACID Operations - ACID Issuance Registry
- **File:** `frontend/lib/features/import_documentation/screens/nafeza_acid_screen.dart` (SubTab 3)
- **Route Index:** `14`
- **Scope:** Certified ACID numbers table, session search, delete/edit actions.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Localized table columns, PO prefixes, search hints, and delete confirmation dialogs.
- **Copy Data Status:** `Complete` — All DataTable cells wrapped with CopyableTableCell providing individual and full-row TSV copy.
- **Date Reviewed:** 2026-09-07

### Screen 15: Nafeza & ACID Operations - Expiry & Release Tracker
- **File:** `frontend/lib/features/import_documentation/screens/nafeza_acid_screen.dart` (SubTab 4)
- **Route Index:** `15`
- **Scope:** 14-day expiry warning triggers, release validity status cards, days remaining countdown.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Localized metric cards, table headers, and validity status badges (Valid, Expiring Soon, Expired).
- **Copy Data Status:** `Complete` — All DataTable cells wrapped with CopyableTableCell + rowSummary, metric counters wrapped with CopyableText.
- **Date Reviewed:** 2026-09-07

### Screen 16: Bank Form 4 & Endorsement - Application
- **File:** `frontend/lib/features/import_documentation/screens/bank_form4_screen.dart` (SubTab 0)
- **Route Index:** `16`
- **Scope:** Bank application details, foreign currency exchange allocation, Form 4 issuance status.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Pure single-locale labels, checklist items without parenthetical acronyms, and clean warnings.
- **Copy Data Status:** `Complete` — Enabled CopyableText for edit mode banner codes and form details.
- **Date Reviewed:** 2026-09-07

### Screen 17: Bank Form 4 & Endorsement - Document Endorsement
- **File:** `frontend/lib/features/import_documentation/screens/bank_form4_screen.dart` (SubTab 1)
- **Route Index:** `17`
- **Scope:** Original shipping documents endorsement, bank release authorization, and registry log.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Localized table columns, search hints, and endorsement status badges (Endorsed / Processing).
- **Copy Data Status:** `Complete` — Wrapped all 6 DataCells in Bank Form 4 Registry with CopyableTableCell + comprehensive TSV rowSummary.
- **Date Reviewed:** 2026-09-07

### Screen 18: Shipment Draft Documents - Draft B/L Review
- **File:** `frontend/lib/features/import_documentation/screens/shipment_draft_docs_screen.dart` (SubTab 2 / `draft_bl_review_tab.dart` & `visual_draft_bl_sheet.dart`)
- **Route Index:** `18`
- **Scope:** Bill of Lading draft review, shipper/consignee validation, container & seal numbers, carrier correction letters, visual B/L export engine.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Localized all 5 review stages, checklist items, carrier correction letters, and visual B/L sheet.
- **Copy Data Status:** `Complete` — Wrapped all checklist rows, revision table, and final registry with `CopyableTableCell` and `CopyableText`.
- **Date Reviewed:** 2026-09-07

### Screen 19: Shipment Draft Documents - Draft COO / EUR.1
- **File:** `frontend/lib/features/import_documentation/screens/shipment_draft_docs_screen.dart` (SubTab 4 / `coo_review_tab.dart` & `visual_draft_coo_sheet.dart`)
- **Route Index:** `19`
- **Scope:** Certificate of Origin validation, preferential trade agreement eligibility (EUR.1 / Arab Agreement), visual COO sheet.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Single-language compliance banner, localized discrepancy matrix, and COO registry.
- **Copy Data Status:** `Complete` — `CopyableTableCell` on discrepancy matrix and registry, `CopyableText` on visual COO sheet.
- **Date Reviewed:** 2026-09-07

### Screen 20: Shipment Draft Documents - Customs Approval
- **File:** `frontend/lib/features/import_documentation/screens/shipment_draft_docs_screen.dart` (SubTab 0 / `customs_document_approval_tab.dart`)
- **Route Index:** `20`
- **Scope:** Broker pre-approval checklist, draft documents customs readiness sign-off, live matrix banner, discrepancy rectification tickets.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Localized dual-tier approvals, ticket severity/status, and live matrix banner.
- **Copy Data Status:** `Complete` — `SelectionArea` enabled across dual approval and discrepancy cards, `CopyableText` on all codes.
- **Date Reviewed:** 2026-09-07

### Screen 21: Shipment Draft Documents - PO & Packing Reconciliation
- **File:** `frontend/lib/features/import_documentation/screens/shipment_draft_docs_screen.dart` (SubTab 1 / `po_reconciliation_tab.dart`)
- **Route Index:** `21`
- **Scope:** Line items cross-check between PO and supplier commercial packing list, weights reconciliation, smart discrepancy extractor, certified audit records.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Added 27 keys, dynamic resolvers for checks and statuses, clean single-locale reporting.
- **Copy Data Status:** `Complete` — `SelectionArea` across all sections, `CopyableTableCell` on invoice/packing/discrepancy/history tables, `CopyHelper.copy`.
- **Date Reviewed:** 2026-09-07

### Screen 22: Shipment Draft Documents - Smart Invoice vs B/L Match
- **File:** `frontend/lib/features/import_documentation/screens/shipment_draft_docs_screen.dart` (SubTab 3 / `invoice_bl_matcher_tab.dart` & `smart_invoice_bl_extractor_dialog.dart`)
- **Route Index:** `22`
- **Scope:** Automated optical/data comparison between Commercial Invoice and Master/House B/L, 10-point Egyptian customs audit radar, carrier correction letters, TSV matrix export.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Added 75+ localization keys, eliminated all stacked slashes and acronyms, pure single-locale tabs, dialogs, and correction templates.
- **Copy Data Status:** `Complete` — `SelectionArea` enabled across matcher view and extractor dialog, `CopyableTableCell` on discrepancy matrix and audit radar, `CopyableText` on metrics, `CopyHelper.copy` for correction letters and TSV data.
- **Date Reviewed:** 2026-09-07

### Screen 23: Customs Declaration 46 - Entry & Declaration
- **File:** `frontend/lib/features/import_documentation/screens/customs_declaration46_screen.dart` (SubTab 0)
- **Route Index:** `23`
- **Scope:** Declaration 46 form fields, customs station, registration number, declaration date.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Added 10 new localization keys, eliminated all stacked English acronyms, parenthetical abbreviations, and bilingual slashes from Arabic keys (`(ACID)`, `(B/L)`, `CIF`, `VAT`, `(EUR.1)`, `(GOEIC)`, `(HS Code)`).
- **Copy Data Status:** `Complete` — `SelectionArea` wrapped across the screen, copy suffix icon buttons on all 9 form fields, `CopyableText` on exemption cards, `CopyableTableCell` on regulatory approvals DataTable and registry table, `CopyHelper.copy` on preview summary and TSV export.
- **Date Reviewed:** 2026-09-07

### Screen 24: Customs Declaration 46 - Tariff Items & Assessment
- **File:** `frontend/lib/features/import_documentation/screens/customs_declaration46_screen.dart` (SubTab 1)
- **Route Index:** `24`
- **Scope:** Itemized customs valuation, CIF calculation, tariff duties, VAT, and service charges.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Added 22 new localization keys. Eliminated all bilingual slashes, stacked abbreviations, and English acronyms (`(CIF)`, `(VAT)`, `(HS Code)`).
- **Copy Data Status:** `Complete` — Maintained `SelectionArea`, wrapped SubTab 1 KPI cards with `CopyableText`, converted all registry table columns to `CopyableTableCell` with full tab-separated `rowSummary`, added itemized tariff assessment dialog with text and TSV export copy actions.
- **Date Reviewed:** 2026-09-07

### Screen 25: Freight Booking Operations
- **File:** `frontend/lib/features/freight_booking/screens/freight_booking_screen.dart`
- **Route Index:** `25`
- **Scope:** Shipping line bookings, container allocation, cost savings comparison, booking confirmation dialog.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Added 15 new localization keys. Fixed all hardcoded strings in DataTable cells, cost savings comparison card, and Print dialog.
- **Copy Data Status:** `Complete` — Wrapped DataTable cells 4–12 with DataCell(CopyableTableCell), View and Print dialogs with SelectionArea, explicit multi-line manifest copy button in Print dialog.
- **Date Reviewed:** 2026-09-07

### Screen 26: Cargo Shipping & Tracking - Allocations (VGM)
- **File:** `frontend/lib/features/cargo_shipping/screens/cargo_shipping_screen.dart` (SubTab 0)
- **Route Index:** `26`
- **Scope:** Container loading manifest, Verified Gross Mass (VGM), seal numbers, departure notice.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Added 14 new localization keys, eliminated all stacked English acronyms (`(VGM)`, `(48h SLA)`, `(PDF / Word / Excel)`), localized AI Extractor button, container type labels, and manifest column headers.
- **Copy Data Status:** `Complete` — Wrapped scaffold body in `SelectionArea`, wrapped active file chips and cargo metrics in `CopyableText`, added copy suffix icons to container fields, and added single-click TSV manifest export in bottom toolbar.
- **Date Reviewed:** 2026-09-08

### Screen 27: Customs Clearance Execution Hub
- **File:** `frontend/lib/features/customs_clearance/screens/customs_clearance_screen.dart`
- **Route Index:** `27`
- **Scope:** Customs inspection progress, radiation/security/health authority inspections, clearance milestones, Under-Bond release.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Added 29 new localization keys, eliminated stacked bilingual acronyms, and localized all under-bond and lab verdict banners.
- **Copy Data Status:** `Complete` — Top-level `SelectionArea`, `CopyableTableCell` across all 4 sub-views, `CopyableText` on clearance card values, copy suffix icons on all 5 dialogs, and 4 dedicated TSV export actions.
- **Date Reviewed:** 2026-09-08

### Screen 28: Inbound Warehouse Hub (GRN)
- **File:** `frontend/lib/features/warehouse_receiving/screens/inbound_warehouse_hub_screen.dart` (SubTab 1) & `warehouse_receiving_screen.dart`
- **Route Index:** `28`
- **Scope:** Goods Received Note (GRN), pallet receipt, damage report, warehouse location assignments, quarantine status.
- **Status:** `Complete`
- **Localization (i18n) Status:** `Complete` — Added 21 new localization keys, eliminated stacked bilingual badge `(Quarantine Lock)`, purified Arabic translations without slashes or English acronyms, and localized all alerts/buttons.
- **Copy Data Status:** `Complete` — Top-level `SelectionArea` on hub and screen, `CopyableText` on card fields and audit counts, copy suffix buttons on form & discrepancy dialogs, and single-click TSV table export.
- **Date Reviewed:** 2026-09-08

### Screen 29: Financial Settlement Hub (Landed Cost Settlement)
- **File:** `frontend/lib/features/financial_settlement/screens/financial_settlement_screen.dart` (SubTab 0)
- **Route Index:** `29`
- **Scope:** Final expense allocations, customs duty receipts, freight settlement, cost per unit landed.
- **Status:** `Pending`

### Screen 30: File Closure & Post-Clearance Archive
- **File:** `frontend/lib/features/file_closure/screens/file_closure_screen.dart`
- **Route Index:** `30`
- **Scope:** Complete import file audit, post-clearance reconciliation, file locking & archiving.
- **Status:** `Pending`

### Screen 31: Master Data - Projects
- **File:** `frontend/lib/features/projects/screens/projects_screen.dart`
- **Route Index:** `31`
- **Scope:** Projects list, budget allocation, assigned import files, project form.
- **Status:** `Pending`

### Screen 32: Master Data - Importing Companies
- **File:** `frontend/lib/features/import_companies/screens/import_companies_screen.dart`
- **Route Index:** `32`
- **Scope:** Legal import entities, tax card & commercial registry data, customs registry number.
- **Status:** `Pending`

### Screen 33: Master Data - Suppliers
- **File:** `frontend/lib/features/suppliers/screens/suppliers_screen.dart`
- **Route Index:** `33`
- **Scope:** Foreign suppliers directory, country of origin, contact details, payment terms.
- **Status:** `Pending`

### Screen 34: Master Data - External Partners & Service Providers
- **File:** `frontend/lib/features/external_service_providers/screens/partners_screen.dart`
- **Route Index:** `34`
- **Scope:** Shipping lines, freight forwarders, customs brokers, inland truckers, inspection bodies.
- **Status:** `Pending`

### Screen 35: Reference Tables - Incoterms 2020
- **File:** `frontend/lib/features/incoterms/screens/incoterms_screen.dart`
- **Route Index:** `35`
- **Scope:** Incoterms rules, cost & risk transfer matrix, insurance & freight obligation breakdown.
- **Status:** `Pending`

### Screen 36: Reference Tables - Customs Tariff Schedule (HS Codes)
- **File:** `frontend/lib/features/customs_tariff/screens/customs_tariff_screen.dart` (Tab 0)
- **Route Index:** `36`
- **Scope:** HS Code directory, duty rates, VAT rates, import fees, trade agreement exemptions.
- **Status:** `Pending`

### Screen 37: Reference Tables - Transport Locations & Ports
- **File:** `frontend/lib/features/transport_locations/screens/transport_locations_screen.dart`
- **Route Index:** `37`
- **Scope:** Sea ports, airports, dry ports, customs zones, UN/LOCODE directory.
- **Status:** `Pending`

### Screen 38: Reference Tables - Currencies & Exchange Rates
- **File:** `frontend/lib/features/currencies/screens/currencies_screen.dart`
- **Route Index:** `38`
- **Scope:** Currency master, official customs exchange rates, historical rate logs.
- **Status:** `Pending`

### Screen 39: System Audit Logs & Operational History
- **File:** `frontend/lib/features/audit_logs/screens/audit_logs_screen.dart`
- **Route Index:** `39`
- **Scope:** Detailed audit trail, entity change history, user action timestamps, diff viewer.
- **Status:** `Pending`

### Screen 40: Smart Tasks & Reminders
- **File:** `frontend/lib/features/smart_tasks/screens/smart_tasks_screen.dart`
- **Route Index:** `40`
- **Scope:** Automated priority alerts, task assignments, deadline countdowns.
- **Status:** `Pending`

### Screen 41: Dynamic Report Builder
- **File:** `frontend/lib/features/dynamic_reporting/screens/dynamic_report_builder_screen.dart`
- **Route Index:** `41`
- **Scope:** Custom report designer, column selector, filtering criteria, export engine.
- **Status:** `Pending`

### Screen 42: Shipment Updates & Milestones Engine
- **File:** `frontend/lib/features/shipment_updates/screens/shipment_update_engine_screen.dart`
- **Route Index:** `42`
- **Scope:** Phase tracking timeline, event logs, milestone completion metrics.
- **Status:** `Pending`

### Screen 43: Import Requirements & Regulatory Engine
- **File:** `frontend/lib/features/import_requirements/screens/import_requirements_screen.dart`
- **Route Index:** `43`
- **Scope:** Egyptian pre-clearance rules, GOEIC requirements, import licenses.
- **Status:** `Pending`

### Screen 44: Demurrage & Detention Calculator
- **File:** `frontend/lib/features/demurrage_detention/screens/demurrage_detention_screen.dart`
- **Route Index:** `44`
- **Scope:** Free-time calculation, shipping line demurrage tiers, detention risk alerts.
- **Status:** `Pending`

### Screen 45: HS Code Explorer & Duty Calculator
- **File:** `frontend/lib/features/customs_tariff/screens/customs_tariff_screen.dart` (Tab 1)
- **Route Index:** `45`
- **Scope:** Interactive tariff duty & VAT calculation sandbox, CIF computation.
- **Status:** `Pending`

### Screen 46: SWIFT Message Reconciliation
- **File:** `frontend/lib/features/financial_approval/screens/swift_reconciliation_screen.dart`
- **Route Index:** `46`
- **Scope:** MT103 / MT700 parsing, bank transfer confirmation, financial matching.
- **Status:** `Pending`

### Screen 47: Import File Comprehensive Report
- **File:** `frontend/lib/features/comprehensive_report/screens/import_file_comprehensive_report_screen.dart`
- **Route Index:** `47`
- **Scope:** 360-degree shipment dossier, all-phase audit report, cost breakdown summary.
- **Status:** `Pending`

### Screen 48: Lifecycle Operations Board (6 Phases / 21 Steps)
- **File:** `frontend/lib/features/lifecycle_board/screens/lifecycle_board_screen.dart`
- **Route Index:** `48`
- **Scope:** Visual Kanban-style board across all 21 operational steps and 6 import phases.
- **Status:** `Pending`

### Screen 49: Freight Quotations & RFQ Evaluator
- **File:** `frontend/lib/features/freight_quotations/screens/freight_quotations_screen.dart`
- **Route Index:** `49`
- **Scope:** Freight forwarder rate cards comparison, RFQ evaluation, fast carrier awarding.
- **Status:** `Pending`

### Screen 50: Landed Cost Comparison Analysis
- **File:** `frontend/lib/features/financial_settlement/screens/financial_settlement_screen.dart` (SubTab 1)
- **Route Index:** `50`
- **Scope:** Estimated vs Actual landed cost breakdown, variance percentage analysis.
- **Status:** `Pending`

### Screen 51: Central Shipment Documents Archive
- **File:** `frontend/lib/features/import_documentation/screens/central_docs_archive_screen.dart`
- **Route Index:** `51`
- **Scope:** Central file repository, discrepancy flags, document version control.
- **Status:** `Pending`

### Screen 52: Cargo Shipping 48h SLA Tracking
- **File:** `frontend/lib/features/cargo_shipping/screens/cargo_shipping_screen.dart` (SubTab 1)
- **Route Index:** `52`
- **Scope:** Real-time container vessel tracking, transit milestones, SLA alerts.
- **Status:** `Pending`

### Screen 53: Draft Inspection Certificate Review
- **File:** `frontend/lib/features/import_documentation/screens/shipment_draft_docs_screen.dart` (SubTab 5)
- **Route Index:** `53`
- **Scope:** Pre-shipment inspection certificate verification, inspection agency approval.
- **Status:** `Pending`

### Screen 54: CargoX Blockchain & ACI Dispatch Hub
- **File:** `frontend/lib/features/import_documentation/screens/original_docs_and_cargox_screen.dart` (SubTab 1)
- **Route Index:** `54`
- **Scope:** CargoX transfer verification, ACI document hash sealing, blockchain confirmation.
- **Status:** `Pending`

### Screen 55: Customs Clearance Quotations & RFQ Evaluator
- **File:** `frontend/lib/features/customs_consultation/screens/customs_consultation_screen.dart` (SubTab 3)
- **Route Index:** `55`
- **Scope:** Broker rate comparison, quotation evaluation, broker assignment.
- **Status:** `Pending`

### Screen 56: Customs Duty Review & Estimator Workspace
- **File:** `frontend/lib/features/customs_consultation/screens/customs_consultation_screen.dart` (Tax Review Mode)
- **Route Index:** `56`
- **Scope:** High-precision tax liability calculation, itemized tax schedules.
- **Status:** `Pending`

### Screen 57: Originals Collection & Courier Tracking
- **File:** `frontend/lib/features/import_documentation/screens/original_docs_and_cargox_screen.dart` (SubTab 0)
- **Route Index:** `57`
- **Scope:** Physical courier tracking (DHL/FedEx/Aramex), original document receipt log.
- **Status:** `Pending`

### Screen 58: Original Documents & CargoX Hub (Default View)
- **File:** `frontend/lib/features/import_documentation/screens/original_docs_and_cargox_screen.dart`
- **Route Index:** `58`
- **Scope:** Unified original documentation overview and dispatch status.
- **Status:** `Pending`

### Screen 59: Production Sync & Deployment Hub
- **File:** `frontend/lib/features/production_sync/screens/production_sync_screen.dart`
- **Route Index:** `59`
- **Scope:** Master data synchronization, database health diagnostics, production migration check.
- **Status:** `Pending`

### Screen 60: Customs Clearance - Drawing Samples & Shortage
- **File:** `frontend/lib/features/customs_clearance/screens/customs_clearance_screen.dart` (SubTab 1)
- **Route Index:** `60`
- **Scope:** Laboratory sample extraction logs, quantity shortage claims, examination report.
- **Status:** `Pending`

### Screen 61: Customs Clearance - Discrepancy & Damage Records
- **File:** `frontend/lib/features/customs_clearance/screens/customs_clearance_screen.dart` (SubTab 2)
- **Route Index:** `61`
- **Scope:** Physical damage inspection, discrepancy protocols, insurance claim prep.
- **Status:** `Pending`

### Screen 62: Customs Clearance - Final Customs Payment (E-Finance)
- **File:** `frontend/lib/features/customs_clearance/screens/customs_clearance_screen.dart` (SubTab 3)
- **Route Index:** `62`
- **Scope:** E-Finance payment slip matching, customs clearance release order issuance.
- **Status:** `Pending`

### Screen 63: Inbound Warehouse - Goods In Transit (GIT) Ledger
- **File:** `frontend/lib/features/warehouse_receiving/screens/inbound_warehouse_hub_screen.dart` (SubTab 0)
- **Route Index:** `63`
- **Scope:** GIT accounting ledger, in-transit inventory valuation, expected arrival schedule.
- **Status:** `Pending`

### Screen 64: Warehouse Received Shipments Detailed Report
- **File:** `frontend/lib/features/warehouse_receiving/screens/inbound_warehouse_hub_screen.dart` (SubTab 2)
- **Route Index:** `64`
- **Scope:** Warehouse receiving report, inspection logs, item putaway records.
- **Status:** `Pending`

### Screen 65: Cargo & Marine Insurance Certificate Hub
- **File:** `frontend/lib/features/cargo_insurance/screens/cargo_insurance_screen.dart`
- **Route Index:** `65`
- **Scope:** Marine cargo insurance policies, premium calculation, certificate issuance.
- **Status:** `Pending`

### Screen 66: Users Management & RBAC Security (Admin)
- **File:** `frontend/lib/features/auth/screens/users_management_screen.dart`
- **Route Index:** `66`
- **Scope:** User accounts directory, role assignments (Admin / Operational / Customs / Finance), access permissions.
- **Status:** `Pending`

---

## 📊 Review Progress

| # | Screen Name | Route Index | Status | Date Reviewed | Notes |
|---|---|:---:|:---:|:---:|---|
| 0 | Operational Dashboard | 0 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableText added across all metrics, cards, and alerts |
| 1 | Import Files Management | 1 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableTableCell & CopyableText enabled across table and dialogs |
| 2 | Purchase Orders | 2 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableTableCell & CopyableText enabled across table and dialogs |
| 3 | CBM & Cargo Calculator | 3 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableTableCell & CopyableText enabled across tables and dialogs |
| 4 | Shipping Scenarios (Study) | 4 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableTableCell & CopyableText enabled across side-by-side table and dialogs |
| 5 | Shipping Scenarios (Saved Records) | 5 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableTableCell enabled across registry DataTable and details dialog |
| 6 | Customs Studies & Consultations | 6 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableTableCell & CopyableText enabled across tariff tables and dialogs |
| 7 | Customs Consultations Log | 7 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableTableCell enabled across saved consultations table |
| 8 | Financial Approval Requests | 8 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableTableCell enabled across payment requests registry |
| 9 | Financial Approval (LC / CAD) | 9 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableText enabled across budget cards and multi-currency metrics |
| 10 | Financial Approval (Form 4) | 10 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableTableCell enabled across saved budgets and SWIFT reconciliation |
| 11 | Nafeza & ACID Request | 11 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyHelper.copy on dispatches, CopyableText on loaded sessions |
| 12 | Nafeza ACID Expiry Tracker | 12 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableTableCell & CopyableText on countdown metrics and table |
| 13 | Nafeza Compliance Checklist | 13 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableText on requested/generated discrepancy matrix values |
| 14 | Nafeza CargoX Dispatch Hub | 14 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableTableCell on certified ACID numbers registry |
| 15 | Nafeza Declarations & 46 Sync | 15 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableTableCell on release tracker table and status cards |
| 16 | Bank Form 4 Application | 16 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableText on form details and banner codes |
| 17 | Bank Form 4 Document Endorsement | 17 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableTableCell on Bank Form 4 registry |
| 18 | Draft B/L Review | 18 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableTableCell & CopyableText enabled across 5 stages and visual B/L |
| 19 | Draft COO / EUR.1 Review | 19 | Complete | 2026-09-07 | i18n anti-stacking applied; CopyableTableCell & CopyableText enabled across tables and visual COO |
| 20 | Draft Docs Customs Approval | 20 | Complete | 2026-09-07 | i18n anti-stacking applied; SelectionArea, CopyableText enabled across dual approval and tickets |
| 21 | PO & Packing List Reconciliation | 21 | Complete | 2026-09-07 | i18n anti-stacking applied; SelectionArea, CopyableTableCell enabled across line items and history |
| 22 | Invoice vs B/L Smart Match | 22 | Complete | 2026-09-07 | i18n anti-stacking applied; SelectionArea, CopyableTableCell & CopyableText enabled across matcher tab and extractor dialog |
| 23 | Customs Declaration 46 Entry | 23 | Complete | 2026-09-07 | i18n anti-stacking applied; SelectionArea, copy icons on all 9 inputs, CopyableTableCell & TSV export enabled |
| 24 | Declaration 46 Tariff Valuation | 24 | Complete | 2026-09-07 | i18n anti-stacking applied; SubTab 1 KPI cards, CopyableTableCell with TSV rowSummary, Tariff Assessment Dialog with copy & TSV export enabled |
| 25 | Freight Booking Operations | 25 | Complete | 2026-09-07 | i18n anti-stacking applied; DataCell(CopyableTableCell) on cells 4-12, SelectionArea, Print manifest copy |
| 26 | Cargo Shipping Allocations (VGM) | 26 | Complete | 2026-09-08 | i18n anti-stacking applied; SelectionArea, CopyableText on Equipment cards, TSV manifest export |
| 27 | Customs Clearance Execution Hub | 27 | Complete | 2026-09-08 | i18n anti-stacking applied; SelectionArea, CopyableTableCell across 3 tables, CopyableText on cards, 4 TSV exports, UnderBond dialog localized & copy-enabled |
| 28 | Inbound Warehouse Hub (GRN) | 28 | Complete | 2026-09-08 | i18n anti-stacking applied; SelectionArea, CopyableTableCell across GRN cards & audit metrics, TSV export & print receipt copy |
| 29 | Financial Settlement Hub | 29 | Complete | 2026-09-08 | i18n anti-stacking applied; SelectionArea, CopyableTableCell across Expense Invoices & Item Landed Cost tables, TSV exports, Odoo journal dialog copy-enabled |
| 30 | File Closure & Archive | 30 | Complete | 2026-09-08 | i18n anti-stacking applied; SelectionArea, CopyableText across cards & certificates, 2 TSV exports, Reopen & Closure dialogs copy-enabled |
| 31 | Master Data - Projects | 31 | Complete | 2026-09-08 | i18n anti-stacking applied; SelectionArea, CopyableTableCell across table, CopyableText on codes/names, TSV export & project summary copy |
| 32 | Master Data - Importing Companies | 32 | Complete | 2026-09-08 | i18n anti-stacking applied; SelectionArea, copy badges on Importer Card/Tax/Reg, TSV export & single-click summary copy, details dialog localized & copy-enabled |
| 33 | Master Data - Suppliers | 33 | Complete | 2026-09-08 | i18n anti-stacking applied; SelectionArea, copy badges, 18 form copy buttons, TSV export, summary copy; details, route, and GOEIC dialogs copy-enabled |
| 34 | Master Data - Partners & Providers | 34 | Complete | 2026-09-08 | i18n anti-stacking applied; SelectionArea, copy badges on code/name, 17 form copy buttons, TSV export, summary copy; details, scorecard, SOA dialogs copy-enabled |
| 35 | Reference - Incoterms 2020 | 35 | Pending | — | Queued |
| 36 | Reference - Customs Tariff Schedule | 36 | Pending | — | Queued |
| 37 | Reference - Transport Locations | 37 | Pending | — | Queued |
| 38 | Reference - Currencies & Rates | 38 | Pending | — | Queued |
| 39 | System Audit Logs & History | 39 | Pending | — | Queued |
| 40 | Smart Tasks & Priority Reminders | 40 | Pending | — | Queued |
| 41 | Dynamic Report Builder | 41 | Pending | — | Queued |
| 42 | Shipment Updates & Milestones | 42 | Pending | — | Queued |
| 43 | Import Requirements & Regulations | 43 | Pending | — | Queued |
| 44 | Demurrage & Detention Calculator | 44 | Pending | — | Queued |
| 45 | HS Code Explorer & Duty Sandbox | 45 | Pending | — | Queued |
| 46 | SWIFT Message Reconciliation | 46 | Pending | — | Queued |
| 47 | Import File Comprehensive Report | 47 | Pending | — | Queued |
| 48 | Lifecycle Operations Board | 48 | Pending | — | Queued |
| 49 | Freight Quotations & RFQ | 49 | Pending | — | Queued |
| 50 | Landed Cost Comparison Analysis | 50 | Pending | — | Queued |
| 51 | Central Shipment Docs Archive | 51 | Pending | — | Queued |
| 52 | Cargo Shipping 48h SLA Tracking | 52 | Pending | — | Queued |
| 53 | Draft Inspection Certificate Review | 53 | Pending | — | Queued |
| 54 | CargoX Blockchain Dispatch Hub | 54 | Pending | — | Queued |
| 55 | Customs Clearance Quotations Evaluator | 55 | Pending | — | Queued |
| 56 | Customs Duty Review Workspace | 56 | Pending | — | Queued |
| 57 | Originals Collection & Courier Tracking | 57 | Pending | — | Queued |
| 58 | Original Docs & CargoX Hub | 58 | Pending | — | Queued |
| 59 | Production Sync & Deployment Hub | 59 | Pending | — | Queued |
| 60 | Clearance - Samples & Shortage | 60 | Pending | — | Queued |
| 61 | Clearance - Discrepancy & Damage | 61 | Pending | — | Queued |
| 62 | Clearance - Final Customs Payment | 62 | Pending | — | Queued |
| 63 | Inbound Hub - GIT Ledger | 63 | Pending | — | Queued |
| 64 | Warehouse Received Detailed Report | 64 | Pending | — | Queued |
| 65 | Cargo & Marine Insurance Hub | 65 | Pending | — | Queued |
| 66 | Users Management & RBAC | 66 | Pending | — | Queued |
