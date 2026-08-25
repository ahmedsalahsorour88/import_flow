import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:frontend/features/freight_quotations/widgets/freight_quotations_extractor_dialog.dart';
import 'package:frontend/features/external_service_providers/providers/partners_provider.dart';
import 'package:frontend/features/transport_locations/providers/transport_locations_provider.dart';

class MockAllPartnersNotifier extends AllPartnersNotifier {
  MockAllPartnersNotifier() : super(dio: Dio()) {
    state = const AsyncValue.data([]);
  }
  @override
  Future<void> fetchPartners() async {
    state = const AsyncValue.data([]);
  }
}

class MockTransportLocationsNotifier extends TransportLocationsNotifier {
  MockTransportLocationsNotifier() : super(Dio()) {
    state = const AsyncValue.data([]);
  }
  @override
  Future<void> fetchLocations({bool includeInactive = true, String? locationType, String? search}) async {
    state = const AsyncValue.data([]);
  }
}

void main() {
  group('Freight Quotations Extractor Model & Dialog Tests', () {
    test('ExtractedQuotationOption parses rate map correctly', () {
      final map = {
        'carrier_name': 'Wan Hai Lines (WHL)',
        'container_type': '40HQ',
        'ocean_freight': 6700.0,
        'local_charges': 880.0,
        'exw_charges': 0.0,
        'total_estimated_cost': 7580.0,
        'currency': 'USD',
        'incoterm': 'FOB',
        'origin_port': 'Shanghai',
        'destination_port': 'El Dekheila',
        'transit_days': 29,
        'is_direct': true,
        'free_time_days': 21,
        'notes': 'Includes OWS',
      };

      final option = ExtractedQuotationOption.fromMap(map, 1);

      expect(option.optionId, 1);
      expect(option.carrierName, 'Wan Hai Lines (WHL)');
      expect(option.containerType, '40HQ');
      expect(option.oceanFreight, 6700.0);
      expect(option.localCharges, 880.0);
      expect(option.totalEstimatedCost, 7580.0);
      expect(option.transitDays, 29);
      expect(option.isDirect, true);
      expect(option.freeTimeDays, 21);
      expect(option.isSelected, true);
    });

    testWidgets('FreightQuotationsExtractorDialog renders tabs and loads sample text', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allPartnersProvider.overrideWith((ref) => MockAllPartnersNotifier()),
            transportLocationsProvider.overrideWith((ref) => MockTransportLocationsNotifier()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    FreightQuotationsExtractorDialog.show(
                      context,
                      onAddQuotations: (_) {},
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify title and tabs
      expect(find.textContaining('نتائج الاستخراج — استخراج كامل'), findsOneWidget);
      expect(find.text('📝 لصق نص / بريد إلكتروني'), findsOneWidget);
      expect(find.text('📁 رفع ملف / مستند / صورة (OCR)'), findsOneWidget);

      // Tap sample text button
      expect(find.text('📋 تحميل نص تجريبي'), findsOneWidget);
      await tester.tap(find.text('📋 تحميل نص تجريبي'));
      await tester.pumpAndSettle();

      // Verify text field contains sample quote text
      expect(find.textContaining('USD6760/20GP'), findsOneWidget);

      // Switch to OCR tab
      await tester.tap(find.text('📁 رفع ملف / مستند / صورة (OCR)'));
      await tester.pumpAndSettle();

      // Verify OCR drag and drop text
      expect(find.textContaining('لاختيار ملف عرض السعر'), findsOneWidget);
    });

    test('ExtractedQuotationOption parses all 8 comprehensive shipment and voyage fields', () {
      final map = {
        'carrier_name': 'COSCO Shipping Lines',
        'forwarder_name': 'Kuehne + Nagel',
        'vessel_name': 'COSCO UNIVERSE',
        'voyage_number': '042E',
        'origin_port': 'Shanghai',
        'destination_port': 'Alexandria',
        'etd_date': '2026-08-28',
        'eta_date': '2026-09-26',
        'container_type': '40HQ',
        'ocean_freight': 6900.0,
        'local_charges': 800.0,
        'transit_days': 29,
        'is_direct': true,
        'free_time_days': 21,
      };

      final opt = ExtractedQuotationOption.fromMap(map, 1);
      expect(opt.carrierName, 'COSCO Shipping Lines');
      expect(opt.forwarderName, 'Kuehne + Nagel');
      expect(opt.vesselName, 'COSCO UNIVERSE');
      expect(opt.voyageNumber, '042E');
      expect(opt.originPort, 'Shanghai');
      expect(opt.destinationPort, 'Alexandria');
      expect(opt.etdDate, '2026-08-28');
      expect(opt.etaDate, '2026-09-26');
      expect(opt.transitDays, 29);
      expect(opt.freeTimeDays, 21);
    });

    test('ExtractedQuotationOption fallback parsing with ocean_freight and single rate', () {
      final singleRateMap = {
        'carrier_name': 'MSC',
        'container_type': '20GP',
        'ocean_freight': 3500.0,
        'local_charges': 400.0,
        'is_direct': false,
        'transit_days': 35,
      };

      final opt = ExtractedQuotationOption.fromMap(singleRateMap, 2);
      expect(opt.carrierName, 'MSC');
      expect(opt.containerType, '20GP');
      expect(opt.oceanFreight, 3500.0);
      expect(opt.totalEstimatedCost, 3900.0);
      expect(opt.isDirect, false);
      expect(opt.transitDays, 35);
    });
  });
}
