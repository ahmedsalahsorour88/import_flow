import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/workspace_tabs_provider.dart';
import 'package:frontend/features/home/widgets/multi_tab_workspace_bar.dart';


void main() {
  group('UI-WORKSPACE-012: Workspace Tabs Provider Tests', () {
    test('Initial state contains unclosable Dashboard tab', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(workspaceTabsProvider);
      expect(state.tabs.length, 1);
      expect(state.tabs.first.id, 'dashboard');
      expect(state.tabs.first.isClosable, false);
      expect(state.activeTabId, 'dashboard');
      expect(state.activeTab?.title, 'لوحة التحكم');
    });

    test('openTab adds a new tab and activates it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workspaceTabsProvider.notifier);
      notifier.openTab(
        id: 'tab_import_files',
        title: 'ملفات الشحنات',
        icon: Icons.folder,
        routeIndex: 1,
      );

      final state = container.read(workspaceTabsProvider);
      expect(state.tabs.length, 2);
      expect(state.activeTabId, 'tab_import_files');
      expect(state.activeTab?.title, 'ملفات الشحنات');
      expect(state.activeTab?.routeIndex, 1);
    });

    test('openTab switches to existing tab without duplicate', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workspaceTabsProvider.notifier);
      notifier.openTab(
        id: 'tab_po',
        title: 'أوامر الشراء',
        icon: Icons.shopping_cart,
        routeIndex: 2,
      );
      expect(container.read(workspaceTabsProvider).tabs.length, 2);

      // Re-open same tab
      notifier.openTab(
        id: 'tab_po',
        title: 'أوامر الشراء',
        icon: Icons.shopping_cart,
        routeIndex: 2,
      );

      final state = container.read(workspaceTabsProvider);
      expect(state.tabs.length, 2); // No duplicate
      expect(state.activeTabId, 'tab_po');
    });

    test('closeTab removes closable tab and selects previous', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workspaceTabsProvider.notifier);
      notifier.openTab(
        id: 'tab_1',
        title: 'شحنة 1',
        icon: Icons.folder,
        routeIndex: 1,
      );
      notifier.openTab(
        id: 'tab_2',
        title: 'شحنة 2',
        icon: Icons.folder,
        routeIndex: 1,
      );

      expect(container.read(workspaceTabsProvider).tabs.length, 3);
      expect(container.read(workspaceTabsProvider).activeTabId, 'tab_2');

      notifier.closeTab('tab_2');

      final state = container.read(workspaceTabsProvider);
      expect(state.tabs.length, 2);
      expect(state.activeTabId, 'tab_1');
    });

    test('closeTab cannot remove unclosable tab', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workspaceTabsProvider.notifier);
      notifier.closeTab('dashboard');

      final state = container.read(workspaceTabsProvider);
      expect(state.tabs.length, 1);
      expect(state.activeTabId, 'dashboard');
    });

    test('closeOtherTabs keeps dashboard and selected tab', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workspaceTabsProvider.notifier);
      notifier.openTab(id: 'tab_a', title: 'A', icon: Icons.star, routeIndex: 1);
      notifier.openTab(id: 'tab_b', title: 'B', icon: Icons.star, routeIndex: 2);
      notifier.openTab(id: 'tab_c', title: 'C', icon: Icons.star, routeIndex: 3);

      expect(container.read(workspaceTabsProvider).tabs.length, 4);

      notifier.closeOtherTabs('tab_b');

      final state = container.read(workspaceTabsProvider);
      expect(state.tabs.length, 2); // dashboard + tab_b
      expect(state.tabs.any((t) => t.id == 'dashboard'), true);
      expect(state.tabs.any((t) => t.id == 'tab_b'), true);
      expect(state.activeTabId, 'tab_b');
    });
  });

  group('UI-WORKSPACE-012: MultiTabWorkspaceBar Widget Tests', () {
    testWidgets('Renders tab bar and switches active tab on tap', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(workspaceTabsProvider.notifier).openTab(
        id: 'tab_po',
        title: 'أوامر الشراء',
        icon: Icons.shopping_cart,
        routeIndex: 2,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: MultiTabWorkspaceBar(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check both tabs are rendered
      expect(find.text('لوحة التحكم'), findsOneWidget);
      expect(find.text('أوامر الشراء'), findsOneWidget);

      // Tap on dashboard tab
      await tester.tap(find.text('لوحة التحكم'));
      await tester.pumpAndSettle();

      expect(container.read(workspaceTabsProvider).activeTabId, 'dashboard');
    });
  });
}
