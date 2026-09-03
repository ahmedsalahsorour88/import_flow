import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/import_documentation/widgets/smart_invoice_bl_extractor_dialog.dart';

void main() {
  testWidgets('SmartInvoiceBLExtractorDialog renders tabs and handles navigation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SmartInvoiceBLExtractorDialog(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Tabs
    expect(find.text('استخلاص الفواتير وبوالص الشحن بالذكاء الاصطناعي (AI-INV-010)'), findsOneWidget);
    expect(find.text('الفاتورة التجارية (Invoice)'), findsOneWidget);
    expect(find.text('بوليصة الشحن (B/L & AWB)'), findsOneWidget);
    expect(find.text('رادار المطابقة (10-Point Audit)'), findsOneWidget);

    // Verify Tab 1 content
    expect(find.text('1. إدخال أو رفع الفاتورة التجارية (Commercial Invoice)'), findsOneWidget);
    expect(find.text('استخلاص الفاتورة بالذكاء الاصطناعي'), findsOneWidget);

    // Navigate to Tab 2 (B/L & AWB)
    await tester.tap(find.text('بوليصة الشحن (B/L & AWB)'));
    await tester.pumpAndSettle();

    expect(find.text('2. إدخال أو رفع بوليصة الشحن (Bill of Lading / Air Waybill)'), findsOneWidget);
    expect(find.text('استخلاص بوليصة الشحن والحاويات'), findsOneWidget);

    // Navigate to Tab 3 (Cross-Audit Radar)
    await tester.tap(find.text('رادار المطابقة (10-Point Audit)'));
    await tester.pumpAndSettle();

    expect(find.text('رادار التدقيق الجمركي المتقاطع (10-Point Pre-Clearance Audit)'), findsOneWidget);
    expect(find.text('تشغيل الفحص الآن'), findsOneWidget);
  });
}
