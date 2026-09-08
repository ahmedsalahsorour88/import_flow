import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dio/dio.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/import_documentation/widgets/invoice_bl_matcher_tab.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';

class MockImportFilesNotifier extends ImportFilesNotifier {
  MockImportFilesNotifier()
      : super(Dio()) {
    state = AsyncValue.data([
      ImportFileModel(
        importFileId: 101,
        importFileCode: 'IMP-2026-001',
        companyName: 'ARCHI Brands',
        supplierName: 'Shaw Europe Limited',
        piNumber: '35220',
        status: 'Draft Documents',
        invoicesData: [],
        packingListsData: [],
        projectIds: [],
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
  testWidgets('InvoiceBLMatcherTab renders dual input boxes and loads sample data in Arabic', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));

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

    // Verify Title and Sub-headings in Arabic
    expect(find.textContaining('أداة الاستخراج الذكي والمطابقة الفورية'), findsOneWidget);
    expect(find.textContaining('1. الفاتورة التجارية النهائية'), findsWidgets);
    expect(find.textContaining('3. مسودة بوليصة الشحن'), findsWidgets);

    // Verify Action Buttons
    expect(find.text('تنفيذ الاستخراج الذكي والمطابقة الفورية'), findsOneWidget);
    expect(find.text('تحميل نموذج تجريبي حقيقي'), findsOneWidget);

    // Tap Load Sample Data Button
    await tester.tap(find.text('تحميل نموذج تجريبي حقيقي'));
    await tester.pumpAndSettle();

    // Verify text fields populated
    expect(find.textContaining('Shaw Europe Limited'), findsWidgets);
    expect(find.textContaining('MEDURE910647'), findsWidgets);
    expect(find.textContaining('BEAU5851356'), findsWidgets);
    expect(find.textContaining('7595528271019210013'), findsWidgets);

    // Verify Packing List card is visible and accessible
    expect(find.textContaining('2. كشف التعبئة النهائي'), findsWidgets);
  });

  testWidgets('InvoiceBLMatcherTab renders correctly in English without Arabic text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          importFilesProvider.overrideWith((ref) => MockImportFilesNotifier()),
        ],
        child: const AppLocalizationsProvider(
          locale: Locale('en'),
          child: MaterialApp(
            home: Scaffold(
              body: InvoiceBLMatcherTab(selectedImportFileId: 101),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Sub-headings in English
    expect(find.textContaining('Smart Extraction & Real-Time Reconciliation'), findsOneWidget);
    expect(find.textContaining('1. Final Commercial Invoice'), findsWidgets);
    expect(find.textContaining('3. Draft Bill of Lading'), findsWidgets);
    expect(find.text('Execute Smart Extraction & Match'), findsOneWidget);
  });
}

