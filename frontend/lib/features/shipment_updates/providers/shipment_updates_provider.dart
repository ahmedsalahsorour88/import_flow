import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/shipment_update_model.dart';

class ShipmentUpdatesState {
  final bool isLoading;
  final String? error;
  final List<ShipmentUpdateLogModel> logs;
  final List<PhaseInspectionModel> inspectedPhases;
  final int? selectedFileId;

  ShipmentUpdatesState({
    this.isLoading = false,
    this.error,
    this.logs = const [],
    this.inspectedPhases = const [],
    this.selectedFileId,
  });

  ShipmentUpdatesState copyWith({
    bool? isLoading,
    String? error,
    List<ShipmentUpdateLogModel>? logs,
    List<PhaseInspectionModel>? inspectedPhases,
    int? selectedFileId,
  }) {
    return ShipmentUpdatesState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      logs: logs ?? this.logs,
      inspectedPhases: inspectedPhases ?? this.inspectedPhases,
      selectedFileId: selectedFileId ?? this.selectedFileId,
    );
  }
}

final shipmentUpdatesProvider =
    StateNotifierProvider<ShipmentUpdatesNotifier, ShipmentUpdatesState>((ref) {
  return ShipmentUpdatesNotifier(ref.read(dioProvider));
});

class ShipmentUpdatesNotifier extends StateNotifier<ShipmentUpdatesState> {
  final Dio _dio;

  ShipmentUpdatesNotifier(this._dio) : super(ShipmentUpdatesState()) {
    fetchLogs();
  }

  Future<void> fetchLogs({
    int? importFileId,
    String? updateCategory,
    String? targetPhase,
    String? search,
  }) async {
    state = state.copyWith(isLoading: true, error: null, selectedFileId: importFileId);
    try {
      final queryParams = <String, dynamic>{};
      if (importFileId != null) queryParams['import_file_id'] = importFileId;
      if (updateCategory != null && updateCategory.isNotEmpty && updateCategory != 'All') queryParams['update_category'] = updateCategory;
      if (targetPhase != null && targetPhase.isNotEmpty && targetPhase != 'All') queryParams['target_phase'] = targetPhase;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final res = await _dio.get('${ApiConstants.baseUrl}/shipment-updates', queryParameters: queryParams);
      final list = (res.data as List).map((x) => ShipmentUpdateLogModel.fromJson(x)).toList();

      List<PhaseInspectionModel> inspections = state.inspectedPhases;
      if (importFileId != null) {
        final resInsp = await _dio.get('${ApiConstants.baseUrl}/shipment-updates/inspect/$importFileId');
        inspections = (resInsp.data as List).map((x) => PhaseInspectionModel.fromJson(x)).toList();
      }

      state = state.copyWith(isLoading: false, logs: list, inspectedPhases: inspections);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<ShipmentUpdateLogModel?> createLog(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('${ApiConstants.baseUrl}/shipment-updates', data: payload);
      final created = ShipmentUpdateLogModel.fromJson(res.data);
      await fetchLogs(importFileId: state.selectedFileId);
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLog(int updateId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/shipment-updates/$updateId');
      await fetchLogs(importFileId: state.selectedFileId);
    } catch (e) {
      rethrow;
    }
  }
}

final shipmentUpdatesProvider = StateNotifierProvider<ShipmentUpdatesNotifier, ShipmentUpdatesState>((ref) {
  return ShipmentUpdatesNotifier();
});
