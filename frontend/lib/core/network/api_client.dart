import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../constants/api_constants.dart';
import '../performance/client_diagnostics_service.dart';

/// Centralized Dio HTTP client provider for Sorour Logistics ERP.
/// All features must use this provider instead of creating their own Dio().
///
/// Features:
/// - Unified base URL from ApiConstants
/// - Consistent timeouts (connect: 30s, receive: 180s for large uploads)
/// - Centralized error interceptor
/// - Auth token and role headers injection
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 180),
      sendTimeout: const Duration(seconds: 180),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip',
      },
    ),
  );

  // ── Auth Token & Role Header & X-Request-ID Interceptor ───────
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        try {
          final authState = ref.read(authProvider);
          if (authState.token != null && authState.token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ${authState.token}';
          }
          if (authState.user != null) {
            options.headers['x-user-role'] = authState.user!.role;
            options.headers['x-user-name'] = authState.user!.username;
          }
          // Inject Correlation ID
          final reqId = 'req_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';
          options.headers['X-Request-ID'] = reqId;
          options.extra['request_start_time'] = DateTime.now().millisecondsSinceEpoch;
        } catch (_) {}
        handler.next(options);
      },
      onResponse: (response, handler) {
        try {
          final start = response.requestOptions.extra['request_start_time'] as int?;
          final durationMs = start != null ? DateTime.now().millisecondsSinceEpoch - start : 0;
          ClientDiagnosticsService.instance.recordNetworkEvent(
            method: response.requestOptions.method,
            path: response.requestOptions.path,
            statusCode: response.statusCode ?? 200,
            durationMs: durationMs,
            requestId: response.requestOptions.headers['X-Request-ID']?.toString(),
          );
        } catch (_) {}
        handler.next(response);
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
        try {
          final start = error.requestOptions.extra['request_start_time'] as int?;
          final durationMs = start != null ? DateTime.now().millisecondsSinceEpoch - start : 0;
          ClientDiagnosticsService.instance.recordNetworkEvent(
            method: error.requestOptions.method,
            path: error.requestOptions.path,
            statusCode: error.response?.statusCode ?? 500,
            durationMs: durationMs,
            requestId: error.requestOptions.headers['X-Request-ID']?.toString(),
          );
          ClientDiagnosticsService.instance.recordError(
            '${error.requestOptions.method} ${error.requestOptions.path} error',
            requestId: error.requestOptions.headers['X-Request-ID']?.toString(),
            error: error.message,
          );
        } catch (_) {}

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
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 180),
      sendTimeout: const Duration(seconds: 180),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        try {
          final authState = ref.read(authProvider);
          if (authState.token != null && authState.token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ${authState.token}';
          }
          if (authState.user != null) {
            options.headers['x-user-role'] = authState.user!.role;
            options.headers['x-user-name'] = authState.user!.username;
          }
        } catch (_) {}
        handler.next(options);
      },
    ),
  );

  return dio;
});
