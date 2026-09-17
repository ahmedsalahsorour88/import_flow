import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/density_provider.dart';
import 'package:frontend/core/widgets/dedicated_stage_scaffold.dart';

class FakeDensityNotifier extends DisplayDensityNotifier {
  FakeDensityNotifier(DisplayDensityMode initial) : super() {
    state = initial;
  }
}

void main() {
  Widget buildTestWidget({
    required DisplayDensityMode densityMode,
    double width = 1366,
    double height = 768,
  }) {
    return ProviderScope(
      overrides: [
        displayDensityProvider.overrideWith((ref) => FakeDensityNotifier(densityMode)),
      ],
      child: MaterialApp(
        home: SizedBox(
          width: width,
          height: height,
          child: DedicatedStageScaffold(
            stageCode: 'STEP_08_BL',
            titleAr: 'مراجعة مسودة بوليصة الشحن',
            titleEn: 'Bill of Lading Review',
            headerIcon: Icons.directions_boat,
            showStageLifecycleControls: false,
            headerActions: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.description, size: 16),
                label: const Text('Formal Letter'),
              ),
            ],
            body: const Center(child: Text('Main Stage Body Content')),
          ),
        ),
      ),
    );
  }

  group('DedicatedStageScaffold Density & Layout Tests', () {
    testWidgets('Renders all header elements and content correctly in Comfortable mode', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(densityMode: DisplayDensityMode.comfortable));
      await tester.pumpAndSettle();

      expect(find.text('Bill of Lading Review'), findsOneWidget);
      expect(find.text('STEP_08_BL'), findsOneWidget);
      expect(find.byIcon(Icons.directions_boat), findsOneWidget);
      expect(find.text('Formal Letter'), findsOneWidget);
      expect(find.text('Main Stage Body Content'), findsOneWidget);

      // Verify Icon size in Comfortable mode
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.directions_boat));
      expect(iconWidget.size, equals(DisplayDensityMode.comfortable.headerIconSize));

      // Verify Title font size in Comfortable mode
      final titleText = tester.widget<Text>(find.text('Bill of Lading Review'));
      expect(titleText.style?.fontSize, equals(DisplayDensityMode.comfortable.headerTitleFontSize));

      // Verify Stage badge font size adheres to 11px floor rule
      final badgeText = tester.widget<Text>(find.text('STEP_08_BL'));
      expect(badgeText.style?.fontSize, greaterThanOrEqualTo(11.0));
    });

    testWidgets('Scales header and icon down in Compact mode while keeping >= 11px', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(densityMode: DisplayDensityMode.compact));
      await tester.pumpAndSettle();

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.directions_boat));
      expect(iconWidget.size, equals(DisplayDensityMode.compact.headerIconSize));

      final titleText = tester.widget<Text>(find.text('Bill of Lading Review'));
      expect(titleText.style?.fontSize, equals(DisplayDensityMode.compact.headerTitleFontSize));

      final badgeText = tester.widget<Text>(find.text('STEP_08_BL'));
      expect(badgeText.style?.fontSize, greaterThanOrEqualTo(11.0));
    });

    testWidgets('Scales header and icon down in Ultra-Compact mode with strict 11px floor rule', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(densityMode: DisplayDensityMode.ultraCompact));
      await tester.pumpAndSettle();

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.directions_boat));
      expect(iconWidget.size, equals(DisplayDensityMode.ultraCompact.headerIconSize));

      final titleText = tester.widget<Text>(find.text('Bill of Lading Review'));
      expect(titleText.style?.fontSize, equals(DisplayDensityMode.ultraCompact.headerTitleFontSize));

      final badgeText = tester.widget<Text>(find.text('STEP_08_BL'));
      expect(badgeText.style?.fontSize, greaterThanOrEqualTo(11.0));
    });

    testWidgets('Includes bottom clearance buffer for floating widgets (+72px)', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(densityMode: DisplayDensityMode.comfortable));
      await tester.pumpAndSettle();

      // Find the Padding widget wrapping the body
      final paddings = tester.widgetList<Padding>(find.byType(Padding));
      bool foundBuffer = false;
      for (final p in paddings) {
        if (p.padding is EdgeInsets) {
          final insets = p.padding as EdgeInsets;
          if (insets.bottom >= 72.0) {
            foundBuffer = true;
            break;
          }
        }
      }
      expect(foundBuffer, isTrue, reason: 'Workspace body must have >= 72px bottom clearance buffer');
    });

    testWidgets('Renders without overflow on narrow screens (< 1000px)', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(
        densityMode: DisplayDensityMode.compact,
        width: 800,
        height: 600,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Bill of Lading Review'), findsOneWidget);
      expect(find.text('Formal Letter'), findsOneWidget);
    });
  });
}
