import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/import_documentation_model.dart';
import '../models/po_reconciliation_session_model.dart';
import '../../../core/network/api_client.dart';



final acidSessionsProvider =
    StateNotifierProvider<AcidSessionsNotifier, AsyncValue<List<AcidRegistrationModel>>>((ref) {
  return AcidSessionsNotifier(ref.read(dioProvider));
});

class AcidSessionsNotifier extends StateNotifier<AsyncValue<List<AcidRegistrationModel>>> {
  final Dio _dio;

  AcidSessionsNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchAcidSessions();
  }

  Future<void> fetchAcidSessions({
    bool includeInactive = false,
    String? search,
    String? status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{
        'include_inactive': includeInactive,
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty && status != 'All') queryParams['status'] = status;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/import-documentation/acid-sessions',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      final sessions = data.map((json) => AcidRegistrationModel.fromJson(json)).toList();
      state = AsyncValue.data(sessions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<AcidRegistrationModel?> createAcidSession(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/acid-sessions',
        data: payload,
      );
      final created = AcidRegistrationModel.fromJson(response.data);
      await fetchAcidSessions();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<AcidRegistrationModel?> updateAcidSession(int acidId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/import-documentation/acid-sessions/$acidId',
        data: payload,
      );
      final updated = AcidRegistrationModel.fromJson(response.data);
      await fetchAcidSessions();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> parseAcidText(String rawText, {int? importFileId}) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/acid/parse-text',
        data: {
          'raw_text': rawText,
          if (importFileId != null) 'import_file_id': importFileId,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<AcidComparisonResult> compareAcid(Map<String, dynamic> requested, Map<String, dynamic> generated) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/acid/compare',
        data: {
          'requested': requested,
          'generated': generated,
        },
      );
      return AcidComparisonResult.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, String>> generateTemplates(Map<String, dynamic> reqData) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/acid/templates',
        data: reqData,
      );
      return {
        'whatsapp_text': response.data['whatsapp_text']?.toString() ?? '',
        'email_subject': response.data['email_subject']?.toString() ?? '',
        'email_body': response.data['email_body']?.toString() ?? '',
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<void> softDeleteAcidSession(int acidId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/import-documentation/acid-sessions/$acidId');
      await fetchAcidSessions();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreAcidSession(int acidId) async {
    try {
      await _dio.patch('${ApiConstants.baseUrl}/import-documentation/acid-sessions/$acidId/restore');
      await fetchAcidSessions();
    } catch (e) {
      rethrow;
    }
  }
}

final bankingDocumentsProvider =
    StateNotifierProvider<BankingDocumentsNotifier, AsyncValue<List<BankingDocumentModel>>>((ref) {
  return BankingDocumentsNotifier(ref.read(dioProvider));
});

class BankingDocumentsNotifier extends StateNotifier<AsyncValue<List<BankingDocumentModel>>> {
  final Dio _dio;

  BankingDocumentsNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchBankingDocuments();
  }

  Future<void> fetchBankingDocuments() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/import-documentation/banking-documents');
      final List<dynamic> data = response.data;
      final docs = data.map((json) => BankingDocumentModel.fromJson(json)).toList();
      state = AsyncValue.data(docs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<BankingDocumentModel?> createBankingDocument(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/banking-documents',
        data: payload,
      );
      final created = BankingDocumentModel.fromJson(response.data);
      await fetchBankingDocuments();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<BankingDocumentModel?> receiveBankingDocument(int bankDocId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/banking-documents/$bankDocId/receive',
        data: payload,
      );
      final received = BankingDocumentModel.fromJson(response.data);
      await fetchBankingDocuments();
      return received;
    } catch (e) {
      rethrow;
    }
  }

  Future<BankingDocumentModel?> updateBankingDocument(int bankDocId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/import-documentation/banking-documents/$bankDocId',
        data: payload,
      );
      final updated = BankingDocumentModel.fromJson(response.data);
      await fetchBankingDocuments();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteBankingDocument(int bankDocId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/import-documentation/banking-documents/$bankDocId');
      await fetchBankingDocuments();
      return true;
    } catch (e) {
      rethrow;
    }
  }
}

final shipmentDocumentsProvider =
    StateNotifierProvider<ShipmentDocumentsNotifier, AsyncValue<List<ShipmentDocumentModel>>>((ref) {
  return ShipmentDocumentsNotifier(ref.read(dioProvider));
});

class ShipmentDocumentsNotifier extends StateNotifier<AsyncValue<List<ShipmentDocumentModel>>> {
  final Dio _dio;

  ShipmentDocumentsNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchShipmentDocuments();
  }

  Future<void> fetchShipmentDocuments() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/import-documentation/shipment-documents');
      final List<dynamic> data = response.data;
      final docs = data.map((json) => ShipmentDocumentModel.fromJson(json)).toList();
      state = AsyncValue.data(docs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<ShipmentDocumentModel?> createShipmentDocument(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/shipment-documents',
        data: payload,
      );
      final created = ShipmentDocumentModel.fromJson(response.data);
      await fetchShipmentDocuments();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<ShipmentDocumentModel?> updateCargoXAndBLEndorsement(int docId, {String? cargoxEnvId, String? endorsementNum}) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/shipment-documents/$docId/cargox-bl',
        queryParameters: {
          if (cargoxEnvId != null) 'cargox_envelope_id': cargoxEnvId,
          if (endorsementNum != null) 'endorsement_number': endorsementNum,
        },
      );
      final updated = ShipmentDocumentModel.fromJson(response.data);
      await fetchShipmentDocuments();
      return updated;
    } catch (e) {
      rethrow;
    }
  }
}

final acidTrackerProvider =
    StateNotifierProvider<AcidTrackerNotifier, AsyncValue<AcidTrackerSummaryModel>>((ref) {
  return AcidTrackerNotifier(ref.read(dioProvider));
});

class AcidTrackerNotifier extends StateNotifier<AsyncValue<AcidTrackerSummaryModel>> {
  final Dio _dio;

  AcidTrackerNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchAcidTracker();
  }

  Future<void> fetchAcidTracker() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/import-documentation/acid/tracker');
      final summary = AcidTrackerSummaryModel.fromJson(response.data);
      state = AsyncValue.data(summary);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// ==============================================================================
// PHASE 6: PROVIDERS FOR DRAFT REVIEWS, COMPLIANCE & RECONCILIATION
// ==============================================================================

// 1. Legal Documents & ACID Expiry Compliance (+30 Days Safety Margin) Provider
final legalComplianceFamilyProvider =
    FutureProvider.family<LegalDocsExpiryComplianceModel, int>((ref, importFileId) async {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  final response = await dio.get(
    '${ApiConstants.baseUrl}/import-documentation/legal-compliance/$importFileId',
  );
  return LegalDocsExpiryComplianceModel.fromJson(response.data);
});

// 2. Draft B/L Review Provider
final draftBLReviewsProvider =
    StateNotifierProvider<DraftBLNotifier, AsyncValue<List<DraftBLReviewModel>>>((ref) {
  return DraftBLNotifier(ref.read(dioProvider));
});

class DraftBLNotifier extends StateNotifier<AsyncValue<List<DraftBLReviewModel>>> {
  final Dio _dio;

  DraftBLNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchReviews();
  }

  Future<void> fetchReviews({int? importFileId, String? search}) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{};
      if (importFileId != null) queryParams['import_file_id'] = importFileId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/import-documentation/draft-bl',
        queryParameters: queryParams,
      );
      final List<dynamic> data = response.data;
      final reviews = data.map((json) => DraftBLReviewModel.fromJson(json)).toList();
      state = AsyncValue.data(reviews);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<DraftBLComparisonResultModel> compareDraftBL(int importFileId, Map<String, dynamic> draftFields, {String? rawText}) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/draft-bl/compare',
        data: {
          'import_file_id': importFileId,
          'draft_fields': draftFields,
          if (rawText != null) 'raw_text': rawText,
        },
      );
      return DraftBLComparisonResultModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> extractDraftBLFromFile(
    List<int> fileBytes,
    String fileName, {
    int? importFileId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
        if (importFileId != null) 'import_file_id': importFileId,
      });
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/draft-bl/extract-file',
        data: formData,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<DraftBLReviewModel> saveDraftBLReview(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/draft-bl',
        data: payload,
      );
      final created = DraftBLReviewModel.fromJson(response.data);
      await fetchReviews();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<DraftBLReviewModel> updateDraftBLChecklist(int reviewId, List<DraftBLChecklistItemModel> items, {String reviewerName = 'Kamal'}) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/import-documentation/draft-bl/$reviewId/checklist',
        queryParameters: {'reviewer_name': reviewerName},
        data: items.map((i) => i.toJson()).toList(),
      );
      final updated = DraftBLReviewModel.fromJson(response.data);
      await fetchReviews();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<DraftBLReviewModel> submitDualApproval(int reviewId, String role, String action, String approvedBy, {String? notes}) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/draft-bl/dual-approval',
        data: {
          'bl_review_id': reviewId,
          'role': role,
          'action': action,
          'approved_by': approvedBy,
          if (notes != null) 'notes': notes,
        },
      );
      final updated = DraftBLReviewModel.fromJson(response.data);
      await fetchReviews();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<DraftBLReviewModel> createNewDraftVersion(int parentSessionId, Map<String, dynamic> draftFields, {String? rawText, String draftSource = 'SMART_TEXT'}) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/draft-bl/new-version',
        data: {
          'parent_session_id': parentSessionId,
          'draft_source': draftSource,
          'draft_fields': draftFields,
          if (rawText != null) 'raw_draft_text': rawText,
        },
      );
      final created = DraftBLReviewModel.fromJson(response.data);
      await fetchReviews();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<DraftBLReviewModel> approveDraftBL(int reviewId, {String approvedBy = 'Kamal'}) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/draft-bl/$reviewId/approve',
        queryParameters: {'approved_by': approvedBy},
      );
      final approved = DraftBLReviewModel.fromJson(response.data);
      await fetchReviews();
      return approved;
    } catch (e) {
      rethrow;
    }
  }
}

// 3. Certificate of Origin (COO / EUR.1) Provider
final cooReviewsProvider =
    StateNotifierProvider<COONotifier, AsyncValue<List<CertificateOfOriginReviewModel>>>((ref) {
  return COONotifier(ref.read(dioProvider));
});

class COONotifier extends StateNotifier<AsyncValue<List<CertificateOfOriginReviewModel>>> {
  final Dio _dio;

  COONotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchReviews();
  }

  Future<void> fetchReviews({int? importFileId}) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{};
      if (importFileId != null) queryParams['import_file_id'] = importFileId;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/import-documentation/coo',
        queryParameters: queryParams,
      );
      final List<dynamic> data = response.data;
      final reviews = data.map((json) => CertificateOfOriginReviewModel.fromJson(json)).toList();
      state = AsyncValue.data(reviews);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<Map<String, dynamic>> compareCOO(int importFileId, String certType, Map<String, dynamic> draftFields) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/coo/compare',
        data: {
          'import_file_id': importFileId,
          'certificate_type': certType,
          'draft_fields': draftFields,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchCooDraftTemplate(int importFileId, {String certType = 'EUR.1'}) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/import-documentation/coo/draft-template/$importFileId',
        queryParameters: {'cert_type': certType},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> extractCertificate(String docType, String rawText, {int? importFileId}) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/extract-certificate',
        data: {
          'document_type': docType,
          'raw_text': rawText,
          if (importFileId != null) 'import_file_id': importFileId,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<CertificateOfOriginReviewModel> saveCOOReview(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/coo',
        data: payload,
      );
      final created = CertificateOfOriginReviewModel.fromJson(response.data);
      await fetchReviews();
      return created;
    } catch (e) {
      rethrow;
    }
  }
}

// 4. Inspection Certificate Provider
final inspectionReviewsProvider =
    StateNotifierProvider<InspectionNotifier, AsyncValue<List<InspectionCertificateReviewModel>>>((ref) {
  return InspectionNotifier(ref.read(dioProvider));
});

class InspectionNotifier extends StateNotifier<AsyncValue<List<InspectionCertificateReviewModel>>> {
  final Dio _dio;

  InspectionNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchReviews();
  }

  Future<void> fetchReviews({int? importFileId}) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{};
      if (importFileId != null) queryParams['import_file_id'] = importFileId;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/import-documentation/inspection',
        queryParameters: queryParams,
      );
      final List<dynamic> data = response.data;
      final reviews = data.map((json) => InspectionCertificateReviewModel.fromJson(json)).toList();
      state = AsyncValue.data(reviews);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<Map<String, dynamic>> fetchInspectionDraftTemplate(int importFileId, {String agency = 'COTECNA', String certType = 'COC (Certificate of Conformity)'}) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/import-documentation/inspection/draft-template/$importFileId',
        queryParameters: {'agency': agency, 'cert_type': certType},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> extractCertificate(String docType, String rawText, {int? importFileId}) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/extract-certificate',
        data: {
          'document_type': docType,
          'raw_text': rawText,
          if (importFileId != null) 'import_file_id': importFileId,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> compareInspection(int importFileId, String inspType, String agency, Map<String, dynamic> draftFields) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/inspection/compare',
        data: {
          'import_file_id': importFileId,
          'inspection_type': inspType,
          'inspection_agency': agency,
          'draft_fields': draftFields,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<InspectionCertificateReviewModel> saveInspectionReview(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/inspection',
        data: payload,
      );
      final created = InspectionCertificateReviewModel.fromJson(response.data);
      await fetchReviews();
      return created;
    } catch (e) {
      rethrow;
    }
  }
}

// 5. PO Final Reconciliation Provider
final poReconciliationProvider = Provider<POReconciliationService>((ref) {
  final dio = ref.read(dioProvider);
  return POReconciliationService(dio);
});

class POReconciliationService {
  final Dio _dio;

  POReconciliationService(this._dio);

  Future<POReconciliationResultModel> submitPOFinalReconciliation(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/po-reconciliation',
        data: payload,
      );
      return POReconciliationResultModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

// 6. PO Reconciliation Saved Sessions Provider (Phase 6 / BP-016)
final poReconciliationSessionsProvider =
    StateNotifierProvider<POReconciliationSessionsNotifier, AsyncValue<List<POReconciliationSessionModel>>>((ref) {
  return POReconciliationSessionsNotifier(ref.read(dioProvider));
});

class POReconciliationSessionsNotifier
    extends StateNotifier<AsyncValue<List<POReconciliationSessionModel>>> {
  final Dio _dio;

  POReconciliationSessionsNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchSessions();
  }

  Future<void> fetchSessions({
    int? importFileId,
    String? overallStatus,
    String? search,
  }) async {
    try {
      state = const AsyncValue.loading();
      final queryParams = <String, dynamic>{};
      if (importFileId != null) queryParams['import_file_id'] = importFileId;
      if (overallStatus != null && overallStatus.isNotEmpty && overallStatus != 'All') {
        queryParams['overall_status'] = overallStatus;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/import-documentation/po-reconciliation/sessions',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      final sessions = data
          .map((json) => POReconciliationSessionModel.fromJson(json as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(sessions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<POReconciliationSessionModel> createSession(POReconciliationSessionModel session) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/po-reconciliation/sessions',
        data: session.toJson(),
      );
      final created = POReconciliationSessionModel.fromJson(response.data as Map<String, dynamic>);
      await fetchSessions();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<POReconciliationSessionModel> updateSession(
      int sessionId, Map<String, dynamic> updateData) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/import-documentation/po-reconciliation/sessions/$sessionId',
        data: updateData,
      );
      final updated = POReconciliationSessionModel.fromJson(response.data as Map<String, dynamic>);
      await fetchSessions();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteSession(int sessionId) async {
    try {
      await _dio.delete(
        '${ApiConstants.baseUrl}/import-documentation/po-reconciliation/sessions/$sessionId',
      );
      await fetchSessions();
      return true;
    } catch (e) {
      rethrow;
    }
  }
}

// 7. Central Shipment Documents Archive & Discrepancies Summary Provider
final centralArchiveProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, importFileId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(
    '${ApiConstants.baseUrl}/import-documentation/central-archive/$importFileId',
  );
  return response.data as Map<String, dynamic>;
});



