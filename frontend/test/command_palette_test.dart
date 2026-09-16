import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/services/command_palette_registry.dart';
import 'package:frontend/core/widgets/command_palette_dialog.dart';
import 'package:frontend/core/providers/navigation_provider.dart';
import 'package:frontend/core/providers/workspace_tabs_provider.dart';

void main() {
  group('Command Palette & Global Hotkeys Tests', () {
    testWidgets('CommandPaletteRegistry registers all core screens and actions', (tester) async {
      late List<CommandPaletteItem> items;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AppLocalizationsProvider(
              locale: const Locale('ar'),
              child: Consumer(
                builder: (context, ref, _) {
                  items = CommandPaletteRegistry.getItems(context, ref);
                  return Scaffold(body: Text('Total items: ${items.length}'));
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check count
      expect(items.length, greaterThanOrEqualTo(35));

      // Verify essential screen items exist
      final screenIds = items.map((i) => i.id).toList();
      expect(screenIds, contains('screen_dashboard'));
      expect(screenIds, contains('screen_import_files'));
      expect(screenIds, contains('screen_purchase_orders'));
      expect(screenIds, contains('screen_cbm_calc'));
      expect(screenIds, contains('screen_step08_bl'));
      expect(screenIds, contains('screen_step08_match'));
      expect(screenIds, contains('screen_step08_coo'));
      expect(screenIds, contains('screen_demurrage_radar'));
      expect(screenIds, contains('screen_landed_cost'));
      expect(screenIds, contains('screen_smart_inquiry'));

      // Verify quick action items exist
      expect(screenIds, contains('action_freight_data_connector'));
      expect(screenIds, contains('action_toggle_theme'));
      expect(screenIds, contains('action_toggle_language'));
      expect(screenIds, contains('action_production_sync'));
    });

    testWidgets('CommandPaletteDialog mounts and renders search and keyboard shortcuts', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AppLocalizationsProvider(
              locale: const Locale('ar'),
              child: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () => CommandPaletteDialog.show(context, ref),
                      child: const Text('Open Palette'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open palette
      await tester.tap(find.text('Open Palette'));
      await tester.pumpAndSettle();

      // Verify dialog is visible
      expect(find.byType(CommandPaletteDialog), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('ESC'), findsNWidgets(2));
      expect(find.text('↵ Enter'), findsOneWidget);

      // Search for B/L
      await tester.enterText(find.byType(TextField), 'بوليصة');
      await tester.pumpAndSettle();

      // Verify filtered results contain B/L review
      expect(find.textContaining('بوليصة'), findsWidgets);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      // Search for Freight connector
      await tester.enterText(find.byType(TextField), 'نولون');
      await tester.pumpAndSettle();
      expect(find.textContaining('نولون'), findsWidgets);
    });

    testWidgets('Selecting an item from Command Palette switches navigation and workspace tab', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AppLocalizationsProvider(
              locale: const Locale('ar'),
              child: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () => CommandPaletteDialog.show(context, ref),
                      child: const Text('Launch Palette'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially index 0
      expect(container.read(navigationIndexProvider), 0);

      // Open palette
      await tester.tap(find.text('Launch Palette'));
      await tester.pumpAndSettle();

      // Filter for CBM
      await tester.enterText(find.byType(TextField), 'حاسبة');
      await tester.pumpAndSettle();

      // Tap on CBM calculator item
      final cbmFinder = find.textContaining('حاسبة وتراصف الحاويات CBM');
      expect(cbmFinder, findsOneWidget);
      await tester.tap(cbmFinder);
      await tester.pumpAndSettle();

      // Verify dialog closed
      expect(find.byType(CommandPaletteDialog), findsNothing);

      // Verify navigation index updated to 3 (CBM Calculator)
      expect(container.read(navigationIndexProvider), 3);

      // Verify workspace tab opened
      final activeTab = container.read(workspaceTabsProvider).activeTab;
      expect(activeTab?.routeIndex, 3);
    });
  });
}
