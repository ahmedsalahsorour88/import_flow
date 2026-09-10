import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/ai_agent_tool_executor.dart';

void main() {
  group('AiAgentToolExecutor - Date Normalization', () {
    test('normalizes various date formats including Egyptian/Arabic numerals', () {
      expect(AiAgentToolExecutor.normalizeDate('27/8'), equals('2026-08-27'));
      expect(AiAgentToolExecutor.normalizeDate('27/08'), equals('2026-08-27'));
      expect(AiAgentToolExecutor.normalizeDate('27-8'), equals('2026-08-27'));
      expect(AiAgentToolExecutor.normalizeDate('27/8/2026'), equals('2026-08-27'));
      expect(AiAgentToolExecutor.normalizeDate('27/08/2026'), equals('2026-08-27'));
      expect(AiAgentToolExecutor.normalizeDate('2026-08-27'), equals('2026-08-27'));
      // Arabic-Indic numerals: ٢٧/٨
      expect(AiAgentToolExecutor.normalizeDate('٢٧/٨'), equals('2026-08-27'));
      expect(AiAgentToolExecutor.normalizeDate(''), equals(''));
      expect(AiAgentToolExecutor.normalizeDate(null), equals(''));
    });
  });

  group('AiAgentToolExecutor - Tool Schemas', () {
    test('declares all 6 essential enterprise agent tools with schemas', () {
      final tools = AiAgentToolExecutor.getAgentTools();
      expect(tools, hasLength(1));
      final decls = tools.first.functionDeclarations!;
      final names = decls.map((d) => d.name).toList();

      expect(names, contains('search_shipments'));
      expect(names, contains('update_container_allocation'));
      expect(names, contains('create_or_update_booking'));
      expect(names, contains('query_acid_status'));
      expect(names, contains('query_shipment_field'));
      expect(names, contains('get_agent_audit_trail'));

      final searchTool = decls.firstWhere((d) => d.name == 'search_shipments');
      expect(searchTool.parameters!.requiredProperties, contains('query'));

      final containerTool = decls.firstWhere((d) => d.name == 'update_container_allocation');
      expect(containerTool.parameters!.requiredProperties, contains('import_file_id'));
      expect(containerTool.parameters!.requiredProperties, contains('container_no'));
      expect(containerTool.parameters!.requiredProperties, contains('seal_no'));
    });
  });

  group('AiAgentToolExecutor - Search & Ambiguity Handling', () {
    test('resolves unique shipment candidate for PET Stock', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/import-files')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'import_file_id': 1,
                      'import_file_code': 'IMP-2026-0001',
                      'company_name': 'ECO Associates',
                      'supplier_name': 'GI Industrial',
                    },
                    {
                      'import_file_id': 4,
                      'import_file_code': 'IMP-2026-0004',
                      'company_name': 'SCAS For Construction And Finishing',
                      'supplier_name': 'Suzhou Yuheng Textile Co.,Ltd',
                      'po_number': 'YH20260730-6',
                      'acid_number': '5281534391023010013',
                      'is_customs_released': false,
                    },
                  ],
                ),
              );
            }
            if (options.path.endsWith('/purchase-orders')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'po_id': 1,
                      'po_number': 'PO-2026-001',
                      'po_reference': 'HSR Project',
                      'import_file_id': 1,
                    },
                    {
                      'po_id': 3,
                      'po_number': 'PO-2026-003',
                      'po_reference': 'PET Stock',
                      'import_file_id': 4,
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
      final res = await executor.searchShipments('PET');

      expect(res['status'], equals('FOUND'));
      expect(res['is_ambiguous'], isFalse);
      expect(res['import_file_id'], equals(4));
      expect(res['file_code'], equals('IMP-2026-0004'));
      expect(res['po_reference'], equals('PET Stock'));
      expect(res['company_name'], contains('SCAS'));
    });

    test('detects ambiguity when multiple shipments match keyword', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/import-files')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'import_file_id': 2,
                      'import_file_code': 'IMP-2026-0002',
                      'company_name': 'ECO Associates',
                      'supplier_name': 'GI Industrial',
                    },
                    {
                      'import_file_id': 3,
                      'import_file_code': 'IMP-2026-0003',
                      'company_name': 'ECO Associates',
                      'supplier_name': 'GI Industrial',
                    },
                  ],
                ),
              );
            }
            if (options.path.endsWith('/purchase-orders')) {
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
      final res = await executor.searchShipments('ECO');

      expect(res['status'], equals('AMBIGUOUS'));
      expect(res['is_ambiguous'], isTrue);
      expect(res['count'], equals(2));
      expect(res['candidates'], hasLength(2));
    });
  });

  group('AiAgentToolExecutor - Container Allocation & RAW Verification', () {
    test('successfully writes container allocation and asserts RAW verification', () async {
      Map<String, dynamic>? storedShippingRecord;

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // GET /cargo-shipping
            if (options.path.endsWith('/cargo-shipping') && options.method == 'GET') {
              if (storedShippingRecord != null) {
                return handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: [storedShippingRecord],
                  ),
                );
              }
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: [],
                ),
              );
            }

            // POST /cargo-shipping
            if (options.path.contains('/cargo-shipping') && options.method == 'POST') {
              final payload = options.data as Map<String, dynamic>;
              storedShippingRecord = {
                'cargo_shipping_id': 1,
                'cargo_shipping_code': 'CS-2026-0001',
                'import_file_id': payload['import_file_id'],
                'containers_loading_data': payload['containers_loading_data'],
              };
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: storedShippingRecord,
                ),
              );
            }

            // GET /freight-booking
            if (options.path.endsWith('/freight-booking') && options.method == 'GET') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'booking_id': 1,
                      'booking_code': 'BKG-2026-0001',
                      'import_file_id': 4,
                      'containers_data': [],
                    }
                  ],
                ),
              );
            }

            // PUT /freight-booking/1
            if (options.path.contains('/freight-booking') && options.method == 'PUT') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'status': 'ok'},
                ),
              );
            }

            return handler.next(options);
          },
        ),
      );

      final executor = AiAgentToolExecutor(dio: dio);
      final res = await executor.updateContainerAllocation(
        importFileId: 4,
        containerNo: 'WHSU81072658',
        sealNo: 'WHA257097',
        assignmentDate: '27/8',
        loadingDate: '27/8',
      );

      expect(res['success'], isTrue);
      expect(res['verified'], isTrue);
      expect(res['record_code'], equals('CS-2026-0001'));
      expect(res['container_no'], equals('WHSU81072658'));
      expect(res['seal_no'], equals('WHA257097'));
      expect(res['assignment_date'], equals('2026-08-27'));
      expect(res['loading_date'], equals('2026-08-27'));

      // Check audit trail
      expect(executor.auditTrail, hasLength(1));
      final audit = executor.auditTrail.first;
      expect(audit.toolName, equals('update_container_allocation'));
      expect(audit.verified, isTrue);
      expect(audit.recordCode, equals('CS-2026-0001'));
    });

    test('fails transparently if RAW verification detects seal mismatch', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // Initial GET
            if (options.path.endsWith('/cargo-shipping') && options.method == 'GET') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  // Simulate corrupted/different re-read data from DB
                  data: [
                    {
                      'cargo_shipping_id': 1,
                      'cargo_shipping_code': 'CS-2026-0001',
                      'containers_loading_data': [
                        {
                          'container_no': 'WHSU81072658',
                          'seal_no': 'WRONG_SEAL_999', // Mismatch!
                        }
                      ],
                    }
                  ],
                ),
              );
            }
            if (options.method == 'PATCH' || options.method == 'POST' || options.method == 'PUT') {
              return handler.resolve(
                Response(requestOptions: options, statusCode: 200, data: {}),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final executor = AiAgentToolExecutor(dio: dio);
      final res = await executor.updateContainerAllocation(
        importFileId: 4,
        containerNo: 'WHSU81072658',
        sealNo: 'WHA257097',
        assignmentDate: '27/8',
        loadingDate: '27/8',
      );

      expect(res['success'], isFalse);
      expect(res['verified'], isFalse);
      expect(res['error'], contains('تطابق السيل'));

      // Audit trail logs the verification failure
      expect(executor.auditTrail, hasLength(1));
      expect(executor.auditTrail.first.verified, isFalse);
    });
  });

  group('AiAgentToolExecutor - Freight Booking & House B/L', () {
    test('updates booking confirmation and House B/L with RAW verification', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/freight-booking') && options.method == 'GET') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'booking_id': 1,
                      'booking_code': 'BKG-2026-0001',
                      'booking_confirmation_no': 'THXJ2608090',
                    }
                  ],
                ),
              );
            }
            if (options.path.contains('/freight-booking') && options.method == 'PUT') {
              return handler.resolve(Response(requestOptions: options, statusCode: 200, data: {}));
            }
            if (options.path.contains('/import-documentation/draft-bl') && options.method == 'GET') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'bl_review_id': 1,
                      'hbl_no': 'THXJ2608090',
                      'booking_no': 'THXJ2608090',
                    }
                  ],
                ),
              );
            }
            if (options.path.contains('/import-documentation/draft-bl') &&
                (options.method == 'POST' || options.method == 'PUT')) {
              return handler.resolve(Response(requestOptions: options, statusCode: 200, data: {}));
            }
            return handler.next(options);
          },
        ),
      );

      final executor = AiAgentToolExecutor(dio: dio);
      final res = await executor.createOrUpdateBooking(
        importFileId: 4,
        bookingNo: 'THXJ2608090',
        houseBlNo: 'THXJ2608090',
      );

      expect(res['success'], isTrue);
      expect(res['verified'], isTrue);
      expect(res['booking_code'], equals('BKG-2026-0001'));
      expect(res['booking_no'], equals('THXJ2608090'));
      expect(res['house_bl_no'], equals('THXJ2608090'));
    });
  });

  group('AiAgentToolExecutor - Live ACID Status Query', () {
    test('queries live ACID data from database without memory hallucination', () async {
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
                    'company_name': 'SCAS For Construction And Finishing',
                    'supplier_name': 'Suzhou Yuheng Textile Co.,Ltd',
                    'po_number': 'YH20260730-6',
                    'acid_number': '5281534391023010013',
                    'acid_issue_date': '2026-07-30',
                    'acid_expiry_date': '2026-10-30',
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
      final res = await executor.queryAcidStatus(importFileId: 4);

      expect(res['status'], equals('SUCCESS'));
      expect(res['has_acid'], isTrue);
      expect(res['acid_number'], equals('5281534391023010013'));
      expect(res['is_customs_released'], isFalse);
      expect(res['customs_release_status'], contains('لم يتم الإفراج'));
      expect(res['live_verified'], isTrue);
      expect(res['source'], contains('Live Database Query'));
    });
  });
}
