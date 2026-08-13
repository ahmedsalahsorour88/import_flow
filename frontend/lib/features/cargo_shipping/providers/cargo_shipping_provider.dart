import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/cargo_shipping_model.dart';

final cargoShippingProvider =
    StateNotifierProvider<CargoShippingNotifier, AsyncValue<List<CargoShippingModel>>>((ref) {
  return CargoShippingNotifier();
});

class CargoShippingNotifier extends StateNotifier<AsyncValue<List<CargoShippingModel>>> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  CargoShippingNotifier() : super(const AsyncValue.loading()) {
    fetchRecords();
  }

  Future<void> fetchRecords({
    bool includeInactive = false,
    int? importFileId,
    String? status,
    String? search,
  }) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{'include_inactive': includeInactive};
      if (importFileId != null) queryParams['import_file_id'] = importFileId;
      if (status != null && status.isNotEmpty && status != 'All') queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/cargo-shipping',
        queryParameters: queryParams,
      );

      final List data = response.data;
      final list = data.map((json) => CargoShippingModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<CargoShippingModel?> createRecord(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/cargo-shipping',
        data: payload,
      );
      final created = CargoShippingModel.fromJson(response.data);
      await fetchRecords();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<CargoShippingModel?> submitLevel1Approval(int recordId, String approvedBy, bool approved, {String? notes}) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/cargo-shipping/$recordId/approval/level1',
        data: {'approved_by': approvedBy, 'approved': approved, 'notes': notes},
      );
      final updated = CargoShippingModel.fromJson(response.data);
      await fetchRecords();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<CargoShippingModel?> submitLevel2Approval(int recordId, String approvedBy, bool approved, {String? notes}) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/cargo-shipping/$recordId/approval/level2',
        data: {'approved_by': approvedBy, 'approved': approved, 'notes': notes},
      );
      final updated = CargoShippingModel.fromJson(response.data);
      await fetchRecords();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<CargoShippingModel?> runCargoXChecklist(int recordId) async {
    try {
      final response = await _dio.post('${ApiConstants.baseUrl}/cargo-shipping/$recordId/cargox/run-checklist');
      final updated = CargoShippingModel.fromJson(response.data);
      await fetchRecords();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<CargoShippingModel?> advanceCargoXStage(int recordId, String targetStage) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/cargo-shipping/$recordId/cargox/advance-stage',
        queryParameters: {'target_stage': targetStage},
      );
      final updated = CargoShippingModel.fromJson(response.data);
      await fetchRecords();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> softDeleteRecord(int recordId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/cargo-shipping/$recordId');
      await fetchRecords();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreRecord(int recordId) async {
    try {
      await _dio.patch('${ApiConstants.baseUrl}/cargo-shipping/$recordId/restore');
      await fetchRecords();
    } catch (e) {
      rethrow;
    }
  }
}
