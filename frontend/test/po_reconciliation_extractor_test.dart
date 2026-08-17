import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/import_documentation/widgets/po_reconciliation_tab.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/purchase_orders/providers/purchase_orders_provider.dart';

class MockImportFilesNotifier extends StateNotifier<AsyncValue<List<ImportFileModel>>>
    implements ImportFilesNotifier {
  MockImportFilesNotifier()
      : super(
          AsyncValue.data([
            ImportFileModel(
              importFileId: 101,
              importFileCode: 'IMP-2026-00101',
              companyName: 'ECO ASSOCIATES',
              supplierName: 'G.I. INDUSTRIAL HOLDING SPA',
              piNumber: 'V1/ 2562',
              status: 'Draft Documents',
              invoicesData: [],
              packingListsData: [],
              projectIds: [],
              shipmentMode: 'Sea',
              incotermCode: 'EXW',
              priority: 'Normal',
              shipmentCategory: 'Commercial',
              estimatedCost: 37741.0,
              estimatedCostCurrency: 'EUR',
              currentModule: 'Import Documentation',
              currentStage: 'Draft Documents',
              progressPercent: 65.0,
              nextAction: 'Reconcile Final PO',
              isCustomsReleased: false,
              isActive: true,
              createdAt: DateTime.now().toString(),
              updatedAt: DateTime.now().toString(),
            )
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

class MockPurchaseOrdersNotifier extends StateNotifier<PurchaseOrdersState>
    implements PurchaseOrdersNotifier {
  MockPurchaseOrdersNotifier() : super(PurchaseOrdersState());

  @override
  Future<void> fetchPurchaseOrders() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('POReconciliationTab renders smart extraction tool card and loads sample data', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          importFilesProvider.overrideWith((ref) => MockImportFilesNotifier()),
          purchaseOrdersProvider.overrideWith((ref) => MockPurchaseOrdersNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: POReconciliationTab(initialImportFileId: 101),
          ),
        ),
      ),
    );


    await tester.pumpAndSettle();

    // Verify presence of the Smart Extraction & 3-Way Reconciliation Tool Card
    expect(find.textContaining('Smart 3-Way Extractor'), findsOneWidget);
    expect(find.textContaining('الفاتورة التجارية النهائية'), findsWidgets);
    expect(find.textContaining('قائمة التعبئة والأوزان'), findsWidgets);

    // Verify 1-Click Sample Button
    final sampleButton = find.textContaining('تحميل نموذج تجريبي حقيقي (G.I. INDUSTRIAL)');
    expect(sampleButton, findsOneWidget);

    // Tap 1-Click Sample Button
    await tester.tap(sampleButton);
    await tester.pumpAndSettle();

    // Verify sample text is loaded into inputs
    expect(find.textContaining('G.I. INDUSTRIAL HOLDING SPA'), findsWidgets);
    expect(find.textContaining('2001830441013710010'), findsWidgets);
    expect(find.textContaining('RTAXT/K/EC/MS 182'), findsWidgets);
  });
}
