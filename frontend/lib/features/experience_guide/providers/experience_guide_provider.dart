import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/guide_entry_model.dart';
import '../models/smart_reference_card_model.dart';

final experienceGuideProvider =
    StateNotifierProvider<ExperienceGuideNotifier, AsyncValue<List<GuideEntryModel>>>((ref) {
  return ExperienceGuideNotifier(ref.read(dioProvider));
});

final smartReferenceCardProvider =
    FutureProvider.family<SmartReferenceCardModel, int>((ref, importFileId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('${ApiConstants.experienceGuide}/reference-card/$importFileId');
  return SmartReferenceCardModel.fromJson(response.data);
});

class ExperienceGuideNotifier extends StateNotifier<AsyncValue<List<GuideEntryModel>>> {
  final Dio _dio;

  ExperienceGuideNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchEntries();
  }

  Future<void> fetchEntries({
    String? search,
    String? scopeType,
    String? scopeValue,
    bool? isActive,
  }) async {
    try {
      state = const AsyncValue.loading();
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (scopeType != null && scopeType.isNotEmpty) queryParams['scope_type'] = scopeType;
      if (scopeValue != null && scopeValue.isNotEmpty) queryParams['scope_value'] = scopeValue;
      if (isActive != null) queryParams['is_active'] = isActive;

      final response = await _dio.get(
        ApiConstants.experienceGuide,
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      final entries = data.map((e) => GuideEntryModel.fromJson(e)).toList();
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<GuideEntryModel> createEntry(Map<String, dynamic> data) async {
    final response = await _dio.post(
      ApiConstants.experienceGuide,
      data: data,
    );
    final created = GuideEntryModel.fromJson(response.data);
    await fetchEntries();
    return created;
  }

  Future<GuideEntryModel> updateEntry(int entryId, Map<String, dynamic> data) async {
    final response = await _dio.put(
      '${ApiConstants.experienceGuide}/$entryId',
      data: data,
    );
    final updated = GuideEntryModel.fromJson(response.data);
    await fetchEntries();
    return updated;
  }

  Future<bool> deleteEntry(int entryId) async {
    final response = await _dio.delete('${ApiConstants.experienceGuide}/$entryId');
    await fetchEntries();
    return response.statusCode == 200;
  }

  Future<GuideMatchResultModel> matchShipment({
    String? hsCode,
    String? productCategory,
    String? destinationPort,
    String? supplier,
    String? shippingLine,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.experienceGuide}/match',
        data: {
          if (hsCode != null && hsCode.isNotEmpty) 'hs_code': hsCode,
          if (productCategory != null && productCategory.isNotEmpty) 'product_category': productCategory,
          if (destinationPort != null && destinationPort.isNotEmpty) 'destination_port': destinationPort,
          if (supplier != null && supplier.isNotEmpty) 'supplier': supplier,
          if (shippingLine != null && shippingLine.isNotEmpty) 'shipping_line': shippingLine,
        },
      );
      return GuideMatchResultModel.fromJson(response.data);
    } catch (_) {
      return GuideMatchResultModel();
    }
  }
}
