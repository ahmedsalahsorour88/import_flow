import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/cargox_model.dart';

final cargoxEnvelopesProvider =
    StateNotifierProvider<CargoXNotifier, AsyncValue<List<CargoXEnvelopeModel>>>((ref) {
  return CargoXNotifier(ref.read(dioProvider));
});

class CargoXNotifier extends StateNotifier<AsyncValue<List<CargoXEnvelopeModel>>> {
  final Dio _dio;

  CargoXNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchEnvelopes();
  }

  Future<void> fetchEnvelopes({
    String? search,
    String? status,
    int? importFileId,
    int? supplierId,
    bool includeInactive = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{
        'include_inactive': includeInactive,
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty && status != 'All') queryParams['status'] = status;
      if (importFileId != null) queryParams['import_file_id'] = importFileId;
      if (supplierId != null) queryParams['supplier_id'] = supplierId;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/cargox/envelopes',
        queryParameters: queryParams,
      );

      final List data = response.data as List;
      final envelopes = data.map((json) => CargoXEnvelopeModel.fromJson(json as Map<String, dynamic>)).toList();
      state = AsyncValue.data(envelopes);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<CargoXEnvelopeModel> createEnvelope(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/cargox/envelopes',
        data: payload,
      );
      final created = CargoXEnvelopeModel.fromJson(response.data as Map<String, dynamic>);
      await fetchEnvelopes();
      return created;
    } catch (err) {
      rethrow;
    }
  }

  Future<CargoXEnvelopeModel> updateEnvelope(int envelopeId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/cargox/envelopes/$envelopeId',
        data: payload,
      );
      final updated = CargoXEnvelopeModel.fromJson(response.data as Map<String, dynamic>);
      await fetchEnvelopes();
      return updated;
    } catch (err) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sealAndTransferToCustoms(
    int envelopeId, {
    String? blNumber,
    String mode = 'MOCK',
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/cargox/envelopes/$envelopeId/seal-and-transfer',
        data: {
          if (blNumber != null && blNumber.isNotEmpty) 'bl_number': blNumber,
          'mode': mode,
        },
      );
      await fetchEnvelopes();
      return response.data as Map<String, dynamic>;
    } catch (err) {
      rethrow;
    }
  }

  Future<CargoXAcidVerificationReportModel> verifyAcidConsistency(int envelopeId) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/cargox/envelopes/$envelopeId/verify-acid',
      );
      final report = CargoXAcidVerificationReportModel.fromJson(response.data as Map<String, dynamic>);
      await fetchEnvelopes();
      return report;
    } catch (err) {
      rethrow;
    }
  }

  Future<DigitalManifestModel> fetchDigitalManifest(int envelopeId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/cargox/envelopes/$envelopeId/digital-manifest',
      );
      return DigitalManifestModel.fromJson(response.data as Map<String, dynamic>);
    } catch (err) {
      rethrow;
    }
  }

  Future<void> deleteEnvelope(int envelopeId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/cargox/envelopes/$envelopeId');
      await fetchEnvelopes();
    } catch (err) {
      rethrow;
    }
  }

  Future<void> restoreEnvelope(int envelopeId) async {
    try {
      await _dio.post('${ApiConstants.baseUrl}/cargox/envelopes/$envelopeId/restore');
      await fetchEnvelopes();
    } catch (err) {
      rethrow;
    }
  }
}

// ============================================================================
// STANDARD EXCEL COMMERCIAL INVOICE NOTIFIER & PROVIDERS
// ============================================================================

final standardInvoiceSessionsProvider =
    StateNotifierProvider<StandardInvoiceNotifier, AsyncValue<List<StandardInvoiceSessionModel>>>((ref) {
  return StandardInvoiceNotifier(ref.read(dioProvider));
});

class StandardInvoiceNotifier extends StateNotifier<AsyncValue<List<StandardInvoiceSessionModel>>> {
  final Dio _dio;

  StandardInvoiceNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchSessions();
  }

  Future<void> fetchSessions({
    String? search,
    String? status,
    int? importFileId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty && status != 'All') queryParams['status'] = status;
      if (importFileId != null) queryParams['import_file_id'] = importFileId;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/cargox/standard-invoice/sessions',
        queryParameters: queryParams,
      );

      final List data = response.data as List;
      final sessions = data.map((json) => StandardInvoiceSessionModel.fromJson(json as Map<String, dynamic>)).toList();
      state = AsyncValue.data(sessions);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<List<int>> downloadExcelTemplate(int importFileId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/cargox/standard-invoice/generate/$importFileId',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } catch (err) {
      rethrow;
    }
  }

  Future<StandardInvoicePayloadModel> parseExcelFile(List<int> fileBytes, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/cargox/standard-invoice/parse',
        data: formData,
      );
      return StandardInvoicePayloadModel.fromJson(response.data as Map<String, dynamic>);
    } catch (err) {
      rethrow;
    }
  }

  Future<StandardInvoiceComparisonResponseModel> compareInvoice(
    int importFileId,
    StandardInvoicePayloadModel supplierData,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/cargox/standard-invoice/compare/$importFileId',
        data: supplierData.toJson(),
      );
      return StandardInvoiceComparisonResponseModel.fromJson(response.data as Map<String, dynamic>);
    } catch (err) {
      rethrow;
    }
  }

  Future<StandardInvoiceSessionModel> saveOrUpsertSession(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/cargox/standard-invoice/session',
        data: payload,
      );
      final session = StandardInvoiceSessionModel.fromJson(response.data as Map<String, dynamic>);
      await fetchSessions();
      return session;
    } catch (err) {
      rethrow;
    }
  }

  Future<StandardInvoiceSessionModel?> fetchSessionByFile(int importFileId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/cargox/standard-invoice/session/by-file/$importFileId',
      );
      if (response.data == null) return null;
      return StandardInvoiceSessionModel.fromJson(response.data as Map<String, dynamic>);
    } catch (err) {
      return null;
    }
  }

  Future<StandardInvoiceSessionModel> updateSessionStatus(
    int sessionId,
    String status, {
    String? justification,
    String? notes,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/cargox/standard-invoice/session/$sessionId/status',
        data: {
          'status': status,
          if (justification != null) 'discrepancy_override_reason': justification,
          if (notes != null) 'notes': notes,
        },
      );
      final updated = StandardInvoiceSessionModel.fromJson(response.data as Map<String, dynamic>);
      await fetchSessions();
      return updated;
    } catch (err) {
      rethrow;
    }
  }

  // ==========================================================================
  // CGX-003: MULTI-PATH EXTRACTION & CUSTOMS TRACK API CALLS
  // ==========================================================================

  Future<ExtractionResponseModel> extractMultiMode(
    int importFileId, {
    String mode = 'all_consolidated',
    String groupingMode = 'by_hs_code',
    String? invoiceFilter,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/cargox/standard-invoice/extract/$importFileId',
        data: {
          'mode': mode,
          'grouping_mode': groupingMode,
          if (invoiceFilter != null && invoiceFilter.isNotEmpty) 'invoice_filter': invoiceFilter,
        },
      );
      return ExtractionResponseModel.fromJson(response.data as Map<String, dynamic>);
    } catch (err) {
      rethrow;
    }
  }

  Future<List<int>> downloadMultiInvoiceZip(
    int importFileId, {
    String mode = 'all_consolidated',
    String groupingMode = 'by_hs_code',
    String? invoiceFilter,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/cargox/standard-invoice/generate-zip/$importFileId',
        data: {
          'mode': mode,
          'grouping_mode': groupingMode,
          if (invoiceFilter != null && invoiceFilter.isNotEmpty) 'invoice_filter': invoiceFilter,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } catch (err) {
      rethrow;
    }
  }

  Future<CustomsInvoiceTrackModel> createCustomsTrack(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/cargox/customs-track/create',
        data: payload,
      );
      return CustomsInvoiceTrackModel.fromJson(response.data as Map<String, dynamic>);
    } catch (err) {
      rethrow;
    }
  }

  Future<List<CustomsInvoiceTrackModel>> fetchCustomsTracks(int importFileId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/cargox/customs-track/by-file/$importFileId',
      );
      final List data = response.data as List;
      return data.map((json) => CustomsInvoiceTrackModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (err) {
      return [];
    }
  }

  Future<CustomsInvoiceTrackModel> updateCustomsTrack(int trackId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/cargox/customs-track/$trackId',
        data: payload,
      );
      return CustomsInvoiceTrackModel.fromJson(response.data as Map<String, dynamic>);
    } catch (err) {
      rethrow;
    }
  }

  Future<void> deleteCustomsTrack(int trackId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/cargox/customs-track/$trackId');
    } catch (err) {
      rethrow;
    }
  }

  Future<List<int>> downloadTrackExcel(int trackId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/cargox/customs-track/$trackId/export-excel',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } catch (err) {
      rethrow;
    }
  }

  Future<List<int>> downloadTrackPackingListExcel(int trackId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/cargox/customs-track/$trackId/export-packing-list-excel',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } catch (err) {
      rethrow;
    }
  }
}

