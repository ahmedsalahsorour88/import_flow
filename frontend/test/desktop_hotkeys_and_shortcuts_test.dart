import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/providers/navigation_provider.dart';
import 'package:frontend/core/providers/workspace_tabs_provider.dart';
import 'package:frontend/core/widgets/keyboard_shortcuts_dialog.dart';

void main() {
  group('Desktop Global Hotkeys & Shortcuts Tests', () {
    test('WorkspaceTabsNotifier tab cycling and closing logic', () {
      final container = ProviderContainer();
      final notifier = container.read(workspaceTabsProvider.notifier);

      // Initially only dashboard (unclosable)
      expect(container.read(workspaceTabsProvider).tabs.length, 1);
      expect(container.read(workspaceTabsProvider).activeTabId, 'dashboard');

      // Open tab 1 and tab 2
      notifier.openTab(
        id: 'tab_files',
        title: 'ملفات الشحنات',
        icon: Icons.folder,
        routeIndex: 1,
      );
      notifier.openTab(
        id: 'tab_cbm',
        title: 'حاسبة CBM',
        icon: Icons.calculate,
        routeIndex: 3,
      );

      expect(container.read(workspaceTabsProvider).tabs.length, 3);
      expect(container.read(workspaceTabsProvider).activeTabId, 'tab_cbm');

      // Test selectNextTab
      final nextTab = notifier.selectNextTab();
      expect(nextTab?.id, 'dashboard');
      expect(container.read(workspaceTabsProvider).activeTabId, 'dashboard');

      // Test selectPreviousTab
      final prevTab = notifier.selectPreviousTab();
      expect(prevTab?.id, 'tab_cbm');
      expect(container.read(workspaceTabsProvider).activeTabId, 'tab_cbm');

      // Test closeActiveTab
      final afterClose = notifier.closeActiveTab();
      expect(afterClose?.id, 'tab_files');
      expect(container.read(workspaceTabsProvider).tabs.length, 2);
    });

    testWidgets('KeyboardShortcutsDialog mounts and displays all shortcut categories and key caps', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AppLocalizationsProvider(
              locale: const Locale('ar'),
              child: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () => KeyboardShortcutsDialog.show(context),
                      child: const Text('Show Shortcuts'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Show Shortcuts'));
      await tester.pumpAndSettle();

      // Verify dialog is visible
      expect(find.byType(KeyboardShortcutsDialog), findsOneWidget);

      // Verify headers and categories
      expect(find.text('دليل اختصارات لوحة المفاتيح'), findsOneWidget);
      expect(find.text('التنقل ومساحة العمل'), findsOneWidget);
      expect(find.text('العمليات والبيانات'), findsOneWidget);
      expect(find.text('المساعدة والإنتاجية'), findsOneWidget);

      // Verify key caps
      expect(find.text('Ctrl'), findsWidgets);
      expect(find.text('K'), findsWidgets);
      expect(find.text('Tab'), findsWidgets);
      expect(find.text('F11'), findsWidgets);
      expect(find.text('ESC'), findsWidgets);
      expect(find.text('F1'), findsWidgets);

      // Dismiss dialog
      await tester.tap(find.text('إغلاق'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardShortcutsDialog), findsNothing);
    });

    testWidgets('Global Hotkeys trigger navigation in CallbackShortcuts harness', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      final notifier = container.read(workspaceTabsProvider.notifier);

      notifier.openTab(
        id: 'tab_files',
        title: 'ملفات الشحنات',
        icon: Icons.folder,
        routeIndex: 1,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AppLocalizationsProvider(
              locale: const Locale('ar'),
              child: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.tab, control: true): () {
                          final newTab = ref.read(workspaceTabsProvider.notifier).selectNextTab();
                          if (newTab != null) {
                            ref.read(navigationIndexProvider.notifier).state = newTab.routeIndex;
                          }
                        },
                        const SingleActivator(LogicalKeyboardKey.keyW, control: true): () {
                          final newTab = ref.read(workspaceTabsProvider.notifier).closeActiveTab();
                          if (newTab != null) {
                            ref.read(navigationIndexProvider.notifier).state = newTab.routeIndex;
                          }
                        },
                        const SingleActivator(LogicalKeyboardKey.f1): () {
                          KeyboardShortcutsDialog.show(context);
                        },
                      },
                      child: const Focus(
                        autofocus: true,
                        child: Text('Shortcuts Container'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Trigger Ctrl + Tab
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // Verified tab cycled
      expect(container.read(workspaceTabsProvider).activeTabId, 'dashboard');
      expect(container.read(navigationIndexProvider), 0);

      // Trigger F1
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardShortcutsDialog), findsOneWidget);
    });
  });
}
