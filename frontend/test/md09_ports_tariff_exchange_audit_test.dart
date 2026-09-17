import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/transport_locations/models/transport_location_model.dart';
import 'package:frontend/features/customs_tariff/models/customs_tariff_model.dart';
import 'package:frontend/features/currencies/models/currency_model.dart';

void main() {
  group('MD-09: Ports, Tariff & Exchange Rates Readiness Audit Tests', () {
    test('TransportLocationModel should parse Egyptian and international ports with correct types', () {
      final alexandriaJson = {
        'location_id': 1,
        'un_locode': 'EGALY',
        'location_name': 'Alexandria Port',
        'location_type': 'Sea Port',
        'country': 'Egypt',
        'city': 'Alexandria',
        'is_active': true,
      };

      final cairoAirJson = {
        'location_id': 2,
        'un_locode': 'EGCAI',
        'location_name': 'Cairo International Airport',
        'location_type': 'Airport',
        'country': 'Egypt',
        'city': 'Cairo',
        'is_active': true,
      };

      final shanghaiJson = {
        'location_id': 3,
        'un_locode': 'CNSHA',
        'location_name': 'Shanghai Port',
        'location_type': 'Sea Port',
        'country': 'China',
        'city': 'Shanghai',
        'is_active': true,
      };

      final alexLoc = TransportLocationModel.fromJson(alexandriaJson);
      final cairoLoc = TransportLocationModel.fromJson(cairoAirJson);
      final shanghaiLoc = TransportLocationModel.fromJson(shanghaiJson);

      expect(alexLoc.unLocode, 'EGALY');
      expect(alexLoc.locationType, 'Sea Port');
      expect(alexLoc.country, 'Egypt');

      expect(cairoLoc.unLocode, 'EGCAI');
      expect(cairoLoc.locationType, 'Airport');

      expect(shanghaiLoc.unLocode, 'CNSHA');
      expect(shanghaiLoc.country, 'China');
    });

    test('CustomsTariffModel should validate Egyptian customs tariff rates, VAT, and exemptions', () {
      final laptopTariffJson = {
        'tariff_id': 1,
        'hs_code': '8471.30.00',
        'hs_description': 'Portable automatic data processing machines (Laptops)',
        'customs_category': 'Electronics',
        'customs_duty_rate': 0.0,
        'vat_rate': 14.0,
        'schedule_tax_rate': 0.0,
        'development_fee_rate': 0.0,
        'import_fee_rate': 0.0,
        'requires_coo': true,
        'requires_inspection': false,
        'requires_acid': true,
        'regulatory_authority': 'NTRA',
        'is_active': true,
      };

      final medTariffJson = {
        'tariff_id': 2,
        'hs_code': '3004.90.90',
        'hs_description': 'Medicaments for therapeutic uses',
        'customs_category': 'Pharmaceuticals',
        'customs_duty_rate': 0.0,
        'vat_rate': 0.0,
        'schedule_tax_rate': 0.0,
        'development_fee_rate': 0.0,
        'import_fee_rate': 0.0,
        'requires_coo': true,
        'requires_inspection': true,
        'requires_acid': true,
        'regulatory_authority': 'EDA',
        'is_active': true,
      };

      final laptopTariff = CustomsTariffModel.fromJson(laptopTariffJson);
      final medTariff = CustomsTariffModel.fromJson(medTariffJson);

      expect(laptopTariff.hsCode, '8471.30.00');
      expect(laptopTariff.customsDutyRate, 0.0);
      expect(laptopTariff.vatRate, 14.0);
      expect(laptopTariff.requiresAcid, isTrue);

      expect(medTariff.hsCode, '3004.90.90');
      expect(medTariff.customsDutyRate, 0.0);
      expect(medTariff.vatRate, 0.0); // Medicines exempt from VAT in Egypt
      expect(medTariff.regulatoryAuthority, 'EDA');
    });

    test('CurrencyModel & ExchangeRateModel should handle commercial and customs rates correctly', () {
      final egpJson = {
        'currency_id': 1,
        'currency_code': 'EGP',
        'currency_name': 'Egyptian Pound',
        'currency_symbol': 'E£',
        'is_base_currency': true,
        'is_active': true,
      };

      final usdRateJson = {
        'rate_id': 10,
        'currency_id': 2,
        'commercial_rate': 48.50,
        'customs_rate': 48.50,
        'effective_date': '2026-09-17',
        'is_active': true,
      };

      final egp = CurrencyModel.fromJson(egpJson);
      final usdRate = ExchangeRateModel.fromJson(usdRateJson);

      expect(egp.currencyCode, 'EGP');
      expect(egp.isBaseCurrency, isTrue);

      expect(usdRate.currencyId, 2);
      expect(usdRate.commercialRate, 48.50);
      expect(usdRate.customsRate, 48.50);
      expect(usdRate.isActive, isTrue);
    });
  });
}
