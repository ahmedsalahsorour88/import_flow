import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/lifecycle_board/models/lifecycle_board_model.dart';
import 'package:frontend/features/lifecycle_board/providers/lifecycle_board_provider.dart';
import 'package:frontend/features/lifecycle_board/providers/live_polling_provider.dart';
import 'package:frontend/features/lifecycle_board/screens/lifecycle_board_screen.dart';
import 'package:frontend/features/notifications/models/notification_model.dart';
import 'package:frontend/features/notifications/providers/notifications_provider.dart';

class MockNotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>>
    implements NotificationsNotifier {
  MockNotificationsNotifier([List<NotificationModel>? initialList])
      : super(AsyncValue.data(initialList ?? []));

  @override
  Future<void> fetchNotifications() async {}

  @override
  Future<void> markAsRead(int notificationId) async {}

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> triggerExpiryCheck() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockBoardData = LifecycleBoardSummaryModel(
    phases: [
      PhaseSummaryModel(
        phaseId: 1,
        titleEn: '1. Pre-Planning & Studies',
        titleAr: 'المرحلة الأولى: التخطيط والدراسات المسبقة',
        colorHex: '#D97706',
        stepCodes: ['STEP_01', 'STEP_02', 'STEP_03'],
        totalActiveShipments: 1,
        stepCounts: {'STEP_01': 1, 'STEP_02': 0, 'STEP_03': 0},
      ),
    ],
    totalActiveFiles: 1,
    allShipments: [
      ShipmentStageCardModel(
        importFileCode: 'IMP-2026-0001',
        companyName: 'Al-Amal Import Co.',
        supplierName: 'Global Steel Ltd',
        poNumber: 'PO-9901',
        shipmentMode: 'Sea FCL',
        incotermCode: 'CIF',
        priority: 'High',
        estimatedCost: 50000.0,
        estimatedCostCurrency: 'USD',
        stepCode: 'STEP_01',
        stepNameEn: 'Freight Studies',
        stepNameAr: 'دراسات ومفاضلة نولون الشحن',
        status: 'In-Progress',
      ),
    ],
  );

  final mockRadarData = LiveLogisticsSummaryModel(
    totalActiveShipments: 2,
    inTransitCount: 1,
    inPortCount: 1,
    highRiskDemurrageCount: 1,
    underSampleTestingCount: 1,
    incompleteDocumentsCount: 1,
    items: [
      LiveLogisticsTrackingItemModel(
        importFileId: 1,
        importFileCode: 'IMP-2026-0001',
        companyName: 'Al-Amal Import Co.',
        supplierName: 'Global Steel Ltd',
        poNumber: 'PO-9901',
        shipmentMode: 'Sea FCL',
        incotermCode: 'CIF',
        priority: 'Critical',
        blNumber: 'MEDU1234567',
        carrierName: 'MSC Line',
        vesselName: 'Ever Given',
        polName: 'Shanghai Port',
        podName: 'El Dekheila Port',
        etd: '2026-08-10',
        eta: '2026-09-05',
        etaCountdownDays: 4,
        arrivalStatus: 'In Transit / Sailing',
        demurrageStatus: 'Safe',
        freeDaysTotal: 14,
        freeDaysRemaining: 14,
        usedFreeDays: 0,
        demurrageRiskLevel: 'Low',
        accumulatedDemurrageFx: 0.0,
        accumulatedDemurrageEgp: 0.0,
        sampleTestStatus: 'Under Testing',
        regulatoryAgency: 'GOEIC',
        labReceiptNumber: 'LAB-GOEIC-107',
        sampleResultCountdownDays: 3,
        docReadinessPercent: 85.7,
        verifiedDocumentsCount: 6,
        totalRequiredDocuments: 7,
        missingDocuments: ['Customs Declaration 46'],
        operationalHealthScore: 'Attention Needed',
        currentStepCode: 'STEP_01',
        currentStepNameAr: 'دراسات ومفاضلة نولون الشحن',
        currentStepNameEn: 'Freight Studies',
        nextAction: 'مراجعة عروض الأسعار',
      ),
      LiveLogisticsTrackingItemModel(
        importFileId: 2,
        importFileCode: 'IMP-2026-0002',
        companyName: 'Nile Trading Group',
        supplierName: 'Bavaria Tech GmbH',
        poNumber: 'PO-9902',
        shipmentMode: 'Sea FCL',
        incotermCode: 'FOB',
        priority: 'High',
        blNumber: 'MAEU9876543',
        carrierName: 'Maersk Line',
        vesselName: 'Maersk Mc-Kinney',
        polName: 'Hamburg Port',
        podName: 'Alexandria Port',
        etd: '2026-07-20',
        eta: '2026-08-15',
        etaCountdownDays: -17,
        arrivalStatus: 'In Port / Clearing',
        demurrageStatus: 'Demurrage Incurred',
        freeDaysTotal: 14,
        freeDaysRemaining: 0,
        usedFreeDays: 17,
        demurrageRiskLevel: 'Critical',
        accumulatedDemurrageFx: 350.0,
        accumulatedDemurrageEgp: 17500.0,
        sampleTestStatus: 'Approved',
        regulatoryAgency: 'Food Safety',
        labReceiptNumber: 'LAB-FS-204',
        sampleResultCountdownDays: 0,
        docReadinessPercent: 42.8,
        verifiedDocumentsCount: 3,
        totalRequiredDocuments: 7,
        missingDocuments: ['Bank Form 4', 'ACID Number', 'Form 46', 'COO'],
        operationalHealthScore: 'Critical Alert',
        currentStepCode: 'STEP_18',
        currentStepNameAr: 'إدارة الغرامات وفترات السماح',
        currentStepNameEn: 'Demurrage & Detention',
        nextAction: 'تسوية غرامات الخط الملاحي',
      ),
    ],
  );

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        lifecycleBoardSummaryProvider.overrideWith((ref) => Future.value(mockBoardData)),
        liveLogisticsTrackingProvider.overrideWith((ref) => Future.value(mockRadarData)),
        livePollingProvider.overrideWith((ref) => Stream.value(mockRadarData)),
        refreshCountdownProvider.overrideWith((ref) => Stream.value(45)),
        notificationsProvider.overrideWith((ref) => MockNotificationsNotifier([])),
      ],
      child: const AppLocalizationsProvider(
        locale: Locale('ar'),
        child: MaterialApp(
          home: LifecycleBoardScreen(),
        ),
      ),
    );
  }

  group('CL-003, CL-004, CL-005, CL-006 Live Shipment Logistics Tracking Radar Tests', () {
    test('LiveLogisticsSummaryModel serialization and model parsing', () {
      final json = {
        'total_active_shipments': 1,
        'in_transit_count': 1,
        'in_port_count': 0,
        'high_risk_demurrage_count': 0,
        'under_sample_testing_count': 1,
        'incomplete_documents_count': 0,
        'items': [
          {
            'import_file_id': 1,
            'import_file_code': 'IMP-2026-0001',
            'company_name': 'Test Co',
            'supplier_name': 'Test Sup',
            'po_number': 'PO-1',
            'shipment_mode': 'Sea FCL',
            'incoterm_code': 'CIF',
            'priority': 'High',
            'bl_number': 'BL-123',
            'carrier_name': 'MSC',
            'vessel_name': 'Ship A',
            'pol_name': 'POL',
            'pod_name': 'POD',
            'etd': '2026-08-01',
            'eta': '2026-09-01',
            'eta_countdown_days': 5,
            'arrival_status': 'In Transit / Sailing',
            'demurrage_status': 'Safe',
            'free_days_total': 14,
            'free_days_remaining': 14,
            'used_free_days': 0,
            'demurrage_risk_level': 'Low',
            'accumulated_demurrage_fx': 0.0,
            'accumulated_demurrage_egp': 0.0,
            'sample_test_status': 'Under Testing',
            'regulatory_agency': 'GOEIC',
            'lab_receipt_number': 'LAB-1',
            'sample_result_countdown_days': 3,
            'doc_readiness_percent': 85.7,
            'verified_documents_count': 6,
            'total_required_documents': 7,
            'missing_documents': ['Form 46'],
            'operational_health_score': 'Optimal',
            'current_step_code': 'STEP_01',
            'current_step_name_ar': 'دراسات النولون',
            'current_step_name_en': 'Freight Studies',
            'next_action': 'Action',
          }
        ]
      };

      final model = LiveLogisticsSummaryModel.fromJson(json);
      expect(model.totalActiveShipments, equals(1));
      expect(model.items.length, equals(1));
      expect(model.items.first.importFileCode, equals('IMP-2026-0001'));
      expect(model.items.first.docReadinessPercent, equals(85.7));
      expect(model.items.first.freeDaysRemaining, equals(14));
      expect(model.items.first.etaCountdownDays, equals(5));
    });

    testWidgets('LifecycleBoardScreen switches smoothly between Kanban and Live Logistics Radar views', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 1. Initially on Kanban view (Mode 0)
      expect(find.byType(LifecycleBoardScreen), findsOneWidget);
      expect(find.text('IMP-2026-0001'), findsWidgets);

      // 2. Switch to Live Logistics Radar view (Mode 1)
      final radarTab = find.text('رادار التتبع اللوجستي الحي');
      expect(radarTab, findsOneWidget);
      await tester.tap(radarTab);
      await tester.pumpAndSettle();

      // 3. Verify CL-004 countdown indicator in AppBar
      expect(find.text('45s'), findsOneWidget);

      // 4. Verify KPI cards render
      expect(find.text('في الطريق للميناء'), findsOneWidget);
      expect(find.text('في الميناء وقيد التخليص'), findsOneWidget);
      expect(find.text('خطر غرامات أرضيات'), findsOneWidget);
      expect(find.text('عينات قيد الفحص المعملي'), findsOneWidget);
      expect(find.text('نواقص مستندية'), findsOneWidget);

      // 5. Verify Radar items and badges
      expect(find.text('IMP-2026-0001'), findsOneWidget);
      expect(find.text('IMP-2026-0002'), findsOneWidget);
      expect(find.text('Under Testing'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('86%'), findsOneWidget);
      expect(find.text('43%'), findsOneWidget);

      // 6. Verify CL-005 navigation indicator icon is present
      expect(find.byIcon(Icons.open_in_new), findsWidgets);

      // 7. Test Risk Filter Chips
      final criticalFilter = find.text('خطر حرج');
      expect(criticalFilter, findsOneWidget);
      await tester.tap(criticalFilter);
      await tester.pumpAndSettle();

      expect(find.text('IMP-2026-0002'), findsOneWidget);
      expect(find.text('IMP-2026-0001'), findsNothing);

      // Switch back to All
      final allFilter = find.text('جميع مستويات الخطر');
      await tester.tap(allFilter);
      await tester.pumpAndSettle();
      expect(find.text('IMP-2026-0001'), findsOneWidget);
      expect(find.text('IMP-2026-0002'), findsOneWidget);
    });
  });
}
