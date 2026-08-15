import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/demurrage_model.dart';

class DemurrageState {
  final List<DemurragePolicyModel> policies;
  final List<DemurrageTrackingModel> trackings;
  final DemurrageSimulationResultModel? simulationResult;
  final bool isLoading;
  final String? error;

  const DemurrageState({
    this.policies = const [],
    this.trackings = const [],
    this.simulationResult,
    this.isLoading = false,
    this.error,
  });

  DemurrageState copyWith({
    List<DemurragePolicyModel>? policies,
    List<DemurrageTrackingModel>? trackings,
    DemurrageSimulationResultModel? simulationResult,
    bool? isLoading,
    String? error,
  }) {
    return DemurrageState(
      policies: policies ?? this.policies,
      trackings: trackings ?? this.trackings,
      simulationResult: simulationResult ?? this.simulationResult,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DemurrageNotifier extends StateNotifier<DemurrageState> {
  final Dio _dio;

  DemurrageNotifier()
      : _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)),
        super(const DemurrageState());

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.wait([
        fetchPolicies(),
        fetchTrackings(),
      ]);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchPolicies({String? carrierName}) async {
    try {
      final res = await _dio.get(
        '/demurrage-detention/policies',
        queryParameters: carrierName != null ? {'carrier_name': carrierName} : null,
      );
      if (res.data is List) {
        final policies = (res.data as List)
            .map((e) => DemurragePolicyModel.fromJson(e))
            .toList();
        state = state.copyWith(policies: policies, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchTrackings({int? importFileId, String? carrierName, String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (importFileId != null) queryParams['import_file_id'] = importFileId;
      if (carrierName != null) queryParams['carrier_name'] = carrierName;
      if (status != null) queryParams['status'] = status;

      final res = await _dio.get(
        '/demurrage-detention/trackings',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (res.data is List) {
        final trackings = (res.data as List)
            .map((e) => DemurrageTrackingModel.fromJson(e))
            .toList();
        state = state.copyWith(trackings: trackings, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<DemurrageSimulationResultModel?> simulateCalculation(Map<String, dynamic> requestPayload) async {
    try {
      final res = await _dio.post('/demurrage-detention/simulate', data: requestPayload);
      if (res.data is Map<String, dynamic>) {
        final result = DemurrageSimulationResultModel.fromJson(res.data);
        state = state.copyWith(simulationResult: result);
        return result;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
    return null;
  }

  Future<bool> createTracking(Map<String, dynamic> trackingData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.post('/demurrage-detention/trackings', data: trackingData);
      await fetchTrackings();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateTrackingDates(int trackingId, {String? gateOutDate, String? emptyReturnDate}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final payload = <String, dynamic>{};
      if (gateOutDate != null) payload['gate_out_date'] = gateOutDate;
      if (emptyReturnDate != null) payload['empty_return_date'] = emptyReturnDate;

      await _dio.put('/demurrage-detention/trackings/$trackingId', data: payload);
      await fetchTrackings();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>?> pushToSettlement(int trackingId, {int? importFileId}) async {
    try {
      final res = await _dio.post(
        '/demurrage-detention/trackings/push-to-settlement',
        data: {'tracking_id': trackingId, 'import_file_id': importFileId},
      );
      await fetchTrackings();
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> createPolicy(Map<String, dynamic> policyData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.post('/demurrage-detention/policies', data: policyData);
      await fetchPolicies();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final demurrageProvider = StateNotifierProvider<DemurrageNotifier, DemurrageState>((ref) {
  return DemurrageNotifier();
});
