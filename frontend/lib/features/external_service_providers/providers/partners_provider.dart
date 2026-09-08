import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../audit_logs/providers/audit_logs_provider.dart';
import '../models/partner_model.dart';
import '../../../core/network/api_client.dart';

final selectedPartnerCategoryProvider = StateProvider<String>((ref) => 'All');
final showInactivePartnersProvider = StateProvider<bool>((ref) => true);

final partnersProvider = StateNotifierProvider<PartnersNotifier, AsyncValue<List<PartnerModel>>>((ref) {
  final category = ref.watch(selectedPartnerCategoryProvider);
  final showInactive = ref.watch(showInactivePartnersProvider);
  return PartnersNotifier(ref: ref, category: category, showInactive: showInactive, dio: ref.read(dioProvider));
});

final allPartnersProvider = StateNotifierProvider<AllPartnersNotifier, AsyncValue<List<PartnerModel>>>((ref) {
  return AllPartnersNotifier(ref: ref, dio: ref.read(dioProvider));
});

class AllPartnersNotifier extends StateNotifier<AsyncValue<List<PartnerModel>>> {
  final Ref? ref;
  final Dio _dio;
  CancelToken? _cancelToken;

  AllPartnersNotifier({this.ref, required Dio dio}) : _dio = dio, super(const AsyncValue.loading()) {
    fetchPartners();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('AllPartnersNotifier disposed');
    super.dispose();
  }

  Future<void> fetchPartners() async {
    _cancelToken?.cancel('Cancelled by new fetchPartners request');
    _cancelToken = CancelToken();
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/external-service-providers',
        queryParameters: {'include_inactive': true},
        cancelToken: _cancelToken,
      );
      final List data = response.data;
      final list = data.map((json) => PartnerModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      state = AsyncValue.error(e, stack);
    }
  }
}

class PartnersNotifier extends StateNotifier<AsyncValue<List<PartnerModel>>> {
  final Ref? ref;
  final Dio _dio;
  final String category;
  final bool showInactive;
  CancelToken? _cancelToken;

  PartnersNotifier({this.ref, required this.category, required this.showInactive, required Dio dio}) : _dio = dio, super(const AsyncValue.loading()) {
    fetchPartners();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('PartnersNotifier disposed');
    super.dispose();
  }

  Future<void> fetchPartners() async {
    _cancelToken?.cancel('Cancelled by new fetchPartners request');
    _cancelToken = CancelToken();
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{'include_inactive': showInactive};
      if (category != 'All') {
        queryParams['partner_type'] = category;
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/external-service-providers',
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );
      final List data = response.data;
      final list = data.map((json) => PartnerModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String?> createPartner(PartnerModel partner) async {
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}/external-service-providers',
        data: partner.toJson(),
      );
      ref?.invalidate(systemAuditLogsProvider);
      ref?.invalidate(allPartnersProvider);
      ref?.read(allPartnersProvider.notifier).fetchPartners();
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
      ref?.invalidate(allPartnersProvider);
      ref?.read(allPartnersProvider.notifier).fetchPartners();
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
      ref?.invalidate(allPartnersProvider);
      ref?.read(allPartnersProvider.notifier).fetchPartners();
      await fetchPartners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<PartnerStatementOfAccountModel?> fetchStatementOfAccount(int providerId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/external-service-providers/$providerId/statement-of-account',
      );
      return PartnerStatementOfAccountModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
}

final partnerStatementOfAccountProvider = FutureProvider.family<PartnerStatementOfAccountModel?, int>((ref, providerId) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get(
      '${ApiConstants.baseUrl}/external-service-providers/$providerId/statement-of-account',
    );
    return PartnerStatementOfAccountModel.fromJson(response.data);
  } catch (e) {
    return null;
  }
});
