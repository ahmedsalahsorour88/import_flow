import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/ai_agent_tool_executor.dart';

void main() {
  group('Policy-Agnostic Agent - Step Code Normalization', () {
    test('normalizes various step code notations to STEP_XX format', () {
      expect(AiAgentToolExecutor.normalizeStepCode('6'), equals('STEP_06'));
      expect(AiAgentToolExecutor.normalizeStepCode('06'), equals('STEP_06'));
      expect(AiAgentToolExecutor.normalizeStepCode('STEP_06'), equals('STEP_06'));
      expect(AiAgentToolExecutor.normalizeStepCode('step_6'), equals('STEP_06'));
      expect(AiAgentToolExecutor.normalizeStepCode('Step 14'), equals('STEP_14'));
      expect(AiAgentToolExecutor.normalizeStepCode('21'), equals('STEP_21'));
      expect(AiAgentToolExecutor.normalizeStepCode(''), equals(''));
      expect(AiAgentToolExecutor.normalizeStepCode(null), equals(''));
    });
  });

  group('Policy-Agnostic Agent - Tool Schema Registration', () {
    test('declares query_step_policy, skip_step, and register_pending_reference', () {
      final tools = AiAgentToolExecutor.getAgentTools();
      expect(tools, hasLength(1));
      final decls = tools.first.functionDeclarations!;
      final names = decls.map((d) => d.name).toList();

      expect(names, contains('query_step_policy'));
      expect(names, contains('skip_step'));
      expect(names, contains('register_pending_reference'));

      final policyTool = decls.firstWhere((d) => d.name == 'query_step_policy');
      expect(policyTool.parameters!.requiredProperties, contains('step_code'));

      final skipTool = decls.firstWhere((d) => d.name == 'skip_step');
      expect(skipTool.parameters!.requiredProperties, contains('import_file_id'));
      expect(skipTool.parameters!.requiredProperties, contains('step_code'));
      expect(skipTool.parameters!.requiredProperties, contains('reason_category'));
      expect(skipTool.parameters!.requiredProperties, contains('justification'));

      final refTool = decls.firstWhere((d) => d.name == 'register_pending_reference');
      expect(refTool.parameters!.requiredProperties, contains('import_file_id'));
      expect(refTool.parameters!.requiredProperties, contains('step_code'));
      expect(refTool.parameters!.requiredProperties, contains('reference_number'));
      expect(refTool.parameters!.requiredProperties, contains('reason_text'));
    });
  });

  group('Policy-Agnostic Agent - Live Policy Query (Section 10.5)', () {
    test('queries live step policy correctly from backend', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/lifecycle-board/step-configs/STEP_06')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'id': 6,
                    'step_code': 'STEP_06',
                    'step_name_ar': 'فحص وتجهيز البضاعة والشحن',
                    'step_name_en': 'Cargo Inspection & Shipping Loading',
                    'phase_id': 2,
                    'skip_policy': 'single_approval',
                    'reason_required': true,
                    'reason_categories': ['Regulatory Exemption', 'Client Waived'],
                    'approver_roles': ['Manager'],
                    'supports_pending_reference': true,
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final executor = AiAgentToolExecutor(dio: dio);
      final res = await executor.queryStepPolicy(stepCode: 'STEP_06');

      expect(res['status'], equals('SUCCESS'));
      expect(res['step_code'], equals('STEP_06'));
      expect(res['skip_policy'], equals('single_approval'));
      expect(res['is_blocked'], isFalse);
      expect(res['requires_single_approval'], isTrue);
      expect(res['supports_pending_reference'], isTrue);
      expect(res['approver_roles'], contains('Manager'));
    });

    test('defaults unconfigured step safely to blocked (Section 10.2)', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/lifecycle-board/step-configs/')) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 404,
                  ),
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final executor = AiAgentToolExecutor(dio: dio);
      final res = await executor.queryStepPolicy(stepCode: 'STEP_99');

      expect(res['status'], equals('DEFAULT_BLOCKED'));
      expect(res['skip_policy'], equals('blocked'));
      expect(res['is_blocked'], isTrue);
      expect(res['supports_pending_reference'], isFalse);
    });
  });

  group('Policy-Agnostic Agent - Skip Step Execution & RAW Verification (Section 10.5)', () {
    test('rejects skip if justification is less than 5 characters', () async {
      final dio = Dio();
      final executor = AiAgentToolExecutor(dio: dio);

      final res = await executor.skipStep(
        importFileId: 4,
        stepCode: 'STEP_06',
        reasonCategory: 'Other',
        justification: 'Done', // only 4 chars
      );

      expect(res['success'], isFalse);
      expect(res['error'], contains('5 أحرف'));
    });

    test('blocks skip if step policy is blocked and logs audit entry', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/lifecycle-board/step-configs/STEP_03')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'step_code': 'STEP_03',
                    'step_name_ar': 'استخراج رقم ACID الإلزامي',
                    'skip_policy': 'blocked',
                    'approver_roles': ['Manager'],
                    'supports_pending_reference': false,
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final executor = AiAgentToolExecutor(dio: dio);
      final res = await executor.skipStep(
        importFileId: 4,
        stepCode: 'STEP_03',
        reasonCategory: 'Regulatory',
        justification: 'Shipper requested expedited release without ACID.',
      );

      expect(res['success'], isFalse);
      expect(res['blocked'], isTrue);
      expect(res['skip_policy'], equals('blocked'));
      expect(res['error'], contains('محظورة من التخطي'));

      final audit = executor.getAgentAuditTrail();
      expect(audit['total_actions'], equals(1));
      expect(audit['audit_entries'][0]['tool_name'], equals('skip_step'));
      expect(audit['audit_entries'][0]['verified'], isFalse);
    });

    test('executes skip and performs RAW Verification when policy permits', () async {
      final dio = Dio();
      bool skipEndpointCalled = false;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/lifecycle-board/step-configs/STEP_06')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'step_code': 'STEP_06',
                    'step_name_ar': 'فحص وتجهيز البضاعة والشحن',
                    'skip_policy': 'single_approval',
                    'approver_roles': ['Manager'],
                    'supports_pending_reference': true,
                  },
                ),
              );
            }
            if (options.path.endsWith('/import-files/4')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'import_file_id': 4,
                    'import_file_code': 'IMP-2026-0004',
                  },
                ),
              );
            }
            if (options.path.endsWith('/lifecycle-board/stages/skip')) {
              skipEndpointCalled = true;
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'message': 'Step skipped successfully'},
                ),
              );
            }
            if (options.path.endsWith('/lifecycle-board/shipments/IMP-2026-0004/stages')) {
              // RAW Verification read
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'step_code': 'STEP_06',
                      'status': 'Skipped',
                      'notes': 'تم تخطي المرحلة: [Client Waived] Waived as per client SLA.',
                    },
                  ],
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final executor = AiAgentToolExecutor(dio: dio);
      final res = await executor.skipStep(
        importFileId: 4,
        stepCode: 'STEP_06',
        reasonCategory: 'Client Waived',
        justification: 'Waived as per client signed SLA and operational agreement.',
      );

      expect(skipEndpointCalled, isTrue);
      expect(res['success'], isTrue);
      expect(res['verified'], isTrue);
      expect(res['raw_verified'], isTrue);
      expect(res['status'], equals('Skipped'));
      expect(res['import_file_code'], equals('IMP-2026-0004'));

      final audit = executor.getAgentAuditTrail();
      expect(audit['total_actions'], equals(1));
      expect(audit['audit_entries'][0]['verified'], isTrue);
    });
  });

  group('Policy-Agnostic Agent - Pending Reference Registration (Section 10.4)', () {
    test('rejects pending reference if step does not support it', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/lifecycle-board/step-configs/STEP_01')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'step_code': 'STEP_01',
                    'supports_pending_reference': false,
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final executor = AiAgentToolExecutor(dio: dio);
      final res = await executor.registerPendingReference(
        importFileId: 4,
        stepCode: 'STEP_01',
        referenceNumber: 'REF-TEMP-110',
        reasonText: 'Invoice pending supplier signature',
      );

      expect(res['success'], isFalse);
      expect(res['supports_pending_reference'], isFalse);
      expect(res['error'], contains('لا تدعم حالياً تسجيل مرجع مؤقت'));
    });

    test('registers pending reference and verifies incomplete status (RAW Verified)', () async {
      final dio = Dio();
      bool registerEndpointCalled = false;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/lifecycle-board/step-configs/STEP_06')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'step_code': 'STEP_06',
                    'supports_pending_reference': true,
                  },
                ),
              );
            }
            if (options.path.endsWith('/import-files/4')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'import_file_id': 4,
                    'import_file_code': 'IMP-2026-0004',
                  },
                ),
              );
            }
            if (options.path.endsWith('/lifecycle-board/stages/register-pending-reference')) {
              registerEndpointCalled = true;
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'message': 'Pending reference recorded'},
                ),
              );
            }
            if (options.path.endsWith('/lifecycle-board/shipments/IMP-2026-0004/stages')) {
              // RAW Verification read
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'step_code': 'STEP_06',
                      'status': 'Reference recorded – pending full documentation',
                      'completed_at': null,
                    },
                  ],
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final executor = AiAgentToolExecutor(dio: dio);
      final res = await executor.registerPendingReference(
        importFileId: 4,
        stepCode: 'STEP_06',
        referenceNumber: 'BL-DRAFT-99881',
        reasonText: 'Original bill of lading in courier transit from Shanghai.',
        expectedCompletionDate: '2026-09-25',
      );

      expect(registerEndpointCalled, isTrue);
      expect(res['success'], isTrue);
      expect(res['verified'], isTrue);
      expect(res['raw_verified'], isTrue);
      expect(res['status'], equals('Reference recorded – pending full documentation'));
      expect(res['is_completed'], isFalse); // Incomplete per Section 10.4
      expect(res['reference_number'], equals('BL-DRAFT-99881'));

      final audit = executor.getAgentAuditTrail();
      expect(audit['total_actions'], equals(1));
      expect(audit['audit_entries'][0]['verified'], isTrue);
      expect(audit['audit_entries'][0]['tool_name'], equals('register_pending_reference'));
    });
  });
}
