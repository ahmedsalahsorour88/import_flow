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

    test('ShipmentBookingModel should parse and serialize cost savings and variances correctly', () {
      final json = {
        'booking_id': 1,
        'booking_code': 'BKG-2026-0001',
        'shipment_type': 'Ocean FCL',
        'status': 'Draft',
        'owner': 'Kamal',
        'total_freight_cost_usd': 7750.0,
        'original_freight_cost_usd': 8280.0,
        'cost_savings_usd': 530.0,
        'cost_variance_usd': 530.0,
        'savings_notes': 'وفر محقق في النولون: \$530.00 USD (6.4% توفير)',
        'quotation_details_data': {
          'original_container_40ft_price': 8280.0,
          'container_40ft_price': 7750.0,
          'savings_breakdown': [
            {
              'charge_type': 'Sea Freight 40ft',
              'original_unit_rate': 8280.0,
              'executed_unit_rate': 7750.0,
              'unit_diff': 530.0,
              'quantity': 1,
              'item_savings': 530.0,
            }
          ]
        },
      };

      final booking = ShipmentBookingModel.fromJson(json);

      expect(booking.totalFreightCostUsd, 7750.0);
      expect(booking.originalFreightCostUsd, 8280.0);
      expect(booking.costSavingsUsd, 530.0);
      expect(booking.costVarianceUsd, 530.0);
      expect(booking.hasSavings, isTrue);
      expect(booking.hasCostIncrease, isFalse);
      expect(booking.savingsPercent, closeTo(6.40, 0.05));
      expect(booking.savingsNotes, contains('530.00'));

      final map = booking.toJson();
      expect(map['original_freight_cost_usd'], 8280.0);
      expect(map['cost_savings_usd'], 530.0);
      expect(map['cost_variance_usd'], 530.0);
      expect(map['savings_notes'], contains('530.00'));
    });
  });
}
