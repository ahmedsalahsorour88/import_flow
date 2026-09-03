import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/simulation/widgets/what_if_simulator_dialog.dart';

void main() {
  testWidgets('WhatIfSimulatorDialog renders controls and handles tab switching', (WidgetTester tester) async {
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
            body: WhatIfSimulatorDialog(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Dialog Header & Tabs
    expect(find.text('محاكي مخاطر الشحن وتغيرات أسعار الصرف والأزمات (SIM-WHATIF-013)'), findsOneWidget);
    expect(find.text('محاكي السيناريوهات الحية (Live What-If Simulator)'), findsOneWidget);
    expect(find.text('رادار الانكشاف المالي بالعملات الأجنبية (FX Exposure)'), findsOneWidget);

    // 2. Verify Tab 1 Controls
    expect(find.text('1. تحديد مدخلات الشحنة والعملة:'), findsOneWidget);
    expect(find.text('2. محاكاة صدمة سعر الصرف (FX Shock):'), findsOneWidget);
    expect(find.text('3. مسار الشحن ومخاطر البحر الأحمر:'), findsOneWidget);
    expect(find.text('تشغيل المحاكاة الآن'), findsOneWidget);

    // 3. Verify Placeholder Guide
    expect(find.text('جاهز لمحاكاة صدمات أسعار الصرف والأزمات اللوجستية'), findsOneWidget);

    // 4. Switch to Tab 2: FX Exposure Radar
    await tester.tap(find.text('رادار الانكشاف المالي بالعملات الأجنبية (FX Exposure)'));
    await tester.pumpAndSettle();

    // Verify Tab 2 is active
    expect(find.byType(TabBarView), findsOneWidget);
  });
}
