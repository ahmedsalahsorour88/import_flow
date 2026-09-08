import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'navigation_perf_tracker.dart';

/// Dio Interceptor that measures HTTP request latency and records backend call
/// timing during screen transitions (entry and exit).
class BackendTimingInterceptor extends Interceptor {
  static const String _startKey = '_perf_req_start_ts';

  final Set<String> _pendingRequests = {};

  int get pendingCount => _pendingRequests.length;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = Stopwatch()..start();
    final reqId = '${options.method} ${options.path}';
    _pendingRequests.add(reqId);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _finishRequest(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _finishRequest(err.requestOptions);
    handler.next(err);
  }

  void _finishRequest(RequestOptions options) {
    final sw = options.extra[_startKey] as Stopwatch?;
    final reqId = '${options.method} ${options.path}';
    _pendingRequests.remove(reqId);

    if (sw != null) {
      sw.stop();
      final elapsedMs = sw.elapsedMicroseconds / 1000.0;
      WorkspaceTabPerfTracker.instance.notifyBackendCallEntry(elapsedMs);

      if (kDebugMode) {
        debugPrint('[PERF-DIO] $reqId finished in ${elapsedMs.toStringAsFixed(1)}ms (pending: ${_pendingRequests.length})');
      }
    }
  }
}
