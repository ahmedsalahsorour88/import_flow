import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/import_documentation/models/docs_customs_approval_model.dart';

void main() {
  group('DC-04: Shipping Docs Matrix Verification & Deficiency Tracking Tests', () {
    test('CrossDocumentMatrixResultModel correctly parses missing_documents and completeness_percent', () {
      final json = {
        'import_file_id': 101,
        'import_file_code': 'IMP-2026-0101',
        'overall_compliance': 'Discrepancies Found',
        'total_checks': 13,
        'passed_checks': 8,
        'failed_checks': 5,
        'checks': [
          {
            'parameter': 'ACID Number (19 Digits)',
            'status': 'Match',
            'acid_val': '1234567890123456789',
            'notes': 'ACID verified and valid',
          },
          {
            'parameter': 'Fumigation Certificate (ISPM 15)',
            'status': 'Missing',
            'notes': 'تنبيه نقص مستندي: شهادة التبخير غير مستوفاة',
          },
        ],
        'recommendations': [
          'تنبيه استكمال مستندي (DC-04): يجب استيفاء شهادة التبخير والصحة النباتية للملف.',
        ],
        'open_tickets_count': 1,
        'missing_documents': [
          'شهادة التبخير والصحة النباتية (Fumigation Cert)',
          'شهادة الفحص والتفتيش والمطابقة (Inspection Cert)',
        ],
        'completeness_percent': 71.4,
      };

      final model = CrossDocumentMatrixResultModel.fromJson(json);

      expect(model.importFileId, 101);
      expect(model.importFileCode, 'IMP-2026-0101');
      expect(model.overallCompliance, 'Discrepancies Found');
      expect(model.totalChecks, 13);
      expect(model.passedChecks, 8);
      expect(model.failedChecks, 5);
      expect(model.checks.length, 2);
      expect(model.checks[1].parameter, 'Fumigation Certificate (ISPM 15)');
      expect(model.checks[1].status, 'Missing');
      expect(model.recommendations.length, 1);
      expect(model.openTicketsCount, 1);
      expect(model.missingDocuments.length, 2);
      expect(model.missingDocuments.first, contains('شهادة التبخير'));
      expect(model.completenessPercent, 71.4);
    });

    test('CrossDocumentMatrixResultModel handles 100% compliant payload', () {
      final json = {
        'import_file_id': 202,
        'import_file_code': 'IMP-2026-0202',
        'overall_compliance': 'Fully Compliant',
        'total_checks': 13,
        'passed_checks': 13,
        'failed_checks': 0,
        'checks': [],
        'recommendations': [],
        'open_tickets_count': 0,
        'missing_documents': [],
        'completeness_percent': 100.0,
      };

      final model = CrossDocumentMatrixResultModel.fromJson(json);

      expect(model.overallCompliance, 'Fully Compliant');
      expect(model.passedChecks, 13);
      expect(model.failedChecks, 0);
      expect(model.missingDocuments, isEmpty);
      expect(model.completenessPercent, 100.0);
    });

    test('CrossDocumentMatrixResultModel gracefully defaults when fields are omitted', () {
      final json = {
        'import_file_id': 303,
      };

      final model = CrossDocumentMatrixResultModel.fromJson(json);

      expect(model.importFileId, 303);
      expect(model.importFileCode, '');
      expect(model.overallCompliance, 'Pending');
      expect(model.missingDocuments, isEmpty);
      expect(model.completenessPercent, 0.0);
    });
  });
}
