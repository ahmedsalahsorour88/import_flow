import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/audit_logs/models/audit_log_model.dart';

void main() {
  group('AuditLogModel Unit Tests', () {
    test('fromJson should parse audit log fields accurately', () {
      final json = {
        'log_id': 1,
        'entity_type': 'Supplier',
        'entity_id': 5,
        'entity_code': 'SUP-000005',
        'action': 'UPDATE',
        'changes_summary': "Updated address from 'Old' to 'New'",
        'old_values': '{"address": "Old"}',
        'new_values': '{"address": "New"}',
        'performed_at': '2026-08-07T23:00:00Z',
        'performed_by': 'Admin User',
      };

      final model = AuditLogModel.fromJson(json);

      expect(model.logId, equals(1));
      expect(model.entityType, equals('Supplier'));
      expect(model.entityId, equals(5));
      expect(model.entityCode, equals('SUP-000005'));
      expect(model.action, equals('UPDATE'));
      expect(model.changesSummary, contains('Updated address'));
      expect(model.performedBy, equals('Admin User'));
    });

    test('toJson should serialize properties correctly', () {
      final model = AuditLogModel(
        logId: 2,
        entityType: 'ImportCompany',
        entityId: 10,
        entityCode: 'IMP-100200',
        action: 'CREATE',
        changesSummary: 'Created new ImportCompany record',
        performedAt: DateTime.parse('2026-08-07T23:05:00Z'),
        performedBy: 'System Admin',
      );

      final json = model.toJson();

      expect(json['log_id'], equals(2));
      expect(json['entity_type'], equals('ImportCompany'));
      expect(json['action'], equals('CREATE'));
      expect(json['performed_by'], equals('System Admin'));
    });
  });
}
