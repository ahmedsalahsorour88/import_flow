import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customs_consultation/providers/customs_consultation_provider.dart';

class _MockHttpClientAdapter implements HttpClientAdapter {
  final Map<String, dynamic> Function(RequestOptions options) handler;

  _MockHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final res = handler(options);
    final status = res['status'] as int? ?? 200;
    final data = res['data'];
    return ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('Expense Catalog Model & Provider Tests (AI-EXPENSE-CATALOG-002)', () {
    test('ExpenseCatalogItemModel parses JSON correctly', () {
      final json = {
        'code': 'CLEAR-BROKER-FEE-20',
        'canonical_name_ar': 'أتعاب تخليص حاوية 20 قدم',
        'canonical_name_en': 'Customs Clearance Fee 20ft',
        'category': 'Clearance Fees',
        'unit_type': 'per_container',
        'allow_composite': false,
        'recognition_patterns': [
          'أتعاب تخليص حاوية 20',
          'اتعاب تخليص 20 قدم',
        ],
        'is_active': true,
        'created_at': '2026-09-10T10:00:00Z',
      };

      final item = ExpenseCatalogItemModel.fromJson(json);

      expect(item.code, 'CLEAR-BROKER-FEE-20');
      expect(item.canonicalNameAr, 'أتعاب تخليص حاوية 20 قدم');
      expect(item.canonicalNameEn, 'Customs Clearance Fee 20ft');
      expect(item.category, 'Clearance Fees');
      expect(item.unitType, 'per_container');
      expect(item.allowComposite, false);
      expect(item.recognitionPatterns.length, 2);
      expect(item.recognitionPatterns.first, 'أتعاب تخليص حاوية 20');
      expect(item.isActive, true);
      expect(item.createdAt, '2026-09-10T10:00:00Z');
    });

    test('ExpenseCatalogNotifier fetches catalog items and updates state', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:28080/api/v1'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        return {
          'status': 200,
          'data': [
            {
              'code': 'CLEAR-BROKER-FEE-40',
              'canonical_name_ar': 'أتعاب تخليص حاوية 40 قدم',
              'category': 'Clearance Fees',
              'unit_type': 'per_container',
              'allow_composite': false,
              'recognition_patterns': ['أتعاب تخليص 40'],
              'is_active': true,
            },
            {
              'code': 'PORT-STORAGE',
              'canonical_name_ar': 'أرضيات وغرامات الميناء',
              'category': 'Port & Handling',
              'unit_type': 'fixed',
              'allow_composite': false,
              'recognition_patterns': ['أرضيات'],
              'is_active': true,
            }
          ],
        };
      });

      final notifier = ExpenseCatalogNotifier(dio);
      await notifier.fetchCatalog();

      final state = notifier.state;
      expect(state.hasValue, true);
      final list = state.value!;
      expect(list.length, 2);
      expect(list[0].code, 'CLEAR-BROKER-FEE-40');
      expect(list[1].code, 'PORT-STORAGE');
      expect(list[1].category, 'Port & Handling');
    });

    test('ExpenseCatalogNotifier createItem adds newly created item to state', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:28080/api/v1'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        if (options.method == 'POST') {
          final data = options.data as Map<String, dynamic>;
          return {
            'status': 201,
            'data': {
              'code': data['code'],
              'canonical_name_ar': data['canonical_name_ar'],
              'category': data['category'],
              'unit_type': data['unit_type'],
              'allow_composite': false,
              'recognition_patterns': [data['canonical_name_ar']],
              'is_active': true,
            },
          };
        }
        return {'status': 200, 'data': []};
      });

      final notifier = ExpenseCatalogNotifier(dio);
      final created = await notifier.createItem({
        'code': 'OTHER-SPECIAL-TEST',
        'canonical_name_ar': 'بند اختباري جديد',
        'category': 'Other Fees',
        'unit_type': 'fixed',
      });

      expect(created, isNotNull);
      expect(created!.code, 'OTHER-SPECIAL-TEST');
      expect(created.canonicalNameAr, 'بند اختباري جديد');

      final list = notifier.state.value!;
      expect(list.any((item) => item.code == 'OTHER-SPECIAL-TEST'), true);
    });

    test('ExpenseCatalogNotifier addPattern calls API and refreshes catalog', () async {
      int fetchCalls = 0;
      bool patternAdded = false;

      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:28080/api/v1'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        if (options.method == 'POST' && options.path.contains('/patterns')) {
          patternAdded = true;
          return {
            'status': 200,
            'data': {'status': 'success', 'code': 'PORT-STORAGE', 'pattern': 'أرضية ميناء الدخيلة'},
          };
        }
        fetchCalls++;
        return {
          'status': 200,
          'data': [
            {
              'code': 'PORT-STORAGE',
              'canonical_name_ar': 'أرضيات وغرامات الميناء',
              'category': 'Port & Handling',
              'unit_type': 'fixed',
              'allow_composite': false,
              'recognition_patterns': ['أرضيات', if (patternAdded) 'أرضية ميناء الدخيلة'],
              'is_active': true,
            }
          ],
        };
      });

      final notifier = ExpenseCatalogNotifier(dio);
      final success = await notifier.addPattern('PORT-STORAGE', 'أرضية ميناء الدخيلة');

      expect(success, true);
      expect(patternAdded, true);
      expect(fetchCalls >= 2, true);

      final list = notifier.state.value!;
      expect(list.first.recognitionPatterns.contains('أرضية ميناء الدخيلة'), true);
    });
  });
}
