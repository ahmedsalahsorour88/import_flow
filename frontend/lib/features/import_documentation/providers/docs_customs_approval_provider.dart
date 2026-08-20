import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/docs_customs_approval_model.dart';

final docsCustomsApprovalProvider =
    StateNotifierProvider<DocsCustomsApprovalNotifier, AsyncValue<List<CustomsDocumentApprovalModel>>>((ref) {
  return DocsCustomsApprovalNotifier(ref.read(dioProvider));
});

final discrepancyTicketsProvider =
    StateNotifierProvider<DiscrepancyTicketsNotifier, AsyncValue<List<DiscrepancyRectificationTicketModel>>>((ref) {
  return DiscrepancyTicketsNotifier(ref.read(dioProvider));
});

class DocsCustomsApprovalNotifier extends StateNotifier<AsyncValue<List<CustomsDocumentApprovalModel>>> {
  final Dio _dio;

  DocsCustomsApprovalNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchApprovals();
  }

  Future<void> fetchApprovals({
    int? importFileId,
    String? overallStatus,
    String? search,
  }) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{'include_inactive': false};
      if (importFileId != null) queryParams['import_file_id'] = importFileId;
      if (overallStatus != null && overallStatus.isNotEmpty && overallStatus != 'All') {
        queryParams['overall_status'] = overallStatus;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/docs-customs-approval',
        queryParameters: queryParams,
      );

      final List data = response.data;
      final list = data.map((json) => CustomsDocumentApprovalModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> autoGenerateChecklist(int importFileId) async {
    try {
      await _dio.post('${ApiConstants.baseUrl}/docs-customs-approval/auto-generate/$importFileId');
      await fetchApprovals(importFileId: importFileId);
    } catch (e) {
      rethrow;
    }
  }

  Future<CustomsDocumentApprovalModel?> submitCommercialReview({
    required int approvalId,
    required String reviewerName,
    required String status,
    String? notes,
    int? importFileId,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/docs-customs-approval/$approvalId/commercial-review',
        data: {
          'reviewer_name': reviewerName,
          'status': status,
          'notes': notes,
        },
      );
      final updated = CustomsDocumentApprovalModel.fromJson(response.data);
      await fetchApprovals(importFileId: importFileId);
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<CustomsDocumentApprovalModel?> submitCustomsBrokerReview({
    required int approvalId,
    required String brokerName,
    required String reviewerName,
    required String status,
    String? notes,
    int? importFileId,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/docs-customs-approval/$approvalId/customs-review',
        data: {
          'broker_name': brokerName,
          'reviewer_name': reviewerName,
          'status': status,
          'notes': notes,
        },
      );
      final updated = CustomsDocumentApprovalModel.fromJson(response.data);
      await fetchApprovals(importFileId: importFileId);
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<CrossDocumentMatrixResultModel> runMatrixCheck(int importFileId) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/docs-customs-approval/matrix-check/$importFileId',
      );
      return CrossDocumentMatrixResultModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

class DiscrepancyTicketsNotifier extends StateNotifier<AsyncValue<List<DiscrepancyRectificationTicketModel>>> {
  final Dio _dio;

  DiscrepancyTicketsNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchTickets();
  }

  Future<void> fetchTickets({
    int? importFileId,
    String? status,
    String? severity,
    String? search,
  }) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{'include_inactive': false};
      if (importFileId != null) queryParams['import_file_id'] = importFileId;
      if (status != null && status.isNotEmpty && status != 'All') {
        queryParams['status'] = status;
      }
      if (severity != null && severity.isNotEmpty && severity != 'All') {
        queryParams['severity'] = severity;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/docs-customs-approval/tickets/list',
        queryParameters: queryParams,
      );

      final List data = response.data;
      final list = data.map((json) => DiscrepancyRectificationTicketModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<DiscrepancyRectificationTicketModel?> createTicket(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/docs-customs-approval/tickets',
        data: payload,
      );
      final created = DiscrepancyRectificationTicketModel.fromJson(response.data);
      await fetchTickets(importFileId: payload['import_file_id'] as int?);
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<DiscrepancyRectificationTicketModel?> resolveTicket(
    int ticketId,
    Map<String, dynamic> payload, {
    int? importFileId,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/docs-customs-approval/tickets/$ticketId/resolve',
        data: payload,
      );
      final resolved = DiscrepancyRectificationTicketModel.fromJson(response.data);
      await fetchTickets(importFileId: importFileId);
      return resolved;
    } catch (e) {
      rethrow;
    }
  }
}
