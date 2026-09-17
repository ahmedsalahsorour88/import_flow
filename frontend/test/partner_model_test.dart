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
        'default_free_days': 14,
        'tracking_url': 'https://www.msc.com/track/',
        'country': 'Switzerland',
        'is_active': true,
      };

      final model = PartnerModel.fromJson(json);

      expect(model.providerId, 12);
      expect(model.partnerCode, 'ESP-000012');
      expect(model.partnerType, 'Shipping Line');
      expect(model.scacCode, 'MSCU');
      expect(model.defaultFreeDays, 14);
      expect(model.country, 'Switzerland');
    });

    test('fromJson should parse freight forwarder partner fields correctly (MD-05)', () {
      final json = {
        'provider_id': 18,
        'partner_code': 'ESP-000018',
        'partner_name': 'Apex Global Freight Logistics',
        'partner_type': 'Freight Forwarder',
        'fiata_id': 'FIATA-EG-7721',
        'shipping_modes': 'Sea FCL, Sea LCL, Air Freight',
        'supported_currencies': 'USD, EUR, EGP',
        'contact_person': 'Tamer Salem',
        'email': 'pricing@apexfreight.com',
        'country': 'Egypt',
        'is_active': true,
      };

      final model = PartnerModel.fromJson(json);

      expect(model.providerId, 18);
      expect(model.partnerCode, 'ESP-000018');
      expect(model.partnerName, 'Apex Global Freight Logistics');
      expect(model.partnerType, 'Freight Forwarder');
      expect(model.fiataId, 'FIATA-EG-7721');
      expect(model.shippingModes, 'Sea FCL, Sea LCL, Air Freight');
      expect(model.supportedCurrencies, 'USD, EUR, EGP');
      expect(model.email, 'pricing@apexfreight.com');
    });

    test('fromJson should parse inspection agency partner fields correctly (MD-06)', () {
      final json = {
        'provider_id': 22,
        'partner_code': 'ESP-000022',
        'partner_name': 'SGS Inspection Services Egypt',
        'partner_type': 'Inspection Agency',
        'inspection_accreditation_number': 'GOIEC-EG-9001',
        'inspection_scope': 'Pre-shipment Inspection, CoC/VOC, Food, Machinery',
        'contact_person': 'Dr. Hesham Kamal',
        'email': 'egypt.inspection@sgs.com',
        'country': 'Egypt',
        'is_active': true,
      };

      final model = PartnerModel.fromJson(json);

      expect(model.providerId, 22);
      expect(model.partnerCode, 'ESP-000022');
      expect(model.partnerName, 'SGS Inspection Services Egypt');
      expect(model.partnerType, 'Inspection Agency');
      expect(model.inspectionAccreditationNumber, 'GOIEC-EG-9001');
      expect(model.inspectionScope, 'Pre-shipment Inspection, CoC/VOC, Food, Machinery');
      expect(model.email, 'egypt.inspection@sgs.com');
    });

    test('fromJson should parse customs broker partner fields correctly (MD-07)', () {
      final json = {
        'provider_id': 25,
        'partner_code': 'ESP-000025',
        'partner_name': 'Alexandria Express Customs Clearance',
        'partner_type': 'Customs Broker',
        'clearance_license_number': 'LIC-ALX-9988',
        'authorized_ports': 'Alexandria, Port Said, Damietta, Ain Sokhna',
        'contact_person': 'Mahmoud El-Sayed',
        'email': 'customs@alexexpress.com',
        'country': 'Egypt',
        'is_active': true,
      };

      final model = PartnerModel.fromJson(json);

      expect(model.providerId, 25);
      expect(model.partnerCode, 'ESP-000025');
      expect(model.partnerName, 'Alexandria Express Customs Clearance');
      expect(model.partnerType, 'Customs Broker');
      expect(model.clearanceLicenseNumber, 'LIC-ALX-9988');
      expect(model.authorizedPorts, 'Alexandria, Port Said, Damietta, Ain Sokhna');
      expect(model.email, 'customs@alexexpress.com');
    });

    test('fromJson should parse inland transport partner fields correctly (MD-08)', () {
      final json = {
        'provider_id': 30,
        'partner_code': 'ESP-000030',
        'partner_name': 'Nile Express Inland Logistics',
        'partner_type': 'Inland Transport',
        'transport_license_number': 'MOT-EG-5566',
        'fleet_types': '20/40ft Flatbed, Lowbed, Reefer Trucks',
        'coverage_areas': 'Alexandria, Damietta, Sokhna, 6th of October',
        'contact_person': 'Hany Mansour',
        'email': 'logistics@nileexpress.eg',
        'country': 'Egypt',
        'is_active': true,
      };

      final model = PartnerModel.fromJson(json);

      expect(model.providerId, 30);
      expect(model.partnerCode, 'ESP-000030');
      expect(model.partnerName, 'Nile Express Inland Logistics');
      expect(model.partnerType, 'Inland Transport');
      expect(model.transportLicenseNumber, 'MOT-EG-5566');
      expect(model.fleetTypes, '20/40ft Flatbed, Lowbed, Reefer Trucks');
      expect(model.coverageAreas, 'Alexandria, Damietta, Sokhna, 6th of October');
      expect(model.email, 'logistics@nileexpress.eg');
    });

    test('fromJson should parse insurance company partner fields correctly (MD-08)', () {
      final json = {
        'provider_id': 35,
        'partner_code': 'ESP-000035',
        'partner_name': 'Delta Marine Insurance Corp',
        'partner_type': 'Insurance Company',
        'insurance_license_number': 'FRA-INS-991',
        'insurance_coverage_types': 'Institute Cargo Clauses (A/B/C), War & Strikes',
        'contact_person': 'Nader Shaker',
        'email': 'underwriting@deltamarine.eg',
        'country': 'Egypt',
        'is_active': true,
      };

      final model = PartnerModel.fromJson(json);

      expect(model.providerId, 35);
      expect(model.partnerCode, 'ESP-000035');
      expect(model.partnerName, 'Delta Marine Insurance Corp');
      expect(model.partnerType, 'Insurance Company');
      expect(model.insuranceLicenseNumber, 'FRA-INS-991');
      expect(model.insuranceCoverageTypes, 'Institute Cargo Clauses (A/B/C), War & Strikes');
      expect(model.email, 'underwriting@deltamarine.eg');
    });

    test('toJson should serialize properties accurately', () {
      final model = PartnerModel(
        providerId: 15,
        partnerCode: 'ESP-000015',
        partnerName: 'Pharaohs Customs Clearance',
        partnerType: 'Customs Broker',
        clearanceLicenseNumber: 'LIC-CAI-7744',
        authorizedPorts: 'Alexandria, Port Said, Damietta',
        transportLicenseNumber: 'MOT-EG-9988',
        fleetTypes: '20/40ft Flatbed, Lowbed',
        coverageAreas: 'Alexandria, Cairo',
        insuranceLicenseNumber: 'FRA-INS-505',
        insuranceCoverageTypes: 'All Risks (Clause A)',
        defaultFreeDays: 21,
        fiataId: 'FIATA-EG-8822',
        shippingModes: 'Sea FCL, Air',
        supportedCurrencies: 'USD, EUR',
        inspectionAccreditationNumber: 'GOIEC-EG-9001',
        inspectionScope: 'CoC/VOC Testing',
      );

      final json = model.toJson();

      expect(json['provider_id'], 15);
      expect(json['partner_code'], 'ESP-000015');
      expect(json['partner_name'], 'Pharaohs Customs Clearance');
      expect(json['clearance_license_number'], 'LIC-CAI-7744');
      expect(json['authorized_ports'], 'Alexandria, Port Said, Damietta');
      expect(json['transport_license_number'], 'MOT-EG-9988');
      expect(json['fleet_types'], '20/40ft Flatbed, Lowbed');
      expect(json['coverage_areas'], 'Alexandria, Cairo');
      expect(json['insurance_license_number'], 'FRA-INS-505');
      expect(json['insurance_coverage_types'], 'All Risks (Clause A)');
      expect(json['default_free_days'], 21);
      expect(json['fiata_id'], 'FIATA-EG-8822');
      expect(json['shipping_modes'], 'Sea FCL, Air');
      expect(json['supported_currencies'], 'USD, EUR');
      expect(json['inspection_accreditation_number'], 'GOIEC-EG-9001');
      expect(json['inspection_scope'], 'CoC/VOC Testing');
    });
  });
}
