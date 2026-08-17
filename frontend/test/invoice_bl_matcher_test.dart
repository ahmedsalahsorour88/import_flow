import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/import_documentation/widgets/invoice_bl_matcher_tab.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';

class MockImportFilesNotifier extends StateNotifier<AsyncValue<List<ImportFileModel>>>
    implements ImportFilesNotifier {
  MockImportFilesNotifier()
      : super(
          AsyncValue.data([
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
          ]),
        );

  @override
  Future<void> fetchImportFiles({
    bool includeInactive = false,
    String? search,
    int? companyId,
    int? supplierId,
    String? status,
    String? owner,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('InvoiceBLMatcherTab renders dual input boxes and loads sample Shaw & MSC data', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          importFilesProvider.overrideWith((ref) => MockImportFilesNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: InvoiceBLMatcherTab(selectedImportFileId: 101),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Sub-headings
    expect(find.textContaining('أداة الاستخراج الذكي والمطابقة الفورية'), findsOneWidget);
    expect(find.textContaining('Commercial Invoice'), findsWidgets);
    expect(find.textContaining('Draft Bill of Lading'), findsWidgets);

    // Verify Action Buttons
    expect(find.text('تنفيذ الاستخراج الذكي والمطابقة الفورية'), findsOneWidget);
    expect(find.text('تحميل نموذج تجريبي حقيقي (Shaw Europe + MSC)'), findsOneWidget);

    // Tap Load Sample Data Button
    await tester.tap(find.text('تحميل نموذج تجريبي حقيقي (Shaw Europe + MSC)'));
    await tester.pumpAndSettle();

    // Verify text fields populated
    expect(find.textContaining('Shaw Europe Limited'), findsWidgets);
    expect(find.textContaining('MEDURE910647'), findsWidgets);
    expect(find.textContaining('BEAU5851356'), findsWidgets);
    expect(find.textContaining('7595528271019210013'), findsWidgets);

    // Test adding Packing List additional document card
    expect(find.text('+ إضافة كشف التعبئة كملف إضافي (Packing List)'), findsOneWidget);
    await tester.tap(find.text('+ إضافة كشف التعبئة كملف إضافي (Packing List)'));
    await tester.pumpAndSettle();

    // Verify Packing List card appears
    expect(find.textContaining('كشف التعبئة النهائي'), findsOneWidget);
    expect(find.byTooltip('إلغاء وإخفاء كشف التعبئة'), findsOneWidget);

    // Test removing Packing List card
    await tester.tap(find.byTooltip('إلغاء وإخفاء كشف التعبئة'));
    await tester.pumpAndSettle();
    expect(find.text('+ إضافة كشف التعبئة كملف إضافي (Packing List)'), findsOneWidget);
  });
}

