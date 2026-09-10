import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/services/ai_agent_tool_executor.dart';

void main() {
  test('Live Acceptance Test: Execute real writes with RAW verification and live queries on local backend', () async {
    final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
    final executor = AiAgentToolExecutor(dio: dio);

    // 1. Search for shipment "PET"
    final searchRes = await executor.searchShipments('PET');
    expect(searchRes['status'], equals('FOUND'));
    expect(searchRes['import_file_id'], equals(4));
    expect(searchRes['file_code'], equals('IMP-2026-0004'));
    final int fileId = searchRes['import_file_id'] as int;

    // 2. Execute Container Allocation & Milestones write with RAW verification
    final containerRes = await executor.updateContainerAllocation(
      importFileId: fileId,
      containerNo: 'WHSU81072658',
      sealNo: 'WHA257097',
      assignmentDate: '27/8',
      loadingDate: '27/8',
    );
    expect(containerRes['success'], isTrue);
    expect(containerRes['verified'], isTrue);
    expect(containerRes['container_no'], equals('WHSU81072658'));
    expect(containerRes['seal_no'], equals('WHA257097'));
    expect(containerRes['assignment_date'], equals('2026-08-27'));
    expect(containerRes['loading_date'], equals('2026-08-27'));
    expect(containerRes['record_code'], isNotNull);

    // 3. Execute Booking Confirmation & House B/L write with RAW verification
    final bookingRes = await executor.createOrUpdateBooking(
      importFileId: fileId,
      bookingNo: 'THXJ2608090',
      houseBlNo: 'THXJ2608090',
    );
    expect(bookingRes['success'], isTrue);
    expect(bookingRes['verified'], isTrue);
    expect(bookingRes['booking_no'], equals('THXJ2608090'));
    expect(bookingRes['house_bl_no'], equals('THXJ2608090'));

    // 4. Live Query ACID Status for "PET"
    final acidRes = await executor.queryAcidStatus(query: 'PET');
    expect(acidRes['status'], equals('SUCCESS'));
    expect(acidRes['has_acid'], isTrue);
    expect(acidRes['acid_number'], equals('5281534391023010013'));
    expect(acidRes['is_customs_released'], isFalse);
    expect(acidRes['live_verified'], isTrue);

    // 5. Audit Trail Verification
    final audit = executor.getAgentAuditTrail();
    expect(audit['total_actions'], greaterThanOrEqualTo(2));
    final entries = audit['audit_entries'] as List;
    expect(entries.every((e) => e['verified'] == true), isTrue);
  });
}
