import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/lifecycle_board/models/step_config_model.dart';

void main() {
  group('StepConfigModel Tests', () {
    test('fromJson and toJson round-trip preserves all fields', () {
      final json = {
        'id': 6,
        'step_code': 'STEP_06',
        'step_name_ar': 'فحص وتجهيز البضاعة والشحن',
        'step_name_en': 'Cargo Inspection & Shipping Loading',
        'phase_id': 2,
        'skip_policy': 'dual_approval',
        'reason_required': true,
        'reason_categories': [
          'Regulatory Exemption',
          'Client Waived Inspection',
        ],
        'approver_roles': ['Manager', 'Director'],
        'supports_pending_reference': true,
        'last_modified_by': 'admin',
        'last_modified_at': '2026-09-09 12:00:00',
      };

      final model = StepConfigModel.fromJson(json);

      expect(model.id, equals(6));
      expect(model.stepCode, equals('STEP_06'));
      expect(model.stepNameAr, equals('فحص وتجهيز البضاعة والشحن'));
      expect(model.stepNameEn, equals('Cargo Inspection & Shipping Loading'));
      expect(model.phaseId, equals(2));
      expect(model.skipPolicy, equals('dual_approval'));
      expect(model.reasonRequired, isTrue);
      expect(model.reasonCategories, hasLength(2));
      expect(model.approverRoles, contains('Director'));
      expect(model.supportsPendingReference, isTrue);
      expect(model.lastModifiedBy, equals('admin'));
      expect(model.lastModifiedAt, equals('2026-09-09 12:00:00'));

      // Helper getters
      expect(model.isBlocked, isFalse);
      expect(model.requiresDualApproval, isTrue);
      expect(model.requiresSingleApproval, isFalse);
      expect(model.hasReasonCategories, isTrue);
      expect(model.skipPolicyDisplayAr, equals('موافقة ثنائية معتمدة'));
      expect(model.skipPolicyDisplayEn, equals('Dual Approval'));

      final outJson = model.toJson();
      expect(outJson['step_code'], equals('STEP_06'));
      expect(outJson['skip_policy'], equals('dual_approval'));
      expect(outJson['supports_pending_reference'], isTrue);
    });

    test('defaults unconfigured step safely to blocked (Section 10.2)', () {
      final json = {
        'id': 1,
        'step_code': 'STEP_01',
        'step_name_ar': 'تسجيل الفاتورة المبدئية',
        'step_name_en': 'PI Registration',
        'phase_id': 1,
      };

      final model = StepConfigModel.fromJson(json);
      expect(model.skipPolicy, equals('blocked'));
      expect(model.isBlocked, isTrue);
      expect(model.requiresDualApproval, isFalse);
      expect(model.requiresSingleApproval, isFalse);
      expect(model.supportsPendingReference, isFalse);
      expect(model.skipPolicyDisplayAr, equals('محظور التخطي نهائياً'));
      expect(model.skipPolicyDisplayEn, equals('Strictly Blocked'));
    });

    test('copyWith properly overrides specified attributes', () {
      const model = StepConfigModel(
        id: 3,
        stepCode: 'STEP_03',
        stepNameAr: 'استخراج رقم ACID',
        stepNameEn: 'ACID Issuance',
        phaseId: 1,
        skipPolicy: 'blocked',
      );

      final updated = model.copyWith(
        skipPolicy: 'single_approval',
        supportsPendingReference: true,
        lastModifiedBy: 'compliance_officer',
      );

      expect(updated.id, equals(3));
      expect(updated.skipPolicy, equals('single_approval'));
      expect(updated.requiresSingleApproval, isTrue);
      expect(updated.isBlocked, isFalse);
      expect(updated.supportsPendingReference, isTrue);
      expect(updated.lastModifiedBy, equals('compliance_officer'));
    });
  });

  group('StepConfigAuditLogModel Tests', () {
    test('fromJson deserializes audit trail correctly', () {
      final json = {
        'id': 101,
        'step_code': 'STEP_06',
        'action': 'UPDATE_POLICY',
        'changed_by': 'general_manager',
        'changed_at': '2026-09-09 13:00:00',
        'old_policy': 'blocked',
        'new_policy': 'single_approval',
        'old_approver_roles': ['Manager'],
        'new_approver_roles': ['Manager', 'OperationsHead'],
        'old_supports_pending_reference': false,
        'new_supports_pending_reference': true,
        'justification': 'Approved for air cargo fast-track clearance as per board decision.',
      };

      final log = StepConfigAuditLogModel.fromJson(json);

      expect(log.id, equals(101));
      expect(log.stepCode, equals('STEP_06'));
      expect(log.action, equals('UPDATE_POLICY'));
      expect(log.changedBy, equals('general_manager'));
      expect(log.oldPolicy, equals('blocked'));
      expect(log.newPolicy, equals('single_approval'));
      expect(log.newApproverRoles, contains('OperationsHead'));
      expect(log.newSupportsPendingReference, isTrue);
      expect(log.justification, contains('Approved for air cargo'));
    });
  });

  group('PendingReferenceModel Tests', () {
    test('fromJson and serialization handles reference-only state', () {
      final json = {
        'message': 'Pending reference recorded successfully',
        'import_file_code': 'IMP-2026-0004',
        'step_code': 'STEP_06',
        'reference_number': 'BL-TEMP-88319',
        'reason_text': 'Waiting for original signed Bill of Lading from shipping line.',
        'expected_completion_date': '2026-09-20',
        'status': 'Reference recorded – pending full documentation',
        'registered_at': '2026-09-09 13:30:00',
        'registered_by': 'AI_Agent',
      };

      final refRecord = PendingReferenceModel.fromJson(json);

      expect(refRecord.importFileCode, equals('IMP-2026-0004'));
      expect(refRecord.stepCode, equals('STEP_06'));
      expect(refRecord.referenceNumber, equals('BL-TEMP-88319'));
      expect(refRecord.status, equals('Reference recorded – pending full documentation'));
      expect(refRecord.isCompleted, isFalse);
    });
  });
}
