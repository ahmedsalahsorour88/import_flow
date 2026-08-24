import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/cargo_insurance_model.dart';

final cargoInsuranceProvider =
    StateNotifierProvider<CargoInsuranceNotifier, AsyncValue<List<CargoInsuranceModel>>>((ref) {
  return CargoInsuranceNotifier(ref.read(dioProvider));
});

class CargoInsuranceNotifier extends StateNotifier<AsyncValue<List<CargoInsuranceModel>>> {
  final Dio _dio;

  CargoInsuranceNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchCertificates();
  }

  Future<void> fetchCertificates({
    int? importFileId,
    String? status,
    String? search,
  }) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{};
      if (importFileId != null) queryParams['import_file_id'] = importFileId;
      if (status != null && status.isNotEmpty && status != 'All') queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/cargo-insurance/certificates',
        queryParameters: queryParams,
      );

      final List items = response.data['items'] ?? [];
      final list = items.map((json) => CargoInsuranceModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<InsuranceCalculationResultModel> calculateInsurance(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/cargo-insurance/calculate',
        data: payload,
      );
      return InsuranceCalculationResultModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<CargoInsuranceModel> createCertificate(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/cargo-insurance/certificates',
        data: payload,
      );
      final created = CargoInsuranceModel.fromJson(response.data);
      await fetchCertificates();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<CargoInsuranceModel> updateCertificate(int certificateId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/cargo-insurance/certificates/$certificateId',
        data: payload,
      );
      final updated = CargoInsuranceModel.fromJson(response.data);
      await fetchCertificates();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<CargoInsuranceModel> issueCertificate(int certificateId) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/cargo-insurance/certificates/$certificateId/issue',
      );
      final issued = CargoInsuranceModel.fromJson(response.data);
      await fetchCertificates();
      return issued;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCertificate(int certificateId) async {
    try {
      await _dio.delete(
        '${ApiConstants.baseUrl}/cargo-insurance/certificates/$certificateId',
      );
      await fetchCertificates();
    } catch (e) {
      rethrow;
    }
  }
}
