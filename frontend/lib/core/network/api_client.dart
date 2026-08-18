import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';

/// Centralized Dio HTTP client provider for ImportFlow ERP.
/// All features must use this provider instead of creating their own Dio().
///
/// Features:
/// - Unified base URL from ApiConstants
/// - Consistent timeouts (connect: 30s, receive: 180s for large uploads)
/// - Centralized error interceptor
/// - Auth token injection (ready for auth implementation)
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 180),
      sendTimeout: const Duration(seconds: 180),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // ── Logging Interceptor (debug only) ──────────────────────
  dio.interceptors.add(
    LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (obj) => debugPrintSynchronously('[DIO] $obj'),
    ),
  );

  // ── Error Response Interceptor ────────────────────────────
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) {
        // Normalize error messages for UI display
        if (error.response != null) {
          final data = error.response!.data;
          if (data is Map && data.containsKey('detail')) {
            error = error.copyWith(
              message: data['detail'].toString(),
            );
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

/// Upload-optimized Dio client (180s timeout, no JSON content-type).
/// Use for multipart file uploads to /smart-upload endpoints.
final uploadDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 180),
      sendTimeout: const Duration(seconds: 180),
    ),
  );
});
