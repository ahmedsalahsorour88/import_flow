import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/locale_provider.dart';
import 'package:frontend/features/operational_dashboard/models/operational_dashboard_model.dart';
import 'package:frontend/features/operational_dashboard/providers/operational_dashboard_provider.dart';
import 'package:frontend/features/operational_dashboard/screens/operational_dashboard_screen.dart';

class MockOperationalDashboardNotifier extends StateNotifier<OperationalDashboardState> implements OperationalDashboardNotifier {
  MockOperationalDashboardNotifier(OperationalDashboardData sampleData)
      : super(OperationalDashboardState(data: AsyncValue.data(sampleData)));

  @override
  Future<void> fetchDashboard() async {}

  @override
  void setPriority(String priority) {}

  @override
  void setBroker(String? broker) {}

  @override
  void setSearchQuery(String query) {}

  @override
  void resetFilters() {}

  @override
  void togglePhase(String phase) {}
}

void main() {
  final sampleDashboardData = OperationalDashboardData(
    shipmentCount: 1,
    lastUpdatedAt: '2026-08-23T20:00:00Z',
    availableBrokers: [
      DashboardBroker(brokerId: 1, brokerName: 'Al-Ameen Customs Clearance'),
    ],
    phaseCounts: {'Phase 1': 1},
    shipments: [],
  );

  group('OperationalDashboardModel Unit Tests (Feature 2.9)', () {
    test('Should parse OperationalDashboardData from JSON correctly', () {
      final json = {
        'shipment_count': 3,
        'last_updated_at': '2026-08-09T14:00:00Z',
        'available_brokers': [
          {'broker_id': 1, 'broker_name': 'Al-Ameen Customs Clearance'},
          {'broker_id': 2, 'broker_name': 'El-Nasr Logistics'},
        ],
        'phase_counts': {
          'Phase 1': 2,
          'Phase 2': 1,
          'Phase 5': 4,
          'Phase 7': 1,
        },
        'shipments': [
          {
            'import_file_id': 1,
            'import_file_code': 'IMP-2026-0001',
            'company_name': 'Alpha Import Ltd',
            'supplier_name': 'Sino Tech Ltd',
            'broker_name': 'Al-Ameen Customs Clearance',
            'priority': 'High',
            'current_module': 'Phase 7 - Customs Clearance',
            'current_stage': 'Duty Payment Requested',
            'progress_percent': 70.0,
            'next_action': 'Pay Duties',
            'is_active': true,
            'created_at': '2026-08-09T10:00:00Z',
            'updated_at': '2026-08-09T10:00:00Z',
          }
        ],
      };

      final data = OperationalDashboardData.fromJson(json);

      expect(data.shipmentCount, 3);
      expect(data.availableBrokers.length, 2);
      expect(data.availableBrokers.first.brokerName, 'Al-Ameen Customs Clearance');
      expect(data.phaseCounts['Phase 5'], 4);
      expect(data.shipments.length, 1);
      expect(data.shipments.first.importFileCode, 'IMP-2026-0001');
    });

    test('DashboardBroker JSON serialization test', () {
      final broker = DashboardBroker(brokerId: 5, brokerName: 'Global Cargo Express');
      final json = broker.toJson();

      expect(json['broker_id'], 5);
      expect(json['broker_name'], 'Global Cargo Express');
    });
  });

  group('OperationalDashboardScreen Localization & Single-Language Rendering Tests', () {
    testWidgets('Renders Arabic-only when Arabic locale is active (No Stacked Arabic+English)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) {
              final n = LocaleNotifier();
              n.setLocale(const Locale('ar'));
              return n;
            }),
            operationalDashboardProvider.overrideWith(
              (ref) => MockOperationalDashboardNotifier(sampleDashboardData),
            ),
          ],
          child: const MaterialApp(
            home: AppLocalizationsProvider(
              locale: Locale('ar'),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: OperationalDashboardScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Arabic titles and controls exist
      expect(find.text('لوحة التحكم ومساحة العمليات'), findsOneWidget);
      expect(find.text('الأولوية:'), findsOneWidget);
      expect(find.text('المخلص الجمركي:'), findsOneWidget);
      expect(find.text('بحث سريع:'), findsOneWidget);
      expect(find.text('إعادة ضبط الفلاتر'), findsOneWidget);

      // Verify OLD stacked/mixed text NEVER appears
      expect(find.text('الأولوية (Priority):'), findsNothing);
      expect(find.text('المخلص الجمركي (Customs Broker):'), findsNothing);
      expect(find.text('بحث سريع (Search):'), findsNothing);
      expect(find.text('جميع المخلصين (All Brokers)'), findsNothing);
      expect(find.text('سجل التحديثات التشغيلية واليومية المباشرة (Daily Check-ins & Live Log):'), findsNothing);
      expect(find.text('روابط الاختصارات السريعة لإنشاء وإدخال السجلات (Quick Create & Register Shortcuts):'), findsNothing);
    });

    testWidgets('Renders English-only when English locale is active (No Stacked Arabic+English)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) {
              final n = LocaleNotifier();
              n.setLocale(const Locale('en'));
              return n;
            }),
            operationalDashboardProvider.overrideWith(
              (ref) => MockOperationalDashboardNotifier(sampleDashboardData),
            ),
          ],
          child: const MaterialApp(
            home: AppLocalizationsProvider(
              locale: Locale('en'),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: OperationalDashboardScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check English titles and controls exist
      expect(find.text('Operational Workspace Dashboard'), findsOneWidget);
      expect(find.text('Priority:'), findsOneWidget);
      expect(find.text('Customs Broker:'), findsOneWidget);
      expect(find.text('Quick Search:'), findsOneWidget);
      expect(find.text('Reset Filters'), findsOneWidget);

      // Verify Arabic text does not pollute the English UI
      expect(find.text('لوحة التحكم ومساحة العمليات'), findsNothing);
      expect(find.text('الأولوية:'), findsNothing);
      expect(find.text('الأولوية (Priority):'), findsNothing);
      expect(find.text('المخلص الجمركي (Customs Broker):'), findsNothing);
      expect(find.text('إعادة ضبط الفلاتر'), findsNothing);
    });
  });
}



