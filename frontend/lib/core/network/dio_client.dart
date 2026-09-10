import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import 'api_client.dart' as central;

/// Single shared Dio HTTP client for Sorour Logistics ERP.
/// Delegated to central api_client.dart dioProvider.
final dioProvider = Provider<Dio>((ref) {
  return ref.watch(central.dioProvider);
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
