import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/operational_dashboard_model.dart';
import '../../../core/network/api_client.dart';


class OperationalDashboardState {
  final String? selectedPhase;
  final String selectedPriority;
  final String? selectedBrokerName;
  final String searchQuery;
  final AsyncValue<OperationalDashboardData> data;

  OperationalDashboardState({
    this.selectedPhase,
    this.selectedPriority = 'All',
    this.selectedBrokerName,
    this.searchQuery = '',
    this.data = const AsyncValue.loading(),
  });

  OperationalDashboardState copyWith({
    String? selectedPhase,
    bool clearPhase = false,
    String? selectedPriority,
    String? selectedBrokerName,
    bool clearBroker = false,
    String? searchQuery,
    AsyncValue<OperationalDashboardData>? data,
  }) {
    return OperationalDashboardState(
      selectedPhase: clearPhase ? null : (selectedPhase ?? this.selectedPhase),
      selectedPriority: selectedPriority ?? this.selectedPriority,
      selectedBrokerName: clearBroker ? null : (selectedBrokerName ?? this.selectedBrokerName),
      searchQuery: searchQuery ?? this.searchQuery,
      data: data ?? this.data,
    );
  }
}

final operationalDashboardProvider =
    StateNotifierProvider<OperationalDashboardNotifier, OperationalDashboardState>((ref) {
  return OperationalDashboardNotifier(ref.read(dioProvider));
});

class OperationalDashboardNotifier extends StateNotifier<OperationalDashboardState> {
  final Dio _dio;
  Timer? _debounceTimer;

  OperationalDashboardNotifier(this._dio) : super(OperationalDashboardState()) {
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    state = state.copyWith(data: const AsyncValue.loading());
    try {
      final queryParams = <String, dynamic>{};
      if (state.selectedPhase != null && state.selectedPhase != 'All') {
        queryParams['phase'] = state.selectedPhase;
      }
      if (state.selectedPriority != 'All') {
        queryParams['priority'] = state.selectedPriority;
      }
      if (state.selectedBrokerName != null && state.selectedBrokerName != 'All') {
        queryParams['broker_name'] = state.selectedBrokerName;
      }
      if (state.searchQuery.trim().isNotEmpty) {
        queryParams['search'] = state.searchQuery.trim();
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/import-files/operational-dashboard',
        queryParameters: queryParams,
      );

      final parsed = OperationalDashboardData.fromJson(response.data);
      state = state.copyWith(data: AsyncValue.data(parsed));
    } on DioException catch (e, stack) {
      // Graceful Connection Error Fallback
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.error.toString().contains('XMLHttpRequest') ||
          e.error.toString().contains('SocketException')) {
        // Return clear offline fallback data so UI remains interactive
        final fallbackData = OperationalDashboardData(
          shipmentCount: 0,
          shipments: [],
          lastUpdatedAt: DateTime.now().toIso8601String(),
          availableBrokers: [
            DashboardBroker(brokerId: 1, brokerName: 'الأمين للتخليص الجمركي'),
            DashboardBroker(brokerId: 2, brokerName: 'النصر للخدمات اللوجستية'),
          ],
          phaseCounts: {for (var i = 1; i <= 10; i++) 'Phase $i': 0},
        );
        state = state.copyWith(data: AsyncValue.data(fallbackData));
      } else {
        state = state.copyWith(data: AsyncValue.error(e, stack));
      }
    } catch (e, stack) {
      state = state.copyWith(data: AsyncValue.error(e, stack));
    }
  }

  void togglePhase(String phase) {
    if (state.selectedPhase == phase) {
      state = state.copyWith(clearPhase: true);
    } else {
      state = state.copyWith(selectedPhase: phase);
    }
    fetchDashboard();
  }

  void setPriority(String priority) {
    state = state.copyWith(selectedPriority: priority);
    fetchDashboard();
  }

  void setBroker(String? brokerName) {
    if (brokerName == null || brokerName == 'All') {
      state = state.copyWith(clearBroker: true);
    } else {
      state = state.copyWith(selectedBrokerName: brokerName);
    }
    fetchDashboard();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      fetchDashboard();
    });
  }

  void resetFilters() {
    state = OperationalDashboardState();
    fetchDashboard();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
