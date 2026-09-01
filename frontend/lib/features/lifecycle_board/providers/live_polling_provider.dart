import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/lifecycle_board_model.dart';

/// آخر وقت تحديث ناجح للرادار
final lastRefreshTimeProvider = StateProvider<DateTime?>((ref) => null);

/// هل يجري التحديث الآن؟
final isRefreshingProvider = StateProvider<bool>((ref) => false);

/// فترة التحديث الفعلية — 20 ثانية عند وجود شحنات حرجة، 60 ثانية في الوضع العادي
final refreshIntervalProvider = StateProvider<Duration>((ref) => const Duration(seconds: 60));

/// StreamProvider يجلب بيانات الرادار اللوجستي ويحدثها تلقائياً
final livePollingProvider = StreamProvider.autoDispose<LiveLogisticsSummaryModel>((ref) {
  final dio = ref.read(dioProvider);

  StreamController<LiveLogisticsSummaryModel>? controller;
  Timer? timer;
  bool disposed = false;

  Future<void> fetchAndEmit() async {
    if (disposed) return;
    ref.read(isRefreshingProvider.notifier).state = true;
    try {
      final response = await dio.get('${ApiConstants.baseUrl}/lifecycle-board/live-tracking');
      if (disposed) return;

      final data = LiveLogisticsSummaryModel.fromJson(response.data as Map<String, dynamic>);

      // تحديث وقت آخر نجاح
      ref.read(lastRefreshTimeProvider.notifier).state = DateTime.now();

      // ضبط الفترة الزمنية بناءً على مستوى الخطر
      final newInterval = data.highRiskDemurrageCount > 0
          ? const Duration(seconds: 20)
          : const Duration(seconds: 60);
      ref.read(refreshIntervalProvider.notifier).state = newInterval;

      controller?.add(data);
    } on DioException {
      // لا نوقف الـ Stream عند خطأ شبكة
    } catch (_) {
      // خطأ غير متوقع
    } finally {
      if (!disposed) {
        ref.read(isRefreshingProvider.notifier).state = false;
      }
    }
  }

  void scheduleNextFetch() {
    if (disposed) return;
    final interval = ref.read(refreshIntervalProvider);
    timer?.cancel();
    timer = Timer(interval, () async {
      await fetchAndEmit();
      scheduleNextFetch();
    });
  }

  controller = StreamController<LiveLogisticsSummaryModel>(
    onCancel: () {
      disposed = true;
      timer?.cancel();
    },
  );

  // جلب فوري عند الفتح
  fetchAndEmit().then((_) => scheduleNextFetch());

  ref.onDispose(() {
    disposed = true;
    timer?.cancel();
    controller?.close();
  });

  return controller.stream;
});

/// CountdownProvider يحسب الثواني المتبقية للتحديث القادم
final refreshCountdownProvider = StreamProvider.autoDispose<int>((ref) async* {
  while (true) {
    final lastRefresh = ref.read(lastRefreshTimeProvider);
    final interval = ref.read(refreshIntervalProvider);

    if (lastRefresh == null) {
      yield 0;
    } else {
      final elapsed = DateTime.now().difference(lastRefresh).inSeconds;
      final remaining = interval.inSeconds - elapsed;
      yield remaining.clamp(0, interval.inSeconds);
    }

    await Future.delayed(const Duration(seconds: 1));
  }
});

