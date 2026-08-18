import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/transport_location_model.dart';
import '../../../core/network/api_client.dart';


final transportLocationsProvider =
    StateNotifierProvider<TransportLocationsNotifier, AsyncValue<List<TransportLocationModel>>>((ref) {
  return TransportLocationsNotifier(ref.read(dioProvider));
});

class TransportLocationsNotifier extends StateNotifier<AsyncValue<List<TransportLocationModel>>> {
  final Dio _dio;

  TransportLocationsNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchLocations();
  }

  Future<void> fetchLocations({bool includeInactive = true, String? locationType, String? search}) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{
        'include_inactive': includeInactive,
      };
      if (locationType != null && locationType.isNotEmpty && locationType != 'All') {
        queryParams['location_type'] = locationType;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/transport-locations',
        queryParameters: queryParams,
      );
      final List data = response.data as List;
      final locations = data.map((json) => TransportLocationModel.fromJson(json)).toList();
      state = AsyncValue.data(locations);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<bool> createLocation(TransportLocationModel model) async {
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}/transport-locations',
        data: model.toJson(),
      );
      await fetchLocations();
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> updateLocation(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put(
        '${ApiConstants.baseUrl}/transport-locations/$id',
        data: data,
      );
      await fetchLocations();
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> toggleActive(int id, bool currentStatus) async {
    try {
      if (currentStatus) {
        await _dio.delete('${ApiConstants.baseUrl}/transport-locations/$id');
      } else {
        await _dio.post('${ApiConstants.baseUrl}/transport-locations/$id/restore');
      }
      await fetchLocations();
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> uploadExcelLocations(List<int> bytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/transport-locations/import-excel',
        data: formData,
      );
      await fetchLocations();
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.response?.data?['detail']?.toString() ?? 'Failed to upload Excel file.';
    } catch (e) {
      throw 'An error occurred during file upload: ${e.toString()}';
    }
  }
}
