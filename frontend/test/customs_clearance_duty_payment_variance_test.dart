import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customs_clearance/models/customs_clearance_model.dart';

void main() {
  testWidgets('CustomsClearanceModel parsing and variance computation', (WidgetTester tester) async {
    final json = {
      'customs_clearance_id': 10,
      'clearance_code': 'CLR-2026-0010',
      'import_file_id': 5,
      'declaration_46_no': '4620260819001',
      'customs_office_name': 'Dekheila Port Customs',
      'channel_type': 'Green Channel',
      'import_duty_amount': 62300.0,
      'vat_amount': 95942.0,
      'schedule_tax_amount': 6230.0,
      'wht_amount': 6230.0,
      'lab_service_fees': 4500.0,
      'total_duty_payable': 175202.0,
      'estimated_duty_total': 170000.0,
      'actual_duty_total': 175202.0,
      'duty_variance_amount': 5202.0,
      'duty_variance_percentage': 3.06,
      'duty_variance_reason': 'تغير سعر الدولار الجمركي',
      'free_days_allowed': 14,
      'payment_status': 'Paid & Verified',
      'status': 'Duty Paid',
      'created_at': '2026-08-23T02:00:00Z',
      'updated_at': '2026-08-23T02:00:00Z',
    };

    final model = CustomsClearanceModel.fromJson(json);
    expect(model.clearanceCode, 'CLR-2026-0010');
    expect(model.declaration46No, '4620260819001');
    expect(model.channelType, 'Green Channel');
    expect(model.estimatedDutyTotal, 170000.0);
    expect(model.actualDutyTotal, 175202.0);
    expect(model.dutyVarianceAmount, 5202.0);
    expect(model.dutyVariancePercentage, 3.06);
    expect(model.freeDaysAllowed, 14);
    expect(model.paymentStatus, 'Paid & Verified');
  });
}
