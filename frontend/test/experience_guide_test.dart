import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/experience_guide/models/guide_entry_model.dart';
import 'package:frontend/features/experience_guide/models/smart_reference_card_model.dart';

void main() {
  group('GuideEntryModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'entry_id': 1,
        'title': 'شهادة المنشأ إلزامية للأكوستيك',
        'content': 'لازم تجيب COO من الصين قبل شحن HS 8520',
        'entry_type': 'required_document',
        'severity': 'critical',
        'created_by': 'System',
        'created_at': '2026-09-10T10:00:00',
        'updated_at': '2026-09-10T10:00:00',
        'is_active': true,
        'scopes': [
          {'scope_type': 'hs_code', 'scope_value': '8520'},
          {'scope_type': 'destination_port', 'scope_value': 'الإسكندرية'},
        ],
      };

      final entry = GuideEntryModel.fromJson(json);

      expect(entry.entryId, equals(1));
      expect(entry.title, equals('شهادة المنشأ إلزامية للأكوستيك'));
      expect(entry.severity, equals('critical'));
      expect(entry.entryType, equals('required_document'));
      expect(entry.isActive, isTrue);
      expect(entry.scopes.length, equals(2));
      expect(entry.scopes.first.scopeType, equals('hs_code'));
      expect(entry.scopes.first.scopeValue, equals('8520'));
    });

    test('fromJson handles missing optional fields gracefully', () {
      final json = {
        'entry_id': 5,
        'title': 'تنبيه',
        'content': 'محتوى',
      };

      final entry = GuideEntryModel.fromJson(json);

      expect(entry.entryId, equals(5));
      expect(entry.severity, equals('info'));
      expect(entry.entryType, equals('alert'));
      expect(entry.scopes, isEmpty);
      expect(entry.isActive, isTrue);
    });

    test('toJson serializes correctly', () {
      final entry = GuideEntryModel(
        entryId: 2,
        title: 'اختبار',
        content: 'محتوى اختبار',
        severity: 'warning',
        entryType: 'task',
      );

      final json = entry.toJson();

      expect(json['entry_id'], equals(2));
      expect(json['title'], equals('اختبار'));
      expect(json['severity'], equals('warning'));
      expect(json['entry_type'], equals('task'));
    });
  });

  group('GuideScopeModel', () {
    test('fromJson parses scope correctly', () {
      final json = {
        'scope_id': 10,
        'guide_entry_id': 1,
        'scope_type': 'hs_code',
        'scope_value': '8520',
      };

      final scope = GuideScopeModel.fromJson(json);

      expect(scope.scopeId, equals(10));
      expect(scope.guideEntryId, equals(1));
      expect(scope.scopeType, equals('hs_code'));
      expect(scope.scopeValue, equals('8520'));
    });

    test('toJson omits null ids', () {
      final scope = GuideScopeModel(
        scopeType: 'destination_port',
        scopeValue: 'الإسكندرية',
      );

      final json = scope.toJson();

      expect(json.containsKey('scope_id'), isFalse);
      expect(json['scope_type'], equals('destination_port'));
      expect(json['scope_value'], equals('الإسكندرية'));
    });
  });

  group('GuideMatchResultModel', () {
    test('empty result has no matches', () {
      final result = GuideMatchResultModel();
      expect(result.matchedEntries, isEmpty);
      expect(result.hasCriticalAlert, isFalse);
      expect(result.hasWarningAlert, isFalse);
    });

    test('fromJson with matched entries', () {
      final json = {
        'matched_entries': [
          {
            'entry_id': 1,
            'title': 'شهادة المنشأ',
            'content': 'COO إلزامية',
            'severity': 'critical',
            'entry_type': 'required_document',
            'created_by': 'System',
            'created_at': '',
            'updated_at': '',
            'is_active': true,
            'scopes': [],
          }
        ],
        'has_critical_alert': true,
        'has_warning_alert': false,
        'mandatory_ports': [],
        'required_documents': ['COO'],
        'suggested_notes': [],
      };

      final result = GuideMatchResultModel.fromJson(json);

      expect(result.matchedEntries.length, equals(1));
      expect(result.hasCriticalAlert, isTrue);
      expect(result.matchedEntries.first.severity, equals('critical'));
    });
  });

  group('SmartReferenceCardModel', () {
    test('helper getters extract from nested maps correctly', () {
      final model = SmartReferenceCardModel(
        importFileId: 100,
        importFileCode: 'IMP-000100',
        productSummary: {
          'hs_code': '8520',
          'product_category': 'أجهزة صوتية',
          'total_cbm': 14.5,
          'total_gross_weight_kg': 2300.0,
          'packages_count': 45,
        },
        routeSummary: {
          'origin_port': 'Shanghai',
          'destination_port': 'El Dekheila Port',
          'shipping_line': 'MSC',
        },
        costSummary: {
          'estimated_cost': 85000.0,
          'actual_invoiced_cost': 82000.0,
          'variance_amount': -3000.0,
          'variance_percentage': -3.53,
          'currency': 'USD',
        },
        documentStatus: {
          'is_complete': false,
          'has_coo_attached': true,
          'is_coo_required': true,
          'pending_documents': ['BL', 'Packing List'],
        },
      );

      expect(model.hsCode, equals('8520'));
      expect(model.productCategory, equals('أجهزة صوتية'));
      expect(model.totalCbm, closeTo(14.5, 0.001));
      expect(model.packagesCount, equals(45));
      expect(model.originPort, equals('Shanghai'));
      expect(model.destinationPort, equals('El Dekheila Port'));
      expect(model.carrier, equals('MSC'));
      expect(model.estimatedCost, closeTo(85000.0, 0.01));
      expect(model.actualCost, closeTo(82000.0, 0.01));
      expect(model.variancePercentage, closeTo(-3.53, 0.001));
      expect(model.currency, equals('USD'));
      expect(model.isDocsComplete, isFalse);
      expect(model.hasCooAttached, isTrue);
      expect(model.pendingDocuments, containsAll(['BL', 'Packing List']));
    });

    test('fromJson parses API response correctly', () {
      final json = {
        'import_file_id': 42,
        'import_file_code': 'IMP-000042',
        'custom_file_number': 'CF-2026-001',
        'product_summary': {'hs_code': '8520', 'total_cbm': 10.0},
        'route_summary': {'destination_port': 'الإسكندرية'},
        'critical_dates': {'target_free_days': 14},
        'document_status': {'is_complete': true, 'has_coo_attached': false},
        'matched_guide_entries': [],
        'cost_summary': {'estimated_cost': 50000.0, 'currency': 'USD'},
      };

      final model = SmartReferenceCardModel.fromJson(json);

      expect(model.importFileId, equals(42));
      expect(model.importFileCode, equals('IMP-000042'));
      expect(model.customFileNumber, equals('CF-2026-001'));
      expect(model.freeDays, equals(14));
      expect(model.isDocsComplete, isTrue);
      expect(model.matchedGuideEntries, isEmpty);
    });
  });
}
