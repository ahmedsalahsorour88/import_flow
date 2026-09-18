import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/demurrage_detention/models/demurrage_model.dart';
import 'package:frontend/features/demurrage_detention/providers/demurrage_provider.dart';
import 'package:frontend/features/operational_dashboard/widgets/container_demurrage_radar_card.dart';

void main() {
  group('TR-02: Demurrage & Detention Radar Models Tests', () {
    test('ContainerRadarItemModel and ContainerRadarOverviewModel parse from JSON correctly', () {
      final json = {
        'total_containers_tracked': 3,
        'safe_containers_count': 1,
        'warning_containers_count': 1,
        'critical_overdue_count': 1,
        'returned_containers_count': 0,
        'total_accrued_demurrage_usd': 420.0,
        'total_accrued_storage_egp': 3750.0,
        'total_estimated_exposure_egp': 24750.0,
        'generated_at': '2026-09-18T14:30:00Z',
        'radar_items': [
          {
            'tracking_id': 101,
            'import_file_id': 55,
            'import_file_code': 'IMP-2026-0055',
            'bill_of_lading_no': 'MEDU1122334',
            'carrier_name': 'MSC',
            'container_number': 'MSCU1111111',
            'container_type': '40ft High Cube',
            'discharge_date': '2026-09-16',
            'gate_out_date': null,
            'empty_return_date': null,
            'radar_status': 'SAFE',
            'color_code': '#27AE60',
            'status_label_ar': 'آمن - داخل فترة السماح',
            'demurrage_days_consumed': 2,
            'demurrage_free_days': 14,
            'demurrage_days_remaining': 12,
            'storage_days_consumed': 2,
            'storage_free_days': 5,
            'storage_days_remaining': 3,
            'accrued_demurrage_usd': 0.0,
            'accrued_storage_egp': 0.0,
            'total_accrued_egp': 0.0,
            'alert_message_ar': 'الحاوية داخل فترة السماح المعتمدة (متبقي 12 يوماً للخط الملاحي).',
          },
          {
            'tracking_id': 102,
            'import_file_id': 56,
            'import_file_code': 'IMP-2026-0056',
            'bill_of_lading_no': 'MAEU5566778',
            'carrier_name': 'Maersk',
            'container_number': 'MRKU2222222',
            'container_type': '40ft High Cube',
            'discharge_date': '2026-09-15',
            'gate_out_date': null,
            'empty_return_date': null,
            'radar_status': 'WARNING',
            'color_code': '#E67E22',
            'status_label_ar': 'تحذير - اقتراب انتهاء السماح',
            'demurrage_days_consumed': 3,
            'demurrage_free_days': 14,
            'demurrage_days_remaining': 11,
            'storage_days_consumed': 3,
            'storage_free_days': 5,
            'storage_days_remaining': 2,
            'accrued_demurrage_usd': 0.0,
            'accrued_storage_egp': 0.0,
            'total_accrued_egp': 0.0,
            'alert_message_ar': 'تحذير: متبقي 2 أيام فقط قبل بدء سريان غرامات التأخير والأرضيات.',
          },
          {
            'tracking_id': 103,
            'import_file_id': 57,
            'import_file_code': 'IMP-2026-0057',
            'bill_of_lading_no': 'CMAU9988776',
            'carrier_name': 'CMA CGM',
            'container_number': 'CMAU3333333',
            'container_type': '40ft High Cube',
            'discharge_date': '2026-08-28',
            'gate_out_date': null,
            'empty_return_date': null,
            'radar_status': 'CRITICAL_OVERDUE',
            'color_code': '#C0392B',
            'status_label_ar': 'حرج - سريان غرامات يومية',
            'demurrage_days_consumed': 21,
            'demurrage_free_days': 14,
            'demurrage_days_remaining': 0,
            'storage_days_consumed': 21,
            'storage_free_days': 5,
            'storage_days_remaining': 0,
            'accrued_demurrage_usd': 420.0,
            'accrued_storage_egp': 3750.0,
            'total_accrued_egp': 24750.0,
            'alert_message_ar': 'خطر غرامات: تجاوز فترة السماح بـ 16 أيام! مطلوب سرعة التعتيق والإرجاع.',
          },
        ],
      };

      final overview = ContainerRadarOverviewModel.fromJson(json);

      expect(overview.totalContainersTracked, 3);
      expect(overview.safeContainersCount, 1);
      expect(overview.warningContainersCount, 1);
      expect(overview.criticalOverdueCount, 1);
      expect(overview.returnedContainersCount, 0);
      expect(overview.totalAccruedDemurrageUsd, 420.0);
      expect(overview.totalAccruedStorageEgp, 3750.0);
      expect(overview.totalEstimatedExposureEgp, 24750.0);
      expect(overview.radarItems.length, 3);

      final safeItem = overview.radarItems[0];
      expect(safeItem.containerNumber, 'MSCU1111111');
      expect(safeItem.radarStatus, 'SAFE');
      expect(safeItem.colorCode, '#27AE60');
      expect(safeItem.demurrageDaysRemaining, 12);
      expect(safeItem.storageDaysRemaining, 3);

      final warnItem = overview.radarItems[1];
      expect(warnItem.containerNumber, 'MRKU2222222');
      expect(warnItem.radarStatus, 'WARNING');
      expect(warnItem.colorCode, '#E67E22');

      final critItem = overview.radarItems[2];
      expect(critItem.containerNumber, 'CMAU3333333');
      expect(critItem.radarStatus, 'CRITICAL_OVERDUE');
      expect(critItem.colorCode, '#C0392B');
      expect(critItem.accruedDemurrageUsd, 420.0);
      expect(critItem.accruedStorageEgp, 3750.0);
    });
  });

  group('TR-02: ContainerDemurrageRadarCard Widget Tests', () {
    testWidgets('Renders ContainerDemurrageRadarCard with header, 4 KPI badges, exposure alert, and container items', (tester) async {
      final mockRadar = ContainerRadarOverviewModel(
        totalContainersTracked: 3,
        safeContainersCount: 1,
        warningContainersCount: 1,
        criticalOverdueCount: 1,
        returnedContainersCount: 0,
        totalAccruedDemurrageUsd: 420.0,
        totalAccruedStorageEgp: 3750.0,
        totalEstimatedExposureEgp: 24750.0,
        generatedAt: '2026-09-18T14:30:00Z',
        radarItems: [
          ContainerRadarItemModel(
            trackingId: 101,
            importFileId: 55,
            importFileCode: 'IMP-2026-0055',
            billOfLadingNo: 'MEDU1122334',
            carrierName: 'MSC',
            containerNumber: 'MSCU1111111',
            containerType: '40ft High Cube',
            dischargeDate: '2026-09-16',
            radarStatus: 'SAFE',
            colorCode: '#27AE60',
            statusLabelAr: 'آمن - داخل فترة السماح',
            demurrageDaysConsumed: 2,
            demurrageFreeDays: 14,
            demurrageDaysRemaining: 12,
            storageDaysConsumed: 2,
            storageFreeDays: 5,
            storageDaysRemaining: 3,
            accruedDemurrageUsd: 0.0,
            accruedStorageEgp: 0.0,
            totalAccruedEgp: 0.0,
            alertMessageAr: 'الحاوية داخل فترة السماح المعتمدة',
          ),
          ContainerRadarItemModel(
            trackingId: 102,
            importFileId: 56,
            importFileCode: 'IMP-2026-0056',
            billOfLadingNo: 'MAEU5566778',
            carrierName: 'Maersk',
            containerNumber: 'MRKU2222222',
            containerType: '40ft High Cube',
            dischargeDate: '2026-09-15',
            radarStatus: 'WARNING',
            colorCode: '#E67E22',
            statusLabelAr: 'تحذير - اقتراب انتهاء السماح',
            demurrageDaysConsumed: 3,
            demurrageFreeDays: 14,
            demurrageDaysRemaining: 11,
            storageDaysConsumed: 3,
            storageFreeDays: 5,
            storageDaysRemaining: 2,
            accruedDemurrageUsd: 0.0,
            accruedStorageEgp: 0.0,
            totalAccruedEgp: 0.0,
            alertMessageAr: 'تحذير: متبقي 2 أيام قبل بدء الغرامات',
          ),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            containerRadarOverviewProvider.overrideWith((ref) => Future.value(mockRadar)),
          ],
          child: const AppLocalizationsProvider(
            locale: Locale('ar'),
            child: MaterialApp(
              locale: Locale('ar'),
              home: Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ContainerDemurrageRadarCard(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Header & Title
      expect(find.byKey(const Key('containerDemurrageRadarCard')), findsOneWidget);
      expect(find.text('رادار مراقبة فترات السماح وتفادي غرامات الحاويات (TR-02)'), findsOneWidget);
      expect(find.byKey(const Key('openDemurrageRadarBtn')), findsOneWidget);
      expect(find.byKey(const Key('refreshDemurrageRadarBtn')), findsOneWidget);

      // 2. KPI Badges
      expect(find.textContaining('آمن داخل السماح:'), findsOneWidget);
      expect(find.textContaining('تحذير 72 ساعة:'), findsOneWidget);
      expect(find.textContaining('غرامات سارية:'), findsOneWidget);
      expect(find.textContaining('تم الإرجاع:'), findsOneWidget);

      // 3. Accrued Exposure Warning Banner
      expect(find.textContaining('إجمالي الغرامات الجارية:'), findsOneWidget);

      // 4. Container Items
      expect(find.byKey(const Key('radar_item_MSCU1111111')), findsOneWidget);
      expect(find.byKey(const Key('radar_item_MRKU2222222')), findsOneWidget);
      expect(find.text('MSCU1111111'), findsOneWidget);
      expect(find.text('MRKU2222222'), findsOneWidget);
      expect(find.text('آمن - داخل فترة السماح'), findsOneWidget);
      expect(find.text('تحذير - اقتراب انتهاء السماح'), findsOneWidget);
    });

    testWidgets('Renders empty state message when no containers are tracked', (tester) async {
      final emptyRadar = ContainerRadarOverviewModel(
        totalContainersTracked: 0,
        safeContainersCount: 0,
        warningContainersCount: 0,
        criticalOverdueCount: 0,
        returnedContainersCount: 0,
        totalAccruedDemurrageUsd: 0.0,
        totalAccruedStorageEgp: 0.0,
        totalEstimatedExposureEgp: 0.0,
        generatedAt: '2026-09-18T14:30:00Z',
        radarItems: [],
      );

      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            containerRadarOverviewProvider.overrideWith((ref) => Future.value(emptyRadar)),
          ],
          child: const AppLocalizationsProvider(
            locale: Locale('ar'),
            child: MaterialApp(
              locale: Locale('ar'),
              home: Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ContainerDemurrageRadarCard(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('لا توجد حاويات قيد التتبع حالياً — كافة الشحنات مستقرة داخل فترات السماح.'), findsOneWidget);
    });
  });
}
