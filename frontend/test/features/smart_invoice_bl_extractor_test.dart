import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/import_documentation/widgets/smart_invoice_bl_extractor_dialog.dart';

void main() {
  testWidgets('SmartInvoiceBLExtractorDialog renders tabs and handles navigation in Arabic', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: AppLocalizationsProvider(
          locale: Locale('ar'),
          child: MaterialApp(
            home: Scaffold(
              body: SmartInvoiceBLExtractorDialog(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Tabs in Arabic
    expect(find.text('استخلاص الفواتير وبوالص الشحن بالذكاء الاصطناعي'), findsOneWidget);
    expect(find.text('الفاتورة التجارية'), findsOneWidget);
    expect(find.text('بوليصة الشحن'), findsOneWidget);
    expect(find.text('رادار المطابقة الجمركية'), findsOneWidget);

    // Verify Tab 1 content
    expect(find.text('1. إدخال أو رفع الفاتورة التجارية'), findsOneWidget);
    expect(find.text('استخلاص الفاتورة بالذكاء الاصطناعي'), findsOneWidget);

    // Navigate to Tab 2 (B/L)
    await tester.tap(find.text('بوليصة الشحن'));
    await tester.pumpAndSettle();

    expect(find.text('2. إدخال أو رفع بوليصة الشحن'), findsOneWidget);
    expect(find.text('استخلاص بوليصة الشحن والحاويات'), findsOneWidget);

    // Navigate to Tab 3 (Cross-Audit Radar)
    await tester.tap(find.text('رادار المطابقة الجمركية'));
    await tester.pumpAndSettle();

    expect(find.text('رادار التدقيق الجمركي المتقاطع'), findsOneWidget);
    expect(find.text('تشغيل الفحص الآن'), findsOneWidget);
  });

  testWidgets('SmartInvoiceBLExtractorDialog renders tabs in English without Arabic text', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: AppLocalizationsProvider(
          locale: Locale('en'),
          child: MaterialApp(
            home: Scaffold(
              body: SmartInvoiceBLExtractorDialog(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Tabs in English
    expect(find.text('AI Invoice & Bill of Lading Extractor'), findsOneWidget);
    expect(find.text('Commercial Invoice'), findsOneWidget);
    expect(find.text('Bill of Lading'), findsOneWidget);
    expect(find.text('Customs Audit Radar'), findsOneWidget);

    // Verify Tab 1 content
    expect(find.text('1. Enter or Upload Commercial Invoice'), findsOneWidget);
    expect(find.text('Extract Invoice with AI'), findsOneWidget);
  });
}
