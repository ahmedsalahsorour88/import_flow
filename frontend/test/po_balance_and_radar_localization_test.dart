import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/demurrage_detention/models/demurrage_model.dart';
import 'package:frontend/features/demurrage_detention/providers/demurrage_provider.dart';
import 'package:frontend/features/operational_dashboard/widgets/container_demurrage_radar_card.dart';
import 'package:frontend/features/purchase_orders/widgets/po_balance_ledger_dialog.dart';

class _MockHttpAdapter implements HttpClientAdapter {
  static final _mockBody = jsonEncode({
    'total_ordered_quantity': 500.0,
    'total_shipped_quantity': 250.0,
    'total_remaining_quantity': 250.0,
    'total_ordered_fob_usd': 50000.0,
    'total_shipped_fob_usd': 25000.0,
    'total_remaining_fob_usd': 25000.0,
    'fulfillment_percentage': 50.0,
    'is_fully_shipped': false,
    'line_items': [
      {
        'item_code': 'ITM-001',
        'description': 'Item 1 description',
        'ordered_quantity': 300.0,
        'shipped_quantity': 150.0,
        'remaining_quantity': 150.0,
        'is_fully_shipped': false,
      },
    ],
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      _mockBody,
      200,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('PO Balance Ledger & Demurrage Radar Localization Direct Tests', () {
    late AppLocalizations ar;
    late AppLocalizations en;

    setUp(() {
      ar = const AppLocalizationsAr();
      en = const AppLocalizationsEn();
    });

    test('PO Balance Ledger getters return valid text in Arabic and English', () {
      expect(ar.poBalanceLedgerTitle, contains('ميزان أمر الشراء'));
      expect(en.poBalanceLedgerTitle, contains('PO Balance'));

      expect(ar.poBalanceSubTitle('PO-01', '50.0'), contains('PO-01'));
      expect(en.poBalanceSubTitle('PO-01', '50.0'), contains('PO-01'));

      expect(ar.poBalanceFullyShipped, contains('100%'));
      expect(en.poBalanceFullyShipped, contains('100%'));

      expect(ar.poBalancePartialInProgress, isNotEmpty);
      expect(en.poBalancePartialInProgress, isNotEmpty);

      expect(ar.poBalanceTotalOrderedQty, isNotEmpty);
      expect(en.poBalanceTotalOrderedQty, isNotEmpty);

      expect(ar.poBalanceActuallyShippedQty, isNotEmpty);
      expect(en.poBalanceActuallyShippedQty, isNotEmpty);

      expect(ar.poBalanceRemainingQty, isNotEmpty);
      expect(en.poBalanceRemainingQty, isNotEmpty);

      expect(ar.poBalanceUnit, isNotEmpty);
      expect(en.poBalanceUnit, isNotEmpty);

      expect(ar.poBalanceValue('\$100'), contains('\$100'));
      expect(en.poBalanceValue('\$100'), contains('\$100'));

      expect(ar.poBalanceLineItemsTitle, isNotEmpty);
      expect(en.poBalanceLineItemsTitle, isNotEmpty);

      expect(ar.poBalanceColItemCode, isNotEmpty);
      expect(en.poBalanceColItemCode, isNotEmpty);

      expect(ar.poBalanceColDescription, isNotEmpty);
      expect(en.poBalanceColDescription, isNotEmpty);

      expect(ar.poBalanceColOrderedQty, isNotEmpty);
      expect(en.poBalanceColOrderedQty, isNotEmpty);

      expect(ar.poBalanceColShippedQty, isNotEmpty);
      expect(en.poBalanceColShippedQty, isNotEmpty);

      expect(ar.poBalanceColRemaining, isNotEmpty);
      expect(en.poBalanceColRemaining, isNotEmpty);

      expect(ar.poBalanceColStatus, isNotEmpty);
      expect(en.poBalanceColStatus, isNotEmpty);

      expect(ar.poBalanceStatusCompleted, contains('✅'));
      expect(en.poBalanceStatusCompleted, contains('✅'));

      expect(ar.poBalanceStatusPartial, contains('⏳'));
      expect(en.poBalanceStatusPartial, contains('⏳'));

      expect(ar.poBalanceLoading, isNotEmpty);
      expect(en.poBalanceLoading, isNotEmpty);

      expect(ar.poBalanceLoadError('net err'), contains('net err'));
      expect(en.poBalanceLoadError('net err'), contains('net err'));
    });

    test('Demurrage Radar getters return valid text in Arabic and English', () {
      expect(ar.demurrageRadarCardTitle, contains('TR-02'));
      expect(en.demurrageRadarCardTitle, contains('TR-02'));

      expect(ar.demurrageRadarCardSubtitle, isNotEmpty);
      expect(en.demurrageRadarCardSubtitle, isNotEmpty);

      expect(ar.demurrageRadarRefreshTooltip, isNotEmpty);
      expect(en.demurrageRadarRefreshTooltip, isNotEmpty);

      expect(ar.demurrageRadarOpenScreenBtn, isNotEmpty);
      expect(en.demurrageRadarOpenScreenBtn, isNotEmpty);

      expect(ar.demurrageRadarSafeBadge, isNotEmpty);
      expect(en.demurrageRadarSafeBadge, isNotEmpty);

      expect(ar.demurrageRadarWarningBadge, isNotEmpty);
      expect(en.demurrageRadarWarningBadge, isNotEmpty);

      expect(ar.demurrageRadarActiveFinesBadge, isNotEmpty);
      expect(en.demurrageRadarActiveFinesBadge, isNotEmpty);

      expect(ar.demurrageRadarReturnedBadge, isNotEmpty);
      expect(en.demurrageRadarReturnedBadge, isNotEmpty);

      expect(ar.demurrageRadarExposureBanner('10', '200', '300'), contains('10'));
      expect(en.demurrageRadarExposureBanner('10', '200', '300'), contains('10'));

      expect(ar.demurrageRadarEmptyState, isNotEmpty);
      expect(en.demurrageRadarEmptyState, isNotEmpty);

      expect(ar.demurrageRadarCarrierFreeDays, isNotEmpty);
      expect(en.demurrageRadarCarrierFreeDays, isNotEmpty);

      expect(ar.demurrageRadarDaysCount(5, 14), contains('5'));
      expect(en.demurrageRadarDaysCount(5, 14), contains('5'));

      expect(ar.demurrageRadarStatusSafe, isNotEmpty);
      expect(en.demurrageRadarStatusSafe, isNotEmpty);

      expect(ar.demurrageRadarStatusWarning, isNotEmpty);
      expect(en.demurrageRadarStatusWarning, isNotEmpty);

      expect(ar.demurrageRadarStatusCritical, isNotEmpty);
      expect(en.demurrageRadarStatusCritical, isNotEmpty);

      expect(ar.demurrageRadarStatusReturned, isNotEmpty);
      expect(en.demurrageRadarStatusReturned, isNotEmpty);

      expect(ar.demurrageRadarButtonLabel, contains('TR-02'));
      expect(en.demurrageRadarButtonLabel, contains('TR-02'));
    });
  });

  group('PO Balance Ledger Dialog Multilingual Rendering Tests', () {
    testWidgets('Renders Arabic text when locale is ar', (tester) async {
      final mockDio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'));
      mockDio.httpClientAdapter = _MockHttpAdapter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dioProvider.overrideWithValue(mockDio)],
          child: const AppLocalizationsProvider(
            locale: Locale('ar'),
            child: MaterialApp(
              home: Scaffold(
                body: POBalanceLedgerDialog(poId: 1, poCode: 'PO-2026-001'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('ميزان أمر الشراء'), findsOneWidget);
      expect(find.textContaining('الكميات المشحونة فعلياً'), findsOneWidget);
      expect(find.textContaining('الرصيد المتبقي للتوريد'), findsOneWidget);
      expect(find.textContaining('كود البند'), findsOneWidget);
    });

    testWidgets('Renders English text when locale is en', (tester) async {
      final mockDio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'));
      mockDio.httpClientAdapter = _MockHttpAdapter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dioProvider.overrideWithValue(mockDio)],
          child: const AppLocalizationsProvider(
            locale: Locale('en'),
            child: MaterialApp(
              home: Scaffold(
                body: POBalanceLedgerDialog(poId: 1, poCode: 'PO-2026-001'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('PO Balance & Partial Shipments Ledger'), findsOneWidget);
      expect(find.textContaining('Actually Shipped Quantity'), findsOneWidget);
      expect(find.textContaining('Remaining Balance for Delivery'), findsOneWidget);
      expect(find.textContaining('Item Code'), findsOneWidget);
    });
  });

  group('Container Demurrage Radar Card Multilingual Rendering Tests', () {
    final sampleRadar = ContainerRadarOverviewModel(
      totalContainersTracked: 1,
      safeContainersCount: 1,
      warningContainersCount: 0,
      criticalOverdueCount: 0,
      returnedContainersCount: 0,
      totalAccruedDemurrageUsd: 0.0,
      totalAccruedStorageEgp: 0.0,
      totalEstimatedExposureEgp: 0.0,
      generatedAt: '2026-09-19T00:00:00Z',
      radarItems: [
        ContainerRadarItemModel(
          trackingId: 1,
          importFileId: 10,
          importFileCode: 'IMP-2026-001',
          billOfLadingNo: 'BL-9988',
          carrierName: 'Maersk',
          containerNumber: 'MSKU1234567',
          containerType: '40ft High Cube',
          dischargeDate: '2026-09-01',
          radarStatus: 'SAFE',
          colorCode: '#27AE60',
          statusLabelAr: 'آمن - داخل فترة السماح',
          demurrageDaysConsumed: 5,
          demurrageFreeDays: 14,
          demurrageDaysRemaining: 9,
          storageDaysConsumed: 3,
          storageFreeDays: 5,
          storageDaysRemaining: 2,
          accruedDemurrageUsd: 0.0,
          accruedStorageEgp: 0.0,
          totalAccruedEgp: 0.0,
          alertMessageAr: 'الحاوية داخل فترة السماح',
        ),
      ],
    );

    testWidgets('Renders Arabic text when locale is ar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            containerRadarOverviewProvider.overrideWith((ref) async => sampleRadar),
          ],
          child: const AppLocalizationsProvider(
            locale: Locale('ar'),
            child: MaterialApp(
              home: Scaffold(
                body: ContainerDemurrageRadarCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('رادار مراقبة فترات السماح وتفادي غرامات الحاويات'), findsOneWidget);
      expect(find.textContaining('آمن داخل السماح'), findsOneWidget);
      expect(find.textContaining('فتح شاشة الغرامات'), findsOneWidget);
      expect(find.textContaining('سماح الخط الملاحي:'), findsOneWidget);
      expect(find.textContaining('آمن - داخل فترة السماح'), findsOneWidget);
    });

    testWidgets('Renders English text when locale is en', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            containerRadarOverviewProvider.overrideWith((ref) async => sampleRadar),
          ],
          child: const AppLocalizationsProvider(
            locale: Locale('en'),
            child: MaterialApp(
              home: Scaffold(
                body: ContainerDemurrageRadarCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Container Demurrage & Free Days Radar (TR-02)'), findsOneWidget);
      expect(find.textContaining('Safe in Free Time'), findsOneWidget);
      expect(find.textContaining('Open Demurrage Screen'), findsOneWidget);
      expect(find.textContaining('Line Free Days:'), findsOneWidget);
      expect(find.text('Safe'), findsOneWidget);
    });
  });
}
