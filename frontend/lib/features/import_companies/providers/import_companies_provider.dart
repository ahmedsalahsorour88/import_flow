import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/import_company_model.dart';

final showInactiveCompaniesProvider = StateProvider<bool>((ref) => true);

final importCompaniesProvider = StateNotifierProvider<ImportCompaniesNotifier, AsyncValue<List<ImportCompanyModel>>>((ref) {
  final showInactive = ref.watch(showInactiveCompaniesProvider);
  return ImportCompaniesNotifier(showInactive: showInactive);
});

class ImportCompaniesNotifier extends StateNotifier<AsyncValue<List<ImportCompanyModel>>> {
  final Dio _dio = Dio();
  final bool showInactive;

  ImportCompaniesNotifier({required this.showInactive}) : super(const AsyncValue.loading()) {
    fetchCompanies();
  }

  Future<void> fetchCompanies() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/import-companies/',
        queryParameters: {'include_inactive': showInactive},
      );
      final List data = response.data;
      final list = data.map((json) => ImportCompanyModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String?> createCompany(ImportCompanyModel company) async {
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}/import-companies/',
        data: company.toJson(),
      );
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

  Future<bool> toggleActiveStatus(int companyId, bool currentlyActive) async {
    try {
      if (currentlyActive) {
        await _dio.delete('${ApiConstants.baseUrl}/import-companies/$companyId');
      } else {
        await _dio.patch('${ApiConstants.baseUrl}/import-companies/$companyId/restore');
      }
      await fetchCompanies();
      return true;
    } catch (e) {
      return false;
    }
  }
}
