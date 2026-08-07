import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/external_service_providers/models/partner_model.dart';

void main() {
  group('PartnerModel Unit Tests (MD-003)', () {
    test('fromJson should parse bank partner fields correctly', () {
      final json = {
        'provider_id': 10,
        'partner_code': 'ESP-000010',
        'partner_name': 'Commercial International Bank (CIB)',
        'partner_type': 'Bank',
        'swift_code': 'CIBEGEXX',
        'bank_code': 'CIB',
        'branch_name': 'Zamalek Branch',
        'country': 'Egypt',
        'is_active': true,
      };

      final model = PartnerModel.fromJson(json);

      expect(model.providerId, 10);
      expect(model.partnerCode, 'ESP-000010');
      expect(model.partnerName, 'Commercial International Bank (CIB)');
      expect(model.partnerType, 'Bank');
      expect(model.swiftCode, 'CIBEGEXX');
      expect(model.isActive, true);
    });

    test('fromJson should parse shipping line partner fields correctly', () {
      final json = {
        'provider_id': 12,
        'partner_code': 'ESP-000012',
        'partner_name': 'Mediterranean Shipping Company (MSC)',
        'partner_type': 'Shipping Line',
        'scac_code': 'MSCU',
        'tracking_url': 'https://www.msc.com/track/',
        'country': 'Switzerland',
        'is_active': true,
      };

      final model = PartnerModel.fromJson(json);

      expect(model.providerId, 12);
      expect(model.partnerCode, 'ESP-000012');
      expect(model.partnerType, 'Shipping Line');
      expect(model.scacCode, 'MSCU');
      expect(model.country, 'Switzerland');
    });

    test('toJson should serialize properties accurately', () {
      final model = PartnerModel(
        providerId: 15,
        partnerCode: 'ESP-000015',
        partnerName: 'Pharaohs Customs Clearance',
        partnerType: 'Customs Broker',
        clearanceLicenseNumber: 'LIC-CAI-7744',
      );

      final json = model.toJson();

      expect(json['provider_id'], 15);
      expect(json['partner_code'], 'ESP-000015');
      expect(json['partner_name'], 'Pharaohs Customs Clearance');
      expect(json['clearance_license_number'], 'LIC-CAI-7744');
    });
  });
}
