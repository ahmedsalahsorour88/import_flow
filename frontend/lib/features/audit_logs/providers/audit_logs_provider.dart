import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/audit_log_model.dart';

final dioProvider = Provider<Dio>((ref) => Dio());

// Fetch single row history timeline live from API
final entityAuditTimelineProvider = FutureProvider.family<List<AuditLogModel>, ({String entityType, int entityId})>((ref, arg) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('${ApiConstants.baseUrl}/audit-logs/${arg.entityType}/${arg.entityId}');
  final List data = response.data as List;
  return data.map((json) => AuditLogModel.fromJson(json as Map<String, dynamic>)).toList();
});

// Fetch all system-wide audit logs live from API
final systemAuditLogsProvider = FutureProvider<List<AuditLogModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('${ApiConstants.baseUrl}/audit-logs/?limit=200');
  final List data = response.data as List;
  return data.map((json) => AuditLogModel.fromJson(json as Map<String, dynamic>)).toList();
});
