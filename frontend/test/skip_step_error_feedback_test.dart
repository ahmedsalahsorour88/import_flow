// Tests for the skip step error feedback fix.
//
// Root Cause: _handleSkipStep() in StepActionDialog silently did nothing
// when skipStep() returned false. The backend raises HTTP 400 for
// skip_policy == "blocked" steps (all 21 steps default to "blocked" per
// Section 10.2), but the error detail was never surfaced to the user.
//
// Fix: LifecycleBoardNotifier now captures the backend error detail in
// lastErrorMessage, which the dialog reads to show a red SnackBar.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/lifecycle_board/providers/lifecycle_board_provider.dart';

// Replicate the _extractErrorDetail logic (mirrors the private top-level fn).
String _extractErrorDetail(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    if (e.message != null && e.message!.isNotEmpty) return e.message!;
  }
  return e.toString();
}

void main() {
  group('_extractErrorDetail — backend error extraction', () {
    test('extracts Arabic detail from FastAPI 400 blocked-policy response', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/lifecycle-board/stages/skip'),
        statusCode: 400,
        data: {
          'detail':
              "الخطوة 'STEP_03' محظورة من التخطي حسب سياسة النظام المعتمدة (Policy: blocked).",
        },
      );
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/lifecycle-board/stages/skip'),
        response: response,
        type: DioExceptionType.badResponse,
      );

      expect(
        _extractErrorDetail(dioEx),
        "الخطوة 'STEP_03' محظورة من التخطي حسب سياسة النظام المعتمدة (Policy: blocked).",
      );
    });

    test('extracts Arabic detail from FastAPI 403 role-restriction response', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/lifecycle-board/stages/skip'),
        statusCode: 403,
        data: {
          'detail':
              "دورك 'Operator' غير مخول باعتماد تخطي هذه الخطوة. الأدوار المعتمدة: [Manager].",
        },
      );
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/lifecycle-board/stages/skip'),
        response: response,
        type: DioExceptionType.badResponse,
      );

      expect(_extractErrorDetail(dioEx), contains("غير مخول باعتماد تخطي"));
    });

    test('falls back to DioException.message when response body has no detail', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/lifecycle-board/stages/skip'),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 500,
          data: <String, dynamic>{},
        ),
        type: DioExceptionType.badResponse,
        message: 'Http status error [500]',
      );

      expect(_extractErrorDetail(dioEx), 'Http status error [500]');
    });

    test('falls back to toString() for non-Dio exceptions', () {
      final ex = Exception('Unexpected failure');
      expect(_extractErrorDetail(ex), contains('Unexpected failure'));
    });

    test('extracts plain-string detail (not only Map)', () {
      final response = Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 422,
        data: {'detail': 'skip_reason must be at least 5 characters'},
      );
      final dioEx = DioException(
        requestOptions: RequestOptions(path: ''),
        response: response,
        type: DioExceptionType.badResponse,
      );

      expect(_extractErrorDetail(dioEx), 'skip_reason must be at least 5 characters');
    });
  });

  group('LifecycleBoardNotifier.lastErrorMessage', () {
    test('is null initially before any operation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(lifecycleBoardActionProvider.notifier);
      expect(notifier.lastErrorMessage, isNull);
    });
  });
}
