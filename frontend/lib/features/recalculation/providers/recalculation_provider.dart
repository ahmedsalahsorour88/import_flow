/// Riverpod provider for Centralized Recalculation Engine (CRE-001)
///
/// All pages that need recalculation use this provider.
/// No page creates its own HTTP call for sync/recalculation logic.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/recalculation_model.dart';

// ── Provider singleton ────────────────────────────────────────────────────────

final recalculationProvider = Provider<RecalculationNotifier>((ref) {
  return RecalculationNotifier(ref.read(dioProvider));
});


// ── Notifier ──────────────────────────────────────────────────────────────────

class RecalculationNotifier {
  final Dio _dio;

  RecalculationNotifier(this._dio);

  /// Preview: compares live upstream values vs stored values.
  /// Does NOT modify any data. Safe to call on screen open.
  Future<RecalculationPreviewResponse> preview({
    required String targetEntityType,
    required int targetEntityId,
    String sourcePage = 'Flutter',
  }) async {
    final response = await _dio.post(
      '${ApiConstants.recalculation}/preview',
      queryParameters: {
        'target_entity_type': targetEntityType,
        'target_entity_id': targetEntityId,
        'source_page': sourcePage,
      },
    );
    return RecalculationPreviewResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Apply: applies live upstream values to the target entity.
  /// Enforces permission, SoD, Hard Block, and Immutability rules on the backend.
  /// [justification] is required when preview.hasHardBlock == true.
  Future<RecalculationApplyResult> apply({
    required String targetEntityType,
    required int targetEntityId,
    required String sourcePage,
    String? justification,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.recalculation}/apply',
      data: {
        'target_entity_type': targetEntityType,
        'target_entity_id': targetEntityId,
        'source_page': sourcePage,
        if (justification != null && justification.trim().isNotEmpty)
          'justification': justification.trim(),
      },
    );
    return RecalculationApplyResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Fetches audit log entries for a given entity.
  Future<List<Map<String, dynamic>>> getLogs({
    required String targetEntityType,
    required int targetEntityId,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.recalculation}/logs',
      queryParameters: {
        'target_entity_type': targetEntityType,
        'target_entity_id': targetEntityId,
        'limit': limit,
      },
    );
    return (response.data as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  /// Lists all active dependency map entries (for admin inspection).
  Future<List<RecalculationDependency>> getDependencies({
    String? targetEntityType,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.recalculation}/dependencies',
      queryParameters: {
        if (targetEntityType != null) 'target_entity_type': targetEntityType,
      },
    );
    return (response.data as List<dynamic>)
        .map((e) => RecalculationDependency.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
