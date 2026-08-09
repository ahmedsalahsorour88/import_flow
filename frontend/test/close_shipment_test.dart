import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';

void main() {
  group('Early Shipment Closure Unit Tests', () {
    test('Should parse closureReason and closedAtPhase from JSON correctly', () {
      final json = {
        'import_file_id': 50,
        'import_file_code': 'IMP-FILE-2026-0050',
        'company_name': 'Gamma Imports Ltd',
        'supplier_name': 'Shanghai Export Co',
        'current_module': 'Phase 10 - Import File Closure & Historical Archive',
        'current_stage': 'Closed at Phase 3 - Import Documentation - Supplier Cancelled Order',
        'progress_percent': 100.0,
        'next_action': 'File Closed Early at Phase 3 - Import Documentation',
        'status': 'Closed',
        'owner': 'Kamal',
        'closure_reason': 'Supplier Cancelled Order due to raw material shortage',
        'closed_at_phase': 'Phase 3 - Import Documentation',
        'is_active': true,
        'created_at': '2026-08-09T15:00:00Z',
        'updated_at': '2026-08-09T15:00:00Z',
      };

      final model = ImportFileModel.fromJson(json);

      expect(model.status, 'Closed');
      expect(model.progressPercent, 100.0);
      expect(model.closureReason, 'Supplier Cancelled Order due to raw material shortage');
      expect(model.closedAtPhase, 'Phase 3 - Import Documentation');
      expect(model.currentModule, 'Phase 10 - Import File Closure & Historical Archive');
    });
  });
}
