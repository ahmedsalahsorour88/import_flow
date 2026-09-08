import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/original_documents_collection_model.dart';

final originalDocsDioProvider = Provider<Dio>((ref) {
  return ref.watch(dioProvider);
});

final originalDocumentsSessionsProvider = StateNotifierProvider<
    OriginalDocumentsCollectionNotifier,
    AsyncValue<List<OriginalDocumentsCollectionSessionModel>>>((ref) {
  return OriginalDocumentsCollectionNotifier(ref.read(originalDocsDioProvider));
});

class OriginalDocumentsCollectionNotifier
    extends StateNotifier<AsyncValue<List<OriginalDocumentsCollectionSessionModel>>> {
  final Dio _dio;
  CancelToken? _cancelToken;

  OriginalDocumentsCollectionNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchSessions();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('OriginalDocumentsCollectionNotifier disposed');
    super.dispose();
  }

  Future<void> fetchSessions({
    String? status,
    String? search,
  }) async {
    _cancelToken?.cancel('New fetch requested');
    _cancelToken = CancelToken();
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status != 'All') queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '/original-documents-collection/sessions',
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      final List<dynamic> list = response.data;
      final sessions = list
          .map((json) => OriginalDocumentsCollectionSessionModel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(sessions);
    } catch (e, st) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return;
      }
      state = AsyncValue.error(e, st);
    }
  }

  Future<OriginalDocumentsAutoPopulateModel> fetchAutoPopulate(int importFileId) async {
    try {
      final response = await _dio.get(
        '/original-documents-collection/auto-populate/$importFileId',
      );
      return OriginalDocumentsAutoPopulateModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<OriginalDocumentsCollectionSessionModel?> fetchSessionByFile(int importFileId) async {
    try {
      final response = await _dio.get(
        '/original-documents-collection/sessions/by-file/$importFileId',
      );
      if (response.data == null) return null;
      return OriginalDocumentsCollectionSessionModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<OriginalDocumentsCollectionSessionModel> saveOrUpsertSession(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.post(
        '/original-documents-collection/sessions',
        data: payload,
      );
      final created = OriginalDocumentsCollectionSessionModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      await fetchSessions();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<int>> downloadExcel(int importFileIdOrSessionId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/original-documents-collection/export/excel/$importFileIdOrSessionId',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? [];
    } catch (e) {
      rethrow;
    }
  }
}
