import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/shipping_scenarios/models/shipping_scenario_model.dart';

void main() {
  group('ShippingScenarioItemModel Unit Tests (BP-007/8)', () {
    test('fromJson and toCreateJson should parse and serialize DTHC and Storage fields', () {
      final json = {
        'provider_name': 'Maersk Line',
        'vessel_name': 'MAERSK MC-KINNEY',
        'sailing_date': '2026-09-01',
        'estimated_arrival_date': '2026-09-25',
        'free_time_days': 14,
        'quotation_currency': 'USD',
        'total_quotation_amount': 3200.0,
        'dthc_applicable': true,
        'dthc_price': 400.0,
        'dthc_currency': 'USD',
        'storage_per_week_applicable': true,
        'storage_per_week_price': 150.0,
        'storage_per_week_currency': 'USD',
        'extra_day_storage_applicable': true,
        'extra_day_storage_price': 25.0,
        'extra_day_storage_currency': 'USD',
      };

      final model = ShippingScenarioItemModel.fromJson(json);

      expect(model.providerName, 'Maersk Line');
      expect(model.dthcApplicable, isTrue);
      expect(model.dthcPrice, 400.0);
      expect(model.dthcCurrency, 'USD');
      expect(model.storagePerWeekApplicable, isTrue);
      expect(model.storagePerWeekPrice, 150.0);
      expect(model.storagePerWeekCurrency, 'USD');
      expect(model.extraDayStorageApplicable, isTrue);
      expect(model.extraDayStoragePrice, 25.0);
      expect(model.extraDayStorageCurrency, 'USD');

      final serialized = model.toCreateJson();
      expect(serialized['dthc_applicable'], isTrue);
      expect(serialized['dthc_price'], 400.0);
      expect(serialized['dthc_currency'], 'USD');
      expect(serialized['storage_per_week_applicable'], isTrue);
      expect(serialized['storage_per_week_price'], 150.0);
      expect(serialized['storage_per_week_currency'], 'USD');
      expect(serialized['extra_day_storage_applicable'], isTrue);
      expect(serialized['extra_day_storage_price'], 25.0);
      expect(serialized['extra_day_storage_currency'], 'USD');
    });

    test('ShippingEvaluationModel parses session and items correctly for prefilling on edit', () {
      final sessionJson = {
        'session_id': 42,
        'session_code': 'SCE-2026-001',
        'title': 'Red Sea Route Evaluation Study',
        'cargo_ready_date': '2026-09-10',
        'pick_up_address': 'Factory 9, Ningbo',
        'avg_form4_days': 4,
        'avg_clearance_days': 6,
        'import_file_id': 10,
        'po_id': 5,
        'project_id': 2,
        'is_active': false, // was soft-deleted
        'items': [
          {
            'item_id': 101,
            'provider_name': 'CMA CGM',
            'vessel_name': 'CMA CGM CONCORDE',
            'voyage_number': 'CC-09',
            'sailing_date': '2026-09-15',
            'estimated_arrival_date': '2026-10-05',
            'free_time_days': 21,
            'quotation_currency': 'USD',
            'total_quotation_amount': 2800.0,
            'container_40ft_applicable': true,
            'container_40ft_price': 2800.0,
            'container_40ft_qty': 1,
            'is_recommended': true,
          }
        ]
      };

      final session = ShippingEvaluationModel.fromJson(sessionJson);

      expect(session.sessionId, 42);
      expect(session.sessionCode, 'SCE-2026-001');
      expect(session.title, 'Red Sea Route Evaluation Study');
      expect(session.cargoReadyDate, '2026-09-10');
      expect(session.pickUpAddress, 'Factory 9, Ningbo');
      expect(session.avgForm4Days, 4);
      expect(session.avgClearanceDays, 6);
      expect(session.importFileId, 10);
      expect(session.poId, 5);
      expect(session.projectId, 2);
      expect(session.isActive, isFalse);
      expect(session.items.length, 1);
      expect(session.items.first.providerName, 'CMA CGM');
      expect(session.items.first.vesselName, 'CMA CGM CONCORDE');
      expect(session.items.first.voyageNumber, 'CC-09');
      expect(session.items.first.freeTimeDays, 21);
      expect(session.items.first.container40ftApplicable, isTrue);
      expect(session.items.first.container40ftPrice, 2800.0);
    });
  });
}
