import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customs_clearance/models/customs_clearance_model.dart';

void main() {
  group('CustomsClearanceModel Unit Tests', () {
    test('Should parse CustomsClearanceModel from JSON correctly', () {
      final json = {
        'customs_clearance_id': 101,
        'clearance_code': 'CLR-2026-0001',
        'import_file_id': 12,
        'declaration_46_no': 'DECL-46-887766',
        'customs_office_name': 'Alexandria Port Customs',
        'channel_type': 'Red Channel',
        'regulatory_bodies': ['GOEIC', 'NTRA'],
        'sample_test_status': 'Samples Under Testing',
        'import_duty_amount': 50000.0,
        'vat_amount': 7000.0,
        'schedule_tax_amount': 1000.0,
        'wht_amount': 500.0,
        'lab_service_fees': 200.0,
        'total_duty_payable': 58700.0,
        'payment_status': 'Unpaid',
        'status': 'Inspection In Progress',
        'owner': 'Kamal',
        'is_active': true,
        'created_at': '2026-08-09T10:00:00Z',
        'updated_at': '2026-08-09T10:00:00Z',
      };

      final model = CustomsClearanceModel.fromJson(json);

      expect(model.customsClearanceId, 101);
      expect(model.clearanceCode, 'CLR-2026-0001');
      expect(model.declaration46No, 'DECL-46-887766');
      expect(model.channelType, 'Red Channel');
      expect(model.regulatoryBodies.length, 2);
      expect(model.totalDutyPayable, 58700.0);
      expect(model.paymentStatus, 'Unpaid');
    });

    test('Should serialize CustomsClearanceModel to JSON correctly', () {
      final model = CustomsClearanceModel(
        customsClearanceId: 102,
        clearanceCode: 'CLR-2026-0002',
        importFileId: 15,
        declaration46No: 'DECL-46-112233',
        channelType: 'Green Channel',
        regulatoryBodies: ['Food Safety Authority'],
        importDutyAmount: 20000.0,
        vatAmount: 2800.0,
        totalDutyPayable: 22800.0,
        paymentStatus: 'Paid & Verified',
        bankReceiptNo: 'RCPT-9988',
        releasePermitNo: 'REL-PERMIT-5544',
        dispatchAuthorized: true,
        createdAt: '2026-08-09T12:00:00Z',
        updatedAt: '2026-08-09T12:00:00Z',
      );

      final json = model.toJson();

      expect(json['clearance_code'], 'CLR-2026-0002');
      expect(json['declaration_46_no'], 'DECL-46-112233');
      expect(json['channel_type'], 'Green Channel');
      expect(json['payment_status'], 'Paid & Verified');
      expect(json['dispatch_authorized'], true);
    });
  });
}
