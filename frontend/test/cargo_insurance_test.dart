import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/cargo_insurance/models/cargo_insurance_model.dart';

void main() {
  group('Cargo Insurance Frontend Model & Valuation Tests', () {
    test('CargoInsuranceModel serialization and default values', () {
      final json = {
        'certificate_id': 101,
        'certificate_code': 'INS-2026-00001',
        'policy_number': 'POL-EGY-99120',
        'policy_type': 'SPECIFIC',
        'insured_entity_name': 'Sorour International Trading',
        'transport_mode': 'OCEAN',
        'carrier_name': 'Hapag-Lloyd',
        'vessel_or_flight_no': 'AL JASRAH',
        'voyage_number': 'V.2026W',
        'tracking_reference': 'HLCU1298401',
        'port_of_loading': 'Hamburg, Germany',
        'port_of_discharge': 'Alexandria Port, Egypt',
        'currency': 'EUR',
        'exchange_rate': 52.80,
        'invoice_value': 120000.0,
        'freight_cost': 6000.0,
        'other_logistics_costs': 1500.0,
        'cif_value': 127500.0,
        'markup_percentage': 0.10,
        'insured_value': 140250.0,
        'coverage_clause': 'ICC_A',
        'include_war_and_strikes': true,
        'base_rate': 0.0025,
        'war_rate': 0.0005,
        'base_premium': 350.63,
        'war_strikes_premium': 70.13,
        'minimum_premium': 30.0,
        'net_premium': 420.76,
        'issuance_fee': 15.0,
        'tax_rate': 0.05,
        'tax_amount': 21.79,
        'total_payable_premium': 457.55,
        'goods_description': 'Electrical Transformers & Distribution Panels',
        'package_count': 32,
        'package_type': 'Wooden Crates',
        'gross_weight_kg': 18500.0,
        'status': 'ISSUED',
        'created_at': '2026-08-25T10:00:00Z',
        'updated_at': '2026-08-25T10:30:00Z',
      };

      final model = CargoInsuranceModel.fromJson(json);

      expect(model.certificateId, 101);
      expect(model.certificateCode, 'INS-2026-00001');
      expect(model.insuredEntityName, 'Sorour International Trading');
      expect(model.cifValue, 127500.0);
      expect(model.insuredValue, 140250.0);
      expect(model.coverageClause, 'ICC_A');
      expect(model.totalPayablePremium, 457.55);
      expect(model.status, 'ISSUED');

      final serialized = model.toJson();
      expect(serialized['certificate_code'], 'INS-2026-00001');
      expect(serialized['insured_value'], 140250.0);
    });

    test('InsuranceCalculationResultModel parsing', () {
      final json = {
        'cif_value': 50000.0,
        'markup_percentage': 0.10,
        'insured_value': 55000.0,
        'coverage_clause': 'AIR_ALL_RISKS',
        'base_rate': 0.0020,
        'base_premium': 110.0,
        'war_rate': 0.0005,
        'war_strikes_premium': 27.5,
        'net_premium': 137.5,
        'issuance_fee': 15.0,
        'tax_rate': 0.05,
        'tax_amount': 7.63,
        'total_payable_premium': 160.13,
        'currency': 'USD',
      };

      final calc = InsuranceCalculationResultModel.fromJson(json);
      expect(calc.cifValue, 50000.0);
      expect(calc.insuredValue, 55000.0);
      expect(calc.coverageClause, 'AIR_ALL_RISKS');
      expect(calc.totalPayablePremium, 160.13);
      expect(calc.currency, 'USD');
    });
  });
}
