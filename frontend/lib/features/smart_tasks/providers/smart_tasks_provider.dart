import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/smart_task_model.dart';

class SmartTasksState {
  final bool isLoading;
  final String? error;
  final List<SmartTaskModel> tasks;
  final SmartTaskSummaryMetricsModel? metrics;

  SmartTasksState({
    this.isLoading = false,
    this.error,
    this.tasks = const [],
    this.metrics,
  });

  SmartTasksState copyWith({
    bool? isLoading,
    String? error,
    List<SmartTaskModel>? tasks,
    SmartTaskSummaryMetricsModel? metrics,
  }) {
    return SmartTasksState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      tasks: tasks ?? this.tasks,
      metrics: metrics ?? this.metrics,
    );
  }
}

final smartTasksProvider =
    StateNotifierProvider<SmartTasksNotifier, SmartTasksState>((ref) {
  return SmartTasksNotifier(ref.read(dioProvider));
});

class SmartTasksNotifier extends StateNotifier<SmartTasksState> {
  final Dio _dio;
  CancelToken? _cancelToken;

  SmartTasksNotifier(this._dio) : super(SmartTasksState()) {
    fetchTasks();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('SmartTasksNotifier disposed');
    super.dispose();
  }

  Future<void> fetchTasks({
    String? taskType,
    String? status,
    String? priority,
    int? importFileId,
    String? search,
  }) async {
    _cancelToken?.cancel('Cancelled by new fetchTasks request');
    _cancelToken = CancelToken();
    state = state.copyWith(isLoading: true, error: null);
    try {
      final queryParams = <String, dynamic>{};
      if (taskType != null && taskType.isNotEmpty && taskType != 'All') queryParams['task_type'] = taskType;
      if (status != null && status.isNotEmpty && status != 'All') queryParams['status'] = status;
      if (priority != null && priority.isNotEmpty && priority != 'All') queryParams['priority'] = priority;
      if (importFileId != null) queryParams['import_file_id'] = importFileId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final resTasks = await _dio.get(
        '${ApiConstants.baseUrl}/smart-tasks',
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );
      final list = (resTasks.data as List).map((x) => SmartTaskModel.fromJson(x)).toList();

      final resMetrics = await _dio.get(
        '${ApiConstants.baseUrl}/smart-tasks/metrics/summary',
        cancelToken: _cancelToken,
      );
      final metrics = SmartTaskSummaryMetricsModel.fromJson(resMetrics.data);

      state = state.copyWith(isLoading: false, tasks: list, metrics: metrics);
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<SmartTaskModel?> createTask(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('${ApiConstants.baseUrl}/smart-tasks', data: payload);
      final created = SmartTaskModel.fromJson(res.data);
      await fetchTasks();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<SmartTaskModel?> updateTask(int taskId, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put('${ApiConstants.baseUrl}/smart-tasks/$taskId', data: payload);
      final updated = SmartTaskModel.fromJson(res.data);
      await fetchTasks();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(int taskId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/smart-tasks/$taskId');
      await fetchTasks();
    } catch (e) {
      rethrow;
    }
  }
}
