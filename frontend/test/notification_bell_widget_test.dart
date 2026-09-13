import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/locale_provider.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/providers/navigation_provider.dart';
import 'package:frontend/features/notifications/models/notification_model.dart';
import 'package:frontend/features/notifications/providers/notifications_provider.dart';
import 'package:frontend/features/notifications/widgets/notification_bell_widget.dart';
import 'package:frontend/features/operational_dashboard/providers/operational_dashboard_provider.dart';

class MockNotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>>
    implements NotificationsNotifier {
  final List<int> readMarkedIds = [];

  MockNotificationsNotifier(List<NotificationModel> initialList)
      : super(AsyncValue.data(initialList));

  @override
  Future<void> fetchNotifications() async {}

  @override
  Future<void> markAsRead(int notificationId) async {
    readMarkedIds.add(notificationId);
    state.whenData((list) {
      final updated = list
          .map((n) => n.notificationId == notificationId ? n.copyWith(isRead: true) : n)
          .toList();
      state = AsyncValue.data(updated);
    });
  }

  @override
  Future<void> markAllAsRead() async {
    state.whenData((list) {
      final updated = list.map((n) => n.copyWith(isRead: true)).toList();
      state = AsyncValue.data(updated);
    });
  }

  @override
  Future<void> triggerExpiryCheck() async {}
}

void main() {
  group('NotificationBellWidget & Actionable Execution Links Tests', () {
    late Dio testDio;

    final sampleNotifications = [
      NotificationModel(
        notificationId: 1,
        title: '📄 نقص مستندي: IMP-2026-0004',
        message: 'مطلوب رفع شهادة المنشأ للشحنة لضمان استكمال الإفراج الجمركي.',
        severity: 'WARNING',
        category: 'INCOMPLETE_DOCS',
        entityType: 'ImportFile',
        entityId: 4,
        isRead: false,
        createdAt: '2026-09-13T10:00:00Z',
      ),
      NotificationModel(
        notificationId: 2,
        title: 'تنبيه متطلبات رقابية وفحص مسبق: IMP-2026-0002',
        message: 'الشحنة تتطلب موافقة الهيئة العامة للرقابة على الصادرات والواردات.',
        severity: 'CRITICAL',
        category: 'REGULATORY_INSPECTION_PENDING',
        entityType: 'ImportRequirementAssessment',
        entityId: 2,
        isRead: false,
        createdAt: '2026-09-13T10:05:00Z',
      ),
      NotificationModel(
        notificationId: 3,
        title: 'تنبيه انتهاء البطاقة الاستيرادية: SCAS For Construction',
        message: 'البطاقة الاستيرادية قاربت على الانتهاء بتاريخ 2026-05-30. يرجى التجديد فوراً.',
        severity: 'WARNING',
        category: 'COMPANY_EXPIRY_IMP_ID',
        entityType: 'ImportCompany',
        entityId: 2,
        isRead: true,
        createdAt: '2026-09-13T09:00:00Z',
      ),
      NotificationModel(
        notificationId: 4,
        title: 'تنبيه قرب انتهاء الرقم المبدئي ACID: 1234567890123456789',
        message: 'رقم الـ ACID متبقي عليه 5 أيام فقط قبل الشحن.',
        severity: 'WARNING',
        category: 'ACID_EXPIRY',
        entityType: 'AcidRegistrationSession',
        entityId: 1,
        isRead: false,
        createdAt: '2026-09-13T08:00:00Z',
      ),
      NotificationModel(
        notificationId: 5,
        title: '🚨 غرامات أرضيات نشطة: IMP-2026-0001',
        message: 'شحنة IMP-2026-0001 تتراكم عليها غرامات أرضيات بقيمة 450 دولار.',
        severity: 'CRITICAL',
        category: 'DEMURRAGE_ACTIVE',
        entityType: 'DemurrageTracking',
        entityId: 1,
        isRead: false,
        createdAt: '2026-09-13T07:00:00Z',
      ),
    ];

    setUp(() {
      testDio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: [],
              ),
            );
          },
        ),
      );
    });

    Widget buildTestWidget({
      required List<NotificationModel> notifications,
      Locale locale = const Locale('ar'),
    }) {
      return ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(testDio),
          notificationsProvider.overrideWith(
            (ref) => MockNotificationsNotifier(notifications),
          ),
          localeProvider.overrideWith((ref) {
            final n = LocaleNotifier();
            n.setLocale(locale);
            return n;
          }),
        ],
        child: MaterialApp(
          locale: locale,
          home: AppLocalizationsProvider(
            locale: locale,
            child: Directionality(
              textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              child: const Scaffold(
                appBar: PreferredSize(
                  preferredSize: Size.fromHeight(60),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        NotificationBellWidget(),
                      ],
                    ),
                  ),
                ),
                body: Center(child: Text('Main Body')),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Renders bell icon with unread count badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget(notifications: sampleNotifications));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications), findsOneWidget);
      // 4 unread notifications out of 5
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('Clicking bell opens popup menu showing notifications as actionable links', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget(notifications: sampleNotifications));
      await tester.pumpAndSettle();

      // Tap the notification bell button
      await tester.tap(find.byType(NotificationBellWidget));
      await tester.pumpAndSettle();

      // Verify header
      expect(find.textContaining('التنبيهات والإشعارات'), findsOneWidget);

      // Verify notifications are listed
      expect(find.textContaining('نقص مستندي'), findsOneWidget);
      expect(find.textContaining('تنبيه متطلبات رقابية'), findsOneWidget);
      expect(find.textContaining('تنبيه انتهاء البطاقة الاستيرادية'), findsOneWidget);

      // Verify execution action links are visible on each item
      expect(find.text('تنفيذ المهمة'), findsWidgets);
      expect(find.byIcon(Icons.open_in_new_rounded), findsWidgets);

      // Verify destination screen pills
      expect(find.text('الأرشيف المركزي للمستندات'), findsOneWidget);
      expect(find.text('اشتراطات وموافقات الاستيراد'), findsOneWidget);
      expect(find.text('الشركات المستوردة'), findsOneWidget);
      expect(find.text('منظومة نافذة ACID'), findsOneWidget);
      expect(find.text('رادار الغرامات والأرضيات'), findsOneWidget);
    });

    testWidgets('Tapping incomplete docs notification routes to Screen 51 and sets shipment search', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int dispatchedIndex = -1;
      String? searchedShipment;
      final mockNotifier = MockNotificationsNotifier(sampleNotifications);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(testDio),
            notificationsProvider.overrideWith((ref) => mockNotifier),
            localeProvider.overrideWith((ref) {
              final n = LocaleNotifier();
              n.setLocale(const Locale('ar'));
              return n;
            }),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              // Listen to navigation state
              ref.listen<int>(navigationIndexProvider, (prev, next) {
                dispatchedIndex = next;
              });
              ref.listen<OperationalDashboardState>(operationalDashboardProvider, (prev, next) {
                searchedShipment = next.searchQuery;
              });

              return const MaterialApp(
                home: AppLocalizationsProvider(
                  locale: Locale('ar'),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Scaffold(
                      appBar: PreferredSize(
                        preferredSize: Size.fromHeight(60),
                        child: SafeArea(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              NotificationBellWidget(),
                            ],
                          ),
                        ),
                      ),
                      body: Center(child: Text('Main Body')),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open notifications menu
      await tester.tap(find.byType(NotificationBellWidget));
      await tester.pumpAndSettle();

      // Tap the first notification (Incomplete Docs: IMP-2026-0004)
      final firstNotif = find.textContaining('نقص مستندي: IMP-2026-0004');
      expect(firstNotif, findsOneWidget);
      await tester.tap(firstNotif);
      await tester.pumpAndSettle();

      // Verify markAsRead was called for notification 1
      expect(mockNotifier.readMarkedIds, contains(1));

      // Verify target screen index 51 (CentralDocsArchiveScreen) was dispatched
      expect(dispatchedIndex, 51);

      // Verify shipment search query was set to IMP-2026-0004
      expect(searchedShipment, 'IMP-2026-0004');
    });

    testWidgets('English mode displays localized action link and target screen names', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestWidget(
          notifications: sampleNotifications,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      // Open notifications menu
      await tester.tap(find.byType(NotificationBellWidget));
      await tester.pumpAndSettle();

      // Header in English
      expect(find.textContaining('Alerts & Notifications'), findsOneWidget);

      // Action link label in English
      expect(find.text('Execute Task'), findsWidgets);

      // Target screen pills in English
      expect(find.text('Central Docs Archive'), findsOneWidget);
      expect(find.text('Import Requirements'), findsOneWidget);
      expect(find.text('Import Companies'), findsOneWidget);
      expect(find.text('Nafeza ACID Engine'), findsOneWidget);
      expect(find.text('Demurrage & Detention Radar'), findsOneWidget);
    });
  });
}
