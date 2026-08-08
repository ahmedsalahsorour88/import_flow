import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/freight_quotation_model.dart';

final freightQuotationsProvider =
    StateNotifierProvider<FreightQuotationsNotifier, AsyncValue<List<FreightRFQRequestModel>>>((ref) {
  return FreightQuotationsNotifier();
});

class FreightQuotationsNotifier extends StateNotifier<AsyncValue<List<FreightRFQRequestModel>>> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  FreightQuotationsNotifier() : super(const AsyncValue.loading()) {
    fetchRFQs();
  }

  Future<void> fetchRFQs({
    bool includeInactive = false,
    String? search,
    String? shippingMethod,
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
      if (shippingMethod != null && shippingMethod.isNotEmpty && shippingMethod != 'All') {
        queryParams['shipping_method'] = shippingMethod;
      }
      if (poId != null) queryParams['po_id'] = poId;
      if (projectId != null) queryParams['project_id'] = projectId;
      if (status != null && status.isNotEmpty && status != 'All') queryParams['status'] = status;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/api/v1/freight-quotations',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      final rfqs = data.map((json) => FreightRFQRequestModel.fromJson(json)).toList();
      state = AsyncValue.data(rfqs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<FreightRFQRequestModel?> createRFQ(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/v1/freight-quotations',
        data: payload,
      );
      final newRfq = FreightRFQRequestModel.fromJson(response.data);
      await fetchRFQs();
      return newRfq;
    } catch (e) {
      rethrow;
    }
  }

  Future<FreightRFQRequestModel?> awardQuotation(int rfqId, int quotationId) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/v1/freight-quotations/$rfqId/award/$quotationId',
      );
      final awarded = FreightRFQRequestModel.fromJson(response.data);
      await fetchRFQs();
      return awarded;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> softDeleteRFQ(int rfqId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/api/v1/freight-quotations/$rfqId');
      await fetchRFQs();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreRFQ(int rfqId) async {
    try {
      await _dio.post('${ApiConstants.baseUrl}/api/v1/freight-quotations/$rfqId/restore');
      await fetchRFQs();
    } catch (e) {
      rethrow;
    }
  }
}
