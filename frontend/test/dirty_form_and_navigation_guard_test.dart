import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/providers/workspace_tabs_provider.dart';
import 'package:frontend/core/widgets/unsaved_changes_dialog.dart';
import 'package:frontend/core/widgets/unsaved_changes_guard.dart';
import 'package:frontend/features/home/widgets/multi_tab_workspace_bar.dart';

void main() {
  group('Dirty Form State & Navigation Guards Tests', () {
    test('WorkspaceTab isDirty toggles properly in WorkspaceTabsNotifier', () {
      final container = ProviderContainer();
      final notifier = container.read(workspaceTabsProvider.notifier);

      notifier.openTab(
        id: 'test_tab_1',
        title: 'ملف الشحنة',
        icon: Icons.description,
        routeIndex: 1,
      );

      // Initially not dirty
      final initialTab = container.read(workspaceTabsProvider).tabs.firstWhere((t) => t.id == 'test_tab_1');
      expect(initialTab.isDirty, false);

      // Set dirty
      notifier.setTabDirty('test_tab_1', true);
      final dirtyTab = container.read(workspaceTabsProvider).tabs.firstWhere((t) => t.id == 'test_tab_1');
      expect(dirtyTab.isDirty, true);

      // Clear dirty
      notifier.setTabDirty('test_tab_1', false);
      final cleanTab = container.read(workspaceTabsProvider).tabs.firstWhere((t) => t.id == 'test_tab_1');
      expect(cleanTab.isDirty, false);
    });

    testWidgets('UnsavedChangesDialog renders and handles discard, stay, and save actions', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool? dialogResult;
      bool saveInvoked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AppLocalizationsProvider(
            locale: const Locale('ar'),
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      dialogResult = await UnsavedChangesDialog.show(
                        context,
                        customMessage: 'توجد بيانات لم يتم حفظها في الفاتورة',
                        onSave: () {
                          saveInvoked = true;
                        },
                      );
                    },
                    child: const Text('Open Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open Dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify content
      expect(find.byType(UnsavedChangesDialog), findsOneWidget);
      expect(find.text('تنبيه تعديلات غير محفوظة'), findsOneWidget);
      expect(find.text('توجد بيانات لم يتم حفظها في الفاتورة'), findsOneWidget);
      expect(find.text('تجاهل التعديلات والمتابعة'), findsOneWidget);
      expect(find.text('البقاء في الشاشة'), findsOneWidget);
      expect(find.text('حفظ التعديلات أولاً'), findsOneWidget);

      // Test Cancel / Stay
      await tester.tap(find.text('البقاء في الشاشة'));
      await tester.pumpAndSettle();

      expect(find.byType(UnsavedChangesDialog), findsNothing);
      expect(dialogResult, false);
      expect(saveInvoked, false);

      // Re-open and test Save
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('حفظ التعديلات أولاً'));
      await tester.pumpAndSettle();

      expect(dialogResult, true);
      expect(saveInvoked, true);
    });

    testWidgets('UnsavedChangesGuard syncs dirty state and guards tab close in MultiTabWorkspaceBar', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      final notifier = container.read(workspaceTabsProvider.notifier);

      notifier.openTab(
        id: 'doc_review_tab',
        title: 'مراجعة البوليصة',
        icon: Icons.article_outlined,
        routeIndex: 18,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AppLocalizationsProvider(
              locale: const Locale('ar'),
              child: Scaffold(
                body: Column(
                  children: [
                    const MultiTabWorkspaceBar(),
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, _) {
                          return const UnsavedChangesGuard(
                            tabId: 'doc_review_tab',
                            isDirty: true,
                            child: Text('Form Content'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the tab is marked dirty in provider
      final tab = container.read(workspaceTabsProvider).tabs.firstWhere((t) => t.id == 'doc_review_tab');
      expect(tab.isDirty, true);

      // Verify crimson dirty badge dot exists
      final dirtyDotFinder = find.byTooltip('توجد تعديلات غير محفوظة في هذا التبويب');
      expect(dirtyDotFinder, findsOneWidget);

      // Tap close icon on the dirty tab
      final closeIconFinder = find.byIcon(Icons.close);
      expect(closeIconFinder, findsOneWidget);
      await tester.tap(closeIconFinder);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appeared
      expect(find.byType(UnsavedChangesDialog), findsOneWidget);

      // Dismiss dialog via stay
      await tester.tap(find.text('البقاء في الشاشة'));
      await tester.pumpAndSettle();

      // Tab should still be open
      expect(container.read(workspaceTabsProvider).tabs.any((t) => t.id == 'doc_review_tab'), true);

      // Tap close again and choose Discard
      await tester.tap(closeIconFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('تجاهل التعديلات والمتابعة'));
      await tester.pumpAndSettle();

      // Tab should now be closed
      expect(container.read(workspaceTabsProvider).tabs.any((t) => t.id == 'doc_review_tab'), false);
    });
  });
}
