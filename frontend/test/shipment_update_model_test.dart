import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/shipment_updates/models/shipment_update_model.dart';

void main() {
  group('ShipmentUpdateLogModel Unit Tests', () {
    test('Should parse ShipmentUpdateLogModel from JSON correctly', () {
      final json = {
        'update_id': 1,
        'update_code': 'UPD-2026-00001',
        'import_file_id': 10,
        'import_file_code': 'IMP-2026-010',
        'update_category': 'Phase Cost Adjustment',
        'target_phase': 'Phase 4',
        'phase_status': 'Current',
        'log_date': '2026-08-13',
        'note': 'تعديل تكلفة النولون البحري للحاوية',
        'adjusted_cost_item': 'Freight Fee',
        'previous_cost': 2500.0,
        'new_cost': 2800.0,
        'alert_priority': 'High',
        'assigned_user': 'Kamal',
        'is_active': true,
        'created_at': '2026-08-13T12:00:00',
        'created_by': 'Kamal',
      };

      final model = ShipmentUpdateLogModel.fromJson(json);

      expect(model.updateId, equals(1));
      expect(model.updateCode, equals('UPD-2026-00001'));
      expect(model.updateCategory, equals('Phase Cost Adjustment'));
      expect(model.targetPhase, equals('Phase 4'));
      expect(model.adjustedCostItem, equals('Freight Fee'));
      expect(model.previousCost, equals(2500.0));
      expect(model.newCost, equals(2800.0));
    });

    test('Should parse PhaseInspectionModel from JSON correctly', () {
      final json = {
        'phase_code': 'Phase 4',
        'phase_name': 'P4: حجز الشحن والناقل',
        'phase_number': 4,
        'status': 'Current',
        'completion_date': '2026-08-13',
        'last_note': 'تم تأكيد حجز الحاوية',
        'update_count': 3,
      };

      final insp = PhaseInspectionModel.fromJson(json);

      expect(insp.phaseCode, equals('Phase 4'));
      expect(insp.phaseName, equals('P4: حجز الشحن والناقل'));
      expect(insp.phaseNumber, equals(4));
      expect(insp.status, equals('Current'));
      expect(insp.updateCount, equals(3));
    });
  });
}
