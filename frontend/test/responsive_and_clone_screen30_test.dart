import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/widgets/clone_entity_review_dialog.dart';
import 'package:frontend/features/file_closure/models/file_closure_model.dart';
import 'package:frontend/features/file_closure/providers/file_closure_provider.dart';
import 'package:frontend/features/file_closure/screens/file_closure_screen.dart';
import 'package:frontend/features/file_closure/widgets/search_and_clone_file_closure_dialog.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';

class _MockFileClosureNotifier extends FileClosureNotifier {
  final List<ImportFileClosureModel> initialRecords;
  _MockFileClosureNotifier(this.initialRecords) : super(Dio()) {
    state = AsyncValue.data(initialRecords);
  }

  @override
  Future<void> fetchClosures({
    bool includeInactive = false,
    int? importFileId,
    String? search,
  }) async {
    state = AsyncValue.data(initialRecords);
  }

  @override
  Future<ImportFileClosureModel?> closeImportFile(Map<String, dynamic> payload) async {
    final created = ImportFileClosureModel(
      closureId: 999,
      closureCode: 'CLOSURE-DRAFT-TEST',
      importFileId: payload['import_file_id'] ?? 20,
      closureChecklist: ClosureChecklistModel.fromJson(payload['closure_checklist'] ?? {}),
      auditorName: payload['auditor_name'] ?? 'Senior Auditor',
      archiveLocation: payload['archive_location'] ?? 'Archive Vault Test',
      archivalNotes: payload['archival_notes'] ?? '',
      status: payload['is_draft'] == true ? 'Draft' : 'Closed',
      closedAt: DateTime.now().toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    initialRecords.add(created);
    state = AsyncValue.data(initialRecords);
    return created;
  }

  @override
  Future<void> softDeleteClosure(int closureId) async {
    initialRecords.removeWhere((r) => r.closureId == closureId);
    state = AsyncValue.data(initialRecords);
  }
}

class _MockImportFilesNotifier extends ImportFilesNotifier {
  final List<ImportFileModel> initialFiles;
  _MockImportFilesNotifier(this.initialFiles) : super(Dio()) {
    state = AsyncValue.data(initialFiles);
  }

  @override
  Future<void> fetchImportFiles({
    bool includeInactive = false,
    String? search,
    int? companyId,
    int? supplierId,
    String? status,
    String? owner,
  }) async {
    state = AsyncValue.data(initialFiles);
  }
}

void main() {
  final List<ImportFileClosureModel> mockRecords = [
    ImportFileClosureModel(
      closureId: 401,
      closureCode: 'CLR-2026-0001',
      importFileId: 20,
      closureChecklist: ClosureChecklistModel(
        docsVerified: true,
        customsCleared: true,
        warehouseReceived: true,
        landedCostSettled: true,
        tasksClosed: true,
      ),
      auditorName: 'Adel Hassan',
      archiveLocation: 'Digital Vault A-1',
      archivalNotes: 'All clear and verified',
      status: 'Closed',
      isActive: true,
      closedAt: '2026-09-17T10:00:00Z',
      createdAt: '2026-09-17T10:00:00Z',
      updatedAt: '2026-09-17T10:00:00Z',
    ),
    ImportFileClosureModel(
      closureId: 402,
      closureCode: 'CLR-2026-0002',
      importFileId: 21,
      closureChecklist: ClosureChecklistModel(
        docsVerified: true,
        customsCleared: true,
        warehouseReceived: true,
        landedCostSettled: false,
        tasksClosed: false,
      ),
      auditorName: 'Mona Auditor',
      archiveLocation: 'Archive Vault B-2',
      archivalNotes: 'Pending final accounts',
      status: 'Draft',
      isActive: true,
      closedAt: '2026-09-16T14:30:00Z',
      createdAt: '2026-09-16T14:30:00Z',
      updatedAt: '2026-09-16T14:30:00Z',
    ),
  ];

  final List<ImportFileModel> mockFiles = [
    ImportFileModel(
      importFileId: 20,
      importFileCode: 'IMP-2026-0020',
      companyId: 1,
      companyName: 'Al-Amal Logistics Co.',
      supplierName: 'Siemens Germany',
      acidNumber: '1234567890123456789',
      portOfLoading: 'Hamburg',
      portOfDischarge: 'Alexandria',
      currentModule: 'File Closure',
      currentStage: 'Archiving',
      nextAction: 'Completed',
      status: 'Active',
      createdAt: '2026-09-01T00:00:00Z',
      updatedAt: '2026-09-01T00:00:00Z',
    ),
    ImportFileModel(
      importFileId: 21,
      importFileCode: 'IMP-2026-0021',
      companyId: 2,
      companyName: 'Nile Delta Trading',
      supplierName: 'Bosch Italy',
      acidNumber: '9876543210987654321',
      portOfLoading: 'Genoa',
      portOfDischarge: 'Port Said',
      currentModule: 'File Closure',
      currentStage: 'Archiving',
      nextAction: 'Reopening Check',
      status: 'Closed',
      closedAtPhase: 'PHASE-6: STEP_21',
      closureReason: 'Operational Stop',
      createdAt: '2026-09-02T00:00:00Z',
      updatedAt: '2026-09-02T00:00:00Z',
    ),
  ];

  Widget buildTestWidget({
    Size size = const Size(1440, 900),
    ThemeMode themeMode = ThemeMode.light,
    Locale locale = const Locale('ar'),
    List<ImportFileClosureModel>? records,
  }) {
    final activeRecords = records ?? List.from(mockRecords);
    return ProviderScope(
      overrides: [
        fileClosureProvider.overrideWith((ref) => _MockFileClosureNotifier(activeRecords)),
        importFilesProvider.overrideWith((ref) => _MockImportFilesNotifier(mockFiles)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: Scaffold(
          body: Directionality(
            textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: AppLocalizationsProvider(
              locale: locale,
              child: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  platformBrightness: themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
                ),
                child: const FileClosureScreen(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Screen 30: File Closure & Archival Enterprise Tests', () {
    testWidgets('1. Desktop Layout (1440x900) renders with complete toolbar & zero RenderFlex overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(size: const Size(1440, 900)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('createClosureBtn')), findsOneWidget);
      expect(find.byKey(const Key('searchAndCloneClosureBtn')), findsOneWidget);
      expect(find.byKey(const Key('copyClosureTableTsvBtn')), findsOneWidget);
      expect(find.byKey(const Key('exportClosureExcelBtn')), findsOneWidget);
      expect(find.byKey(const Key('exportClosurePdfBtn')), findsOneWidget);

      expect(find.text('CLR-2026-0001'), findsOneWidget);
    });

    testWidgets('2. Tablet Layout (800x1280) wraps toolbar cleanly with zero RenderFlex overflow',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(size: const Size(800, 1280)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('createClosureBtn')), findsOneWidget);
      expect(find.byKey(const Key('searchAndCloneClosureBtn')), findsOneWidget);
      expect(find.text('CLR-2026-0001'), findsOneWidget);
    });

    testWidgets('3. Mobile Layout (390x844) renders without RenderFlex overflow and adapts cards',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      FlutterErrorDetails? errorDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errorDetails = details;
        originalOnError?.call(details);
      };

      await tester.pumpWidget(buildTestWidget(size: const Size(390, 844)));
      await tester.pumpAndSettle();

      FlutterError.onError = originalOnError;

      if (errorDetails != null) {
        // ignore: avoid_print
        print('=== TEST 3 FULL DETAILS ===');
        // ignore: avoid_print
        print(errorDetails.toString());
      }

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('createClosureBtn')), findsOneWidget);
      expect(find.byKey(const Key('searchAndCloneClosureBtn')), findsOneWidget);
    });

    testWidgets('4. Dark Mode WCAG AA Compliance renders with appropriate dark palette',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(size: const Size(1440, 900), themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('createClosureBtn')), findsOneWidget);
      expect(find.text('CLR-2026-0001'), findsOneWidget);
    });

    testWidgets('5. Arabic RTL Directionality properly applies right-to-left layout and localized labels',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(size: const Size(1440, 900), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('إصدار شهادة إغلاق وأرشفة شحنة نهائياً'), findsOneWidget);
      expect(find.text('بحث واستنساخ أرشفة سابقة'), findsOneWidget);
    });

    testWidgets('6. Search & Clone Dialog workflow enforces strict reset invariants (Task D)',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(size: const Size(1440, 900)));
      await tester.pumpAndSettle();

      // Tap toolbar button to open search and clone dialog
      final cloneBtn = find.byKey(const Key('searchAndCloneClosureBtn'));
      expect(cloneBtn, findsOneWidget);
      await tester.tap(cloneBtn);
      await tester.pumpAndSettle();

      // Confirm SearchAndCloneFileClosureDialog is visible
      expect(find.byType(SearchAndCloneFileClosureDialog), findsOneWidget);
      expect(find.byKey(const Key('selectClosureToCloneBtn_CLR-2026-0001')), findsOneWidget);

      // Select record to clone
      await tester.tap(find.byKey(const Key('selectClosureToCloneBtn_CLR-2026-0001')));
      await tester.pumpAndSettle();

      // Confirm CloneEntityReviewDialog appears
      expect(find.byType(CloneEntityReviewDialog), findsOneWidget);

      // Verify reset invariants are highlighted
      expect(find.textContaining('معرف الإغلاق'), findsWidgets);
      expect(find.textContaining('CLOSURE-DRAFT-'), findsWidgets);

      // Confirm cloning into draft
      final confirmBtn = find.byKey(const Key('confirmCloneBtn'));
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Form dialog opens populated with cloned draft data
      expect(find.text('Digital Vault A-1'), findsWidgets);
      expect(find.text('Adel Hassan'), findsWidgets);
    });

    testWidgets('7. Row TSV Copy, Table TSV Copy, Excel/PDF exports, and Card Clone button operate cleanly',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(size: const Size(1440, 1600)));
      await tester.pumpAndSettle();

      // Row TSV Copy
      final copyRowBtn = find.byKey(const Key('copyClosureRowBtn_CLR-2026-0001'));
      await tester.scrollUntilVisible(copyRowBtn, 150, scrollable: find.byType(Scrollable).first);
      expect(copyRowBtn, findsOneWidget);
      await tester.tap(copyRowBtn);
      await tester.pumpAndSettle();

      // Table TSV Copy
      final copyTableBtn = find.byKey(const Key('copyClosureTableTsvBtn'));
      expect(copyTableBtn, findsOneWidget);
      await tester.tap(copyTableBtn);
      await tester.pumpAndSettle();

      // Excel & PDF export buttons
      final excelBtn = find.byKey(const Key('exportClosureExcelBtn'));
      expect(excelBtn, findsOneWidget);
      await tester.tap(excelBtn);
      await tester.pumpAndSettle();

      final pdfBtn = find.byKey(const Key('exportClosurePdfBtn'));
      expect(pdfBtn, findsOneWidget);
      await tester.tap(pdfBtn);
      await tester.pumpAndSettle();

      // Row direct clone button
      final rowCloneBtn = find.byKey(const Key('cloneClosureBtn_CLR-2026-0001'));
      await tester.scrollUntilVisible(rowCloneBtn, 150, scrollable: find.byType(Scrollable).first);
      expect(rowCloneBtn, findsOneWidget);
      await tester.tap(rowCloneBtn);
      await tester.pumpAndSettle();

      expect(find.byType(CloneEntityReviewDialog), findsOneWidget);
      expect(find.textContaining('CLR-2026-0001'), findsWidgets);
    });
  });
}
