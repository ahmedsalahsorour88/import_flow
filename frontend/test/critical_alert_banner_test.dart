import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/widgets/critical_alert_banner.dart';
import 'package:frontend/features/notifications/models/notification_model.dart';
import 'package:frontend/features/notifications/providers/notifications_provider.dart';

class MockNotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>>
    implements NotificationsNotifier {
  MockNotificationsNotifier(List<NotificationModel> initialList)
      : super(AsyncValue.data(initialList));

  @override
  Future<void> fetchNotifications() async {}

  @override
  Future<void> markAsRead(int notificationId) async {
    state.whenData((list) {
      state = AsyncValue.data(
        list.map((n) => n.notificationId == notificationId ? n.copyWith(isRead: true) : n).toList(),
      );
    });
  }

  @override
  Future<void> markAllAsRead() async {
    state.whenData((list) {
      state = AsyncValue.data(
        list.map((n) => n.copyWith(isRead: true)).toList(),
      );
    });
  }

  @override
  Future<void> triggerExpiryCheck() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockCriticalNotification = NotificationModel(
    notificationId: 1,
    title: '🚨 غرامات أرضيات نشطة: IMP-2026-0002',
    message: 'شحنة تتراكم عليها غرامات بقيمة 350 دولار',
    severity: 'CRITICAL',
    category: 'DEMURRAGE_ACTIVE',
    entityType: 'DemurrageTracking',
    entityId: 1,
    targetRole: 'ALL',
    isRead: false,
    createdAt: '2026-09-01T12:00:00',
  );

  Widget createWidgetUnderTest(List<NotificationModel> notifications) {
    return ProviderScope(
      overrides: [
        notificationsProvider.overrideWith((ref) => MockNotificationsNotifier(notifications)),
      ],
      child: const AppLocalizationsProvider(
        locale: Locale('ar'),
        child: MaterialApp(
          home: Scaffold(
            body: CriticalAlertBanner(),
          ),
        ),
      ),
    );
  }

  group('CL-006 CriticalAlertBanner Widget Tests', () {
    testWidgets('CriticalAlertBanner is hidden when no unread CRITICAL notifications exist', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest([]));
      await tester.pumpAndSettle();

      expect(find.byType(CriticalAlertBanner), findsOneWidget);
      expect(find.textContaining('تنبيه حرج'), findsNothing);
    });

    testWidgets('CriticalAlertBanner is visible when unread CRITICAL notification is present', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest([mockCriticalNotification]));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 تنبيه حرج يتطلب تدخلاً فورياً'), findsOneWidget);
      expect(find.textContaining('غرامات أرضيات نشطة'), findsOneWidget);
      expect(find.text('عرض التفاصيل (1)'), findsOneWidget);
    });

    testWidgets('Tapping on view details button opens the alerts sheet', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest([mockCriticalNotification]));
      await tester.pumpAndSettle();

      final detailsBtn = find.text('عرض التفاصيل (1)');
      expect(detailsBtn, findsOneWidget);
      await tester.tap(detailsBtn);
      await tester.pumpAndSettle();

      expect(find.text('التنبيهات الحرجة (1)'), findsOneWidget);
      expect(find.text('وضع الكل مقروءاً ✓'), findsOneWidget);
    });
  });
}
