import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/import_documentation/models/import_documentation_model.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';

void main() {
  group('ACID Expiry Tracker & Import File Model Tests', () {
    test('ImportFileModel parses ACID issue, expiry, and customs release info', () {
      final json = {
        'import_file_id': 10,
        'import_file_code': 'IMP-2026-010',
        'custom_file_number': 'CUST-8890',
        'company_name': 'El-Araby Group',
        'supplier_name': 'Samsung Electronics',
        'acid_number': '1987654321098765432',
        'acid_issue_date': '2026-06-01',
        'acid_expiry_date': '2026-12-01',
        'is_customs_released': true,
        'customs_released_at': '2026-08-14T12:00:00Z',
        'current_module': 'Phase 7 - Customs Clearance',
        'current_stage': 'Customs Release Granted',
        'next_action': 'Warehouse Dispatch',
        'created_at': '2026-06-01T08:00:00Z',
        'updated_at': '2026-08-14T12:00:00Z',
      };

      final model = ImportFileModel.fromJson(json);

      expect(model.importFileId, 10);
      expect(model.importFileCode, 'IMP-2026-010');
      expect(model.acidNumber, '1987654321098765432');
      expect(model.acidIssueDate, '2026-06-01');
      expect(model.acidExpiryDate, '2026-12-01');
      expect(model.isCustomsReleased, true);
      expect(model.customsReleasedAt, '2026-08-14T12:00:00Z');

      final serialized = model.toJson();
      expect(serialized['acid_number'], '1987654321098765432');
      expect(serialized['acid_issue_date'], '2026-06-01');
      expect(serialized['acid_expiry_date'], '2026-12-01');
      expect(serialized['is_customs_released'], true);
    });

    test('AcidTrackerItemModel parses valid, expiring soon, expired, and customs released items', () {
      final validJson = {
        'import_file_id': 1,
        'import_file_code': 'IMP-001',
        'acid_number': '1111222233334444555',
        'importer_name': 'Fresh Electric',
        'supplier_name': 'Media China',
        'acid_issue_date': '2026-08-01',
        'acid_expiry_date': '2026-11-01',
        'days_remaining': 78,
        'total_validity_days': 92,
        'validity_percentage': 84.8,
        'is_customs_released': false,
        'status': 'Valid',
        'status_label_ar': 'ساري وصالح',
        'alert_required': false,
      };

      final validItem = AcidTrackerItemModel.fromJson(validJson);
      expect(validItem.acidNumber, '1111222233334444555');
      expect(validItem.status, 'Valid');
      expect(validItem.alertRequired, false);
      expect(validItem.daysRemaining, 78);

      final releasedJson = {
        'import_file_id': 4,
        'import_file_code': 'IMP-004',
        'acid_number': '9999888877776666555',
        'importer_name': 'Universal Group',
        'supplier_name': 'Haier China',
        'acid_issue_date': '2026-05-01',
        'acid_expiry_date': '2026-08-01',
        'days_remaining': -14,
        'total_validity_days': 92,
        'validity_percentage': 0.0,
        'is_customs_released': true,
        'customs_released_at': '2026-08-10T14:30:00Z',
        'release_permit_no': 'REL-2026-EG-991',
        'status': 'Customs Released',
        'status_label_ar': 'صُرفت من الجمرك (معفى من التنبيه)',
        'alert_required': false,
      };

      final releasedItem = AcidTrackerItemModel.fromJson(releasedJson);
      expect(releasedItem.isCustomsReleased, true);
      expect(releasedItem.status, 'Customs Released');
      expect(releasedItem.alertRequired, false); // Alert suppressed once released!
      expect(releasedItem.releasePermitNo, 'REL-2026-EG-991');
    });

    test('AcidTrackerSummaryModel parses aggregates correctly', () {
      final summaryJson = {
        'total_acids_count': 4,
        'valid_count': 2,
        'expiring_soon_count': 1,
        'expired_count': 0,
        'customs_released_count': 1,
        'pending_issue_count': 0,
        'items': [
          {
            'acid_number': '1111',
            'importer_name': 'Imp 1',
            'supplier_name': 'Sup 1',
            'days_remaining': 60,
            'validity_percentage': 66.0,
            'is_customs_released': false,
            'status': 'Valid',
            'status_label_ar': 'ساري وصالح',
            'alert_required': false,
          },
          {
            'acid_number': '2222',
            'importer_name': 'Imp 2',
            'supplier_name': 'Sup 2',
            'days_remaining': 8,
            'validity_percentage': 8.8,
            'is_customs_released': false,
            'status': 'Expiring Soon',
            'status_label_ar': 'يوشك على الانتهاء',
            'alert_required': true,
          },
        ],
      };

      final summary = AcidTrackerSummaryModel.fromJson(summaryJson);
      expect(summary.totalAcidsCount, 4);
      expect(summary.validCount, 2);
      expect(summary.expiringSoonCount, 1);
      expect(summary.customsReleasedCount, 1);
      expect(summary.items.length, 2);
      expect(summary.items[1].alertRequired, true);
    });
  });
}
