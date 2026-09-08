import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../audit_logs/providers/audit_logs_provider.dart';
import '../models/import_company_model.dart';

import '../../../core/network/api_client.dart';

final showInactiveCompaniesProvider = StateProvider<bool>((ref) => true);

final importCompaniesProvider = StateNotifierProvider<ImportCompaniesNotifier, AsyncValue<List<ImportCompanyModel>>>((ref) {
  final showInactive = ref.watch(showInactiveCompaniesProvider);
  return ImportCompaniesNotifier(ref: ref, showInactive: showInactive, dio: ref.read(dioProvider));
});

class ImportCompaniesNotifier extends StateNotifier<AsyncValue<List<ImportCompanyModel>>> {
  final Ref? ref;
  final Dio _dio;
  final bool showInactive;
  CancelToken? _cancelToken;

  ImportCompaniesNotifier({this.ref, required this.showInactive, required Dio dio}) : _dio = dio, super(const AsyncValue.loading()) {
    fetchCompanies();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('ImportCompaniesNotifier disposed');
    super.dispose();
  }

  Future<void> fetchCompanies() async {
    _cancelToken?.cancel('New fetch requested');
    _cancelToken = CancelToken();

    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/import-companies',
        queryParameters: {'include_inactive': showInactive},
        cancelToken: _cancelToken,
      );
      final List data = response.data;
      final list = data.map((json) => ImportCompanyModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return;
      }
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String?> createCompany(ImportCompanyModel company) async {
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}/import-companies',
        data: company.toJson(),
      );
      ref?.invalidate(systemAuditLogsProvider);
      await fetchCompanies();
      return null; // Success
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null && e.response?.data['detail'] != null) {
        return e.response?.data['detail'].toString();
      }
      return 'Failed to create company. Please try again.';
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> updateCompany(int companyId, ImportCompanyModel company) async {
    try {
      await _dio.put(
        '${ApiConstants.baseUrl}/import-companies/$companyId',
        data: company.toJson(),
      );
      ref?.invalidate(systemAuditLogsProvider);
      ref?.invalidate(entityAuditTimelineProvider((entityType: 'ImportCompany', entityId: companyId)));
      await fetchCompanies();
      return null; // Success
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null && e.response?.data['detail'] != null) {
        return e.response?.data['detail'].toString();
      }
      return 'Failed to update company. Please try again.';
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<bool> toggleActiveStatus(int companyId, bool currentlyActive) async {
    try {
      if (currentlyActive) {
        await _dio.delete('${ApiConstants.baseUrl}/import-companies/$companyId');
      } else {
        await _dio.patch('${ApiConstants.baseUrl}/import-companies/$companyId/restore');
      }
      ref?.invalidate(systemAuditLogsProvider);
      ref?.invalidate(entityAuditTimelineProvider((entityType: 'ImportCompany', entityId: companyId)));
      await fetchCompanies();
      return true;
    } catch (e) {
      return false;
    }
  }
}
