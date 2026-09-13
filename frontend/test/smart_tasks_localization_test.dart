import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';
import 'package:frontend/core/localization/locale_provider.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';
import 'package:frontend/features/smart_tasks/models/smart_task_model.dart';
import 'package:frontend/features/smart_tasks/providers/smart_tasks_provider.dart';
import 'package:frontend/features/smart_tasks/screens/smart_tasks_screen.dart';

class MockSmartTasksNotifier extends SmartTasksNotifier {
  MockSmartTasksNotifier(List<SmartTaskModel> tasks) : super(Dio()) {
    state = SmartTasksState(tasks: tasks, isLoading: false);
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

/// Prevents network calls during widget tests.
/// SmartTasksScreen reads importFilesProvider (for DisplayNameResolver) in initState.
class MockImportFilesNotifier extends ImportFilesNotifier {
  MockImportFilesNotifier() : super(Dio()) {
    state = const AsyncData(<ImportFileModel>[]);
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
  group('Screen: Smart Tasks & Reminder Engine Localization Tests', () {
    late AppLocalizations ar;
    late AppLocalizations en;

    setUp(() {
      ar = const AppLocalizationsAr();
      en = const AppLocalizationsEn();
    });

    test('All Smart Tasks getters return non-empty strings in Arabic and English', () {
      // Screen titles and actions
      expect(ar.smartTasksTitle, isNotEmpty);
      expect(en.smartTasksTitle, isNotEmpty);
      expect(ar.smartTasksNewTaskBtn, isNotEmpty);
      expect(en.smartTasksNewTaskBtn, isNotEmpty);

      // Filters
      expect(ar.smartTasksFilterType, isNotEmpty);
      expect(en.smartTasksFilterType, isNotEmpty);
      expect(ar.smartTasksTypeAll, isNotEmpty);
      expect(en.smartTasksTypeAll, isNotEmpty);
      expect(ar.smartTasksTypeSystem, isNotEmpty);
      expect(en.smartTasksTypeSystem, isNotEmpty);
      expect(ar.smartTasksTypeManual, isNotEmpty);
      expect(en.smartTasksTypeManual, isNotEmpty);

      expect(ar.smartTasksFilterPriority, isNotEmpty);
      expect(en.smartTasksFilterPriority, isNotEmpty);
      expect(ar.smartTasksPriorityAll, isNotEmpty);
      expect(en.smartTasksPriorityAll, isNotEmpty);
      expect(ar.smartTasksPriorityLow, isNotEmpty);
      expect(en.smartTasksPriorityLow, isNotEmpty);
      expect(ar.smartTasksPriorityMedium, isNotEmpty);
      expect(en.smartTasksPriorityMedium, isNotEmpty);
      expect(ar.smartTasksPriorityHigh, isNotEmpty);
      expect(en.smartTasksPriorityHigh, isNotEmpty);
      expect(ar.smartTasksPriorityCritical, isNotEmpty);
      expect(en.smartTasksPriorityCritical, isNotEmpty);

      expect(ar.smartTasksFilterStatus, isNotEmpty);
      expect(en.smartTasksFilterStatus, isNotEmpty);
      expect(ar.smartTasksStatusAll, isNotEmpty);
      expect(en.smartTasksStatusAll, isNotEmpty);
      expect(ar.smartTasksStatusPending, isNotEmpty);
      expect(en.smartTasksStatusPending, isNotEmpty);
      expect(ar.smartTasksStatusInProgress, isNotEmpty);
      expect(en.smartTasksStatusInProgress, isNotEmpty);
      expect(ar.smartTasksStatusCompleted, isNotEmpty);
      expect(en.smartTasksStatusCompleted, isNotEmpty);
      expect(ar.smartTasksStatusCancelled, isNotEmpty);
      expect(en.smartTasksStatusCancelled, isNotEmpty);

      expect(ar.smartTasksResetFiltersTooltip, isNotEmpty);
      expect(en.smartTasksResetFiltersTooltip, isNotEmpty);
      expect(ar.smartTasksTableTitle, isNotEmpty);
      expect(en.smartTasksTableTitle, isNotEmpty);

      // Columns
      expect(ar.smartTasksColCode, isNotEmpty);
      expect(en.smartTasksColCode, isNotEmpty);
      expect(ar.smartTasksColType, isNotEmpty);
      expect(en.smartTasksColType, isNotEmpty);
      expect(ar.smartTasksColTitle, isNotEmpty);
      expect(en.smartTasksColTitle, isNotEmpty);
      expect(ar.smartTasksColShipment, isNotEmpty);
      expect(en.smartTasksColShipment, isNotEmpty);
      expect(ar.smartTasksColPriority, isNotEmpty);
      expect(en.smartTasksColPriority, isNotEmpty);
      expect(ar.smartTasksColReminder, isNotEmpty);
      expect(en.smartTasksColReminder, isNotEmpty);
      expect(ar.smartTasksColDueDate, isNotEmpty);
      expect(en.smartTasksColDueDate, isNotEmpty);
      expect(ar.smartTasksColStatus, isNotEmpty);
      expect(en.smartTasksColStatus, isNotEmpty);
      expect(ar.smartTasksColActions, isNotEmpty);
      expect(en.smartTasksColActions, isNotEmpty);

      // Tooltips & feedback
      expect(ar.smartTasksGeneralBadge, isNotEmpty);
      expect(en.smartTasksGeneralBadge, isNotEmpty);
      expect(ar.smartTasksActionCompleteTooltip, isNotEmpty);
      expect(en.smartTasksActionCompleteTooltip, isNotEmpty);
      expect(ar.smartTasksActionEditTooltip, isNotEmpty);
      expect(en.smartTasksActionEditTooltip, isNotEmpty);
      expect(ar.smartTasksActionDeleteTooltip, isNotEmpty);
      expect(en.smartTasksActionDeleteTooltip, isNotEmpty);
      expect(ar.smartTasksBulkCompleteBtn(3), contains('3'));
      expect(en.smartTasksBulkCompleteBtn(3), contains('3'));
      expect(ar.smartTasksBulkCompleteSuccess(3), contains('3'));
      expect(en.smartTasksBulkCompleteSuccess(3), contains('3'));
      expect(ar.smartTasksFetchError('Err'), contains('Err'));
      expect(en.smartTasksFetchError('Err'), contains('Err'));
      expect(ar.smartTasksEmptyMessage, isNotEmpty);
      expect(en.smartTasksEmptyMessage, isNotEmpty);

      // Dialog
      expect(ar.smartTaskDialogEditTitle, isNotEmpty);
      expect(en.smartTaskDialogEditTitle, isNotEmpty);
      expect(ar.smartTaskDialogNewTitle, isNotEmpty);
      expect(en.smartTaskDialogNewTitle, isNotEmpty);
      expect(ar.smartTaskFieldTitle, isNotEmpty);
      expect(en.smartTaskFieldTitle, isNotEmpty);
      expect(ar.smartTaskFieldTitleRequired, isNotEmpty);
      expect(en.smartTaskFieldTitleRequired, isNotEmpty);
      expect(ar.smartTaskFieldLinkShipment, isNotEmpty);
      expect(en.smartTaskFieldLinkShipment, isNotEmpty);
      expect(ar.smartTaskFieldPriority, isNotEmpty);
      expect(en.smartTaskFieldPriority, isNotEmpty);
      expect(ar.smartTaskFieldReminderType, isNotEmpty);
      expect(en.smartTaskFieldReminderType, isNotEmpty);
      expect(ar.smartTaskFieldDueDate, isNotEmpty);
      expect(en.smartTaskFieldDueDate, isNotEmpty);
      expect(ar.smartTaskFieldReminderDate, isNotEmpty);
      expect(en.smartTaskFieldReminderDate, isNotEmpty);
      expect(ar.smartTaskFieldDescription, isNotEmpty);
      expect(en.smartTaskFieldDescription, isNotEmpty);
      expect(ar.smartTaskFieldNotes, isNotEmpty);
      expect(en.smartTaskFieldNotes, isNotEmpty);
      expect(ar.smartTaskBtnCancel, isNotEmpty);
      expect(en.smartTaskBtnCancel, isNotEmpty);
      expect(ar.smartTaskBtnUpdate, isNotEmpty);
      expect(en.smartTaskBtnUpdate, isNotEmpty);
      expect(ar.smartTaskBtnSave, isNotEmpty);
      expect(en.smartTaskBtnSave, isNotEmpty);
      expect(ar.smartTaskSuccessUpdated, isNotEmpty);
      expect(en.smartTaskSuccessUpdated, isNotEmpty);
      expect(ar.smartTaskSuccessCreated, isNotEmpty);
      expect(en.smartTaskSuccessCreated, isNotEmpty);
      expect(ar.smartTaskSubmitError('Err'), contains('Err'));
      expect(en.smartTaskSubmitError('Err'), contains('Err'));

      // Helper functions
      expect(ar.smartTaskPriorityLabel('Critical'), equals('حرجة'));
      expect(en.smartTaskPriorityLabel('Critical'), equals('Critical'));
      expect(ar.smartTaskPriorityLabel('High'), equals('عالية'));
      expect(en.smartTaskPriorityLabel('High'), equals('High'));

      expect(ar.smartTaskStatusLabel('Pending'), equals('قيد الانتظار'));
      expect(en.smartTaskStatusLabel('Pending'), equals('Pending'));
      expect(ar.smartTaskStatusLabel('Completed'), equals('مكتملة'));
      expect(en.smartTaskStatusLabel('Completed'), equals('Completed'));

      expect(ar.smartTaskReminderTypeLabel('ETA Arrival'), equals('موعد وصول الشحنة'));
      expect(en.smartTaskReminderTypeLabel('ETA Arrival'), equals('Shipment ETA Arrival'));
      expect(ar.smartTaskReminderTypeLabel('Bank Form 4'), equals('نموذج 4 البنكي'));
      expect(en.smartTaskReminderTypeLabel('Bank Form 4'), equals('Bank Form 4'));

      // Export, Copy and TSV getters
      expect(ar.smartTasksExportTsvBtn, isNotEmpty);
      expect(en.smartTasksExportTsvBtn, isNotEmpty);
      expect(ar.smartTasksExportTsvSuccess, isNotEmpty);
      expect(en.smartTasksExportTsvSuccess, isNotEmpty);
      expect(ar.smartTasksExportPdfBtn, isNotEmpty);
      expect(en.smartTasksExportPdfBtn, isNotEmpty);
      expect(ar.smartTasksExportExcelBtn, isNotEmpty);
      expect(en.smartTasksExportExcelBtn, isNotEmpty);
      expect(ar.smartTaskCopySummaryBtn, isNotEmpty);
      expect(en.smartTaskCopySummaryBtn, isNotEmpty);
      expect(ar.smartTaskCopySummarySuccess, isNotEmpty);
      expect(en.smartTaskCopySummarySuccess, isNotEmpty);
      expect(ar.smartTaskPrintPdfTooltip, isNotEmpty);
      expect(en.smartTaskPrintPdfTooltip, isNotEmpty);
      expect(ar.smartTaskShareWhatsappTooltip, isNotEmpty);
      expect(en.smartTaskShareWhatsappTooltip, isNotEmpty);
      expect(ar.smartTaskCodeBadgeLabel, isNotEmpty);
      expect(en.smartTaskCodeBadgeLabel, isNotEmpty);
      expect(ar.smartTaskImportFileBadgeLabel, isNotEmpty);
      expect(en.smartTaskImportFileBadgeLabel, isNotEmpty);
      expect(ar.smartTaskCopyFieldTooltip, isNotEmpty);
      expect(en.smartTaskCopyFieldTooltip, isNotEmpty);

      // TSV Headers
      expect(ar.smartTasksTsvHeaderCode, isNotEmpty);
      expect(en.smartTasksTsvHeaderCode, isNotEmpty);
      expect(ar.smartTasksTsvHeaderType, isNotEmpty);
      expect(en.smartTasksTsvHeaderType, isNotEmpty);
      expect(ar.smartTasksTsvHeaderTitle, isNotEmpty);
      expect(en.smartTasksTsvHeaderTitle, isNotEmpty);
      expect(ar.smartTasksTsvHeaderShipment, isNotEmpty);
      expect(en.smartTasksTsvHeaderShipment, isNotEmpty);
      expect(ar.smartTasksTsvHeaderPriority, isNotEmpty);
      expect(en.smartTasksTsvHeaderPriority, isNotEmpty);
      expect(ar.smartTasksTsvHeaderReminder, isNotEmpty);
      expect(en.smartTasksTsvHeaderReminder, isNotEmpty);
      expect(ar.smartTasksTsvHeaderDueDate, isNotEmpty);
      expect(en.smartTasksTsvHeaderDueDate, isNotEmpty);
      expect(ar.smartTasksTsvHeaderStatus, isNotEmpty);
      expect(en.smartTasksTsvHeaderStatus, isNotEmpty);
      expect(ar.smartTasksTsvHeaderAssignedUser, isNotEmpty);
      expect(en.smartTasksTsvHeaderAssignedUser, isNotEmpty);
      expect(ar.smartTasksTsvHeaderDescription, isNotEmpty);
      expect(en.smartTasksTsvHeaderDescription, isNotEmpty);
    });

    test('Arabic strings should not contain English or Latin characters', () {
      final latinPattern = RegExp(r'[a-zA-Z]');

      expect(latinPattern.hasMatch(ar.smartTasksTitle), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksNewTaskBtn), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksFilterType), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksTypeAll), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksTypeSystem), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksTypeManual), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksFilterPriority), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksPriorityAll), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksPriorityLow), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksPriorityMedium), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksPriorityHigh), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksPriorityCritical), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksFilterStatus), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksStatusAll), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksStatusPending), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksStatusInProgress), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksStatusCompleted), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksStatusCancelled), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksResetFiltersTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksTableTitle), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksColCode), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksColType), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksColTitle), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksColShipment), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksColPriority), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksColReminder), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksColDueDate), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksColStatus), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksColActions), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksGeneralBadge), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksActionCompleteTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksActionEditTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksActionDeleteTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksEmptyMessage), isFalse);

      expect(latinPattern.hasMatch(ar.smartTaskDialogEditTitle), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskDialogNewTitle), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskFieldTitle), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskFieldTitleRequired), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskFieldLinkShipment), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskFieldPriority), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskFieldReminderType), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskFieldDueDate), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskFieldReminderDate), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskFieldDescription), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskFieldNotes), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskBtnCancel), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskBtnUpdate), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskBtnSave), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskSuccessUpdated), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskSuccessCreated), isFalse);

      expect(latinPattern.hasMatch(ar.smartTasksExportTsvBtn), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksExportTsvSuccess), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksExportPdfBtn), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksExportExcelBtn), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskCopySummaryBtn), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskCopySummarySuccess), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskPrintPdfTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskShareWhatsappTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskCodeBadgeLabel), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskImportFileBadgeLabel), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskCopyFieldTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksTsvHeaderCode), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksTsvHeaderType), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksTsvHeaderTitle), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksTsvHeaderShipment), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksTsvHeaderPriority), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksTsvHeaderReminder), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksTsvHeaderDueDate), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksTsvHeaderStatus), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksTsvHeaderAssignedUser), isFalse);
      expect(latinPattern.hasMatch(ar.smartTasksTsvHeaderDescription), isFalse);

      expect(latinPattern.hasMatch(ar.smartTaskPriorityLabel('critical')), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskStatusLabel('completed')), isFalse);
      expect(latinPattern.hasMatch(ar.smartTaskReminderTypeLabel('ETA Arrival')), isFalse);
    });

    test('English strings should not contain Arabic characters', () {
      final arabicPattern = RegExp(r'[\u0600-\u06FF]');

      expect(arabicPattern.hasMatch(en.smartTasksTitle), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksNewTaskBtn), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksFilterType), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksTypeAll), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksTypeSystem), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksTypeManual), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksFilterPriority), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksPriorityAll), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksPriorityLow), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksPriorityMedium), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksPriorityHigh), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksPriorityCritical), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksFilterStatus), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksStatusAll), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksStatusPending), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksStatusInProgress), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksStatusCompleted), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksStatusCancelled), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksResetFiltersTooltip), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksTableTitle), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksColCode), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksColType), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksColTitle), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksColShipment), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksColPriority), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksColReminder), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksColDueDate), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksColStatus), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksColActions), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksGeneralBadge), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksActionCompleteTooltip), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksActionEditTooltip), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksActionDeleteTooltip), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksEmptyMessage), isFalse);

      expect(arabicPattern.hasMatch(en.smartTaskDialogEditTitle), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskDialogNewTitle), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskFieldTitle), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskFieldTitleRequired), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskFieldLinkShipment), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskFieldPriority), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskFieldReminderType), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskFieldDueDate), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskFieldReminderDate), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskFieldDescription), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskFieldNotes), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskBtnCancel), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskBtnUpdate), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskBtnSave), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskSuccessUpdated), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskSuccessCreated), isFalse);

      expect(arabicPattern.hasMatch(en.smartTasksExportTsvBtn), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksExportTsvSuccess), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksExportPdfBtn), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksExportExcelBtn), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskCopySummaryBtn), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskCopySummarySuccess), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskPrintPdfTooltip), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskShareWhatsappTooltip), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskCodeBadgeLabel), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskImportFileBadgeLabel), isFalse);
      expect(arabicPattern.hasMatch(en.smartTaskCopyFieldTooltip), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksTsvHeaderCode), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksTsvHeaderType), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksTsvHeaderTitle), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksTsvHeaderShipment), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksTsvHeaderPriority), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksTsvHeaderReminder), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksTsvHeaderDueDate), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksTsvHeaderStatus), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksTsvHeaderAssignedUser), isFalse);
      expect(arabicPattern.hasMatch(en.smartTasksTsvHeaderDescription), isFalse);
    });

    final sampleTasks = [
      SmartTaskModel(
        taskId: 1,
        taskCode: 'TSK-001',
        title: 'Review Packing List for PO-1024',
        description: 'Verify carton count against invoice',
        taskType: 'System Generated',
        importFileId: 10,
        importFileCode: 'IMP-2026-001',
        phaseName: 'Clearance',
        assignedUser: 'Kamal',
        priority: 'Critical',
        reminderType: 'Document Review',
        dueDate: '2026-09-10',
        reminderDate: '2026-09-08',
        status: 'Pending',
        notes: null,
        attachmentUrl: null,
        isAutoClosed: false,
        isActive: true,
        createdAt: '2026-09-01T10:00:00Z',
        createdBy: 'system',
      ),
      SmartTaskModel(
        taskId: 2,
        taskCode: 'TSK-002',
        title: 'Call shipping line for arrival notice',
        description: null,
        taskType: 'Manual To-Do',
        importFileId: null,
        importFileCode: null,
        phaseName: null,
        assignedUser: 'Kamal',
        priority: 'Low',
        reminderType: 'General Reminder',
        dueDate: '2026-09-12',
        reminderDate: '2026-09-11',
        status: 'Completed',
        notes: null,
        attachmentUrl: null,
        isAutoClosed: false,
        isActive: true,
        createdAt: '2026-09-02T10:00:00Z',
        createdBy: 'Kamal',
      ),
    ];

    testWidgets('SmartTasksScreen renders purely in Arabic without stacked English text', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) {
              final n = LocaleNotifier();
              n.setLocale(const Locale('ar'));
              return n;
            }),
            smartTasksProvider.overrideWith((ref) => MockSmartTasksNotifier(sampleTasks)),
            importFilesProvider.overrideWith((ref) => MockImportFilesNotifier()),
          ],
          child: const MaterialApp(
            home: AppLocalizationsProvider(
              locale: Locale('ar'),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SmartTasksScreen(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Arabic titles and column headers
      expect(find.text('إدارة المهام الذكية ومحرك التذكيرات'), findsOneWidget);
      expect(find.text('إضافة مهمة جديدة'), findsOneWidget);
      expect(find.text('كود المهمة'), findsOneWidget);
      expect(find.text('نوع المهمة'), findsWidgets);
      expect(find.text('عنوان وتفاصيل المهمة'), findsOneWidget);
      expect(find.text('الشحنة المرتبطة'), findsOneWidget);
      expect(find.text('الأولوية'), findsWidgets);
      expect(find.text('الحالة'), findsWidgets);
      expect(find.text('تاريخ الاستحقاق'), findsOneWidget);

      // Verify translated chips
      expect(find.text('آلية'), findsOneWidget);
      expect(find.text('يدوية'), findsOneWidget);
      expect(find.text('حرجة'), findsOneWidget);
      expect(find.text('منخفضة'), findsOneWidget);
      expect(find.text('قيد الانتظار'), findsOneWidget);
      expect(find.text('مكتملة'), findsOneWidget);
      expect(find.text('عام'), findsOneWidget);

      // Verify absence of stacked bilingual text
      expect(find.text('آلي (System)'), findsNothing);
      expect(find.text('يدوي (To-Do)'), findsNothing);
      expect(find.text('يدوية (To-Do)'), findsNothing);
      expect(find.text('حرجة (Critical)'), findsNothing);
      expect(find.text('عام (General)'), findsNothing);
      expect(find.text('Smart Task Management & Reminder Engine (2.4 / 2.5)'), findsNothing);
    });

    testWidgets('SmartTasksScreen renders purely in English without stacked Arabic text', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) {
              final n = LocaleNotifier();
              n.setLocale(const Locale('en'));
              return n;
            }),
            smartTasksProvider.overrideWith((ref) => MockSmartTasksNotifier(sampleTasks)),
            importFilesProvider.overrideWith((ref) => MockImportFilesNotifier()),
          ],
          child: const MaterialApp(
            home: AppLocalizationsProvider(
              locale: Locale('en'),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: SmartTasksScreen(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify English titles and column headers
      expect(find.text('Smart Tasks & Reminder Engine'), findsOneWidget);
      expect(find.text('Add New Task'), findsOneWidget);
      expect(find.text('Task Code'), findsOneWidget);
      expect(find.text('Task Type'), findsWidgets);
      expect(find.text('Task Title & Details'), findsOneWidget);
      expect(find.text('Linked Shipment'), findsOneWidget);
      expect(find.text('Priority'), findsWidgets);
      expect(find.text('Status'), findsWidgets);
      expect(find.text('Due Date'), findsOneWidget);

      // Verify translated chips
      expect(find.text('Automated'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);

      // Verify absence of Arabic or stacked strings
      expect(find.text('آلي (System)'), findsNothing);
      expect(find.text('إضافة مهمة جديدة'), findsNothing);
      expect(find.text('كود المهمة'), findsNothing);
    });
  });
}
