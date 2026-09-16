import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/widgets/enterprise_multi_pane_layout.dart';

void main() {
  group('EnterpriseMultiPaneLayout Tests', () {
    Widget buildTestApp({
      Widget? detailPane,
      String? masterTitle,
      String? detailTitle,
      Locale locale = const Locale('ar'),
    }) {
      return MaterialApp(
        home: AppLocalizationsProvider(
          locale: locale,
          child: Directionality(
            textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              body: EnterpriseMultiPaneLayout(
                masterTitle: masterTitle ?? 'قائمة الشحنات',
                detailTitle: detailTitle,
                masterPane: const Center(child: Text('عناصر القائمة الجانبية')),
                detailPane: detailPane,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Wide desktop renders dual panes with master and empty detail placeholder', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('قائمة الشحنات'), findsOneWidget);
      expect(find.text('عناصر القائمة الجانبية'), findsOneWidget);
      expect(find.text('لوحة التفاصيل المعمقة'), findsOneWidget);
      expect(find.text('حدد عنصرا من القائمة الجانبية لمعاينة التفاصيل الكاملة والوثائق المرتبطة'), findsOneWidget);
    });

    testWidgets('Wide desktop renders master and active detail pane simultaneously', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          detailPane: const Center(child: Text('تفاصيل الشحنة رقم 104')),
          detailTitle: 'ملف الشحنة IMP-2026-0004',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('عناصر القائمة الجانبية'), findsOneWidget);
      expect(find.text('تفاصيل الشحنة رقم 104'), findsOneWidget);
      expect(find.text('ملف الشحنة IMP-2026-0004'), findsOneWidget);
    });

    testWidgets('Collapsing and expanding master sidebar toggles visibility', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          detailPane: const Center(child: Text('تفاصيل الشحنة')),
        ),
      );
      await tester.pumpAndSettle();

      // Find collapse button in master header
      final collapseBtn = find.byTooltip('طي القائمة الجانبية');
      expect(collapseBtn, findsOneWidget);
      await tester.tap(collapseBtn);
      await tester.pumpAndSettle();

      // Master pane should be hidden
      expect(find.text('عناصر القائمة الجانبية'), findsNothing);

      // Expand button should now be available in detail header / splitter
      final expandBtn = find.byTooltip('إظهار القائمة الجانبية');
      expect(expandBtn, findsWidgets);
      await tester.tap(expandBtn.first);
      await tester.pumpAndSettle();

      // Master pane should be visible again
      expect(find.text('عناصر القائمة الجانبية'), findsOneWidget);
    });

    testWidgets('Narrow screen collapses to single pane and provides back button', (tester) async {
      tester.view.physicalSize = const Size(700, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool backed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AppLocalizationsProvider(
            locale: const Locale('ar'),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: EnterpriseMultiPaneLayout(
                  masterPane: const Center(child: Text('عناصر القائمة')),
                  detailPane: const Center(child: Text('معاينة التفاصيل')),
                  onBackToMaster: () => backed = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Because detailPane is provided on narrow screen, it displays detail + back button
      expect(find.text('معاينة التفاصيل'), findsOneWidget);
      expect(find.text('العودة إلى القائمة'), findsOneWidget);

      await tester.tap(find.text('العودة إلى القائمة'));
      expect(backed, isTrue);
    });
  });
}
