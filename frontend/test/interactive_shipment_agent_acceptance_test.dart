import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/active_shipment_context.dart';
import 'package:frontend/core/providers/ai_assistant_provider.dart';
import 'package:frontend/core/services/ai_agent_tool_executor.dart';
import 'package:frontend/core/utils/ai_language_detector.dart';
import 'package:frontend/core/utils/shipment_task_formatter.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';
import 'package:frontend/features/smart_tasks/models/smart_task_model.dart';
import 'package:frontend/features/smart_tasks/providers/smart_tasks_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late ImportFileModel shipmentA;
  late ImportFileModel shipmentB;

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    shipmentA = ImportFileModel(
      importFileId: 4,
      importFileCode: 'IMP-2026-0004',
      customFileNumber: 'PET Stock',
      companyName: 'SCAS Co.',
      supplierName: 'Sinopec Chemical',
      currentModule: 'Shipping Operations',
      currentStage: 'Phase 5: Cargo Shipping',
      nextAction: 'Container Allocation',
      progressPercent: 40.0,
      createdAt: '2026-08-01T10:00:00',
      updatedAt: '2026-08-27T10:00:00',
    );

    shipmentB = ImportFileModel(
      importFileId: 5,
      importFileCode: 'IMP-2026-0005',
      customFileNumber: 'PVC Resin',
      companyName: 'Egyptian Polymers',
      supplierName: 'LG Chem',
      currentModule: 'Freight RFQ & Booking',
      currentStage: 'Phase 4: Freight Booking',
      nextAction: 'Booking confirmation',
      progressPercent: 30.0,
      createdAt: '2026-08-10T10:00:00',
      updatedAt: '2026-08-28T10:00:00',
    );

    container = ProviderContainer(
      overrides: [
        importFilesProvider.overrideWith((ref) => MockImportFilesNotifier([shipmentA, shipmentB])),
        smartTasksProvider.overrideWith((ref) => MockSmartTasksNotifier()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Acceptance Test 1: Bilingual Dynamic Switching & Identifier Preservation', () {
    test('detects per-message language and preserves system identifiers', () {
      final notifier = container.read(aiAssistantProvider.notifier);

      // 1. User sends Arabic query
      const arabicMessage = 'ما هو موقف شحنة PET وحالة رقم ACID 482910523 وتاريخ 27/08/2026؟';
      final langAr = AiLanguageDetector.detectDominantLanguage(arabicMessage);
      expect(langAr, equals('ar'));

      notifier.setLanguage(langAr);
      expect(container.read(aiAssistantProvider).isArabic, isTrue);

      // System identifiers in Arabic directive
      final arDirective = notifier.state.isArabic;
      expect(arDirective, isTrue);

      // 2. User switches to English in the same session
      const englishMessage = 'Can you show me container allocations for WHSU81072658 and booking THXJ2608090?';
      final langEn = AiLanguageDetector.detectDominantLanguage(englishMessage);
      expect(langEn, equals('en'));

      notifier.setLanguage(langEn);
      expect(container.read(aiAssistantProvider).isEnglish, isTrue);

      // Preserves identifiers (never translated or transliterated)
      expect(englishMessage, contains('WHSU81072658'));
      expect(englishMessage, contains('THXJ2608090'));
      expect(arabicMessage, contains('482910523'));
      expect(arabicMessage, contains('27/08/2026'));
    });
  });

  group('Acceptance Test 2: Navigator -> Chat Handoff (Active Context Inheritance)', () {
    test('omitted shipment reference in tool execution inherits active context', () async {
      final notifier = container.read(aiAssistantProvider.notifier);

      // User clicks Step 5 in the visual navigator for shipment A (id: 4)
      await notifier.setActiveStep(
        shipmentId: shipmentA.importFileId,
        shipmentName: shipmentA.displayName,
        clientName: shipmentA.companyName,
        fileCode: shipmentA.importFileCode,
        stepId: 5,
        screenReference: 'Phase 5 Screen',
      );

      final state = container.read(aiAssistantProvider);
      expect(state.hasActiveContext, isTrue);
      expect(state.activeContext!.shipmentId, equals(4));
      expect(state.activeContext!.stepId, equals(5));

      // Mock tool executor tracking the passed activeShipmentId
      final dio = Dio();
      int? capturedShipmentId;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/cargo-shipping')) {
              capturedShipmentId = (options.queryParameters['import_file_id'] as num?)?.toInt() ??
                  (options.data is Map ? (options.data['import_file_id'] as num?)?.toInt() : null);
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'cargo_shipping_id': 101,
                      'import_file_id': capturedShipmentId ?? 4,
                      'containers_loading_data': [
                        {
                          'container_no': 'WHSU81072658',
                          'seal_no': 'WHA257097',
                        }
                      ],
                    }
                  ],
                ),
              );
            } else if (options.path.contains('/freight-booking')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: [],
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final executor = AiAgentToolExecutor(dio: dio);

      // Tool call where arguments OMIT import_file_id
      final args = {
        'container_no': 'WHSU81072658',
        'seal_no': 'WHA257097',
        'assignment_date': '2026-08-27',
      };

      final result = await executor.execute(
        'update_container_allocation',
        args,
        activeShipmentId: state.activeContext?.shipmentId,
      );

      // Verify that active context ID (4) was automatically inherited
      expect(capturedShipmentId, equals(4));
      expect(result['verified'], isTrue);
      expect(result['import_file_id'], equals(4));
    });
  });

  group('Acceptance Test 3: Conflict Override (Explicit Mention > Clicked Context)', () {
    test('explicit text mention overrides clicked active context silently', () async {
      final notifier = container.read(aiAssistantProvider.notifier);

      // User clicked Shipment A (id: 4) in navigator
      await notifier.setActiveStep(
        shipmentId: shipmentA.importFileId,
        shipmentName: shipmentA.displayName,
        clientName: shipmentA.companyName,
        fileCode: shipmentA.importFileCode,
        stepId: 4,
      );

      expect(container.read(aiAssistantProvider).activeContext!.shipmentId, equals(4));

      // User sends free text explicitly naming Shipment B ("IMP-2026-0005")
      await notifier.sendMessage('في شحنة IMP-2026-0005 سجل رقم الحاوية WHSU999999');

      final updatedState = container.read(aiAssistantProvider);

      // Active context and selected shipment ID must override silently to Shipment B (id: 5)
      expect(updatedState.activeContext, isNotNull);
      expect(updatedState.activeContext!.shipmentId, equals(5));
      expect(updatedState.activeContext!.fileCode, equals('IMP-2026-0005'));
      expect(updatedState.selectedShipmentId, equals(5));
    });
  });

  group('Acceptance Test 4: Verification Failure (Zero False Success)', () {
    test('rejects write tool call with missing required fields with explicit error', () async {
      final dio = Dio();
      final executor = AiAgentToolExecutor(dio: dio);

      // Calling container allocation without container_no
      final invalidArgs = {
        'import_file_id': 4,
        'seal_no': 'WHA257097',
      };

      final result = await executor.execute('update_container_allocation', invalidArgs);

      expect(result['verified'], isFalse);
      expect(result['error'], contains('رقم الحاوية'));

      // Calling without import_file_id and no active context fallback
      final noFileArgs = {
        'container_no': 'WHSU81072658',
        'seal_no': 'WHA257097',
      };

      final noFileResult = await executor.execute('update_container_allocation', noFileArgs);
      expect(noFileResult['verified'], isFalse);
      expect(noFileResult['error'], contains('import_file_id'));
    });
  });

  group('Acceptance Test 5: Live Status Query', () {
    test('queries live ACID and container data directly from service', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/import-files/4')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'import_file_id': 4,
                    'import_file_code': 'IMP-2026-0004',
                    'acid_number': '482910523',
                    'acid_issue_date': '2026-07-01',
                    'acid_expiry_date': '2026-09-30',
                    'is_customs_released': false,
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final executor = AiAgentToolExecutor(dio: dio);
      final queryResult = await executor.execute('query_acid_status', {'import_file_id': 4});

      expect(queryResult['status'], equals('SUCCESS'));
      expect(queryResult['live_verified'], isTrue);
      expect(queryResult['acid_number'], equals('482910523'));
      expect(queryResult['is_customs_released'], isFalse);
      expect(queryResult['acid_expiry_date'], equals('2026-09-30'));
    });
  });

  group('Acceptance Test 6: Session Persistence (4-Hour Window)', () {
    test('persists active context and restores it if within 4 hours, drops if expired', () async {
      final notifier = container.read(aiAssistantProvider.notifier);

      final activeCtx = ActiveShipmentContext(
        shipmentId: 4,
        shipmentName: 'PET Stock',
        clientName: 'SCAS',
        fileCode: 'IMP-2026-0004',
        stepId: 5,
        stepNameAr: 'تخصيص الحاويات',
        stepNameEn: 'Container Allocation',
        setAt: DateTime.now(),
      );

      await notifier.setActiveContext(activeCtx);

      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('ai_assistant_active_context');
      expect(savedJson, isNotNull);

      // Verify deserialized context
      final restored = ActiveShipmentContext.fromJsonString(savedJson!);
      expect(restored, isNotNull);
      expect(restored!.shipmentId, equals(4));
      expect(restored.isExpired(), isFalse);

      // Simulate context set 4 hours and 10 minutes ago
      final expiredContext = activeCtx.copyWith(
        setAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 10)),
      );
      await prefs.setString('ai_assistant_active_context', expiredContext.toJsonString());

      // Create new container simulating app restart
      final newContainer = ProviderContainer(
        overrides: [
          importFilesProvider.overrideWith((ref) => MockImportFilesNotifier([shipmentA, shipmentB])),
          smartTasksProvider.overrideWith((ref) => MockSmartTasksNotifier()),
        ],
      );

      // Read notifier to trigger _loadPersistedContext
      newContainer.read(aiAssistantProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      // Expired context should not be restored as active
      expect(newContainer.read(aiAssistantProvider).hasActiveContext, isFalse);
      newContainer.dispose();
    });

    test('clear context command resets active context and navigator', () async {
      final notifier = container.read(aiAssistantProvider.notifier);

      await notifier.setActiveStep(
        shipmentId: 4,
        shipmentName: 'PET Stock',
        clientName: 'SCAS',
        fileCode: 'IMP-2026-0004',
        stepId: 5,
      );

      expect(container.read(aiAssistantProvider).hasActiveContext, isTrue);

      // User commands "clear context"
      await notifier.sendMessage('امسح السياق');

      final state = container.read(aiAssistantProvider);
      expect(state.hasActiveContext, isFalse);
      expect(state.selectedShipmentId, isNull);
      expect(state.messages.last.text, contains('تم مسح سياق الشحنة'));
    });
  });

  group('Acceptance Test 7: Unified Output Formatting Specification Compliance', () {
    test('formats task list with status-first alert, human identity, and completion bar', () {
      final now = DateTime.now();
      final overdueTask = SmartTaskModel.fromJson({
        'task_id': 10,
        'task_code': 'TSK-2026-0010',
        'title': 'اعتماد نموذج 4 البنكي',
        'priority': 'High',
        'status': 'Pending',
        'due_date': now.subtract(const Duration(days: 3)).toIso8601String().split('T').first,
        'import_file_id': 4,
      });

      final todayTask = SmartTaskModel.fromJson({
        'task_id': 11,
        'task_code': 'TSK-2026-0011',
        'title': 'تخصيص الحاوية والسيل',
        'priority': 'Critical',
        'status': 'Pending',
        'due_date': now.toIso8601String().split('T').first,
        'import_file_id': 4,
      });

      final output = ShipmentTaskFormatter.formatTaskList(
        shipmentName: 'PET Stock',
        clientName: 'SCAS Company',
        fileCode: 'IMP-2026-0004',
        completedSteps: 4,
        totalSteps: 10,
        tasks: [overdueTask, todayTask],
        renderTime: now,
        isArabic: true,
      );

      // 1. Status-first alert line if overdue
      expect(output, startsWith('⚠️'));
      expect(output, contains('متأخرة منذ 3 أيام'));

      // 2. Human-readable shipment identity (no leading file code)
      expect(output, contains('PET Stock – SCAS (IMP-2026-0004)'));

      // 3. Completion rate with 10-block progress bar
      expect(output, contains('نسبة الإنجاز: 🟡 40% (4 من 10 خطوة مكتملة) ▓▓▓▓░░░░░░'));

      // 4. Section ordering: متأخرة: then مستحقة اليوم:
      final overdueIdx = output.indexOf('متأخرة:');
      final todayIdx = output.indexOf('مستحقة اليوم:');
      expect(overdueIdx, isNot(-1));
      expect(todayIdx, isNot(-1));
      expect(overdueIdx, lessThan(todayIdx));

      // 5. Next clear action
      expect(output, contains('المطلوب منك الآن:'));
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
  MockSmartTasksNotifier() : super(Dio()) {
    state = SmartTasksState(tasks: []);
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
