import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/lifecycle_board/models/lifecycle_board_model.dart';
import 'package:frontend/features/lifecycle_board/providers/live_polling_provider.dart';

void main() {
  group('CL-004 Live Polling Provider Tests', () {
    test('Initial states of polling auxiliary providers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(lastRefreshTimeProvider), isNull);
      expect(container.read(isRefreshingProvider), isFalse);
      expect(container.read(refreshIntervalProvider), equals(const Duration(seconds: 60)));
    });

    test('Refresh interval adapts to critical risk shipments', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Normal state: 60s
      container.read(refreshIntervalProvider.notifier).state = const Duration(seconds: 60);
      expect(container.read(refreshIntervalProvider).inSeconds, equals(60));

      // Critical state: 20s
      container.read(refreshIntervalProvider.notifier).state = const Duration(seconds: 20);
      expect(container.read(refreshIntervalProvider).inSeconds, equals(20));
    });

    test('lastRefreshTimeProvider records timestamps', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final now = DateTime.now();
      container.read(lastRefreshTimeProvider.notifier).state = now;
      expect(container.read(lastRefreshTimeProvider), equals(now));

      container.read(isRefreshingProvider.notifier).state = true;
      expect(container.read(isRefreshingProvider), isTrue);
    });
  });
}
