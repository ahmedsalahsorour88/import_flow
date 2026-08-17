import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/lifecycle_board/models/lifecycle_board_model.dart';

void main() {
  group('Lifecycle Board Model Tests', () {
    test('PhaseSummaryModel and LifecycleBoardSummaryModel JSON parsing', () {
      final json = {
        'phases': [
          {
            'phase_id': 1,
            'title_en': '1. Pre-Planning & Studies',
            'title_ar': 'المرحلة الأولى: التخطيط والدراسات المسبقة',
            'color_hex': '#D97706',
            'step_codes': ['STEP_01', 'STEP_02', 'STEP_03'],
            'total_active_shipments': 2,
            'step_counts': {'STEP_01': 1, 'STEP_02': 1, 'STEP_03': 0},
          }
        ],
        'total_active_files': 1,
        'all_shipments': [
          {
            'import_file_code': 'IMP-2026-0001',
            'company_name': 'Al-Ahram Industrial',
            'supplier_name': 'Global Steel Italy',
            'po_number': 'PO-2026-101',
            'shipment_mode': 'Sea FCL',
            'incoterm_code': 'FOB',
            'priority': 'High',
            'estimated_cost': 45000.0,
            'estimated_cost_currency': 'USD',
            'step_code': 'STEP_01',
            'step_name_en': 'Freight Studies',
            'step_name_ar': 'دراسات ومفاضلة نولون الشحن',
            'status': 'In-Progress',
            'started_at': '2026-08-17 12:00:00',
            'notes': 'Comparing freight rates',
          }
        ],
      };

      final model = LifecycleBoardSummaryModel.fromJson(json);
      expect(model.phases.length, 1);
      expect(model.phases[0].phaseId, 1);
      expect(model.phases[0].totalActiveShipments, 2);
      expect(model.totalActiveFiles, 1);
      expect(model.allShipments.length, 1);
      expect(model.allShipments[0].importFileCode, 'IMP-2026-0001');
      expect(model.allShipments[0].estimatedCost, 45000.0);
    });
  });
}
