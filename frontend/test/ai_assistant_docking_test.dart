import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/providers/ai_assistant_provider.dart';
import 'package:frontend/core/widgets/ai_assistant_panel.dart';

import 'package:frontend/core/widgets/ai_assistant_top_bar_button.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('AI Assistant State & Dismissal Unit Tests', () {
    test('isGreetingDismissed defaults to false in initial state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(aiAssistantProvider);
      expect(state.isGreetingDismissed, isFalse);
    });

    test('dismissGreeting() updates isGreetingDismissed to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(aiAssistantProvider.notifier);
      expect(container.read(aiAssistantProvider).isGreetingDismissed, isFalse);

      notifier.dismissGreeting();
      expect(container.read(aiAssistantProvider).isGreetingDismissed, isTrue);
    });

    test('copyWith preserves or overrides isGreetingDismissed properly', () {
      const state = AiAssistantState(isGreetingDismissed: false);
      final updated = state.copyWith(isGreetingDismissed: true);
      expect(updated.isGreetingDismissed, isTrue);

      final preserved = updated.copyWith(isPanelOpen: true);
      expect(preserved.isGreetingDismissed, isTrue);
      expect(preserved.isPanelOpen, isTrue);
    });
  });

  group('AiAssistantDockedPanel Widget Tests', () {
    testWidgets('AiAssistantDockedPanel renders docked container with header controls', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  Expanded(child: Center(child: Text('Main Content'))),
                  AiAssistantDockedPanel(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Main content is present alongside docked panel
      expect(find.text('Main Content'), findsOneWidget);

      // Close and maximize buttons exist in header
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.open_in_full_rounded), findsOneWidget);
    });
  });

  group('AiAssistantOverlay Greeting & Launcher Tests', () {
    testWidgets('Default AiAssistantOverlay does not render floating launcher on tables', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Center(child: Text('Table View')),
                  AiAssistantOverlay(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Floating button is NOT rendered in default overlay
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('Greeting bubble is visible when showFloatingLauncher is true and disappears when dismissed', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Center(child: Text('Table View')),
                  AiAssistantOverlay(showFloatingLauncher: true),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Floating button exists
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);

      // Close icon on greeting bubble exists
      final closeGreetingFinder = find.byIcon(Icons.close);
      expect(closeGreetingFinder, findsOneWidget);

      // Tap close icon on greeting bubble
      await tester.tap(closeGreetingFinder);
      await tester.pumpAndSettle();

      // Greeting bubble close icon should now be gone
      expect(find.byIcon(Icons.close), findsNothing);

      // Launcher button remains
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    });
  });

  group('AiAssistantTopBarButton Widget Tests', () {
    testWidgets('Renders downsized button in top bar and toggles panel on tap', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(40),
                child: Row(
                  children: [
                    AiAssistantTopBarButton(),
                  ],
                ),
              ),
              body: Center(child: Text('App Content')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially closed: chat bubble outline icon
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      // Tap to toggle open
      await tester.tap(find.byType(AiAssistantTopBarButton));
      await tester.pumpAndSettle();

      // Now open: close icon is shown
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);

      // Tap again to toggle closed
      await tester.tap(find.byType(AiAssistantTopBarButton));
      await tester.pumpAndSettle();

      // Returned to closed state
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });
  });
}
