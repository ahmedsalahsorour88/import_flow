import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dio/dio.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';
import 'package:frontend/features/import_documentation/widgets/invoice_bl_matcher_tab.dart';
import 'package:frontend/features/import_documentation/widgets/smart_invoice_bl_extractor_dialog.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';

class MockImportFilesNotifier extends ImportFilesNotifier {
  MockImportFilesNotifier() : super(Dio()) {
    state = AsyncValue.data([
      ImportFileModel(
        importFileId: 101,
        importFileCode: 'IMP-2026-001',
        companyName: 'ARCHI Brands',
        supplierName: 'Shaw Europe Limited',
        piNumber: '35220',
        status: 'Draft Documents',
        invoicesData: const [],
        packingListsData: const [],
        projectIds: const [],
        shipmentMode: 'Sea',
        incotermCode: 'EXW',
        priority: 'Normal',
        shipmentCategory: 'Commercial',
        estimatedCost: 85060.57,
        estimatedCostCurrency: 'USD',
        currentModule: 'Import Documentation',
        currentStage: 'Draft Documents',
        progressPercent: 65.0,
        nextAction: 'Reconcile B/L',
        isCustomsReleased: false,
        isActive: true,
        createdAt: DateTime.now().toString(),
        updatedAt: DateTime.now().toString(),
      ),
    ]);
  }

  @override
  Future<void> fetchImportFiles({
    bool includeInactive = false,
    String? search,
    int? companyId,
    int? supplierId,
    String? status,
    String? owner,
  }) async {}
}

void main() {
  group('Screen 22: Smart Invoice vs B/L Match - Getters Unit Verification', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    test('All Screen 22 Matcher Tab getters return non-empty, localized text', () {
      expect(ar.invoiceBlMatcherTitle, isNotEmpty);
      expect(en.invoiceBlMatcherTitle, isNotEmpty);
      expect(ar.invoiceBlMatcherSubtitle, isNotEmpty);
      expect(en.invoiceBlMatcherSubtitle, isNotEmpty);
      expect(ar.invoiceBlMatcherLinkImportFile, isNotEmpty);
      expect(en.invoiceBlMatcherSelectFileHint, isNotEmpty);
      expect(ar.invoiceBlMatcherAddPackingListButton, isNotEmpty);
      expect(ar.invoiceBlMatcherRemovePackingList, isNotEmpty);
      expect(ar.invoiceBlMatcherInvoiceBoxTitle, isNotEmpty);
      expect(ar.invoiceBlMatcherPackingBoxTitle, isNotEmpty);
      expect(ar.invoiceBlMatcherBlBoxTitle, isNotEmpty);
      expect(ar.invoiceBlMatcherChangeFile, isNotEmpty);
      expect(ar.invoiceBlMatcherUploadFile, isNotEmpty);
      expect(ar.invoiceBlMatcherExecuteMatchButton, isNotEmpty);
      expect(ar.invoiceBlMatcherLoadSampleButton, isNotEmpty);
      expect(ar.invoiceBlMatcherResetButton, isNotEmpty);
      expect(ar.invoiceBlMatcherMatrixTitle, isNotEmpty);
      expect(ar.invoiceBlMatcherColCheckItem, isNotEmpty);
      expect(ar.invoiceBlMatcherColInvoiceValue, isNotEmpty);
      expect(ar.invoiceBlMatcherColBlValue, isNotEmpty);
      expect(ar.invoiceBlMatcherColMatchStatus, isNotEmpty);
      expect(ar.invoiceBlMatcherColActionRequired, isNotEmpty);
      expect(ar.invoiceBlMatcherStatusMatch, isNotEmpty);
      expect(ar.invoiceBlMatcherStatusMinor, isNotEmpty);
      expect(ar.invoiceBlMatcherStatusMismatch, isNotEmpty);
      expect(ar.invoiceBlMatcherExtractedInvoiceTitle, isNotEmpty);
      expect(ar.invoiceBlMatcherExtractedBlTitle, isNotEmpty);
      expect(ar.invoiceBlMatcherCorrectionLetterTitle, isNotEmpty);
      expect(ar.invoiceBlMatcherCopyLetterButton, isNotEmpty);
      expect(ar.invoiceBlMatcherSyncFooterTitle, isNotEmpty);
      expect(ar.invoiceBlMatcherExportReportButton, isNotEmpty);
      expect(ar.invoiceBlMatcherCertifySyncButton, isNotEmpty);
    });

    test('All Screen 22 Smart Extractor Dialog getters return non-empty, localized text', () {
      expect(ar.smartExtractorDialogTitle, isNotEmpty);
      expect(en.smartExtractorDialogTitle, isNotEmpty);
      expect(ar.smartExtractorDialogSubtitle, isNotEmpty);
      expect(en.smartExtractorDialogSubtitle, isNotEmpty);
      expect(ar.smartExtractorTabInvoice, isNotEmpty);
      expect(ar.smartExtractorTabBl, isNotEmpty);
      expect(ar.smartExtractorTabAudit, isNotEmpty);
      expect(ar.smartExtractorInvoiceCardTitle, isNotEmpty);
      expect(ar.smartExtractorInvoiceCardHint, isNotEmpty);
      expect(ar.smartExtractorPickFileButton, isNotEmpty);
      expect(ar.smartExtractorExtractInvoiceButton, isNotEmpty);
      expect(ar.smartExtractorExtractedInvoiceTitle, isNotEmpty);
      expect(ar.smartExtractorFieldInvoiceNo, isNotEmpty);
      expect(ar.smartExtractorFieldInvoiceDate, isNotEmpty);
      expect(ar.smartExtractorFieldAcidNo, isNotEmpty);
      expect(ar.smartExtractorFieldImporterTaxId, isNotEmpty);
      expect(ar.smartExtractorFieldSupplier, isNotEmpty);
      expect(ar.smartExtractorFieldImporter, isNotEmpty);
      expect(ar.smartExtractorFieldIncoterms, isNotEmpty);
      expect(ar.smartExtractorFieldTotalAmount, isNotEmpty);
      expect(ar.smartExtractorFieldTotalGrossWeight, isNotEmpty);
      expect(ar.smartExtractorFieldPorts, isNotEmpty);
      expect(ar.smartExtractorColItemDescription, isNotEmpty);
      expect(ar.smartExtractorColQuantity, isNotEmpty);
      expect(ar.smartExtractorColUnit, isNotEmpty);
      expect(ar.smartExtractorColUnitPrice, isNotEmpty);
      expect(ar.smartExtractorColTotalPrice, isNotEmpty);
      expect(ar.smartExtractorApplySectionTitle, isNotEmpty);
      expect(ar.smartExtractorSelectFileLabel, isNotEmpty);
      expect(ar.smartExtractorSearchFileHint, isNotEmpty);
      expect(ar.smartExtractorApplyInvoiceButton, isNotEmpty);
      expect(ar.smartExtractorBlCardTitle, isNotEmpty);
      expect(ar.smartExtractorBlCardHint, isNotEmpty);
      expect(ar.smartExtractorExtractBlButton, isNotEmpty);
      expect(ar.smartExtractorOceanBlTitle, isNotEmpty);
      expect(ar.smartExtractorAirWaybillTitle, isNotEmpty);
      expect(ar.smartExtractorPaymentPrepaid, isNotEmpty);
      expect(ar.smartExtractorPaymentCollect, isNotEmpty);
      expect(ar.smartExtractorFieldBlNo, isNotEmpty);
      expect(ar.smartExtractorFieldCarrier, isNotEmpty);
      expect(ar.smartExtractorFieldFlightNo, isNotEmpty);
      expect(ar.smartExtractorFieldVesselVoyage, isNotEmpty);
      expect(ar.smartExtractorFieldPol, isNotEmpty);
      expect(ar.smartExtractorFieldPod, isNotEmpty);
      expect(ar.smartExtractorFieldTotalCbm, isNotEmpty);
      expect(ar.smartExtractorFieldPackagesCount, isNotEmpty);
      expect(ar.smartExtractorFieldShipper, isNotEmpty);
      expect(ar.smartExtractorFieldConsignee, isNotEmpty);
      expect(ar.smartExtractorColContainerNo, isNotEmpty);
      expect(ar.smartExtractorColSealNo, isNotEmpty);
      expect(ar.smartExtractorColContainerType, isNotEmpty);
      expect(ar.smartExtractorColGrossWeightKg, isNotEmpty);
      expect(ar.smartExtractorApplyBlSectionTitle, isNotEmpty);
      expect(ar.smartExtractorApplyBlButton, isNotEmpty);
      expect(ar.smartExtractorAuditCardTitle, isNotEmpty);
      expect(ar.smartExtractorAuditCardSubtitle, isNotEmpty);
      expect(ar.smartExtractorRunAuditButton, isNotEmpty);
      expect(ar.smartExtractorAuditMatrixTitle, isNotEmpty);
      expect(ar.smartExtractorColCheckItem, isNotEmpty);
      expect(ar.smartExtractorColInvoiceValue, isNotEmpty);
      expect(ar.smartExtractorColBlValue, isNotEmpty);
      expect(ar.smartExtractorColStatus, isNotEmpty);
      expect(ar.smartExtractorColDetailsGuidance, isNotEmpty);
      expect(ar.smartExtractorNoticeCardTitle, isNotEmpty);
      expect(ar.smartExtractorNoticeCardSubtitle, isNotEmpty);
      expect(ar.smartExtractorCopyEnglishNoticeButton, isNotEmpty);
      expect(ar.smartExtractorCopyArabicNoticeButton, isNotEmpty);
      expect(ar.smartExtractorAuditPass, isNotEmpty);
      expect(ar.smartExtractorAuditWarning, isNotEmpty);
      expect(ar.smartExtractorAuditCritical, isNotEmpty);
      expect(ar.smartExtractorAuditCompliant, isNotEmpty);
      expect(ar.smartExtractorAuditWarningsDetected, isNotEmpty);
      expect(ar.smartExtractorAuditCriticalMismatch, isNotEmpty);
    });

    test('Arabic getters do not contain stacked bilingual slashes or English keywords', () {
      final arabicStrings = [
        ar.invoiceBlMatcherTitle,
        ar.invoiceBlMatcherInvoiceBoxTitle,
        ar.invoiceBlMatcherPackingBoxTitle,
        ar.invoiceBlMatcherBlBoxTitle,
        ar.invoiceBlMatcherExecuteMatchButton,
        ar.invoiceBlMatcherLoadSampleButton,
        ar.smartExtractorTabInvoice,
        ar.smartExtractorTabBl,
        ar.smartExtractorTabAudit,
        ar.smartExtractorInvoiceCardTitle,
        ar.smartExtractorBlCardTitle,
        ar.smartExtractorAuditCardTitle,
      ];

      for (final s in arabicStrings) {
        expect(s.contains(' / '), isFalse, reason: 'Found bilingual slash in: $s');
        expect(s.contains('(Invoice)'), isFalse, reason: 'Found (Invoice) in: $s');
        expect(s.contains('(B/L)'), isFalse, reason: 'Found (B/L) in: $s');
        expect(s.contains('(10-Point Audit)'), isFalse, reason: 'Found (10-Point Audit) in: $s');
      }
    });
  });

  group('Screen 22: Widget Rendering & SelectionArea Verification', () {
    testWidgets('InvoiceBLMatcherTab is wrapped in SelectionArea and renders in Arabic', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            importFilesProvider.overrideWith((ref) => MockImportFilesNotifier()),
          ],
          child: const AppLocalizationsProvider(
            locale: Locale('ar'),
            child: MaterialApp(
              home: Scaffold(
                body: InvoiceBLMatcherTab(selectedImportFileId: 101),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SelectionArea), findsWidgets);
      expect(find.text('أداة الاستخراج الذكي والمطابقة الفورية'), findsOneWidget);
      expect(find.text('تنفيذ الاستخراج الذكي والمطابقة الفورية'), findsOneWidget);
    });

    testWidgets('SmartInvoiceBLExtractorDialog is wrapped in SelectionArea and renders in English', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        const ProviderScope(
          child: AppLocalizationsProvider(
            locale: Locale('en'),
            child: MaterialApp(
              home: Scaffold(
                body: SmartInvoiceBLExtractorDialog(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SelectionArea), findsWidgets);
      expect(find.text('AI Invoice & Bill of Lading Extractor'), findsOneWidget);
      expect(find.text('Commercial Invoice'), findsOneWidget);
      expect(find.text('Bill of Lading'), findsOneWidget);
      expect(find.text('Customs Audit Radar'), findsOneWidget);
    });
  });
}
