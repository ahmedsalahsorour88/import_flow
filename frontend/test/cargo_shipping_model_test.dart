import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/cargo_shipping/models/cargo_shipping_model.dart';

void main() {
  group('CargoShippingModel Unit Tests (Phase 5 - Cargo & CargoX)', () {
    test('ContainerLoadingModel fromJson and toJson should parse correctly', () {
      final json = {
        'container_no': 'MSKU1234567',
        'seal_no': 'SL-9988',
        'tare_weight_kg': 2300.0,
        'net_weight_kg': 19000.0,
        'gross_weight_kg': 21300.0,
        'vgm_status': 'Submitted',
        'vgm_ref_no': 'VGM-100200',
      };

      final model = ContainerLoadingModel.fromJson(json);

      expect(model.containerNo, equals('MSKU1234567'));
      expect(model.sealNo, equals('SL-9988'));
      expect(model.grossWeightKg, equals(21300.0));
      expect(model.vgmStatus, equals('Submitted'));

      final map = model.toJson();
      expect(map['container_no'], equals('MSKU1234567'));
      expect(map['vgm_ref_no'], equals('VGM-100200'));
    });

    test('CourierTrackingModel fromJson and toJson should parse correctly', () {
      final json = {
        'courier_provider': 'DHL Express',
        'tracking_number': 'DHL-88776655',
        'dispatch_date': '2026-08-10',
        'receipt_status': 'Dispatched',
        'received_at': null,
        'received_by': null,
      };

      final model = CourierTrackingModel.fromJson(json);

      expect(model.courierProvider, equals('DHL Express'));
      expect(model.trackingNumber, equals('DHL-88776655'));
      expect(model.receiptStatus, equals('Dispatched'));

      final map = model.toJson();
      expect(map['courier_provider'], equals('DHL Express'));
      expect(map['tracking_number'], equals('DHL-88776655'));
    });

    test('CargoXExchangeModel fromJson and toJson should parse verification checklist', () {
      final json = {
        'platform_provider': 'CargoX Platform',
        'envelope_id': 'ENV-CGX-2026-0001',
        'envelope_status': 'Uploaded',
        'blockchain_tx_hash': '0xBC7789A990001FA88321',
        'verification_checklist': [
          {'rule_name': 'ACID Verification', 'passed': true, 'details': 'Verified'},
          {'rule_name': 'Dual Approval', 'passed': true, 'details': 'Approved'},
        ],
      };

      final model = CargoXExchangeModel.fromJson(json);

      expect(model.platformProvider, equals('CargoX Platform'));
      expect(model.envelopeId, equals('ENV-CGX-2026-0001'));
      expect(model.envelopeStatus, equals('Uploaded'));
      expect(model.verificationChecklist.length, equals(2));
      expect(model.verificationChecklist[0].ruleName, equals('ACID Verification'));
      expect(model.verificationChecklist[0].passed, isTrue);
    });

    test('CargoShippingModel fromJson and toJson should parse full shipping record', () {
      final json = {
        'cargo_shipping_id': 1,
        'cargo_shipping_code': 'CSH-2026-0001',
        'import_file_id': 10,
        'crd_date': '2026-08-10T00:00:00',
        'cargo_cutoff_date': '2026-08-15T00:00:00',
        'is_crd_validated': true,
        'containers_loading_data': [
          {'container_no': 'COSU9876543', 'seal_no': 'SL-5544', 'gross_weight_kg': 20000.0}
        ],
        'level1_approval_status': 'Approved',
        'level2_approval_status': 'Approved',
        'dual_approval_status': 'Dual Approved',
        'courier_tracking_data': {'courier_provider': 'FedEx', 'tracking_number': 'FEDEX-1234'},
        'cargox_exchange_data': {'platform_provider': 'CargoX', 'envelope_status': 'Checklist Passed'},
        'live_tracking_url': 'https://tracking.cosco.com/COSU9876543',
        'status': 'Dual Approved',
        'owner': 'Kamal',
        'is_active': true,
        'created_at': '2026-08-09T10:00:00Z',
        'updated_at': '2026-08-09T11:00:00Z',
        'import_file_code': 'IMP-FILE-100',
      };

      final model = CargoShippingModel.fromJson(json);

      expect(model.cargoShippingId, equals(1));
      expect(model.cargoShippingCode, equals('CSH-2026-0001'));
      expect(model.containersLoadingData.length, equals(1));
      expect(model.containersLoadingData[0].containerNo, equals('COSU9876543'));
      expect(model.dualApprovalStatus, equals('Dual Approved'));
      expect(model.courierTrackingData.courierProvider, equals('FedEx'));
      expect(model.cargoxExchangeData.envelopeStatus, equals('Checklist Passed'));
    });
  });
}
