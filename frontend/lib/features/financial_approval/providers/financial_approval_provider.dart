import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/financial_approval_model.dart';

final paymentRequestsProvider =
    StateNotifierProvider<PaymentRequestsNotifier, AsyncValue<List<PaymentRequestModel>>>((ref) {
  return PaymentRequestsNotifier();
});

class PaymentRequestsNotifier extends StateNotifier<AsyncValue<List<PaymentRequestModel>>> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  PaymentRequestsNotifier() : super(const AsyncValue.loading()) {
    fetchPaymentRequests();
  }

  Future<void> fetchPaymentRequests({
    bool includeInactive = false,
    String? search,
    int? poId,
    int? supplierId,
    String? status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{
        'include_inactive': includeInactive,
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (poId != null) queryParams['po_id'] = poId;
      if (supplierId != null) queryParams['supplier_id'] = supplierId;
      if (status != null && status.isNotEmpty && status != 'All') queryParams['status'] = status;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/api/v1/financial-approval/payment-requests',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      final requests = data.map((json) => PaymentRequestModel.fromJson(json)).toList();
      state = AsyncValue.data(requests);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<PaymentRequestModel?> createPaymentRequest(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/v1/financial-approval/payment-requests',
        data: payload,
      );
      final created = PaymentRequestModel.fromJson(response.data);
      await fetchPaymentRequests();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<PaymentRequestModel?> approvePaymentRequest(int paymentId) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/v1/financial-approval/payment-requests/$paymentId/approve',
      );
      final approved = PaymentRequestModel.fromJson(response.data);
      await fetchPaymentRequests();
      return approved;
    } catch (e) {
      rethrow;
    }
  }

  Future<PaymentRequestModel?> executePayment(int paymentId, {String? swiftRef}) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/v1/financial-approval/payment-requests/$paymentId/pay',
        queryParameters: swiftRef != null ? {'swift_reference_no': swiftRef} : null,
      );
      final paid = PaymentRequestModel.fromJson(response.data);
      await fetchPaymentRequests();
      return paid;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> softDeletePaymentRequest(int paymentId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/api/v1/financial-approval/payment-requests/$paymentId');
      await fetchPaymentRequests();
    } catch (e) {
      rethrow;
    }
  }
}

final importBudgetsProvider =
    StateNotifierProvider<ImportBudgetsNotifier, AsyncValue<List<ImportBudgetModel>>>((ref) {
  return ImportBudgetsNotifier();
});

class ImportBudgetsNotifier extends StateNotifier<AsyncValue<List<ImportBudgetModel>>> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  ImportBudgetsNotifier() : super(const AsyncValue.loading()) {
    fetchImportBudgets();
  }

  Future<void> fetchImportBudgets({
    bool includeInactive = false,
    String? search,
    int? poId,
    String? budgetStatus,
  }) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{
        'include_inactive': includeInactive,
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (poId != null) queryParams['po_id'] = poId;
      if (budgetStatus != null && budgetStatus.isNotEmpty && budgetStatus != 'All') {
        queryParams['budget_status'] = budgetStatus;
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/api/v1/financial-approval/import-budgets',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      final budgets = data.map((json) => ImportBudgetModel.fromJson(json)).toList();
      state = AsyncValue.data(budgets);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<ImportBudgetModel?> createImportBudget(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/v1/financial-approval/import-budgets',
        data: payload,
      );
      final created = ImportBudgetModel.fromJson(response.data);
      await fetchImportBudgets();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<ImportBudgetModel?> approveImportBudget(int budgetId, {String approvedBy = 'Finance Manager'}) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/v1/financial-approval/import-budgets/$budgetId/approve',
        queryParameters: {'approved_by': approvedBy},
      );
      final approved = ImportBudgetModel.fromJson(response.data);
      await fetchImportBudgets();
      return approved;
    } catch (e) {
      rethrow;
    }
  }
}
