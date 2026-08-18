import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/notification_model.dart';
import '../../../core/network/api_client.dart';


final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationsNotifier(ref.read(dioProvider));
});

class NotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final Dio _dio;

  NotificationsNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/notifications?limit=100');
      final List data = response.data as List;
      final list = data.map((json) => NotificationModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _dio.patch('${ApiConstants.baseUrl}/notifications/$notificationId/read');
      await fetchNotifications();
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.post('${ApiConstants.baseUrl}/notifications/mark-all-read');
      await fetchNotifications();
    } catch (_) {}
  }

  Future<void> triggerExpiryCheck() async {
    try {
      await _dio.post('${ApiConstants.baseUrl}/notifications/trigger-expiry-check');
      await fetchNotifications();
    } catch (_) {}
  }
}
