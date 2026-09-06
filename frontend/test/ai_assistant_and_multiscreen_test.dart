import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/ai_assistant_provider.dart';
import 'package:frontend/core/providers/workspace_tabs_provider.dart';
import 'package:frontend/core/widgets/ai_assistant_panel.dart';

void main() {
  group('AI Assistant & Multi-Screen Workspace Tests', () {
    test('WorkspaceTabsNotifier enforces max 10 tabs limit', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workspaceTabsProvider.notifier);

      // Open 12 tabs
      for (int i = 1; i <= 12; i++) {
        notifier.openTab(
          id: 'tab_$i',
          title: 'شاشة $i',
          icon: Icons.tab,
          routeIndex: i,
        );
      }

      final state = container.read(workspaceTabsProvider);
      // Must not exceed maxTabs (10)
      expect(state.tabs.length, lessThanOrEqualTo(10));
      // Unclosable dashboard tab is preserved
      expect(state.tabs.any((t) => t.id == 'dashboard'), isTrue);
      // Active tab is the latest opened tab
      expect(state.activeTabId, 'tab_12');
    });

    test('ChatMessage model creates correct messages', () {
      final msg = ChatMessage(
        id: 'msg_1',
        text: 'كيف يتم حساب الضرائب الجمركية؟',
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      );

      expect(msg.id, 'msg_1');
      expect(msg.text, 'كيف يتم حساب الضرائب الجمركية؟');
      expect(msg.sender, MessageSender.user);
      expect(msg.isError, isFalse);
    });

    test('AiAssistantState initial state and context update', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(aiAssistantProvider);
      expect(state.isPanelOpen, isFalse);
      expect(state.isLoading, isFalse);

      final notifier = container.read(aiAssistantProvider.notifier);
      notifier.updateScreenContext('مرحلة 1: دراسات الشحن');

      final updated = container.read(aiAssistantProvider);
      expect(updated.currentScreenContext, 'مرحلة 1: دراسات الشحن');

      notifier.togglePanel();
      expect(container.read(aiAssistantProvider).isPanelOpen, isTrue);

      notifier.togglePanel();
      expect(container.read(aiAssistantProvider).isPanelOpen, isFalse);
    });

    testWidgets('AiAssistantOverlay renders floating button and greeting bubble', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Center(child: Text('Main Screen Content')),
                  AiAssistantOverlay(),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the greeting card matching user screenshot is rendered
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Here to help - Feedback,\nChat.'), findsOneWidget);
      expect(find.text('مساعد الاستيراد الذكي متصل'), findsOneWidget);

      // Verify floating button is rendered with chat icon
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);

      // Tap floating button to open chat panel
      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
      await tester.pumpAndSettle();

      // Chat panel should now be open
      expect(container.read(aiAssistantProvider).isPanelOpen, isTrue);
      expect(find.text('مساعد الاستيراد الذكي'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsWidgets);
    });
  });
}
