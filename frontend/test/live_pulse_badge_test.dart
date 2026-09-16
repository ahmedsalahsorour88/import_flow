import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/live_pulse_badge.dart';

void main() {
  group('LivePulseBadge Unit & Widget Tests', () {
    testWidgets('LivePulseBadge renders custom label, icon, and handles tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LivePulseBadge(
                label: 'شحنة قيد الفحص',
                icon: Icons.shield_outlined,
                color: AppTheme.cobalt,
                tooltip: 'فحص الحاوية',
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('شحنة قيد الفحص'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);

      await tester.tap(find.byType(LivePulseBadge));
      expect(tapped, isTrue);
    });

    testWidgets('LivePulseBadge.acid correctly applies Egyptian Customs BP-014 rules', (tester) async {
      // 1. Customs Released -> Emerald, non-pulsing
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LivePulseBadge.acid(
              daysRemaining: 5,
              isCustomsReleased: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مُفرج جمركياً'), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);

      // 2. Expired (days <= 0) -> Crimson, Pulsing
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LivePulseBadge.acid(
              daysRemaining: 0,
              isCustomsReleased: false,
            ),
          ),
        ),
      );
      await tester.pump(); // don't pumpAndSettle due to repeating animation controller

      expect(find.text('منتهي الصلاحية'), findsOneWidget);

      // 3. Expiring Soon (1 <= days <= 14) -> Crimson warning, Pulsing
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LivePulseBadge.acid(
              daysRemaining: 8,
              isCustomsReleased: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('يوشك على الانتهاء (8 يوم)'), findsOneWidget);

      // 4. Valid (days > 14) -> Emerald, non-pulsing
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LivePulseBadge.acid(
              daysRemaining: 60,
              isCustomsReleased: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ساري (60 يوم)'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('LivePulseBadge.demurrage correctly flags incurred and critical free days', (tester) async {
      // 1. Incurred demurrage -> Orange pulse
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LivePulseBadge.demurrage(
              status: 'Demurrage Incurred',
              accruedPenaltyEgp: 14500,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('غرامات: 14500 ج.م'), findsOneWidget);

      // 2. Critical free time remaining (<= 3 days) -> Orange warning pulse
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LivePulseBadge.demurrage(
              status: 'Free Time Active',
              freeDaysRemaining: 2,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('مهلة سماح حرجة (2 أيام)'), findsOneWidget);

      // 3. Normal free time -> Emerald stable
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LivePulseBadge.demurrage(
              status: 'Free Time Active',
              freeDaysRemaining: 12,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('فترة سماح سارية'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });
  });
}
