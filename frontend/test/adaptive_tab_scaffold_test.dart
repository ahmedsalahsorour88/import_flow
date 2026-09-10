import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/adaptive_tab_scaffold.dart';

void main() {
  Widget buildTestWidget({
    required double width,
    required double height,
    required List<AdaptiveTabItem> tabs,
    int selectedIndex = 0,
    ValueChanged<int>? onTabSelected,
    TabController? controller,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: AdaptiveTabScaffold(
              tabs: tabs,
              selectedIndex: selectedIndex,
              onTabSelected: onTabSelected,
              controller: controller,
            ),
          ),
        ),
      ),
    );
  }

  group('AdaptiveTabScaffold Responsive Transitions', () {
    final threeTabs = [
      const AdaptiveTabItem(
        icon: Icons.info_outline,
        label: 'Tab One',
        content: Center(child: Text('Content 1')),
      ),
      const AdaptiveTabItem(
        icon: Icons.settings,
        label: 'Tab Two',
        content: Center(child: Text('Content 2')),
      ),
      const AdaptiveTabItem(
        icon: Icons.history,
        label: 'Tab Three',
        content: Center(child: Text('Content 3')),
      ),
    ];

    final fiveTabs = [
      ...threeTabs,
      const AdaptiveTabItem(
        icon: Icons.analytics,
        label: 'Tab Four',
        content: Center(child: Text('Content 4')),
      ),
      const AdaptiveTabItem(
        icon: Icons.calculate,
        label: 'Tab Five',
        content: Center(child: Text('Content 5')),
      ),
    ];

    testWidgets('Renders horizontal layout when width is large (1200px) and tab count is <= 3', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(
        buildTestWidget(
          width: 1200,
          height: 800,
          tabs: threeTabs,
        ),
      );
      await tester.pumpAndSettle();

      // In horizontal layout, tabs are displayed in a Row with horizontal border styling
      expect(find.text('Tab One'), findsOneWidget);
      expect(find.text('Tab Two'), findsOneWidget);
      expect(find.text('Tab Three'), findsOneWidget);
      expect(find.text('Content 1'), findsOneWidget);
      // Not using Dropdown
      expect(find.byType(DropdownButton<int>), findsNothing);
      // Not using sidebar ListView
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('Switches to sidebar layout when width is constrained (<800px) even with 3 tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(750, 800));
      await tester.pumpWidget(
        buildTestWidget(
          width: 750,
          height: 800,
          tabs: threeTabs,
        ),
      );
      await tester.pumpAndSettle();

      // Sidebar uses ListView.separated
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Tab One'), findsOneWidget);
      expect(find.text('Content 1'), findsOneWidget);
      expect(find.byType(DropdownButton<int>), findsNothing);
    });

    testWidgets('Automatically prefers sidebar layout when tab count is >= 4, even at wide desktop (1400px)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      await tester.pumpWidget(
        buildTestWidget(
          width: 1400,
          height: 800,
          tabs: fiveTabs,
        ),
      );
      await tester.pumpAndSettle();

      // 5 tabs exceed tabCountThreshold (4) -> must trigger vertical sidebar to eliminate tab overcrowding
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Tab Four'), findsOneWidget);
      expect(find.text('Tab Five'), findsOneWidget);
      expect(find.text('Content 1'), findsOneWidget);
    });

    testWidgets('Switches to compact dropdown layout when screen is mobile width (<550px)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 700));
      await tester.pumpWidget(
        buildTestWidget(
          width: 450,
          height: 700,
          tabs: threeTabs,
        ),
      );
      await tester.pumpAndSettle();

      // In compact mobile mode, DropdownButton is rendered
      expect(find.byType(DropdownButton<int>), findsOneWidget);
      expect(find.text('Content 1'), findsOneWidget);
      // Sidebar ListView is not present
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('Active tab remains synchronized and selectable across transitions', (tester) async {
      int activeIndex = 0;
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(
        buildTestWidget(
          width: 1200,
          height: 800,
          tabs: threeTabs,
          onTabSelected: (idx) => activeIndex = idx,
        ),
      );
      await tester.pumpAndSettle();

      // Tap tab two
      await tester.tap(find.text('Tab Two'));
      await tester.pumpAndSettle();

      expect(activeIndex, 1);
      expect(find.text('Content 2'), findsOneWidget);

      // Now resize to sidebar layout (< 800px)
      await tester.pumpWidget(
        buildTestWidget(
          width: 700,
          height: 800,
          tabs: threeTabs,
          selectedIndex: activeIndex,
          onTabSelected: (idx) => activeIndex = idx,
        ),
      );
      await tester.pumpAndSettle();

      // Content 2 remains active
      expect(find.text('Content 2'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
