import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/freight_booking_model.dart';

final freightBookingProvider =
    StateNotifierProvider<FreightBookingNotifier, AsyncValue<List<ShipmentBookingModel>>>((ref) {
  return FreightBookingNotifier();
});

class FreightBookingNotifier extends StateNotifier<AsyncValue<List<ShipmentBookingModel>>> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  FreightBookingNotifier() : super(const AsyncValue.loading()) {
    fetchBookings();
  }

  Future<void> fetchBookings({
    bool includeInactive = false,
    int? importFileId,
    String? status,
    String? search,
  }) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{'include_inactive': includeInactive};
      if (importFileId != null) queryParams['import_file_id'] = importFileId;
      if (status != null && status.isNotEmpty && status != 'All') queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/freight-booking',
        queryParameters: queryParams,
      );

      final List data = response.data;
      final list = data.map((json) => ShipmentBookingModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<ShipmentBookingModel?> createBooking(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/freight-booking',
        data: payload,
      );
      final created = ShipmentBookingModel.fromJson(response.data);
      await fetchBookings();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<ShipmentBookingModel?> updateBooking(int bookingId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/freight-booking/$bookingId',
        data: payload,
      );
      final updated = ShipmentBookingModel.fromJson(response.data);
      await fetchBookings();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> softDeleteBooking(int bookingId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/freight-booking/$bookingId');
      await fetchBookings();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreBooking(int bookingId) async {
    try {
      await _dio.patch('${ApiConstants.baseUrl}/freight-booking/$bookingId/restore');
      await fetchBookings();
    } catch (e) {
      rethrow;
    }
  }
}
