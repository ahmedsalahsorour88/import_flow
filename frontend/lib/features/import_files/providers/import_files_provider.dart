import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/import_file_model.dart';

final importFilesProvider =
    StateNotifierProvider<ImportFilesNotifier, AsyncValue<List<ImportFileModel>>>((ref) {
  return ImportFilesNotifier();
});

class ImportFilesNotifier extends StateNotifier<AsyncValue<List<ImportFileModel>>> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  ImportFilesNotifier() : super(const AsyncValue.loading()) {
    fetchImportFiles();
  }

  Future<void> fetchImportFiles({
    bool includeInactive = false,
    String? search,
    int? companyId,
    int? supplierId,
    String? status,
    String? owner,
  }) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{
        'include_inactive': includeInactive,
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (companyId != null) queryParams['company_id'] = companyId;
      if (supplierId != null) queryParams['supplier_id'] = supplierId;
      if (status != null && status.isNotEmpty && status != 'All') queryParams['status'] = status;
      if (owner != null && owner.isNotEmpty && owner != 'All') queryParams['owner'] = owner;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/import-files',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      final files = data.map((json) => ImportFileModel.fromJson(json)).toList();
      state = AsyncValue.data(files);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<ImportFileModel?> createImportFile(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-files',
        data: payload,
      );
      final created = ImportFileModel.fromJson(response.data);
      await fetchImportFiles();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<ImportFileModel?> updateImportFile(int importFileId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/import-files/$importFileId',
        data: payload,
      );
      final updated = ImportFileModel.fromJson(response.data);
      await fetchImportFiles();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> softDeleteImportFile(int importFileId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/import-files/$importFileId');
      await fetchImportFiles();
    } catch (e) {
      rethrow;
    }
  }

  Future<ImportMasterReportSummaryModel> fetchMasterReport() async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/import-files/report/master');
      return ImportMasterReportSummaryModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
