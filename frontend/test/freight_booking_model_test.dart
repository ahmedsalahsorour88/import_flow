import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/freight_booking/models/freight_booking_model.dart';

void main() {
  group('ShipmentBookingModel Scenario Linkage & Tracking Unit Tests (Phase 4)', () {
    test('fromJson and toJson should parse and serialize scenario linkage and tracking fields accurately', () {
      final json = {
        'booking_id': 55,
        'booking_code': 'BKG-2026-0055',
        'booking_confirmation_no': 'MSC-CN-889001',
        'import_file_id': 12,
        'scenario_session_id': 8,
        'scenario_item_id': 19,
        'scenario_provider_name': 'Mediterranean Shipping Company (MSC)',
        'freight_forwarder_name': 'El-Ahram Logistics',
        'shipping_line_name': 'MSC',
        'shipment_type': 'Ocean FCL',
        'pol_name': 'Shanghai Port',
        'pod_name': 'Alexandria Port',
        'etd': '2026-08-15T00:00:00.000',
        'eta': '2026-09-02T00:00:00.000',
        'atd': '2026-08-19T00:00:00.000',
        'departure_delay_days': 4,
        'expected_warehouse_days': 7,
        'expected_warehouse_arrival_date': '2026-09-13T00:00:00.000',
        'transit_time_days': 18,
        'free_demurrage_days': 21,
        'vessel_name': 'MSC Oscar',
        'voyage_number': 'VY-2026-X8',
        'container_mismatch_reason': 'High volumetric density required 40HC',
        'status': 'Confirmed',
        'owner': 'Kamal',
        'is_active': true,
        'created_at': '2026-08-14T20:00:00.000',
        'updated_at': '2026-08-14T20:00:00.000',
        'containers_data': [
          {
            'container_type': '40HC',
            'quantity': 2,
            'container_numbers': ['MSCU1234567', 'MSCU7654321'],
            'seal_numbers': ['SL-99001', 'SL-99002'],
            'vgm_weight_kg': 24500.0,
            'individual_containers': [
              {'container_number': 'MSCU1234567', 'seal_number': 'SL-99001', 'vgm_weight_kg': 12250.0},
              {'container_number': 'MSCU7654321', 'seal_number': 'SL-99002', 'vgm_weight_kg': 12250.0},
            ],
          }
        ],
        'cost_charges_data': [
          {
            'charge_type': 'Sea Freight 40ft',
            'unit': 'Per Container',
            'quantity': 2,
            'currency': 'USD',
            'rate': 2200.0,
            'total': 4400.0,
          },
          {
            'charge_type': 'DTHC',
            'unit': 'Per Shipment',
            'quantity': 1,
            'currency': 'USD',
            'rate': 350.0,
            'total': 350.0,
          }
        ],
        'quotation_details_data': {
          'dthc_app': true,
          'dthc_price': 350.0,
        },
        'total_freight_cost_usd': 4750.0,
      };

      final model = ShipmentBookingModel.fromJson(json);

      expect(model.bookingId, 55);
      expect(model.bookingCode, 'BKG-2026-0055');
      expect(model.scenarioSessionId, 8);
      expect(model.scenarioItemId, 19);
      expect(model.scenarioProviderName, 'Mediterranean Shipping Company (MSC)');
      expect(model.atd, '2026-08-19T00:00:00.000');
      expect(model.departureDelayDays, 4);
      expect(model.expectedWarehouseDays, 7);
      expect(model.expectedWarehouseArrivalDate, '2026-09-13T00:00:00.000');
      expect(model.containerMismatchReason, 'High volumetric density required 40HC');
      expect(model.freeDemurrageDays, 21);
      expect(model.containersData.length, 1);
      expect(model.containersData.first.individualContainers.length, 2);
      expect(model.containersData.first.individualContainers.first.containerNumber, 'MSCU1234567');
      expect(model.containersData.first.individualContainers.first.sealNumber, 'SL-99001');
      expect(model.costChargesData.length, 2);
      expect(model.quotationDetailsData['dthc_price'], 350.0);
      expect(model.totalFreightCostUsd, 4750.0);

      final serialized = model.toJson();
      expect(serialized['scenario_session_id'], 8);
      expect(serialized['scenario_item_id'], 19);
      expect(serialized['scenario_provider_name'], 'Mediterranean Shipping Company (MSC)');
      expect(serialized['atd'], '2026-08-19T00:00:00.000');
      expect(serialized['container_mismatch_reason'], 'High volumetric density required 40HC');
      expect(serialized['status'], 'Confirmed');
    });
  });
}
