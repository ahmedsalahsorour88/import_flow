import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/file_closure/models/file_closure_model.dart';

void main() {
  group('ImportFileClosureModel Unit Tests (Phase 10)', () {
    test('Should parse ImportFileClosureModel from JSON correctly', () {
      final json = {
        'closure_id': 401,
        'closure_code': 'CLR-2026-0001',
        'import_file_id': 20,
        'closure_checklist': {
          'docs_verified': true,
          'customs_cleared': true,
          'warehouse_received': true,
          'landed_cost_settled': true,
          'tasks_closed': true,
        },
        'auditor_name': 'Hatem Auditor',
        'archive_location': 'Digital Vault 2026',
        'archival_notes': 'Successfully archived file.',
        'status': 'Closed',
        'is_active': true,
        'closed_at': '2026-08-09T16:00:00Z',
        'created_at': '2026-08-09T16:00:00Z',
        'updated_at': '2026-08-09T16:00:00Z',
      };

      final model = ImportFileClosureModel.fromJson(json);

      expect(model.closureId, 401);
      expect(model.closureCode, 'CLR-2026-0001');
      expect(model.importFileId, 20);
      expect(model.auditorName, 'Hatem Auditor');
      expect(model.closureChecklist.isAllCompleted, isTrue);
      expect(model.status, 'Closed');
    });

    test('Should serialize ImportFileClosureModel to JSON correctly', () {
      final chk = ClosureChecklistModel(
        docsVerified: true,
        customsCleared: true,
        warehouseReceived: true,
        landedCostSettled: true,
        tasksClosed: true,
      );

      final model = ImportFileClosureModel(
        closureId: 402,
        closureCode: 'CLR-2026-0002',
        importFileId: 22,
        closureChecklist: chk,
        auditorName: 'Senior Auditor',
        archiveLocation: 'Server Vault A',
        closedAt: '2026-08-09T16:00:00Z',
        createdAt: '2026-08-09T16:00:00Z',
        updatedAt: '2026-08-09T16:00:00Z',
      );

      final json = model.toJson();

      expect(json['closure_code'], 'CLR-2026-0002');
      expect(json['import_file_id'], 22);
      expect((json['closure_checklist'] as Map)['docs_verified'], isTrue);
    });
  });
}
