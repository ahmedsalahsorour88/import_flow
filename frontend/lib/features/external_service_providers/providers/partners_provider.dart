import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../audit_logs/providers/audit_logs_provider.dart';
import '../models/partner_model.dart';

final selectedPartnerCategoryProvider = StateProvider<String>((ref) => 'All');
final showInactivePartnersProvider = StateProvider<bool>((ref) => true);

final partnersProvider = StateNotifierProvider<PartnersNotifier, AsyncValue<List<PartnerModel>>>((ref) {
  final category = ref.watch(selectedPartnerCategoryProvider);
  final showInactive = ref.watch(showInactivePartnersProvider);
  return PartnersNotifier(ref: ref, category: category, showInactive: showInactive);
});

class PartnersNotifier extends StateNotifier<AsyncValue<List<PartnerModel>>> {
  final Ref? ref;
  final Dio _dio = Dio();
  final String category;
  final bool showInactive;

  PartnersNotifier({this.ref, required this.category, required this.showInactive}) : super(const AsyncValue.loading()) {
    fetchPartners();
  }

  Future<void> fetchPartners() async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{'include_inactive': showInactive};
      if (category != 'All') {
        queryParams['partner_type'] = category;
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/external-service-providers/',
        queryParameters: queryParams,
      );
      final List data = response.data;
      final list = data.map((json) => PartnerModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String?> createPartner(PartnerModel partner) async {
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}/external-service-providers/',
        data: partner.toJson(),
      );
      ref?.invalidate(systemAuditLogsProvider);
      await fetchPartners();
      return null; // Success
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null && e.response?.data['detail'] != null) {
        return e.response?.data['detail'].toString();
      }
      return 'Failed to create partner. Please check inputs.';
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> updatePartner(int providerId, PartnerModel partner) async {
    try {
      await _dio.put(
        '${ApiConstants.baseUrl}/external-service-providers/$providerId',
        data: partner.toJson(),
      );
      ref?.invalidate(systemAuditLogsProvider);
      ref?.invalidate(entityAuditTimelineProvider((entityType: 'ExternalServiceProvider', entityId: providerId)));
      await fetchPartners();
      return null; // Success
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null && e.response?.data['detail'] != null) {
        return e.response?.data['detail'].toString();
      }
      return 'Failed to update partner. Please check inputs.';
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<bool> toggleActiveStatus(int providerId, bool currentlyActive) async {
    try {
      if (currentlyActive) {
        await _dio.delete('${ApiConstants.baseUrl}/external-service-providers/$providerId');
      } else {
        await _dio.patch('${ApiConstants.baseUrl}/external-service-providers/$providerId/restore');
      }
      ref?.invalidate(systemAuditLogsProvider);
      ref?.invalidate(entityAuditTimelineProvider((entityType: 'ExternalServiceProvider', entityId: providerId)));
      await fetchPartners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
