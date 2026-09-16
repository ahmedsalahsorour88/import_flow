import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/import_documentation/models/import_documentation_model.dart';

void main() {
  group('Draft BL and COO Sessions Parity Unit Tests', () {
    test('DraftBLReviewModel parses isDraft correctly from JSON', () {
      final jsonDraft = {
        'bl_review_id': 101,
        'bl_review_code': 'BL-REV-2026-0001',
        'import_file_id': 5,
        'draft_bl_number': 'MEDU12345678',
        'status': 'Draft Generated',
        'is_draft': true,
        'is_active': true,
        'created_at': '2026-09-16T10:00:00Z',
        'comparison_matrix': [],
        'blocking_reasons': [],
        'has_discrepancies': false,
        'has_blocking_mismatch': false,
      };

      final modelDraft = DraftBLReviewModel.fromJson(jsonDraft);
      expect(modelDraft.isDraft, isTrue);
      expect(modelDraft.status, 'Draft Generated');
      expect(modelDraft.blReviewId, 101);

      final jsonCertified = {
        'bl_review_id': 102,
        'bl_review_code': 'BL-REV-2026-0002',
        'import_file_id': 5,
        'draft_bl_number': 'MEDU87654321',
        'status': 'Final Approved',
        'is_draft': false,
        'is_active': true,
        'created_at': '2026-09-16T11:00:00Z',
        'comparison_matrix': [],
        'blocking_reasons': [],
        'has_discrepancies': false,
        'has_blocking_mismatch': false,
      };

      final modelCertified = DraftBLReviewModel.fromJson(jsonCertified);
      expect(modelCertified.isDraft, isFalse);
      expect(modelCertified.status, 'Final Approved');

      // Test toJson roundtrip
      final serializedDraft = modelDraft.toJson();
      expect(serializedDraft['is_draft'], isTrue);

      final serializedCertified = modelCertified.toJson();
      expect(serializedCertified['is_draft'], isFalse);
    });

    test('DraftBLReviewModel defaults isDraft to false when null in JSON', () {
      final jsonLegacy = {
        'bl_review_id': 103,
        'bl_review_code': 'BL-REV-2026-0003',
        'draft_bl_number': 'COSU99999999',
        'status': 'Approved',
        'is_active': true,
        'created_at': '2026-09-16T12:00:00Z',
        'comparison_matrix': [],
        'blocking_reasons': [],
        'has_discrepancies': false,
        'has_blocking_mismatch': false,
      };

      final modelLegacy = DraftBLReviewModel.fromJson(jsonLegacy);
      expect(modelLegacy.isDraft, isFalse);
    });

    test('CertificateOfOriginReviewModel parses isDraft correctly from JSON', () {
      final jsonDraft = {
        'coo_review_id': 201,
        'coo_review_code': 'COO-REV-2026-0001',
        'import_file_id': 6,
        'certificate_type': 'EUR.1',
        'certificate_number': 'DRAFT-EUR1-001',
        'status': 'Draft Generated',
        'is_draft': true,
        'is_active': true,
        'created_at': '2026-09-16T10:30:00Z',
        'comparison_matrix': [],
        'blocking_reasons': [],
        'has_discrepancies': true,
        'has_critical_mismatch': false,
      };

      final modelDraft = CertificateOfOriginReviewModel.fromJson(jsonDraft);
      expect(modelDraft.isDraft, isTrue);
      expect(modelDraft.status, 'Draft Generated');
      expect(modelDraft.certificateType, 'EUR.1');

      final jsonCertified = {
        'coo_review_id': 202,
        'coo_review_code': 'COO-REV-2026-0002',
        'import_file_id': 6,
        'certificate_type': 'Standard COO',
        'certificate_number': 'CERT-COO-888',
        'status': 'Verified',
        'is_draft': false,
        'is_active': true,
        'created_at': '2026-09-16T11:30:00Z',
        'comparison_matrix': [],
        'blocking_reasons': [],
        'has_discrepancies': false,
        'has_critical_mismatch': false,
      };

      final modelCertified = CertificateOfOriginReviewModel.fromJson(jsonCertified);
      expect(modelCertified.isDraft, isFalse);
      expect(modelCertified.status, 'Verified');

      // Test toJson roundtrip
      final serializedDraft = modelDraft.toJson();
      expect(serializedDraft['is_draft'], isTrue);

      final serializedCertified = modelCertified.toJson();
      expect(serializedCertified['is_draft'], isFalse);
    });

    test('CertificateOfOriginReviewModel defaults isDraft to false when null in JSON', () {
      final jsonLegacy = {
        'coo_review_id': 203,
        'coo_review_code': 'COO-REV-2026-0003',
        'certificate_type': 'GAFTA',
        'certificate_number': 'GAFTA-777',
        'status': 'Discrepancy_Accepted',
        'is_active': true,
        'created_at': '2026-09-16T12:30:00Z',
        'comparison_matrix': [],
        'blocking_reasons': [],
        'has_discrepancies': true,
        'has_critical_mismatch': false,
      };

      final modelLegacy = CertificateOfOriginReviewModel.fromJson(jsonLegacy);
      expect(modelLegacy.isDraft, isFalse);
    });
  });
}
