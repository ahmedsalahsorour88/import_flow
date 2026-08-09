import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/operational_dashboard/models/operational_dashboard_model.dart';

void main() {
  group('OperationalDashboardModel Unit Tests (Feature 2.9)', () {
    test('Should parse OperationalDashboardData from JSON correctly', () {
      final json = {
        'shipment_count': 3,
        'last_updated_at': '2026-08-09T14:00:00Z',
        'available_brokers': [
          {'broker_id': 1, 'broker_name': 'Al-Ameen Customs Clearance'},
          {'broker_id': 2, 'broker_name': 'El-Nasr Logistics'},
        ],
        'phase_counts': {
          'Phase 1': 2,
          'Phase 2': 1,
          'Phase 5': 4,
          'Phase 7': 1,
        },
        'shipments': [
          {
            'import_file_id': 1,
            'import_file_code': 'IMP-2026-0001',
            'company_name': 'Alpha Import Ltd',
            'supplier_name': 'Sino Tech Ltd',
            'broker_name': 'Al-Ameen Customs Clearance',
            'priority': 'High',
            'current_module': 'Phase 7 - Customs Clearance',
            'current_stage': 'Duty Payment Requested',
            'progress_percent': 70.0,
            'next_action': 'Pay Duties',
            'is_active': true,
            'created_at': '2026-08-09T10:00:00Z',
            'updated_at': '2026-08-09T10:00:00Z',
          }
        ],
      };

      final data = OperationalDashboardData.fromJson(json);

      expect(data.shipmentCount, 3);
      expect(data.availableBrokers.length, 2);
      expect(data.availableBrokers.first.brokerName, 'Al-Ameen Customs Clearance');
      expect(data.phaseCounts['Phase 5'], 4);
      expect(data.shipments.length, 1);
      expect(data.shipments.first.importFileCode, 'IMP-2026-0001');
    });

    test('DashboardBroker JSON serialization test', () {
      final broker = DashboardBroker(brokerId: 5, brokerName: 'Global Cargo Express');
      final json = broker.toJson();

      expect(json['broker_id'], 5);
      expect(json['broker_name'], 'Global Cargo Express');
    });
  });
}
