import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/active_shipment_context.dart';
import 'package:frontend/core/providers/ai_assistant_provider.dart';
import 'package:frontend/core/widgets/shipment_lifecycle_navigator.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';
import 'package:frontend/features/smart_tasks/models/smart_task_model.dart';
import 'package:frontend/features/smart_tasks/providers/smart_tasks_provider.dart';

void main() {
  ImportFileModel createMockFile({
    required int id,
    required String code,
    required String displayName,
    required String companyName,
    required double progress,
  }) {
    return ImportFileModel(
      importFileId: id,
      importFileCode: code,
      customFileNumber: displayName,
      companyName: companyName,
      supplierName: 'Global Exporter Inc.',
      currentModule: 'Shipping Operations',
      currentStage: 'Phase 4: Freight Booking',
      nextAction: 'Container allocation',
      progressPercent: progress,
      status: 'In Progress',
      createdAt: '2026-08-01T10:00:00',
      updatedAt: '2026-08-27T10:00:00',
    );
  }

  SmartTaskModel createMockTask({
    required int taskId,
    required int importFileId,
    required String title,
    String? phaseName,
    String? dueDate,
    String status = 'Pending',
  }) {
    return SmartTaskModel(
      taskId: taskId,
      taskCode: 'TSK-$taskId',
      title: title,
      taskType: 'System Generated',
      importFileId: importFileId,
      phaseName: phaseName,
      assignedUser: 'Kamal',
      priority: 'Critical',
      reminderType: 'Document',
      dueDate: dueDate,
      status: status,
      isAutoClosed: false,
      isActive: true,
      createdAt: '2026-08-01T10:00:00',
      createdBy: 'System',
    );
  }

  Widget createTestWidget({
    required List<ImportFileModel> files,
    List<SmartTaskModel> tasks = const [],
    ActiveShipmentContext? activeContext,
    String language = 'ar',
    void Function(String)? onSendMessage,
  }) {
    return ProviderScope(
      overrides: [
        importFilesProvider
            .overrideWith((ref) => MockImportFilesNotifier(files)),
        smartTasksProvider
            .overrideWith((ref) => MockSmartTasksNotifier(tasks)),
        aiAssistantProvider.overrideWith((ref) {
          final notifier = AiAssistantNotifier(ref);
          notifier.setLanguage(language);
          if (activeContext != null) {
            notifier.setActiveContext(activeContext);
          }
          return notifier;
        }),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ShipmentLifecycleNavigator(
            onSendMessage: onSendMessage,
          ),
        ),
      ),
    );
  }

  group('ShipmentLifecycleNavigator Widget Tests (Section 2.3 & 2.3.1)', () {
    testWidgets('renders friendly empty state when no shipments exist',
        (tester) async {
      String? sentPrompt;

      await tester.pumpWidget(createTestWidget(
        files: [],
        language: 'ar',
        onSendMessage: (msg) => sentPrompt = msg,
      ));
      await tester.pumpAndSettle();

      expect(find.text('لا توجد شحنات مسجلة حالياً'), findsOneWidget);
      expect(find.text('ابدأ شحنة جديدة'), findsOneWidget);

      await tester.tap(find.text('ابدأ شحنة جديدة'));
      await tester.pumpAndSettle();

      expect(sentPrompt, contains('كيف أبدأ إنشاء شحنة استيراد جديدة'));
    });

    testWidgets(
        'renders progressive disclosure collapsed view with only current step and hidden count toggle (Section 2.3.1)',
        (tester) async {
      final mockFile = createMockFile(
        id: 4,
        code: 'IMP-2026-0004',
        displayName: 'PET Stock',
        companyName: 'SCAS Co.',
        progress: 40.0, // Step 4 is current
      );

      await tester.pumpWidget(createTestWidget(
        files: [mockFile],
        language: 'ar',
      ));
      await tester.pumpAndSettle();

      // Selector shows formatted label
      expect(find.textContaining('PET Stock – SCAS'), findsOneWidget);

      // Completion rate: 40% (4 من 10 خطوات)
      expect(find.textContaining('40%'), findsOneWidget);
      expect(find.textContaining('4 من 10 خطوات'), findsOneWidget);

      // In collapsed view: ONLY current step (4. حجز الشحن) is rendered
      expect(find.textContaining('4. حجز الشحن'), findsOneWidget);
      expect(find.textContaining('حالية'), findsOneWidget);

      // Completed & upcoming steps are hidden behind toggle
      expect(find.textContaining('1. الجدوى والنولون'), findsNothing);
      expect(find.textContaining('5. تخصيص الحاويات'), findsNothing);
      expect(find.textContaining('10. إغلاق والأرشفة'), findsNothing);

      // Toggle button shows count of hidden steps: 10 - 1 = 9
      expect(find.text('عرض كل المراحل (+9)'), findsOneWidget);
    });

    testWidgets(
        'tapping toggle expands to all 10 steps vertically and toggles button to hide other stages (Section 2.3)',
        (tester) async {
      final mockFile = createMockFile(
        id: 4,
        code: 'IMP-2026-0004',
        displayName: 'PET Stock',
        companyName: 'SCAS Co.',
        progress: 40.0,
      );

      await tester.pumpWidget(createTestWidget(
        files: [mockFile],
        language: 'ar',
      ));
      await tester.pumpAndSettle();

      // Tap toggle button to expand
      expect(find.text('عرض كل المراحل (+9)'), findsOneWidget);
      await tester.tap(find.text('عرض كل المراحل (+9)'));
      await tester.pumpAndSettle();

      // Button toggles to "إخفاء باقي المراحل"
      expect(find.text('إخفاء باقي المراحل'), findsOneWidget);

      // All 10 steps are now rendered vertically
      expect(find.textContaining('1. الجدوى والنولون'), findsOneWidget);
      expect(find.textContaining('2. الموافقة المالية'), findsOneWidget);
      expect(find.textContaining('3. المستندات ونافذة'), findsOneWidget);
      expect(find.textContaining('4. حجز الشحن'), findsOneWidget);
      expect(find.textContaining('5. تخصيص الحاويات'), findsOneWidget);
      expect(find.textContaining('10. إغلاق والأرشفة'), findsOneWidget);

      // Tapping toggle again collapses back
      await tester.ensureVisible(find.text('إخفاء باقي المراحل'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إخفاء باقي المراحل'));
      await tester.pumpAndSettle();

      expect(find.text('عرض كل المراحل (+9)'), findsOneWidget);
      expect(find.textContaining('1. الجدوى والنولون'), findsNothing);
    });

    testWidgets(
        'tapping a stage step in expanded list sets active context and displays quick actions',
        (tester) async {
      final mockFile = createMockFile(
        id: 4,
        code: 'IMP-2026-0004',
        displayName: 'PET Stock',
        companyName: 'SCAS',
        progress: 40.0,
      );

      String? sentAction;

      await tester.pumpWidget(createTestWidget(
        files: [mockFile],
        language: 'ar',
        onSendMessage: (msg) => sentAction = msg,
      ));
      await tester.pumpAndSettle();

      // Expand to show step 5
      await tester.tap(find.text('عرض كل المراحل (+9)'));
      await tester.pumpAndSettle();

      // Tap on step 5: "5. تخصيص الحاويات"
      await tester.ensureVisible(find.textContaining('تخصيص الحاويات'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('تخصيص الحاويات'));
      await tester.pumpAndSettle();

      // Quick actions row appears
      expect(find.textContaining('إجراءات مرحلة: تخصيص الحاويات'), findsOneWidget);
      expect(find.text('عرض البيانات'), findsOneWidget);
      expect(find.text('تحديث'), findsOneWidget);
      expect(find.text('اسأل'), findsOneWidget);

      // Tap "عرض البيانات"
      await tester.ensureVisible(find.text('عرض البيانات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('عرض البيانات'));
      await tester.pumpAndSettle();

      expect(sentAction, contains('اعرض بيانات وموقف مرحلة'));
      expect(sentAction, contains('تخصيص الحاويات'));
    });

    testWidgets(
        'surfaces overdue step anywhere in the list alongside current step in collapsed view (Section 2.3.1)',
        (tester) async {
      final mockFile = createMockFile(
        id: 4,
        code: 'IMP-2026-0004',
        displayName: 'PET Stock',
        companyName: 'SCAS Co.',
        progress: 40.0, // Current step is 4
      );

      // Step 3 (ACID) has an overdue task
      final overdueTask = createMockTask(
        taskId: 101,
        importFileId: 4,
        title: 'تجديد رقم ACID من نافذة قبل الشحن',
        phaseName: 'Phase 3: Documents & ACID',
        dueDate: '2026-08-01', // definitely overdue compared to current date
      );

      await tester.pumpWidget(createTestWidget(
        files: [mockFile],
        tasks: [overdueTask],
        language: 'ar',
      ));
      await tester.pumpAndSettle();

      // BOTH current step (4) AND overdue step (3) surface in collapsed view!
      expect(find.textContaining('4. حجز الشحن'), findsOneWidget);
      expect(find.textContaining('3. المستندات ونافذة'), findsOneWidget);
      expect(find.textContaining('متأخرة'), findsOneWidget);

      // Hidden count is 10 - 2 = 8
      expect(find.text('عرض كل المراحل (+8)'), findsOneWidget);
    });

    testWidgets(
        'displays 100% completed banner when all stages are completed',
        (tester) async {
      final completedFile = createMockFile(
        id: 1,
        code: 'IMP-2026-0001',
        displayName: 'Solar Panels',
        companyName: 'Eco Solar',
        progress: 100.0,
      );

      await tester.pumpWidget(createTestWidget(
        files: [completedFile],
        language: 'ar',
      ));
      await tester.pumpAndSettle();

      expect(
          find.textContaining('اكتملت جميع مراحل الشحنة بنجاح (100%)'),
          findsOneWidget);
    });

    testWidgets(
        'bilingual English rendering displays English labels, badges, and toggle button',
        (tester) async {
      final mockFile = createMockFile(
        id: 4,
        code: 'IMP-2026-0004',
        displayName: 'PET Stock',
        companyName: 'SCAS',
        progress: 50.0, // Step 5 is current
      );

      await tester.pumpWidget(createTestWidget(
        files: [mockFile],
        language: 'en',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Lifecycle:'), findsOneWidget);
      expect(find.textContaining('Completion Rate:'), findsOneWidget);
      expect(find.textContaining('5. Container Allocation'), findsOneWidget);
      expect(find.textContaining('Active'), findsOneWidget);
      expect(find.text('Show all stages (+9)'), findsOneWidget);

      // Expand
      await tester.tap(find.text('Show all stages (+9)'));
      await tester.pumpAndSettle();

      expect(find.text('Hide other stages'), findsOneWidget);
      expect(find.textContaining('1. Feasibility & Freight'), findsOneWidget);
      expect(find.textContaining('Completed'), findsWidgets);
    });

    testWidgets(
        'falls back to single next actionable step if zero current/overdue steps exist (Section 2.3.1)',
        (tester) async {
      final newFile = createMockFile(
        id: 99,
        code: 'IMP-2026-0099',
        displayName: 'New Shipment',
        companyName: 'Raw Materials Ltd',
        progress: 0.0, // 0% progress -> Step 1 is next actionable step
      );

      await tester.pumpWidget(createTestWidget(
        files: [newFile],
        language: 'ar',
      ));
      await tester.pumpAndSettle();

      // Renders step 1 as fallback actionable step
      expect(find.textContaining('1. الجدوى والنولون'), findsOneWidget);
      expect(find.text('عرض كل المراحل (+9)'), findsOneWidget);
    });

    testWidgets(
        'switching shipments resets expanded toggle back to collapsed state (Section 2.3.1)',
        (tester) async {
      final file1 = createMockFile(
        id: 1,
        code: 'IMP-2026-0001',
        displayName: 'Shipment 1',
        companyName: 'Alpha Corp',
        progress: 30.0,
      );
      final file2 = createMockFile(
        id: 2,
        code: 'IMP-2026-0002',
        displayName: 'Shipment 2',
        companyName: 'Beta Corp',
        progress: 60.0,
      );

      await tester.pumpWidget(createTestWidget(
        files: [file1, file2],
        language: 'ar',
      ));
      await tester.pumpAndSettle();

      // Expand file 1
      await tester.tap(find.text('عرض كل المراحل (+9)'));
      await tester.pumpAndSettle();
      expect(find.text('إخفاء باقي المراحل'), findsOneWidget);

      // Switch to file 2
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Shipment 2').last);
      await tester.pumpAndSettle();

      // Verify it reset back to collapsed state for file 2
      expect(find.text('عرض كل المراحل (+9)'), findsOneWidget);
      expect(find.textContaining('6. إقرار 46 جمرك'), findsOneWidget);
      expect(find.textContaining('1. الجدوى والنولون'), findsNothing);
    });
  });
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

class MockSmartTasksNotifier extends SmartTasksNotifier {
  MockSmartTasksNotifier([List<SmartTaskModel>? tasks]) : super(Dio()) {
    state = SmartTasksState(tasks: tasks ?? []);
  }

  @override
  Future<void> fetchTasks({
    String? taskType,
    String? status,
    String? priority,
    int? importFileId,
    String? search,
  }) async {}
}
