import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/demurrage_detention/widgets/freight_data_monitor_dialog.dart';

class _MockFreightHttpClientAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    if (path.contains('/freight-data/status')) {
      final mockStatus = {
        'shaq_freight_status': 'Active (Free SFX Weekly Index)',
        'last_sfx_sync': '2026-09-10T08:00:00Z',
        'total_sfx_routes_tracked': 20,
        'shippingrates_status': 'Active (Quota Guard Protected)',
        'monthly_quota_limit': 25,
        'monthly_quota_used': 3,
        'monthly_quota_remaining': 22,
        'active_shipping_lines_tracked': 5,
        'active_port_decrees_count': 8,
        'active_port_authorities': ['Alexandria', 'Damietta', 'Sokhna', 'Port Said'],
      };
      return ResponseBody.fromString(
        jsonEncode(mockStatus),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (path.contains('/freight-data/port-tariffs')) {
      final mockTariffs = [
        {
          'port_authority': 'Alexandria',
          'container_type': '40ft',
          'free_days': 4,
          'rate_slabs': [
            {'from_day': 1, 'to_day': 4, 'rate_per_day': 0.0},
            {'from_day': 5, 'to_day': 10, 'rate_per_day': 280.0},
          ],
          'tariff_version': 'Decision-554-2024',
          'effective_from': '2024-07-01',
          'effective_to': null,
          'source_document': 'Ministerial_Decree_554_2024.pdf',
        }
      ];
      return ResponseBody.fromString(
        jsonEncode(mockTariffs),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString('[]', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Dio _createTestDio() {
  final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:28080/api/v1'));
  dio.httpClientAdapter = _MockFreightHttpClientAdapter();
  return dio;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('INT-DATA-015: Free Freight & Demurrage Connector Tests', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    test('All INT-DATA-015 localization getters are defined and non-empty', () {
      final gettersAr = [
        ar.freightDataConnectorDialogTitle,
        ar.freightDataConnectorDialogSubtitle,
        ar.freightDataTabOverview,
        ar.freightDataTabSimulator,
        ar.freightDataTabPortTariffs,
        ar.freightDataShaqFreightSection,
        ar.freightDataShaqFreightDesc,
        ar.freightDataShippingRatesSection,
        ar.freightDataShippingRatesDesc,
        ar.freightDataPortDecreesSection,
        ar.freightDataPortDecreesDesc,
        ar.freightDataStatusActive,
        ar.freightDataMonthlyQuota,
        ar.freightDataQuotaUsed,
        ar.freightDataQuotaRemaining,
        ar.freightDataSyncSfxNow,
        ar.freightDataSyncSfxSuccess,
        ar.freightDataRefreshStatus,
        ar.freightDataTrackedRoutesCount,
        ar.freightDataTrackedLinesCount,
        ar.freightDataActiveDecreesCount,
        ar.freightDataLastSyncDate,
        ar.freightDataNeverSynced,
        ar.freightDataSimShippingLine,
        ar.freightDataSimPortAuthority,
        ar.freightDataSimContainerType,
        ar.freightDataSimDischargeDate,
        ar.freightDataSimClearanceDate,
        ar.freightDataSimDaysInPort,
        ar.freightDataSimFxRate,
        ar.freightDataSimCalculateBtn,
        ar.freightDataCarrierDetentionTitle,
        ar.freightDataPortStorageTitle,
        ar.freightDataAppliedDecree,
        ar.freightDataFreeDaysLabel,
        ar.freightDataChargeableDaysLabel,
        ar.freightDataConsolidatedSummary,
        ar.freightDataTotalDetentionUsd,
        ar.freightDataTotalStorageEgp,
        ar.freightDataConsolidatedEgp,
        ar.freightDataConsolidatedUsd,
        ar.freightDataCopySimulationDossier,
        ar.freightDataSimulationDossierCopied,
        ar.freightDataAddTariffDecreeBtn,
        ar.freightDataTariffVersionCol,
        ar.freightDataEffectiveFromCol,
        ar.freightDataEffectiveToCol,
        ar.freightDataActiveOngoing,
        ar.freightDataSourceDocCol,
        ar.freightDataRateSlabsSummary,
        ar.freightDataCopySlabRateTooltip,
        ar.freightDataLaunchConnectorTooltip,
        ar.freightDataQuotaGuardAlert,
        ar.freightDataDayUnit,
        ar.freightDataPerDayUnit,
        ar.freightDataCopyStatusSummary,
        ar.freightDataTotalLabel,
        ar.freightDataNoDecreesFound,
      ];

      final gettersEn = [
        en.freightDataConnectorDialogTitle,
        en.freightDataConnectorDialogSubtitle,
        en.freightDataTabOverview,
        en.freightDataTabSimulator,
        en.freightDataTabPortTariffs,
        en.freightDataShaqFreightSection,
        en.freightDataShaqFreightDesc,
        en.freightDataShippingRatesSection,
        en.freightDataShippingRatesDesc,
        en.freightDataPortDecreesSection,
        en.freightDataPortDecreesDesc,
        en.freightDataStatusActive,
        en.freightDataMonthlyQuota,
        en.freightDataQuotaUsed,
        en.freightDataQuotaRemaining,
        en.freightDataSyncSfxNow,
        en.freightDataSyncSfxSuccess,
        en.freightDataRefreshStatus,
        en.freightDataTrackedRoutesCount,
        en.freightDataTrackedLinesCount,
        en.freightDataActiveDecreesCount,
        en.freightDataLastSyncDate,
        en.freightDataNeverSynced,
        en.freightDataSimShippingLine,
        en.freightDataSimPortAuthority,
        en.freightDataSimContainerType,
        en.freightDataSimDischargeDate,
        en.freightDataSimClearanceDate,
        en.freightDataSimDaysInPort,
        en.freightDataSimFxRate,
        en.freightDataSimCalculateBtn,
        en.freightDataCarrierDetentionTitle,
        en.freightDataPortStorageTitle,
        en.freightDataAppliedDecree,
        en.freightDataFreeDaysLabel,
        en.freightDataChargeableDaysLabel,
        en.freightDataConsolidatedSummary,
        en.freightDataTotalDetentionUsd,
        en.freightDataTotalStorageEgp,
        en.freightDataConsolidatedEgp,
        en.freightDataConsolidatedUsd,
        en.freightDataCopySimulationDossier,
        en.freightDataSimulationDossierCopied,
        en.freightDataAddTariffDecreeBtn,
        en.freightDataTariffVersionCol,
        en.freightDataEffectiveFromCol,
        en.freightDataEffectiveToCol,
        en.freightDataActiveOngoing,
        en.freightDataSourceDocCol,
        en.freightDataRateSlabsSummary,
        en.freightDataCopySlabRateTooltip,
        en.freightDataLaunchConnectorTooltip,
        en.freightDataQuotaGuardAlert,
        en.freightDataDayUnit,
        en.freightDataPerDayUnit,
        en.freightDataCopyStatusSummary,
        en.freightDataTotalLabel,
        en.freightDataNoDecreesFound,
      ];

      expect(gettersAr.length, 58);
      expect(gettersEn.length, 58);

      for (final val in gettersAr) {
        expect(val.trim().isNotEmpty, isTrue);
      }
      for (final val in gettersEn) {
        expect(val.trim().isNotEmpty, isTrue);
      }
    });

    test('Task A: Arabic strings must NOT contain Latin characters or bilingual slashes', () {
      final latinPattern = RegExp(r'[a-zA-Z]');
      final gettersAr = [
        ar.freightDataConnectorDialogTitle,
        ar.freightDataConnectorDialogSubtitle,
        ar.freightDataTabOverview,
        ar.freightDataTabSimulator,
        ar.freightDataTabPortTariffs,
        ar.freightDataShaqFreightSection,
        ar.freightDataShaqFreightDesc,
        ar.freightDataShippingRatesSection,
        ar.freightDataShippingRatesDesc,
        ar.freightDataPortDecreesSection,
        ar.freightDataPortDecreesDesc,
        ar.freightDataStatusActive,
        ar.freightDataMonthlyQuota,
        ar.freightDataQuotaUsed,
        ar.freightDataQuotaRemaining,
        ar.freightDataSyncSfxNow,
        ar.freightDataSyncSfxSuccess,
        ar.freightDataRefreshStatus,
        ar.freightDataTrackedRoutesCount,
        ar.freightDataTrackedLinesCount,
        ar.freightDataActiveDecreesCount,
        ar.freightDataLastSyncDate,
        ar.freightDataNeverSynced,
        ar.freightDataSimShippingLine,
        ar.freightDataSimPortAuthority,
        ar.freightDataSimContainerType,
        ar.freightDataSimDischargeDate,
        ar.freightDataSimClearanceDate,
        ar.freightDataSimDaysInPort,
        ar.freightDataSimFxRate,
        ar.freightDataSimCalculateBtn,
        ar.freightDataCarrierDetentionTitle,
        ar.freightDataPortStorageTitle,
        ar.freightDataAppliedDecree,
        ar.freightDataFreeDaysLabel,
        ar.freightDataChargeableDaysLabel,
        ar.freightDataConsolidatedSummary,
        ar.freightDataTotalDetentionUsd,
        ar.freightDataTotalStorageEgp,
        ar.freightDataConsolidatedEgp,
        ar.freightDataConsolidatedUsd,
        ar.freightDataCopySimulationDossier,
        ar.freightDataSimulationDossierCopied,
        ar.freightDataAddTariffDecreeBtn,
        ar.freightDataTariffVersionCol,
        ar.freightDataEffectiveFromCol,
        ar.freightDataEffectiveToCol,
        ar.freightDataActiveOngoing,
        ar.freightDataSourceDocCol,
        ar.freightDataRateSlabsSummary,
        ar.freightDataCopySlabRateTooltip,
        ar.freightDataLaunchConnectorTooltip,
        ar.freightDataQuotaGuardAlert,
        ar.freightDataDayUnit,
        ar.freightDataPerDayUnit,
        ar.freightDataCopyStatusSummary,
        ar.freightDataTotalLabel,
        ar.freightDataNoDecreesFound,
      ];

      for (final s in gettersAr) {
        expect(latinPattern.hasMatch(s), isFalse, reason: 'Found Latin characters in: $s');
        expect(s.contains('/'), isFalse, reason: 'Found bilingual slash in: $s');
      }
    });

    testWidgets('FreightDataMonitorDialog mounts and displays tabs in Arabic', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testDio = _createTestDio();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(testDio),
          ],
          child: const MaterialApp(
            home: AppLocalizationsProvider(
              locale: Locale('ar'),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: FreightDataMonitorDialog(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title is rendered
      expect(find.text(ar.freightDataConnectorDialogTitle), findsOneWidget);
      // Verify Tab items are rendered
      expect(find.text(ar.freightDataTabOverview), findsOneWidget);
      expect(find.text(ar.freightDataTabSimulator), findsOneWidget);
      expect(find.text(ar.freightDataTabPortTariffs), findsOneWidget);

      // Verify SelectionArea exists for Desktop copy
      expect(find.byType(SelectionArea), findsWidgets);
    });

    testWidgets('FreightDataMonitorDialog mounts and displays tabs in English', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testDio = _createTestDio();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(testDio),
          ],
          child: const MaterialApp(
            home: AppLocalizationsProvider(
              locale: Locale('en'),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Scaffold(
                  body: FreightDataMonitorDialog(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title is rendered in English
      expect(find.text(en.freightDataConnectorDialogTitle), findsOneWidget);
      expect(find.text(en.freightDataTabOverview), findsOneWidget);
      expect(find.text(en.freightDataTabSimulator), findsOneWidget);
      expect(find.text(en.freightDataTabPortTariffs), findsOneWidget);
    });
  });
}
