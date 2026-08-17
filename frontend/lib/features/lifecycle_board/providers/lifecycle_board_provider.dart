import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/lifecycle_board_model.dart';

final lifecycleBoardSummaryProvider =
    FutureProvider.autoDispose<LifecycleBoardSummaryModel>((ref) async {
  final dio = Dio();
  final response = await dio.get('${ApiConstants.baseUrl}/lifecycle-board/summary');
  return LifecycleBoardSummaryModel.fromJson(response.data);
});

class LifecycleBoardNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  final Dio _dio = Dio();

  LifecycleBoardNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<bool> advanceStep({
    required String importFileCode,
    required String currentStepCode,
    required List<String> nextStepCodes,
    String? notes,
    Map<String, dynamic>? actionData,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}/lifecycle-board/stages/advance',
        data: {
          'import_file_code': importFileCode,
          'current_step_code': currentStepCode,
          'next_step_codes': nextStepCodes,
          'notes': notes,
          'action_data': actionData,
        },
      );
      state = const AsyncValue.data(null);
      ref.invalidate(lifecycleBoardSummaryProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> setMultiActiveStages({
    required String importFileCode,
    required List<String> activeStepCodes,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}/lifecycle-board/stages/set-active',
        data: {
          'import_file_code': importFileCode,
          'active_step_codes': activeStepCodes,
          'notes': notes,
        },
      );
      state = const AsyncValue.data(null);
      ref.invalidate(lifecycleBoardSummaryProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final lifecycleBoardActionProvider =
    StateNotifierProvider<LifecycleBoardNotifier, AsyncValue<void>>((ref) {
  return LifecycleBoardNotifier(ref);
});
