import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/financial_settlement_model.dart';
import '../../../core/network/api_client.dart';


final financialSettlementProvider =
    StateNotifierProvider<FinancialSettlementNotifier, AsyncValue<List<LandedCostSettlementModel>>>((ref) {
  return FinancialSettlementNotifier(ref.read(dioProvider));
});

class FinancialSettlementNotifier extends StateNotifier<AsyncValue<List<LandedCostSettlementModel>>> {
  final Dio _dio;

  FinancialSettlementNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchSettlements();
  }

  Future<void> fetchSettlements({
    bool includeInactive = false,
    int? importFileId,
    String? status,
    String? search,
  }) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{'include_inactive': includeInactive};
      if (importFileId != null) queryParams['import_file_id'] = importFileId;
      if (status != null && status.isNotEmpty && status != 'All') queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/financial-settlement',
        queryParameters: queryParams,
      );

      final List data = response.data;
      final list = data.map((json) => LandedCostSettlementModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<LandedCostSettlementModel?> createSettlement(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/financial-settlement',
        data: payload,
      );
      final created = LandedCostSettlementModel.fromJson(response.data);
      await fetchSettlements();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<LandedCostSettlementModel?> recalculateSettlement(int settlementId) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/financial-settlement/$settlementId/recalculate',
      );
      final updated = LandedCostSettlementModel.fromJson(response.data);
      await fetchSettlements();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> softDeleteSettlement(int settlementId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/financial-settlement/$settlementId');
      await fetchSettlements();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreSettlement(int settlementId) async {
    try {
      await _dio.patch('${ApiConstants.baseUrl}/financial-settlement/$settlementId/restore');
      await fetchSettlements();
    } catch (e) {
      rethrow;
    }
  }

  Future<OdooJournalEntryModel> fetchOdooJournalEntry(int settlementId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/financial-settlement/$settlementId/odoo-journal-entry',
      );
      return OdooJournalEntryModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

