import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/customs_consultation_model.dart';

final customsConsultationsProvider =
    StateNotifierProvider<CustomsConsultationNotifier, AsyncValue<List<CustomsConsultationModel>>>((ref) {
  return CustomsConsultationNotifier();
});

class CustomsConsultationNotifier extends StateNotifier<AsyncValue<List<CustomsConsultationModel>>> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  CustomsConsultationNotifier() : super(const AsyncValue.loading()) {
    fetchConsultations();
  }

  Future<void> fetchConsultations({
    bool includeInactive = false,
    String? search,
    int? brokerId,
    int? poId,
    int? projectId,
    String? status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{
        'include_inactive': includeInactive,
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (brokerId != null) queryParams['broker_id'] = brokerId;
      if (poId != null) queryParams['po_id'] = poId;
      if (projectId != null) queryParams['project_id'] = projectId;
      if (status != null && status.isNotEmpty && status != 'All') queryParams['status'] = status;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/api/v1/customs-consultations',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      final consultations = data.map((json) => CustomsConsultationModel.fromJson(json)).toList();
      state = AsyncValue.data(consultations);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<CustomsConsultationModel?> createConsultation(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/v1/customs-consultations',
        data: payload,
      );
      final newConsultation = CustomsConsultationModel.fromJson(response.data);
      await fetchConsultations();
      return newConsultation;
    } catch (e) {
      rethrow;
    }
  }

  Future<CustomsConsultationModel?> updateConsultation(int consultationId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/api/v1/customs-consultations/$consultationId',
        data: payload,
      );
      final updated = CustomsConsultationModel.fromJson(response.data);
      await fetchConsultations();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> softDeleteConsultation(int consultationId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/api/v1/customs-consultations/$consultationId');
      await fetchConsultations();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreConsultation(int consultationId) async {
    try {
      await _dio.post('${ApiConstants.baseUrl}/api/v1/customs-consultations/$consultationId/restore');
      await fetchConsultations();
    } catch (e) {
      rethrow;
    }
  }
}
