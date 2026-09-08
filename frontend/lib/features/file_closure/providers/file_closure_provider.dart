import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/file_closure_model.dart';
import '../../../core/network/api_client.dart';


final fileClosureProvider =
    StateNotifierProvider<FileClosureNotifier, AsyncValue<List<ImportFileClosureModel>>>((ref) {
  return FileClosureNotifier(ref.read(dioProvider));
});

class FileClosureNotifier extends StateNotifier<AsyncValue<List<ImportFileClosureModel>>> {
  final Dio _dio;
  CancelToken? _cancelToken;

  FileClosureNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchClosures();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('FileClosureNotifier disposed');
    super.dispose();
  }

  Future<void> fetchClosures({
    bool includeInactive = false,
    int? importFileId,
    String? search,
  }) async {
    _cancelToken?.cancel('New fetch started');
    _cancelToken = CancelToken();

    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
    try {
      final queryParams = <String, dynamic>{'include_inactive': includeInactive};
      if (importFileId != null) queryParams['import_file_id'] = importFileId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/file-closure',
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      final List data = response.data;
      final list = data.map((json) => ImportFileClosureModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return;
      }
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
