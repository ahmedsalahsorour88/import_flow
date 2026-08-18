import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/incoterm_model.dart';

import '../../../core/network/api_client.dart';

// ==================================================
// Incoterms Provider (MD-006)
// ==================================================

final showInactiveIncotermsProvider = StateProvider<bool>((ref) => false);

final incotermsProvider =
    StateNotifierProvider<IncotermsNotifier, AsyncValue<List<IncotermModel>>>(
        (ref) {
  final showInactive = ref.watch(showInactiveIncotermsProvider);
  return IncotermsNotifier(ref: ref, showInactive: showInactive, dio: ref.read(dioProvider));
});

class IncotermsNotifier
    extends StateNotifier<AsyncValue<List<IncotermModel>>> {
  final Ref ref;
  final Dio _dio;
  final bool showInactive;

  IncotermsNotifier({required this.ref, required this.showInactive, required Dio dio})
      : _dio = dio, super(const AsyncValue.loading()) {
    fetchIncoterms();
  }

  Future<void> fetchIncoterms() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/incoterms',
        queryParameters: {'include_inactive': showInactive},
      );
      final list = (response.data as List)
          .map((json) => IncotermModel.fromJson(json))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String?> createIncoterm(Map<String, dynamic> data) async {
    try {
      await _dio.post('${ApiConstants.baseUrl}/incoterms', data: data);
      await fetchIncoterms();
      return null;
    } on DioException catch (e) {
      return e.response?.data?['detail']?.toString() ??
          'Failed to create incoterm.';
    } catch (_) {
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> updateIncoterm(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('${ApiConstants.baseUrl}/incoterms/$id', data: data);
      await fetchIncoterms();
      return null;
    } on DioException catch (e) {
      return e.response?.data?['detail']?.toString() ??
          'Failed to update incoterm.';
    } catch (_) {
      return 'An unexpected error occurred.';
    }
  }

  Future<bool> toggleActive(int id, bool currentlyActive) async {
    try {
      if (currentlyActive) {
        await _dio.delete('${ApiConstants.baseUrl}/incoterms/$id');
      } else {
        await _dio.patch('${ApiConstants.baseUrl}/incoterms/$id/restore');
      }
      await fetchIncoterms();
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ==================================================
// Cost Items Provider (MD-006A)
// ==================================================

final showInactiveCostItemsProvider = StateProvider<bool>((ref) => false);

final costItemsProvider =
    StateNotifierProvider<CostItemsNotifier, AsyncValue<List<CostItemModel>>>(
        (ref) {
  final showInactive = ref.watch(showInactiveCostItemsProvider);
  return CostItemsNotifier(ref: ref, showInactive: showInactive);
});

class CostItemsNotifier
    extends StateNotifier<AsyncValue<List<CostItemModel>>> {
  final Ref ref;
  final Dio _dio = Dio();
  final bool showInactive;

  CostItemsNotifier({required this.ref, required this.showInactive})
      : super(const AsyncValue.loading()) {
    fetchCostItems();
  }

  Future<void> fetchCostItems() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/cost-items',
        queryParameters: {'include_inactive': showInactive},
      );
      final list = (response.data as List)
          .map((json) => CostItemModel.fromJson(json))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String?> createCostItem(Map<String, dynamic> data) async {
    try {
      await _dio.post('${ApiConstants.baseUrl}/cost-items', data: data);
      await fetchCostItems();
      return null;
    } on DioException catch (e) {
      return e.response?.data?['detail']?.toString() ??
          'Failed to create cost item.';
    } catch (_) {
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> updateCostItem(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('${ApiConstants.baseUrl}/cost-items/$id', data: data);
      await fetchCostItems();
      return null;
    } on DioException catch (e) {
      return e.response?.data?['detail']?.toString() ??
          'Failed to update cost item.';
    } catch (_) {
      return 'An unexpected error occurred.';
    }
  }

  Future<bool> toggleActive(int id, bool currentlyActive) async {
    try {
      if (currentlyActive) {
        await _dio.delete('${ApiConstants.baseUrl}/cost-items/$id');
      } else {
        await _dio.patch('${ApiConstants.baseUrl}/cost-items/$id/restore');
      }
      await fetchCostItems();
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ==================================================
// Responsibility Matrix Provider (MD-006B)
// ==================================================

final selectedIncotermForMatrixProvider = StateProvider<int?>((ref) => null);

final responsibilityMatrixProvider = StateNotifierProvider<
    ResponsibilityMatrixNotifier,
    AsyncValue<List<IncotermResponsibilityModel>>>((ref) {
  return ResponsibilityMatrixNotifier(ref: ref);
});

class ResponsibilityMatrixNotifier
    extends StateNotifier<AsyncValue<List<IncotermResponsibilityModel>>> {
  final Ref ref;
  final Dio _dio = Dio();

  ResponsibilityMatrixNotifier({required this.ref})
      : super(const AsyncValue.loading()) {
    fetchAll();
  }

  Future<void> fetchAll() async {
    state = const AsyncValue.loading();
    try {
      final response =
          await _dio.get('${ApiConstants.baseUrl}/incoterm-responsibilities');
      final list = (response.data as List)
          .map((json) => IncotermResponsibilityModel.fromJson(json))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<List<IncotermResponsibilityModel>> fetchForIncoterm(
      int incotermId) async {
    try {
      final response = await _dio.get(
          '${ApiConstants.baseUrl}/incoterm-responsibilities/matrix/$incotermId');
      return (response.data as List)
          .map((json) => IncotermResponsibilityModel.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> createResponsibility(Map<String, dynamic> data) async {
    try {
      await _dio.post('${ApiConstants.baseUrl}/incoterm-responsibilities',
          data: data);
      await fetchAll();
      return null;
    } on DioException catch (e) {
      return e.response?.data?['detail']?.toString() ??
          'Failed to create responsibility.';
    } catch (_) {
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> updateResponsibility(
      int id, Map<String, dynamic> data) async {
    try {
      await _dio.put(
          '${ApiConstants.baseUrl}/incoterm-responsibilities/$id',
          data: data);
      await fetchAll();
      return null;
    } on DioException catch (e) {
      return e.response?.data?['detail']?.toString() ??
          'Failed to update responsibility.';
    } catch (_) {
      return 'An unexpected error occurred.';
    }
  }

  Future<bool> deleteResponsibility(int id) async {
    try {
      await _dio
          .delete('${ApiConstants.baseUrl}/incoterm-responsibilities/$id');
      await fetchAll();
      return true;
    } catch (_) {
      return false;
    }
  }
}
