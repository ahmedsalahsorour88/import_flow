import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/customs_consultation_model.dart';
import '../../../core/network/api_client.dart';


// ==============================================================================
// Clearance Expense Types Provider
// ==============================================================================

final clearanceExpenseTypesProvider =
    StateNotifierProvider<ClearanceExpenseTypesNotifier, AsyncValue<List<ClearanceExpenseTypeModel>>>((ref) {
  return ClearanceExpenseTypesNotifier(ref.read(dioProvider));
});

class ClearanceExpenseTypesNotifier extends StateNotifier<AsyncValue<List<ClearanceExpenseTypeModel>>> {
  final Dio _dio;

  ClearanceExpenseTypesNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchExpenseTypes();
  }

  Future<void> fetchExpenseTypes({
    bool includeInactive = false,
    String? category,
    String? search,
  }) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{
        'include_inactive': includeInactive,
      };
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/customs-consultations/expense-types',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      final items = data.map((json) => ClearanceExpenseTypeModel.fromJson(json)).toList();
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<ClearanceExpenseTypeModel?> createExpenseType(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/customs-consultations/expense-types',
        data: payload,
      );
      final item = ClearanceExpenseTypeModel.fromJson(response.data);
      await fetchExpenseTypes();
      return item;
    } catch (e) {
      rethrow;
    }
  }

  Future<ClearanceExpenseTypeModel?> updateExpenseType(int expenseId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/customs-consultations/expense-types/$expenseId',
        data: payload,
      );
      final item = ClearanceExpenseTypeModel.fromJson(response.data);
      await fetchExpenseTypes();
      return item;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteExpenseType(int expenseId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/customs-consultations/expense-types/$expenseId');
      await fetchExpenseTypes();
    } catch (e) {
      rethrow;
    }
  }
}

// ==============================================================================
// Broker Price Lists Provider
// ==============================================================================

final brokerPriceListsProvider =
    StateNotifierProvider<BrokerPriceListsNotifier, AsyncValue<List<BrokerPriceListModel>>>((ref) {
  return BrokerPriceListsNotifier(ref.read(dioProvider));
});

class BrokerPriceListsNotifier extends StateNotifier<AsyncValue<List<BrokerPriceListModel>>> {
  final Dio _dio;

  BrokerPriceListsNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchPriceLists();
  }

  Future<void> fetchPriceLists({
    bool includeInactive = false,
    int? brokerId,
    String? search,
  }) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{
        'include_inactive': includeInactive,
      };
      if (brokerId != null) queryParams['broker_id'] = brokerId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/customs-consultations/price-lists',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      final items = data.map((json) => BrokerPriceListModel.fromJson(json)).toList();
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<BrokerPriceListModel?> getActivePriceListForBroker(int brokerId, {String? targetDate}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (targetDate != null) queryParams['target_date'] = targetDate;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/customs-consultations/price-lists/active/$brokerId',
        queryParameters: queryParams,
      );
      if (response.data == null) return null;
      return BrokerPriceListModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<BrokerPriceListModel?> createPriceList(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/customs-consultations/price-lists',
        data: payload,
      );
      final pl = BrokerPriceListModel.fromJson(response.data);
      await fetchPriceLists();
      return pl;
    } catch (e) {
      rethrow;
    }
  }

  Future<BrokerPriceListModel?> updatePriceList(int priceListId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/customs-consultations/price-lists/$priceListId',
        data: payload,
      );
      final pl = BrokerPriceListModel.fromJson(response.data);
      await fetchPriceLists();
      return pl;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> softDeletePriceList(int priceListId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/customs-consultations/price-lists/$priceListId');
      await fetchPriceLists();
    } catch (e) {
      rethrow;
    }
  }
}

// ==============================================================================
// Customs Consultations Provider
// ==============================================================================

final customsConsultationsProvider =
    StateNotifierProvider<CustomsConsultationNotifier, AsyncValue<List<CustomsConsultationModel>>>((ref) {
  return CustomsConsultationNotifier(ref.read(dioProvider));
});

class CustomsConsultationNotifier extends StateNotifier<AsyncValue<List<CustomsConsultationModel>>> {
  final Dio _dio;

  CustomsConsultationNotifier(this._dio) : super(const AsyncValue.loading()) {
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
        '${ApiConstants.baseUrl}/customs-consultations',
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
        '${ApiConstants.baseUrl}/customs-consultations',
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
        '${ApiConstants.baseUrl}/customs-consultations/$consultationId',
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
      await _dio.delete('${ApiConstants.baseUrl}/customs-consultations/$consultationId');
      await fetchConsultations();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreConsultation(int consultationId) async {
    try {
      await _dio.post('${ApiConstants.baseUrl}/customs-consultations/$consultationId/restore');
      await fetchConsultations();
    } catch (e) {
      rethrow;
    }
  }

  Future<CustomsRecalculationResponseModel> recalculateFromReconciliation({
    required int importFileId,
    double? exchangeRate,
    double? freightEgp,
    double? insuranceEgp,
    String? estimateDate,
  }) async {
    try {
      final payload = <String, dynamic>{
        'import_file_id': importFileId,
        if (exchangeRate != null) 'exchange_rate': exchangeRate,
        if (freightEgp != null) 'freight_egp': freightEgp,
        if (insuranceEgp != null) 'insurance_egp': insuranceEgp,
        if (estimateDate != null) 'estimate_date': estimateDate,
      };
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/customs-consultations/recalculate-from-reconciliation',
        data: payload,
      );
      return CustomsRecalculationResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

