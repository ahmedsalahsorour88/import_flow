import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../audit_logs/providers/audit_logs_provider.dart';
import '../models/customs_tariff_model.dart';

final showInactiveCustomsTariffsProvider = StateProvider<bool>((ref) => false);
final customsTariffSearchQueryProvider = StateProvider<String>((ref) => '');

final customsTariffProvider = StateNotifierProvider<CustomsTariffNotifier,
    AsyncValue<List<CustomsTariffModel>>>((ref) {
  final showInactive = ref.watch(showInactiveCustomsTariffsProvider);
  final search = ref.watch(customsTariffSearchQueryProvider);
  return CustomsTariffNotifier(ref: ref, showInactive: showInactive, search: search);
});

class CustomsTariffNotifier
    extends StateNotifier<AsyncValue<List<CustomsTariffModel>>> {
  final Ref ref;
  final Dio _dio = Dio();
  final bool showInactive;
  final String search;

  CustomsTariffNotifier({
    required this.ref,
    required this.showInactive,
    required this.search,
  }) : super(const AsyncValue.loading()) {
    fetchTariffs();
  }

  Future<void> fetchTariffs() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/customs-tariff',
        queryParameters: {
          'include_inactive': showInactive,
          if (search.isNotEmpty) 'search': search,
        },
      );
      final list = (response.data as List)
          .map((json) => CustomsTariffModel.fromJson(json))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String?> createTariff(Map<String, dynamic> data) async {
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}/customs-tariff',
        data: data,
      );
      ref.invalidate(systemAuditLogsProvider);
      ref.invalidate(customsTariffProvider);
      return null;
    } on DioException catch (e) {
      return e.response?.data?['detail']?.toString() ??
          'Failed to create tariff entry.';
    } catch (_) {
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> updateTariff(int tariffId, Map<String, dynamic> data) async {
    try {
      await _dio.put(
        '${ApiConstants.baseUrl}/customs-tariff/$tariffId',
        data: data,
      );
      ref.invalidate(systemAuditLogsProvider);
      ref.invalidate(customsTariffProvider);
      return null;
    } on DioException catch (e) {
      return e.response?.data?['detail']?.toString() ??
          'Failed to update tariff entry.';
    } catch (_) {
      return 'An unexpected error occurred.';
    }
  }

  Future<bool> toggleActive(int tariffId, bool currentlyActive) async {
    try {
      if (currentlyActive) {
        await _dio.delete('${ApiConstants.baseUrl}/customs-tariff/$tariffId');
      } else {
        await _dio.patch('${ApiConstants.baseUrl}/customs-tariff/$tariffId/restore');
      }
      ref.invalidate(systemAuditLogsProvider);
      ref.invalidate(customsTariffProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<CustomsDutyBreakdownModel?> estimateDuty({
    required String hsCode,
    required double cifValue,
    required double freight,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/customs-tariff/estimate',
        data: {
          'hs_code': hsCode,
          'cif_value': cifValue,
          'freight': freight,
        },
      );
      return CustomsDutyBreakdownModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['detail']?.toString() ?? 'Failed to calculate duty.');
    } catch (e) {
      throw Exception('An unexpected error occurred during calculation.');
    }
  }

  Future<Map<String, dynamic>?> estimateMultiItemDuty(Map<String, dynamic> requestData) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/customs-tariff/estimate-multi',
        data: requestData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['detail']?.toString() ?? 'Failed to calculate multi-item duties.');
    } catch (e) {
      throw Exception('An unexpected error occurred during calculation.');
    }
  }

  Future<Map<String, dynamic>?> uploadExcelTariffs(List<int> bytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/customs-tariff/upload-excel',
        data: formData,
      );
      ref.invalidate(systemAuditLogsProvider);
      ref.invalidate(customsTariffProvider);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.response?.data?['detail']?.toString() ?? 'Failed to upload Excel file.';
    } catch (e) {
      throw 'An error occurred during file upload: ${e.toString()}';
    }
  }
}
