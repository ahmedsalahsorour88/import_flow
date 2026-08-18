import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../shipping_scenarios/providers/shipping_scenarios_provider.dart';
import '../models/purchase_order_model.dart';

class PurchaseOrdersState {
  final List<PurchaseOrderModel> purchaseOrders;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String? statusFilter;
  final int? projectFilter;
  final bool showInactive;

  PurchaseOrdersState({
    this.purchaseOrders = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.statusFilter,
    this.projectFilter,
    this.showInactive = false,
  });

  PurchaseOrdersState copyWith({
    List<PurchaseOrderModel>? purchaseOrders,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? statusFilter,
    int? projectFilter,
    bool? showInactive,
  }) {
    return PurchaseOrdersState(
      purchaseOrders: purchaseOrders ?? this.purchaseOrders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      projectFilter: projectFilter ?? this.projectFilter,
      showInactive: showInactive ?? this.showInactive,
    );
  }
}

class PurchaseOrdersNotifier extends StateNotifier<PurchaseOrdersState> {
  final Dio _dio;
  final Ref _ref;

  PurchaseOrdersNotifier(this._dio, this._ref) : super(PurchaseOrdersState()) {
    fetchPurchaseOrders();
  }

  Future<void> fetchPurchaseOrders() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _dio.get(
        '/purchase-orders',
        queryParameters: {
          'include_inactive': state.showInactive,
          if (state.statusFilter != null && state.statusFilter!.isNotEmpty) 'status': state.statusFilter,
          if (state.projectFilter != null) 'project_id': state.projectFilter,
          if (state.searchQuery.isNotEmpty) 'search': state.searchQuery,
        },
      );
      final List data = response.data;
      final list = data.map((json) => PurchaseOrderModel.fromJson(json)).toList();
      state = state.copyWith(purchaseOrders: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load purchase orders: ${e.toString()}',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    fetchPurchaseOrders();
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status);
    fetchPurchaseOrders();
  }

  void setProjectFilter(int? projectId) {
    state = state.copyWith(projectFilter: projectId);
    fetchPurchaseOrders();
  }

  void toggleShowInactive(bool val) {
    state = state.copyWith(showInactive: val);
    fetchPurchaseOrders();
  }

  Future<String?> createPurchaseOrder(PurchaseOrderModel po) async {
    try {
      await _dio.post('/purchase-orders', data: po.toJson());
      await fetchPurchaseOrders();
      _ref.read(importFilesProvider.notifier).fetchImportFiles();
      _ref.read(shippingScenariosProvider.notifier).fetchSessions();
      return null;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      String msg = 'Failed to create purchase order.';
      if (detail != null) {
        if (detail is List) {
          msg = detail.map((d) => d['msg'] ?? d.toString()).join('\n');
        } else {
          msg = detail.toString();
        }
      } else if (e.message != null) {
        msg = e.message!;
      }
      state = state.copyWith(errorMessage: msg);
      return msg;
    } catch (e) {
      final msg = 'Failed to create purchase order: ${e.toString()}';
      state = state.copyWith(errorMessage: msg);
      return msg;
    }
  }

  Future<String?> updatePurchaseOrder(int poId, Map<String, dynamic> data) async {
    try {
      await _dio.put('/purchase-orders/$poId', data: data);
      await fetchPurchaseOrders();
      _ref.read(importFilesProvider.notifier).fetchImportFiles();
      _ref.read(shippingScenariosProvider.notifier).fetchSessions();
      return null;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      String msg = 'Failed to update purchase order.';
      if (detail != null) {
        if (detail is List) {
          msg = detail.map((d) => d['msg'] ?? d.toString()).join('\n');
        } else {
          msg = detail.toString();
        }
      } else if (e.message != null) {
        msg = e.message!;
      }
      state = state.copyWith(errorMessage: msg);
      return msg;
    } catch (e) {
      final msg = 'Failed to update purchase order: ${e.toString()}';
      state = state.copyWith(errorMessage: msg);
      return msg;
    }
  }

  Future<bool> deletePurchaseOrder(int poId) async {
    try {
      await _dio.delete('/purchase-orders/$poId');
      await fetchPurchaseOrders();
      _ref.read(importFilesProvider.notifier).fetchImportFiles();
      _ref.read(shippingScenariosProvider.notifier).fetchSessions();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete purchase order: ${e.toString()}');
      return false;
    }
  }

  Future<bool> restorePurchaseOrder(int poId) async {
    try {
      await _dio.post('/purchase-orders/$poId/restore');
      await fetchPurchaseOrders();
      _ref.read(importFilesProvider.notifier).fetchImportFiles();
      _ref.read(shippingScenariosProvider.notifier).fetchSessions();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to restore purchase order: ${e.toString()}');
      return false;
    }
  }
}

final purchaseOrdersDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 180),
    receiveTimeout: const Duration(seconds: 180),
  ));
});

final purchaseOrdersProvider = StateNotifierProvider<PurchaseOrdersNotifier, PurchaseOrdersState>((ref) {
  final dio = ref.watch(purchaseOrdersDioProvider);
  return PurchaseOrdersNotifier(dio, ref);
});
