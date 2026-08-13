import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/file_closure_model.dart';

final fileClosureProvider =
    StateNotifierProvider<FileClosureNotifier, AsyncValue<List<ImportFileClosureModel>>>((ref) {
  return FileClosureNotifier();
});

class FileClosureNotifier extends StateNotifier<AsyncValue<List<ImportFileClosureModel>>> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  FileClosureNotifier() : super(const AsyncValue.loading()) {
    fetchClosures();
  }

  Future<void> fetchClosures({
    bool includeInactive = false,
    int? importFileId,
    String? search,
  }) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{'include_inactive': includeInactive};
      if (importFileId != null) queryParams['import_file_id'] = importFileId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/file-closure',
        queryParameters: queryParams,
      );

      final List data = response.data;
      final list = data.map((json) => ImportFileClosureModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<ImportFileClosureModel?> closeImportFile(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/file-closure',
        data: payload,
      );
      final created = ImportFileClosureModel.fromJson(response.data);
      await fetchClosures();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> softDeleteClosure(int closureId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/file-closure/$closureId');
      await fetchClosures();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreClosure(int closureId) async {
    try {
      await _dio.patch('${ApiConstants.baseUrl}/file-closure/$closureId/restore');
      await fetchClosures();
    } catch (e) {
      rethrow;
    }
  }
}
