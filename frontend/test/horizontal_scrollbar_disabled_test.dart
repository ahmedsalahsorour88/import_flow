import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  group('AppCustomScrollBehavior - Horizontal Scrollbar Disabled Globally', () {
    final scrollBehavior = AppCustomScrollBehavior();

    test('buildScrollbar returns child directly without Scrollbar for horizontal directions', () {
      final dummyContext = _DummyBuildContext();
      const testChild = Text('Horizontal Content');

      // Test AxisDirection.left
      final detailsLeft = ScrollableDetails(
        direction: AxisDirection.left,
        controller: ScrollController(),
      );
      final widgetLeft = scrollBehavior.buildScrollbar(dummyContext, testChild, detailsLeft);
      expect(widgetLeft, same(testChild));
      expect(widgetLeft is Scrollbar, isFalse);

      // Test AxisDirection.right
      final detailsRight = ScrollableDetails(
        direction: AxisDirection.right,
        controller: ScrollController(),
      );
      final widgetRight = scrollBehavior.buildScrollbar(dummyContext, testChild, detailsRight);
      expect(widgetRight, same(testChild));
      expect(widgetRight is Scrollbar, isFalse);
    });

    test('buildScrollbar retains Scrollbar for vertical directions', () {
      final dummyContext = _DummyBuildContext();
      const testChild = Text('Vertical Content');

      // Test AxisDirection.down
      final detailsDown = ScrollableDetails(
        direction: AxisDirection.down,
        controller: ScrollController(),
      );
      final widgetDown = scrollBehavior.buildScrollbar(dummyContext, testChild, detailsDown);
      expect(widgetDown, isA<Scrollbar>());

      // Test AxisDirection.up
      final detailsUp = ScrollableDetails(
        direction: AxisDirection.up,
        controller: ScrollController(),
      );
      final widgetUp = scrollBehavior.buildScrollbar(dummyContext, testChild, detailsUp);
      expect(widgetUp, isA<Scrollbar>());
    });

    testWidgets('Horizontal SingleChildScrollView does not render Scrollbar in tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scrollBehavior: AppCustomScrollBehavior(),
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  20,
                  (i) => Container(
                    width: 100,
                    height: 50,
                    color: i.isEven ? Colors.blue : Colors.green,
                    child: Text('Item $i'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure NO Scrollbar or RawScrollbar widget is built for the horizontal scrollable
      expect(find.byType(Scrollbar), findsNothing);
      expect(find.byType(RawScrollbar), findsNothing);
    });

    testWidgets('Vertical SingleChildScrollView still renders Scrollbar in tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scrollBehavior: AppCustomScrollBehavior(),
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: List.generate(
                  20,
                  (i) => Container(
                    width: 100,
                    height: 100,
                    color: i.isEven ? Colors.blue : Colors.green,
                    child: Text('Item $i'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure Scrollbar is built for the vertical scrollable
      expect(find.byType(Scrollbar), findsOneWidget);
    });
  });
}

class _DummyBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
