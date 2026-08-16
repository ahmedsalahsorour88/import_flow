import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/cargo_shipping/models/cargo_shipping_model.dart';

void main() {
  group('CargoShippingModel Unit Tests (Phase 5 - Cargo & Container Follow-up)', () {
    test('ContainerLoadingModel 5-Milestones & SLA tracking serialization', () {
      final json = {
        'container_type': '40HC',
        'quantity': 1,
        'container_no': 'MSKU1234567',
        'seal_no': 'SL-9988',
        'tare_weight_kg': 2300.0,
        'net_weight_kg': 19000.0,
        'gross_weight_kg': 21300.0,
        'vgm_status': 'Submitted',
        'vgm_ref_no': 'VGM-100200',
        'container_assignment_date': '2026-08-16',
        'arrival_at_supplier_at': '2026-08-16T09:00:00Z',
        'loading_start_at': '2026-08-16T11:00:00Z',
        'loading_end_at': '2026-08-16T15:00:00Z',
        'port_gate_in_at': '2026-08-17T08:00:00Z',
        'sla_deadline_at': '2026-08-18T00:00:00Z',
        'is_sla_breached': false,
        'tracking_status': 'GATED_IN_AT_PORT',
        'tracking_history': [
          {'timestamp': '2026-08-16T09:00:00Z', 'status': 'ARRIVED_AT_SUPPLIER', 'updated_by': 'Kamal'}
        ],
        'individual_units': [
          {'container_no': 'MSKU1234567', 'seal_no': 'SL-9988'}
        ]
      };

      final model = ContainerLoadingModel.fromJson(json);

      expect(model.containerNo, equals('MSKU1234567'));
      expect(model.sealNo, equals('SL-9988'));
      expect(model.grossWeightKg, equals(21300.0));
      expect(model.vgmStatus, equals('Submitted'));
      expect(model.containerAssignmentDate, equals('2026-08-16'));
      expect(model.portGateInAt, equals('2026-08-17T08:00:00Z'));
      expect(model.trackingStatus, equals('GATED_IN_AT_PORT'));
      expect(model.progressStepIndex, equals(5));
      expect(model.arabicStatusLabel, contains('دخلت الميناء'));
      expect(model.isSlaBreached, isFalse);

      final map = model.toJson();
      expect(map['container_no'], equals('MSKU1234567'));
      expect(map['port_gate_in_at'], equals('2026-08-17T08:00:00Z'));
      expect(map['tracking_status'], equals('GATED_IN_AT_PORT'));
    });

    test('LclLoadingTrackingModel serialization and milestone steps', () {
      final json = {
        'shipment_type': 'LCL',
        'cfs_warehouse_name': 'Shanghai CFS Hub #4',
        'consolidation_scheduled_date': '2026-08-16',
        'arrival_at_cfs_at': '2026-08-16T10:00:00Z',
        'stuffing_start_at': '2026-08-16T12:00:00Z',
        'stuffing_end_at': '2026-08-16T16:00:00Z',
        'port_gate_in_at': '2026-08-17T14:00:00Z',
        'sla_deadline_at': '2026-08-18T00:00:00Z',
        'is_sla_breached': false,
        'tracking_status': 'GATED_IN_AT_PORT',
      };

      final lcl = LclLoadingTrackingModel.fromJson(json);

      expect(lcl.cfsWarehouseName, equals('Shanghai CFS Hub #4'));
      expect(lcl.progressStepIndex, equals(5));
      expect(lcl.arabicStatusLabel, contains('دخلت الميناء'));
      expect(lcl.isSlaBreached, isFalse);

      final map = lcl.toJson();
      expect(map['cfs_warehouse_name'], equals('Shanghai CFS Hub #4'));
      expect(map['tracking_status'], equals('GATED_IN_AT_PORT'));
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
        'cargo_shipping_code': 'SHP-2026-0001',
        'import_file_id': 10,
        'import_file_code': 'IMP-FILE-100',
        'company_name': 'Alpha Importers Co',
        'shipment_type': 'FCL',
        'crd_date': '2026-08-10T00:00:00',
        'cargo_cutoff_date': '2026-08-15T00:00:00',
        'is_crd_validated': true,
        'containers_loading_data': [
          {
            'container_no': 'COSU9876543',
            'seal_no': 'SL-5544',
            'gross_weight_kg': 20000.0,
            'container_assignment_date': '2026-08-16',
            'tracking_status': 'ASSIGNED',
            'is_sla_breached': false,
          }
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
      };

      final model = CargoShippingModel.fromJson(json);

      expect(model.cargoShippingId, equals(1));
      expect(model.cargoShippingCode, equals('SHP-2026-0001'));
      expect(model.companyName, equals('Alpha Importers Co'));
      expect(model.shipmentType, equals('FCL'));
      expect(model.containersLoadingData.length, equals(1));
      expect(model.containersLoadingData.first.containerNo, equals('COSU9876543'));
      expect(model.containersLoadingData.first.trackingStatus, equals('ASSIGNED'));
      expect(model.dualApprovalStatus, equals('Dual Approved'));
    });
  });
}
