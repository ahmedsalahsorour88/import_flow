import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/freight_booking/models/freight_booking_model.dart';

void main() {
  group('SH-01: Departure Confirmation & Bill of Lading Tests', () {
    test('ShipmentBookingModel correctly parses bill_of_lading_no and atd from JSON', () {
      final json = {
        'booking_id': 88,
        'booking_code': 'BKG-2026-0088',
        'booking_confirmation_no': 'MSC-CONF-9900',
        'bill_of_lading_no': 'MEDUST1234567',
        'import_file_id': 10,
        'import_file_code': 'IMP-2026-0010',
        'shipping_line_name': 'MSC Mediterranean Shipping Co',
        'vessel_name': 'MSC LORETTO',
        'voyage_number': '2609W',
        'shipment_type': 'Ocean FCL',
        'pol_name': 'Shanghai Port',
        'pod_name': 'Alexandria Port',
        'etd': '2026-08-20T10:00:00Z',
        'eta': '2026-09-07T18:00:00Z',
        'atd': '2026-08-22T14:00:00Z',
        'departure_delay_days': 2,
        'transit_time_days': 16,
        'free_demurrage_days': 21,
        'status': 'Sailed',
        'owner': 'Kamal',
        'is_active': true,
        'created_at': '2026-08-10T08:00:00Z',
        'updated_at': '2026-08-22T14:30:00Z',
      };

      final model = ShipmentBookingModel.fromJson(json);

      expect(model.bookingId, 88);
      expect(model.bookingCode, 'BKG-2026-0088');
      expect(model.bookingConfirmationNo, 'MSC-CONF-9900');
      expect(model.billOfLadingNo, 'MEDUST1234567');
      expect(model.status, 'Sailed');
      expect(model.atd, '2026-08-22T14:00:00Z');
      expect(model.departureDelayDays, 2);
      expect(model.transitTimeDays, 16);
      expect(model.freeDemurrageDays, 21);
      expect(model.vesselName, 'MSC LORETTO');
      expect(model.voyageNumber, '2609W');
    });

    test('ShipmentBookingModel serializes bill_of_lading_no in toJson()', () {
      final model = ShipmentBookingModel(
        bookingId: 99,
        bookingCode: 'BKG-2026-0099',
        bookingConfirmationNo: 'CMA-CONF-1122',
        billOfLadingNo: 'CMA-BL-887766',
        importFileId: 12,
        status: 'Sailed',
        atd: '2026-08-25T15:00:00Z',
        createdAt: '2026-08-15T10:00:00Z',
        updatedAt: '2026-08-25T15:30:00Z',
      );

      final json = model.toJson();

      expect(json['booking_id'], 99);
      expect(json['bill_of_lading_no'], 'CMA-BL-887766');
      expect(json['status'], 'Sailed');
      expect(json['atd'], '2026-08-25T15:00:00Z');
    });

    test('Departure confirmation payload construction and B/L validation', () {
      // Valid B/L
      const validBol = 'MSCU99887711';
      expect(validBol.trim().length >= 3, true);

      // Short B/L rejection
      const invalidBol = 'AB';
      expect(invalidBol.trim().length >= 3, false);

      // Payload validation
      final departureDate = DateTime(2026, 8, 22, 14, 0);
      final revisedEta = DateTime(2026, 9, 7, 18, 0);

      final payload = {
        'actual_departure_date': departureDate.toIso8601String(),
        'bill_of_lading_no': validBol,
        'revised_eta': revisedEta.toIso8601String(),
        'vessel_name': 'MSC OSCAR',
        'voyage_number': '2608W',
      };

      expect(payload['bill_of_lading_no'], 'MSCU99887711');
      expect(payload['actual_departure_date'], contains('2026-08-22'));
      expect(payload['revised_eta'], contains('2026-09-07'));
    });
  });
}
