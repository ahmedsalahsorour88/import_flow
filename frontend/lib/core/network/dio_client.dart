import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';

/// Single shared Dio HTTP client for ImportFlow ERP.
///
/// Replaces `Dio()` instantiated locally in every widget.
/// Provides:
///   - Shared connection pool (no per-widget client overhead)
///   - Configured timeouts
///   - Centralized error interception point
///
/// Usage in ConsumerWidget:
///   final dio = ref.read(dioProvider);
///   final resp = await dio.get('/import-files');
///
/// Usage in StatefulWidget (via Riverpod container):
///   Use dioClientProvider below.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // ── Request / Response Logging (debug builds only) ────────────────────────
  assert(() {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (o) {
          // ignore: avoid_print
          print('[DIO] $o');
        },
      ),
    );
    return true;
  }());

  // ── Error Normalizer ──────────────────────────────────────────────────────
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (DioException err, ErrorInterceptorHandler handler) {
        // Re-throw with cleaner message; callers can still catch DioException
        handler.next(err);
      },
    ),
  );

  return dio;
});

/// Separate Dio instance for multipart/file upload operations.
/// Disables JSON content-type header so Dio can set multipart boundary.
final uploadDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 120), // uploads may be slow
      sendTimeout: const Duration(seconds: 120),
    ),
  );
  return dio;
});
