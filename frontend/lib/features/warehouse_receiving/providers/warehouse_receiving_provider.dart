import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/warehouse_receiving_model.dart';
import '../../../core/network/api_client.dart';


final warehouseReceivingProvider =
    StateNotifierProvider<WarehouseReceivingNotifier, AsyncValue<List<WarehouseReceivingModel>>>((ref) {
  return WarehouseReceivingNotifier(ref.read(dioProvider));
});

class WarehouseReceivingNotifier extends StateNotifier<AsyncValue<List<WarehouseReceivingModel>>> {
  final Dio _dio;
  CancelToken? _cancelToken;

  WarehouseReceivingNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchRecords();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('WarehouseReceivingNotifier disposed');
    super.dispose();
  }

  Future<void> fetchRecords({
    bool includeInactive = false,
    int? importFileId,
    String? status,
    String? search,
  }) async {
    _cancelToken?.cancel('Cancelled by new fetchRecords request');
    _cancelToken = CancelToken();

    // Preserve previous data during refresh if available
    if (state.valueOrNull == null) {
      state = const AsyncValue.loading();
    }

    try {
      final queryParams = <String, dynamic>{'include_inactive': includeInactive};
      if (importFileId != null) queryParams['import_file_id'] = importFileId;
      if (status != null && status.isNotEmpty && status != 'All') queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/warehouse-receiving',
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      final List data = response.data;
      final list = data.map((json) => WarehouseReceivingModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return;
      }
      state = AsyncValue.error(e, stack);
    }
  }

  Future<WarehouseReceivingModel?> createRecord(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/warehouse-receiving',
        data: payload,
      );
      final created = WarehouseReceivingModel.fromJson(response.data);
      await fetchRecords();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<WarehouseReceivingModel?> updateRecord(int recordId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/warehouse-receiving/$recordId',
        data: payload,
      );
      final updated = WarehouseReceivingModel.fromJson(response.data);
      await fetchRecords();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<WarehouseReceivingModel?> reportDiscrepancy(int recordId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/warehouse-receiving/$recordId/report-discrepancy',
        data: payload,
      );
      final updated = WarehouseReceivingModel.fromJson(response.data);
      await fetchRecords();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> softDeleteRecord(int recordId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/warehouse-receiving/$recordId');
      await fetchRecords();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreRecord(int recordId) async {
    try {
      await _dio.patch('${ApiConstants.baseUrl}/warehouse-receiving/$recordId/restore');
      await fetchRecords();
    } catch (e) {
      rethrow;
    }
  }
}
