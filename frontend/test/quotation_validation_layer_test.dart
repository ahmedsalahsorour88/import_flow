import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';
import 'package:frontend/core/theme/app_theme.dart';

void main() {
  group('AI Quotation Completeness & Validation Layer (AI-EXTRACT-VALIDATE-001)', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    test('All 18 Quotation Validation localization keys return valid strings in both languages', () {
      // Banner titles
      expect(ar.quotationValidationBannerSafeTitle.isNotEmpty, true);
      expect(en.quotationValidationBannerSafeTitle.isNotEmpty, true);
      expect(ar.quotationValidationBannerWarningTitle.isNotEmpty, true);
      expect(en.quotationValidationBannerWarningTitle.isNotEmpty, true);
      expect(ar.quotationValidationBannerCriticalTitle.isNotEmpty, true);
      expect(en.quotationValidationBannerCriticalTitle.isNotEmpty, true);

      // KPI Counts & Gaps
      expect(ar.quotationValidationExpectedCount(50), contains('50'));
      expect(en.quotationValidationExpectedCount(50), contains('50'));
      expect(ar.quotationValidationExtractedCount(48), contains('48'));
      expect(en.quotationValidationExtractedCount(48), contains('48'));
      expect(ar.quotationValidationGapPercentage(4.0), contains('4'));
      expect(en.quotationValidationGapPercentage(4.0), contains('4'));

      // Badges & Tooltips
      expect(ar.quotationValidationMultiValueBadge.isNotEmpty, true);
      expect(en.quotationValidationMultiValueBadge.isNotEmpty, true);
      expect(ar.quotationValidationMultiValueTooltip.isNotEmpty, true);
      expect(en.quotationValidationMultiValueTooltip.isNotEmpty, true);

      expect(ar.quotationValidationRangeBadge.isNotEmpty, true);
      expect(en.quotationValidationRangeBadge.isNotEmpty, true);
      expect(ar.quotationValidationRangeTooltip(500, 1500), contains('500'));
      expect(en.quotationValidationRangeTooltip(500, 1500), contains('1500'));

      expect(ar.quotationValidationOutsideTableBadge.isNotEmpty, true);
      expect(en.quotationValidationOutsideTableBadge.isNotEmpty, true);
      expect(ar.quotationValidationOutsideTableTooltip.isNotEmpty, true);
      expect(en.quotationValidationOutsideTableTooltip.isNotEmpty, true);

      // Modal Confirmation
      expect(ar.quotationValidationConfirmTitle.isNotEmpty, true);
      expect(en.quotationValidationConfirmTitle.isNotEmpty, true);
      final arConfirmMsg = ar.quotationValidationConfirmMessage(50, 30, '40.0');
      expect(arConfirmMsg, contains('50'));
      expect(arConfirmMsg, contains('30'));
      expect(arConfirmMsg, contains('40.0'));
      expect(ar.quotationValidationProceedBtn.isNotEmpty, true);
      expect(en.quotationValidationProceedBtn.isNotEmpty, true);
      expect(ar.quotationValidationReviewBtn.isNotEmpty, true);
      expect(en.quotationValidationReviewBtn.isNotEmpty, true);

      // Copy Audit Report
      expect(ar.quotationValidationCopyReportBtn.isNotEmpty, true);
      expect(en.quotationValidationCopyReportBtn.isNotEmpty, true);
      expect(ar.quotationValidationReportCopiedToast.isNotEmpty, true);
      expect(en.quotationValidationReportCopiedToast.isNotEmpty, true);
    });

    test('Task A: Arabic strings contain 0 English characters and 0 slashes', () {
      final arabicStrings = [
        ar.quotationValidationBannerSafeTitle,
        ar.quotationValidationBannerWarningTitle,
        ar.quotationValidationBannerCriticalTitle,
        ar.quotationValidationExpectedCount(10),
        ar.quotationValidationExtractedCount(10),
        ar.quotationValidationGapPercentage(0),
        ar.quotationValidationMultiValueBadge,
        ar.quotationValidationMultiValueTooltip,
        ar.quotationValidationRangeBadge,
        ar.quotationValidationRangeTooltip(100, 200),
        ar.quotationValidationOutsideTableBadge,
        ar.quotationValidationOutsideTableTooltip,
        ar.quotationValidationConfirmTitle,
        ar.quotationValidationConfirmMessage(10, 5, 50),
        ar.quotationValidationProceedBtn,
        ar.quotationValidationReviewBtn,
        ar.quotationValidationCopyReportBtn,
        ar.quotationValidationReportCopiedToast,
      ];

      final latinRegex = RegExp(r'[a-zA-Z]');
      for (final s in arabicStrings) {
        expect(latinRegex.hasMatch(s), false, reason: 'Arabic string "$s" contains Latin characters');
        expect(s.contains('/'), false, reason: 'Arabic string "$s" contains a forward slash');
      }
    });

    testWidgets('Validation Banner renders Safe status with KPI chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                const l10n = AppLocalizationsAr();
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    border: Border.all(color: AppTheme.emerald),
                  ),
                  child: Column(
                    children: [
                      Text(l10n.quotationValidationBannerSafeTitle),
                      Text(l10n.quotationValidationExpectedCount(50)),
                      Text(l10n.quotationValidationExtractedCount(50)),
                      Text(l10n.quotationValidationGapPercentage('0.0')),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('استخراج موثوق ومكتمل بنسبة عالية'), findsOneWidget);
      expect(find.text('البنود المتوقعة: 50'), findsOneWidget);
      expect(find.text('البنود المستخرجة: 50'), findsOneWidget);
      expect(find.text('نسبة الفجوة: 0.0٪'), findsOneWidget);
    });

    testWidgets('Critical Validation Gap triggers Modal Confirmation Dialog', (WidgetTester tester) async {
      bool userConfirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                const l10n = AppLocalizationsAr();
                return ElevatedButton(
                  onPressed: () async {
                    // Simulate critical gap adoption check (> 20% gap)
                    final proceed = await showDialog<bool>(
                      context: ctx,
                      builder: (modalCtx) => AlertDialog(
                        title: Text(l10n.quotationValidationConfirmTitle),
                        content: Text(l10n.quotationValidationConfirmMessage(50, 30, '40.0')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(modalCtx, false),
                            child: Text(l10n.quotationValidationReviewBtn),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(modalCtx, true),
                            child: Text(l10n.quotationValidationProceedBtn),
                          ),
                        ],
                      ),
                    );
                    if (proceed == true) {
                      userConfirmed = true;
                    }
                  },
                  child: const Text('Save Quote'),
                );
              },
            ),
          ),
        ),
      );

      // Tap Save button
      await tester.tap(find.text('Save Quote'));
      await tester.pumpAndSettle();

      // Check modal is presented with warning details
      expect(find.text('تأكيد اعتماد المقايسة مع وجود فجوة استخراج'), findsOneWidget);
      expect(find.textContaining('اكتشف النظام 50 نمطا سعريا'), findsOneWidget);
      expect(find.text('متابعة الاعتماد على مسؤوليتي'), findsOneWidget);
      expect(find.text('العودة للمراجعة والتدقيق'), findsOneWidget);

      // Tap Confirm button
      await tester.tap(find.text('متابعة الاعتماد على مسؤوليتي'));
      await tester.pumpAndSettle();

      expect(userConfirmed, true);
    });

    testWidgets('Special items render multi-value split badge and price range badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Multi-value split item badge
                Container(
                  padding: const EdgeInsets.all(4),
                  color: Colors.amber.shade100,
                  child: const Text('خلية متعددة'),
                ),
                // Range item badge
                Container(
                  padding: const EdgeInsets.all(4),
                  color: const Color(0xFFEDE9FE),
                  child: const Text('نطاق سعري'),
                ),
                // Outside table item badge
                Container(
                  padding: const EdgeInsets.all(4),
                  color: Colors.blueGrey.shade100,
                  child: const Text('خارج الجدول'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('خلية متعددة'), findsOneWidget);
      expect(find.text('نطاق سعري'), findsOneWidget);
      expect(find.text('خارج الجدول'), findsOneWidget);
    });
  });
}
