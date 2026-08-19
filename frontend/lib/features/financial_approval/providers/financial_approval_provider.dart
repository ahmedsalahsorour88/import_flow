import 'dart:typed_data';
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
        '${ApiConstants.baseUrl}/financial-approval/payment-requests',
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
        '${ApiConstants.baseUrl}/financial-approval/payment-requests',
        data: payload,
      );
      final created = PaymentRequestModel.fromJson(response.data);
      await fetchPaymentRequests();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<PaymentRequestModel?> updatePaymentRequest(int paymentId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/financial-approval/payment-requests/$paymentId',
        data: payload,
      );
      final updated = PaymentRequestModel.fromJson(response.data);
      await fetchPaymentRequests();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<PaymentRequestModel?> approvePaymentRequest(int paymentId) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/financial-approval/payment-requests/$paymentId/approve',
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
        '${ApiConstants.baseUrl}/financial-approval/payment-requests/$paymentId/pay',
        queryParameters: swiftRef != null ? {'swift_reference_no': swiftRef} : null,
      );
      final paid = PaymentRequestModel.fromJson(response.data);
      await fetchPaymentRequests();
      return paid;
    } catch (e) {
      rethrow;
    }
  }

  Future<PaymentRequestModel?> reconcileSwift({
    required int paymentId,
    required String swiftReferenceNo,
    required String swiftReceiptDate,
    required double swiftTransferredAmount,
    String swiftTransferredCurrency = 'USD',
    String? swiftReconciliationNotes,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/financial-approval/payment-requests/$paymentId/reconcile-swift',
        data: {
          'swift_reference_no': swiftReferenceNo,
          'swift_receipt_date': swiftReceiptDate,
          'swift_transferred_amount': swiftTransferredAmount,
          'swift_transferred_currency': swiftTransferredCurrency,
          if (swiftReconciliationNotes != null && swiftReconciliationNotes.isNotEmpty)
            'swift_reconciliation_notes': swiftReconciliationNotes,
        },
      );
      final reconciled = PaymentRequestModel.fromJson(response.data);
      await fetchPaymentRequests();
      return reconciled;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> smartExtractSwift({
    required String rawText,
    int? targetPaymentId,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/financial-approval/swift/smart-extract',
        data: {
          'raw_text': rawText,
          if (targetPaymentId != null) 'target_payment_id': targetPaymentId,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> smartExtractSwiftFromFile({
    required Uint8List fileBytes,
    required String filename,
    int? targetPaymentId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: filename),
        if (targetPaymentId != null) 'target_payment_id': targetPaymentId,
      });
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/financial-approval/swift/smart-extract-file',
        data: formData,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<PaymentRequestModel?> smartReconcileSwift({
    required int paymentId,
    String? rawText,
    required String swiftReferenceNo,
    required String swiftReceiptDate,
    required double swiftTransferredAmount,
    String swiftTransferredCurrency = 'USD',
    String? bankName,
    String? swiftCode,
    String? ibanAccountNo,
    String? swiftReconciliationNotes,
    bool autoExecute = true,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/financial-approval/swift/smart-reconcile',
        data: {
          'payment_id': paymentId,
          if (rawText != null) 'raw_text': rawText,
          'swift_reference_no': swiftReferenceNo,
          'swift_receipt_date': swiftReceiptDate,
          'swift_transferred_amount': swiftTransferredAmount,
          'swift_transferred_currency': swiftTransferredCurrency,
          if (bankName != null) 'bank_name': bankName,
          if (swiftCode != null) 'swift_code': swiftCode,
          if (ibanAccountNo != null) 'iban_account_no': ibanAccountNo,
          if (swiftReconciliationNotes != null) 'swift_reconciliation_notes': swiftReconciliationNotes,
          'auto_execute': autoExecute,
        },
      );
      final reconciled = PaymentRequestModel.fromJson(response.data);
      await fetchPaymentRequests();
      return reconciled;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> softDeletePaymentRequest(int paymentId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/financial-approval/payment-requests/$paymentId');
      await fetchPaymentRequests();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restorePaymentRequest(int paymentId) async {
    try {
      await _dio.post('${ApiConstants.baseUrl}/financial-approval/payment-requests/$paymentId/restore');
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
        '${ApiConstants.baseUrl}/financial-approval/import-budgets',
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
        '${ApiConstants.baseUrl}/financial-approval/import-budgets',
        data: payload,
      );
      final created = ImportBudgetModel.fromJson(response.data);
      await fetchImportBudgets();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<ImportBudgetModel?> updateImportBudget(int budgetId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/financial-approval/import-budgets/$budgetId',
        data: payload,
      );
      final updated = ImportBudgetModel.fromJson(response.data);
      await fetchImportBudgets();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> softDeleteImportBudget(int budgetId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/financial-approval/import-budgets/$budgetId');
      await fetchImportBudgets();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreImportBudget(int budgetId) async {
    try {
      await _dio.post('${ApiConstants.baseUrl}/financial-approval/import-budgets/$budgetId/restore');
      await fetchImportBudgets();
    } catch (e) {
      rethrow;
    }
  }

  Future<ImportBudgetModel?> approveImportBudget(int budgetId, {String approvedBy = 'Finance Manager'}) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/financial-approval/import-budgets/$budgetId/approve',
        queryParameters: {'approved_by': approvedBy},
      );
      final approved = ImportBudgetModel.fromJson(response.data);
      await fetchImportBudgets();
      return approved;
    } catch (e) {
      rethrow;
    }
  }

  Future<BudgetPrefillModel?> fetchBudgetPrefill(int importFileId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/financial-approval/prefill/$importFileId',
      );
      return BudgetPrefillModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
}
