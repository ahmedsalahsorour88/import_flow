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

  Future<bool> createCompany(ImportCompanyModel company) async {
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}/import-companies/',
        data: company.toJson(),
      );
      await fetchCompanies();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleActiveStatus(int companyId, bool currentlyActive) async {
    try {
      if (currentlyActive) {
        // Deactivate (Soft Delete)
        await _dio.delete('${ApiConstants.baseUrl}/import-companies/$companyId');
      } else {
        // Activate (Restore)
        await _dio.patch('${ApiConstants.baseUrl}/import-companies/$companyId/restore');
      }
      await fetchCompanies();
      return true;
    } catch (e) {
      return false;
    }
  }
}
