import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/freight_quotations/widgets/freight_quotations_extractor_dialog.dart';

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
        MaterialApp(
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
      );

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify title and tabs
      expect(find.text('استخراج عروض أسعار الشحن الذكي (Text & OCR)'), findsOneWidget);
      expect(find.text('📝 لصق نص / بريد إلكتروني'), findsOneWidget);
      expect(find.text('📁 رفع ملف / مستند / صورة (OCR)'), findsOneWidget);

      // Tap sample text button
      expect(find.text('📋 تحميل نص تجريبي'), findsOneWidget);
      await tester.tap(find.text('📋 تحميل نص تجريبي'));
      await tester.pumpAndSettle();

      // Verify text field contains sample quote text
      expect(find.textContaining('WHL: USD 6,700/40HQ'), findsOneWidget);

      // Switch to OCR tab
      await tester.tap(find.text('📁 رفع ملف / مستند / صورة (OCR)'));
      await tester.pumpAndSettle();

      // Verify OCR drag and drop text
      expect(find.textContaining('لاختيار ملف عرض السعر'), findsOneWidget);
    });
  });
}
