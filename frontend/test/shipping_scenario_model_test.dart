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
  });
}
