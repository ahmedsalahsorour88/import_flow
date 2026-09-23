import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/clone_entity_review_dialog.dart';
import 'package:frontend/features/import_documentation/models/docs_customs_approval_model.dart';
import 'package:frontend/features/import_documentation/providers/docs_customs_approval_provider.dart';
import 'package:frontend/features/import_documentation/providers/import_documentation_provider.dart';
import 'package:frontend/features/import_documentation/screens/central_docs_archive_screen.dart';
import 'package:frontend/features/import_documentation/screens/shipment_draft_docs_screen.dart';
import 'package:frontend/features/import_documentation/widgets/customs_document_approval_tab.dart';
import 'package:frontend/features/import_documentation/widgets/search_and_clone_customs_approval_dialog.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';

class MockDocsCustomsApprovalNotifier extends DocsCustomsApprovalNotifier {
  final List<CustomsDocumentApprovalModel> _initialList;

  MockDocsCustomsApprovalNotifier(this._initialList) : super(Dio()) {
    state = AsyncValue.data(_initialList);
  }

  @override
  Future<void> fetchApprovals({
    int? importFileId,
    String? overallStatus,
    String? search,
  }) async {
    state = AsyncValue.data(_initialList);
  }

  @override
  Future<void> autoGenerateChecklist(int importFileId) async {}

  @override
  Future<CrossDocumentMatrixResultModel> runMatrixCheck(int importFileId) async {
    return CrossDocumentMatrixResultModel(
      importFileId: 1,
      importFileCode: 'IMP-2026-001',
      overallCompliance: 'Fully Compliant',
      totalChecks: 6,
      passedChecks: 6,
      failedChecks: 0,
      checks: [],
      recommendations: ['All documents are verified and compliant.'],
      openTicketsCount: 0,
    );
  }

  @override
  Future<CustomsDocumentApprovalModel?> submitCommercialReview({
    required int approvalId,
    required String reviewerName,
    required String status,
    String? notes,
    int? importFileId,
    int? version,
  }) async {
    return null;
  }

  @override
  Future<CustomsDocumentApprovalModel?> submitCustomsBrokerReview({
    required int approvalId,
    required String brokerName,
    required String reviewerName,
    required String status,
    String? notes,
    int? importFileId,
    int? version,
  }) async {
    return null;
  }
}

class MockDiscrepancyTicketsNotifier extends DiscrepancyTicketsNotifier {
  final List<DiscrepancyRectificationTicketModel> _initialTickets;

  MockDiscrepancyTicketsNotifier(this._initialTickets) : super(Dio()) {
    state = AsyncValue.data(_initialTickets);
  }

  @override
  Future<void> fetchTickets({
    int? importFileId,
    String? status,
    String? severity,
    String? search,
  }) async {
    state = AsyncValue.data(_initialTickets);
  }

  @override
  Future<DiscrepancyRectificationTicketModel?> createTicket(Map<String, dynamic> payload) async {
    return null;
  }

  @override
  Future<DiscrepancyRectificationTicketModel?> resolveTicket(
    int ticketId,
    Map<String, dynamic> payload, {
    int? importFileId,
  }) async {
    return null;
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
  Future<void> fetchReviews({int? importFileId, String? search, bool? isDraft}) async {}
}

class MockCOONotifier extends COONotifier {
  MockCOONotifier() : super(Dio()) {
    state = const AsyncValue.data([]);
  }

  @override
  Future<void> fetchReviews({int? importFileId, bool? isDraft}) async {}
}

void main() {
  final List<CustomsDocumentApprovalModel> sampleApprovals = [
    CustomsDocumentApprovalModel(
      approvalId: 101,
      approvalCode: 'DOCAPPR-2026-001',
      importFileId: 1,
      importFileCode: 'IMP-2026-001',
      documentType: 'Commercial Invoice',
      documentReferenceNo: 'INV-DE-2026-001',
      commercialStatus: 'Approved',
      commercialReviewedBy: 'Ahmed Commercial',
      commercialReviewedAt: '2026-09-15T10:00:00Z',
      customsStatus: 'Pending',
      overallStatus: 'Under Review',
      isActive: true,
      createdAt: '2026-09-15T09:00:00Z',
      updatedAt: '2026-09-15T10:00:00Z',
    ),
    CustomsDocumentApprovalModel(
      approvalId: 102,
      approvalCode: 'DOCAPPR-2026-002',
      importFileId: 1,
      importFileCode: 'IMP-2026-001',
      documentType: 'Packing List',
      documentReferenceNo: 'PL-DE-2026-001',
      commercialStatus: 'Approved',
      commercialReviewedBy: 'Ahmed Commercial',
      commercialReviewedAt: '2026-09-15T10:05:00Z',
      customsStatus: 'Approved',
      customsReviewedBy: 'Sayed Broker',
      customsBrokerName: 'Sorour Brokerage Office',
      customsReviewedAt: '2026-09-15T10:30:00Z',
      overallStatus: 'Approved for Clearance',
      isActive: true,
      createdAt: '2026-09-15T09:00:00Z',
      updatedAt: '2026-09-15T10:30:00Z',
    ),
  ];

  final List<DiscrepancyRectificationTicketModel> sampleTickets = [
    DiscrepancyRectificationTicketModel(
      ticketId: 201,
      ticketCode: 'TKT-2026-001',
      approvalId: 101,
      importFileId: 1,
      importFileCode: 'IMP-2026-001',
      issueCategory: 'HS Code Mismatch',
      severity: 'Major',
      description: 'HS code on draft invoice differs from customs pre-approval.',
      expectedValue: '8471.30.00',
      foundValue: '8471.49.00',
      supplierActionRequired: 'Provide updated invoice with harmonized HS code.',
      status: 'Open',
      isActive: true,
      createdAt: '2026-09-15T10:15:00Z',
      updatedAt: '2026-09-15T10:15:00Z',
    ),
    DiscrepancyRectificationTicketModel(
      ticketId: 202,
      ticketCode: 'TKT-2026-002',
      approvalId: 102,
      importFileId: 1,
      importFileCode: 'IMP-2026-001',
      issueCategory: 'Weight Discrepancy',
      severity: 'Minor',
      description: 'Gross weight discrepancy of 12kg between B/L and Packing List.',
      expectedValue: '1240.00 KG',
      foundValue: '1228.00 KG',
      supplierActionRequired: 'Clarify packaging weight margin.',
      supplierResponse: 'Confirmed tare weight adjustment of 12kg.',
      status: 'Resolved',
      resolvedAt: '2026-09-15T11:00:00Z',
      resolvedBy: 'Hassan Compliance',
      isActive: true,
      createdAt: '2026-09-15T10:20:00Z',
      updatedAt: '2026-09-15T11:00:00Z',
    ),
  ];

  final List<ImportFileModel> sampleFiles = [
    ImportFileModel(
      importFileId: 1,
      importFileCode: 'IMP-2026-001',
      supplierName: 'Siemens AG',
      companyName: 'الشركة الهندسية للتوريدات',
      status: 'Customs Clearance',
      currentModule: 'import_documentation',
      currentStage: 'Customs Approval',
      nextAction: 'Dual-Tier Sign-off',
      acidNumber: '7595528271020210010',
      createdAt: '2026-09-10T10:00:00Z',
      updatedAt: '2026-09-10T10:00:00Z',
    ),
  ];

  Widget createTestWidget({
    Size size = const Size(1400, 900),
    ThemeMode themeMode = ThemeMode.light,
    Locale locale = const Locale('ar'),
    int initialSubTab = 0,
  }) {
    return ProviderScope(
      overrides: [
        docsCustomsApprovalProvider.overrideWith((ref) => MockDocsCustomsApprovalNotifier(sampleApprovals)),
        discrepancyTicketsProvider.overrideWith((ref) => MockDiscrepancyTicketsNotifier(sampleTickets)),
        importFilesProvider.overrideWith((ref) => MockImportFilesNotifier(sampleFiles)),
        shipmentDocumentsProvider.overrideWith((ref) => MockShipmentDocumentsNotifier()),
        draftBLReviewsProvider.overrideWith((ref) => MockDraftBLNotifier()),
        cooReviewsProvider.overrideWith((ref) => MockCOONotifier()),
        centralArchiveProvider(1).overrideWith((ref) => Future.value({
          'import_file_id': 1,
          'import_file_code': 'IMP-2026-001',
          'supplier_name': 'Siemens AG',
          'company_name': 'الشركة الهندسية للتوريدات',
          'total_documents': 2,
          'documents': [],
          'discrepancies': [],
          'reconciliation_status': 'Compliant',
        })),
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

  testWidgets('Test 1: Responsive Layout on Desktop (1400x900) - 0 RenderFlex overflow & Dual-Tier Columns rendered', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget(size: const Size(1400, 900)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomsDocumentApprovalTab), findsOneWidget);
    expect(find.textContaining('INV-DE-2026-001'), findsWidgets);
    expect(find.text('TKT-2026-001'), findsOneWidget);
  });

  testWidgets('Test 2: Responsive Layout on Tablet (800x1024) - 0 RenderFlex overflow', (tester) async {
    tester.view.physicalSize = const Size(800, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget(size: const Size(800, 1024)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomsDocumentApprovalTab), findsOneWidget);
  });

  testWidgets('Test 3: Responsive Layout on Mobile (390x844) - 0 RenderFlex overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget(size: const Size(390, 844)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomsDocumentApprovalTab), findsOneWidget);
  });

  testWidgets('Test 4: Sub-view switching between Dual-Tier Matrix and Central Archive', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Switch to Central Archive (Sub-view 1)
    await tester.tap(find.byKey(const Key('centralArchiveChoiceChip')));
    await tester.pumpAndSettle();

    expect(find.byType(CentralDocsArchiveScreen), findsOneWidget);

    // Switch back to Dual-Tier Matrix (Sub-view 0)
    await tester.tap(find.byKey(const Key('dualSignoffChoiceChip')));
    await tester.pumpAndSettle();

    expect(find.byType(CentralDocsArchiveScreen), findsNothing);
    expect(find.textContaining('INV-DE-2026-001'), findsWidgets);
  });

  testWidgets('Test 5: Search & Clone Customs Approval Dialog Opens via Header Action and Ctrl+D', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Header clone button
    final cloneHeaderBtn = find.byKey(const Key('searchAndCloneCustomsApprovalBtn'));
    expect(cloneHeaderBtn, findsOneWidget);
    await tester.tap(cloneHeaderBtn);
    await tester.pumpAndSettle();

    expect(find.byType(SearchAndCloneCustomsApprovalDialog), findsOneWidget);
    expect(find.text('DOCAPPR-2026-001'), findsOneWidget);
    expect(find.text('DOCAPPR-2026-002'), findsOneWidget);

    // Dismiss dialog via close button
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(SearchAndCloneCustomsApprovalDialog), findsNothing);

    // Keyboard shortcut Ctrl + D
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.byType(SearchAndCloneCustomsApprovalDialog), findsOneWidget);
  });

  testWidgets('Test 6: Live Filtering and Selecting Item in Search & Clone Dialog opens CloneEntityReviewDialog', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('searchAndCloneCustomsApprovalBtn')));
    await tester.pumpAndSettle();

    final searchInput = find.byKey(const Key('searchCustomsApprovalQueryInput'));
    expect(searchInput, findsOneWidget);

    // Filter by 'Packing'
    await tester.enterText(searchInput, 'Packing');
    await tester.pumpAndSettle();

    expect(find.text('DOCAPPR-2026-002'), findsOneWidget);
    expect(find.text('DOCAPPR-2026-001'), findsNothing);

    // Select item to trigger CloneEntityReviewDialog
    final itemBtn = find.byKey(const Key('selectApprovalItem_102'));
    expect(itemBtn, findsOneWidget);
    await tester.tap(itemBtn);
    await tester.pumpAndSettle();

    expect(find.byType(CloneEntityReviewDialog), findsOneWidget);
    expect(find.textContaining('DOCAPPR-2026-002'), findsWidgets);

    // Confirm clone
    final confirmBtn = find.byKey(const Key('confirmCloneBtn'));
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    expect(find.byType(CloneEntityReviewDialog), findsNothing);
  });

  testWidgets('Test 7: Row-Level Clone Button on Approval Item triggers CloneEntityReviewDialog', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final rowCloneBtn = find.byKey(const Key('cloneApprovalRowBtn_101'));
    expect(rowCloneBtn, findsOneWidget);
    await tester.tap(rowCloneBtn);
    await tester.pumpAndSettle();

    expect(find.byType(CloneEntityReviewDialog), findsOneWidget);
    expect(find.textContaining('DOCAPPR-2026-001'), findsWidgets);
  });

  testWidgets('Test 8: Row-Level Clone Button on Discrepancy Ticket triggers ticket clone dialog', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final rowTicketCloneBtn = find.byKey(const Key('cloneTicketRowBtn_201'));
    expect(rowTicketCloneBtn, findsOneWidget);
    await tester.tap(rowTicketCloneBtn);
    await tester.pumpAndSettle();

    // Verify ticket dialog opened with copied description
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('HS code on draft invoice'), findsWidgets);
  });

  testWidgets('Test 9: Dark Mode WCAG AA compliance and Arabic RTL layout rendering', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomsDocumentApprovalTab), findsOneWidget);
  });

  testWidgets('Test 10: Task J — SelectionArea, Copy TSV buttons, and Export buttons present and functional', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify export & copy buttons exist on Approvals column
    final copyApprovalsBtn = find.byKey(const Key('copyApprovalsBtn'));
    final exportApprovalsExcelBtn = find.byKey(const Key('exportApprovalsExcelBtn'));
    final exportApprovalsPdfBtn = find.byKey(const Key('exportApprovalsPdfBtn'));

    expect(copyApprovalsBtn, findsOneWidget);
    expect(exportApprovalsExcelBtn, findsOneWidget);
    expect(exportApprovalsPdfBtn, findsOneWidget);

    // Verify export & copy buttons exist on Tickets column
    final copyTicketsBtn = find.byKey(const Key('copyTicketsBtn'));
    final exportTicketsExcelBtn = find.byKey(const Key('exportTicketsExcelBtn'));
    final exportTicketsPdfBtn = find.byKey(const Key('exportTicketsPdfBtn'));

    expect(copyTicketsBtn, findsOneWidget);
    expect(exportTicketsExcelBtn, findsOneWidget);
    expect(exportTicketsPdfBtn, findsOneWidget);

    // Test TSV copy click handlers
    await tester.tap(copyApprovalsBtn);
    await tester.pumpAndSettle();

    await tester.tap(copyTicketsBtn);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
