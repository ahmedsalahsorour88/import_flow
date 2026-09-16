import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/clone_entity_review_dialog.dart';
import 'package:frontend/features/import_documentation/models/import_documentation_model.dart';
import 'package:frontend/features/import_documentation/providers/import_documentation_provider.dart';
import 'package:frontend/features/import_documentation/screens/shipment_draft_docs_screen.dart';
import 'package:frontend/features/import_documentation/widgets/coo_review_tab.dart';
import 'package:frontend/features/import_documentation/widgets/search_and_clone_coo_dialog.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';

class MockCOONotifier extends COONotifier {
  final List<CertificateOfOriginReviewModel> _initialList;

  MockCOONotifier(this._initialList) : super(Dio()) {
    state = AsyncValue.data(_initialList);
  }

  @override
  Future<void> fetchReviews({int? importFileId}) async {
    state = AsyncValue.data(_initialList);
  }

  @override
  Future<void> fetchCOOReviews({int? importFileId}) async {
    state = AsyncValue.data(_initialList);
  }

  @override
  Future<Map<String, dynamic>> fetchCooDraftTemplate(int importFileId, {String? certType}) async {
    return {
      'certificate_type': certType ?? 'EUR.1',
      'recommended_certificate_type': 'EUR.1',
      'allowed_certificate_types': ['EUR.1', 'Agadir Agreement', 'Standard COO'],
      'is_manual_choice_required': false,
      'recommendation_alert': 'موصى به: شهادة EUR.1 تمنح إعفاء جمركي كامل بنسبة 100%',
      'exemption_notes': 'إعفاء كامل من ضريبة الوارد بموجب اتفاقية الشراكة المصرية الأوروبية',
      'preview_markdown': '# Official Draft Preview',
      'template_data': {
        'certificate_number': 'DRAFT-EUR1-2026-001',
        'box_1_exporter': 'Siemens AG - Munich Germany',
        'box_2_consignee': 'الشركة الهندسية للتوريدات - القاهرة',
        'country_of_origin': 'Germany',
        'box_4_country_of_destination': 'Egypt',
        'box_10_invoice_number_and_date': 'INV-2026-9901',
        'applicable_agreement_name': 'الاتفاقية الأوروبية (Egyptian-EU Association Agreement)',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> compareCOO(int importFileId, String certType, Map<String, dynamic> draftFields) async {
    return {
      'has_discrepancies': false,
      'has_critical_mismatch': false,
      'comparison_matrix': [
        {
          'field': 'exporter_name',
          'field_label_ar': 'اسم المصدر',
          'system_value': 'Siemens AG',
          'draft_value': 'Siemens AG',
          'match_status': 'Matched',
          'severity': 'INFO',
          'details': 'متطابق بالكامل',
        },
        {
          'field': 'importer_name',
          'field_label_ar': 'اسم المستورد',
          'system_value': 'الشركة الهندسية للتوريدات',
          'draft_value': 'الشركة الهندسية للتوريدات',
          'match_status': 'Matched',
          'severity': 'INFO',
          'details': 'متطابق بالكامل',
        },
        {
          'field': 'country_of_origin',
          'field_label_ar': 'بلد المنشأ',
          'system_value': 'Germany',
          'draft_value': 'Germany',
          'match_status': 'Matched',
          'severity': 'INFO',
          'details': 'دولة مؤهلة لاتفاقية EUR.1',
        },
      ],
      'system_snapshot_data': {
        'supplier_name': 'Siemens AG',
        'company_name': 'الشركة الهندسية للتوريدات',
        'country_of_origin': 'Germany',
      },
      'draft_input_data': draftFields,
    };
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

void main() {
  final List<CertificateOfOriginReviewModel> sampleReviews = [
    CertificateOfOriginReviewModel(
      cooReviewId: 401,
      cooReviewCode: 'COOREV-2026-001',
      importFileId: 1,
      certificateType: 'EUR.1',
      certificateNumber: 'DRAFT-EUR1-001',
      rawText: 'Exporter: Siemens AG, Importer: Egyptian Engineering',
      documentFileUrl: null,
      systemSnapshotData: {
        'supplier_name': 'Siemens AG',
        'company_name': 'الشركة الهندسية للتوريدات',
        'country_of_origin': 'Germany',
      },
      draftInputData: {
        'exporter_name': 'Siemens AG Germany',
        'box_1_exporter': 'Siemens AG Germany',
        'importer_name': 'الشركة الهندسية للتوريدات',
        'box_2_consignee': 'الشركة الهندسية للتوريدات',
        'country_of_origin': 'Germany',
        'box_3_country_of_origin': 'Germany',
        'destination_country': 'Egypt',
        'box_4_country_of_destination': 'Egypt',
        'invoice_number': 'INV-2026-9901',
        'box_10_invoice_number_and_date': 'INV-2026-9901',
        'raw_text': 'EUR.1 Movement Certificate Siemens AG',
      },
      comparisonMatrix: [
        {
          'field': 'exporter_name',
          'field_label_ar': 'اسم المصدر',
          'system_value': 'Siemens AG',
          'draft_value': 'Siemens AG Germany',
          'match_status': 'Matched',
          'severity': 'INFO',
          'details': 'متطابق',
        },
      ],
      hasDiscrepancies: false,
      hasCriticalMismatch: false,
      status: 'Verified',
      approvedBy: 'Customs Officer',
      approvedAt: '2026-09-14 10:00:00',
      notes: 'Approved without objections',
      isActive: true,
      createdAt: '2026-09-14 09:30:00',
    ),
    CertificateOfOriginReviewModel(
      cooReviewId: 402,
      cooReviewCode: 'COOREV-2026-002',
      importFileId: 1,
      certificateType: 'China Certificate of Origin (CCPIT)',
      certificateNumber: 'DRAFT-CCPIT-002',
      rawText: 'Exporter: Shanghai Machinery, Importer: Egyptian Engineering',
      documentFileUrl: null,
      systemSnapshotData: {
        'supplier_name': 'Shanghai Machinery Ltd',
        'company_name': 'الشركة الهندسية للتوريدات',
        'country_of_origin': 'China',
      },
      draftInputData: {
        'exporter_name': 'Shanghai Machinery Ltd',
        'importer_name': 'الشركة الهندسية للتوريدات',
        'country_of_origin': 'China',
        'destination_country': 'Egypt',
        'invoice_number': 'INV-CN-8802',
      },
      comparisonMatrix: [],
      hasDiscrepancies: true,
      hasCriticalMismatch: false,
      status: 'Draft',
      approvedBy: null,
      approvedAt: null,
      notes: null,
      isActive: true,
      createdAt: '2026-09-15 08:00:00',
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
      currentStage: 'COO',
      nextAction: 'Review Draft COO',
      acidNumber: '7595528271020210010',
      createdAt: '2026-09-10T10:00:00Z',
      updatedAt: '2026-09-10T10:00:00Z',
    ),
  ];

  Widget createTestWidget({
    Size size = const Size(1400, 900),
    ThemeMode themeMode = ThemeMode.light,
    Locale locale = const Locale('ar'),
    int initialSubTab = 4,
  }) {
    return ProviderScope(
      overrides: [
        cooReviewsProvider.overrideWith((ref) => MockCOONotifier(sampleReviews)),
        importFilesProvider.overrideWith((ref) => MockImportFilesNotifier(sampleFiles)),
        shipmentDocumentsProvider.overrideWith((ref) => MockShipmentDocumentsNotifier()),
        draftBLReviewsProvider.overrideWith((ref) => MockDraftBLNotifier()),
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

  testWidgets('Test 1: Responsive Layout on Desktop (1400x900) - 0 RenderFlex overflow', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget(size: const Size(1400, 900)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(COOReviewTab), findsOneWidget);
    expect(find.textContaining('EUR.1'), findsWidgets);
  });

  testWidgets('Test 2: Responsive Layout on Tablet (800x1024) - 0 RenderFlex overflow', (tester) async {
    tester.view.physicalSize = const Size(800, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget(size: const Size(800, 1024)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(COOReviewTab), findsOneWidget);
  });

  testWidgets('Test 3: Responsive Layout on Mobile (390x844) - 0 RenderFlex overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget(size: const Size(390, 844)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(COOReviewTab), findsOneWidget);
  });

  testWidgets('Test 4: Stage Navigation across all 4 stages (Requirements, Input, Matrix, Registry)', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Step 0: Requirements & Decision Engine
    expect(find.textContaining('اتفاقية'), findsWidgets);

    // Navigate to Step 1 (Smart Input)
    await tester.tap(find.byIcon(Icons.file_upload));
    await tester.pumpAndSettle();
    expect(find.textContaining('DRAFT-'), findsWidgets);

    // Navigate to Step 3 (Registry)
    await tester.ensureVisible(find.byIcon(Icons.history_edu));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.history_edu));
    await tester.pumpAndSettle();
    expect(find.text('COOREV-2026-001'), findsOneWidget);
  });

  testWidgets('Test 5: Search & Clone COO Dialog Opens via Header Action and Displays Previous Reviews', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final cloneHeaderBtn = find.byKey(const Key('searchAndCloneCooBtn'));
    expect(cloneHeaderBtn, findsOneWidget);
    await tester.tap(cloneHeaderBtn);
    await tester.pumpAndSettle();

    expect(find.byType(SearchAndCloneCooDialog), findsOneWidget);
    expect(find.text('COOREV-2026-001'), findsOneWidget);
    expect(find.text('COOREV-2026-002'), findsOneWidget);
  });

  testWidgets('Test 6: Live Filtering in Search & Clone COO Dialog by Certificate Number & Exporter', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('searchAndCloneCooBtn')));
    await tester.pumpAndSettle();

    final searchInput = find.byKey(const Key('searchCooDialogQueryInput'));
    expect(searchInput, findsOneWidget);

    // Filter by Siemens
    await tester.enterText(searchInput, 'Siemens');
    await tester.pumpAndSettle();

    expect(find.text('COOREV-2026-001'), findsOneWidget);
    expect(find.text('COOREV-2026-002'), findsNothing);

    // Filter non-matching
    await tester.enterText(searchInput, 'NonExistentCOO999');
    await tester.pumpAndSettle();
    expect(find.text('COOREV-2026-001'), findsNothing);
    expect(find.text('COOREV-2026-002'), findsNothing);
  });

  testWidgets('Test 7: Keyboard Shortcut Ctrl + D Opens Search and Clone COO Dialog', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.byType(SearchAndCloneCooDialog), findsOneWidget);
  });

  testWidgets('Test 8: Full Clone Execution with Invariants Verification', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('searchAndCloneCooBtn')));
    await tester.pumpAndSettle();

    final itemToSelect = find.byKey(const Key('selectCooItem_401'));
    expect(itemToSelect, findsOneWidget);
    await tester.tap(itemToSelect);
    await tester.pumpAndSettle();

    // Verify CloneEntityReviewDialog opens
    expect(find.byType(CloneEntityReviewDialog), findsOneWidget);
    expect(find.textContaining('COOREV-2026-001'), findsWidgets);

    // Confirm clone
    final confirmBtn = find.byKey(const Key('confirmCloneBtn'));
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // Dialog dismissed
    expect(find.byType(CloneEntityReviewDialog), findsNothing);

    // Switched to Step 1 (Smart Input) with reset cert number
    final certInput = find.byType(TextFormField).first;
    final certController = (tester.widget(certInput) as TextFormField).controller;
    expect(certController?.text, startsWith('DRAFT-EUR1-2026-'));
  });

  testWidgets('Test 9: Row-Level Clone Button in Step 4 Registry triggers CloneEntityReviewDialog', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Navigate to Step 3 (Registry)
    await tester.ensureVisible(find.byIcon(Icons.history_edu));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.history_edu));
    await tester.pumpAndSettle();

    final rowCloneBtn = find.byKey(const Key('cloneCooRowBtn_401'));
    expect(rowCloneBtn, findsOneWidget);
    await tester.tap(rowCloneBtn);
    await tester.pumpAndSettle();

    expect(find.byType(CloneEntityReviewDialog), findsOneWidget);
    expect(find.textContaining('COOREV-2026-001'), findsWidgets);
  });

  testWidgets('Test 10: Step 4 Registry Live Search and Empty State when No Matches Found', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    // Navigate to Step 3 (Registry)
    await tester.ensureVisible(find.byIcon(Icons.history_edu));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.history_edu));
    await tester.pumpAndSettle();

    final registrySearch = find.byKey(const Key('cooRegistrySearchField'));
    expect(registrySearch, findsOneWidget);

    // Search for non-existent item
    await tester.enterText(registrySearch, 'UNKNOWN_COO_CODE_XYZ');
    await tester.pumpAndSettle();

    expect(find.text('COOREV-2026-001'), findsNothing);
    expect(find.text('COOREV-2026-002'), findsNothing);

    // Clear search
    await tester.enterText(registrySearch, '');
    await tester.pumpAndSettle();

    expect(find.text('COOREV-2026-001'), findsOneWidget);
  });
}
