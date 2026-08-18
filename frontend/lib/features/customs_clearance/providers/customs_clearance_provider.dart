import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/customs_clearance_model.dart';
import '../../../core/network/api_client.dart';


final customsClearanceProvider =
    StateNotifierProvider<CustomsClearanceNotifier, AsyncValue<List<CustomsClearanceModel>>>((ref) {
  return CustomsClearanceNotifier(ref.read(dioProvider));
});

class CustomsClearanceNotifier extends StateNotifier<AsyncValue<List<CustomsClearanceModel>>> {
  final Dio _dio;

  CustomsClearanceNotifier(this._dio) : super(const AsyncValue.loading()) {
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
        '${ApiConstants.baseUrl}/customs-clearance',
        queryParameters: queryParams,
      );

      final List data = response.data;
      final list = data.map((json) => CustomsClearanceModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<CustomsClearanceModel?> createRecord(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/customs-clearance',
        data: payload,
      );
      final created = CustomsClearanceModel.fromJson(response.data);
      await fetchRecords();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<CustomsClearanceModel?> submitDutyPayment(int recordId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/customs-clearance/$recordId/pay-duty',
        data: payload,
      );
      final updated = CustomsClearanceModel.fromJson(response.data);
      await fetchRecords();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<CustomsClearanceModel?> completeRelease(int recordId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/customs-clearance/$recordId/complete-release',
        data: payload,
      );
      final updated = CustomsClearanceModel.fromJson(response.data);
      await fetchRecords();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> softDeleteRecord(int recordId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/customs-clearance/$recordId');
      await fetchRecords();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreRecord(int recordId) async {
    try {
      await _dio.patch('${ApiConstants.baseUrl}/customs-clearance/$recordId/restore');
      await fetchRecords();
    } catch (e) {
      rethrow;
    }
  }
}
