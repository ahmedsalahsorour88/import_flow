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
