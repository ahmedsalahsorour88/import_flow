import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/clone_entity_review_dialog.dart';
import 'package:frontend/features/import_documentation/models/po_reconciliation_session_model.dart';
import 'package:frontend/features/import_documentation/providers/import_documentation_provider.dart';
import 'package:frontend/features/import_documentation/screens/shipment_draft_docs_screen.dart';
import 'package:frontend/features/import_documentation/widgets/po_reconciliation_tab.dart';
import 'package:frontend/features/import_documentation/widgets/search_and_clone_po_reconciliation_dialog.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';
import 'package:frontend/features/purchase_orders/providers/purchase_orders_provider.dart';

class MockPOReconciliationSessionsNotifier extends POReconciliationSessionsNotifier {
  final List<POReconciliationSessionModel> _initialSessions;

  MockPOReconciliationSessionsNotifier(this._initialSessions) : super(Dio()) {
    state = AsyncValue.data(_initialSessions);
  }

  @override
  Future<void> fetchSessions({
    int? importFileId,
    String? overallStatus,
    String? search,
  }) async {
    state = AsyncValue.data(_initialSessions);
  }

  @override
  Future<bool> deleteSession(int sessionId) async {
    return true;
  }
}

class MockImportFilesNotifier extends ImportFilesNotifier {
  MockImportFilesNotifier(List<ImportFileModel> files) : super(Dio()) {
    state = AsyncValue.data(files);
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

class MockShipmentDocumentsNotifier extends ShipmentDocumentsNotifier {
  MockShipmentDocumentsNotifier() : super(Dio()) {
    state = const AsyncValue.data([]);
  }

  @override
  Future<void> fetchShipmentDocuments({int? importFileId}) async {}
}

class MockDraftBLNotifier extends DraftBLNotifier {
  MockDraftBLNotifier() : super(Dio()) {
    state = const AsyncValue.data([]);
  }

  @override
  Future<void> fetchReviews({int? importFileId, String? search}) async {}
}

class MockCOONotifier extends COONotifier {
  MockCOONotifier() : super(Dio()) {
    state = const AsyncValue.data([]);
  }

  @override
  Future<void> fetchReviews({int? importFileId}) async {}
}

class MockPurchaseOrdersNotifier extends PurchaseOrdersNotifier {
  MockPurchaseOrdersNotifier(Ref ref) : super(Dio(), ref);

  @override
  Future<void> fetchPurchaseOrders() async {
    state = state.copyWith(purchaseOrders: const [], isLoading: false);
  }
}

void main() {
  final List<ImportFileModel> sampleImportFiles = [
    ImportFileModel(
      importFileId: 1,
      importFileCode: 'IMP-2026-001',
      supplierName: 'Siemens Germany',
      companyName: 'Al-Sorour Import Co.',
      status: 'Customs Clearance',
      currentModule: 'import_documentation',
      currentStage: 'PO Reconciliation',
      nextAction: '3-Way Audit',
      acidNumber: '7595528271020210010',
      createdAt: '2026-09-01T00:00:00Z',
      updatedAt: '2026-09-01T00:00:00Z',
    ),
  ];

  final sampleSessions = [
    POReconciliationSessionModel(
      sessionId: 1,
      sessionCode: 'REC-2026-001',
      importFileId: 1,
      importFileCode: 'IMP-2026-001',
      importerName: 'Al-Sorour Import Co.',
      finalInvoiceNumber: 'INV-2026-9901',
      finalPackingListNumber: 'PL-2026-9901',
      shipperName: 'Siemens AG',
      acidNumber: 'ACID-99887766',
      totalInvoiceAmount: 45000.0,
      currency: 'USD',
      totalPackages: 120.0,
      totalGrossWeightKg: 4500.0,
      totalNetWeightKg: 4200.0,
      totalCbm: 18.5,
      overallStatus: 'FULLY_MATCHED',
      isSafeForCertification: true,
      criticalDiscrepanciesCount: 0,
      warningDiscrepanciesCount: 0,
      reconciledInvoiceItems: [
        {
          'item_code': 'ITEM-001',
          'description': 'Industrial Controller',
          'initial_quantity': 100.0,
          'final_quantity': 100.0,
          'initial_unit_price': 450.0,
          'final_unit_price': 450.0,
          'unit_price': 450.0,
          'hs_code': '8537.10.00',
        }
      ],
      reconciledPackingItems: [
        {
          'item_code': 'ITEM-001',
          'description': 'Industrial Controller',
          'package_type': 'Wooden Crate',
          'final_packages_count': 120.0,
          'final_gross_weight_kg': 4500.0,
          'final_net_weight_kg': 4200.0,
          'final_cbm': 18.5,
        }
      ],
      createdAt: '2026-09-15T12:00:00Z',
      updatedAt: '2026-09-15T12:30:00Z',
    ),
    POReconciliationSessionModel(
      sessionId: 2,
      sessionCode: 'REC-2026-002',
      importFileId: 1,
      importFileCode: 'IMP-2026-001',
      importerName: 'Al-Sorour Import Co.',
      finalInvoiceNumber: 'INV-2026-9902',
      finalPackingListNumber: 'PL-2026-9902',
      shipperName: 'Schneider Electric',
      acidNumber: 'ACID-11223344',
      totalInvoiceAmount: 28000.0,
      currency: 'EUR',
      totalPackages: 80.0,
      totalGrossWeightKg: 2100.0,
      totalNetWeightKg: 1950.0,
      totalCbm: 9.2,
      overallStatus: 'ACCEPTED_WITH_WARNINGS',
      isSafeForCertification: true,
      criticalDiscrepanciesCount: 0,
      warningDiscrepanciesCount: 1,
      createdAt: '2026-09-14T09:00:00Z',
      updatedAt: '2026-09-14T10:00:00Z',
    ),
  ];

  Widget createTestWidget({
    Size size = const Size(1400, 900),
    ThemeMode themeMode = ThemeMode.light,
    Locale locale = const Locale('ar'),
    int initialSubTab = 1,
  }) {
    return ProviderScope(
      overrides: [
        poReconciliationSessionsProvider.overrideWith(
          (ref) => MockPOReconciliationSessionsNotifier(sampleSessions),
        ),
        importFilesProvider.overrideWith(
          (ref) => MockImportFilesNotifier(sampleImportFiles),
        ),
        shipmentDocumentsProvider.overrideWith(
          (ref) => MockShipmentDocumentsNotifier(),
        ),
        draftBLReviewsProvider.overrideWith(
          (ref) => MockDraftBLNotifier(),
        ),
        cooReviewsProvider.overrideWith(
          (ref) => MockCOONotifier(),
        ),
        purchaseOrdersProvider.overrideWith(
          (ref) => MockPurchaseOrdersNotifier(ref),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        locale: locale,
        home: AppLocalizationsProvider(
          locale: locale,
          child: Directionality(
            textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: MediaQuery(
              data: MediaQueryData(size: size, textScaler: TextScaler.noScaling),
              child: Scaffold(
                body: ShipmentDraftDocsScreen(
                  initialSubTab: initialSubTab,
                  initialImportFileId: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Screen 21: POReconciliationTab Responsive & Certification Tests', () {
    testWidgets('1. Desktop Viewport (1400x900) — Renders with zero RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(size: const Size(1400, 900)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(POReconciliationTab), findsOneWidget);
      expect(find.byType(SelectionArea), findsWidgets);
      expect(find.byKey(const Key('editorSearchAndCloneBtn')), findsOneWidget);
      expect(find.byKey(const Key('searchAndClonePoReconBtn')), findsOneWidget);
    });

    testWidgets('2. Tablet Viewport (800x1024) — Renders with zero RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(size: const Size(800, 1024)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(POReconciliationTab), findsOneWidget);
    });

    testWidgets('3. Mobile Viewport (390x844) — Renders with zero RenderFlex overflow and wraps gracefully', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(size: const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(POReconciliationTab), findsOneWidget);
    });

    testWidgets('4. Responsive Form Controls & KPI Metric Cards render correctly', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Top inputs
      expect(find.byType(TextFormField), findsWidgets);
      // Smart extraction tool card
      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
    });

    testWidgets('5. Screen-Level Clone: opens SearchAndClonePoReconciliationDialog via header button', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final cloneBtn = find.byKey(const Key('searchAndClonePoReconBtn'));
      expect(cloneBtn, findsOneWidget);
      await tester.tap(cloneBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SearchAndClonePoReconciliationDialog), findsOneWidget);
      expect(find.byKey(const Key('searchPoReconField')), findsOneWidget);
    });

    testWidgets('6. Search & Clone Dialog live filtering and opening CloneEntityReviewDialog', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('searchAndClonePoReconBtn')));
      await tester.pumpAndSettle();

      // Live search filter
      await tester.enterText(find.byKey(const Key('searchPoReconField')), 'Siemens');
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(SearchAndClonePoReconciliationDialog),
          matching: find.textContaining('REC-2026-001'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SearchAndClonePoReconciliationDialog),
          matching: find.textContaining('REC-2026-002'),
        ),
        findsNothing,
      );

      // Tap clone card button
      final cloneCardBtn = find.byKey(const Key('cloneSessionCardBtn_1'));
      expect(cloneCardBtn, findsOneWidget);
      await tester.tap(cloneCardBtn);
      await tester.pumpAndSettle();

      expect(find.byType(CloneEntityReviewDialog), findsOneWidget);
      expect(find.textContaining('REC-2026-'), findsWidgets);
    });

    testWidgets('7. Row-Level Clone on Saved Session in History table', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll to history table
      final rowCloneBtn = find.byKey(const Key('cloneSessionRowBtn_1'));
      await tester.scrollUntilVisible(
        rowCloneBtn,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(rowCloneBtn, findsOneWidget);

      await tester.tap(rowCloneBtn);
      await tester.pumpAndSettle();

      expect(find.byType(CloneEntityReviewDialog), findsOneWidget);

      // Confirm clone
      final confirmBtn = find.byKey(const Key('confirmCloneBtn'));
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Should load into editor with copied invoice and packing list numbers
      expect(find.text('INV-2026-9901-COPY'), findsOneWidget);
      expect(find.text('PL-2026-9901-COPY'), findsOneWidget);
    });

    testWidgets('8. Row-Level Clone on Commercial Invoice and Packing List Items', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Load session 1 into editor via row clone button
      final rowCloneBtn = find.byKey(const Key('cloneSessionRowBtn_1'));
      await tester.scrollUntilVisible(
        rowCloneBtn,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(rowCloneBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmCloneBtn')));
      await tester.pumpAndSettle();

      // Invoice item clone button should be visible
      final invoiceItemCloneBtn = find.byKey(const Key('cloneInvoiceItemRowBtn_ITEM-001'));
      await tester.scrollUntilVisible(
        invoiceItemCloneBtn,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(invoiceItemCloneBtn, findsOneWidget);
      await tester.tap(invoiceItemCloneBtn);
      await tester.pumpAndSettle();

      expect(find.text('ITEM-001-COPY'), findsWidgets);

      // Packing item clone button should be visible
      final packingItemCloneBtn = find.byKey(const Key('clonePackingItemRowBtn_ITEM-001'));
      await tester.scrollUntilVisible(
        packingItemCloneBtn,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(packingItemCloneBtn, findsOneWidget);
      await tester.tap(packingItemCloneBtn);
      await tester.pumpAndSettle();

      expect(find.text('ITEM-001-COPY'), findsWidgets);
    });

    testWidgets('9. Dark Mode & RTL Arabic Layout Compliance', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(
        themeMode: ThemeMode.dark,
        locale: const Locale('ar'),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(POReconciliationTab), findsOneWidget);
    });

    testWidgets('10. Task J Retrofit: SelectionArea, Copy TSV buttons, and Export buttons exist', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Invoice table Task J buttons
      expect(find.byKey(const Key('copyInvoiceItemsBtn')), findsOneWidget);
      expect(find.byKey(const Key('exportInvoiceItemsExcelBtn')), findsOneWidget);
      expect(find.byKey(const Key('exportInvoiceItemsPdfBtn')), findsOneWidget);

      // Packing table Task J buttons
      expect(find.byKey(const Key('copyPackingItemsBtn')), findsOneWidget);
      expect(find.byKey(const Key('exportPackingItemsExcelBtn')), findsOneWidget);
      expect(find.byKey(const Key('exportPackingItemsPdfBtn')), findsOneWidget);

      // Scroll to history table
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      // Sessions history Task J buttons
      expect(find.byKey(const Key('copySessionsBtn')), findsOneWidget);
      expect(find.byKey(const Key('exportSessionsExcelBtn')), findsOneWidget);
      expect(find.byKey(const Key('exportSessionsPdfBtn')), findsOneWidget);
    });
  });
}
